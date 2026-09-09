import 'package:flutter/material.dart';

/// Centralized typography for MathTutor.
///
/// [AppTypography.textTheme] is fed into the Material 3 [ThemeData] so widgets
/// can rely on `Theme.of(context).textTheme` instead of hardcoded styles.
abstract final class AppTypography {
  const AppTypography._();

  /// Font family used for regular UI copy. `null` keeps the platform default,
  /// which avoids shipping font assets in this phase.
  static const String? fontFamily = null;

  /// Monospace family used when rendering raw math expressions.
  static const String mathFontFamily = 'monospace';

  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      height: 1.12,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      height: 1.16,
      fontWeight: FontWeight.w400,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      height: 1.22,
      fontWeight: FontWeight.w400,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      height: 1.25,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 1.29,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      height: 1.33,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      height: 1.27,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      height: 1.43,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.43,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      height: 1.33,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      height: 1.43,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      height: 1.33,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 1.45,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );

  /// Style for inline math expressions rendered as plain text.
  static const TextStyle mathExpression = TextStyle(
    fontFamily: mathFontFamily,
    fontSize: 20,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );
}
