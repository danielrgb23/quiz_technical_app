import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_module/quiz_module.dart';

void main() {
  final service = StreakService();

  test('primeira sessão completa nunca antes -> streak 1', () {
    final streak = service.computeStreakOnSessionCompleted(
      previousStreak: 0,
      lastCompletedAt: null,
      completedAt: DateTime(2026, 1, 10),
    );
    expect(streak, 1);
  });

  test('sessão em dia consecutivo incrementa o streak', () {
    final streak = service.computeStreakOnSessionCompleted(
      previousStreak: 3,
      lastCompletedAt: DateTime(2026, 1, 10),
      completedAt: DateTime(2026, 1, 11),
    );
    expect(streak, 4);
  });

  test('pular um dia zera o streak', () {
    final streak = service.computeStreakOnSessionCompleted(
      previousStreak: 5,
      lastCompletedAt: DateTime(2026, 1, 10),
      completedAt: DateTime(2026, 1, 12),
    );
    expect(streak, 1);
  });

  test('segunda sessão no mesmo dia não incrementa de novo', () {
    final streak = service.computeStreakOnSessionCompleted(
      previousStreak: 4,
      lastCompletedAt: DateTime(2026, 1, 11, 8),
      completedAt: DateTime(2026, 1, 11, 20),
    );
    expect(streak, 4);
  });

  test(
    'primeira sessão do dia com streak zerado vira 1 mesmo no mesmo dia',
    () {
      final streak = service.computeStreakOnSessionCompleted(
        previousStreak: 0,
        lastCompletedAt: DateTime(2026, 1, 11, 8),
        completedAt: DateTime(2026, 1, 11, 20),
      );
      expect(streak, 1);
    },
  );

  test('virada de dia próxima à meia-noite (timezone local)', () {
    final streak = service.computeStreakOnSessionCompleted(
      previousStreak: 2,
      lastCompletedAt: DateTime(2026, 1, 10, 23, 59),
      completedAt: DateTime(2026, 1, 11, 0, 1),
    );
    expect(streak, 3);
  });
}
