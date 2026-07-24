# streak-gamification

## ADDED Requirements

### Requirement: Streak diário
`StreakService` SHALL incrementar o streak quando o usuário completa pelo menos uma sessão no dia (considerando o timezone local do dispositivo); pular um dia sem sessão completa SHALL zerar o streak.

#### Scenario: Sessões em dias consecutivos
- **WHEN** o usuário completa uma sessão hoje e já tinha completado uma ontem
- **THEN** o streak é incrementado em relação ao valor anterior

#### Scenario: Dia pulado zera o streak
- **WHEN** o usuário completa uma sessão hoje mas não completou nenhuma sessão ontem (streak anterior > 0)
- **THEN** o streak reinicia em 1 (não soma ao valor anterior)

#### Scenario: Mais de uma sessão no mesmo dia
- **WHEN** o usuário completa duas sessões no mesmo dia
- **THEN** o streak é incrementado apenas uma vez por esse dia

### Requirement: XP por resposta e por sessão
O sistema SHALL conceder +10 XP por acerto, +2 XP por erro e bônus de +20 XP ao completar uma sessão.

#### Scenario: XP de uma sessão de 10 questões com 8 acertos
- **WHEN** uma sessão de 10 questões é completada com 8 acertos e 2 erros
- **THEN** o XP total ganho na sessão é `8*10 + 2*2 + 20 = 104`
