# ci-scope-policy

## ADDED Requirements

### Requirement: Pipeline não roda automaticamente no CI
O job `pipeline` do CI MUST NOT ser disparado por `push` ou `pull_request`; SHALL estar disponível apenas via disparo manual (`workflow_dispatch`).

#### Scenario: Push para main
- **WHEN** um commit é enviado para `main` ou aberto um pull request
- **THEN** o job `pipeline` não é executado; apenas os jobs `app` (e `build-android`, se aplicável) rodam

#### Scenario: Disparo manual
- **WHEN** o dono do projeto dispara o workflow manualmente pela interface ou CLI do GitHub
- **THEN** o job `pipeline` executa `pytest` normalmente

### Requirement: Geração de questões permanece exclusivamente manual e local
Os comandos `generate` e `run` do pipeline MUST NOT ser invocados por nenhum job de CI, automático ou manual; permanecem uma ação local do responsável pelo banco de questões, com `ANTHROPIC_API_KEY` própria.

#### Scenario: Nenhum job chama generate/run
- **WHEN** o conteúdo de `.github/workflows/ci.yml` é inspecionado
- **THEN** nenhum job contém `python -m pipeline generate` ou `python -m pipeline run`
