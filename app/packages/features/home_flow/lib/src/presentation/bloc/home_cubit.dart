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
    required int xpTotal,
    @Default({}) Map<String, PathProgress> paths,
  }) = HomeLoaded;
  const factory HomeState.failure(String message) = HomeFailure;
}

/// ViewModel do dashboard (spec-03): tópicos (roadmaps) com o progresso de
/// cada trilha, streak atual e acesso ao desafio diário.
@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(
    this._questionRepository,
    this._getUserStatsUseCase,
    this._learningPathService,
  ) : super(const HomeState.initial());

  final QuestionRepository _questionRepository;
  final GetUserStatsUseCase _getUserStatsUseCase;
  final LearningPathService _learningPathService;

  Future<void> loadDashboard() async {
    emit(const HomeState.loading());

    final topicsResult = await _questionRepository.getTopics();
    if (topicsResult.isFailure) {
      emit(HomeState.failure(topicsResult.failureOrNull!.message));
      return;
    }

    final topics = topicsResult.dataOrNull!;
    // Cada tópico é um roadmap independente; mostramos o progresso de todos.
    final paths = {
      for (final topic in topics)
        topic: await _learningPathService.progress(topic),
    };

    final statsResult = await _getUserStatsUseCase();
    emit(
      HomeState.loaded(
        topics: topics,
        paths: paths,
        streakDays: statsResult.dataOrNull?.streakDays ?? 0,
        xpTotal: statsResult.dataOrNull?.xpTotal ?? 0,
      ),
    );
  }
}
