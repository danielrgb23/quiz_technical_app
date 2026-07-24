import 'package:flutter/foundation.dart';

/// Progresso do usuário em uma questão.
@immutable
class QuestionProgress {
  const QuestionProgress({
    required this.questionId,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.lastSeenAt,
    this.nextReviewAt,
  });

  final String questionId;
  final int correctCount;
  final int wrongCount;
  final DateTime? lastSeenAt;
  final DateTime? nextReviewAt;

  QuestionProgress copyWith({
    int? correctCount,
    int? wrongCount,
    DateTime? lastSeenAt,
    DateTime? nextReviewAt,
  }) => QuestionProgress(
    questionId: questionId,
    correctCount: correctCount ?? this.correctCount,
    wrongCount: wrongCount ?? this.wrongCount,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    nextReviewAt: nextReviewAt ?? this.nextReviewAt,
  );

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'correctCount': correctCount,
    'wrongCount': wrongCount,
    'lastSeenAt': lastSeenAt?.toIso8601String(),
    'nextReviewAt': nextReviewAt?.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is QuestionProgress && other.questionId == questionId;

  @override
  int get hashCode => questionId.hashCode;
}
