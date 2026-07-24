import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:question_bank_module/question_bank.dart';
import 'package:quiz_module/quiz_module.dart';

part 'quiz_session_state.freezed.dart';

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
    int? selectedIndex,
  }) = QuizSessionQuestion;

  const factory QuizSessionState.feedback({
    required Question current,
    required Answer answer,
    required int index,
    required int total,
  }) = QuizSessionFeedback;

  const factory QuizSessionState.summary(SessionResult result) =
      QuizSessionSummary;

  const factory QuizSessionState.error(String message) = QuizSessionError;
}
