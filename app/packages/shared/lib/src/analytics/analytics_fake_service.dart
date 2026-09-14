import 'analytics_service.dart';

/// No-op implementation used in dev so no Firebase call ever happens
/// outside stg/prod (see openspec firebase-integration spec).
class FakeAnalyticsService implements AnalyticsService {
  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setUserProperty(String name, String value) async {}

  @override
  Future<void> logScreenView(String screenName) async {}
}
