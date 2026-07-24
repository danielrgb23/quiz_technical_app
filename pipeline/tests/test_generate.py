import json

from pipeline.generate import question_id, run_generate
from tests.conftest import FakeLLMClient


def write_pairs(config, pairs):
    config.parsed_dir.mkdir(parents=True, exist_ok=True)
    with open(config.parsed_dir / "test_source.jsonl", "w") as f:
        for p in pairs:
            f.write(json.dumps(p) + "\n")


PAIR = {
    "source_id": "test_source",
    "raw_question": "O que é um Widget?",
    "raw_answer": "Bloco de construção da UI.",
    "topic_hint": "flutter",
}

LLM_RESPONSE = {
    "question": "No Flutter, o que é um Widget?",
    "options": [
        "O bloco de construção imutável da UI",
        "Uma thread de background",
        "Um banco de dados local",
        "Um servidor HTTP embutido",
        "Um gerenciador de dependências",
    ],
    "correctIndex": 0,
    "explanation": "Widgets descrevem a UI de forma declarativa. As demais opções "
                   "confundem Widget com outros conceitos.",
    "topic": "flutter",
    "level": 1,
    "tags": ["flutter", "widgets"],
}


def test_question_id_deterministic():
    a = question_id("src", "O que é um Widget?")
    b = question_id("src", "O que é um Widget?")
    c = question_id("src", "Outra pergunta?")
    assert a == b
    assert a != c
    assert a.startswith("src_")
    assert len(a.split("_")[-1]) == 8


def test_generate_success(config):
    write_pairs(config, [PAIR])
    client = FakeLLMClient(default=LLM_RESPONSE)

    stats = run_generate(config, client, backoff_base=0)

    assert stats["generated"] == 1
    assert client.calls == 1
    qid = question_id(PAIR["source_id"], PAIR["raw_question"])
    data = json.loads((config.generated_dir / f"{qid}.json").read_text())
    assert data["id"] == qid
    assert data["source"] == "test_source"
    assert data["generated_answer"] is False


def test_generate_answerless_pair_sets_flag(config):
    pair = dict(PAIR, raw_answer=None)
    write_pairs(config, [pair])
    client = FakeLLMClient(default=LLM_RESPONSE)

    run_generate(config, client, backoff_base=0)

    qid = question_id(pair["source_id"], pair["raw_question"])
    data = json.loads((config.generated_dir / f"{qid}.json").read_text())
    assert data["generated_answer"] is True


def test_generate_idempotent_no_calls_on_rerun(config):
    write_pairs(config, [PAIR])
    client = FakeLLMClient(default=LLM_RESPONSE)
    run_generate(config, client, backoff_base=0)

    client2 = FakeLLMClient(default=LLM_RESPONSE)
    stats = run_generate(config, client2, backoff_base=0)

    assert client2.calls == 0
    assert stats["skipped"] == 1
    assert stats["generated"] == 0


def test_generate_invalid_json_retries_then_rejects(config):
    write_pairs(config, [PAIR])
    client = FakeLLMClient(responses=["not json", "still not json", "{broken"])

    stats = run_generate(config, client, backoff_base=0)

    assert client.calls == 3
    assert stats["rejected"] == 1
    assert stats["generated"] == 0
    rejected = (config.review_dir / "rejected.jsonl").read_text()
    assert "generate" in rejected


def test_generate_retry_then_success(config):
    write_pairs(config, [PAIR])
    client = FakeLLMClient(responses=["not json", json.dumps(LLM_RESPONSE)])

    stats = run_generate(config, client, backoff_base=0)

    assert client.calls == 2
    assert stats["generated"] == 1


def test_generate_dry_run_makes_no_calls(config):
    write_pairs(config, [PAIR, dict(PAIR, raw_question="Outra?")])

    stats = run_generate(config, None, dry_run=True)

    assert stats["planned"] == 2
    assert stats["generated"] == 0


def test_generate_dry_run_with_limit(config):
    write_pairs(config, [PAIR, dict(PAIR, raw_question="Outra?"),
                         dict(PAIR, raw_question="Mais uma?")])

    stats = run_generate(config, None, dry_run=True, limit=2)

    assert stats["planned"] == 2


def test_generate_strips_code_fences(config):
    write_pairs(config, [PAIR])
    fenced = "```json\n" + json.dumps(LLM_RESPONSE) + "\n```"
    client = FakeLLMClient(responses=[fenced])

    stats = run_generate(config, client, backoff_base=0)

    assert stats["generated"] == 1
