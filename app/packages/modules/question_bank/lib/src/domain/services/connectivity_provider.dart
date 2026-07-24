import 'dart:async';

/// Abstração mínima de conectividade para o módulo (sem depender de `shared`).
///
/// O app registra um adapter sobre o ConnectivityService de `packages/shared`
/// nos ambientes stg/prod.
abstract class ConnectivityProvider {
  Future<bool> get isOnline;
  Stream<bool> get onStatusChanged;
}

/// Provider fixo — default seguro (offline) enquanto o app não registra o
/// adapter real; também usado em testes.
class StaticConnectivityProvider implements ConnectivityProvider {
  StaticConnectivityProvider({required bool online}) : _online = online;

  StaticConnectivityProvider.offline() : this(online: false);

  bool _online;
  final _controller = StreamController<bool>.broadcast();

  set online(bool value) {
    _online = value;
    _controller.add(value);
  }

  @override
  Future<bool> get isOnline async => _online;

  @override
  Stream<bool> get onStatusChanged => _controller.stream;
}
