import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:question_bank_module/question_bank.dart';

/// Espelho remoto real de XP/streak — `users/{uid}/progress/_stats` (mesma
/// subcoleção prevista no firebase-integration spec, stg/prod only).
class FirestoreStatsDataSource implements StatsRemoteDataSource {
  FirestoreStatsDataSource()
    : _firestore = FirebaseFirestore.instance,
      _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<void> upsert({
    required int xpTotal,
    required int streakDays,
    DateTime? streakLastCompletedAt,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('No signed-in user to sync stats to');
    }
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc(statsSyncPlaceholderId)
        .set({
          'xpTotal': xpTotal,
          'streakDays': streakDays,
          'streakLastCompletedAt': streakLastCompletedAt?.toIso8601String(),
        }, SetOptions(merge: true));
  }
}
