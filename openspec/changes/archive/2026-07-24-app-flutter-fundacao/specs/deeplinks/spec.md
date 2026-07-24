# deeplinks

## ADDED Requirements

### Requirement: Rotas profundas declaradas no auto_route
O router SHALL declarar as rotas `/quiz/{topic}`, `/question/{id}` e `/daily` com deep link handling, acessíveis com o app fechado e aberto.

#### Scenario: Deeplink com app fechado
- **WHEN** `quizapp://quiz/flutter` é aberto com o app fechado
- **THEN** o app inicia e navega direto para a rota do tópico flutter

#### Scenario: Deeplink com app aberto
- **WHEN** `https://<dominio>/quiz/flutter` é aberto com o app em foreground
- **THEN** o app navega para a rota sem reiniciar

### Requirement: Custom scheme e App/Universal Links
O app SHALL registrar o scheme `quizapp://` (fallback) e App Links Android (`intent-filter` com `autoVerify=true`) / Universal Links iOS (Associated Domains) para `https://<dominio>/...`.

#### Scenario: Configuração das plataformas
- **WHEN** os manifests Android e entitlements iOS são inspecionados
- **THEN** contêm o scheme customizado e a configuração de App/Universal Links para o domínio

### Requirement: Guard para conteúdo indisponível
Um guard de rota SHALL verificar se o conteúdo referenciado pelo deeplink existe localmente; se não existir, SHALL exibir tela de fallback com CTA em vez de erro.

#### Scenario: Questão inexistente
- **WHEN** `/question/{id}` referencia um id ausente do banco local
- **THEN** a tela de fallback com CTA é exibida
