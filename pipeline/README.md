# Pipeline de Questões (Spec 01)

Baixa perguntas de entrevista mobile de repos open source no GitHub, converte cada par
pergunta/resposta em questão de múltipla escolha (5 alternativas + explicação) via LLM
e exporta um banco JSON versionado para o app Flutter.

## Setup

```bash
cd pipeline
python3 -m venv .venv
.venv/bin/pip install -e ".[dev]"
cp .env.example .env   # preencher ANTHROPIC_API_KEY
```

## Comandos

```bash
.venv/bin/python -m pipeline fetch          # baixa/atualiza fontes (cache por hash)
.venv/bin/python -m pipeline parse          # markdown -> pares Q/A em data/parsed/
.venv/bin/python -m pipeline generate       # Q/A -> MCQ via LLM (idempotente)
.venv/bin/python -m pipeline validate       # valida schema e deduplica
.venv/bin/python -m pipeline export --bump  # gera data/output/questions_v<N>.json + manifest
.venv/bin/python -m pipeline run            # tudo em sequência
```

### Estimar custo antes de gerar

```bash
.venv/bin/python -m pipeline generate --dry-run            # conta as chamadas previstas
.venv/bin/python -m pipeline generate --dry-run --limit 10 # limita o lote
```

Cada questão custa 1 chamada ao modelo (padrão `claude-opus-4-8`, configurável via
`PIPELINE_MODEL` no `.env`). A geração é idempotente: ids determinísticos por pergunta,
questões já geradas em `data/generated/` são puladas — reexecutar sem mudanças nas
fontes não faz nenhuma chamada.

### Geração real (primeira vez)

```bash
.venv/bin/python -m pipeline generate --limit 10   # lote pequeno para revisar qualidade
# revisar data/generated/*.json manualmente, então:
.venv/bin/python -m pipeline generate              # o restante
.venv/bin/python -m pipeline validate
.venv/bin/python -m pipeline export --bump
```

## Estrutura de dados

```
data/
  raw/<source_id>/         # markdown baixado + .sha256 (cache)
  parsed/<source_id>.jsonl # pares {source_id, raw_question, raw_answer, topic_hint}
  generated/<id>.json      # uma questão por arquivo (idempotência)
  validated/questions.jsonl
  review/rejected.jsonl    # falhas de geração/validação com motivo
  review/duplicates.jsonl  # colisões de pergunta normalizada
  output/questions_v<N>.json + manifest.json
```

O `manifest.json` traz `{version, generatedAt, count, sources[] (com licenças), checksum}`;
o checksum SHA-256 é validado pelo app na importação (Spec 02).

## Fontes

Declaradas em `sources.yaml` — cada fonte exige o campo `license` (conferir o LICENSE do
repo antes de adicionar). Campos por fonte: `parser` (heurística), `min_heading_level`,
`list_questions` (perguntas em lista sem resposta → o LLM gera a resposta com flag
`generated_answer: true`) e `min_expected_pairs` (se a extração cair abaixo, o parsed
anterior é preservado — proteção contra mudança de estrutura do repo).

## Testes

```bash
.venv/bin/python -m pytest
```

38 testes, todos offline (HTTP mockado + LLM fake), incluindo smoke end-to-end.
