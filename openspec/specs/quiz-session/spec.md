# quiz-session Specification

## Purpose
TBD - created by archiving change quiz-features. Update Purpose after archive.
## Requirements
### Requirement: Modos de sessão de quiz
`StartSessionUseCase` SHALL montar a fila de questões de acordo com o modo: **por tópico** (N questões do tópico informado, priorizando não vistas e com `nextReviewAt` vencida), **revisão** (apenas questões com `nextReviewAt <= now`, de qualquer tópico) e **desafio diário** (10 questões fixas, mesma seleção durante todo o dia).

#### Scenario: Sessão por tópico
- **WHEN** `StartSessionUseCase` é chamado com `mode: topic`, `topic: "flutter"`, `size: 10`
- **THEN** a sessão é montada com até 10 questões do tópico `flutter`, priorizando as não vistas e as vencidas para revisão

#### Scenario: Sessão de revisão sem questões vencidas
- **WHEN** `StartSessionUseCase` é chamado com `mode: review` e nenhuma questão tem `nextReviewAt <= now`
- **THEN** a sessão é montada vazia (0 questões), sem erro

#### Scenario: Desafio diário estável no dia
- **WHEN** `StartSessionUseCase` é chamado com `mode: daily` em horários diferentes do mesmo dia
- **THEN** a lista das 10 questões selecionadas é idêntica em todas as chamadas

#### Scenario: Desafio diário muda no dia seguinte
- **WHEN** `StartSessionUseCase` é chamado com `mode: daily` em dois dias diferentes
- **THEN** as seleções podem diferir (seed derivado da data)

### Requirement: Registro de resposta
`AnswerQuestionUseCase` SHALL registrar a resposta do usuário (questionId, selectedIndex, isCorrect, elapsedMs), atualizar o progresso local via `ProgressRepository` e agendar a próxima revisão via `SpacedRepetitionScheduler`.

#### Scenario: Resposta correta
- **WHEN** o usuário responde corretamente a uma questão
- **THEN** o progresso é salvo com `correctCount` incrementado e `nextReviewAt` recalculado pelo scheduler

#### Scenario: Resposta incorreta
- **WHEN** o usuário responde incorretamente a uma questão
- **THEN** o progresso é salvo com `wrongCount` incrementado e `nextReviewAt` definido para o intervalo curto (revisão no dia seguinte)

### Requirement: Sessão abandonada
Se o usuário sair no meio de uma sessão, as questões já respondidas SHALL contar no progresso; a sessão abandonada MUST NOT contar para o streak do dia.

#### Scenario: Abandono no meio da sessão
- **WHEN** o usuário responde 3 de 10 questões e sai sem concluir
- **THEN** o progresso das 3 respondidas é mantido e o streak do dia não é incrementado por essa sessão

