import 'package:flutter_test/flutter_test.dart';
import 'package:question_bank_module/question_bank.dart';
import 'package:quiz_module/quiz_module.dart';

import 'fakes.dart';

void main() {
  test(
    'agrega streak/XP do storage e desempenho por tópico do progresso',
    () async {
      final storage = FakeLocalStorage();
      await storage.setInt('quiz_xp_total', 150);
      await storage.setInt('quiz_streak_days', 4);
      await storage.setString(
        'quiz_streak_last_completed_at',
        DateTime(2026, 1, 11).toIso8601String(),
      );

      final questionRepo = FakeQuestionRepository([
        makeQuestion('f1'),
        makeQuestion('f2'),
        makeQuestion('a1', topic: 'android'),
      ]);
      final progressRepo = FakeProgressRepository();
      await progressRepo.save(
        const QuestionProgress(questionId: 'f1', correctCount: 2),
      );
      await progressRepo.save(
        const QuestionProgress(questionId: 'f2', wrongCount: 1),
      );
      await progressRepo.save(
        const QuestionProgress(questionId: 'a1', correctCount: 1),
      );

      final useCase = GetUserStatsUseCase(
        storage,
        questionRepo,
        progressRepo,
        StreakService(),
      );
      final result = await useCase.call(now: DateTime(2026, 1, 11, 20));

      expect(result.isSuccess, true);
      final stats = result.dataOrNull!;
      expect(stats.xpTotal, 150);
      expect(stats.streakDays, 4);
      expect(stats.byTopic.map((t) => t.topic), ['android', 'flutter']);
      final flutterStats = stats.byTopic.firstWhere(
        (t) => t.topic == 'flutter',
      );
      expect(flutterStats.seen, 2);
      expect(flutterStats.correct, 1);
      expect(flutterStats.wrong, 1);
    },
  );

  test('streak exibido zera se a última sessão foi antes de ontem, mesmo sem '
      'completar uma nova sessão para recalcular', () async {
    final storage = FakeLocalStorage();
    await storage.setInt('quiz_streak_days', 7);
    await storage.setString(
      'quiz_streak_last_completed_at',
      DateTime(2026, 1, 8).toIso8601String(),
    );

    final useCase = GetUserStatsUseCase(
      storage,
      FakeQuestionRepository(const []),
      FakeProgressRepository(),
      StreakService(),
    );
    final result = await useCase.call(now: DateTime(2026, 1, 11));

    expect(result.dataOrNull!.streakDays, 0);
  });
}
