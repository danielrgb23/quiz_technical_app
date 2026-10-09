# pastel-theme
## ADDED Requirements
### Requirement: Paleta pastel
Os tokens de `AppColors` SHALL usar tons pastel (pêssego/laranja suave, creme, menta, manteiga) e o tema claro/escuro MUST derivar deles; telas não devem usar cores hexadecimais fixas fora dos tokens.
#### Scenario: Contraste
- **WHEN** texto é exibido sobre cor primária/secundária pastel
- **THEN** usa `onPrimary`/`onSecondary` escuros com contraste mínimo de 4.5:1
