"""Etapa generate: converte pares Q/A em questões de múltipla escolha via LLM."""

from __future__ import annotations

import hashlib
import json
import logging
import random
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

from pydantic import ValidationError
from slugify import slugify

from .config import Config
from .llm import LLMClient
from .schema import TOPICS, Question

log = logging.getLogger(__name__)

MAX_ATTEMPTS = 3
MAX_WORKERS = 5

PROMPT_TEMPLATE = """Você é um gerador de questões de múltipla escolha para um app de estudo \
de entrevistas técnicas mobile. A partir da pergunta e resposta abaixo, produza SOMENTE um \
objeto JSON (sem texto adicional) com os campos:

- "question": a pergunta reescrita de forma autocontida, em pt-BR. Preserve blocos de código \
se houver.
- "options": exatamente 5 alternativas em pt-BR — 1 correta e 4 distratores plausíveis \
(erros conceituais comuns, não absurdos). Sem alternativas duplicadas.
- "correctIndex": índice (0-4) da alternativa correta.
- "explanation": 2 a 5 frases explicando por que a correta está certa e por que os \
distratores erram.
- "topic": um de {topics}.
- "level": 1 (júnior), 2 (pleno) ou 3 (sênior).
- "tags": lista curta de tags em inglês (ex.: ["kotlin", "concurrency"]).

Tópico sugerido pela fonte: {topic_hint}

Pergunta original:
{raw_question}

{answer_section}"""

ANSWER_WITH = "Resposta original (use como base para a alternativa correta):\n{raw_answer}"
ANSWER_WITHOUT = (
    "Não há resposta original — responda a pergunta você mesmo com precisão técnica "
    "e use essa resposta como base para a alternativa correta."
)


def question_id(source_id: str, raw_question: str) -> str:
    digest = hashlib.sha1(slugify(source_id + " " + raw_question).encode()).hexdigest()[:8]
    return f"{source_id}_{digest}"


def build_prompt(pair: dict) -> str:
    answer = pair.get("raw_answer")
    answer_section = ANSWER_WITH.format(raw_answer=answer) if answer else ANSWER_WITHOUT
    return PROMPT_TEMPLATE.format(
        topics=", ".join(sorted(TOPICS)),
        topic_hint=pair.get("topic_hint", ""),
        raw_question=pair["raw_question"],
        answer_section=answer_section,
    )


def _parse_llm_json(text: str) -> dict:
    text = text.strip()
    if text.startswith("```"):
        text = re_strip_fences(text)
    return json.loads(text)


def re_strip_fences(text: str) -> str:
    lines = text.splitlines()
    if lines and lines[0].startswith("```"):
        lines = lines[1:]
    if lines and lines[-1].startswith("```"):
        lines = lines[:-1]
    return "\n".join(lines)


def generate_one(
    pair: dict, qid: str, client: LLMClient, backoff_base: float = 1.0
) -> Question:
    """Gera uma questão com retry/backoff. Levanta exceção após MAX_ATTEMPTS falhas."""
    prompt = build_prompt(pair)
    last_error: Exception | None = None
    for attempt in range(MAX_ATTEMPTS):
        try:
            raw = client.complete(prompt)
            data = _parse_llm_json(raw)
            data["id"] = qid
            data["source"] = pair["source_id"]
            data["generated_answer"] = pair.get("raw_answer") is None
            return Question.model_validate(data)
        except (json.JSONDecodeError, ValidationError, RuntimeError, OSError) as e:
            last_error = e
            if attempt < MAX_ATTEMPTS - 1:
                delay = backoff_base * (2**attempt) + random.uniform(0, backoff_base)
                log.warning("generate %s tentativa %d falhou: %s — retry em %.1fs",
                            qid, attempt + 1, e, delay)
                time.sleep(delay)
    raise RuntimeError(f"geração de {qid} falhou após {MAX_ATTEMPTS} tentativas: {last_error}")


def load_pairs(config: Config) -> list[dict]:
    pairs: list[dict] = []
    if not config.parsed_dir.exists():
        return pairs
    for jsonl in sorted(config.parsed_dir.glob("*.jsonl")):
        for line in jsonl.read_text(encoding="utf-8").splitlines():
            if line.strip():
                pairs.append(json.loads(line))
    return pairs


def run_generate(
    config: Config,
    client: LLMClient | None,
    dry_run: bool = False,
    limit: int | None = None,
    backoff_base: float = 1.0,
) -> dict[str, int]:
    """Gera MCQs para pares ainda sem questão. Retorna contadores."""
    config.generated_dir.mkdir(parents=True, exist_ok=True)
    config.review_dir.mkdir(parents=True, exist_ok=True)

    pending: list[tuple[dict, str]] = []
    skipped = 0
    for pair in load_pairs(config):
        qid = question_id(pair["source_id"], pair["raw_question"])
        if (config.generated_dir / f"{qid}.json").exists():
            skipped += 1
            continue
        pending.append((pair, qid))

    if limit is not None:
        pending = pending[:limit]

    if dry_run:
        log.info("dry-run: %d chamadas ao LLM seriam feitas (%d já geradas)",
                 len(pending), skipped)
        return {"planned": len(pending), "skipped": skipped, "generated": 0, "rejected": 0}

    if not pending:
        log.info("generate: nada a fazer (%d já geradas)", skipped)
        return {"planned": 0, "skipped": skipped, "generated": 0, "rejected": 0}

    assert client is not None, "cliente LLM é obrigatório fora de dry-run"

    generated = 0
    rejected = 0
    rejected_file = config.review_dir / "rejected.jsonl"

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as pool:
        futures = {
            pool.submit(generate_one, pair, qid, client, backoff_base): (pair, qid)
            for pair, qid in pending
        }
        for future in as_completed(futures):
            pair, qid = futures[future]
            try:
                question = future.result()
            except Exception as e:
                rejected += 1
                with open(rejected_file, "a", encoding="utf-8") as f:
                    f.write(json.dumps({
                        "id": qid,
                        "source_id": pair["source_id"],
                        "raw_question": pair["raw_question"],
                        "stage": "generate",
                        "reason": str(e),
                    }, ensure_ascii=False) + "\n")
                continue
            out = config.generated_dir / f"{qid}.json"
            out.write_text(question.model_dump_json(indent=2), encoding="utf-8")
            generated += 1

    log.info("generate: %d geradas, %d rejeitadas, %d puladas", generated, rejected, skipped)
    return {"planned": len(pending), "skipped": skipped,
            "generated": generated, "rejected": rejected}
