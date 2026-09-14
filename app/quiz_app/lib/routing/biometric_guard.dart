import 'package:auth_flow/auth_flow.dart';
import 'package:auth_module/auth_module.dart';
import 'package:auto_route/auto_route.dart';
import 'package:get_it/get_it.dart';

/// Runs after [AuthGuard]: if the user opted into biometric unlock and
/// this app session hasn't been unlocked yet, redirects to
/// [BiometricLockPage] instead of letting them straight into Home.
/// Convenience gate only — SecureStorage/Firebase Auth are what actually
/// protect the data behind it.
class BiometricGuard extends AutoRouteGuard {
  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final gate = GetIt.I<BiometricSessionGate>();
    if (gate.unlocked) {
      resolver.next();
      return;
    }
    final enabled = await GetIt.I<BiometricPreferences>().isEnabled;
    if (!enabled) {
      resolver.next();
    } else {
      resolver.redirectUntil(const BiometricLockRoute());
    }
  }
}
