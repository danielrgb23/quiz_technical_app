import 'dart:convert';

import 'package:core/core.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/question_progress.dart';
import '../../domain/repositories/progress_repository.dart';
import '../db/question_bank_db.dart';

@LazySingleton(as: ProgressRepository)
class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(this._db);

  final QuestionBankDb _db;

  @override
  Future<Result<QuestionProgress?>> getByQuestionId(String questionId) async {
    try {
      final row = await (_db.select(
        _db.progress,
      )..where((p) => p.questionId.equals(questionId))).getSingleOrNull();
      return Result.success(row == null ? null : progressFromRow(row));
    } catch (e) {
      return Result.failure(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<QuestionProgress>>> getAll() async {
    try {
      final rows = await _db.select(_db.progress).get();
      return Result.success(rows.map(progressFromRow).toList());
    } catch (e) {
      return Result.failure(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<QuestionProgress>>> getDueForReview(DateTime now) async {
    try {
      final rows =
          await (_db.select(_db.progress)..where(
                (p) =>
                    p.nextReviewAt.isNotNull() &
                    p.nextReviewAt.isSmallerOrEqualValue(now),
              ))
              .get();
      return Result.success(rows.map(progressFromRow).toList());
    } catch (e) {
      return Result.failure(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> save(QuestionProgress progress) async {
    try {
      await _db.transaction(() async {
        await _db
            .into(_db.progress)
            .insertOnConflictUpdate(
              ProgressCompanion.insert(
                questionId: progress.questionId,
                correctCount: Value(progress.correctCount),
                wrongCount: Value(progress.wrongCount),
                lastSeenAt: Value(progress.lastSeenAt),
                nextReviewAt: Value(progress.nextReviewAt),
              ),
            );
        await _db
            .into(_db.pendingSync)
            .insert(
              PendingSyncCompanion.insert(
                questionId: progress.questionId,
                payloadJson: jsonEncode(progress.toJson()),
                createdAt: DateTime.now(),
              ),
            );
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure(UnexpectedFailure(message: e.toString()));
    }
  }
}
