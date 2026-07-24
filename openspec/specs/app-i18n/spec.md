# app-i18n Specification

## Purpose
TBD - created by archiving change app-flutter-fundacao. Update Purpose after archive.
## Requirements
### Requirement: Traduções embarcadas com fallback pt
O app SHALL fornecer `app_pt.arb` (padrão) e `app_en.arb` compilados no binário via gen-l10n, com `localeResolutionCallback` que faz fallback para `pt`. As strings MUST estar disponíveis de forma síncrona desde o primeiro frame, 100% offline.

#### Scenario: Troca de idioma do dispositivo
- **WHEN** o idioma do dispositivo muda para inglês em modo avião
- **THEN** as strings de UI aparecem em inglês sem rebuild, sem rede e sem carregamento visível

#### Scenario: Idioma não suportado
- **WHEN** o dispositivo está em um idioma sem tradução (ex.: francês)
- **THEN** a UI usa pt

### Requirement: Proibição de tradução remota
O app MUST NOT carregar traduções de fontes remotas (Firestore/Remote Config); mudanças de texto SHALL ocorrer apenas via release. Strings de UI MUST NOT ser hardcoded fora dos `.arb`.

#### Scenario: Revisão de código
- **WHEN** o lint/CI roda
- **THEN** strings hardcoded em widgets são apontadas como violação

