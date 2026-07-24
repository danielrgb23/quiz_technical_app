import 'package:drift_flutter/drift_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../data/data_sources/bank_asset_data_source.dart';
import '../data/data_sources/bank_remote_data_source.dart';
import '../data/data_sources/progress_remote_data_source.dart';
import '../data/db/question_bank_db.dart';
import '../domain/services/connectivity_provider.dart';

@InjectableInit.microPackage(
  ignoreUnregisteredTypesInPackages: ['package:core'],
)
void initQuestionBankModulePackageModule(GetIt getIt) {}

/// Registros padrão do módulo.
///
/// As fontes remotas e a conectividade são fakes/no-op por padrão; os
/// ambientes stg/prod substituem pelas implementações reais (Firebase,
/// adapter do ConnectivityService de `shared`) na configuração do app.
@module
abstract class QuestionBankModule {
  @lazySingleton
  QuestionBankDb db() => QuestionBankDb(driftDatabase(name: 'question_bank'));

  @lazySingleton
  BankAssetDataSource assetDataSource() => BankAssetDataSource();

  @LazySingleton(as: BankRemoteDataSource)
  FakeBankRemoteDataSource fakeBankRemote() => FakeBankRemoteDataSource();

  @LazySingleton(as: ProgressRemoteDataSource)
  FakeProgressRemoteDataSource fakeProgressRemote() =>
      FakeProgressRemoteDataSource();

  @LazySingleton(as: ConnectivityProvider)
  StaticConnectivityProvider connectivity() =>
      StaticConnectivityProvider.offline();
}
