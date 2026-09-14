import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../entities/user.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class LinkWithEmailPasswordUseCase
    implements UseCase<LinkWithEmailPasswordParams, User> {
  LinkWithEmailPasswordUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<User>> call(LinkWithEmailPasswordParams params) =>
      _repository.linkWithEmailPassword(
        email: params.email,
        password: params.password,
        name: params.name,
      );
}

class LinkWithEmailPasswordParams {
  const LinkWithEmailPasswordParams({
    required this.email,
    required this.password,
    required this.name,
  });

  final String email;
  final String password;
  final String name;
}
