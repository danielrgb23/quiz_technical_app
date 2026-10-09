import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_module/quiz_module.dart';

import 'fakes.dart';

void main() {
  late FakeLocalStorage storage;
  late LearningPathService service;

  setUp(() {
    storage = FakeLocalStorage();
    service = LearningPathService(
      FakeQuestionRepository([
        for (var i = 0; i < 12; i++) makeQuestion('f$i'),
        makeQuestion('a1', topic: 'android'),
      ]),
      storage,
    );
  });

  test('passed exige >= 80% de acertos', () {
    expect(LearningPathService.passed(correct: 4, total: 5), isTrue);
    expect(LearningPathService.passed(correct: 3, total: 5), isFalse);
    expect(LearningPathService.passed(correct: 0, total: 0), isFalse);
  });

  test(
    'trilha de 12 questões tem 3 lições; cada tópico é independente',
    () async {
      expect((await service.progress('flutter')).total, 3);
      expect((await service.progress('android')).total, 1);
    },
  );

  test('3/5 não libera a próxima lição; 4/5 libera', () async {
    final failed = await service.recordLessonResult(
      topic: 'flutter',
      lesson: 0,
      correct: 3,
      total: 5,
    );
    expect(failed, isFalse);
    expect((await service.progress('flutter')).completed, 0);

    final passed = await service.recordLessonResult(
      topic: 'flutter',
      lesson: 0,
      correct: 4,
      total: 5,
    );
    expect(passed, isTrue);
    expect((await service.progress('flutter')).completed, 1);
  });

  test('refazer lição já concluída não avança a trilha', () async {
    await service.recordLessonResult(
      topic: 'flutter',
      lesson: 0,
      correct: 5,
      total: 5,
    );
    final again = await service.recordLessonResult(
      topic: 'flutter',
      lesson: 0,
      correct: 5,
      total: 5,
    );
    expect(again, isFalse);
    expect((await service.progress('flutter')).completed, 1);
  });

  test('progresso de um tópico não afeta o outro', () async {
    await service.recordLessonResult(
      topic: 'flutter',
      lesson: 0,
      correct: 5,
      total: 5,
    );
    expect((await service.progress('android')).completed, 0);
  });
}
