# mcq-generation

## ADDED Requirements

### Requirement: Geração de MCQ via LLM com saída somente JSON
Para cada par pergunta/resposta, o pipeline SHALL chamar o LLM com prompt estruturado que exige somente JSON contendo: pergunta reescrita de forma autocontida, 5 alternativas (1 correta + 4 distratores plausíveis), explicação de 2–5 frases, `topic` da taxonomia definida e `level` (1=júnior, 2=pleno, 3=sênior).

#### Scenario: Par com resposta
- **WHEN** `python -m pipeline generate` processa um par com `raw_answer` presente
- **THEN** uma questão JSON com 5 alternativas, `correctIndex`, explicação, `topic` e `level` é gravada em `data/generated/`

#### Scenario: Par sem resposta
- **WHEN** o par tem `raw_answer: null`
- **THEN** o LLM gera a resposta e a questão resultante carrega a flag `generated_answer: true`

### Requirement: Idempotência por id determinístico
Cada questão MUST ter id determinístico derivado de `slug(source_id + raw_question)` com sufixo hash de 8 caracteres, e o pipeline SHALL pular pares cujo id já existe no diretório de geradas.

#### Scenario: Reexecução sem mudanças
- **WHEN** `generate` roda novamente sem mudança nas fontes
- **THEN** nenhuma chamada ao LLM é feita

### Requirement: Resiliência de chamadas ao LLM
As chamadas ao LLM SHALL usar retry com backoff exponencial (até 3 tentativas) para falhas de rede/rate limit/JSON inválido, com paralelismo limitado a 5 workers; após esgotar as tentativas a questão SHALL ser registrada em `data/review/rejected.jsonl` sem interromper o restante do lote.

#### Scenario: JSON inválido persistente
- **WHEN** o LLM devolve JSON inválido em 3 tentativas consecutivas para um par
- **THEN** o par é registrado em `rejected.jsonl` com o motivo e o pipeline continua com os demais

### Requirement: Estimativa de custo com dry-run
O comando `generate` SHALL aceitar `--dry-run` e `--limit N`, imprimindo a contagem de chamadas previstas sem chamar o LLM.

#### Scenario: Dry-run
- **WHEN** `generate --dry-run --limit 10` é executado
- **THEN** o pipeline imprime quantas questões seriam geradas (máx. 10) e não faz nenhuma chamada ao LLM
