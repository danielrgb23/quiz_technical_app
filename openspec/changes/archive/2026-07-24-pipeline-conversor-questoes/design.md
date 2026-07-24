# Design — Pipeline de Conversão de Questões

## Context

O pipeline é um projeto Python novo, sem código existente. Ele transforma markdown de 4 repos GitHub (spec-01-conversor.md lista as fontes e licenças) em um banco JSON de MCQs consumido pelo app Flutter. Roda localmente na máquina do dev; o upload para Firebase é etapa manual posterior. A geração usa a API da Anthropic e tem custo por chamada, então idempotência e dry-run são requisitos de primeira classe.

## Goals / Non-Goals

**Goals:**
- Pipeline reexecutável: cada etapa lê o output da anterior em disco e só reprocessa o que mudou.
- Idempotência na etapa cara (generate): id determinístico por questão, ids já gerados são pulados.
- Banco final 100% validado por schema, sem duplicatas, com atribuição de licença por fonte.
- CLI simples: `fetch`, `parse`, `generate`, `validate`, `export`, `run`, com `--dry-run` e `--limit`.

**Non-Goals:**
- UI, upload para Firebase, tradução de conteúdo (v2).
- Deduplicação semântica sofisticada (embeddings) — apenas normalização textual no MVP.

## Decisions

1. **Python 3.11+ com layout `pipeline/` como pacote executável** (`python -m pipeline`). Alternativa Dart CLI descartada: o ecossistema Python (pydantic, httpx, anthropic) reduz o custo de implementação e o pipeline não roda no app.
2. **Etapas desacopladas por arquivos em `data/`** (`raw/` → `parsed/` → `generated/` → `validated/` → `output/`). Cada etapa é uma função pura de diretório para diretório, o que permite rodar/depurar etapas isoladas. Alternativa (pipeline em memória de ponta a ponta) descartada por dificultar retomada após falha no meio da geração.
3. **Cache de fetch por hash SHA-256 do conteúdo** gravado em `data/raw/<source_id>/<file>.sha256`. Se o hash baixado for igual, as etapas seguintes podem pular a fonte. Sem ETags/If-None-Match no MVP (raw.githubusercontent.com nem sempre respeita).
4. **Parsing por heurística de headings com config por fonte.** Cada fonte declara em `sources.yaml` um `parser` (`headings` padrão) e parâmetros (`min_heading_level`). Perguntas sem resposta viram `raw_answer: null` e serão respondidas pelo LLM (`generated_answer: true`). Fallback de segurança: se uma fonte extrair menos pares que `min_expected_pairs`, a etapa alerta e não sobrescreve o parsed anterior.
5. **Geração: 1 questão por chamada, JSON estruturado.** Prompt pede somente JSON; parse com retry (até 3 tentativas com backoff exponencial). Paralelismo com `ThreadPoolExecutor(max_workers=5)`. Modelo configurável via env (`PIPELINE_MODEL`, default um modelo Claude atual). Id determinístico: `f"{source_id}_{sha1(slug(source_id + raw_question))[:8]}"` — estável entre execuções.
6. **Validação com Pydantic v2** (`Question` model): exatamente 5 alternativas, `correctIndex` 0–4, alternativas únicas, explicação não vazia, `topic` na taxonomia, `level` 1–3. Rejeitadas vão para `data/review/rejected.jsonl` com o motivo; duplicatas por pergunta normalizada vão para `data/review/duplicates.jsonl`.
7. **Export versionado com bump manual** (`--bump` incrementa; sem bump regrava a versão corrente). `manifest.json` contém `{version, generatedAt, count, sources[{id, repo, license}], checksum}` onde checksum é SHA-256 do arquivo de questões — o app valida na importação (Spec 02).
8. **Sem framework de CLI pesado**: `argparse` da stdlib. Alternativas (click/typer) descartadas para minimizar dependências.

## Risks / Trade-offs

- [Qualidade de distratores ruim] → amostragem manual por lote (critério de aceite 4); arquivo `data/review/flagged.jsonl` preparado para o report de questões vindo do app.
- [Custo de API acima do esperado] → `--dry-run --limit N` imprime contagem de chamadas previstas sem chamar o LLM; idempotência evita retrabalho.
- [Repos mudam de estrutura e o parser quebra] → limiar `min_expected_pairs` por fonte; falha ruidosa sem sobrescrever cache bom.
- [LLM devolve JSON inválido] → retry com mensagem de correção; após 3 falhas a questão vai para `rejected.jsonl` e o pipeline continua.
- [Rate limit da API] → backoff exponencial com jitter; paralelismo limitado a 5 workers.

## Migration Plan

Projeto novo — sem migração. Rollback = apagar `data/` e reexecutar.

## Open Questions

- Volume real de pares extraíveis por fonte (define se a meta de ≥200 questões precisa de fontes extras) — resolvido empiricamente na primeira execução de `parse`.
