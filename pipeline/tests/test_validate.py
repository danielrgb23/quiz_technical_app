import json

import pytest
from pydantic import ValidationError

from pipeline.schema import Question
from pipeline.validate import normalize_question, run_validate
from tests.conftest import make_question_dict


def write_generated(config, questions):
    config.generated_dir.mkdir(parents=True, exist_ok=True)
    for q in questions:
        (config.generated_dir / f"{q['id']}.json").write_text(
            json.dumps(q, ensure_ascii=False)
        )


def test_valid_question_passes():
    Question.model_validate(make_question_dict())


@pytest.mark.parametrize("overrides", [
    {"options": ["A", "B", "C", "D"]},                       # 4 alternativas
    {"options": ["A", "B", "C", "D", "E", "F"]},             # 6 alternativas
    {"correctIndex": 5},                                     # fora de 0-4
    {"correctIndex": -1},
    {"options": ["A", "a", "C", "D", "E"]},                  # duplicadas (case-insensitive)
    {"explanation": "   "},                                  # explicação vazia
    {"question": ""},
    {"topic": "cooking"},                                    # fora da taxonomia
    {"level": 4},
])
def test_invalid_questions_rejected(overrides):
    with pytest.raises(ValidationError):
        Question.model_validate(make_question_dict(**overrides))


def test_normalize_question():
    assert normalize_question("O que é um Widget?") == normalize_question(
        "o que e um widget"
    )


def test_run_validate_accepts_and_rejects(config):
    good = make_question_dict(qid="q1")
    bad = make_question_dict(qid="q2", correctIndex=9)
    write_generated(config, [good, bad])

    stats = run_validate(config)

    assert stats["valid"] == 1
    assert stats["rejected"] == 1
    lines = (config.validated_dir / "questions.jsonl").read_text().splitlines()
    assert len(lines) == 1
    assert json.loads(lines[0])["id"] == "q1"
    assert "validate" in (config.review_dir / "rejected.jsonl").read_text()


def test_run_validate_dedupes(config):
    q1 = make_question_dict(qid="q1", question="O que é um Widget?")
    q2 = make_question_dict(qid="q2", question="o que e um widget")
    write_generated(config, [q1, q2])

    stats = run_validate(config)

    assert stats["valid"] == 1
    assert stats["duplicates"] == 1
    dup = json.loads((config.review_dir / "duplicates.jsonl").read_text())
    assert dup["id"] == "q2"
    assert dup["duplicate_of"] == "q1"
