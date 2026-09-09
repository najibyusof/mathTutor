/// Low-level errors thrown by the data layer (network, cache, parsing).
sealed class AppException implements Exception {
  const AppException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// The device could not reach the API at all.
class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// The API responded with a 5xx status.
class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode});
}

/// The API responded with 401/403.
class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, {super.statusCode});
}

/// The API responded with 422 and per-field validation errors.
class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    super.statusCode,
    this.fieldErrors = const <String, List<String>>{},
  });

  final Map<String, List<String>> fieldErrors;
}

/// The response body could not be decoded into the expected shape.
class ParsingException extends AppException {
  const ParsingException(super.message);
}

/// Local storage read/write failure.
class CacheException extends AppException {
  const CacheException(super.message);
}
