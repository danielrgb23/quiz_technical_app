import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../entities/user.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class RegisterUseCase implements UseCase<RegisterParams, User> {
  RegisterUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<User>> call(RegisterParams params) => _repository.register(
    email: params.email,
    password: params.password,
    name: params.name,
  );
}

class RegisterParams {
  const RegisterParams({
    required this.email,
    required this.password,
    required this.name,
  });

  final String email;
  final String password;
  final String name;
}
