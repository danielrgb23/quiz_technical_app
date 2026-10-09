import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:question_bank_module/question_bank.dart';
import 'package:quiz_module/quiz_module.dart';

part 'quiz_session_state.freezed.dart';

/// Resultado de uma lição da trilha (aprovada com >= 80% de acertos?).
class LessonOutcome {
  const LessonOutcome({
    required this.lesson,
    required this.passed,
    required this.ratio,
    required this.newlyUnlocked,
  });

  final int lesson;
  final bool passed;

  /// Acertos / total (0..1).
  final double ratio;

  /// A próxima lição foi liberada agora (não era já liberada).
  final bool newlyUnlocked;
}

@freezed
sealed class QuizSessionState with _$QuizSessionState {
  const factory QuizSessionState.loading() = QuizSessionLoading;

  /// Nenhuma questão disponível para o modo/tópico escolhido (ex.: revisão
  /// sem nada vencido).
  const factory QuizSessionState.empty() = QuizSessionEmpty;

  const factory QuizSessionState.question({
    required Question current,
    required int index,
    required int total,
    required int streakDays,
    required List<int> optionOrder,
    int? selectedIndex,
  }) = QuizSessionQuestion;

  const factory QuizSessionState.feedback({
    required Question current,
    required Answer answer,
    required int index,
    required int total,
    required List<int> optionOrder,
  }) = QuizSessionFeedback;

  const factory QuizSessionState.summary(
    SessionResult result, {

    /// Preenchido só em sessões de lição da trilha.
    LessonOutcome? lesson,
    @Default([]) List<Question> wrongQuestions,
  }) = QuizSessionSummary;

  const factory QuizSessionState.error(String message) = QuizSessionError;
}
