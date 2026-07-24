# Tasks — CI não executa o pipeline automaticamente

## 1. Ajuste do workflow

- [x] 1.1 Adicionar `on.workflow_dispatch` ao workflow e remover o job `pipeline` do trigger implícito de `push`/`pull_request` (ex.: mover para um workflow separado disparado só por `workflow_dispatch`, ou condicionar o job a `github.event_name == 'workflow_dispatch'`)
- [x] 1.2 Confirmar que os jobs `app` e `build-android` continuam disparando normalmente em `push`/`pull_request`/tag
- [x] 1.3 Validar a sintaxe do workflow (`gh workflow view` ou revisão manual do YAML)

## 2. Verificação final

- [ ] 2.1 Confirmar no histórico do GitHub Actions que um push subsequente não dispara o job `pipeline`
