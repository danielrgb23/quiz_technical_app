import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../entities/user.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class LoginAnonymouslyUseCase implements UseCaseNoParams<User> {
  LoginAnonymouslyUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<User>> call() => _repository.loginAnonymously();
}
