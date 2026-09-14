import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/user.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

@freezed
abstract class UserDto with _$UserDto {
  const UserDto._();

  const factory UserDto({
    required String id,
    required String email,
    required String name,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'is_email_verified') @Default(false) bool isEmailVerified,
    @JsonKey(name: 'is_anonymous') @Default(false) bool isAnonymous,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  factory UserDto.fromEntity(User user) => UserDto(
    id: user.id,
    email: user.email,
    name: user.name,
    avatarUrl: user.avatarUrl,
    isEmailVerified: user.isEmailVerified,
    isAnonymous: user.isAnonymous,
  );

  User toEntity() => User(
    id: id,
    email: email,
    name: name,
    avatarUrl: avatarUrl,
    isEmailVerified: isEmailVerified,
    isAnonymous: isAnonymous,
  );
}
