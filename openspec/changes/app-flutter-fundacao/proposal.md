# Fundação do App Flutter (Boilerplate + Firebase + Offline + Deeplinks)

## Why

O app de quiz precisa de uma fundação sólida antes das features (Spec 03): projeto Flutter estruturado, Firebase para analytics/crash/auth/sync, funcionamento 100% offline no primeiro launch (consumindo o `questions_v<N>.json` da Spec 01) e deeplinks. Em vez de montar tudo do zero, usamos o boilerplate `prodevcom/flutter-mono-repo` (MIT) como fork próprio, implementando apenas o que é específico do produto.

## What Changes

- Fork/vendorização do `prodevcom/flutter-mono-repo` no repositório; app base renomeado para `apps/quiz_app` (fluxo white-label ignorado).
- Identidade do app: applicationId/bundle `com.<dominio>.quizmobile` (+ sufixos `.dev`/`.stg`), ícone, splash, minSdk 24 / iOS 13+.
- Integração Firebase atrás das abstrações existentes do `packages/shared`: Analytics, Crashlytics, auth anônimo, Firestore (`banks/{version}`, `users/{uid}/progress`), Remote Config (`min_app_version`, `latest_bank_version`, flags) — implementações registradas só em stg/prod; dev mantém fakes.
- Novo pacote `packages/modules/question_bank` (sem UI): banco embarcado como asset, drift como fonte de verdade local (`questions`, `progress`, `pending_sync`), `BankSyncService` com validação de checksum, sync de progresso com fila e retry.
- Deeplinks via auto_route: rotas `/quiz/{topic}`, `/question/{id}`, `/daily`; custom scheme `quizapp://` + App Links/Universal Links; guard com fallback para conteúdo indisponível.
- i18n: `app_pt.arb` padrão + `app_en.arb`, fallback pt, traduções somente embarcadas (sem OTA), zero strings hardcoded.
- CI: `make ci` no GitHub Actions em PR; builds por tag.

## Capabilities

### New Capabilities

- `app-identity`: identidade do app por flavor (ids, ícone, splash, versões mínimas de SO).
- `firebase-integration`: Analytics/Crashlytics/Auth/Firestore/Remote Config atrás das abstrações do boilerplate, ativos apenas em stg/prod.
- `question-bank-offline`: módulo de dados offline-first com banco embarcado, drift, sync de banco com checksum e fila de sync de progresso.
- `deeplinks`: rotas profundas por custom scheme e App/Universal Links com guard de conteúdo.
- `app-i18n`: traduções embarcadas pt/en com fallback pt e proibição de tradução remota.

### Modified Capabilities

(nenhuma — as capabilities da Spec 01 não mudam; o app apenas consome o output)

## Impact

- Novo diretório com o monorepo Flutter (Melos + Makefile) na raiz do repositório.
- Dependências novas: firebase_core/analytics/crashlytics/auth/cloud_firestore/remote_config, drift, flutter_launcher_icons, flutter_native_splash.
- Requer projetos Firebase (dev e prod) configurados via `flutterfire configure` — etapa com credenciais do usuário.
- O output da Spec 01 (`questions_v1.json`) passa a ser asset do app.
- Hospedagem futura de `assetlinks.json` / `apple-app-site-association` para App/Universal Links.
