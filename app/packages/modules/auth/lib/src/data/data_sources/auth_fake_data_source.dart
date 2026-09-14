import 'package:firebase_auth/firebase_auth.dart' show EmailAuthProvider;

import '../dtos/user_dto.dart';
import 'auth_local_data_source.dart';
import 'auth_remote_data_source.dart';

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  static const _fakeUser = UserDto(
    id: 'fake-user-1',
    email: 'dev@monoapp.com',
    name: 'Dev User',
    avatarUrl: null,
    isEmailVerified: true,
  );

  static const _fakeAnonymousUser = UserDto(
    id: 'fake-anon-1',
    email: '',
    name: '',
    avatarUrl: null,
    isAnonymous: true,
  );

  static const _fakeGoogleUser = UserDto(
    id: 'fake-google-1',
    email: 'dev.google@monoapp.com',
    name: 'Dev Google User',
    avatarUrl: null,
    isEmailVerified: true,
  );

  /// Use este e-mail em dev para exercitar o caminho "conta já existe" do
  /// fluxo de merge (RegisterCubit/LoginCubit) sem precisar de Firebase.
  static const existingAccountTestEmail = 'existing@test.dev';

  /// Começa deslogado — como o Firebase real — para a tela de login
  /// aparecer em dev também (null = nenhuma sessão ainda).
  UserDto? _current;

  @override
  Future<UserDto> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _current = _fakeUser;
    return _current!;
  }

  @override
  Future<UserDto> register({
    required String email,
    required String password,
    required String name,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _current = _fakeUser.copyWith(email: email, name: name);
    return _current!;
  }

  @override
  Future<UserDto> loginAnonymously() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _current = _fakeAnonymousUser;
    return _current!;
  }

  @override
  Future<UserDto> linkWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (email == existingAccountTestEmail) {
      throw AccountAlreadyExistsException(
        email: email,
        credential: EmailAuthProvider.credential(
          email: email,
          password: password,
        ),
      );
    }
    _current = _fakeUser.copyWith(
      email: email,
      name: name,
      isAnonymous: false,
    );
    return _current!;
  }

  @override
  Future<UserDto> loginWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _current = _fakeGoogleUser;
    return _current!;
  }

  @override
  Future<UserDto> signInWithCredential(Object credential) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _current = _fakeGoogleUser;
    return _current!;
  }

  @override
  Future<UserDto> updateAvatarUrl(String url) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final current = _current;
    if (current == null) throw StateError('No signed-in user');
    _current = current.copyWith(avatarUrl: url);
    return _current!;
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _current = null;
  }

  @override
  Future<UserDto> getCurrentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final current = _current;
    if (current == null) {
      throw StateError('No signed-in user');
    }
    return current;
  }

  @override
  String? get currentUid => _current?.id;

  @override
  bool get isAnonymous => _current?.isAnonymous ?? false;
}

class FakeAuthLocalDataSource implements AuthLocalDataSource {
  UserDto? _cachedUser;

  @override
  Future<UserDto?> getCachedUser() async => _cachedUser;

  @override
  Future<void> cacheUser(UserDto user) async => _cachedUser = user;

  @override
  Future<void> clearCache() async => _cachedUser = null;
}
