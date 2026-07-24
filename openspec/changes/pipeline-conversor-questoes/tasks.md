# Tasks — Pipeline de Conversão de Questões

## 1. Setup do projeto

- [x] 1.1 Criar estrutura do pacote `pipeline/` com `__main__.py` (argparse: fetch, parse, generate, validate, export, run) e `pyproject.toml` com dependências (httpx, anthropic, pydantic, python-slugify, pyyaml, python-dotenv, pytest)
- [x] 1.2 Criar `sources.yaml` com as 4 fontes da spec (repos, files, topic_default, license, min_expected_pairs) e `.env.example` com `ANTHROPIC_API_KEY`; `.gitignore` para `data/` e `.env`
- [x] 1.3 Criar módulo `config.py` que carrega e valida `sources.yaml` (falha em fonte sem license) e `.env`

## 2. Fetch

- [x] 2.1 Implementar `fetch.py`: download via raw.githubusercontent.com para `data/raw/<source_id>/`, gravação de `.sha256`, detecção de mudança, tolerância a falha por fonte
- [x] 2.2 Testes unitários do fetch (HTTP mockado): fetch inicial, conteúdo inalterado, conteúdo alterado, fonte inacessível

## 3. Parse

- [x] 3.1 Implementar `parse.py`: heurística de headings configurável por fonte, `raw_answer: null` para perguntas sem corpo, normalização (badges/imagens fora, código preservado), output JSONL
- [x] 3.2 Implementar fallback `min_expected_pairs` (alerta e não sobrescreve parsed anterior)
- [x] 3.3 Testes unitários do parse com fixtures de markdown representando os formatos das 4 fontes

## 4. Generate

- [x] 4.1 Implementar `schema.py` (Pydantic `Question` + taxonomia de tópicos) compartilhado por generate/validate
- [x] 4.2 Implementar `generate.py`: prompt estruturado somente-JSON, id determinístico, skip de ids existentes, retry/backoff (3x), ThreadPoolExecutor(5), `rejected.jsonl`, flag `generated_answer`
- [x] 4.3 Implementar `--dry-run` e `--limit` (contagem de chamadas previstas sem chamar API)
- [x] 4.4 Testes unitários do generate com cliente LLM fake: geração ok, JSON inválido 3x → rejected, idempotência (nenhuma chamada na reexecução), dry-run

## 5. Validate

- [x] 5.1 Implementar `validate.py`: validação via schema Pydantic, rejeições com motivo em `rejected.jsonl`, deduplicação por pergunta normalizada com `duplicates.jsonl`
- [x] 5.2 Testes unitários: questão válida, 5 alternativas exatas, correctIndex fora do range, alternativas duplicadas, explicação vazia, dedup

## 6. Export

- [x] 6.1 Implementar `export.py`: `questions_v<N>.json` com `--bump`, `manifest.json` (version, generatedAt, count, sources com licenças, checksum SHA-256)
- [x] 6.2 Implementar comando `run` (sequência completa, para em falha)
- [x] 6.3 Testes unitários: primeiro export, export sem bump, manifest com checksum válido

## 7. Verificação final

- [x] 7.1 Rodar suíte completa de testes (pytest) verde
- [x] 7.2 Smoke test end-to-end offline: fetch com fixtures locais → parse → generate (LLM fake) → validate → export produz JSON válido
- [x] 7.3 Documentar uso no README do pipeline (comandos, custo estimado, como rodar geração real)
