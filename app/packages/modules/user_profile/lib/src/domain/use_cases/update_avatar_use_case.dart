import 'dart:io';

import 'package:auth_module/auth_module.dart';
import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../../data/data_sources/avatar_upload_service.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

@lazySingleton
class UpdateAvatarUseCase implements UseCase<File, Profile> {
  UpdateAvatarUseCase(
    this._uploadService,
    this._authRepository,
    this._profileRepository,
  );

  final AvatarUploadService _uploadService;
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;

  @override
  Future<Result<Profile>> call(File file) async {
    final uid = _authRepository.currentUid;
    if (uid == null) {
      return Result.failure(
        const UnexpectedFailure(message: 'No signed-in user'),
      );
    }
    try {
      final url = await _uploadService.upload(uid: uid, file: file);
      final authResult = await _authRepository.updateAvatarUrl(url);
      if (authResult.isFailure) {
        return Result.failure(authResult.failureOrNull!);
      }
      return _profileRepository.getProfile();
    } catch (e, st) {
      return Result.failure(
        UnexpectedFailure(message: e.toString(), stackTrace: st),
      );
    }
  }
}
