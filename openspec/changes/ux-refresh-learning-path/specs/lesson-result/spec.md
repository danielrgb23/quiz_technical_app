# lesson-result
## ADDED Requirements
### Requirement: Tela de resultado clara e motivadora
Ao fim de uma sessão o app SHALL exibir o percentual de acertos em um anel, título e mensagem coerentes com o resultado, métricas (XP, acertos, sequência) e as questões erradas para revisar.
#### Scenario: Lição reprovada
- **WHEN** a precisão fica abaixo de 80% em uma lição
- **THEN** o título é de incentivo, o texto informa a meta e os botões são "Tentar novamente" e "Voltar à trilha"
#### Scenario: Lição aprovada
- **WHEN** a precisão é >= 80%
- **THEN** o botão principal é "Continuar" e volta para a trilha atualizada
