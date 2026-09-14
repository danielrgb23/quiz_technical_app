import 'dart:async';

import 'package:dio/dio.dart';

import '../env/env_config.dart';
import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required SecureStorage secureStorage, Dio? refreshDio})
    : _secureStorage = secureStorage,
      _refreshDio = refreshDio ?? Dio(BaseOptions(baseUrl: EnvConfig.baseUrl));

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _retriedFlag = 'auth_interceptor_retried';

  final SecureStorage _secureStorage;
  final Dio _refreshDio;

  Completer<String?>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(_accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.response?.requestOptions;
    final alreadyRetried = requestOptions?.extra[_retriedFlag] == true;

    if (err.response?.statusCode != 401 ||
        requestOptions == null ||
        alreadyRetried) {
      handler.next(err);
      return;
    }

    final newAccessToken = await _refreshAccessToken();
    if (newAccessToken == null) {
      await _secureStorage.deleteAll();
      handler.next(err);
      return;
    }

    try {
      requestOptions.extra[_retriedFlag] = true;
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final response = await _refreshDio.fetch<dynamic>(requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Coalesces concurrent 401s onto a single refresh call.
  Future<String?> _refreshAccessToken() {
    final pending = _refreshCompleter;
    if (pending != null) {
      return pending.future;
    }

    final completer = Completer<String?>();
    _refreshCompleter = completer;
    unawaited(_performRefresh(completer));
    return completer.future;
  }

  Future<void> _performRefresh(Completer<String?> completer) async {
    try {
      final refreshToken = await _secureStorage.read(_refreshTokenKey);
      if (refreshToken == null) {
        completer.complete(null);
        return;
      }

      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = response.data;
      final newAccessToken = data?['access_token'] as String?;
      if (newAccessToken == null) {
        completer.complete(null);
        return;
      }

      await _secureStorage.write(_accessTokenKey, newAccessToken);
      final newRefreshToken = data?['refresh_token'] as String?;
      if (newRefreshToken != null) {
        await _secureStorage.write(_refreshTokenKey, newRefreshToken);
      }
      completer.complete(newAccessToken);
    } on DioException {
      completer.complete(null);
    } finally {
      _refreshCompleter = null;
    }
  }
}
