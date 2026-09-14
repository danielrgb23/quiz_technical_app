abstract class Failure {
  const Failure({required this.message, this.stackTrace});

  final String message;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.stackTrace,
    this.statusCode,
  });

  final int? statusCode;
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.stackTrace});
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection',
    super.stackTrace,
  });
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'An unexpected error occurred',
    super.stackTrace,
  });
}

/// Linking an anonymous session to an email/password credential that
/// already belongs to a different account (Firebase
/// `credential-already-in-use` / `email-already-in-use`). Callers should
/// treat this as a signal to sign in to that existing account and merge
/// progress, not as a generic error.
class AccountExistsFailure extends Failure {
  const AccountExistsFailure({
    required this.email,
    required this.credential,
    super.message = 'An account already exists for this email',
    super.stackTrace,
  });

  final String email;

  /// Opaque credential to finish signing into the existing account with
  /// (implementation-specific; auth module casts it back internally).
  final Object credential;
}
