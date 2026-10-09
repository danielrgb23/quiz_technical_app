# streak-gamification

## MODIFIED Requirements

### Requirement: Streak diário
`StreakService` SHALL comparar **dias de calendário** locais (ano/mês/dia), nunca intervalos de 24h: sessão no dia seguinte ao último dia ativo soma 1; mais de um dia de diferença reinicia em 1; mesmo dia mantém o valor (no mínimo 1). Se o relógio do aparelho voltar no tempo (dia atual anterior ao último dia ativo), o streak MUST ser mantido, nunca zerado nem somado.

#### Scenario: Dias seguidos acumulam
- **WHEN** o usuário completa sessões em 10, 11, 12 e 13/jan
- **THEN** o streak é 1, 2, 3 e 4

#### Scenario: Perder um dia reseta para 0
- **WHEN** o usuário completa sessões em 10, 11 e 12/jan e não completa nenhuma em 13/jan
- **THEN** em 14/jan (antes de qualquer sessão) o streak exibido é 0 em todas as telas (Home, barra da sessão)
- **AND** ao concluir uma sessão em 14/jan o streak passa a 1 (nova sequência) e em 15/jan, concluindo outra, passa a 2

#### Scenario: Dia da graça
- **WHEN** a última sessão foi ontem e hoje ainda não houve sessão
- **THEN** o streak exibido continua o armazenado até o fim do dia

#### Scenario: Viradas de mês, ano e bissexto
- **WHEN** a sessão anterior foi em 31/jan, 31/dez ou 28/fev (ano bissexto) e a atual no dia civil seguinte
- **THEN** o streak soma 1

#### Scenario: Mais de 24h mas dia civil seguinte
- **WHEN** a última sessão foi às 08:00 de segunda e a atual às 23:00 de terça
- **THEN** o streak soma 1

#### Scenario: Horário de verão
- **WHEN** o dia civil tem 23h ou 25h
- **THEN** o resultado é o mesmo de um dia normal (sem reset indevido)

#### Scenario: Exibição sem sessão hoje
- **WHEN** o último dia ativo foi hoje ou ontem
- **THEN** o streak exibido é o armazenado; se foi antes de ontem, exibe 0
