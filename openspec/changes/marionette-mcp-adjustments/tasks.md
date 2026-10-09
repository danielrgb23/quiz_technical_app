# Tasks — Ajustes de integração do Marionette MCP

## 1. Logs

- [x] 1.1 Adicionar `marionette_logger` ao `quiz_app`
- [x] 1.2 Criar `AppLogger.attachOutput` em `core` (MultiOutput console + extra)
- [x] 1.3 Conectar `LoggerLogCollector` em `main_dev.dart` (kDebugMode)

## 2. Design system

- [x] 2.1 Criar `lib/debug/marionette_config.dart` com `isInteractiveElement` e `extractText`
- [x] 2.2 Passar a configuração ao `MarionetteBinding.ensureInitialized`

## 3. Verificação

- [x] 3.1 `dart analyze` limpo em `quiz_app`, `core` e `design_system`
- [x] 3.2 Rodar `flutter run -t lib/main_dev.dart`, conectar e validar `get_interactive_elements` (botões e campos de login) e `get_logs`
- [x] 3.3 Config estendida se faltasse widget (nenhum faltou)
- [ ] 3.4 Arquivar a change (`/opsx:archive`)
