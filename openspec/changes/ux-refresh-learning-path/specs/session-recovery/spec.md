# session-recovery
## ADDED Requirements
### Requirement: Sem login por biometria
O app MUST NOT oferecer, exigir ou referenciar desbloqueio biométrico.
#### Scenario: Primeiro login
- **WHEN** o usuário conclui login/cadastro/convidado
- **THEN** vai direto à Home, sem diálogo de biometria
### Requirement: Sessão recuperada automaticamente
Após o primeiro login, aberturas seguintes SHALL restaurar a sessão sem pedir credenciais, até logout explícito.
#### Scenario: Reabertura do app
- **WHEN** o app é reiniciado com sessão válida
- **THEN** o usuário cai na Home sem passar por Login
#### Scenario: Logout
- **WHEN** o usuário faz logout
- **THEN** a sessão persistida é apagada e o próximo início mostra Login
