import 'dart:developer' as developer;

import '../config/app_config.dart';

/// Thin logging facade so logging can be redirected later without touching
/// call sites. Logs are suppressed automatically in production builds.
abstract final class AppLogger {
  const AppLogger._();

  static final RegExp _secretPattern = RegExp(
    r'(authorization|bearer|token|password|api[_-]?key|secret)\s*[:=]\s*(?:bearer\s+)?[^,\s]+',
    caseSensitive: false,
  );

  static String sanitize(String value) => value.replaceAllMapped(
    _secretPattern,
    (Match match) => '${match.group(1)}=[REDACTED]',
  );

  static void debug(String message, {String name = 'MathTutor'}) {
    if (!AppConfigScope.current.enableLogging) {
      return;
    }
    developer.log(sanitize(message), name: name);
  }

  static void error(
    String message, {
    String name = 'MathTutor',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      sanitize(message),
      name: name,
      level: 1000,
      error: error == null ? null : sanitize(error.toString()),
      stackTrace: stackTrace,
    );
  }
}
