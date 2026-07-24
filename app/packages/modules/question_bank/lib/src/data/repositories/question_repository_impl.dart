import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/question.dart';
import '../../domain/repositories/question_repository.dart';
import '../db/question_bank_db.dart';

@LazySingleton(as: QuestionRepository)
class QuestionRepositoryImpl implements QuestionRepository {
  QuestionRepositoryImpl(this._db);

  final QuestionBankDb _db;

  @override
  Future<Result<List<Question>>> getByTopic(String topic, {int? limit}) async {
    try {
      final query = _db.select(_db.questions)
        ..where((q) => q.topic.equals(topic));
      if (limit != null) query.limit(limit);
      final rows = await query.get();
      return Result.success(rows.map(questionFromRow).toList());
    } catch (e) {
      return Result.failure(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Question>> getById(String id) async {
    try {
      final row = await (_db.select(
        _db.questions,
      )..where((q) => q.id.equals(id))).getSingleOrNull();
      if (row == null) {
        return Result.failure(
          const CacheFailure(message: 'questão não encontrada'),
        );
      }
      return Result.success(questionFromRow(row));
    } catch (e) {
      return Result.failure(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Question>>> getAll() async {
    try {
      final rows = await _db.select(_db.questions).get();
      return Result.success(rows.map(questionFromRow).toList());
    } catch (e) {
      return Result.failure(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<String>>> getTopics() async {
    try {
      final query = _db.selectOnly(_db.questions, distinct: true)
        ..addColumns([_db.questions.topic]);
      final rows = await query.get();
      return Result.success(
        rows.map((r) => r.read(_db.questions.topic)!).toList()..sort(),
      );
    } catch (e) {
      return Result.failure(UnexpectedFailure(message: e.toString()));
    }
  }
}
