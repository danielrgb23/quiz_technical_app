/// Modos de sessão de quiz (spec-03-features-quiz.md).
enum SessionMode {
  /// N questões de um tópico, priorizando não vistas e revisões vencidas.
  topic,

  /// Apenas questões com `nextReviewAt <= now`, de qualquer tópico.
  review,

  /// 10 questões fixas por dia (seed determinístico pela data).
  daily,
}
