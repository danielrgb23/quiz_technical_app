import 'dart:convert';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../dtos/user_dto.dart';

/// Caches the last known user for instant, offline-safe reads. Firebase
/// Auth's SDK persists the actual session itself — there's no separate
/// token to manage here anymore. Backed by [SecureStorage] (encrypted)
/// since this carries name/email/phone-adjacent PII, not just prefs.
abstract class AuthLocalDataSource {
  Future<UserDto?> getCachedUser();
  Future<void> cacheUser(UserDto user);
  Future<void> clearCache();
}

@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._secureStorage);

  final SecureStorage _secureStorage;

  static const _cachedUserKey = 'cached_user';

  @override
  Future<UserDto?> getCachedUser() async {
    final jsonString = await _secureStorage.read(_cachedUserKey);
    if (jsonString == null) return null;
    return UserDto.fromJson(json.decode(jsonString) as Map<String, dynamic>);
  }

  @override
  Future<void> cacheUser(UserDto user) async {
    await _secureStorage.write(_cachedUserKey, json.encode(user.toJson()));
  }

  @override
  Future<void> clearCache() async {
    await _secureStorage.delete(_cachedUserKey);
  }
}
