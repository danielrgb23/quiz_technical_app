# flip-card-affordance
## ADDED Requirements
### Requirement: O card de feedback deixa claro que gira
A tela de feedback MUST oferecer (1) alternador "Pergunta | Explicação", (2) faixa fixa no card com o texto "Toque para ver a explicação" / "Toque para voltar à pergunta" e (3) uma animação de dica ao aparecer.
#### Scenario: Usuário não sabe que pode tocar
- **WHEN** o feedback é exibido
- **THEN** há um alternador e uma faixa visível indicando como ver a explicação, e o card balança levemente
#### Scenario: Toque durante a dica
- **WHEN** o usuário toca enquanto a dica anima
- **THEN** o card vira normalmente (a dica não sobrescreve o toque)
