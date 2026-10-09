import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_module/quiz_module.dart';

import 'fakes.dart';

void main() {
  late FakeLocalStorage storage;
  late CompleteSessionUseCase useCase;

  setUp(() {
    storage = FakeLocalStorage();
    useCase = CompleteSessionUseCase(
      storage,
      StreakService(),
      FakeStatsSyncGateway(),
    );
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

  group('streak ao longo dos dias', () {
    final answered = sessionWith([
      const Answer(
        questionId: 'f1',
        selectedIndex: 0,
        isCorrect: true,
        elapsedMs: 100,
      ),
    ]);

    Future<int> complete(DateTime day) async {
      final result = await useCase.call(answered, now: day);
      return result.dataOrNull!.streakDays;
    }

    test('dias seguidos somam; segunda sessão no mesmo dia não soma', () async {
      expect(await complete(DateTime(2026, 1, 10, 9)), 1);
      expect(await complete(DateTime(2026, 1, 11, 9)), 2);
      expect(await complete(DateTime(2026, 1, 11, 21)), 2);
      expect(await complete(DateTime(2026, 1, 12, 7)), 3);
      expect(await complete(DateTime(2026, 1, 13, 22)), 4);
    });

    test('perder um dia reseta para 1 e volta a somar a partir daí', () async {
      expect(await complete(DateTime(2026, 1, 10)), 1);
      expect(await complete(DateTime(2026, 1, 11)), 2);
      expect(await complete(DateTime(2026, 1, 12)), 3);
      // Pulou 13/jan e 14/jan.
      expect(await complete(DateTime(2026, 1, 15)), 1);
      expect(await complete(DateTime(2026, 1, 16)), 2);
    });
  });

  test(
    'perder um dia: exibe 0 até concluir uma sessão; ao concluir vira 1',
    () async {
      final stats = GetUserStatsUseCase(
        storage,
        FakeQuestionRepository(const []),
        FakeProgressRepository(),
        StreakService(),
      );
      final answered = sessionWith([
        const Answer(
          questionId: 'f1',
          selectedIndex: 0,
          isCorrect: true,
          elapsedMs: 100,
        ),
      ]);
      Future<int> shown(DateTime now) async =>
          (await stats.call(now: now)).dataOrNull!.streakDays;

      await useCase.call(answered, now: DateTime(2026, 1, 10, 9));
      await useCase.call(answered, now: DateTime(2026, 1, 11, 9));
      await useCase.call(answered, now: DateTime(2026, 1, 12, 9));
      expect(await shown(DateTime(2026, 1, 12, 20)), 3);
      // 13/jan ainda dá tempo (dia da graça); 14/jan o streak já quebrou.
      expect(await shown(DateTime(2026, 1, 13, 8)), 3);
      expect(await shown(DateTime(2026, 1, 14, 8)), 0);

      // Voltou a estudar em 14/jan: a sessão concluída inicia nova sequência.
      final result = await useCase.call(
        answered,
        now: DateTime(2026, 1, 14, 9),
      );
      expect(result.dataOrNull!.streakDays, 1);
      expect(await shown(DateTime(2026, 1, 14, 20)), 1);
      expect(await shown(DateTime(2026, 1, 16, 8)), 0);
    },
  );
}
