import 'package:core/core.dart';

/// Report de questão offline-first (design.md decisão 7, Spec 03):
/// enfileira localmente de imediato e sincroniza com o remoto quando online,
/// reaproveitando a fila `pending_sync` do question_bank.
abstract class QuestionReportRepository {
  Future<Result<void>> reportQuestion(String questionId);
}
