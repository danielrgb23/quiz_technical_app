# question-validation

## ADDED Requirements

### Requirement: Validação de schema da questão
O pipeline SHALL validar cada questão gerada contra o schema (Pydantic): exatamente 5 alternativas, `correctIndex` entre 0 e 4, alternativas sem duplicatas, explicação não vazia, `topic` pertencente à taxonomia e `level` entre 1 e 3. Questões rejeitadas SHALL ser gravadas em `data/review/rejected.jsonl` com o motivo.

#### Scenario: Questão válida
- **WHEN** `python -m pipeline validate` processa uma questão conforme o schema
- **THEN** a questão é aceita para o conjunto validado

#### Scenario: Questão com alternativas duplicadas
- **WHEN** uma questão tem duas alternativas idênticas
- **THEN** ela é rejeitada e registrada em `rejected.jsonl` com o motivo

### Requirement: Deduplicação por pergunta normalizada
O pipeline SHALL normalizar a pergunta (lowercase, sem pontuação) e comparar entre todas as questões; colisões SHALL ser gravadas em `data/review/duplicates.jsonl` para revisão manual, mantendo apenas a primeira ocorrência no conjunto validado.

#### Scenario: Perguntas equivalentes
- **WHEN** duas questões têm perguntas iguais após normalização
- **THEN** a primeira é mantida e a segunda vai para `duplicates.jsonl`
