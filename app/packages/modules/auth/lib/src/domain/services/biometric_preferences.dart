import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

/// Whether the user opted into biometric app-unlock, and whether we've
/// already asked. Just a preference flag — not sensitive, so plain
/// [LocalStorage] (unlike the cached user/profile, which use
/// [SecureStorage]).
@lazySingleton
class BiometricPreferences {
  BiometricPreferences(this._localStorage);

  final LocalStorage _localStorage;

  static const _enabledKey = 'biometric_enabled';
  static const _promptedKey = 'biometric_prompted';

  Future<bool> get isEnabled async =>
      await _localStorage.getBool(_enabledKey) ?? false;

  Future<void> setEnabled(bool value) =>
      _localStorage.setBool(_enabledKey, value: value);

  Future<bool> get wasPrompted async =>
      await _localStorage.getBool(_promptedKey) ?? false;

  Future<void> markPrompted() =>
      _localStorage.setBool(_promptedKey, value: true);
}

/// In-memory "unlocked this app session" flag — reset on every cold
/// start by construction (it's a fresh singleton), which is exactly the
/// point: biometric unlock is required once per launch, not once ever.
@lazySingleton
class BiometricSessionGate {
  bool unlocked = false;
}
