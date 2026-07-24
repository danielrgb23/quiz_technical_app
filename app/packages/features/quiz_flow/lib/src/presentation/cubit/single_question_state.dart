import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:question_bank_module/question_bank.dart';
import 'package:quiz_module/quiz_module.dart';

part 'single_question_state.freezed.dart';

@freezed
sealed class SingleQuestionState with _$SingleQuestionState {
  const factory SingleQuestionState.loading() = SingleQuestionLoading;
  const factory SingleQuestionState.notFound() = SingleQuestionNotFound;

  const factory SingleQuestionState.loaded({
    required Question question,
    int? selectedIndex,
    Answer? answer,
  }) = SingleQuestionLoaded;

  const factory SingleQuestionState.error(String message) = SingleQuestionError;
}
