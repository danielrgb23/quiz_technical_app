/// Push notifications abstraction (Firebase Cloud Messaging behind it in
/// stg/prod; dev keeps a no-op fake — same rule as Analytics/Crashlytics).
abstract class NotificationService {
  /// Requests OS permission (iOS: explicit prompt; Android 13+:
  /// POST_NOTIFICATIONS runtime permission) and, if granted, obtains the
  /// device token and registers it for the given uid so a backend can
  /// target this device. Safe to call multiple times.
  Future<void> initialize({required String uid});

  /// Stream of notification payloads (`data` map) for messages tapped
  /// while the app was backgrounded/terminated, or received in the
  /// foreground. Screens can listen to this to deep-link on tap.
  Stream<Map<String, dynamic>> get onMessage;
}
