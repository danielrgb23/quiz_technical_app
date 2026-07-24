# qa-parsing

## ADDED Requirements

### Requirement: Extração de pares pergunta/resposta por headings
O pipeline SHALL extrair pares pergunta/resposta do markdown de cada fonte tratando headings (`###`, `####`, conforme configuração da fonte) como pergunta e o corpo até o próximo heading como resposta, gravando o resultado em `data/parsed/<source_id>.jsonl` com os campos `{source_id, raw_question, raw_answer, topic_hint}`.

#### Scenario: Markdown com headings e respostas
- **WHEN** `python -m pipeline parse` processa um arquivo com headings seguidos de corpo de texto
- **THEN** cada heading vira `raw_question` e o corpo correspondente vira `raw_answer` no JSONL de saída

#### Scenario: Lista de perguntas sem resposta
- **WHEN** a fonte contém perguntas sem corpo de resposta (caso Mindorks)
- **THEN** o par é emitido com `raw_answer: null` para que a resposta seja gerada pelo LLM na etapa seguinte

### Requirement: Normalização de conteúdo
O parser SHALL remover badges, imagens e links quebrados do texto extraído e MUST preservar blocos de código intactos.

#### Scenario: Resposta com badge e bloco de código
- **WHEN** uma resposta contém um badge de imagem e um bloco de código cercado
- **THEN** o badge é removido e o bloco de código permanece íntegro no `raw_answer`

### Requirement: Fallback contra mudança de estrutura da fonte
Se a extração de uma fonte produzir menos pares que o mínimo esperado configurado (`min_expected_pairs`), o pipeline SHALL alertar e MUST NOT sobrescrever o arquivo parsed anterior daquela fonte.

#### Scenario: Extração abaixo do limiar
- **WHEN** `parse` extrai menos pares que `min_expected_pairs` da fonte e existe um parsed anterior
- **THEN** o pipeline emite alerta e mantém o `data/parsed/<source_id>.jsonl` anterior intacto
