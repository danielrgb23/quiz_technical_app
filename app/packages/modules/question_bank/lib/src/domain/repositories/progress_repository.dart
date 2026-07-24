import 'package:core/core.dart';

import '../entities/question_progress.dart';

abstract class ProgressRepository {
  Future<Result<QuestionProgress?>> getByQuestionId(String questionId);
  Future<Result<List<QuestionProgress>>> getAll();

  /// Questões com revisão vencida (nextReviewAt <= now).
  Future<Result<List<QuestionProgress>>> getDueForReview(DateTime now);

  /// Grava o progresso localmente e enfileira para sync remoto.
  Future<Result<void>> save(QuestionProgress progress);
}
