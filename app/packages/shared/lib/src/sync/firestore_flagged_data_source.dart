import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:question_bank_module/question_bank.dart';

/// Espelho remoto real de reports de questão (`flagged_questions`,
/// stg/prod only).
class FirestoreFlaggedDataSource implements FlaggedRemoteDataSource {
  FirestoreFlaggedDataSource()
    : _firestore = FirebaseFirestore.instance,
      _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<void> reportFlag(String questionId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('No signed-in user to report a flag as');
    }
    await _firestore.collection('flagged_questions').add({
      'questionId': questionId,
      'reportedBy': uid,
      'reportedAt': FieldValue.serverTimestamp(),
    });
  }
}
