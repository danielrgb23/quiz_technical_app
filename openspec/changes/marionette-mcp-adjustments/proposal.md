# Ajustes de integração do Marionette MCP

## Why

O Marionette MCP foi integrado ao app (binding + `.mcp.json` + skill), mas em modo zero-config: o agente não reconhece os widgets do `design_system` (`DsButton`, `DsTextField`, `DsCard`, `DsFlipCard`) e `get_logs` não retorna nada, pois o `AppLogger` (pacote `logger`) não alimenta nenhum `LogCollector`.

## What Changes

- `MarionetteConfiguration` dedicada em `lib/debug/marionette_config.dart`, com `isInteractiveElement` e `extractText` para os widgets do design system.
- `marionette_logger` adicionado; `LoggerLogCollector` compartilhado entre Marionette e `AppLogger`.
- `AppLogger.attachOutput(LogOutput)` em `core`, que espelha os logs para uma saída extra além do console.
- `main_dev.dart` usa a configuração e conecta o coletor, apenas em `kDebugMode`.

## Capabilities

### New Capabilities

- `marionette-debug-tooling`: wiring do Marionette restrito a debug da flavor dev, com reconhecimento do design system e coleta de logs.

### Modified Capabilities

(nenhuma)

## Impact

- `app/quiz_app/pubspec.yaml` (+ `marionette_logger`), `lib/main_dev.dart`, novo `lib/debug/marionette_config.dart`.
- `app/packages/core/lib/src/logger/app_logger.dart`: novo método `attachOutput`; comportamento padrão inalterado.
- Flavors stg/prod e builds release não são afetados.
