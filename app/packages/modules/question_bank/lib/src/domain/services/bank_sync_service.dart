/// Resultado de uma tentativa de sincronização do banco de questões.
enum BankSyncResult {
  /// Banco local já está na última versão.
  upToDate,

  /// Nova versão baixada, validada (checksum) e importada.
  updated,

  /// Checksum do download não bateu com o manifest — import abortado.
  checksumMismatch,

  /// Falha de rede/config — banco atual mantido.
  failed,
}

abstract class BankSyncService {
  /// Garante o banco embarcado importado no primeiro launch (offline).
  Future<void> ensureSeeded();

  /// Compara versão local com a remota e importa se houver versão nova.
  Future<BankSyncResult> syncIfNeeded();
}
