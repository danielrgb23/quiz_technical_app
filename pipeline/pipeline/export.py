"""Etapa export: gera questions_v<N>.json e manifest.json versionados."""

from __future__ import annotations

import hashlib
import json
import logging
import re
from datetime import datetime, timezone

from .config import Config

log = logging.getLogger(__name__)

_VERSION_RE = re.compile(r"questions_v(\d+)\.json$")


def current_version(config: Config) -> int:
    """Maior versão existente em data/output, ou 0 se nenhuma."""
    if not config.output_dir.exists():
        return 0
    versions = [
        int(m.group(1))
        for p in config.output_dir.glob("questions_v*.json")
        if (m := _VERSION_RE.search(p.name))
    ]
    return max(versions, default=0)


def run_export(config: Config, bump: bool = False) -> dict:
    config.output_dir.mkdir(parents=True, exist_ok=True)

    validated = config.validated_dir / "questions.jsonl"
    if not validated.exists():
        raise FileNotFoundError(
            f"{validated} não existe — rode 'validate' antes de 'export'"
        )
    questions = [
        json.loads(line)
        for line in validated.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]

    version = current_version(config)
    if bump or version == 0:
        version += 1

    questions_path = config.output_dir / f"questions_v{version}.json"
    payload = json.dumps(questions, ensure_ascii=False, indent=2)
    questions_path.write_text(payload, encoding="utf-8")

    checksum = hashlib.sha256(payload.encode("utf-8")).hexdigest()
    manifest = {
        "version": version,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "count": len(questions),
        "sources": [
            {"id": s.id, "repo": s.repo, "license": s.license}
            for s in config.sources
        ],
        "checksum": checksum,
    }
    (config.output_dir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    log.info("export: %s (%d questões, checksum %s)", questions_path.name,
             len(questions), checksum[:12])
    return manifest
