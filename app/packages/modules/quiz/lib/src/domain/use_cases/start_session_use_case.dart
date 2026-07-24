import 'dart:math';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';
import 'package:question_bank_module/question_bank.dart';

import '../entities/quiz_session.dart';
import '../entities/session_mode.dart';

const dailyChallengeSize = 10;

/// Monta a fila de questões de uma sessão conforme o modo (spec-03).
@lazySingleton
class StartSessionUseCase {
  StartSessionUseCase(this._questionRepository, this._progressRepository);

  final QuestionRepository _questionRepository;
  final ProgressRepository _progressRepository;

  Future<Result<QuizSession>> call({
    required SessionMode mode,
    String? topic,
    int size = 10,
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final questionsResult = switch (mode) {
      SessionMode.topic => await _byTopic(topic!, size, effectiveNow),
      SessionMode.review => await _review(effectiveNow),
      SessionMode.daily => await _daily(effectiveNow),
    };
    if (questionsResult.isFailure) {
      return Result.failure(questionsResult.failureOrNull!);
    }

    return Result.success(
      QuizSession(
        id: _generateSessionId(effectiveNow),
        mode: mode,
        topic: topic,
        questions: questionsResult.dataOrNull!,
        startedAt: effectiveNow,
      ),
    );
  }

  Future<Result<List<Question>>> _byTopic(
    String topic,
    int size,
    DateTime now,
  ) async {
    final questionsResult = await _questionRepository.getByTopic(topic);
    if (questionsResult.isFailure) return questionsResult;
    final progressResult = await _progressRepository.getAll();
    if (progressResult.isFailure) {
      return Result.failure(progressResult.failureOrNull!);
    }

    final progressById = {
      for (final p in progressResult.dataOrNull!) p.questionId: p,
    };
    final questions = List<Question>.from(questionsResult.dataOrNull!);
    questions.sort(
      (a, b) => _priority(
        a,
        progressById,
        now,
      ).compareTo(_priority(b, progressById, now)),
    );
    return Result.success(questions.take(size).toList());
  }

  /// Menor valor = maior prioridade: não vistas primeiro, depois vencidas
  /// para revisão, depois o restante.
  int _priority(
    Question question,
    Map<String, QuestionProgress> progressById,
    DateTime now,
  ) {
    final progress = progressById[question.id];
    if (progress == null) return 0;
    final due =
        progress.nextReviewAt != null && !progress.nextReviewAt!.isAfter(now);
    return due ? 1 : 2;
  }

  Future<Result<List<Question>>> _review(DateTime now) async {
    final dueResult = await _progressRepository.getDueForReview(now);
    if (dueResult.isFailure) return Result.failure(dueResult.failureOrNull!);

    final questions = <Question>[];
    for (final progress in dueResult.dataOrNull!) {
      final result = await _questionRepository.getById(progress.questionId);
      if (result.isSuccess) questions.add(result.dataOrNull!);
    }
    return Result.success(questions);
  }

  Future<Result<List<Question>>> _daily(DateTime now) async {
    final allResult = await _questionRepository.getAll();
    if (allResult.isFailure) return allResult;

    final all = List<Question>.from(allResult.dataOrNull!)
      ..sort((a, b) => a.id.compareTo(b.id));
    if (all.isEmpty) return Result.success(const []);

    final seed = now.year * 10000 + now.month * 100 + now.day;
    all.shuffle(Random(seed));
    return Result.success(all.take(dailyChallengeSize).toList());
  }

  String _generateSessionId(DateTime now) =>
      '${now.microsecondsSinceEpoch}_${Random().nextInt(1 << 32)}';
}
