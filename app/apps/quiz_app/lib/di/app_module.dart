import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

/// App-specific overrides and additional bindings.
@module
abstract class AppModule {
  /// Config remota: fake com valores fixos até o Firebase Remote Config
  /// entrar em stg/prod (Spec 02, trabalho 4).
  @lazySingleton
  RemoteConfigService get remoteConfigService =>
      const FakeRemoteConfigService(fakeLatestBankVersion: 1);
}
