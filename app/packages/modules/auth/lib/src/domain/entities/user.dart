import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

/// Placeholder id used by [User] when guest mode starts offline, before a
/// real Firebase anonymous uid can be obtained.
const localGuestId = 'local-guest';

@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String name,
    String? avatarUrl,
    @Default(false) bool isEmailVerified,
    @Default(false) bool isAnonymous,
  }) = _User;
}
