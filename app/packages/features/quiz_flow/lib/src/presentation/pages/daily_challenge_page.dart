import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:quiz_module/quiz_module.dart';

import 'quiz_session_page.dart';

/// Desafio diário (deeplink `/daily`): thin wrapper que inicia a sessão no
/// modo `daily` — mesmas 10 questões o dia todo (seed determinístico).
@RoutePage()
class DailyChallengePage extends StatelessWidget {
  const DailyChallengePage({super.key});

  @override
  Widget build(BuildContext context) =>
      const QuizSessionPage(mode: SessionMode.daily);
}
