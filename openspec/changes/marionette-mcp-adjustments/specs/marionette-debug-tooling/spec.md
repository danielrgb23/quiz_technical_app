# marionette-debug-tooling

## ADDED Requirements

### Requirement: Marionette ativo somente em debug da flavor dev
O `MarionetteBinding` MUST ser inicializado apenas quando `kDebugMode` for verdadeiro em `main_dev.dart`; `main_stg.dart` e `main_prod.dart` MUST NOT referenciá-lo.

#### Scenario: Build release
- **WHEN** o app é compilado em modo release
- **THEN** o `WidgetsFlutterBinding` padrão é usado e nenhuma extensão Marionette é registrada

### Requirement: Widgets do design system são visíveis ao agente
`DsButton`, `DsTextField`, `DsCard` e `DsFlipCard` SHALL ser reconhecidos como interativos, e `DsButton.label` / `DsTextField.label` SHALL ser extraídos como texto.

#### Scenario: Tap por texto
- **WHEN** o agente chama `tap(text: <label de um DsButton>)`
- **THEN** o botão é encontrado e acionado

#### Scenario: Listagem de elementos
- **WHEN** o agente chama `get_interactive_elements` em uma tela com `DsTextField`
- **THEN** o campo aparece na listagem

### Requirement: Logs do AppLogger disponíveis via get_logs
Em debug na flavor dev, todo log emitido por `AppLogger` SHALL ser entregue ao `LoggerLogCollector` do Marionette, sem remover a saída de console.

#### Scenario: Log após ação
- **WHEN** o app chama `AppLogger.info('x')`
- **THEN** `get_logs` contém `x` e o console também o exibe

### Requirement: Comportamento padrão do AppLogger preservado
Sem `attachOutput`, `AppLogger` MUST se comportar como antes (apenas console, nível por ambiente).
