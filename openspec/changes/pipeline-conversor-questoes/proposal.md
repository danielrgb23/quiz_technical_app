# Pipeline de Download e Conversão de Perguntas

## Why

O app de quiz (Specs 02 e 03) precisa de um banco de questões de múltipla escolha de qualidade sobre entrevistas mobile, mas o conteúdo disponível em repositórios open source está em formato pergunta/resposta livre em markdown. É necessário um pipeline automatizado que transforme esse conteúdo em MCQs validadas e versionadas, prontas para consumo offline pelo app Flutter.

## What Changes

- Novo pacote Python `pipeline` com CLI (`python -m pipeline <comando>`).
- Etapa `fetch`: download de arquivos markdown de repos GitHub via `raw.githubusercontent.com`, com cache por hash em `data/raw/<source_id>/`.
- Etapa `parse`: extração de pares pergunta/resposta do markdown por heurística de headings, com normalização; output em `data/parsed/<source_id>.jsonl`.
- Etapa `generate`: conversão de cada par Q/A em questão de múltipla escolha (5 alternativas + explicação) via LLM (Anthropic), com ids determinísticos e idempotência.
- Etapa `validate`: validação de schema via Pydantic e deduplicação por pergunta normalizada.
- Etapa `export`: geração de `data/output/questions_v<N>.json` + `manifest.json` versionado com checksum e atribuição de licenças.
- Comando `run` que executa todas as etapas em sequência; flags `--dry-run` e `--limit` para estimar custo.
- Configuração via `.env` (`ANTHROPIC_API_KEY`) e `sources.yaml` (lista de repos com licenças).

## Capabilities

### New Capabilities

- `source-fetching`: download e cache de arquivos markdown das fontes declaradas em `sources.yaml`, reprocessando apenas conteúdo alterado.
- `qa-parsing`: extração de pares pergunta/resposta de markdown com heurísticas por fonte e normalização de conteúdo.
- `mcq-generation`: geração de questões de múltipla escolha via LLM com ids determinísticos, retry/backoff e idempotência.
- `question-validation`: validação de schema das questões e deduplicação semântica simples com fila de revisão manual.
- `bank-export`: export do banco JSON versionado com manifest (versão, contagem, fontes, licenças, checksum).

### Modified Capabilities

(nenhuma — projeto novo, sem specs existentes)

## Impact

- Novo diretório `pipeline/` (código Python) e `data/` (artefatos gerados, fora do versionamento exceto output).
- Dependências novas: `httpx`, `anthropic`, `pydantic`, `python-slugify`, `pyyaml`, `python-dotenv`.
- Custo de API: ~1 chamada de LLM por questão gerada (mitigado por idempotência e `--dry-run`).
- O output `questions_v<N>.json` é contrato consumido pelo app Flutter (Spec 02, módulo `question_bank`).
