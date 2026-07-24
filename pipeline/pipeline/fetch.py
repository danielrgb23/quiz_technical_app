"""Etapa fetch: baixa arquivos markdown das fontes com cache por hash."""

from __future__ import annotations

import hashlib
import logging

import httpx

from .config import Config, Source

log = logging.getLogger(__name__)

RAW_BASE = "https://raw.githubusercontent.com"


def _sha256(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()


def fetch_source(source: Source, config: Config, client: httpx.Client) -> dict[str, str]:
    """Baixa os arquivos de uma fonte. Retorna {arquivo: 'new'|'updated'|'unchanged'|'error'}."""
    result: dict[str, str] = {}
    source_dir = config.raw_dir / source.id
    source_dir.mkdir(parents=True, exist_ok=True)

    for file in source.files:
        url = f"{RAW_BASE}/{source.repo}/HEAD/{file}"
        target = source_dir / file.replace("/", "__")
        hash_file = target.with_suffix(target.suffix + ".sha256")
        try:
            resp = client.get(url, follow_redirects=True, timeout=30.0)
            resp.raise_for_status()
        except Exception as e:
            log.error("fetch %s/%s falhou: %s (cache preservado)", source.id, file, e)
            result[file] = "error"
            continue

        new_hash = _sha256(resp.content)
        old_hash = hash_file.read_text().strip() if hash_file.exists() else None
        if old_hash == new_hash:
            result[file] = "unchanged"
            continue

        target.write_bytes(resp.content)
        hash_file.write_text(new_hash)
        result[file] = "updated" if old_hash else "new"
    return result


def run_fetch(config: Config) -> dict[str, dict[str, str]]:
    results: dict[str, dict[str, str]] = {}
    with httpx.Client() as client:
        for source in config.sources:
            results[source.id] = fetch_source(source, config, client)
            log.info("fetch %s: %s", source.id, results[source.id])
    return results
