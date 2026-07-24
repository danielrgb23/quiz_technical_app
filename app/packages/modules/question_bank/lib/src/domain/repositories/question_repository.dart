import 'package:core/core.dart';

import '../entities/question.dart';

abstract class QuestionRepository {
  Future<Result<List<Question>>> getByTopic(String topic, {int? limit});
  Future<Result<Question>> getById(String id);
  Future<Result<List<Question>>> getAll();
  Future<Result<List<String>>> getTopics();
}
