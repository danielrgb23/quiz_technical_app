import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';

/// Uploads a locally-picked image as the user's avatar and returns a
/// public URL. That URL becomes the single source of truth for the
/// avatar via `AuthRepository.updateAvatarUrl` — same field Google
/// sign-in already populates natively.
abstract class AvatarUploadService {
  Future<String> upload({required String uid, required File file});
}

@LazySingleton(as: AvatarUploadService)
class FirebaseAvatarUploadService implements AvatarUploadService {
  FirebaseAvatarUploadService() : _storage = FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<String> upload({required String uid, required File file}) async {
    final ref = _storage.ref('avatars/$uid.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}

/// Dev fake: skips the real upload and just hands back the local file
/// path — `Image.file` renders it directly, no network needed.
class FakeAvatarUploadService implements AvatarUploadService {
  @override
  Future<String> upload({required String uid, required File file}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return file.path;
  }
}
