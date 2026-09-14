import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:question_bank_module/question_bank.dart';

/// Espelho remoto real do progresso — `users/{uid}/progress/{questionId}`
/// (stg/prod only; ver firebase-integration spec e AuthGuard).
class FirestoreProgressDataSource implements ProgressRemoteDataSource {
  FirestoreProgressDataSource()
    : _firestore = FirebaseFirestore.instance,
      _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<void> upsert(QuestionProgress progress) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      // No real Firebase session yet (still-offline guest, see
      // AuthRepository.loginAnonymously). Throw so ProgressSyncQueue keeps
      // this item queued instead of dropping it — it retries automatically
      // once retryPendingGuestLogin() lands a real uid.
      throw StateError('No signed-in user to sync progress to');
    }
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc(progress.questionId)
        .set(progress.toJson(), SetOptions(merge: true));
  }
}
