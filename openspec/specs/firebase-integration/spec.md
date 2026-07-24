# firebase-integration Specification

## Purpose
TBD - created by archiving change app-flutter-fundacao. Update Purpose after archive.
## Requirements
### Requirement: Firebase atrás das abstrações, apenas em stg/prod
As implementações Firebase de `AnalyticsService` (Analytics) e `CrashReporter` (Crashlytics) SHALL ser registradas via injectable somente nos environments stg e prod; o environment dev MUST manter as implementações fake/no-op do boilerplate. Nenhum feature ou module SHALL importar Firebase diretamente.

#### Scenario: Crash de teste em stg
- **WHEN** um crash forçado ocorre no flavor stg
- **THEN** o Crashlytics recebe o report e um evento de Analytics é registrado

#### Scenario: Dev sem Firebase
- **WHEN** o flavor dev inicia
- **THEN** nenhuma chamada a Firebase é feita e o app funciona normalmente

### Requirement: Login anônimo no primeiro launch
O app SHALL autenticar o usuário anonimamente via firebase_auth no primeiro launch em stg/prod, obtendo um uid estável para sync de progresso.

#### Scenario: Primeiro launch com rede
- **WHEN** o app stg/prod abre pela primeira vez com rede
- **THEN** um usuário anônimo é criado e seu uid fica disponível para o sync

#### Scenario: Primeiro launch sem rede
- **WHEN** o app abre pela primeira vez em modo avião
- **THEN** o app funciona normalmente e o login anônimo é adiado até haver rede

### Requirement: Estrutura Firestore e regras de acesso
O Firestore SHALL conter `banks/{version}` (manifest do banco de questões, leitura pública) e `users/{uid}/progress` (escrita permitida apenas pelo próprio uid).

#### Scenario: Escrita de progresso de outro usuário
- **WHEN** um cliente tenta escrever em `users/{outroUid}/progress`
- **THEN** as regras do Firestore negam a operação

### Requirement: Remote Config atrás de interface
Uma interface `RemoteConfigService` em `packages/core` SHALL expor `min_app_version`, `latest_bank_version` e feature flags; a implementação Firebase fica em `packages/shared` e o dev usa implementação fake com valores padrão.

#### Scenario: Leitura de latest_bank_version
- **WHEN** o `BankSyncService` consulta a versão mais recente do banco
- **THEN** obtém o valor via `RemoteConfigService` sem conhecer Firebase

