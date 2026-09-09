import 'dart:developer' as developer;

import '../config/app_config.dart';

/// Thin logging facade so logging can be redirected later without touching
/// call sites. Logs are suppressed automatically in production builds.
abstract final class AppLogger {
  const AppLogger._();

  static void debug(String message, {String name = 'MathTutor'}) {
    if (!AppConfigScope.current.enableLogging) {
      return;
    }
    developer.log(message, name: name);
  }

  static void error(
    String message, {
    String name = 'MathTutor',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
