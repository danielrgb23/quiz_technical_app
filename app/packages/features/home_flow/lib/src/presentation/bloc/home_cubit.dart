import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:question_bank_module/question_bank.dart';
import 'package:quiz_module/quiz_module.dart';

part 'home_cubit.freezed.dart';

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState.initial() = HomeInitial;
  const factory HomeState.loading() = HomeLoading;
  const factory HomeState.loaded({
    required List<String> topics,
    required int streakDays,
  }) = HomeLoaded;
  const factory HomeState.failure(String message) = HomeFailure;
}

/// ViewModel do dashboard (spec-03): tópicos disponíveis e streak atual,
/// usados para navegar para a pré-sessão por tópico e para o desafio diário.
@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._questionRepository, this._getUserStatsUseCase)
    : super(const HomeState.initial());

  final QuestionRepository _questionRepository;
  final GetUserStatsUseCase _getUserStatsUseCase;

  Future<void> loadDashboard() async {
    emit(const HomeState.loading());

    final topicsResult = await _questionRepository.getTopics();
    if (topicsResult.isFailure) {
      emit(HomeState.failure(topicsResult.failureOrNull!.message));
      return;
    }

    final statsResult = await _getUserStatsUseCase();
    emit(
      HomeState.loaded(
        topics: topicsResult.dataOrNull!,
        streakDays: statsResult.dataOrNull?.streakDays ?? 0,
      ),
    );
  }
}
