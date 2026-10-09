# sound-effects
## ADDED Requirements
### Requirement: Efeitos sonoros de feedback
O app SHALL tocar sons curtos para: toque em nó/ação principal, resposta correta, resposta errada e sessão concluída, acompanhados de haptic leve.
#### Scenario: Resposta correta
- **WHEN** o usuário confirma e acerta
- **THEN** toca o som de acerto
### Requirement: Usuário pode silenciar
O perfil MUST ter a chave "Sons"; desligada, nenhum som toca, e a escolha persiste.
### Requirement: Falha de áudio não afeta o fluxo
Erros de reprodução MUST ser ignorados.
