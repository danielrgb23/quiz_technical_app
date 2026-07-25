import 'package:auto_route/auto_route.dart';

import 'package:auth_flow/auth_flow.dart';
import 'package:core/core.dart';
import 'package:home_flow/home_flow.dart';
import 'package:onboarding/onboarding.dart';
import 'package:profile_flow/profile_flow.dart';
import 'package:quiz_flow/quiz_flow.dart';
import 'package:stats_flow/stats_flow.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, path: AppRoutes.home, initial: true),
    AutoRoute(page: HomeItemDetailRoute.page, path: AppRoutes.homeDetail),
    AutoRoute(page: LoginRoute.page, path: AppRoutes.login),
    AutoRoute(page: RegisterRoute.page, path: AppRoutes.register),
    AutoRoute(page: OnboardingRoute.page, path: AppRoutes.onboarding),
    AutoRoute(page: ProfileRoute.page, path: AppRoutes.profile),
    AutoRoute(page: EditProfileRoute.page, path: AppRoutes.editProfile),
    // Deeplinks do quiz (quizapp:// e App/Universal Links) — Spec 03
    AutoRoute(page: PreSessionRoute.page, path: AppRoutes.quizTopic),
    AutoRoute(page: SingleQuestionRoute.page, path: AppRoutes.question),
    AutoRoute(page: DailyChallengeRoute.page, path: AppRoutes.daily),
    AutoRoute(page: ReviewRoute.page, path: AppRoutes.review),
    // Não-deeplink: pré-sessão empurra para aqui com o modo/tópico/tamanho.
    AutoRoute(page: QuizSessionRoute.page),
    AutoRoute(page: StatsRoute.page, path: AppRoutes.stats),
  ];
}
