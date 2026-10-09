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

  group('contagem por dia de calendário', () {
    int next(int streak, DateTime last, DateTime now) =>
        service.computeStreakOnSessionCompleted(
          previousStreak: streak,
          lastCompletedAt: last,
          completedAt: now,
        );

    test('virada de mês (31/jan -> 1/fev) soma', () {
      expect(next(2, DateTime(2026, 1, 31, 22), DateTime(2026, 2, 1, 7)), 3);
    });

    test('virada de ano (31/dez -> 1/jan) soma', () {
      expect(next(9, DateTime(2025, 12, 31, 23), DateTime(2026, 1, 1, 1)), 10);
    });

    test('ano bissexto (28/fev -> 29/fev -> 1/mar) soma nos dois dias', () {
      expect(next(1, DateTime(2028, 2, 28), DateTime(2028, 2, 29)), 2);
      expect(next(2, DateTime(2028, 2, 29), DateTime(2028, 3, 1)), 3);
    });

    test('mais de 24h mas só um dia de calendário de diferença soma', () {
      // 08:00 de segunda -> 23:00 de terça = 39h depois, ainda dia seguinte.
      expect(next(4, DateTime(2026, 1, 12, 8), DateTime(2026, 1, 13, 23)), 5);
    });

    test('pulou um dia de calendário (qualquer horário) zera', () {
      expect(next(4, DateTime(2026, 1, 12, 0, 1), DateTime(2026, 1, 14)), 1);
    });

    test('relógio voltou no tempo: mantém o streak, não zera nem soma', () {
      expect(next(6, DateTime(2026, 1, 12), DateTime(2026, 1, 9)), 6);
    });

    test('vários dias de gap zera para 1', () {
      expect(next(30, DateTime(2026, 1, 1), DateTime(2026, 3, 1)), 1);
    });
  });

  group('currentStreak (exibição sem sessão completada hoje)', () {
    test('nunca completou sessão -> 0', () {
      final streak = service.currentStreak(
        storedStreak: 5,
        lastCompletedAt: null,
        now: DateTime(2026, 1, 11),
      );
      expect(streak, 0);
    });

    test('última sessão hoje -> mantém o streak guardado', () {
      final streak = service.currentStreak(
        storedStreak: 5,
        lastCompletedAt: DateTime(2026, 1, 11, 8),
        now: DateTime(2026, 1, 11, 20),
      );
      expect(streak, 5);
    });

    test('última sessão ontem -> mantém (ainda dá tempo de jogar hoje)', () {
      final streak = service.currentStreak(
        storedStreak: 5,
        lastCompletedAt: DateTime(2026, 1, 10),
        now: DateTime(2026, 1, 11),
      );
      expect(streak, 5);
    });

    test('última sessão antes de ontem -> streak quebrado, exibe 0', () {
      final streak = service.currentStreak(
        storedStreak: 5,
        lastCompletedAt: DateTime(2026, 1, 8),
        now: DateTime(2026, 1, 11),
      );
      expect(streak, 0);
    });
  });
}
