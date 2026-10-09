import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:shared/shared.dart';

import 'app.dart';
import 'debug/marionette_config.dart';
import 'di/injection.dart';

// dev never talks to Firebase (openspec firebase-integration spec) — no
// Firebase.initializeApp() here, only in main_stg.dart / main_prod.dart.
void main() {
  runZonedGuarded(
    () async {
      // Marionette lets AI agents drive the debug app via MCP (see /.mcp.json).
      if (kDebugMode) {
        MarionetteBinding.ensureInitialized(marionetteConfiguration());
        AppLogger.attachOutput(marionetteLogCollector);
        AppLogger.info('Marionette log collector attached', tag: 'Marionette');
      } else {
        WidgetsFlutterBinding.ensureInitialized();
      }

      FlutterError.onError = (details) {
        AppLogger.error(
          details.exceptionAsString(),
          tag: 'FlutterError',
          error: details.exception,
          stackTrace: details.stack,
        );
        _recordCrash(details.exception, details.stack);
      };

      await configureDependencies('dev');
      await bootstrapQuestionBank();
      runApp(const App());
    },
    (error, stack) {
      AppLogger.error(
        'Uncaught error',
        tag: 'Zone',
        error: error,
        stackTrace: stack,
      );
      _recordCrash(error, stack);
    },
  );
}

/// GetIt may not be configured yet if the crash happens during startup,
/// so this is best-effort and must never throw.
void _recordCrash(Object error, StackTrace? stackTrace) {
  if (!GetIt.I.isRegistered<CrashReportingService>()) return;
  unawaited(GetIt.I<CrashReportingService>().recordError(error, stackTrace));
}
