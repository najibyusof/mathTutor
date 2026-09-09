/// Static, non-localized application constants.
abstract final class AppConstants {
  const AppConstants._();

  static const String appName = 'MathTutor';
  static const String appVersion = '1.0.0';

  /// Shared animation durations.
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 250);
  static const Duration longAnimation = Duration(milliseconds: 400);

  /// Number of items requested per paginated API call.
  static const int defaultPageSize = 20;

  /// Maximum characters accepted by the math expression input.
  static const int maxExpressionLength = 512;
}
