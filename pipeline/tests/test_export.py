import hashlib
import json

import pytest

from pipeline.export import run_export
from tests.conftest import make_question_dict


def write_validated(config, questions):
    config.validated_dir.mkdir(parents=True, exist_ok=True)
    with open(config.validated_dir / "questions.jsonl", "w") as f:
        for q in questions:
            f.write(json.dumps(q, ensure_ascii=False) + "\n")


def test_first_export_creates_v1(config):
    write_validated(config, [make_question_dict(qid="q1")])

    manifest = run_export(config, bump=True)

    assert manifest["version"] == 1
    assert (config.output_dir / "questions_v1.json").exists()
    assert manifest["count"] == 1


def test_export_without_bump_rewrites_current(config):
    write_validated(config, [make_question_dict(qid="q1")])
    run_export(config, bump=True)

    write_validated(config, [make_question_dict(qid="q1"), make_question_dict(qid="q2")])
    manifest = run_export(config, bump=False)

    assert manifest["version"] == 1
    assert not (config.output_dir / "questions_v2.json").exists()
    data = json.loads((config.output_dir / "questions_v1.json").read_text())
    assert len(data) == 2


def test_export_bump_increments(config):
    write_validated(config, [make_question_dict(qid="q1")])
    run_export(config, bump=True)
    manifest = run_export(config, bump=True)

    assert manifest["version"] == 2
    assert (config.output_dir / "questions_v2.json").exists()


def test_manifest_checksum_and_sources(config):
    write_validated(config, [make_question_dict(qid="q1")])

    manifest = run_export(config, bump=True)

    payload = (config.output_dir / "questions_v1.json").read_text(encoding="utf-8")
    assert manifest["checksum"] == hashlib.sha256(payload.encode()).hexdigest()
    assert manifest["sources"] == [
        {"id": "test_source", "repo": "owner/repo", "license": "MIT"}
    ]
    assert "generatedAt" in manifest


def test_export_without_validated_fails(config):
    with pytest.raises(FileNotFoundError):
        run_export(config)
