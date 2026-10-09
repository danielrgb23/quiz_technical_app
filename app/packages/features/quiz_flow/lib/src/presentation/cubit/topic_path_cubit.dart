import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:quiz_module/quiz_module.dart';

sealed class TopicPathState {
  const TopicPathState();
}

class TopicPathLoading extends TopicPathState {
  const TopicPathLoading();
}

class TopicPathLoaded extends TopicPathState {
  const TopicPathLoaded({
    required this.totalLessons,
    required this.completedLessons,
  });

  final int totalLessons;

  /// Lições concluídas (>= 80% de acertos); a atual é o índice
  /// `completedLessons`.
  final int completedLessons;

  bool get isFinished => totalLessons > 0 && completedLessons >= totalLessons;
}

class TopicPathError extends TopicPathState {
  const TopicPathError(this.message);

  final String message;
}

/// Trilha (roadmap) de um tópico. O progresso vem do [LearningPathService]:
/// cada tópico tem a sua trilha, independente das demais.
@injectable
class TopicPathCubit extends Cubit<TopicPathState> {
  TopicPathCubit(this._learningPathService) : super(const TopicPathLoading());

  final LearningPathService _learningPathService;

  Future<void> load(String topic) async {
    try {
      final progress = await _learningPathService.progress(topic);
      emit(
        TopicPathLoaded(
          totalLessons: progress.total,
          completedLessons: progress.completed,
        ),
      );
    } catch (_) {
      emit(const TopicPathError('load_failed'));
    }
  }
}
