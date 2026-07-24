import 'package:flutter_test/flutter_test.dart';
import 'package:question_bank_module/question_bank.dart';
import 'package:quiz_module/quiz_module.dart';

import 'fakes.dart';

void main() {
  late FakeQuestionRepository questionRepo;
  late FakeProgressRepository progressRepo;
  late StartSessionUseCase useCase;

  setUp(() {
    questionRepo = FakeQuestionRepository([
      makeQuestion('f1'),
      makeQuestion('f2'),
      makeQuestion('f3'),
      makeQuestion('a1', topic: 'android'),
    ]);
    progressRepo = FakeProgressRepository();
    useCase = StartSessionUseCase(questionRepo, progressRepo);
  });

  test('modo topic retorna questões do tópico, respeitando size', () async {
    final result = await useCase.call(
      mode: SessionMode.topic,
      topic: 'flutter',
      size: 2,
    );

    expect(result.isSuccess, true);
    expect(result.dataOrNull!.questions, hasLength(2));
    expect(
      result.dataOrNull!.questions.every((q) => q.topic == 'flutter'),
      true,
    );
  });

  test('modo topic prioriza não vistas e vencidas antes das demais', () async {
    final now = DateTime(2026, 1, 10);
    await progressRepo.save(
      const QuestionProgress(questionId: 'f1'), // vista, sem revisão vencida
    );
    await progressRepo.save(
      QuestionProgress(
        questionId: 'f2',
        nextReviewAt: now.subtract(const Duration(days: 1)), // vencida
      ),
    );
    // f3 nunca vista

    final result = await useCase.call(
      mode: SessionMode.topic,
      topic: 'flutter',
      size: 3,
      now: now,
    );

    final order = result.dataOrNull!.questions.map((q) => q.id).toList();
    expect(order.indexOf('f3'), lessThan(order.indexOf('f1')));
    expect(order.indexOf('f2'), lessThan(order.indexOf('f1')));
  });

  test('modo review retorna apenas questões vencidas', () async {
    final now = DateTime(2026, 1, 10);
    await progressRepo.save(
      QuestionProgress(
        questionId: 'f1',
        nextReviewAt: now.subtract(const Duration(days: 1)),
      ),
    );
    await progressRepo.save(
      QuestionProgress(
        questionId: 'f2',
        nextReviewAt: now.add(const Duration(days: 1)),
      ),
    );

    final result = await useCase.call(mode: SessionMode.review, now: now);

    expect(result.dataOrNull!.questions.map((q) => q.id).toList(), ['f1']);
  });

  test('modo review sem vencidas retorna sessão vazia sem erro', () async {
    final result = await useCase.call(mode: SessionMode.review);

    expect(result.isSuccess, true);
    expect(result.dataOrNull!.questions, isEmpty);
  });

  test('desafio diário é estável no mesmo dia', () async {
    final day = DateTime(2026, 3, 5, 8);
    final sameDayLater = DateTime(2026, 3, 5, 22);

    final first = await useCase.call(mode: SessionMode.daily, now: day);
    final second = await useCase.call(
      mode: SessionMode.daily,
      now: sameDayLater,
    );

    expect(
      first.dataOrNull!.questions.map((q) => q.id),
      second.dataOrNull!.questions.map((q) => q.id),
    );
  });

  test('desafio diário pode variar entre dias diferentes', () async {
    questionRepo = FakeQuestionRepository(
      List.generate(30, (i) => makeQuestion('q$i')),
    );
    useCase = StartSessionUseCase(questionRepo, progressRepo);

    final day1 = await useCase.call(
      mode: SessionMode.daily,
      now: DateTime(2026, 3, 5),
    );
    final day2 = await useCase.call(
      mode: SessionMode.daily,
      now: DateTime(2026, 3, 6),
    );

    expect(
      day1.dataOrNull!.questions.map((q) => q.id).toList(),
      isNot(day2.dataOrNull!.questions.map((q) => q.id).toList()),
    );
  });
}
