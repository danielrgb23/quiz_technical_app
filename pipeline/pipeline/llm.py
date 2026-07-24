"""Cliente LLM: interface + implementação Anthropic (structured outputs)."""

from __future__ import annotations

from typing import Protocol

from .schema import LLM_OUTPUT_SCHEMA


class LLMClient(Protocol):
    def complete(self, prompt: str) -> str:
        """Retorna a resposta do modelo como string JSON."""
        ...


class AnthropicClient:
    def __init__(self, model: str) -> None:
        import anthropic

        self.model = model
        # Resolução padrão de credenciais: ANTHROPIC_API_KEY (inclusive via .env),
        # ANTHROPIC_AUTH_TOKEN ou perfil do `ant auth login`.
        self._client = anthropic.Anthropic()

    def complete(self, prompt: str) -> str:
        response = self._client.messages.create(
            model=self.model,
            max_tokens=2048,
            output_config={"format": {"type": "json_schema", "schema": LLM_OUTPUT_SCHEMA}},
            messages=[{"role": "user", "content": prompt}],
        )
        if response.stop_reason == "refusal":
            raise RuntimeError("LLM recusou a requisição (stop_reason=refusal)")
        text = next((b.text for b in response.content if b.type == "text"), None)
        if text is None:
            raise RuntimeError(f"resposta sem bloco de texto (stop_reason={response.stop_reason})")
        return text
