import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:question_bank_module/question_bank.dart';

import 'answer.dart';
import 'session_mode.dart';

part 'quiz_session.freezed.dart';

/// Sessão de quiz em memória (não persistida como entidade própria — cada
/// resposta já persiste via ProgressRepository; ver design.md decisão 4).
@freezed
abstract class QuizSession with _$QuizSession {
  const factory QuizSession({
    required String id,
    required SessionMode mode,
    String? topic,
    required List<Question> questions,
    @Default(0) int currentIndex,
    @Default([]) List<Answer> answers,
    required DateTime startedAt,
    DateTime? finishedAt,
  }) = _QuizSession;

  const QuizSession._();

  Question? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  bool get isFinished => currentIndex >= questions.length;

  int get correctCount => answers.where((a) => a.isCorrect).length;

  int get wrongCount => answers.where((a) => !a.isCorrect).length;
}
