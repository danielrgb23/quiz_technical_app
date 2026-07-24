import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_module/quiz_module.dart';

import 'fakes.dart';

void main() {
  late FakeProgressRepository progressRepo;
  late AnswerQuestionUseCase useCase;
  final question = makeQuestion('f1'); // correctIndex: 0

  setUp(() {
    progressRepo = FakeProgressRepository();
    useCase = AnswerQuestionUseCase(progressRepo, SpacedRepetitionScheduler());
  });

  test(
    'resposta correta incrementa correctCount e agenda revisão em 1d',
    () async {
      final now = DateTime(2026, 1, 1);
      final result = await useCase.call(
        question: question,
        selectedIndex: 0,
        elapsedMs: 1200,
        now: now,
      );

      expect(result.isSuccess, true);
      expect(result.dataOrNull!.isCorrect, true);
      final progress = (await progressRepo.getByQuestionId('f1')).dataOrNull!;
      expect(progress.correctCount, 1);
      expect(progress.consecutiveCorrect, 1);
      expect(progress.nextReviewAt, now.add(const Duration(days: 1)));
    },
  );

  test(
    'resposta incorreta incrementa wrongCount e reseta consecutiveCorrect',
    () async {
      await useCase.call(question: question, selectedIndex: 0, elapsedMs: 100);
      final result = await useCase.call(
        question: question,
        selectedIndex: 1,
        elapsedMs: 100,
      );

      expect(result.dataOrNull!.isCorrect, false);
      final progress = (await progressRepo.getByQuestionId('f1')).dataOrNull!;
      expect(progress.wrongCount, 1);
      expect(progress.consecutiveCorrect, 0);
    },
  );

  test('acertos consecutivos espaçam o intervalo de revisão', () async {
    final now = DateTime(2026, 1, 1);
    await useCase.call(
      question: question,
      selectedIndex: 0,
      elapsedMs: 100,
      now: now,
    );
    final second = await useCase.call(
      question: question,
      selectedIndex: 0,
      elapsedMs: 100,
      now: now,
    );

    expect(second.isSuccess, true);
    final progress = (await progressRepo.getByQuestionId('f1')).dataOrNull!;
    expect(progress.consecutiveCorrect, 2);
    expect(progress.nextReviewAt, now.add(const Duration(days: 3)));
  });
}
