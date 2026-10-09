import 'dart:convert';

import 'package:core/core.dart';
import 'package:firebase_auth/firebase_auth.dart' show EmailAuthProvider;

import '../dtos/user_dto.dart';
import 'auth_local_data_source.dart';
import 'auth_remote_data_source.dart';

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  FakeAuthRemoteDataSource(this._storage);

  /// Espelha o Firebase real, que persiste o refresh token: em dev a sessão
  /// fake também sobrevive a reinícios, até o logout.
  final SecureStorage _storage;

  static const _sessionKey = 'fake_session_user';

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

  /// Restaura a sessão persistida; chamar uma vez no bootstrap de dev.
  Future<void> restoreSession() async {
    final raw = await _storage.read(_sessionKey);
    if (raw == null) return;
    _current = UserDto.fromJson(json.decode(raw) as Map<String, dynamic>);
  }

  Future<UserDto?> _persist(UserDto? user) async {
    _current = user;
    if (user == null) {
      await _storage.delete(_sessionKey);
    } else {
      await _storage.write(_sessionKey, json.encode(user.toJson()));
    }
    return user;
  }

  @override
  Future<UserDto> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return (await _persist(_fakeUser))!;
  }

  @override
  Future<UserDto> register({
    required String email,
    required String password,
    required String name,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return (await _persist(_fakeUser.copyWith(email: email, name: name)))!;
  }

  @override
  Future<UserDto> loginAnonymously() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return (await _persist(_fakeAnonymousUser))!;
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
    return (await _persist(
      _fakeUser.copyWith(email: email, name: name, isAnonymous: false),
    ))!;
  }

  @override
  Future<UserDto> loginWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return (await _persist(_fakeGoogleUser))!;
  }

  @override
  Future<UserDto> signInWithCredential(Object credential) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return (await _persist(_fakeGoogleUser))!;
  }

  @override
  Future<UserDto> updateAvatarUrl(String url) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final current = _current;
    if (current == null) throw StateError('No signed-in user');
    return (await _persist(current.copyWith(avatarUrl: url)))!;
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await _persist(null);
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
