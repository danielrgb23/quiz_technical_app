import '../../domain/entities/bank_manifest.dart';

/// Fonte remota do banco de questões (Firebase Storage/Firestore em stg/prod).
///
/// A implementação Firebase vive fora do módulo (packages/shared), atrás
/// desta interface. O módulo nunca importa Firebase.
abstract class BankRemoteDataSource {
  Future<BankManifest> fetchManifest(int version);

  /// Bytes do arquivo `questions_v<version>.json`, exatamente como publicado
  /// (o checksum do manifest é calculado sobre esses bytes).
  Future<List<int>> downloadBankBytes(int version);
}

/// Fake para dev/testes: nunca há versão remota nova.
class FakeBankRemoteDataSource implements BankRemoteDataSource {
  @override
  Future<BankManifest> fetchManifest(int version) async =>
      throw UnsupportedError('sem backend no ambiente dev');

  @override
  Future<List<int>> downloadBankBytes(int version) async =>
      throw UnsupportedError('sem backend no ambiente dev');
}
