import 'package:core/core.dart';
import 'package:question_bank_module/question_bank.dart';
import 'package:shared/shared.dart';

Question makeQuestion(String id, {String topic = 'flutter'}) => Question(
  id: id,
  source: 'test',
  topic: topic,
  level: 1,
  question: 'Pergunta $id?',
  options: const ['certa', 'errada 1', 'errada 2', 'errada 3', 'errada 4'],
  correctIndex: 0,
  explanation: 'A alternativa certa está correta porque sim.',
);

class FakeQuestionRepository implements QuestionRepository {
  FakeQuestionRepository(this.questions);

  final List<Question> questions;

  @override
  Future<Result<List<Question>>> getByTopic(String topic, {int? limit}) async {
    final result = questions.where((q) => q.topic == topic).toList();
    return Result.success(limit == null ? result : result.take(limit).toList());
  }

  @override
  Future<Result<Question>> getById(String id) async {
    final match = questions.where((q) => q.id == id);
    if (match.isEmpty) {
      return Result.failure(const CacheFailure(message: 'not found'));
    }
    return Result.success(match.first);
  }

  @override
  Future<Result<List<Question>>> getAll() async => Result.success(questions);

  @override
  Future<Result<List<String>>> getTopics() async =>
      Result.success(questions.map((q) => q.topic).toSet().toList());
}

class FakeProgressRepository implements ProgressRepository {
  final Map<String, QuestionProgress> store = {};

  @override
  Future<Result<QuestionProgress?>> getByQuestionId(String questionId) async =>
      Result.success(store[questionId]);

  @override
  Future<Result<List<QuestionProgress>>> getAll() async =>
      Result.success(store.values.toList());

  @override
  Future<Result<List<QuestionProgress>>> getDueForReview(DateTime now) async =>
      Result.success(
        store.values
            .where(
              (p) => p.nextReviewAt != null && !p.nextReviewAt!.isAfter(now),
            )
            .toList(),
      );

  @override
  Future<Result<void>> save(QuestionProgress progress) async {
    store[progress.questionId] = progress;
    return Result.success(null);
  }
}

class FakeLocalStorage implements LocalStorage {
  final Map<String, Object> _values = {};

  @override
  Future<bool?> getBool(String key) async => _values[key] as bool?;

  @override
  Future<int?> getInt(String key) async => _values[key] as int?;

  @override
  Future<String?> getString(String key) async => _values[key] as String?;

  @override
  Future<void> setBool(String key, {required bool value}) async {
    _values[key] = value;
  }

  @override
  Future<void> setInt(String key, int value) async {
    _values[key] = value;
  }

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async => _values.remove(key);

  @override
  Future<void> clear() async => _values.clear();
}

class FakeQuestionReportRepository implements QuestionReportRepository {
  final List<String> reported = [];

  @override
  Future<Result<void>> reportQuestion(String questionId) async {
    reported.add(questionId);
    return Result.success(null);
  }
}

class FakeAnalyticsService implements AnalyticsService {
  @override
  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? parameters,
  }) async {}

  @override
  Future<void> logScreenView(String screenName) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setUserProperty(String name, String value) async {}
}
