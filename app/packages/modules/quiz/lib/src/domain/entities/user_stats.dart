import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_stats.freezed.dart';

@freezed
abstract class TopicStats with _$TopicStats {
  const factory TopicStats({
    required String topic,
    @Default(0) int seen,
    @Default(0) int correct,
    @Default(0) int wrong,
  }) = _TopicStats;
}

@freezed
abstract class UserStats with _$UserStats {
  const factory UserStats({
    @Default(0) int streakDays,
    @Default(0) int xpTotal,
    @Default([]) List<TopicStats> byTopic,
  }) = _UserStats;
}
