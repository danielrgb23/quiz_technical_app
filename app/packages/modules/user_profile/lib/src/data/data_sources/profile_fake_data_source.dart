import 'package:auth_module/auth_module.dart';

import '../dtos/profile_dto.dart';
import 'profile_remote_data_source.dart';

/// Mirrors whatever dev's [AuthRepository] fake currently has signed in,
/// instead of a hardcoded persona disconnected from the actual login
/// flow — so the profile screen in dev reflects real (guest vs.
/// logged-in) state.
class FakeProfileRemoteDataSource implements ProfileRemoteDataSource {
  FakeProfileRemoteDataSource(this._authRepository);

  final AuthRepository _authRepository;
  String? _phone;
  String? _bio;

  @override
  Future<ProfileDto> getProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final result = await _authRepository.getCurrentUser();
    final user = result.dataOrNull;
    return ProfileDto(
      id: user?.id ?? '',
      name: user?.name ?? '',
      email: user?.email ?? '',
      phone: _phone,
      avatarUrl: user?.avatarUrl,
      bio: _bio,
    );
  }

  @override
  Future<ProfileDto> updateProfile(ProfileDto profile) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _phone = profile.phone;
    _bio = profile.bio;
    return getProfile();
  }
}
