import 'package:auth_module/auth_module.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'login_cubit.freezed.dart';

@freezed
abstract class LoginState with _$LoginState {
  const factory LoginState.initial() = LoginInitial;
  const factory LoginState.loading() = LoginLoading;
  const factory LoginState.success(User user) = LoginSuccess;
  const factory LoginState.failure(String message) = LoginFailure;
}

@injectable
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(
    this._loginUseCase,
    this._loginAnonymouslyUseCase,
    this._loginWithGoogleUseCase,
    this._mergeService,
    this._authRepository,
  ) : super(const LoginState.initial());

  final LoginUseCase _loginUseCase;
  final LoginAnonymouslyUseCase _loginAnonymouslyUseCase;
  final LoginWithGoogleUseCase _loginWithGoogleUseCase;
  final AccountMergeService _mergeService;
  final AuthRepository _authRepository;

  Future<void> login({required String email, required String password}) async {
    emit(const LoginState.loading());

    // Guest session active → this is "log into an existing account", so
    // merge local (anonymous) progress into it instead of a plain login.
    final result = _authRepository.isCurrentUserAnonymous
        ? await _mergeService.loginAndMerge(email: email, password: password)
        : await _loginUseCase(LoginParams(email: email, password: password));

    result.when(
      success: (user) => emit(LoginState.success(user)),
      failure: (failure) => emit(LoginState.failure(failure.message)),
    );
  }

  Future<void> continueAsGuest() async {
    emit(const LoginState.loading());

    final result = await _loginAnonymouslyUseCase();

    result.when(
      success: (user) => emit(LoginState.success(user)),
      failure: (failure) => emit(LoginState.failure(failure.message)),
    );
  }

  Future<void> loginWithGoogle() async {
    emit(const LoginState.loading());

    final result = await _loginWithGoogleUseCase();
    // Google account already belongs to a different existing user — we
    // already have a full credential in hand, so finish signing into
    // that account (and merge) right away, no extra screen needed.
    final finalResult = result.failureOrNull is AccountExistsFailure
        ? await _mergeService.completeMerge(
            result.failureOrNull! as AccountExistsFailure,
          )
        : result;

    finalResult.when(
      success: (user) => emit(LoginState.success(user)),
      failure: (failure) => emit(LoginState.failure(failure.message)),
    );
  }
}
