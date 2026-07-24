# Design — CI não executa o pipeline automaticamente

## Context

`.github/workflows/ci.yml` (criado na Spec 02) tem hoje três jobs: `pipeline` (pytest do script Python), `app` (make ci do monorepo Flutter) e `build-android` (só em tags). O job `pipeline` roda em todo `push`/`pull_request`, junto com `app`. O pipeline em si nunca chama o LLM em CI (`pytest` testa fetch/parse/validate/export com HTTP mockado e LLM fake), mas o dono do projeto prefere que mesmo essa execução automática não aconteça — a decisão de rodar o pipeline (testar ou gerar) deve ser sempre dele.

## Goals / Non-Goals

**Goals:**
- CI nunca dispara nada relacionado ao pipeline em `push`/`pull_request`.
- O responsável pelo projeto ainda consegue rodar os testes do pipeline via CI quando quiser (não é uma remoção, é uma restrição de trigger).

**Non-Goals:**
- Não altera o pipeline em si, nem seus critérios de aceite (Spec 01).
- Não impede execução local de `pytest` pelo desenvolvedor.

## Decisions

1. **`workflow_dispatch` em vez de remover o job.** Trocar o trigger do job `pipeline` de implícito (herda `on: push/pull_request` do workflow) para `workflow_dispatch` exclusivo, adicionando um `on.workflow_dispatch` ao workflow. Isso preserva a suíte de testes como ferramenta disponível sob demanda (ex.: após uma mudança grande no código do pipeline) sem rodar a cada commit. Alternativa descartada: remover o job inteiramente — perderia a verificação automatizada disponível para quando o dono do projeto quiser usá-la.
2. **Jobs `app` e `build-android` não mudam.** A regra é específica do pipeline de geração de questões; a fundação Flutter continua com CI automático normal.

## Risks / Trade-offs

- [Regressões no código do pipeline passam sem detecção automática em PRs] → aceito conforme pedido explícito do dono do projeto; mitigado por rodar `pytest` localmente antes de commitar (já documentado no `pipeline/README.md`) e pelo dispatch manual quando desejado.

## Migration Plan

Mudança apenas no workflow de CI; nenhuma migração de dados ou código necessária.

## Open Questions

Nenhuma.
