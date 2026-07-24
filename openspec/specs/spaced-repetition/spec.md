# spaced-repetition Specification

## Purpose
TBD - created by archiving change quiz-features. Update Purpose after archive.
## Requirements
### Requirement: Cálculo de próximo intervalo de revisão (SM-2 simplificado)
`SpacedRepetitionScheduler` SHALL calcular `nextReviewAt` por questão: uma resposta incorreta SHALL definir intervalo curto (revisão no dia seguinte); acertos consecutivos SHALL espaçar o intervalo pela sequência 1d → 3d → 7d → 21d.

#### Scenario: Primeiro acerto
- **WHEN** uma questão nunca vista antes é respondida corretamente
- **THEN** `nextReviewAt` é definido para 1 dia a partir de agora

#### Scenario: Acertos consecutivos espaçam o intervalo
- **WHEN** uma questão é acertada 2 vezes seguidas (após já ter intervalo de 1 dia)
- **THEN** o intervalo avança para 3 dias; um terceiro acerto consecutivo avança para 7 dias, e um quarto para 21 dias

#### Scenario: Erro reseta o intervalo
- **WHEN** uma questão com intervalo espaçado (ex.: 7 dias) é respondida incorretamente
- **THEN** `nextReviewAt` volta para o intervalo curto (1 dia), independentemente do histórico de acertos anterior

### Requirement: Reaparecimento em Revisão
Uma questão errada SHALL reaparecer no modo Revisão no dia seguinte (quando `nextReviewAt <= now`).

#### Scenario: Errar e revisar no dia seguinte
- **WHEN** uma questão é errada hoje e o modo Revisão é aberto no dia seguinte
- **THEN** essa questão aparece na fila de revisão

