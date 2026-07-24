# question-bank-offline

## ADDED Requirements

### Requirement: Banco embarcado disponível offline no primeiro launch
O app SHALL embarcar `questions_v<N>.json` (output da Spec 01) como asset e importá-lo para o drift no primeiro launch, permitindo uso completo em modo avião.

#### Scenario: Primeiro launch em modo avião
- **WHEN** o app abre pela primeira vez sem nenhuma conectividade
- **THEN** o banco de questões do asset é carregado e a navegação funciona normalmente

### Requirement: drift como fonte de verdade local
O módulo `question_bank` (sem UI) SHALL manter tabelas `questions`, `progress` (questionId, acertos, erros, lastSeenAt, nextReviewAt) e `pending_sync` no drift, expostas pelas interfaces `QuestionRepository` e `ProgressRepository`.

#### Scenario: Consulta de questões por tópico
- **WHEN** um consumidor pede questões de um tópico via `QuestionRepository`
- **THEN** os dados vêm do drift sem acesso à rede

### Requirement: Sync de banco com validação de checksum
No boot com rede, o `BankSyncService` SHALL comparar a versão local com `latest_bank_version` (Remote Config); havendo versão nova, SHALL baixar o JSON do Firebase Storage, validar o checksum SHA-256 do manifest e importar em transação. Checksum inválido MUST abortar o import mantendo o banco atual.

#### Scenario: Nova versão publicada
- **WHEN** `latest_bank_version` é maior que a versão local e o download conclui com checksum válido
- **THEN** o drift passa a servir a nova versão após o import transacional

#### Scenario: Checksum inválido
- **WHEN** o JSON baixado não bate com o checksum do manifest
- **THEN** o import é abortado, o banco atual permanece e o erro é reportado ao CrashReporter

### Requirement: Sync de progresso com fila offline
Escritas de progresso SHALL ser aplicadas localmente de imediato e enfileiradas em `pending_sync`; com rede, a fila SHALL ser espelhada em `users/{uid}/progress` com retry em background. A UI MUST NOT bloquear por falta de rede.

#### Scenario: Progresso offline
- **WHEN** o usuário responde questões em modo avião
- **THEN** o progresso é salvo localmente e enfileirado; ao voltar a rede, a fila é sincronizada sem intervenção
