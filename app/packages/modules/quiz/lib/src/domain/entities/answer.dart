import 'package:freezed_annotation/freezed_annotation.dart';

part 'answer.freezed.dart';

@freezed
abstract class Answer with _$Answer {
  const factory Answer({
    required String questionId,
    required int selectedIndex,
    required bool isCorrect,
    required int elapsedMs,
  }) = _Answer;
}
