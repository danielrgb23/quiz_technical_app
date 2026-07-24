import 'dart:convert';

import 'package:core/core.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:question_bank_module/question_bank.dart';

Map<String, dynamic> questionJson(String id, {String topic = 'flutter'}) => {
  'id': id,
  'source': 'test',
  'topic': topic,
  'level': 1,
  'question': 'Pergunta $id?',
  'options': ['A', 'B', 'C', 'D', 'E'],
  'correctIndex': 0,
  'explanation': 'Porque sim, com detalhes suficientes.',
  'tags': ['t'],
  'language': 'pt-BR',
  'generated_answer': false,
};

class StubBankRemote implements BankRemoteDataSource {
  StubBankRemote({required this.manifest, required this.bytes});

  BankManifest manifest;
  List<int> bytes;

  @override
  Future<BankManifest> fetchManifest(int version) async => manifest;

  @override
  Future<List<int>> downloadBankBytes(int version) async => bytes;
}

void main() {
  late QuestionBankDb db;

  setUp(() {
    db = QuestionBankDb(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  BankAssetDataSource assetSource({int version = 1, int count = 2}) {
    final questions = [for (var i = 0; i < count; i++) questionJson('q$i')];
    return BankAssetDataSource(
      loadString: (path) async => path.endsWith('manifest.json')
          ? jsonEncode({'version': version, 'count': count, 'checksum': 'x'})
          : jsonEncode(questions),
    );
  }

  group('ensureSeeded', () {
    test('importa banco do asset no primeiro launch', () async {
      final sync = BankSyncServiceImpl(
        db,
        assetSource(),
        FakeBankRemoteDataSource(),
        const FakeRemoteConfigService(),
      );

      await sync.ensureSeeded();

      expect(await db.bankVersion(), 1);
      final repo = QuestionRepositoryImpl(db);
      final all = await repo.getAll();
      expect(all.dataOrNull, hasLength(2));
    });

    test('não reimporta quando já há banco', () async {
      final sync = BankSyncServiceImpl(
        db,
        assetSource(),
        FakeBankRemoteDataSource(),
        const FakeRemoteConfigService(),
      );
      await sync.ensureSeeded();
      await db.importBank([Question.fromJson(questionJson('other'))], 5);

      await sync.ensureSeeded();

      expect(await db.bankVersion(), 5);
    });
  });

  group('syncIfNeeded', () {
    test('atualiza quando há versão nova com checksum válido', () async {
      final newQuestions = [
        questionJson('n1'),
        questionJson('n2'),
        questionJson('n3'),
      ];
      final bytes = utf8.encode(jsonEncode(newQuestions));
      final checksum = sha256.convert(bytes).toString();
      final sync = BankSyncServiceImpl(
        db,
        assetSource(),
        StubBankRemote(
          manifest: BankManifest(version: 2, count: 3, checksum: checksum),
          bytes: bytes,
        ),
        const FakeRemoteConfigService(fakeLatestBankVersion: 2),
      );
      await sync.ensureSeeded();

      final result = await sync.syncIfNeeded();

      expect(result, BankSyncResult.updated);
      expect(await db.bankVersion(), 2);
      final all = await QuestionRepositoryImpl(db).getAll();
      expect(all.dataOrNull, hasLength(3));
    });

    test('checksum inválido aborta e mantém banco atual', () async {
      final bytes = utf8.encode(jsonEncode([questionJson('n1')]));
      final sync = BankSyncServiceImpl(
        db,
        assetSource(),
        StubBankRemote(
          manifest: const BankManifest(
            version: 2,
            count: 1,
            checksum: 'errado',
          ),
          bytes: bytes,
        ),
        const FakeRemoteConfigService(fakeLatestBankVersion: 2),
      );
      await sync.ensureSeeded();

      final result = await sync.syncIfNeeded();

      expect(result, BankSyncResult.checksumMismatch);
      expect(await db.bankVersion(), 1);
      final all = await QuestionRepositoryImpl(db).getAll();
      expect(all.dataOrNull, hasLength(2));
    });

    test('sem versão nova retorna upToDate sem tocar o banco', () async {
      final sync = BankSyncServiceImpl(
        db,
        assetSource(),
        FakeBankRemoteDataSource(),
        const FakeRemoteConfigService(fakeLatestBankVersion: 1),
      );
      await sync.ensureSeeded();

      expect(await sync.syncIfNeeded(), BankSyncResult.upToDate);
      expect(await db.bankVersion(), 1);
    });
  });

  group('progresso e fila de sync', () {
    test('save grava local e enfileira; drain offline não envia', () async {
      final repo = ProgressRepositoryImpl(db);
      final remote = FakeProgressRemoteDataSource();
      final connectivity = StaticConnectivityProvider(online: false);
      final queue = ProgressSyncQueue(db, remote, connectivity);

      await repo.save(
        QuestionProgress(
          questionId: 'q1',
          correctCount: 1,
          lastSeenAt: DateTime.now(),
        ),
      );

      expect(await queue.drain(), 0);
      expect(remote.received, isEmpty);
      final local = await repo.getByQuestionId('q1');
      expect(local.dataOrNull?.correctCount, 1);
    });

    test('drain envia a fila quando online e a esvazia', () async {
      final repo = ProgressRepositoryImpl(db);
      final remote = FakeProgressRemoteDataSource();
      final connectivity = StaticConnectivityProvider(online: true);
      final queue = ProgressSyncQueue(db, remote, connectivity);

      await repo.save(
        const QuestionProgress(questionId: 'q1', correctCount: 1),
      );
      await repo.save(const QuestionProgress(questionId: 'q2', wrongCount: 2));

      expect(await queue.drain(), 2);
      expect(remote.received.map((p) => p.questionId), ['q1', 'q2']);
      expect(await queue.drain(), 0); // fila vazia
    });

    test('getDueForReview retorna apenas vencidas', () async {
      final repo = ProgressRepositoryImpl(db);
      final now = DateTime.now();
      await repo.save(
        QuestionProgress(
          questionId: 'due',
          nextReviewAt: now.subtract(const Duration(days: 1)),
        ),
      );
      await repo.save(
        QuestionProgress(
          questionId: 'future',
          nextReviewAt: now.add(const Duration(days: 3)),
        ),
      );

      final due = await repo.getDueForReview(now);

      expect(due.dataOrNull?.map((p) => p.questionId), ['due']);
    });
  });
}
