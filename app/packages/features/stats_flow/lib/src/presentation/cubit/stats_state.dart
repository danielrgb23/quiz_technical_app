import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quiz_module/quiz_module.dart';

part 'stats_state.freezed.dart';

@freezed
sealed class StatsState with _$StatsState {
  const factory StatsState.loading() = StatsLoading;
  const factory StatsState.loaded(UserStats stats) = StatsLoaded;
  const factory StatsState.error(String message) = StatsError;
}
