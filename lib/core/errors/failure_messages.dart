import 'failures.dart';

/// Maps a [Failure] onto a short, non-technical message for the UI.
String friendlyMessage(Failure failure) {
  return switch (failure) {
    NetworkFailure() =>
      'Unable to connect to the server. Please check your internet connection and try again.',
    UnauthorizedFailure(:final String message) =>
      message.isEmpty
          ? 'Your session has expired. Please sign in again.'
          : message,
    ValidationFailure(
      :final String message,
      :final Map<String, List<String>> fieldErrors,
    ) =>
      fieldErrors.values.expand((List<String> e) => e).firstOrNull ??
          (message.isEmpty ? 'Please check the highlighted fields.' : message),
    ServerFailure() =>
      'The server is unavailable right now. Please try again later.',
    NotFoundFailure(:final String message) =>
      message.isEmpty
          ? 'We could not find what you were looking for.'
          : message,
    CacheFailure() => 'Could not read saved data on this device.',
    PermissionFailure(:final String message) =>
      message.isEmpty
          ? 'Permission is needed to continue. You can enable it in Settings.'
          : message,
    DeviceUnavailableFailure(:final String message) =>
      message.isEmpty ? 'That is not available on this device.' : message,
    MathParserFailure() =>
      'We couldn\'t understand this equation. Please check the expression and try again.',
    MathSolverFailure(:final String message) =>
      message.isEmpty
          ? 'We could not solve this problem yet. Please try another expression.'
          : message,
    SolutionValidationFailure(:final String message) => message,
    AIExplanationFailure() =>
      'The explanation service is unavailable. Please try again.',
    AIResponseFailure() =>
      'The explanation response was invalid. Please try again.',
    UnexpectedFailure() => 'Something went wrong. Please try again.',
  };
}
