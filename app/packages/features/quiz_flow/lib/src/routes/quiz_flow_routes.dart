import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:quiz_module/quiz_module.dart';

import '../presentation/pages/daily_challenge_page.dart';
import '../presentation/pages/pre_session_page.dart';
import '../presentation/pages/quiz_session_page.dart';
import '../presentation/pages/review_page.dart';
import '../presentation/pages/single_question_page.dart';

part 'quiz_flow_routes.gr.dart';

@AutoRouterConfig()
class QuizFlowRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: PreSessionRoute.page),
    AutoRoute(page: QuizSessionRoute.page),
    AutoRoute(page: SingleQuestionRoute.page),
    AutoRoute(page: DailyChallengeRoute.page),
    AutoRoute(page: ReviewRoute.page),
  ];
}
