import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import '../dtos/user_dto.dart';

abstract class AuthRemoteDataSource {
  Future<UserDto> login({required String email, required String password});
  Future<UserDto> register({
    required String email,
    required String password,
    required String name,
  });
  Future<UserDto> loginAnonymously();

  /// Upgrades the current anonymous session to a permanent email/password
  /// account, preserving the uid (Firebase `linkWithCredential`). Throws
  /// [AccountAlreadyExistsException] when the email already belongs to a
  /// different account — callers should sign in to that account instead.
  Future<UserDto> linkWithEmailPassword({
    required String email,
    required String password,
    required String name,
  });

  /// Signs in with Google — upgrades (links) the current session if it's
  /// anonymous, or signs in directly otherwise. Throws
  /// [AccountAlreadyExistsException] (same as [linkWithEmailPassword]) if
  /// the Google account already belongs to a different Firebase user;
  /// its `credential` can be handed straight to [signInWithCredential] to
  /// finish signing into that account, no need to redo the Google flow.
  Future<UserDto> loginWithGoogle();

  /// Completes a sign-in with a credential obtained earlier (namely from
  /// [AccountAlreadyExistsException.credential]).
  Future<UserDto> signInWithCredential(Object credential);

  Future<void> logout();
  Future<UserDto> getCurrentUser();

  /// Updates the current user's photo URL (Google sign-in already sets
  /// this automatically; used for manual avatar uploads too, so avatarUrl
  /// always has one source of truth: Firebase Auth's own profile).
  Future<UserDto> updateAvatarUrl(String url);

  String? get currentUid;
  bool get isAnonymous;
}

/// Thrown by [AuthRemoteDataSource.linkWithEmailPassword]/[loginWithGoogle]
/// when the credential already belongs to a different account.
/// [credential] lets the caller finish signing into that existing account
/// without asking the user to redo the login flow.
class AccountAlreadyExistsException implements Exception {
  const AccountAlreadyExistsException({
    required this.email,
    required this.credential,
  });

  final String email;
  final fb.AuthCredential credential;
}

@LazySingleton(as: AuthRemoteDataSource)
class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  FirebaseAuthRemoteDataSource()
    : _auth = fb.FirebaseAuth.instance,
      _googleSignIn = GoogleSignIn();

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  Future<UserDto> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapUser(credential.user!);
  }

  @override
  Future<UserDto> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(name);
    return _mapUser(credential.user!, nameOverride: name);
  }

  @override
  Future<UserDto> loginAnonymously() async {
    final credential = await _auth.signInAnonymously();
    return _mapUser(credential.user!);
  }

  @override
  Future<UserDto> linkWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    final current = _auth.currentUser;
    final authCredential = fb.EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    if (current == null || !current.isAnonymous) {
      // No anonymous session to upgrade — fall back to a plain sign-in.
      final credential = await _auth.signInWithCredential(authCredential);
      return _mapUser(credential.user!);
    }
    try {
      final linked = await current.linkWithCredential(authCredential);
      await linked.user!.updateDisplayName(name);
      return _mapUser(linked.user!, nameOverride: name);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use') {
        throw AccountAlreadyExistsException(
          email: email,
          credential: authCredential,
        );
      }
      rethrow;
    }
  }

  @override
  Future<UserDto> loginWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw fb.FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Google sign-in was cancelled',
      );
    }
    final googleAuth = await googleUser.authentication;
    final authCredential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final current = _auth.currentUser;
    if (current == null || !current.isAnonymous) {
      final credential = await _auth.signInWithCredential(authCredential);
      return _mapUser(credential.user!);
    }
    try {
      final linked = await current.linkWithCredential(authCredential);
      return _mapUser(linked.user!);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use') {
        throw AccountAlreadyExistsException(
          email: googleUser.email,
          credential: authCredential,
        );
      }
      rethrow;
    }
  }

  @override
  Future<UserDto> signInWithCredential(Object credential) async {
    final result = await _auth.signInWithCredential(
      credential as fb.AuthCredential,
    );
    return _mapUser(result.user!);
  }

  @override
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  @override
  Future<UserDto> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw fb.FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user',
      );
    }
    return _mapUser(user);
  }

  @override
  Future<UserDto> updateAvatarUrl(String url) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw fb.FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user',
      );
    }
    await user.updatePhotoURL(url);
    await user.reload();
    return _mapUser(_auth.currentUser!);
  }

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  UserDto _mapUser(fb.User user, {String? nameOverride}) => UserDto(
    id: user.uid,
    email: user.email ?? '',
    name: nameOverride ?? user.displayName ?? '',
    avatarUrl: user.photoURL,
    isEmailVerified: user.emailVerified,
    isAnonymous: user.isAnonymous,
  );
}
