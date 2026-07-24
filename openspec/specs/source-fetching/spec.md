# source-fetching Specification

## Purpose
TBD - created by archiving change pipeline-conversor-questoes. Update Purpose after archive.
## Requirements
### Requirement: Download de fontes declaradas em sources.yaml
O pipeline SHALL baixar os arquivos markdown de cada fonte listada em `sources.yaml` via `raw.githubusercontent.com`, sem clone do repositório, e gravá-los em `data/raw/<source_id>/`.

#### Scenario: Fetch inicial
- **WHEN** `python -m pipeline fetch` é executado com `sources.yaml` válido e sem cache prévio
- **THEN** cada arquivo declarado de cada fonte é baixado e salvo em `data/raw/<source_id>/<arquivo>`

#### Scenario: Fonte inacessível
- **WHEN** o download de uma fonte falha (HTTP != 200 ou erro de rede)
- **THEN** o pipeline reporta o erro para aquela fonte, preserva o cache existente e continua com as demais fontes

### Requirement: Cache por hash de conteúdo
O pipeline SHALL gravar o hash SHA-256 do conteúdo de cada arquivo baixado e SHALL sinalizar como inalterado o arquivo cujo hash não mudou, permitindo às etapas seguintes pular reprocessamento.

#### Scenario: Conteúdo inalterado
- **WHEN** `fetch` é executado e o conteúdo baixado tem o mesmo hash do cache
- **THEN** o arquivo é marcado como inalterado e nenhum reprocessamento é sinalizado para as etapas seguintes

#### Scenario: Conteúdo alterado
- **WHEN** `fetch` é executado e o conteúdo baixado difere do hash em cache
- **THEN** o arquivo em `data/raw/` e seu hash são atualizados e a fonte é marcada para reprocessamento

### Requirement: Registro de licença por fonte
Cada fonte em `sources.yaml` MUST declarar o campo `license`, e o pipeline SHALL falhar o fetch de uma fonte sem licença declarada.

#### Scenario: Fonte sem licença
- **WHEN** `sources.yaml` contém uma fonte sem o campo `license`
- **THEN** o pipeline aborta com mensagem indicando a fonte inválida

