import 'dart:async';

import 'package:auth_flow/auth_flow.dart';
import 'package:auth_module/auth_module.dart';
import 'package:core/core.dart';
import 'package:get_it/get_it.dart';
import 'package:home_flow/home_flow.dart';
import 'package:home_module/home_module.dart';
import 'package:injectable/injectable.dart';
import 'package:onboarding/onboarding.dart';
import 'package:profile_flow/profile_flow.dart';
import 'package:question_bank_module/question_bank.dart';
import 'package:quiz_flow/quiz_flow.dart';
import 'package:quiz_module/quiz_module.dart';
import 'package:shared/shared.dart';
import 'package:stats_flow/stats_flow.dart';
import 'package:user_profile_module/user_profile_module.dart';

import '../services/real_account_merge_service.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  externalPackageModulesBefore: [
    ExternalModule(CorePackageModule),
    ExternalModule(SharedPackageModule),
    ExternalModule(AuthModulePackageModule),
    ExternalModule(HomeModulePackageModule),
    ExternalModule(QuestionBankModulePackageModule),
    ExternalModule(QuizModulePackageModule),
    ExternalModule(UserProfileModulePackageModule),
    ExternalModule(AuthFlowPackageModule),
    ExternalModule(HomeFlowPackageModule),
    ExternalModule(OnboardingPackageModule),
    ExternalModule(ProfileFlowPackageModule),
    ExternalModule(QuizFlowPackageModule),
    ExternalModule(StatsFlowPackageModule),
  ],
)
Future<void> configureDependencies(String environment) async {
  await getIt.init(environment: environment);

  if (environment == 'dev') {
    _registerDevOverrides();
    // Recupera a sessão fake persistida (equivalente ao refresh token do
    // Firebase em stg/prod) antes do AuthGuard rodar.
    await (getIt<AuthRemoteDataSource>() as FakeAuthRemoteDataSource)
        .restoreSession();
  } else {
    _registerStgProdOverrides();
  }
}

/// Prepara os dados offline-first: banco embarcado no primeiro launch,
/// sync de versão do banco e fila de progresso (nunca bloqueia a UI).
Future<void> bootstrapQuestionBank() async {
  final bankSync = getIt<BankSyncService>();
  await bankSync.ensureSeeded();
  unawaited(bankSync.syncIfNeeded());
  getIt<ProgressSyncQueue>().start();
  // If guest mode started offline (see AuthRepository.loginAnonymously),
  // upgrade the local-only placeholder to a real Firebase anonymous uid
  // now that there's a chance we're online. Best-effort, never blocks.
  unawaited(getIt<AuthRepository>().retryPendingGuestLogin());
  // Covers the returning-user case (login/register pages already handle
  // the fresh-login case themselves — see auth_flow's LoginPage/RegisterPage).
  final uid = getIt<AuthRepository>().currentUid;
  if (uid != null) {
    unawaited(getIt<NotificationService>().initialize(uid: uid));
  }
}

/// Replaces real data sources with in-memory fakes for local development.
///
/// This runs AFTER [getIt.init] so fakes always override the real
/// implementations regardless of injectable_generator's registration order.
void _registerDevOverrides() {
  final previousAllowReassignment = getIt.allowReassignment;
  getIt.allowReassignment = true;
  try {
    getIt.registerLazySingleton<AuthRemoteDataSource>(
      () => FakeAuthRemoteDataSource(getIt<SecureStorage>()),
    );
    getIt.registerLazySingleton<AuthLocalDataSource>(
      FakeAuthLocalDataSource.new,
    );
    getIt.registerLazySingleton<HomeRemoteDataSource>(
      FakeHomeRemoteDataSource.new,
    );
    getIt.registerLazySingleton<ProfileRemoteDataSource>(
      () => FakeProfileRemoteDataSource(getIt<AuthRepository>()),
    );
    // Firebase-backed by default (see [AnalyticsServiceImpl] /
    // [CrashReportingServiceImpl]); dev never calls Firebase per the
    // firebase-integration spec, so no-op fakes take over here.
    getIt.registerLazySingleton<AnalyticsService>(FakeAnalyticsService.new);
    getIt.registerLazySingleton<CrashReportingService>(
      FakeCrashReportingService.new,
    );
    getIt.registerLazySingleton<NotificationService>(
      FakeNotificationService.new,
    );
    getIt.registerLazySingleton<AvatarUploadService>(
      FakeAvatarUploadService.new,
    );
  } finally {
    getIt.allowReassignment = previousAllowReassignment;
  }
}

/// Wires the real Firestore-backed remotes and connectivity in stg/prod,
/// replacing question_bank's default fakes (see [QuestionBankModule]).
void _registerStgProdOverrides() {
  final previousAllowReassignment = getIt.allowReassignment;
  getIt.allowReassignment = true;
  try {
    getIt.registerLazySingleton<ProgressRemoteDataSource>(
      FirestoreProgressDataSource.new,
    );
    getIt.registerLazySingleton<FlaggedRemoteDataSource>(
      FirestoreFlaggedDataSource.new,
    );
    getIt.registerLazySingleton<StatsRemoteDataSource>(
      FirestoreStatsDataSource.new,
    );
    getIt.registerLazySingleton<ConnectivityProvider>(
      () => ConnectivityProviderAdapter(getIt<ConnectivityService>()),
    );
    getIt.registerLazySingleton<AccountMergeService>(
      () => RealAccountMergeService(
        getIt<AuthRepository>(),
        getIt<ProgressRepository>(),
        getIt<GetRawLocalStatsUseCase>(),
        getIt<SetRawLocalStatsUseCase>(),
        FirestoreProgressReader(),
      ),
    );
  } finally {
    getIt.allowReassignment = previousAllowReassignment;
  }
}
