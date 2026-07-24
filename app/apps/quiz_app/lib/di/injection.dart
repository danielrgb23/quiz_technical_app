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
import 'package:shared/shared.dart';
import 'package:user_profile_module/user_profile_module.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  externalPackageModulesBefore: [
    ExternalModule(CorePackageModule),
    ExternalModule(SharedPackageModule),
    ExternalModule(AuthModulePackageModule),
    ExternalModule(HomeModulePackageModule),
    ExternalModule(QuestionBankModulePackageModule),
    ExternalModule(UserProfileModulePackageModule),
    ExternalModule(AuthFlowPackageModule),
    ExternalModule(HomeFlowPackageModule),
    ExternalModule(OnboardingPackageModule),
    ExternalModule(ProfileFlowPackageModule),
  ],
)
Future<void> configureDependencies(String environment) async {
  await getIt.init(environment: environment);

  if (environment == 'dev') {
    _registerDevOverrides();
  }
}

/// Prepara os dados offline-first: banco embarcado no primeiro launch,
/// sync de versão do banco e fila de progresso (nunca bloqueia a UI).
Future<void> bootstrapQuestionBank() async {
  final bankSync = getIt<BankSyncService>();
  await bankSync.ensureSeeded();
  unawaited(bankSync.syncIfNeeded());
  getIt<ProgressSyncQueue>().start();
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
      FakeAuthRemoteDataSource.new,
    );
    getIt.registerLazySingleton<AuthLocalDataSource>(
      FakeAuthLocalDataSource.new,
    );
    getIt.registerLazySingleton<HomeRemoteDataSource>(
      FakeHomeRemoteDataSource.new,
    );
    getIt.registerLazySingleton<ProfileRemoteDataSource>(
      FakeProfileRemoteDataSource.new,
    );
  } finally {
    getIt.allowReassignment = previousAllowReassignment;
  }
}
