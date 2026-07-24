# Design — Fundação do App Flutter

## Context

A Spec 02 monta a base do app sobre o `prodevcom/flutter-mono-repo`, que já resolve monorepo (Melos + Makefile), flavors dev/stg/prod com fake data sources, clean architecture com regras de dependência, DI (get_it + injectable), routing (auto_route), i18n (intl + gen-l10n), design system, abstrações de analytics/crash/connectivity e CI local (`make ci`). O trabalho é plugar Firebase, offline-first e deeplinks sem violar essas regras. O upstream é pequeno: tratamos como fork próprio, com versões fixadas.

## Goals / Non-Goals

**Goals:**
- `make setup` + run do flavor dev funcionando sem backend (fakes).
- Firebase apenas em stg/prod, sempre atrás das interfaces do `packages/shared`/`packages/core`.
- App 100% funcional offline no primeiro launch (banco embarcado da Spec 01).
- Atualização de banco por versão com checksum validado; progresso espelhado no Firestore com fila offline.
- Deeplinks funcionando com app fechado e aberto.

**Non-Goals:**
- Fluxo do quiz, gamificação, repetição espaçada (Spec 03).
- Login social, notificações, white-label (v2).

## Decisions

1. **Vendorizar o boilerplate no monorepo deste repositório** (não um fork no GitHub): o repo é a fonte de verdade única para pipeline + app; upstream pequeno não justifica manter remote de sincronização. Histórico upstream referenciado no commit de importação.
2. **Cubit como ViewModel (MVVM preservado):** estado imutável via Freezed + métodos de intenção; a View conhece só o Cubit. Bloc completo descartado (eventos são cerimônia desnecessária aqui).
3. **Firebase por flavor com `--dart-define-from-file`:** projetos dev e prod (stg compartilha dev no MVP); `firebase_options_<flavor>.dart` gerados por `flutterfire configure`; implementações concretas (`FirebaseAnalyticsService`, `CrashlyticsReporter`) registradas via injectable apenas nos environments stg/prod — dev permanece com no-op/fakes do boilerplate.
4. **`RemoteConfigService` em `packages/core`** como interface; implementação Firebase em `packages/shared`. Chaves: `min_app_version`, `latest_bank_version`, feature flags.
5. **drift como fonte de verdade local** no módulo `question_bank`: tabelas `questions`, `progress(questionId, acertos, erros, lastSeenAt, nextReviewAt)`, `pending_sync`. Interfaces `QuestionRepository`/`ProgressRepository` no módulo; drift/Firestore são detalhes trocáveis.
6. **Import do banco em transação com checksum:** no boot com rede, `BankSyncService` compara versão local vs `latest_bank_version`; baixa JSON do Firebase Storage, valida SHA-256 do manifest (mesmo algoritmo da Spec 01) e importa atomicamente. Falha de checksum → mantém banco atual e reporta ao Crashlytics.
7. **Sync de progresso com fila `pending_sync`:** escrita local sempre; espelho em `users/{uid}/progress` quando online, com retry em background usando a abstração de connectivity. UI nunca bloqueia por rede.
8. **auto_route para deeplinks** (já no boilerplate): rotas `/quiz/{topic}`, `/question/{id}`, `/daily`; `quizapp://` como fallback + App Links (`autoVerify`) / Universal Links (Associated Domains). Guard verifica disponibilidade local do conteúdo → tela de fallback com CTA.
9. **i18n embarcado somente:** `.arb` compilados no build (síncronos desde o primeiro frame, offline); `localeResolutionCallback` com fallback `pt`; proibição de tradução OTA; lint contra strings hardcoded.

## Risks / Trade-offs

- [Firebase exige credenciais/projetos do usuário] → trabalho estruturado para que tudo compile e rode em dev (fakes) sem Firebase; etapa `flutterfire configure` documentada e isolada.
- [Boilerplate pode ter drift de versões do Flutter atual] → fixar versões; primeiro `make setup`/`make ci` valida; ajustes de compatibilidade fazem parte da task de validação inicial.
- [App/Universal Links exigem domínio + arquivos hospedados] → custom scheme `quizapp://` funciona sem infraestrutura; App Links ficam configurados no app e a hospedagem dos arquivos é etapa externa documentada.
- [Import de banco grande travar UI] → import em isolate/transação drift; só troca a versão ao concluir.

## Migration Plan

Projeto novo. Rollback = remover o diretório do app; o pipeline (Spec 01) é independente.

## Open Questions

- Domínio definitivo para applicationId e App Links (placeholder `com.quizmobile.app` até o usuário definir).
- Conta Firebase do usuário (necessária para stg/prod; dev roda sem).
