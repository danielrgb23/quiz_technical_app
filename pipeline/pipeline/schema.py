"""Schema da questão de múltipla escolha e taxonomia de tópicos."""

from __future__ import annotations

from pydantic import BaseModel, Field, field_validator, model_validator

TOPICS = {
    "flutter",
    "dart",
    "android",
    "kotlin",
    "ios",
    "swift",
    "architecture",
    "state_management",
    "system_design",
    "testing",
    "performance",
    "concurrency",
    "networking",
    "storage",
}


class Question(BaseModel):
    id: str
    source: str
    topic: str
    level: int = Field(ge=1, le=3)
    question: str
    options: list[str]
    correctIndex: int = Field(ge=0, le=4)
    explanation: str
    tags: list[str] = []
    language: str = "pt-BR"
    generated_answer: bool = False

    @field_validator("question", "explanation")
    @classmethod
    def not_blank(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("não pode ser vazio")
        return v

    @field_validator("topic")
    @classmethod
    def topic_in_taxonomy(cls, v: str) -> str:
        if v not in TOPICS:
            raise ValueError(f"tópico '{v}' fora da taxonomia")
        return v

    @model_validator(mode="after")
    def check_options(self) -> "Question":
        if len(self.options) != 5:
            raise ValueError(f"esperadas 5 alternativas, recebidas {len(self.options)}")
        normalized = [o.strip().lower() for o in self.options]
        if len(set(normalized)) != len(normalized):
            raise ValueError("alternativas duplicadas")
        if any(not o.strip() for o in self.options):
            raise ValueError("alternativa vazia")
        return self


# Schema JSON pedido ao LLM (structured outputs) — sem id/source, que são nossos.
LLM_OUTPUT_SCHEMA = {
    "type": "object",
    "properties": {
        "question": {"type": "string"},
        "options": {"type": "array", "items": {"type": "string"}},
        "correctIndex": {"type": "integer", "enum": [0, 1, 2, 3, 4]},
        "explanation": {"type": "string"},
        "topic": {"type": "string", "enum": sorted(TOPICS)},
        "level": {"type": "integer", "enum": [1, 2, 3]},
        "tags": {"type": "array", "items": {"type": "string"}},
    },
    "required": ["question", "options", "correctIndex", "explanation", "topic", "level", "tags"],
    "additionalProperties": False,
}
