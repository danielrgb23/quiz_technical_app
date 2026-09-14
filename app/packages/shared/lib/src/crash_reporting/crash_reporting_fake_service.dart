import 'crash_reporting_service.dart';

/// No-op implementation used in dev so no Firebase call ever happens
/// outside stg/prod (see openspec firebase-integration spec).
class FakeCrashReportingService implements CrashReportingService {
  @override
  Future<void> recordError(dynamic exception, StackTrace? stackTrace) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> log(String message) async {}
}
