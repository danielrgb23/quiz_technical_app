# question-report

## ADDED Requirements

### Requirement: Report de questão offline-first
O report de uma questão SHALL ser gravado localmente de imediato e enfileirado para sincronização com o Firestore quando online, reaproveitando a fila de sync já existente (Spec 02); o report MUST NOT se perder quando offline.

#### Scenario: Report offline
- **WHEN** o usuário reporta uma questão em modo avião
- **THEN** o report é salvo localmente e permanece na fila até haver conectividade

#### Scenario: Report sincronizado ao voltar a rede
- **WHEN** a conectividade retorna após um report feito offline
- **THEN** o report é enviado ao Firestore e removido da fila local
