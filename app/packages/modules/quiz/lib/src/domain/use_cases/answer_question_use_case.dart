import 'package:core/core.dart';
import 'package:injectable/injectable.dart';
import 'package:question_bank_module/question_bank.dart';

import '../entities/answer.dart';
import '../services/spaced_repetition_scheduler.dart';

/// +10 XP por acerto, +2 XP por erro (respondeu = aprendeu) — spec-03.
int xpForAnswer({required bool isCorrect}) => isCorrect ? 10 : 2;

/// Registra a resposta do usuário: persiste o progresso via
/// [ProgressRepository] e agenda a próxima revisão via
/// [SpacedRepetitionScheduler] (design.md decisão 1).
@lazySingleton
class AnswerQuestionUseCase {
  AnswerQuestionUseCase(this._progressRepository, this._scheduler);

  final ProgressRepository _progressRepository;
  final SpacedRepetitionScheduler _scheduler;

  Future<Result<Answer>> call({
    required Question question,
    required int selectedIndex,
    required int elapsedMs,
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final isCorrect = selectedIndex == question.correctIndex;

    final existingResult = await _progressRepository.getByQuestionId(
      question.id,
    );
    if (existingResult.isFailure) {
      return Result.failure(existingResult.failureOrNull!);
    }
    final existing = existingResult.dataOrNull;

    final newConsecutiveCorrect = isCorrect
        ? (existing?.consecutiveCorrect ?? 0) + 1
        : 0;
    final nextReviewAt = _scheduler.nextReviewAt(
      now: effectiveNow,
      wasCorrect: isCorrect,
      consecutiveCorrectAfterAnswer: newConsecutiveCorrect,
    );

    final updated = (existing ?? QuestionProgress(questionId: question.id))
        .copyWith(
          correctCount: (existing?.correctCount ?? 0) + (isCorrect ? 1 : 0),
          wrongCount: (existing?.wrongCount ?? 0) + (isCorrect ? 0 : 1),
          consecutiveCorrect: newConsecutiveCorrect,
          lastSeenAt: effectiveNow,
          nextReviewAt: nextReviewAt,
        );

    final saveResult = await _progressRepository.save(updated);
    if (saveResult.isFailure) {
      return Result.failure(saveResult.failureOrNull!);
    }

    return Result.success(
      Answer(
        questionId: question.id,
        selectedIndex: selectedIndex,
        isCorrect: isCorrect,
        elapsedMs: elapsedMs,
      ),
    );
  }
}
