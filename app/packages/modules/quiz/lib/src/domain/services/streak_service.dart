import 'package:injectable/injectable.dart';

/// Diferença em dias de calendário (local) entre [a] e [b]: 0 = mesmo dia,
/// 1 = [b] é o dia seguinte a [a], negativo = [b] é anterior a [a].
///
/// Usa a data (ano/mês/dia) e não `Duration` de 24h: em dias de horário de
/// verão (23h/25h) subtrair 24h cai no dia errado e quebrava o streak.
int _calendarDaysBetween(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

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

    final gap = _calendarDaysBetween(lastCompletedAt, completedAt);
    // Mesmo dia (ou relógio do aparelho voltou no tempo): não soma nem zera.
    if (gap <= 0) return previousStreak == 0 ? 1 : previousStreak;
    // Dia seguinte: soma. Qualquer dia pulado: recomeça em 1.
    return gap == 1 ? previousStreak + 1 : 1;
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
    // Hoje ou ontem ainda mantém; antes de ontem o streak quebrou.
    return _calendarDaysBetween(lastCompletedAt, now) <= 1 ? storedStreak : 0;
  }
}
