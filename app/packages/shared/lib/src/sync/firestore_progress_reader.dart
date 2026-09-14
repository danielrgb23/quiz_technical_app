import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:question_bank_module/question_bank.dart';

/// Snapshot completo do progresso remoto de uma conta — usado só no
/// momento de mesclar uma sessão anônima numa conta já existente (ver
/// AccountMergeService em quiz_app). Não é usado no sync do dia a dia
/// (isso já roda por [ProgressRemoteDataSource]/[StatsRemoteDataSource]).
class RemoteProgressSnapshot {
  const RemoteProgressSnapshot({
    required this.perQuestion,
    required this.xpTotal,
    required this.streakDays,
    this.streakLastCompletedAt,
  });

  final List<QuestionProgress> perQuestion;
  final int xpTotal;
  final int streakDays;
  final DateTime? streakLastCompletedAt;
}

class FirestoreProgressReader {
  FirestoreProgressReader() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<RemoteProgressSnapshot> fetchAll(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('progress')
        .get();

    final perQuestion = <QuestionProgress>[];
    var xpTotal = 0;
    var streakDays = 0;
    DateTime? streakLastCompletedAt;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (doc.id == statsSyncPlaceholderId) {
        xpTotal = data['xpTotal'] as int? ?? 0;
        streakDays = data['streakDays'] as int? ?? 0;
        final raw = data['streakLastCompletedAt'] as String?;
        streakLastCompletedAt = raw != null ? DateTime.parse(raw) : null;
        continue;
      }
      perQuestion.add(
        QuestionProgress(
          questionId: doc.id,
          correctCount: data['correctCount'] as int? ?? 0,
          wrongCount: data['wrongCount'] as int? ?? 0,
          consecutiveCorrect: data['consecutiveCorrect'] as int? ?? 0,
          lastSeenAt: data['lastSeenAt'] != null
              ? DateTime.parse(data['lastSeenAt'] as String)
              : null,
          nextReviewAt: data['nextReviewAt'] != null
              ? DateTime.parse(data['nextReviewAt'] as String)
              : null,
        ),
      );
    }

    return RemoteProgressSnapshot(
      perQuestion: perQuestion,
      xpTotal: xpTotal,
      streakDays: streakDays,
      streakLastCompletedAt: streakLastCompletedAt,
    );
  }
}
