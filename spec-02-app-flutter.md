# Spec 02 — App Flutter: Setup sobre o Boilerplate (Firebase + Offline + Deeplinks)

## Objetivo
Montar a fundação do app de quiz usando o **prodevcom/flutter-mono-repo** (MIT) como base, aproveitando o que ele já resolve e implementando apenas o que é específico do produto: Firebase, offline-first e deeplinks.

## Decisões de arquitetura (atualizadas)
- **Base:** fork do `flutter-mono-repo`; desenvolvimento no `apps/app_boilerplate` (renomear para `apps/quiz_app`). Ignorar o fluxo white-label (`create_app.sh`, `client_example`) — manter no fork, sem usar.
- **State management:** **Cubit no papel de ViewModel** (MVVM preservado: estado imutável via Freezed + métodos de intenção; a View só conhece o Cubit).
- **Routing/deeplinks:** **auto_route** (já configurado no boilerplate) no lugar de go_router.
- **DI:** get_it + injectable (do boilerplate).
- **Tratar como fork próprio:** projeto upstream é pequeno; não depender de manutenção externa. Fixar versões e evoluir internamente.

## O que o boilerplate JÁ resolve (não implementar, apenas validar)
| Item | Onde |
| --- | --- |
| Monorepo Melos + Makefile (setup, gen, l10n, analyze, test, ci) | raiz |
| Flavors dev/stg/prod via `--dart-define-from-file` (dev com fake data sources, roda sem backend) | `env/*.json`, `main_*.dart` |
| Clean architecture com regras de dependência (modules sem UI; features não dependem entre si) | `packages/modules`, `packages/features` |
| DI (get_it + injectable) com environments por flavor | `docs/06` |
| Routing com auto_route | `docs/07` |
| i18n com intl + gen-l10n | `docs/08` |
| Design system / theming | `packages/design_system`, `docs/09` |
| Abstrações de analytics, crash reporting e connectivity | `packages/shared` |
| Lint, Freezed/json_serializable, CI local (`make ci`) | raiz |

**Validação inicial (Dia 1):** `make setup` + `make run-boilerplate-dev` funcionando em Android e iOS; `make ci` verde.

## Trabalho 1 — Identidade do app
- Renomear app base: `applicationId`/bundle `com.<seu_dominio>.quizmobile` (+ sufixo `.dev`/`.stg` por flavor).
- Ícone e splash (`flutter_launcher_icons`, `flutter_native_splash`).
- Ajustar `env/dev|stg|prod.json` com as chaves do projeto.
- Android minSdk 24; iOS 13+.

## Trabalho 2 — Firebase
O boilerplate não traz Firebase; plugar **atrás das abstrações existentes** do `packages/shared`.
1. Projetos Firebase separados por ambiente (dev e prod; stg pode compartilhar dev no MVP), configurados com `flutterfire configure` por flavor (`firebase_options_<flavor>.dart`).
2. Implementações concretas em `packages/shared`:
   - `AnalyticsService` → Firebase Analytics
   - `CrashReporter` → Crashlytics
   - registradas via injectable apenas nos environments stg/prod (dev mantém fakes/no-op).
3. `firebase_auth`: login anônimo no primeiro launch (módulo `auth` do boilerplate adaptado; social login v2).
4. `cloud_firestore`: `banks/{version}` (manifest do banco de questões) e `users/{uid}/progress`; regras: leitura pública do banco, escrita de progresso só pelo próprio uid.
5. `firebase_remote_config`: `min_app_version`, `latest_bank_version`, feature flags — atrás de uma interface `RemoteConfigService` em `packages/core`.

## Trabalho 3 — Offline-first (módulo `question_bank`)
Novo pacote `packages/modules/question_bank` (sem UI):
1. **Banco embarcado:** `questions_v1.json` (output da Spec 01) como asset — app 100% funcional offline no primeiro launch.
2. **drift** como fonte de verdade local: tabelas `questions`, `progress` (questionId, acertos, erros, lastSeenAt, nextReviewAt), `pending_sync`.
3. `BankSyncService`: no boot com rede, compara versão local vs `latest_bank_version` (Remote Config); baixa novo JSON (Firebase Storage), valida checksum do manifest e importa em transação.
4. Sync de progresso: espelho em Firestore, fila `pending_sync` com retry em background; usa a abstração de connectivity do `packages/shared`. UI nunca bloqueia por falta de rede.
5. Interfaces (`QuestionRepository`, `ProgressRepository`) no módulo; drift/Firestore como detalhes de implementação trocáveis.

## Trabalho 4 — Deeplinks (auto_route)
- **Rotas:** `/quiz/{topic}`, `/question/{id}`, `/daily` — declaradas no router do auto_route com deep link handling.
- **Custom scheme** `quizapp://` (fallback) + **App Links/Universal Links** `https://<seu_dominio>/...`:
  - Android: `intent-filter` com `autoVerify=true`; hospedar `assetlinks.json`.
  - iOS: Associated Domains (`applinks:`); hospedar `apple-app-site-association`.
- Guard para conteúdo ainda não disponível localmente → tela de fallback com CTA.

## Trabalho 5 — i18n (ajuste sobre o existente)
O boilerplate já usa intl + gen-l10n, que atende ao requisito de **traduções embarcadas no binário (APK/IPA)**: os `.arb` são compilados em Dart no build, disponíveis de forma síncrona desde o primeiro frame, 100% offline, sem pré-carregamento. Ajustes:
- Garantir `app_pt.arb` como padrão + `app_en.arb`; fallback para `pt` no `localeResolutionCallback`.
- **Proibido** qualquer tradução OTA/remota (Firestore/Remote Config); mudanças de texto só via release.
- MVP: só strings de UI em pt/en; conteúdo das questões em pt-BR (campo `language` do schema prevê bancos por idioma no futuro).
- Zero strings hardcoded (lint/code review).

## CI/CD
- Aproveitar `make ci` no GitHub Actions (analyze + format + test) em PR; build Android/iOS em tag; semver + build_number automático.

## Critérios de aceite
1. `make setup` + run do flavor dev em Android e iOS sem backend (fakes do boilerplate).
2. Flavors stg/prod inicializam Firebase (Crashlytics recebe crash de teste; Analytics registra evento).
3. Em modo avião no primeiro launch, o app carrega o banco de questões do asset e navega normalmente.
4. Nova versão do banco publicada (Storage + Remote Config) → drift atualizado no próximo boot com rede, com checksum validado.
5. `quizapp://quiz/flutter` e `https://<domínio>/quiz/flutter` abrem a rota correta com app fechado e aberto.
6. Trocar idioma do dispositivo para inglês troca as strings de UI sem rebuild, sem rede e sem carregamento visível (verificável em modo avião).
7. Regras de dependência preservadas: nenhum feature importa outro feature; nenhum module importa UI; `make ci` verde.

## Fora de escopo
Fluxo do quiz, gamificação e repetição espaçada → Spec 03. Login social, notificações → v2.
