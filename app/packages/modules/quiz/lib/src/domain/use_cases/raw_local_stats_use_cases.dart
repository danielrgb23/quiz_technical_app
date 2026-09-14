import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

const _kXpTotalKey = 'quiz_xp_total';
const _kStreakDaysKey = 'quiz_streak_days';
const _kStreakLastCompletedAtKey = 'quiz_streak_last_completed_at';

class RawLocalStats {
  const RawLocalStats({
    required this.xpTotal,
    required this.streakDays,
    this.streakLastCompletedAt,
  });

  final int xpTotal;
  final int streakDays;
  final DateTime? streakLastCompletedAt;
}

/// Raw XP/streak reader — used by [quiz_app]'s account-merge orchestration,
/// which needs the unprocessed local values (no "is streak still active"
/// logic, unlike [GetUserStatsUseCase]).
@lazySingleton
class GetRawLocalStatsUseCase {
  GetRawLocalStatsUseCase(this._localStorage);

  final LocalStorage _localStorage;

  Future<RawLocalStats> call() async {
    final xpTotal = await _localStorage.getInt(_kXpTotalKey) ?? 0;
    final streakDays = await _localStorage.getInt(_kStreakDaysKey) ?? 0;
    final raw = await _localStorage.getString(_kStreakLastCompletedAtKey);
    return RawLocalStats(
      xpTotal: xpTotal,
      streakDays: streakDays,
      streakLastCompletedAt: raw != null ? DateTime.parse(raw) : null,
    );
  }
}

/// Overwrites local XP/streak — used to land the merged result during
/// account linking (see [quiz_app]'s AccountMergeService).
@lazySingleton
class SetRawLocalStatsUseCase {
  SetRawLocalStatsUseCase(this._localStorage);

  final LocalStorage _localStorage;

  Future<void> call(RawLocalStats stats) async {
    await _localStorage.setInt(_kXpTotalKey, stats.xpTotal);
    await _localStorage.setInt(_kStreakDaysKey, stats.streakDays);
    if (stats.streakLastCompletedAt != null) {
      await _localStorage.setString(
        _kStreakLastCompletedAtKey,
        stats.streakLastCompletedAt!.toIso8601String(),
      );
    }
  }
}
