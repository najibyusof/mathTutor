import 'failures.dart';

/// Maps a [Failure] onto a short, non-technical message for the UI.
String friendlyMessage(Failure failure) {
  return switch (failure) {
    NetworkFailure() =>
      'No internet connection. Check your network and try again.',
    UnauthorizedFailure(:final String message) => message.isEmpty
        ? 'Your session has expired. Please sign in again.'
        : message,
    ValidationFailure(:final String message, :final Map<String, List<String>> fieldErrors) =>
      fieldErrors.values.expand((List<String> e) => e).firstOrNull ??
          (message.isEmpty ? 'Please check the highlighted fields.' : message),
    ServerFailure() => 'The server is not responding. Please try again later.',
    CacheFailure() => 'Could not read saved data on this device.',
    PermissionFailure(:final String message) => message.isEmpty
        ? 'Permission is needed to continue. You can enable it in Settings.'
        : message,
    DeviceUnavailableFailure(:final String message) => message.isEmpty
        ? 'That is not available on this device.'
        : message,
    UnexpectedFailure() => 'Something went wrong. Please try again.',
  };
}
