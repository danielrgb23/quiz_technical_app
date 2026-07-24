import 'package:injectable/injectable.dart';

/// SM-2 simplificado (design.md decisão 2): erro volta ao intervalo curto
/// (1 dia); acertos consecutivos avançam pela sequência 1d → 3d → 7d → 21d.
@lazySingleton
class SpacedRepetitionScheduler {
  static const intervalsDays = [1, 3, 7, 21];

  /// Calcula o próximo `nextReviewAt` a partir de [now].
  ///
  /// [consecutiveCorrectAfterAnswer] é o número de acertos consecutivos da
  /// questão JÁ incluindo a resposta atual (0 se a resposta atual foi
  /// incorreta — o chamador reseta o contador antes de chamar aqui).
  DateTime nextReviewAt({
    required DateTime now,
    required bool wasCorrect,
    required int consecutiveCorrectAfterAnswer,
  }) {
    if (!wasCorrect) {
      return now.add(Duration(days: intervalsDays.first));
    }
    final step = (consecutiveCorrectAfterAnswer - 1).clamp(
      0,
      intervalsDays.length - 1,
    );
    return now.add(Duration(days: intervalsDays[step]));
  }
}
