import 'package:auth_module/auth_module.dart';
import 'package:core/core.dart';
import 'package:question_bank_module/question_bank.dart';
import 'package:quiz_module/quiz_module.dart';
import 'package:shared/shared.dart';

/// Merges an anonymous (guest) session's local progress into an existing
/// account being logged into — the "git-like" merge decided with the
/// user: per question, the record with the more recent `lastSeenAt` wins
/// whole (never mixed field-by-field); XP sums (the two histories are
/// genuinely disjoint — different uids that never synced to each other
/// before); streak takes whichever side has the more recent
/// `streakLastCompletedAt`.
///
/// Registered manually only in stg/prod (see
/// `_registerStgProdOverrides` in quiz_app/lib/di/injection.dart) — not
/// `@LazySingleton`-annotated on purpose, since [AccountMergeService] is
/// already registered by auth_module's [DefaultAccountMergeService] and
/// injectable would collide on the duplicate binding. Dev keeps that
/// default (its fakes have no real accounts to merge into anyway).
class RealAccountMergeService implements AccountMergeService {
  RealAccountMergeService(
    this._authRepository,
    this._progressRepository,
    this._getRawLocalStats,
    this._setRawLocalStats,
    this._progressReader,
  );

  final AuthRepository _authRepository;
  final ProgressRepository _progressRepository;
  final GetRawLocalStatsUseCase _getRawLocalStats;
  final SetRawLocalStatsUseCase _setRawLocalStats;
  final FirestoreProgressReader _progressReader;

  @override
  Future<Result<User>> loginAndMerge({
    required String email,
    required String password,
  }) => _mergeAround(
    () => _authRepository.login(email: email, password: password),
  );

  @override
  Future<Result<User>> completeMerge(AccountExistsFailure failure) =>
      _mergeAround(() => _authRepository.signInWithFailedCredential(failure));

  /// Snapshots local progress, runs [doLogin], and if it succeeds merges
  /// the snapshot into whatever account was just signed into.
  Future<Result<User>> _mergeAround(
    Future<Result<User>> Function() doLogin,
  ) async {
    final localProgress =
        (await _progressRepository.getAll()).dataOrNull ?? const [];
    final localStats = await _getRawLocalStats();

    final loginResult = await doLogin();
    if (loginResult.isFailure) return loginResult;

    final uid = _authRepository.currentUid;
    if (uid == null) return loginResult;

    try {
      final remote = await _progressReader.fetchAll(uid);
      await _mergePerQuestion(localProgress, remote.perQuestion);
      final streak = _newerStreakWins(localStats, remote);
      await _setRawLocalStats(
        RawLocalStats(
          xpTotal: localStats.xpTotal + remote.xpTotal,
          streakDays: streak.streakDays,
          streakLastCompletedAt: streak.streakLastCompletedAt,
        ),
      );
    } catch (e) {
      // Login already succeeded — surface the user as signed in even if
      // the merge itself failed (e.g. transient network blip right after
      // sign-in); nothing was lost locally, so it's safe to retry later.
      AppLogger.warning(
        'Falha ao mesclar progresso anônimo na conta existente',
        tag: 'AccountMerge',
        error: e,
      );
    }

    return loginResult;
  }

  Future<void> _mergePerQuestion(
    List<QuestionProgress> local,
    List<QuestionProgress> remote,
  ) async {
    final merged = <String, QuestionProgress>{
      for (final p in remote) p.questionId: p,
    };
    for (final p in local) {
      final existing = merged[p.questionId];
      if (existing == null || _isAfter(p.lastSeenAt, existing.lastSeenAt)) {
        merged[p.questionId] = p;
      }
    }
    for (final p in merged.values) {
      await _progressRepository.save(p);
    }
  }

  ({int streakDays, DateTime? streakLastCompletedAt}) _newerStreakWins(
    RawLocalStats local,
    RemoteProgressSnapshot remote,
  ) {
    final localIsNewer = _isAfter(
      local.streakLastCompletedAt,
      remote.streakLastCompletedAt,
    );
    return localIsNewer
        ? (
            streakDays: local.streakDays,
            streakLastCompletedAt: local.streakLastCompletedAt,
          )
        : (
            streakDays: remote.streakDays,
            streakLastCompletedAt: remote.streakLastCompletedAt,
          );
  }

  bool _isAfter(DateTime? a, DateTime? b) {
    if (a == null) return false;
    if (b == null) return true;
    return a.isAfter(b);
  }
}
