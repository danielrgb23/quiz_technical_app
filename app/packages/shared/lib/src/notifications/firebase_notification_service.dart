import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';

import 'notification_service.dart';

/// Top-level, `@pragma('vm:entry-point')`-annotated per FCM's requirement
/// — background messages run in a separate isolate with no access to app
/// state, so this can only log/no-op, not touch Firestore or GetIt.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

@LazySingleton(as: NotificationService)
class FirebaseNotificationService implements NotificationService {
  FirebaseNotificationService()
    : _messaging = FirebaseMessaging.instance,
      _firestore = FirebaseFirestore.instance {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(
      (m) => _controller.add(m.data),
    );
    FirebaseMessaging.onMessageOpenedApp.listen(
      (m) => _controller.add(m.data),
    );
  }

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get onMessage => _controller.stream;

  @override
  Future<void> initialize({required String uid}) async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final settings = await _messaging.requestPermission();
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!granted) return;

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _controller.add(initialMessage.data);

    final token = await _messaging.getToken();
    if (token != null) await _saveToken(uid, token);
    _messaging.onTokenRefresh.listen((newToken) => _saveToken(uid, newToken));
  }

  Future<void> _saveToken(String uid, String token) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('fcm_tokens')
        .doc(token)
        .set({'updatedAt': FieldValue.serverTimestamp()});
  }
}
