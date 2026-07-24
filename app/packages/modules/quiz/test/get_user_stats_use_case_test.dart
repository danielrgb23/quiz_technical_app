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

      final useCase = GetUserStatsUseCase(storage, questionRepo, progressRepo);
      final result = await useCase.call();

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
}
