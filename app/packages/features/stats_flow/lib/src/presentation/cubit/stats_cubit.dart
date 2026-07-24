import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:quiz_module/quiz_module.dart';

import 'stats_state.dart';

/// ViewModel da tela de estatísticas (stats_flow, spec-03).
@injectable
class StatsCubit extends Cubit<StatsState> {
  StatsCubit(this._getUserStatsUseCase) : super(const StatsState.loading());

  final GetUserStatsUseCase _getUserStatsUseCase;

  Future<void> load() async {
    emit(const StatsState.loading());
    final result = await _getUserStatsUseCase();
    if (result.isFailure) {
      emit(StatsState.error(result.failureOrNull!.message));
      return;
    }
    emit(StatsState.loaded(result.dataOrNull!));
  }
}
