import 'dart:async';

import 'package:core/core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/shared.dart';

import 'app.dart';
import 'di/injection.dart';
import 'firebase_options.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Simulators/emulators can't produce real App Attest/Play Integrity
      // tokens — debug providers here, real ones in main_prod.dart.
      await activateAppCheck(useDebugProviders: true);

      FlutterError.onError = (details) {
        AppLogger.error(
          details.exceptionAsString(),
          tag: 'FlutterError',
          error: details.exception,
          stackTrace: details.stack,
        );
        _recordCrash(details.exception, details.stack);
      };

      await configureDependencies('stg');
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
