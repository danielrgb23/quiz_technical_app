import 'package:auth_module/auth_module.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'register_cubit.freezed.dart';

@freezed
abstract class RegisterState with _$RegisterState {
  const factory RegisterState.initial() = RegisterInitial;
  const factory RegisterState.loading() = RegisterLoading;
  const factory RegisterState.success(User user) = RegisterSuccess;
  const factory RegisterState.accountExists(String email) =
      RegisterAccountExists;
  const factory RegisterState.failure(String message) = RegisterFailure;
}

@injectable
class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit(this._registerUseCase, this._linkUseCase)
    : super(const RegisterState.initial());

  final RegisterUseCase _registerUseCase;
  final LinkWithEmailPasswordUseCase _linkUseCase;

  /// Whether there's an anonymous session to upgrade (guest → account) —
  /// callers pass this in from [AuthRepository.getCurrentUser] so the
  /// cubit doesn't need its own reference to the repository just for that.
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required bool isGuestUpgrade,
  }) async {
    emit(const RegisterState.loading());

    final result = isGuestUpgrade
        ? await _linkUseCase(
            LinkWithEmailPasswordParams(
              email: email,
              password: password,
              name: name,
            ),
          )
        : await _registerUseCase(
            RegisterParams(email: email, password: password, name: name),
          );

    result.when(
      success: (user) => emit(RegisterState.success(user)),
      failure: (failure) {
        if (failure is AccountExistsFailure) {
          emit(RegisterState.accountExists(failure.email));
        } else {
          emit(RegisterState.failure(failure.message));
        }
      },
    );
  }
}
