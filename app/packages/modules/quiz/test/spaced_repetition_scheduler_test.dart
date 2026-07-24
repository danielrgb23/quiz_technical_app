import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_module/quiz_module.dart';

void main() {
  final scheduler = SpacedRepetitionScheduler();
  final now = DateTime(2026, 1, 1);

  DateTime daysAfter(int days) => now.add(Duration(days: days));

  final cases = <({int consecutive, bool correct, int expectedDays})>[
    (consecutive: 1, correct: true, expectedDays: 1),
    (consecutive: 2, correct: true, expectedDays: 3),
    (consecutive: 3, correct: true, expectedDays: 7),
    (consecutive: 4, correct: true, expectedDays: 21),
    (consecutive: 5, correct: true, expectedDays: 21), // clamp no topo
    (consecutive: 0, correct: false, expectedDays: 1),
  ];

  for (final c in cases) {
    test(
      'consecutive=${c.consecutive} correct=${c.correct} -> ${c.expectedDays}d',
      () {
        final result = scheduler.nextReviewAt(
          now: now,
          wasCorrect: c.correct,
          consecutiveCorrectAfterAnswer: c.consecutive,
        );
        expect(result, daysAfter(c.expectedDays));
      },
    );
  }

  test('erro após intervalo espaçado reseta para 1 dia', () {
    // Simula: questão tinha 3 acertos consecutivos (7d), errou agora.
    final result = scheduler.nextReviewAt(
      now: now,
      wasCorrect: false,
      consecutiveCorrectAfterAnswer: 0,
    );
    expect(result, daysAfter(1));
  });
}
