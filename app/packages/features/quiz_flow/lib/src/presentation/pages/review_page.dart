import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:quiz_module/quiz_module.dart';

import 'quiz_session_page.dart';

/// Modo Revisão (`/review`): sessão só com questões vencidas
/// (`nextReviewAt <= now`), priorizadas pelo `SpacedRepetitionScheduler`.
@RoutePage()
class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const QuizSessionPage(mode: SessionMode.review);
}
