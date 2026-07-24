# Spec 01 — Script de Download e Conversão de Perguntas

## Objetivo
Pipeline que baixa perguntas de entrevista mobile de repositórios open source no GitHub, converte cada par pergunta/resposta em uma questão de múltipla escolha (5 alternativas) com explicação, e gera um banco de dados JSON versionado para consumo pelo app Flutter.

## Escopo
- **Inclui:** download dos repos, parsing de markdown, geração de MCQs via LLM, validação de schema, deduplicação, export em JSON.
- **Não inclui:** UI, sincronização com Firebase (o upload é etapa manual/CI posterior), tradução (v2).

## Stack
- **Linguagem:** Python 3.11+ (alternativa: Dart CLI, se quiser manter stack única — a spec é agnóstica)
- **Dependências:** `requests`/`httpx`, `anthropic` (ou `openai`), `pydantic` (validação de schema), `python-slugify`
- **Config:** `.env` com `ANTHROPIC_API_KEY`; `sources.yaml` com a lista de repos

## Fontes (sources.yaml)
```yaml
sources:
  - id: mindorks_android
    repo: MindorksOpenSource/android-interview-questions
    files: [README.md]
    topic_default: android
    license: Apache-2.0
  - id: codexhub_flutter
    repo: thecodexhub/flutter-interview-questions
    files: [README.md]
    topic_default: flutter
    license: MIT
  - id: onthecodepath_ios
    repo: onthecodepath/iOS-Interview-Questions
    files: [README.md]
    topic_default: ios
    license: MIT
  - id: weeebox_system_design
    repo: weeeBox/mobile-system-design
    files: [README.md]
    topic_default: system_design
    license: MIT
```
> Antes de adicionar uma fonte, conferir o arquivo LICENSE do repo e registrar no campo `license`. Manter atribuição no JSON final.

## Pipeline (etapas)

### 1. Download (`fetch`)
- Baixar os arquivos markdown via `raw.githubusercontent.com` (sem clone completo).
- Cache local em `data/raw/<source_id>/` com hash do conteúdo — só reprocessar o que mudou.

### 2. Parsing (`parse`)
- Extrair pares pergunta/resposta do markdown. Heurísticas por fonte:
  - Headings (`###`, `####`) como pergunta; corpo até o próximo heading como resposta.
  - Listas de perguntas sem resposta (caso Mindorks) → marcar como `answer: null` (o LLM gera a resposta na etapa seguinte, com flag `generated_answer: true`).
- Normalizar: remover badges, imagens, links quebrados; preservar blocos de código.
- Output: `data/parsed/<source_id>.jsonl` com `{source_id, raw_question, raw_answer, topic_hint}`.

### 3. Geração de MCQ (`generate`)
- Para cada par, chamar o LLM com prompt estruturado pedindo **somente JSON**:
  - Reescrever a pergunta de forma autocontida.
  - 1 alternativa correta + 4 distratores plausíveis (erros conceituais comuns, não absurdos).
  - Explicação de 2–5 frases: por que a correta está certa e por que os distratores erram.
  - Classificar `topic` (taxonomia abaixo) e `level` (1=júnior, 2=pleno, 3=sênior).
- Batching: 1 questão por chamada (qualidade > custo) com retry/backoff; paralelismo limitado (5 workers).
- Idempotência: `id` determinístico = `slug(source_id + raw_question)[hash:8]`; pular ids já gerados.

### 4. Validação (`validate`)
- Schema via Pydantic (abaixo). Rejeitar: menos/mais de 5 alternativas, `correctIndex` fora de 0–4, alternativas duplicadas, explicação vazia.
- Deduplicação semântica simples: normalizar pergunta (lowercase, sem pontuação) e comparar; colisões vão para `data/review/duplicates.jsonl` para revisão manual.

### 5. Export (`export`)
- `data/output/questions_v<N>.json` + `manifest.json` com `{version, generatedAt, count, sources[], checksum}`.
- O app consome esse arquivo (asset local no MVP; Firebase Storage/Firestore depois).

## Schema da questão
```json
{
  "id": "mindorks_android_a1b2c3d4",
  "source": "mindorks_android",
  "topic": "coroutines",
  "level": 2,
  "question": "O que acontece com uma coroutine quando seu Job pai é cancelado?",
  "options": ["...", "...", "...", "...", "..."],
  "correctIndex": 2,
  "explanation": "...",
  "tags": ["kotlin", "concurrency"],
  "language": "pt-BR"
}
```

## Taxonomia de tópicos
`flutter`, `dart`, `android`, `kotlin`, `ios`, `swift`, `architecture` (MVVM, Clean, patterns), `state_management`, `system_design`, `testing`, `performance`, `concurrency`, `networking`, `storage`.

## CLI
```
python -m pipeline fetch          # baixa/atualiza fontes
python -m pipeline parse          # markdown -> pares Q/A
python -m pipeline generate       # Q/A -> MCQ (usa LLM)
python -m pipeline validate       # valida e deduplica
python -m pipeline export --bump  # gera JSON versionado
python -m pipeline run            # tudo em sequência
```

## Critérios de aceite
1. Rodar `run` do zero produz um `questions_v1.json` válido com ≥ 200 questões distribuídas entre pelo menos 4 tópicos.
2. Rodar `run` de novo sem mudanças nas fontes não faz nenhuma chamada ao LLM (idempotência).
3. 100% das questões passam no schema; nenhuma com alternativas duplicadas.
4. Amostragem manual de 20 questões: ≥ 18 com correta de fato correta e distratores plausíveis.
5. `manifest.json` lista todas as fontes com suas licenças.

## Riscos e mitigação
- **Qualidade dos distratores:** revisar amostras por lote; manter arquivo `data/review/flagged.jsonl` para questões marcadas no app (feature futura de "reportar questão").
- **Custo de API:** ~1 chamada/questão; estimar antes com `--dry-run --limit 10`.
- **Repos mudam de estrutura:** parsing por heurística com fallback: se extração < X pares esperados, alertar e não sobrescrever cache.
