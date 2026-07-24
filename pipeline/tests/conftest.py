import json

import pytest

from pipeline.config import Config, Source


@pytest.fixture
def source() -> Source:
    return Source(
        id="test_source",
        repo="owner/repo",
        files=["README.md"],
        topic_default="flutter",
        license="MIT",
        min_expected_pairs=1,
    )


@pytest.fixture
def config(tmp_path, source) -> Config:
    return Config(sources=[source], data_dir=tmp_path / "data")


def make_question_dict(qid="test_source_abc12345", **overrides) -> dict:
    base = {
        "id": qid,
        "source": "test_source",
        "topic": "flutter",
        "level": 2,
        "question": "O que é um Widget no Flutter?",
        "options": ["A", "B", "C", "D", "E"],
        "correctIndex": 0,
        "explanation": "Widgets são os blocos de construção da UI no Flutter.",
        "tags": ["flutter"],
        "language": "pt-BR",
    }
    base.update(overrides)
    return base


class FakeLLMClient:
    """Cliente LLM fake: devolve respostas pré-programadas e conta chamadas."""

    def __init__(self, responses=None, default: dict | None = None):
        self.responses = list(responses or [])
        self.default = default
        self.calls = 0

    def complete(self, prompt: str) -> str:
        self.calls += 1
        if self.responses:
            item = self.responses.pop(0)
        else:
            item = self.default
        if item is None:
            raise RuntimeError("FakeLLMClient sem resposta configurada")
        if isinstance(item, Exception):
            raise item
        if isinstance(item, str):
            return item
        return json.dumps(item)
