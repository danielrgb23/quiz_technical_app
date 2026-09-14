import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../db/question_bank_db.dart';

const statsSyncPlaceholderId = '_stats';

/// Entry point for other modules (namely `quiz`'s `CompleteSessionUseCase`)
/// to enqueue XP/streak onto the same offline-first `PendingSync` queue
/// used for per-question progress — [ProgressSyncQueue] drains both.
abstract class StatsSyncGateway {
  Future<void> enqueueStats({
    required int xpTotal,
    required int streakDays,
    DateTime? streakLastCompletedAt,
  });
}

@LazySingleton(as: StatsSyncGateway)
class StatsSyncGatewayImpl implements StatsSyncGateway {
  StatsSyncGatewayImpl(this._db);

  final QuestionBankDb _db;

  @override
  Future<void> enqueueStats({
    required int xpTotal,
    required int streakDays,
    DateTime? streakLastCompletedAt,
  }) {
    return _db
        .into(_db.pendingSync)
        .insert(
          PendingSyncCompanion.insert(
            questionId: statsSyncPlaceholderId,
            type: const Value('stats'),
            payloadJson: jsonEncode({
              'xpTotal': xpTotal,
              'streakDays': streakDays,
              'streakLastCompletedAt': streakLastCompletedAt
                  ?.toIso8601String(),
            }),
            createdAt: DateTime.now(),
          ),
        );
  }
}
