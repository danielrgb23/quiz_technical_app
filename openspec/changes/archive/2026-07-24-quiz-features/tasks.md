# Tasks — Features do Quiz

## 1. Módulo quiz (domínio, sem UI)

- [x] 1.1 Criar pacote `packages/modules/quiz` (entidades `QuizSession`, `Answer`, `UserStats` via Freezed)
- [x] 1.2 Implementar `SpacedRepetitionScheduler` (SM-2 simplificado: erro → 1d; acertos consecutivos → 1d/3d/7d/21d)
- [x] 1.3 Implementar `StreakService` (streak por timezone local, a partir de sessões completas persistidas)
- [x] 1.4 Implementar `StartSessionUseCase` (modos: topic, review, daily com seed determinístico pela data)
- [x] 1.5 Implementar `AnswerQuestionUseCase` (grava resposta via `ProgressRepository`, aciona o scheduler, calcula XP)
- [x] 1.6 DI do módulo (`quiz_module_di.dart` + `@module` com fakes onde aplicável)
- [x] 1.7 Testes unitários: tabela de casos do `SpacedRepetitionScheduler`; `StreakService` (dias consecutivos, dia pulado, mesmo dia); `StartSessionUseCase` por modo; `AnswerQuestionUseCase` (XP, progresso)

## 2. Feature quiz_flow (UI)

- [x] 2.1 Criar pacote `packages/features/quiz_flow`; `QuizSessionCubit` com estado Freezed (`loading | question | feedback | summary | error`)
- [x] 2.2 Tela de pré-sessão (tópico, quantidade, iniciar)
- [x] 2.3 Tela de questão: progresso x/N, streak, enunciado com suporte a bloco de código, 5 alternativas, botão confirmar
- [x] 2.4 Feedback imediato: acerto (destaque verde + avança) e erro (alternativa correta destacada + explicação expandida + "entendi")
- [x] 2.5 Tela de resumo: acertos/N, XP, streak, lista de erradas com link para explicação, CTA nova sessão
- [x] 2.6 Modo questão única (`/question/{id}`): explicação sempre visível ao responder
- [x] 2.7 Diálogo de confirmação ao voltar no meio da sessão
- [x] 2.8 Botão de report na tela de feedback (integra com `question-report`)
- [x] 2.9 Rewiring do router: `/quiz/{topic}`, `/question/{id}`, `/daily` apontam para as telas novas (remover `quiz_deeplink_pages.dart` placeholder)
- [x] 2.10 Eventos de analytics via `AnalyticsService`: `session_started`, `question_answered`, `session_completed`
- [x] 2.11 Testes widget: smoke do fluxo questão → erro → explicação → resumo

## 3. Report de questão

- [x] 3.1 Implementar gravação do report na fila local (reaproveitando `pending_sync` do `question_bank`) e sync com Firestore quando online
- [x] 3.2 Evento de analytics `question_flagged`
- [x] 3.3 Testes: report offline não se perde; sync ao voltar a rede

## 4. Feature stats_flow (UI)

- [x] 4.1 Criar pacote `packages/features/stats_flow`; `StatsCubit`
- [x] 4.2 Tela de estatísticas: streak, XP total, desempenho por tópico, questões mais erradas
- [x] 4.3 Evento de analytics `streak_incremented`
- [x] 4.4 Testes widget: smoke da tela de estatísticas com dados fake

## 5. Home dashboard

- [x] 5.1 Adaptar `home_flow`: dashboard com tópicos disponíveis, streak atual e CTA do desafio diário (substituindo o conteúdo de exemplo do boilerplate)
- [x] 5.2 Navegação da home para pré-sessão por tópico e para `/daily`

## 6. Verificação final

- [x] 6.1 `make ci` verde (analyze + format + test) com os novos pacotes registrados no workspace
- [x] 6.2 Cobertura de lógica do módulo `quiz` ≥80% (meta da spec) — 91,9% de linhas (125/136, lcov)
- [x] 6.3 Testar no emulador, em modo avião: sessão por tópico completa com feedback e explicação
- [x] 6.4 Testar no emulador: errar uma questão hoje e simular data seguinte → aparece em Revisão; acertar 2x seguidas espaça o intervalo
- [x] 6.5 Testar no emulador: completar sessões em dias simulados consecutivos incrementa streak; pular um dia zera
- [x] 6.6 Testar no emulador: deeplinks `/quiz/{topic}`, `/question/{id}`, `/daily` abrem o fluxo real (não mais o placeholder)
- [x] 6.7 Testar no emulador: desafio diário mostra as mesmas 10 questões em horários diferentes do mesmo dia
- [ ] 6.8 ~~Verificar eventos de analytics~~ — pulado a pedido do dono do projeto (depende do setup real de Firebase, Spec 02 tasks 4.2-4.5)
