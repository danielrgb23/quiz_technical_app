import 'dart:convert';

import 'package:core/core.dart';
import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/question.dart';
import '../../domain/services/bank_sync_service.dart';
import '../data_sources/bank_asset_data_source.dart';
import '../data_sources/bank_remote_data_source.dart';
import '../db/question_bank_db.dart';

@LazySingleton(as: BankSyncService)
class BankSyncServiceImpl implements BankSyncService {
  BankSyncServiceImpl(this._db, this._asset, this._remote, this._remoteConfig);

  final QuestionBankDb _db;
  final BankAssetDataSource _asset;
  final BankRemoteDataSource _remote;
  final RemoteConfigService _remoteConfig;

  @override
  Future<void> ensureSeeded() async {
    final manifest = await _asset.loadManifest();
    final localVersion = await _db.bankVersion();
    if (localVersion >= manifest.version) return;
    final questions = await _asset.loadQuestions();
    await _db.importBank(questions, manifest.version);
    AppLogger.info(
      'banco embarcado importado: v${manifest.version} '
      '(${questions.length} questões)',
      tag: 'BankSync',
    );
  }

  @override
  Future<BankSyncResult> syncIfNeeded() async {
    try {
      final localVersion = await _db.bankVersion();
      final latestVersion = await _remoteConfig.latestBankVersion();
      if (latestVersion <= localVersion) return BankSyncResult.upToDate;

      final manifest = await _remote.fetchManifest(latestVersion);
      final bytes = await _remote.downloadBankBytes(latestVersion);

      final checksum = sha256.convert(bytes).toString();
      if (checksum != manifest.checksum) {
        AppLogger.error(
          'checksum inválido para banco v$latestVersion '
          '(esperado ${manifest.checksum}, obtido $checksum) — import abortado',
          tag: 'BankSync',
        );
        return BankSyncResult.checksumMismatch;
      }

      final list = jsonDecode(utf8.decode(bytes)) as List;
      final questions = [
        for (final item in list)
          Question.fromJson(item as Map<String, dynamic>),
      ];
      await _db.importBank(questions, manifest.version);
      AppLogger.info(
        'banco atualizado para v${manifest.version} '
        '(${questions.length} questões)',
        tag: 'BankSync',
      );
      return BankSyncResult.updated;
    } catch (e, s) {
      AppLogger.error(
        'sync do banco falhou — mantendo versão local',
        tag: 'BankSync',
        error: e,
        stackTrace: s,
      );
      return BankSyncResult.failed;
    }
  }
}
