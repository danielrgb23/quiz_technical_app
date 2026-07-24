# CI não executa o pipeline automaticamente

## Why

O pipeline de geração de questões (Spec 01) usa a API da Anthropic e tem custo por chamada. Mesmo o job atual de CI só rodando `pytest` (testes offline, sem chamadas reais ao LLM), o dono do projeto quer que a decisão de quando rodar o pipeline — testes ou geração — seja sempre manual e deliberada, nunca disparada automaticamente por push/PR. Isso evita qualquer risco de custo inesperado ou de geração de conteúdo fora do controle do responsável pelo banco de questões.

## What Changes

- O job `pipeline` do GitHub Actions (`.github/workflows/ci.yml`) deixa de rodar automaticamente em `push`/`pull_request`.
- Passa a existir apenas via `workflow_dispatch` (disparo manual pela interface/CLI do GitHub), preservando a possibilidade de rodar os testes do pipeline quando o dono do projeto quiser, sem rodá-los a cada commit.
- Nenhuma mudança no comportamento do pipeline em si: comandos de geração (`generate`, `run`) continuam exigindo execução manual local com `ANTHROPIC_API_KEY`, como já documentado no `pipeline/README.md`.

## Capabilities

### New Capabilities

- `ci-scope-policy`: regra de que o pipeline (testes e, a fortiori, geração) nunca é executado automaticamente pelo CI — apenas manualmente, pelo responsável pelo projeto.

### Modified Capabilities

(nenhuma — decisão de infraestrutura de CI, não altera requisitos de spec-level de nenhuma capability existente)

## Impact

- `.github/workflows/ci.yml`: job `pipeline` movido de trigger automático para `workflow_dispatch`.
- Nenhum impacto no código do pipeline, no app Flutter ou nos artefatos gerados.
