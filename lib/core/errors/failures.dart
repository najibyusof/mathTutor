import 'exceptions.dart';

/// Domain-level representation of an error.
///
/// Repositories translate [AppException]s into [Failure]s so the presentation
/// layer never depends on transport details.
sealed class Failure {
  const Failure(this.message, {this.code});

  final String message;
  final int? code;

  @override
  String toString() => '$runtimeType($code): $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message, {super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure(
    super.message, {
    super.code,
    this.fieldErrors = const <String, List<String>>{},
  });

  final Map<String, List<String>> fieldErrors;
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code});
}

class DeviceUnavailableFailure extends Failure {
  const DeviceUnavailableFailure(super.message, {super.code});
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.code});
}

/// Maps a data-layer [AppException] onto its domain [Failure].
Failure mapExceptionToFailure(Object error) {
  return switch (error) {
    NetworkException(:final String message) => NetworkFailure(message),
    ServerException(:final String message, :final int? statusCode) =>
      ServerFailure(message, code: statusCode),
    UnauthorizedException(:final String message, :final int? statusCode) =>
      UnauthorizedFailure(message, code: statusCode),
    ValidationException(
      :final String message,
      :final int? statusCode,
      :final Map<String, List<String>> fieldErrors,
    ) =>
      ValidationFailure(message, code: statusCode, fieldErrors: fieldErrors),
    CacheException(:final String message) => CacheFailure(message),
    PermissionDeniedException(:final String message) =>
      PermissionFailure(message),
    DeviceUnavailableException(:final String message) =>
      DeviceUnavailableFailure(message),
    InvalidImageException(:final String message) => ValidationFailure(message),
    ParsingException(:final String message) => UnexpectedFailure(message),
    _ => UnexpectedFailure(error.toString()),
  };
}
