# learning-path
## ADDED Requirements
### Requirement: Trilha ao abrir um tópico
Abrir um tópico SHALL exibir uma trilha vertical de lições (nós circulares em zigue-zague) com cabeçalho do tópico, em vez do formulário de pré-sessão.
#### Scenario: Estados dos nós
- **WHEN** a trilha é exibida
- **THEN** lições concluídas aparecem preenchidas com check, a lição atual com bolha "COMEÇAR" e as demais bloqueadas com cadeado
### Requirement: Aprovação com 80% libera a próxima lição
Uma lição MUST contar como concluída somente com >= 80% de respostas corretas; abaixo disso a próxima lição permanece bloqueada.
#### Scenario: Reprovado
- **WHEN** o usuário acerta 3 de 5 (60%)
- **THEN** a trilha não avança e a tela de resultado oferece "Tentar novamente"
#### Scenario: Aprovado
- **WHEN** o usuário acerta 4 de 5 (80%) na lição atual
- **THEN** a próxima lição é liberada e o resultado exibe "Próxima lição liberada!"
#### Scenario: Refazer lição concluída
- **WHEN** o usuário refaz uma lição já concluída
- **THEN** o progresso da trilha não muda
### Requirement: Lições fixas e repetíveis
Cada lição SHALL usar um bloco fixo de 5 questões do tópico ordenadas por id; refazer repete as mesmas questões.
### Requirement: Várias trilhas independentes
Cada tópico MUST ter sua própria trilha e progresso; a Home SHALL mostrar o progresso (x/y lições) de cada tópico.
#### Scenario: Alternar entre tópicos
- **WHEN** o usuário avança em "architecture" e abre "android"
- **THEN** "android" mantém seu próprio progresso
### Requirement: Nó bloqueado
Tocar em um nó bloqueado MUST NOT iniciar sessão e SHALL informar a meta de 80%.
### Requirement: Deeplink preservado
`/quiz/{topic}` MUST continuar abrindo a tela do tópico.
