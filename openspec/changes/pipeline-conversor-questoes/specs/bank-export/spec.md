# bank-export

## ADDED Requirements

### Requirement: Export do banco JSON versionado
O comando `export` SHALL gravar o conjunto validado em `data/output/questions_v<N>.json`; com a flag `--bump` a versão SHALL ser incrementada, sem a flag a versão corrente é regravada.

#### Scenario: Primeiro export
- **WHEN** `python -m pipeline export --bump` roda pela primeira vez
- **THEN** `data/output/questions_v1.json` é criado

#### Scenario: Export sem bump
- **WHEN** `export` roda sem `--bump` com a versão 1 existente
- **THEN** `questions_v1.json` é regravado sem criar nova versão

### Requirement: Manifest com fontes, licenças e checksum
O export SHALL gravar `data/output/manifest.json` com `{version, generatedAt, count, sources[], checksum}`, onde `sources[]` lista todas as fontes com repo e licença, e `checksum` é o SHA-256 do arquivo de questões da versão exportada.

#### Scenario: Manifest gerado
- **WHEN** `export` conclui
- **THEN** `manifest.json` contém a versão, contagem de questões, todas as fontes com suas licenças e o checksum válido do arquivo exportado

### Requirement: Comando run executa o pipeline completo
O comando `run` SHALL executar `fetch`, `parse`, `generate`, `validate` e `export` em sequência, interrompendo em falha de etapa.

#### Scenario: Execução completa do zero
- **WHEN** `python -m pipeline run` roda do zero com fontes acessíveis e API configurada
- **THEN** um `questions_v1.json` válido é produzido com manifest correspondente
