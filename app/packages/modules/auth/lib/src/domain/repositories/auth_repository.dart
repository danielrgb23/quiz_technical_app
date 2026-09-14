import 'package:core/core.dart';

import '../entities/user.dart';

abstract class AuthRepository {
  Future<Result<User>> login({required String email, required String password});
  Future<Result<User>> register({
    required String email,
    required String password,
    required String name,
  });

  /// Signs in an anonymous session (guest mode). Safe to call repeatedly —
  /// returns the existing anonymous session if there already is one. If
  /// there's no network, falls back to a local-only guest session (id
  /// [localGuestId]) so the user is never blocked offline; call
  /// [retryPendingGuestLogin] once connectivity is back to upgrade it to a
  /// real Firebase anonymous uid (needed before anything can sync).
  Future<Result<User>> loginAnonymously();

  /// No-op unless the current session is the local-only placeholder guest
  /// (see [loginAnonymously]). Best-effort — swallows network failures.
  Future<void> retryPendingGuestLogin();

  /// Upgrades the current anonymous session into a permanent account,
  /// preserving its uid and therefore all progress already synced under
  /// it. On [AccountExistsFailure] the caller should re-attempt via
  /// [login] with the same credentials and merge progress explicitly.
  Future<Result<User>> linkWithEmailPassword({
    required String email,
    required String password,
    required String name,
  });

  /// Same idea as [linkWithEmailPassword]/[login] but for Google — links
  /// if there's a guest session, signs in directly otherwise. On
  /// [AccountExistsFailure] the caller should finish via
  /// [signInWithFailedCredential] instead of redoing the Google flow.
  Future<Result<User>> loginWithGoogle();

  /// Completes a sign-in using the credential carried by an
  /// [AccountExistsFailure] returned from [linkWithEmailPassword] or
  /// [loginWithGoogle].
  Future<Result<User>> signInWithFailedCredential(AccountExistsFailure failure);

  /// Updates the avatar shown for the current user (Google sign-in sets
  /// this automatically; this covers manual uploads too).
  Future<Result<User>> updateAvatarUrl(String url);

  Future<Result<void>> logout();
  Future<Result<User>> getCurrentUser();
  Future<Result<bool>> get isAuthenticated;

  /// Firebase uid of the current session (anonymous or not), or null if
  /// nobody has ever signed in on this device.
  String? get currentUid;

  /// Whether the current session is a guest (anonymous) one — decides
  /// whether "criar conta" should link (preserve progress) or register a
  /// brand new account.
  bool get isCurrentUserAnonymous;
}
