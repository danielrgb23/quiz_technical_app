# quiz-flow-ui

## ADDED Requirements

### Requirement: Tela de pré-sessão
A tela de pré-sessão (via home ou deeplink `/quiz/{topic}`) SHALL exibir o tópico, a quantidade de questões e um botão para iniciar a sessão.

#### Scenario: Iniciar sessão pela pré-sessão
- **WHEN** o usuário toca em "iniciar" na pré-sessão de um tópico
- **THEN** a sessão é criada e a primeira questão é exibida

### Requirement: Tela de questão com feedback imediato
A tela de questão SHALL exibir barra de progresso (x/N) e streak, o enunciado (com suporte a bloco de código monoespaçado), 5 alternativas em cards de seleção única e um botão de confirmar. Ao confirmar: acerto SHALL destacar em verde e avançar; erro SHALL destacar a alternativa correta, expandir a explicação e exigir toque em "entendi" para avançar. Não SHALL haver penalidade tipo "vidas".

#### Scenario: Resposta correta
- **WHEN** o usuário seleciona a alternativa correta e confirma
- **THEN** a alternativa é destacada em verde e a sessão avança para a próxima questão

#### Scenario: Resposta incorreta
- **WHEN** o usuário seleciona uma alternativa incorreta e confirma
- **THEN** a alternativa correta é destacada, a explicação é exibida expandida, e o avanço só ocorre após o usuário tocar em "entendi"

### Requirement: Resumo da sessão
Ao concluir a sessão, SHALL ser exibido o resumo com acertos/N, XP ganho, streak atualizado, lista de questões erradas com link para revisar a explicação, e CTA para nova sessão.

#### Scenario: Conclusão de sessão de 10 questões
- **WHEN** a última questão da sessão é respondida
- **THEN** o resumo exibe a contagem de acertos, o XP ganho, o streak atualizado e a lista de erradas

### Requirement: Deeplink de questão única
`/question/{id}` SHALL abrir o modo de questão única, com a explicação sempre visível ao responder (independente de acerto ou erro).

#### Scenario: Abrir questão única pelo deeplink
- **WHEN** `/question/{id}` é aberto
- **THEN** a questão é exibida isoladamente e, ao responder, a explicação aparece independentemente do resultado

### Requirement: Confirmação ao abandonar sessão
Voltar no meio de uma sessão SHALL exibir um diálogo de confirmação antes de abandonar.

#### Scenario: Voltar durante a sessão
- **WHEN** o usuário aciona o botão de voltar durante uma sessão em andamento
- **THEN** um diálogo de confirmação é exibido antes de encerrar a sessão

### Requirement: Report de questão na tela de feedback
A tela de feedback SHALL ter um botão discreto para reportar a questão atual.

#### Scenario: Reportar questão
- **WHEN** o usuário toca no botão de report na tela de feedback
- **THEN** a questão é marcada como reportada (ver capability `question-report`)
