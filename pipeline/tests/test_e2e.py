"""Smoke test end-to-end offline: fetch (HTTP mockado) → parse → generate (LLM
fake) → validate → export."""

import json

import httpx

from pipeline.export import run_export
from pipeline.fetch import fetch_source
from pipeline.generate import run_generate
from pipeline.parse import run_parse
from pipeline.validate import run_validate
from tests.conftest import FakeLLMClient

MARKDOWN = """\
# Flutter Questions

### O que é um StatelessWidget?

Um widget imutável.

### O que é um StatefulWidget?

Um widget com estado mutável via State.
"""


def llm_response(question: str) -> dict:
    return {
        "question": question,
        "options": [
            f"Resposta correta para: {question}",
            "Distrator um",
            "Distrator dois",
            "Distrator três",
            "Distrator quatro",
        ],
        "correctIndex": 0,
        "explanation": "A primeira alternativa está correta porque descreve o conceito. "
                       "As demais confundem com outros conceitos.",
        "topic": "flutter",
        "level": 1,
        "tags": ["flutter"],
    }


def test_full_pipeline_offline(config, source):
    # fetch com transporte mockado
    def handler(request):
        return httpx.Response(200, content=MARKDOWN.encode())

    with httpx.Client(transport=httpx.MockTransport(handler)) as client:
        result = fetch_source(source, config, client)
    assert result == {"README.md": "new"}

    # parse
    counts = run_parse(config)
    assert counts[source.id] == 2

    # generate com LLM fake (uma resposta distinta por pergunta)
    fake = FakeLLMClient(
        responses=[
            json.dumps(llm_response("Pergunta gerada 1?")),
            json.dumps(llm_response("Pergunta gerada 2?")),
        ]
    )
    stats = run_generate(config, fake, backoff_base=0)
    assert stats["generated"] == 2

    # validate
    vstats = run_validate(config)
    assert vstats["valid"] == 2
    assert vstats["rejected"] == 0

    # export
    manifest = run_export(config, bump=True)
    assert manifest["version"] == 1
    assert manifest["count"] == 2
    questions = json.loads((config.output_dir / "questions_v1.json").read_text())
    assert len(questions) == 2
    assert all(len(q["options"]) == 5 for q in questions)

    # idempotência: rodar generate de novo não faz nenhuma chamada
    fake2 = FakeLLMClient()
    stats2 = run_generate(config, fake2, backoff_base=0)
    assert fake2.calls == 0
    assert stats2["skipped"] == 2
