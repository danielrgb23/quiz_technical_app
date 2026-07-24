import 'package:freezed_annotation/freezed_annotation.dart';

import 'answer.dart';

part 'session_result.freezed.dart';

/// Resumo de uma sessão concluída (tela de resumo, spec-03).
@freezed
abstract class SessionResult with _$SessionResult {
  const factory SessionResult({
    required int totalQuestions,
    required int correctCount,
    required int wrongCount,
    required int xpEarned,
    required int streakDays,
    required List<Answer> wrongAnswers,
  }) = _SessionResult;
}
