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

  /// Streak para exibição (ex.: dashboard) sem que o usuário tenha
  /// completado uma sessão hoje: [computeStreakOnSessionCompleted] só
  /// reavalia o streak quando uma sessão é concluída, então sem isso a UI
  /// continuaria mostrando o streak antigo mesmo depois de dias sem
  /// atividade. Streak quebrado (última sessão antes de ontem) exibe 0.
  int currentStreak({
    required int storedStreak,
    required DateTime? lastCompletedAt,
    required DateTime now,
  }) {
    if (lastCompletedAt == null) return 0;
    if (_isSameLocalDay(lastCompletedAt, now)) return storedStreak;

    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameLocalDay(lastCompletedAt, yesterday)) return storedStreak;

    return 0;
  }
}
