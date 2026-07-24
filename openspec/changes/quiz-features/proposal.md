# Features do Quiz (modules/quiz + features/quiz_flow)

## Why

A Spec 02 entrega a fundação (Firebase, offline-first, deeplinks) mas nenhuma tela de quiz de fato. É hora de implementar o produto: sessões de quiz estilo Duolingo sobre o banco de questões já embarcado, com progresso, repetição espaçada (SM-2 simplificado) e gamificação leve (XP/streak), consumindo as interfaces `QuestionRepository`/`ProgressRepository` do módulo `question_bank` (Spec 02).

## What Changes

- Novo módulo `packages/modules/quiz` (sem UI): entidades `QuizSession`, `Answer`, `UserStats`; use cases `StartSessionUseCase`, `AnswerQuestionUseCase`; `SpacedRepetitionScheduler` (SM-2 simplificado); `StreakService`.
- Três modos de sessão: por tópico, revisão (questões com `nextReviewAt` vencida) e desafio diário (10 questões fixas por seed do dia, `/daily`).
- Nova feature `packages/features/quiz_flow`: telas de pré-sessão, questão (progresso, enunciado com suporte a código, 5 alternativas, feedback imediato), resumo da sessão. Cubits como ViewModel (estado Freezed imutável).
- Nova feature `packages/features/stats_flow`: streak, XP, desempenho por tópico, questões mais erradas.
- Adaptação de `packages/features/home_flow`: dashboard com tópicos, streak e CTA do desafio diário (substituindo o conteúdo de exemplo do boilerplate).
- Deeplinks `/quiz/{topic}`, `/question/{id}`, `/daily` (rotas já existentes na Spec 02) passam a abrir o fluxo real de quiz em vez do placeholder.
- Report de questão (botão na tela de feedback) grava em fila local e sincroniza com Firestore quando online, reaproveitando a fila de sync da Spec 02.
- Eventos de analytics via `AnalyticsService` (interface já existente, Spec 02): `session_started`, `question_answered`, `session_completed`, `question_flagged`, `streak_incremented`.

## Capabilities

### New Capabilities

- `quiz-session`: modelagem de sessão de quiz (entidades, modos, use cases de iniciar/responder).
- `spaced-repetition`: agendamento de revisão por questão via SM-2 simplificado.
- `streak-gamification`: streak diário e XP.
- `quiz-flow-ui`: telas de sessão de quiz (pré-sessão, questão, feedback, resumo).
- `stats-flow-ui`: tela de estatísticas (streak, XP, desempenho, erros frequentes).
- `question-report`: report de questão com fila de sync offline-first.

### Modified Capabilities

(nenhuma — a capability `deeplinks` da Spec 02 ainda não foi arquivada em `openspec/specs/`; a troca das telas placeholder pelo fluxo real de `quiz_flow` é um detalhe de implementação das rotas já declaradas, não uma mudança de requisito de spec)

## Impact

- Novo pacote `packages/modules/quiz` e novas features `quiz_flow`, `stats_flow`.
- `home_flow` adaptado (dashboard); páginas placeholder de deeplink da Spec 02 (`quiz_deeplink_pages.dart`) substituídas pelas telas reais de `quiz_flow`.
- Dependência de `question_bank` (Spec 02) para dados; de `shared`/`core` (Spec 02) para analytics e connectivity.
- Sem novas dependências de pacotes externos além de `freezed`/`flutter_bloc` (já presentes no boilerplate).
