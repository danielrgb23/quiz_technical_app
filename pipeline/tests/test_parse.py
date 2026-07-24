import json

from pipeline.config import Source
from pipeline.parse import parse_markdown, run_parse

MARKDOWN_WITH_ANSWERS = """\
# Flutter Interview Questions

### O que é um StatelessWidget?

Um widget imutável cuja configuração não muda ao longo do tempo.

```dart
class MyWidget extends StatelessWidget {}
```

### Qual a diferença entre hot reload e hot restart?

Hot reload injeta código atualizado preservando o estado; hot restart reinicia o app.

### Contents

Isto é um índice, não uma pergunta.
"""


def test_parse_headings_with_answers(source):
    pairs = parse_markdown(MARKDOWN_WITH_ANSWERS, source)
    assert len(pairs) == 2
    assert pairs[0]["raw_question"] == "O que é um StatelessWidget?"
    assert "imutável" in pairs[0]["raw_answer"]
    assert "```dart" in pairs[0]["raw_answer"]
    assert pairs[0]["topic_hint"] == "flutter"
    assert pairs[1]["raw_question"].startswith("Qual a diferença")


def test_parse_list_questions_without_answers():
    source = Source(
        id="mindorks",
        repo="o/r",
        files=["README.md"],
        topic_default="android",
        license="Apache-2.0",
        list_questions=True,
        min_expected_pairs=1,
    )
    md = """\
# Android Questions

* What is an Activity?
* What is a Service?
- **What is a ContentProvider?**
* Not a question item
"""
    pairs = parse_markdown(md, source)
    assert [p["raw_question"] for p in pairs] == [
        "What is an Activity?",
        "What is a Service?",
        "What is a ContentProvider?",
    ]
    assert all(p["raw_answer"] is None for p in pairs)


def test_parse_normalization_removes_badges_keeps_code(source):
    md = """\
### O que é null safety?

![badge](https://img.shields.io/badge.svg)
Veja a [documentação](https://dart.dev) oficial.

```dart
int? x = null;
```
"""
    pairs = parse_markdown(md, source)
    answer = pairs[0]["raw_answer"]
    assert "img.shields.io" not in answer
    assert "documentação" in answer
    assert "https://dart.dev" not in answer
    assert "int? x = null;" in answer


def test_parse_empty_body_yields_null_answer(source):
    md = "### Pergunta sem resposta?\n\n### Outra pergunta?\n\nCom resposta.\n"
    pairs = parse_markdown(md, source)
    assert pairs[0]["raw_answer"] is None
    assert pairs[1]["raw_answer"] == "Com resposta."


def test_run_parse_fallback_keeps_previous(config, source, tmp_path):
    source.min_expected_pairs = 5
    raw_dir = config.raw_dir / source.id
    raw_dir.mkdir(parents=True)
    (raw_dir / "README.md").write_text(MARKDOWN_WITH_ANSWERS)

    parsed_file = config.parsed_dir / f"{source.id}.jsonl"
    config.parsed_dir.mkdir(parents=True)
    previous = json.dumps({"source_id": source.id, "raw_question": "old?",
                           "raw_answer": "old", "topic_hint": "flutter"})
    parsed_file.write_text(previous + "\n")

    counts = run_parse(config)

    assert counts[source.id] == -1
    assert parsed_file.read_text().strip() == previous


def test_run_parse_writes_jsonl(config, source):
    raw_dir = config.raw_dir / source.id
    raw_dir.mkdir(parents=True)
    (raw_dir / "README.md").write_text(MARKDOWN_WITH_ANSWERS)

    counts = run_parse(config)

    assert counts[source.id] == 2
    lines = (config.parsed_dir / f"{source.id}.jsonl").read_text().splitlines()
    assert len(lines) == 2
    assert json.loads(lines[0])["source_id"] == source.id
