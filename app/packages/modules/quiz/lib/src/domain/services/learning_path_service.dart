import 'package:core/core.dart';
import 'package:injectable/injectable.dart';
import 'package:question_bank_module/question_bank.dart';

/// Questões por lição (nó) da trilha de um tópico.
const lessonSize = 5;

/// Fração mínima de acertos para concluir uma lição e liberar a próxima.
const lessonPassRatio = 0.8;

/// Estado da trilha (roadmap) de um tópico.
class PathProgress {
  const PathProgress({required this.completed, required this.total});

  /// Lições concluídas; a lição atual é o índice [completed].
  final int completed;
  final int total;

  bool get isFinished => total > 0 && completed >= total;
}

/// Progresso por tópico: cada tópico é um roadmap independente e o usuário
/// pode alternar entre eles livremente. Uma lição só conta como concluída
/// com >= [lessonPassRatio] de acertos.
@lazySingleton
class LearningPathService {
  LearningPathService(this._questionRepository, this._localStorage);

  final QuestionRepository _questionRepository;
  final LocalStorage _localStorage;

  static String _key(String topic) => 'path_completed_$topic';

  static bool passed({required int correct, required int total}) =>
      total > 0 && correct / total >= lessonPassRatio;

  Future<PathProgress> progress(String topic) async {
    final questions = await _questionRepository.getByTopic(topic);
    final count = questions.dataOrNull?.length ?? 0;
    final total = (count / lessonSize).ceil();
    final saved = await _localStorage.getInt(_key(topic)) ?? 0;
    return PathProgress(completed: saved.clamp(0, total), total: total);
  }

  /// Registra o resultado da lição [lesson]. Devolve `true` quando ela era a
  /// lição atual e foi aprovada (próxima lição liberada).
  Future<bool> recordLessonResult({
    required String topic,
    required int lesson,
    required int correct,
    required int total,
  }) async {
    if (!passed(correct: correct, total: total)) return false;
    final current = await progress(topic);
    if (lesson != current.completed || current.completed >= current.total) {
      return false;
    }
    await _localStorage.setInt(_key(topic), current.completed + 1);
    return true;
  }
}
