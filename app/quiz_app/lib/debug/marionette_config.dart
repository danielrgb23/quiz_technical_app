import 'package:design_system/design_system.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:marionette_logger/marionette_logger.dart';

/// Collector shared by Marionette (`get_logs`) and `AppLogger`.
final LoggerLogCollector marionetteLogCollector = LoggerLogCollector();

/// Teaches Marionette about the design_system widgets. Only imported from
/// `main_dev.dart`, behind `kDebugMode`.
MarionetteConfiguration marionetteConfiguration() => MarionetteConfiguration(
  logCollector: marionetteLogCollector,
  isInteractiveElement: (element) => switch (element.widget) {
    DsButton() || DsTextField() || DsCard() || DsFlipCard() => true,
    _ => false,
  },
  extractText: (element) {
    final widget = element.widget;
    if (widget is DsButton) return widget.label;
    if (widget is DsTextField) return widget.label ?? widget.hint;
    return null;
  },
);
