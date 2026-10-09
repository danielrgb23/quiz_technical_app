import 'package:logger/logger.dart' as logger_pkg;

import '../env/env_config.dart';

class AppLogger {
  AppLogger._();

  static logger_pkg.Logger _logger = _build();

  static logger_pkg.Logger _build({logger_pkg.LogOutput? extraOutput}) {
    return logger_pkg.Logger(
      printer: logger_pkg.PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
      ),
      level:
          EnvConfig.isProd ? logger_pkg.Level.warning : logger_pkg.Level.debug,
      output: extraOutput == null
          ? null
          : logger_pkg.MultiOutput([logger_pkg.ConsoleOutput(), extraOutput]),
    );
  }

  /// Mirrors every log line to [output] in addition to the console
  /// (e.g. the Marionette log collector in debug builds).
  static void attachOutput(logger_pkg.LogOutput output) {
    _logger = _build(extraOutput: output);
  }

  static void debug(String message, {String? tag}) {
    _logger.d(_format(message, tag));
  }

  static void info(String message, {String? tag}) {
    _logger.i(_format(message, tag));
  }

  static void warning(String message, {String? tag, Object? error}) {
    _logger.w(_format(message, tag), error: error);
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.e(_format(message, tag), error: error, stackTrace: stackTrace);
  }

  static String _format(String message, String? tag) {
    return tag != null ? '[$tag] $message' : message;
  }
}
