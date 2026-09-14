import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:injectable/injectable.dart';

abstract class CrashReportingService {
  Future<void> recordError(dynamic exception, StackTrace? stackTrace);
  Future<void> setUserId(String? userId);
  Future<void> log(String message);
}

@LazySingleton(as: CrashReportingService)
class CrashReportingServiceImpl implements CrashReportingService {
  CrashReportingServiceImpl() : _crashlytics = FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(dynamic exception, StackTrace? stackTrace) {
    return _crashlytics.recordError(exception, stackTrace);
  }

  @override
  Future<void> setUserId(String? userId) =>
      _crashlytics.setUserIdentifier(userId ?? '');

  @override
  Future<void> log(String message) => _crashlytics.log(message);
}
