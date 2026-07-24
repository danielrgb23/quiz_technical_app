/// Espelho remoto de reports de questão (Firestore em stg/prod; alimenta
/// `data/review/flagged.jsonl` da Spec 01 no processo de revisão).
abstract class FlaggedRemoteDataSource {
  Future<void> reportFlag(String questionId);
}

/// Fake para dev/testes: aceita tudo sem efeito.
class FakeFlaggedRemoteDataSource implements FlaggedRemoteDataSource {
  final List<String> received = [];

  @override
  Future<void> reportFlag(String questionId) async {
    received.add(questionId);
  }
}
