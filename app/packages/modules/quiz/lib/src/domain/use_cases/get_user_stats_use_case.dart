import 'package:core/core.dart';
import 'package:injectable/injectable.dart';
import 'package:question_bank_module/question_bank.dart';

import '../entities/user_stats.dart';

const _kXpTotalKey = 'quiz_xp_total';
const _kStreakDaysKey = 'quiz_streak_days';

/// Monta o [UserStats] agregado para a tela de estatísticas (stats_flow):
/// streak/XP vêm do [LocalStorage] (persistidos por [CompleteSessionUseCase]);
/// o desempenho por tópico é derivado on-demand de [QuestionRepository] +
/// [ProgressRepository] — não há uma segunda fonte de verdade duplicada.
@lazySingleton
class GetUserStatsUseCase {
  GetUserStatsUseCase(
    this._localStorage,
    this._questionRepository,
    this._progressRepository,
  );

  final LocalStorage _localStorage;
  final QuestionRepository _questionRepository;
  final ProgressRepository _progressRepository;

  Future<Result<UserStats>> call() async {
    final xpTotal = await _localStorage.getInt(_kXpTotalKey) ?? 0;
    final streakDays = await _localStorage.getInt(_kStreakDaysKey) ?? 0;

    final questionsResult = await _questionRepository.getAll();
    if (questionsResult.isFailure) {
      return Result.failure(questionsResult.failureOrNull!);
    }
    final progressResult = await _progressRepository.getAll();
    if (progressResult.isFailure) {
      return Result.failure(progressResult.failureOrNull!);
    }

    final topicById = {
      for (final q in questionsResult.dataOrNull!) q.id: q.topic,
    };
    final byTopic = <String, TopicStats>{};
    for (final progress in progressResult.dataOrNull!) {
      final topic = topicById[progress.questionId];
      if (topic == null) continue;
      final current = byTopic[topic] ?? TopicStats(topic: topic);
      byTopic[topic] = current.copyWith(
        seen: current.seen + 1,
        correct: current.correct + (progress.correctCount > 0 ? 1 : 0),
        wrong: current.wrong + (progress.wrongCount > 0 ? 1 : 0),
      );
    }

    return Result.success(
      UserStats(
        streakDays: streakDays,
        xpTotal: xpTotal,
        byTopic: byTopic.values.toList()
          ..sort((a, b) => a.topic.compareTo(b.topic)),
      ),
    );
  }
}
