import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:injectable/injectable.dart';

abstract class AnalyticsService {
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters});
  Future<void> setUserId(String? userId);
  Future<void> setUserProperty(String name, String value);
  Future<void> logScreenView(String screenName);
}

@LazySingleton(as: AnalyticsService)
class AnalyticsServiceImpl implements AnalyticsService {
  AnalyticsServiceImpl() : _analytics = FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) {
    return _analytics.logEvent(
      name: name,
      parameters: parameters?.cast<String, Object>(),
    );
  }

  @override
  Future<void> setUserId(String? userId) => _analytics.setUserId(id: userId);

  @override
  Future<void> setUserProperty(String name, String value) =>
      _analytics.setUserProperty(name: name, value: value);

  @override
  Future<void> logScreenView(String screenName) =>
      _analytics.logScreenView(screenName: screenName);
}
