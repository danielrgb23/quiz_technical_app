"""Etapa validate: valida schema e deduplica por pergunta normalizada."""

from __future__ import annotations

import json
import logging
import re
import unicodedata

from pydantic import ValidationError

from .config import Config
from .schema import Question

log = logging.getLogger(__name__)

_PUNCT_RE = re.compile(r"[^\w\s]", re.UNICODE)
_WS_RE = re.compile(r"\s+")


def normalize_question(text: str) -> str:
    text = unicodedata.normalize("NFKD", text.lower())
    text = "".join(c for c in text if not unicodedata.combining(c))
    text = _PUNCT_RE.sub("", text)
    return _WS_RE.sub(" ", text).strip()


def run_validate(config: Config) -> dict[str, int]:
    """Valida questões geradas e escreve o conjunto validado. Retorna contadores."""
    config.validated_dir.mkdir(parents=True, exist_ok=True)
    config.review_dir.mkdir(parents=True, exist_ok=True)

    rejected_file = config.review_dir / "rejected.jsonl"
    duplicates_file = config.review_dir / "duplicates.jsonl"
    out_file = config.validated_dir / "questions.jsonl"

    valid: list[Question] = []
    rejected = 0
    duplicates = 0
    seen: dict[str, str] = {}

    files = sorted(config.generated_dir.glob("*.json")) if config.generated_dir.exists() else []
    for path in files:
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            question = Question.model_validate(data)
        except (json.JSONDecodeError, ValidationError) as e:
            rejected += 1
            with open(rejected_file, "a", encoding="utf-8") as f:
                f.write(json.dumps({
                    "id": path.stem,
                    "stage": "validate",
                    "reason": str(e),
                }, ensure_ascii=False) + "\n")
            continue

        key = normalize_question(question.question)
        if key in seen:
            duplicates += 1
            with open(duplicates_file, "a", encoding="utf-8") as f:
                f.write(json.dumps({
                    "id": question.id,
                    "duplicate_of": seen[key],
                    "question": question.question,
                }, ensure_ascii=False) + "\n")
            continue
        seen[key] = question.id
        valid.append(question)

    with open(out_file, "w", encoding="utf-8") as f:
        for question in valid:
            f.write(question.model_dump_json() + "\n")

    log.info("validate: %d válidas, %d rejeitadas, %d duplicadas",
             len(valid), rejected, duplicates)
    return {"valid": len(valid), "rejected": rejected, "duplicates": duplicates}
