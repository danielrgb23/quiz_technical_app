import 'package:firebase_app_check/firebase_app_check.dart';

/// Activates Firebase App Check so Firestore/Storage/Auth can verify
/// requests actually come from this app (not a forged client) — App
/// Attest on iOS, Play Integrity on Android.
///
/// [useDebugProviders] should be true for stg/local testing (simulators
/// and emulators can't produce real App Attest/Play Integrity tokens);
/// each debug install prints a token that must be added once in the
/// Firebase Console (App Check > Apps > Manage debug tokens) — this
/// activates monitoring only, it does NOT turn on enforcement, so
/// nothing breaks even without registering a token.
Future<void> activateAppCheck({required bool useDebugProviders}) {
  return FirebaseAppCheck.instance.activate(
    providerApple: useDebugProviders
        ? const AppleDebugProvider()
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    providerAndroid: useDebugProviders
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
  );
}
