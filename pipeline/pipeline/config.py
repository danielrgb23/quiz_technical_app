"""Carregamento e validação de sources.yaml e variáveis de ambiente."""

from __future__ import annotations

import os
from pathlib import Path

import yaml
from dotenv import load_dotenv
from pydantic import BaseModel, field_validator

DEFAULT_MODEL = "claude-opus-4-8"


class Source(BaseModel):
    id: str
    repo: str
    files: list[str]
    topic_default: str
    license: str
    parser: str = "headings"
    min_heading_level: int = 3
    list_questions: bool = False
    min_expected_pairs: int = 10

    @field_validator("license")
    @classmethod
    def license_required(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("campo 'license' é obrigatório")
        return v


class Config(BaseModel):
    sources: list[Source]
    data_dir: Path

    @property
    def raw_dir(self) -> Path:
        return self.data_dir / "raw"

    @property
    def parsed_dir(self) -> Path:
        return self.data_dir / "parsed"

    @property
    def generated_dir(self) -> Path:
        return self.data_dir / "generated"

    @property
    def validated_dir(self) -> Path:
        return self.data_dir / "validated"

    @property
    def review_dir(self) -> Path:
        return self.data_dir / "review"

    @property
    def output_dir(self) -> Path:
        return self.data_dir / "output"


def load_config(sources_path: Path, data_dir: Path) -> Config:
    with open(sources_path, encoding="utf-8") as f:
        raw = yaml.safe_load(f)
    if not raw or "sources" not in raw:
        raise ValueError(f"{sources_path}: esperado mapeamento com chave 'sources'")
    try:
        sources = [Source.model_validate(s) for s in raw["sources"]]
    except Exception as e:
        raise ValueError(f"{sources_path}: fonte inválida — {e}") from e
    return Config(sources=sources, data_dir=data_dir)


def load_env(dotenv_path: Path | None = None) -> None:
    load_dotenv(dotenv_path)


def get_model() -> str:
    return os.environ.get("PIPELINE_MODEL", DEFAULT_MODEL)
