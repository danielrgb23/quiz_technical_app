# Tasks — Fundação do App Flutter

## 1. Importar e validar o boilerplate

- [x] 1.1 Vendorizar `prodevcom/flutter-mono-repo` em `app/` (sem fluxo white-label), fixando versões e registrando a origem no commit
- [x] 1.2 Rodar `make setup` e o flavor dev (fakes, sem backend); corrigir incompatibilidades com o Flutter instalado
- [x] 1.3 Rodar `make ci` (analyze + format + test) verde

## 2. Identidade do app

- [ ] 2.1 Renomear `apps/app_boilerplate` → `apps/quiz_app`; applicationId/bundle `com.quizmobile.app` + sufixos `.dev`/`.stg`; minSdk 24 / iOS 13+
- [ ] 2.2 Configurar ícone e splash (`flutter_launcher_icons`, `flutter_native_splash`) com placeholders
- [ ] 2.3 Ajustar `env/dev|stg|prod.json`

## 3. Módulo question_bank (offline-first, roda sem Firebase)

- [ ] 3.1 Criar pacote `packages/modules/question_bank` com drift: tabelas `questions`, `progress`, `pending_sync`; interfaces `QuestionRepository`/`ProgressRepository`
- [ ] 3.2 Embarcar `questions_v1.json` + `manifest.json` como assets e implementar import inicial em transação
- [ ] 3.3 Implementar `BankSyncService` (comparação de versão via `RemoteConfigService`, download, validação de checksum SHA-256, import transacional) — com fontes fake em dev
- [ ] 3.4 Implementar fila `pending_sync` de progresso com retry usando a abstração de connectivity
- [ ] 3.5 Testes unitários do módulo: import de asset, checksum inválido aborta, fila offline drena ao voltar rede

## 4. Firebase (stg/prod)

- [ ] 4.1 Definir interface `RemoteConfigService` em `packages/core` + fake em dev
- [ ] 4.2 Implementar `AnalyticsService`→Firebase Analytics e `CrashReporter`→Crashlytics em `packages/shared`, registradas via injectable só em stg/prod
- [ ] 4.3 Integrar `firebase_auth` (login anônimo no primeiro launch, tolerante a offline)
- [ ] 4.4 Implementar espelho Firestore do progresso (`users/{uid}/progress`) e leitura de `banks/{version}`; escrever regras de segurança
- [ ] 4.5 Documentar/rodar `flutterfire configure` por flavor (requer conta Firebase do usuário) e validar crash de teste + evento no DebugView

## 5. Deeplinks

- [ ] 5.1 Declarar rotas `/quiz/{topic}`, `/question/{id}`, `/daily` no router auto_route com deep link handling
- [ ] 5.2 Configurar scheme `quizapp://` + App Links (`autoVerify`) / Universal Links (Associated Domains); documentar hospedagem de `assetlinks.json`/AASA
- [ ] 5.3 Implementar guard de conteúdo indisponível com tela de fallback + CTA
- [ ] 5.4 Testar deeplinks com app fechado e aberto (adb/xcrun)

## 6. i18n

- [ ] 6.1 Garantir `app_pt.arb` padrão + `app_en.arb`; `localeResolutionCallback` com fallback pt
- [ ] 6.2 Migrar strings hardcoded para `.arb` e habilitar lint contra novas ocorrências

## 7. CI/CD e verificação final

- [ ] 7.1 GitHub Actions com `make ci` em PR; build Android/iOS em tag com semver + build_number
- [ ] 7.2 Verificar critérios de aceite: dev roda sem backend; modo avião no primeiro launch funciona; deeplinks abrem as rotas; troca de idioma offline funciona; `make ci` verde
