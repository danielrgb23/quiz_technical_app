# Tasks — Refresh de UX

## 1. Biometria → recuperação de sessão
- [x] 1.1 Remover serviço/prefs/gate/guard/tela/diálogo/strings/`local_auth`/Info.plist
- [x] 1.2 Regenerar DI e rotas
- [x] 1.3 Persistir sessão fake em dev (SecureStorage)
## 2. Rodapés
- [x] 2.1 SafeArea nas telas sem proteção
## 3. Paleta pastel
- [x] 3.1 Tokens + tema claro/escuro
- [x] 3.2 Revisar textos sobre cores pastel e cores fixas
## 4. Trilha
- [x] 4.1 `TopicPathCubit` + `TopicPathPage` + rota
- [x] 4.2 Strings pt/en/es
## 5. Sons
- [x] 5.1 Gerar WAVs (script) + assets
- [x] 5.2 `SoundService` + DI + toggle no perfil
- [x] 5.3 Disparar sons na trilha e na sessão
## 6. Verificação
- [x] 6.1 `dart analyze` + testes
- [x] 6.2 Rodar no simulador com Marionette e capturar telas
- [x] 6.3 Documentar (app/docs/ux-refresh.md)
- [ ] 6.4 Arquivar a change (`/opsx:archive`)

## 7. Resultado, aprovação 80%, trilhas e card que gira
- [x] 7.1 `LearningPathService` + `lesson` em `StartSessionUseCase` (blocos fixos de 5)
- [x] 7.2 Gating de 80% na trilha e `LessonOutcome` no resumo
- [x] 7.3 `LessonSummaryView` (anel, métricas, revisão, botões)
- [x] 7.4 Progresso por tópico na Home
- [x] 7.5 Card que gira: alternador, faixa fixa, peek (+ correção do peek vs. toque)
- [x] 7.6 Testes (`learning_path_service_test`, `topic_path_cubit_test`, lição fixa, widget de feedback/resumo)
- [x] 7.7 Validado no simulador (reprovado 40% → sem desbloqueio; aprovado 100% → lição 2 liberada; Home com progresso por tópico)

## 8. Ajustes finais
- [x] 8.1 Streak por dias de calendário (DST/relógio) + testes de sequência
- [x] 8.2 Ícone e splash na paleta pastel (generate_branding.py + geradores nativos)
- [x] 8.3 Sons na pergunta única
- [x] 8.4 Lista "Para revisar" com contagem e fade
- [ ] 8.5 Validar sons/volume em aparelho real (fora do escopo desta rodada)
