import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Called when the user submits login credentials while a guest
/// (anonymous) session is active — i.e. they already have an account and
/// want in, instead of creating a new one. Implementations sign in and,
/// if there's local progress worth preserving, merge it into the account
/// being signed into.
///
/// `auth_module` can't see quiz/question_bank progress data, so
/// [DefaultAccountMergeService] just logs in with no merge; `quiz_app`
/// registers a real merge-capable implementation for stg/prod at
/// bootstrap (dev has no real accounts to merge into anyway).
abstract class AccountMergeService {
  Future<Result<User>> loginAndMerge({
    required String email,
    required String password,
  });

  /// Same idea as [loginAndMerge], for the Google sign-in path: the
  /// credential is already in hand (from [AccountExistsFailure]), so this
  /// just finishes signing in and merges — no re-auth needed.
  Future<Result<User>> completeMerge(AccountExistsFailure failure);
}

@LazySingleton(as: AccountMergeService)
class DefaultAccountMergeService implements AccountMergeService {
  DefaultAccountMergeService(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<User>> loginAndMerge({
    required String email,
    required String password,
  }) => _repository.login(email: email, password: password);

  @override
  Future<Result<User>> completeMerge(AccountExistsFailure failure) =>
      _repository.signInWithFailedCredential(failure);
}
