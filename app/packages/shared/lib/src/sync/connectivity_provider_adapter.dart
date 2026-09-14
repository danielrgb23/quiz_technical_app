import 'package:question_bank_module/question_bank.dart';

import '../connectivity/connectivity_service.dart';

/// Adapts `shared`'s [ConnectivityService] (real `connectivity_plus`) to
/// question_bank's [ConnectivityProvider] abstraction, so
/// [ProgressSyncQueue] can react to real connectivity in stg/prod.
class ConnectivityProviderAdapter implements ConnectivityProvider {
  ConnectivityProviderAdapter(this._connectivityService);

  final ConnectivityService _connectivityService;

  @override
  Future<bool> get isOnline => _connectivityService.isConnected;

  @override
  Stream<bool> get onStatusChanged =>
      _connectivityService.onConnectivityChanged;
}
