/// Espelho remoto de XP/streak (`users/{uid}/progress/_stats`, stg/prod
/// only — ver firebase-integration spec).
abstract class StatsRemoteDataSource {
  Future<void> upsert({
    required int xpTotal,
    required int streakDays,
    DateTime? streakLastCompletedAt,
  });
}

/// Fake para dev/testes: aceita tudo sem efeito.
class FakeStatsRemoteDataSource implements StatsRemoteDataSource {
  int? lastXpTotal;
  int? lastStreakDays;

  @override
  Future<void> upsert({
    required int xpTotal,
    required int streakDays,
    DateTime? streakLastCompletedAt,
  }) async {
    lastXpTotal = xpTotal;
    lastStreakDays = streakDays;
  }
}
