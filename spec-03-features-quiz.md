# Spec 03 — Features do Quiz (modules/quiz + features/quiz_flow)

## Objetivo
Implementar o produto em si sobre a base da Spec 02: sessões de quiz estilo Duolingo (5 alternativas, explicação no erro), progresso, repetição espaçada e gamificação leve.

## Estrutura (seguindo o padrão do boilerplate)
```
packages/
  modules/
    question_bank/        # (Spec 02) dados: questões, progresso, sync
    quiz/                 # lógica de sessão, seleção de questões, SM-2, streak/XP
  features/
    home_flow/            # adaptar: dashboard com tópicos, streak, CTA do dia
    quiz_flow/            # sessão de quiz: pergunta, alternativas, feedback, resumo
    stats_flow/           # estatísticas e revisão de erros
```
Regras do boilerplate mantidas: `quiz` (module) não tem UI e não conhece features; `quiz_flow` não importa outros features; Cubits fazem papel de ViewModel (estado Freezed imutável + métodos de intenção).

## Domínio (modules/quiz)

### Entidades
- `QuizSession` — id, modo, lista de questionIds, índice atual, respostas dadas, iniciadaEm/finalizadaEm
- `Answer` — questionId, selectedIndex, isCorrect, elapsedMs
- `UserStats` — streakDays, xpTotal, porTópico {vistos, acertos, erros}

### Serviços/UseCases (interfaces no module, implementação com repos do question_bank)
- `StartSessionUseCase(mode, {topic, size=10})` → monta a fila de questões
- `AnswerQuestionUseCase` → registra resposta, atualiza progresso local + agenda sync
- `SpacedRepetitionScheduler` → SM-2 simplificado: calcula `nextReviewAt` por questão (erro → intervalo curto; acertos consecutivos → intervalos crescentes 1d/3d/7d/21d)
- `StreakService` → streak diário (sessão completa no dia mantém; timezone do dispositivo)

### Modos de sessão
1. **Por tópico:** N questões do tópico, priorizando não vistas e `nextReviewAt` vencidas.
2. **Revisão:** apenas questões com `nextReviewAt <= now` (qualquer tópico).
3. **Desafio diário:** mix fixo de 10 questões (seed pelo dia — mesma seleção o dia todo), acessível por `/daily`.

## UI (features/quiz_flow)

### Telas e fluxo
1. **Pré-sessão** (via home ou deeplink `/quiz/{topic}`): tópico, quantidade, botão iniciar.
2. **Questão:**
   - Barra de progresso da sessão (x/N) + streak no topo.
   - Enunciado (com suporte a bloco de código monoespaçado — questões técnicas têm snippets).
   - 5 alternativas em cards; seleção única; botão confirmar.
   - **Feedback imediato:** acerto → destaque verde + próxima; erro → alternativa correta destacada, card de **explicação** expandido, botão "entendi" para avançar. Sem punição estilo "vidas" no MVP.
3. **Resumo da sessão:** acertos/N, XP ganho, streak atualizado, lista de erradas com link para rever explicação, CTA "nova sessão".
4. **Stats (features/stats_flow):** streak, XP, desempenho por tópico, lista de questões mais erradas.

### Estados (Freezed, por Cubit)
`QuizSessionState = loading | question(current, progress, selected?) | feedback(answer, explanation) | summary(result) | error`

### Interações
- Voltar no meio da sessão → dialog de confirmação (sessão abandonada conta questões já respondidas no progresso, não no streak).
- `question/{id}` (deeplink) → modo questão única com explicação sempre visível ao responder.
- Report de questão: botão discreto na tela de feedback → grava em `flagged` local + Firestore quando online (alimenta o `data/review/flagged.jsonl` da Spec 01).

## Gamificação (leve, MVP)
- **XP:** +10 acerto, +2 erro (respondeu = aprendeu), bônus +20 sessão completa.
- **Streak:** dias consecutivos com ≥1 sessão completa; aviso visual quando em risco (sem notificação push no MVP).
- Sem ligas/ranking no MVP.

## Analytics (via AnalyticsService do shared)
`session_started {mode, topic}`, `question_answered {topic, level, correct, elapsedMs}`, `session_completed {mode, score}`, `question_flagged {id}`, `streak_incremented {days}`.

## Testes
- Unit: `SpacedRepetitionScheduler` (tabela de casos de intervalos), `StreakService` (virada de dia/timezone), Cubits de sessão (fakes dos repos).
- Widget: smoke do fluxo questão → erro → explicação → resumo.
- Meta: módulos `quiz` com ≥80% de cobertura de lógica.

## Critérios de aceite
1. Sessão por tópico de 10 questões funciona 100% offline (modo avião), com feedback e explicação no erro.
2. Errar uma questão faz ela reaparecer em "Revisão" no dia seguinte; acertá-la 2x seguidas espaça o intervalo.
3. Completar uma sessão em dias consecutivos incrementa o streak; pular um dia zera.
4. Deeplinks `/quiz/{topic}`, `/question/{id}` e `/daily` abrem os fluxos corretos.
5. Desafio diário mostra as mesmas 10 questões em qualquer hora do mesmo dia.
6. Report de questão aparece no Firestore quando online e não se perde quando offline (fila de sync).
7. Eventos de analytics visíveis no DebugView do Firebase (flavor stg).

## Fora de escopo (v2)
Notificações de lembrete, ligas/ranking, login social, bancos de questões em outros idiomas, modo "entrevista simulada" cronometrado.