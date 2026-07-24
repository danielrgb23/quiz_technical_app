"""Etapa parse: extrai pares pergunta/resposta do markdown."""

from __future__ import annotations

import json
import logging
import re

from .config import Config, Source

log = logging.getLogger(__name__)

_BADGE_RE = re.compile(r"!\[[^\]]*\]\([^)]*\)")
_IMG_TAG_RE = re.compile(r"<img[^>]*>", re.IGNORECASE)
_LINK_RE = re.compile(r"\[([^\]]+)\]\([^)]*\)")
_HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)$")
_LIST_QUESTION_RE = re.compile(r"^\s*[-*+]\s+(?:\*\*)?(.+?\?)(?:\*\*)?\s*$")


def _normalize(text: str) -> str:
    """Remove badges, imagens e links; preserva blocos de código intactos."""
    parts = re.split(r"(```.*?```)", text, flags=re.DOTALL)
    cleaned: list[str] = []
    for i, part in enumerate(parts):
        if i % 2 == 1:  # bloco de código cercado
            cleaned.append(part)
            continue
        part = _BADGE_RE.sub("", part)
        part = _IMG_TAG_RE.sub("", part)
        part = _LINK_RE.sub(r"\1", part)
        cleaned.append(part)
    return "".join(cleaned).strip()


def parse_markdown(text: str, source: Source) -> list[dict]:
    """Extrai pares Q/A: headings terminados em '?' viram pergunta, corpo até o
    próximo heading vira resposta; itens de lista terminados em '?' viram
    perguntas sem resposta quando list_questions=True."""
    pairs: list[dict] = []
    lines = text.splitlines()

    current_question: str | None = None
    body: list[str] = []
    in_code_block = False

    def flush() -> None:
        nonlocal current_question, body
        if current_question is None:
            return
        answer = _normalize("\n".join(body))
        pairs.append(
            {
                "source_id": source.id,
                "raw_question": current_question,
                "raw_answer": answer or None,
                "topic_hint": source.topic_default,
            }
        )
        current_question = None
        body = []

    for line in lines:
        if line.strip().startswith("```"):
            in_code_block = not in_code_block
            body.append(line)
            continue
        if in_code_block:
            body.append(line)
            continue

        m = _HEADING_RE.match(line)
        if m:
            flush()
            level = len(m.group(1))
            title = _normalize(m.group(2)).strip()
            if level >= source.min_heading_level and title.endswith("?"):
                current_question = title
            continue

        if current_question is not None:
            body.append(line)
        elif source.list_questions:
            lm = _LIST_QUESTION_RE.match(line)
            if lm:
                q = _normalize(lm.group(1)).strip()
                if q.endswith("?"):
                    pairs.append(
                        {
                            "source_id": source.id,
                            "raw_question": q,
                            "raw_answer": None,
                            "topic_hint": source.topic_default,
                        }
                    )

    flush()
    return pairs


def run_parse(config: Config) -> dict[str, int]:
    """Processa todas as fontes. Retorna {source_id: quantidade de pares}."""
    config.parsed_dir.mkdir(parents=True, exist_ok=True)
    counts: dict[str, int] = {}

    for source in config.sources:
        source_dir = config.raw_dir / source.id
        pairs: list[dict] = []
        if source_dir.exists():
            for raw_file in sorted(source_dir.iterdir()):
                if raw_file.suffix == ".sha256":
                    continue
                text = raw_file.read_text(encoding="utf-8", errors="replace")
                pairs.extend(parse_markdown(text, source))

        out_file = config.parsed_dir / f"{source.id}.jsonl"
        if len(pairs) < source.min_expected_pairs and out_file.exists():
            log.warning(
                "parse %s: extraídos %d pares (< min_expected_pairs=%d) — "
                "mantendo parsed anterior intacto",
                source.id,
                len(pairs),
                source.min_expected_pairs,
            )
            counts[source.id] = -1
            continue
        if len(pairs) < source.min_expected_pairs:
            log.warning(
                "parse %s: apenas %d pares extraídos (< min_expected_pairs=%d)",
                source.id,
                len(pairs),
                source.min_expected_pairs,
            )

        with open(out_file, "w", encoding="utf-8") as f:
            for pair in pairs:
                f.write(json.dumps(pair, ensure_ascii=False) + "\n")
        counts[source.id] = len(pairs)
        log.info("parse %s: %d pares", source.id, len(pairs))
    return counts
