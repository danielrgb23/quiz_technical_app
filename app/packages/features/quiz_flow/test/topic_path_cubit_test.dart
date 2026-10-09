import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_flow/quiz_flow.dart';
import 'package:quiz_module/quiz_module.dart';

import 'fakes.dart';

void main() {
  Future<TopicPathCubit> build(int questionCount, {int completed = 0}) async {
    final storage = FakeLocalStorage();
    if (completed > 0) {
      await storage.setInt('path_completed_flutter', completed);
    }
    final questions = [
      for (var i = 0; i < questionCount; i++) makeQuestion('q$i'),
    ];
    return TopicPathCubit(
      LearningPathService(FakeQuestionRepository(questions), storage),
    );
  }

  test('12 questões, nada concluído → 3 lições, 0 concluídas', () async {
    final cubit = await build(12);
    await cubit.load('flutter');
    final state = cubit.state as TopicPathLoaded;
    expect(state.totalLessons, 3);
    expect(state.completedLessons, 0);
  });

  test('progresso salvo é refletido e limitado ao total', () async {
    final cubit = await build(12, completed: 99);
    await cubit.load('flutter');
    final state = cubit.state as TopicPathLoaded;
    expect(state.completedLessons, 3);
    expect(state.isFinished, isTrue);
  });

  test('tópico sem questões → 0 lições', () async {
    final cubit = await build(0);
    await cubit.load('flutter');
    expect((cubit.state as TopicPathLoaded).totalLessons, 0);
  });
}
