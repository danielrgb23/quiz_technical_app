# Design

## Decisões

- **Config em arquivo próprio** (`lib/debug/marionette_config.dart`), importado só por `main_dev.dart`: mantém a introspecção do design system fora de stg/prod.
- **`isInteractiveElement` (não `isInteractiveWidget`)**: casa por `is`, cobrindo subclasses e genéricos. `shouldStopTraversalAtElement` fica `null` (reduz cobertura de widgets na prática).
- **`extractText`**: `DsButton.label` e `DsTextField.label ?? hint`. Os demais widgets já expõem `Text` interno.
- **`AppLogger.attachOutput`**: reconstrói o `Logger` com `MultiOutput([ConsoleOutput, extra])`. Alternativa descartada: `core` depender de `marionette_logger` (acoplaria código de produção a tooling de debug).
- Logs chegam ao agente com o formato do `PrettyPrinter` (linhas com moldura); aceitável para debug.

## Riscos

- `AppLogger.attachOutput` substitui o logger estático; chamadas devem ocorrer antes de logs relevantes (no início do `main`).
- `marionette_flutter`/`marionette_logger` ficam no `pubspec` do app; o código não é referenciado em stg/prod e é removido por tree-shaking.
