import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_module/quiz_module.dart';

import 'fakes.dart';

void main() {
  late FakeLocalStorage storage;
  late CompleteSessionUseCase useCase;

  setUp(() {
    storage = FakeLocalStorage();
    useCase = CompleteSessionUseCase(storage, StreakService());
  });

  QuizSession sessionWith(List<Answer> answers) => QuizSession(
    id: 's1',
    mode: SessionMode.topic,
    topic: 'flutter',
    questions: [makeQuestion('f1'), makeQuestion('f2')],
    answers: answers,
    startedAt: DateTime(2026, 1, 1),
  );

  test('XP = soma por resposta + bônus de conclusão', () async {
    final session = sessionWith([
      const Answer(
        questionId: 'f1',
        selectedIndex: 0,
        isCorrect: true,
        elapsedMs: 100,
      ),
      const Answer(
        questionId: 'f2',
        selectedIndex: 1,
        isCorrect: false,
        elapsedMs: 100,
      ),
    ]);

    final result = await useCase.call(session, now: DateTime(2026, 1, 10));

    expect(result.isSuccess, true);
    expect(result.dataOrNull!.xpEarned, 10 + 2 + sessionCompletionXpBonus);
  });

  test('primeira sessão completa define streak em 1', () async {
    final session = sessionWith([
      const Answer(
        questionId: 'f1',
        selectedIndex: 0,
        isCorrect: true,
        elapsedMs: 100,
      ),
    ]);

    final result = await useCase.call(session, now: DateTime(2026, 1, 10));

    expect(result.dataOrNull!.streakDays, 1);
  });

  test('XP acumula entre sessões via LocalStorage', () async {
    final session = sessionWith([
      const Answer(
        questionId: 'f1',
        selectedIndex: 0,
        isCorrect: true,
        elapsedMs: 100,
      ),
    ]);

    await useCase.call(session, now: DateTime(2026, 1, 10));
    final second = await useCase.call(session, now: DateTime(2026, 1, 11));

    // cada chamada soma 10 + 20 = 30; duas chamadas => xpEarned individual
    // é sempre 30, mas o total acumulado interno deve refletir 60.
    expect(second.dataOrNull!.xpEarned, 30);
    expect(await storage.getInt('quiz_xp_total'), 60);
  });

  test('wrongAnswers contém apenas as respostas incorretas', () async {
    final session = sessionWith([
      const Answer(
        questionId: 'f1',
        selectedIndex: 0,
        isCorrect: true,
        elapsedMs: 100,
      ),
      const Answer(
        questionId: 'f2',
        selectedIndex: 1,
        isCorrect: false,
        elapsedMs: 100,
      ),
    ]);

    final result = await useCase.call(session, now: DateTime(2026, 1, 10));

    expect(result.dataOrNull!.wrongAnswers.map((a) => a.questionId), ['f2']);
  });
}
