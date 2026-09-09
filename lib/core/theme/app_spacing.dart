/// Centralized spacing, radius and sizing tokens.
///
/// Every layout value in the app should reference one of these constants so
/// that vertical rhythm stays consistent across features.
abstract final class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Default horizontal padding for page-level content.
  static const double pageHorizontal = lg;

  /// Default vertical padding for page-level content.
  static const double pageVertical = lg;

  /// Maximum content width so the UI stays readable on tablets/foldables.
  static const double maxContentWidth = 640;
}

abstract final class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

abstract final class AppSizes {
  const AppSizes._();

  static const double buttonHeight = 52;
  static const double buttonMinWidth = 88;
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 64;
  static const double dividerThickness = 1;
}

abstract final class AppBreakpoints {
  const AppBreakpoints._();

  static const double compact = 600;
  static const double medium = 840;
}
