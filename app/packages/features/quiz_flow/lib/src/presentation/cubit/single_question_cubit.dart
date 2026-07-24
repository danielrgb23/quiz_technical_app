import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:question_bank_module/question_bank.dart';
import 'package:quiz_module/quiz_module.dart';

import 'single_question_state.dart';

/// ViewModel do modo questão única (deeplink `/question/{id}`): a explicação
/// SHALL ficar sempre visível ao responder, independente do resultado.
@injectable
class SingleQuestionCubit extends Cubit<SingleQuestionState> {
  SingleQuestionCubit(this._questionRepository, this._answerQuestionUseCase)
    : super(const SingleQuestionState.loading());

  final QuestionRepository _questionRepository;
  final AnswerQuestionUseCase _answerQuestionUseCase;

  Future<void> load(String id) async {
    emit(const SingleQuestionState.loading());
    final result = await _questionRepository.getById(id);
    if (result.isFailure) {
      emit(const SingleQuestionState.notFound());
      return;
    }
    emit(SingleQuestionState.loaded(question: result.dataOrNull!));
  }

  void selectOption(int index) {
    final current = state;
    if (current is! SingleQuestionLoaded || current.answer != null) return;
    emit(current.copyWith(selectedIndex: index));
  }

  Future<void> confirm() async {
    final current = state;
    if (current is! SingleQuestionLoaded || current.selectedIndex == null) {
      return;
    }
    final result = await _answerQuestionUseCase.call(
      question: current.question,
      selectedIndex: current.selectedIndex!,
      elapsedMs: 0,
    );
    if (result.isFailure) return;
    emit(current.copyWith(answer: result.dataOrNull));
  }
}
