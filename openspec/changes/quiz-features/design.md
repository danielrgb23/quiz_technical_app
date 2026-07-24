# Design — Features do Quiz

## Context

Sobre a fundação da Spec 02 (offline-first, `question_bank` com drift, deeplinks, Firebase atrás de interfaces), a Spec 03 implementa o produto: sessões de quiz com feedback imediato, repetição espaçada e gamificação leve. Regras de dependência do boilerplate continuam valendo: `quiz` (module) não tem UI e não conhece features; `quiz_flow` não importa outros features; Cubits são o ViewModel (MVVM).

## Goals / Non-Goals

**Goals:**
- Sessão de quiz 100% offline (modo avião), com feedback e explicação no erro.
- SM-2 simplificado funcionando de forma verificável (tabela de casos).
- Streak diário correto por timezone do dispositivo.
- Deeplinks da Spec 02 abrindo o fluxo real.

**Non-Goals:**
- Notificações de lembrete, ligas/ranking, login social, bancos multilíngue, modo cronometrado (v2, conforme spec-03).

## Decisions

1. **`modules/quiz` depende de `question_bank` via as interfaces já existentes** (`QuestionRepository`, `ProgressRepository`) — não acessa drift diretamente. `AnswerQuestionUseCase` escreve progresso via `ProgressRepository.save`, que já cuida de persistência local + fila de sync (Spec 02); o module `quiz` não reimplementa isso.
2. **SM-2 simplificado com 4 níveis de intervalo:** erro → revisão no dia seguinte (1d); acerto consecutivo avança 1d→3d→7d→21d; erro em qualquer ponto reseta para 1d. Implementado como função pura `SpacedRepetitionScheduler.nextInterval(currentStreak, wasCorrect)` para ser trivialmente testável por tabela de casos.
3. **`StreakService` calcula streak a partir de `lastSeenAt`/histórico de sessões completas, não de um contador incremental ingênuo:** evita drift em caso de reinstalação/multi-dispositivo (mesma fonte de verdade que já existe em `progress`/sessões persistidas). Vira dia = comparação de datas no timezone local do dispositivo (`DateTime.now()` local, não UTC).
4. **`QuizSession` é efêmera em memória (Cubit), não persistida como entidade própria no drift:** cada resposta já persiste via `ProgressRepository`; a sessão em si (fila de questões, índice atual) não precisa sobreviver a um kill do processo no MVP — reabrir a rota recomeça a sessão. Simplifica o modelo e evita uma tabela `sessions` extra sem requisito que a justifique.
5. **Desafio diário com seed determinístico:** `seed = date.year*10000 + date.month*100 + date.day`; `Random(seed)` seleciona as 10 questões a partir do banco completo, garantindo mesma seleção em qualquer hora do mesmo dia (critério de aceite 5).
6. **`quiz_flow` reaproveita o `_ContentGuard` e o padrão de página da Spec 02** (`quiz_deeplink_pages.dart` é substituído, não duplicado) — as rotas do router passam a apontar para as páginas novas de `quiz_flow`.
7. **Report de questão usa a mesma fila `pending_sync` do `question_bank`** com um novo tipo de payload (`flagged`), evitando criar uma segunda fila de sync paralela.
8. **Estado por Cubit + Freezed:** `QuizSessionState` como union (`loading | question | feedback | summary | error`), consumido só pela View; sem métodos de navegação na View além dos disparados pelo Cubit.

## Risks / Trade-offs

- [SM-2 "simplificado" pode não bater com SM-2 "de livro"] → aceito conforme a spec ("simplificado"); documentado na tabela de casos do teste, não é o SM-2 completo com fator de facilidade.
- [Streak por timezone do dispositivo pode gerar edge cases perto de meia-noite/mudança de fuso] → cobrir explicitamente em teste (virada de dia, viagem de fuso não é requisito do MVP).
- [Seed do desafio diário pode colidir/repetir se o banco tiver poucas questões] → aceitável no MVP com >200 questões esperadas (Spec 01); não é tratado como erro.

## Migration Plan

Aditivo sobre a Spec 02; nenhuma migração de dados. Rollback = remover os pacotes novos e reverter as rotas do router para os placeholders.

## Open Questions

Nenhuma pendência bloqueante — segue direto para especificação.
