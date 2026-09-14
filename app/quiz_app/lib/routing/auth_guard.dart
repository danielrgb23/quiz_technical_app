import 'package:auth_flow/auth_flow.dart';
import 'package:auth_module/auth_module.dart';
import 'package:auto_route/auto_route.dart';
import 'package:get_it/get_it.dart';

/// Blocks entry into the app until there's a session — even a guest one.
/// Only the very first launch (before any choice was made) redirects to
/// [LoginRoute]; once a session exists (anonymous or not) this always
/// lets navigation through.
class AuthGuard extends AutoRouteGuard {
  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final result = await GetIt.I<AuthRepository>().isAuthenticated;
    if (result.dataOrNull ?? false) {
      resolver.next();
    } else {
      resolver.redirectUntil(const LoginRoute());
    }
  }
}
