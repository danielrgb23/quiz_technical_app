import 'dart:async';

import 'notification_service.dart';

/// No-op: dev never calls Firebase (firebase-integration spec).
class FakeNotificationService implements NotificationService {
  @override
  Future<void> initialize({required String uid}) async {}

  @override
  Stream<Map<String, dynamic>> get onMessage => const Stream.empty();
}
