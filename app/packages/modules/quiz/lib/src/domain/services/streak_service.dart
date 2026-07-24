import 'package:injectable/injectable.dart';

bool _isSameLocalDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Streak diário por timezone local do dispositivo (design.md decisão 3):
/// completar >=1 sessão no dia mantém/incrementa; pular um dia zera.
@lazySingleton
class StreakService {
  /// Calcula o novo streak dado o streak anterior, a data da última sessão
  /// completa anterior (nula se nunca houve) e o instante da sessão que
  /// acabou de ser completada — todos em horário local.
  int computeStreakOnSessionCompleted({
    required int previousStreak,
    required DateTime? lastCompletedAt,
    required DateTime completedAt,
  }) {
    if (lastCompletedAt == null) return 1;

    if (_isSameLocalDay(lastCompletedAt, completedAt)) {
      return previousStreak == 0 ? 1 : previousStreak;
    }

    final yesterday = completedAt.subtract(const Duration(days: 1));
    if (_isSameLocalDay(lastCompletedAt, yesterday)) {
      return previousStreak + 1;
    }

    return 1;
  }
}
