import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../entities/quiz_session.dart';
import '../entities/session_result.dart';
import '../services/streak_service.dart';
import 'answer_question_use_case.dart';

/// Bônus de XP por completar a sessão inteira — spec-03.
const sessionCompletionXpBonus = 20;

const _kXpTotalKey = 'quiz_xp_total';
const _kStreakDaysKey = 'quiz_streak_days';
const _kStreakLastCompletedAtKey = 'quiz_streak_last_completed_at';

/// Finaliza uma sessão completada (não chamar para sessões abandonadas —
/// design.md decisão: abandono não conta para o streak): soma o XP, atualiza
/// o streak via [StreakService] e persiste o novo total via [LocalStorage].
@lazySingleton
class CompleteSessionUseCase {
  CompleteSessionUseCase(this._localStorage, this._streakService);

  final LocalStorage _localStorage;
  final StreakService _streakService;

  Future<Result<SessionResult>> call(
    QuizSession session, {
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();

    final xpFromAnswers = session.answers.fold<int>(
      0,
      (sum, a) => sum + xpForAnswer(isCorrect: a.isCorrect),
    );
    final xpEarned = session.answers.isEmpty
        ? 0
        : xpFromAnswers + sessionCompletionXpBonus;

    final previousXp = await _localStorage.getInt(_kXpTotalKey) ?? 0;
    final previousStreak = await _localStorage.getInt(_kStreakDaysKey) ?? 0;
    final lastCompletedRaw = await _localStorage.getString(
      _kStreakLastCompletedAtKey,
    );
    final lastCompletedAt = lastCompletedRaw != null
        ? DateTime.parse(lastCompletedRaw)
        : null;

    final newStreak = _streakService.computeStreakOnSessionCompleted(
      previousStreak: previousStreak,
      lastCompletedAt: lastCompletedAt,
      completedAt: effectiveNow,
    );
    final newXpTotal = previousXp + xpEarned;

    await _localStorage.setInt(_kXpTotalKey, newXpTotal);
    await _localStorage.setInt(_kStreakDaysKey, newStreak);
    await _localStorage.setString(
      _kStreakLastCompletedAtKey,
      effectiveNow.toIso8601String(),
    );

    return Result.success(
      SessionResult(
        totalQuestions: session.questions.length,
        correctCount: session.correctCount,
        wrongCount: session.wrongCount,
        xpEarned: xpEarned,
        streakDays: newStreak,
        wrongAnswers: session.answers.where((a) => !a.isCorrect).toList(),
      ),
    );
  }
}
