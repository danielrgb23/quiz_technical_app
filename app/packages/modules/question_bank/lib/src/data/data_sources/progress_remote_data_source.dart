import '../../domain/entities/question_progress.dart';

/// Espelho remoto do progresso (Firestore `users/{uid}/progress` em stg/prod).
abstract class ProgressRemoteDataSource {
  Future<void> upsert(QuestionProgress progress);
}

/// Fake para dev/testes: aceita tudo sem efeito.
class FakeProgressRemoteDataSource implements ProgressRemoteDataSource {
  final List<QuestionProgress> received = [];

  @override
  Future<void> upsert(QuestionProgress progress) async {
    received.add(progress);
  }
}
