import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

/// Device-local biometric check (Face ID/Touch ID/fingerprint) — a
/// convenience second factor for re-entering the app faster, never the
/// sole guardian of sensitive data (that's SecureStorage's job; this
/// only gates the UI).
abstract class BiometricAuthService {
  Future<bool> get isAvailable;
  Future<bool> authenticate({required String reason});
}

@LazySingleton(as: BiometricAuthService)
class LocalAuthBiometricService implements BiometricAuthService {
  LocalAuthBiometricService() : _auth = LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> get isAvailable async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}
