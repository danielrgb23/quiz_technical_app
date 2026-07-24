import 'dart:async';
import 'dart:convert';

import 'package:core/core.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/question_progress.dart';
import '../../domain/services/connectivity_provider.dart';
import '../data_sources/flagged_remote_data_source.dart';
import '../data_sources/progress_remote_data_source.dart';
import '../db/question_bank_db.dart';

/// Drena a fila `pending_sync` para os espelhos remotos quando há rede.
///
/// A UI nunca espera por esta fila: escritas locais acontecem primeiro
/// (ProgressRepository/QuestionReportRepository) e o sync roda em
/// background com retry. Cada item tem um `type` ('progress' ou 'flagged')
/// que determina qual remoto recebe o payload (design.md decisão 7).
@lazySingleton
class ProgressSyncQueue {
  ProgressSyncQueue(
    this._db,
    this._progressRemote,
    this._flaggedRemote,
    this._connectivity,
  );

  final QuestionBankDb _db;
  final ProgressRemoteDataSource _progressRemote;
  final FlaggedRemoteDataSource _flaggedRemote;
  final ConnectivityProvider _connectivity;

  StreamSubscription<bool>? _subscription;
  bool _draining = false;

  /// Começa a observar conectividade e tenta drenar imediatamente.
  void start() {
    _subscription ??= _connectivity.onStatusChanged.listen((online) {
      if (online) unawaited(drain());
    });
    unawaited(drain());
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Envia itens pendentes em ordem; para no primeiro erro (retry depois).
  /// Retorna quantos itens foram sincronizados.
  Future<int> drain() async {
    if (_draining) return 0;
    if (!await _connectivity.isOnline) return 0;
    _draining = true;
    var synced = 0;
    try {
      final items = await (_db.select(
        _db.pendingSync,
      )..orderBy([(p) => OrderingTerm.asc(p.id)])).get();
      for (final item in items) {
        try {
          await _syncOne(item);
          await (_db.delete(
            _db.pendingSync,
          )..where((p) => p.id.equals(item.id))).go();
          synced++;
        } catch (e) {
          AppLogger.warning(
            'sync falhou (item ${item.id}, type ${item.type}) — '
            'retry depois: $e',
            tag: 'ProgressSync',
          );
          break;
        }
      }
    } finally {
      _draining = false;
    }
    return synced;
  }

  Future<void> _syncOne(PendingSyncData item) async {
    final json = jsonDecode(item.payloadJson) as Map<String, dynamic>;
    if (item.type == 'flagged') {
      await _flaggedRemote.reportFlag(json['questionId'] as String);
      return;
    }
    await _progressRemote.upsert(
      QuestionProgress(
        questionId: json['questionId'] as String,
        correctCount: json['correctCount'] as int? ?? 0,
        wrongCount: json['wrongCount'] as int? ?? 0,
        consecutiveCorrect: json['consecutiveCorrect'] as int? ?? 0,
        lastSeenAt: json['lastSeenAt'] != null
            ? DateTime.parse(json['lastSeenAt'] as String)
            : null,
        nextReviewAt: json['nextReviewAt'] != null
            ? DateTime.parse(json['nextReviewAt'] as String)
            : null,
      ),
    );
  }
}
