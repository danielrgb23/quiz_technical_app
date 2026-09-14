import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

abstract class SecureStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

@LazySingleton(as: SecureStorage)
class SecureStorageImpl implements SecureStorage {
  SecureStorageImpl()
    : _storage = const FlutterSecureStorage(
        // Nunca sai deste aparelho: sem isso, o Keychain/Keystore entra no
        // backup do iCloud/Google e pode restaurar sessão em outro device
        // sem re-autenticação (ver plano de segurança de backup).
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}
