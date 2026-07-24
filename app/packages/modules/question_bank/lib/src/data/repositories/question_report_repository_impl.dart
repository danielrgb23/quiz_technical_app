import 'dart:convert';

import 'package:core/core.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/question_report_repository.dart';
import '../db/question_bank_db.dart';

@LazySingleton(as: QuestionReportRepository)
class QuestionReportRepositoryImpl implements QuestionReportRepository {
  QuestionReportRepositoryImpl(this._db);

  final QuestionBankDb _db;

  @override
  Future<Result<void>> reportQuestion(String questionId) async {
    try {
      await _db
          .into(_db.pendingSync)
          .insert(
            PendingSyncCompanion.insert(
              questionId: questionId,
              payloadJson: jsonEncode({'questionId': questionId}),
              createdAt: DateTime.now(),
              type: const Value('flagged'),
            ),
          );
      return Result.success(null);
    } catch (e) {
      return Result.failure(UnexpectedFailure(message: e.toString()));
    }
  }
}
