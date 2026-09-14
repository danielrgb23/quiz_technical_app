import 'biometric_auth_service.dart';

/// Dev fake: pretends biometrics are available and always succeed, so
/// the opt-in prompt and lock screen are exercisable without a real
/// device sensor.
class FakeBiometricAuthService implements BiometricAuthService {
  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<bool> authenticate({required String reason}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return true;
  }
}
