import 'package:core/core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:injectable/injectable.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/auth_local_data_source.dart';
import '../data_sources/auth_remote_data_source.dart';
import '../dtos/user_dto.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) => _guard(() async {
    final dto = await _remoteDataSource.login(email: email, password: password);
    await _localDataSource.cacheUser(dto);
    return dto.toEntity();
  });

  @override
  Future<Result<User>> register({
    required String email,
    required String password,
    required String name,
  }) => _guard(() async {
    final dto = await _remoteDataSource.register(
      email: email,
      password: password,
      name: name,
    );
    await _localDataSource.cacheUser(dto);
    return dto.toEntity();
  });

  @override
  Future<Result<User>> loginAnonymously() async {
    try {
      final dto = await _remoteDataSource.loginAnonymously();
      await _localDataSource.cacheUser(dto);
      return Result.success(dto.toEntity());
    } catch (e, st) {
      if (!_isNetworkError(e)) return Result.failure(_mapError(e, st));
      // Offline: never block guest entry — cache a local placeholder and
      // let retryPendingGuestLogin() upgrade it once back online.
      const guest = UserDto(
        id: localGuestId,
        email: '',
        name: '',
        isAnonymous: true,
      );
      await _localDataSource.cacheUser(guest);
      return Result.success(guest.toEntity());
    }
  }

  @override
  Future<void> retryPendingGuestLogin() async {
    final cached = await _localDataSource.getCachedUser();
    if (cached?.id != localGuestId) return;
    try {
      final dto = await _remoteDataSource.loginAnonymously();
      await _localDataSource.cacheUser(dto);
    } catch (_) {
      // Still offline or transient failure — next retry picks it up.
    }
  }

  @override
  Future<Result<User>> linkWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) => _guard(() async {
    final dto = await _remoteDataSource.linkWithEmailPassword(
      email: email,
      password: password,
      name: name,
    );
    await _localDataSource.cacheUser(dto);
    return dto.toEntity();
  });

  @override
  Future<Result<User>> loginWithGoogle() => _guard(() async {
    final dto = await _remoteDataSource.loginWithGoogle();
    await _localDataSource.cacheUser(dto);
    return dto.toEntity();
  });

  @override
  Future<Result<User>> signInWithFailedCredential(
    AccountExistsFailure failure,
  ) => _guard(() async {
    final dto = await _remoteDataSource.signInWithCredential(
      failure.credential,
    );
    await _localDataSource.cacheUser(dto);
    return dto.toEntity();
  });

  @override
  Future<Result<User>> updateAvatarUrl(String url) => _guard(() async {
    final dto = await _remoteDataSource.updateAvatarUrl(url);
    await _localDataSource.cacheUser(dto);
    return dto.toEntity();
  });

  @override
  Future<Result<void>> logout() => _guard(() async {
    await _remoteDataSource.logout();
    await _localDataSource.clearCache();
  });

  @override
  Future<Result<User>> getCurrentUser() async {
    try {
      final dto = await _remoteDataSource.getCurrentUser();
      await _localDataSource.cacheUser(dto);
      return Result.success(dto.toEntity());
    } catch (e, st) {
      final cached = await _localDataSource.getCachedUser();
      if (cached != null) return Result.success(cached.toEntity());
      return Result.failure(_mapError(e, st));
    }
  }

  @override
  Future<Result<bool>> get isAuthenticated async {
    if (_remoteDataSource.currentUid != null) return Result.success(true);
    final cached = await _localDataSource.getCachedUser();
    return Result.success(cached != null);
  }

  @override
  String? get currentUid => _remoteDataSource.currentUid;

  @override
  bool get isCurrentUserAnonymous => _remoteDataSource.isAnonymous;

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } catch (e, st) {
      return Result.failure(_mapError(e, st));
    }
  }

  bool _isNetworkError(Object e) =>
      e is fb.FirebaseAuthException && e.code == 'network-request-failed';

  Failure _mapError(Object e, StackTrace st) {
    if (e is AccountAlreadyExistsException) {
      return AccountExistsFailure(
        email: e.email,
        credential: e.credential,
        stackTrace: st,
      );
    }
    if (e is fb.FirebaseAuthException) {
      return ServerFailure(message: e.message ?? e.code, stackTrace: st);
    }
    return UnexpectedFailure(message: e.toString(), stackTrace: st);
  }
}
