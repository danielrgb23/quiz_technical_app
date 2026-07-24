# app-identity Specification

## Purpose
TBD - created by archiving change app-flutter-fundacao. Update Purpose after archive.
## Requirements
### Requirement: Identidade do app por flavor
O app SHALL usar applicationId/bundle base `com.quizmobile.app` com sufixos `.dev` e `.stg` nos flavors correspondentes, ícone e splash próprios, Android minSdk 24 e iOS 13+.

#### Scenario: Build por flavor
- **WHEN** o app é compilado nos flavors dev, stg e prod
- **THEN** cada build tem applicationId/bundle distinto (`.dev`, `.stg`, sem sufixo) e pode ser instalado lado a lado

### Requirement: Flavor dev roda sem backend
O flavor dev SHALL inicializar com data sources fake do boilerplate, sem exigir Firebase ou rede.

#### Scenario: make setup + run dev
- **WHEN** `make setup` é executado e o flavor dev é iniciado em Android e iOS
- **THEN** o app abre e navega sem nenhuma configuração de backend

