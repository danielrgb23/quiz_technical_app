import 'package:auth_module/auth_module.dart';
import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../dtos/profile_dto.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileDto> getProfile();
  Future<ProfileDto> updateProfile(ProfileDto profile);
}

/// There's no separate profile backend — the profile IS the signed-in
/// Firebase user (name/email/avatar), plus a couple of extras (phone,
/// bio) that Firebase Auth doesn't carry, kept locally. This replaced a
/// `/profile` REST call that never had a real backend behind it.
@LazySingleton(as: ProfileRemoteDataSource)
class AuthBackedProfileDataSource implements ProfileRemoteDataSource {
  AuthBackedProfileDataSource(this._authRepository, this._secureStorage);

  static const _phoneKey = 'profile_phone';
  static const _bioKey = 'profile_bio';

  final AuthRepository _authRepository;
  final SecureStorage _secureStorage;

  @override
  Future<ProfileDto> getProfile() async {
    final result = await _authRepository.getCurrentUser();
    final user = result.dataOrNull;
    final phone = await _secureStorage.read(_phoneKey);
    final bio = await _secureStorage.read(_bioKey);
    return ProfileDto(
      id: user?.id ?? '',
      name: user?.name ?? '',
      email: user?.email ?? '',
      phone: phone,
      avatarUrl: user?.avatarUrl,
      bio: bio,
    );
  }

  @override
  Future<ProfileDto> updateProfile(ProfileDto profile) async {
    if (profile.phone != null) {
      await _secureStorage.write(_phoneKey, profile.phone!);
    }
    if (profile.bio != null) {
      await _secureStorage.write(_bioKey, profile.bio!);
    }
    return getProfile();
  }
}
