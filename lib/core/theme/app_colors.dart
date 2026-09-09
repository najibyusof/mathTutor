import 'package:flutter/material.dart';

/// Centralized color palette for MathTutor.
///
/// Material 3 derives most component colors from a [ColorScheme]; the raw
/// values below are the seeds and the few brand/semantic colors that are not
/// part of the generated scheme.
abstract final class AppColors {
  const AppColors._();

  // Brand seeds
  static const Color primarySeed = Color(0xFF2F6BFF);
  static const Color secondarySeed = Color(0xFF00BFA6);
  static const Color tertiarySeed = Color(0xFFFF8A3D);

  // Semantic colors
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFC8E6C9);
  static const Color warning = Color(0xFFED6C02);
  static const Color warningContainer = Color(0xFFFFE0B2);
  static const Color info = Color(0xFF0288D1);
  static const Color infoContainer = Color(0xFFB3E5FC);

  // Neutrals used by custom surfaces (math keyboard, canvas, etc.)
  static const Color canvasLight = Color(0xFFFFFFFF);
  static const Color canvasDark = Color(0xFF12141A);
  static const Color gridLineLight = Color(0xFFE3E6EC);
  static const Color gridLineDark = Color(0xFF2A2E39);
  static const Color inkLight = Color(0xFF1B1C1F);
  static const Color inkDark = Color(0xFFF2F3F5);

  static ColorScheme get lightScheme => ColorScheme.fromSeed(
    seedColor: primarySeed,
    brightness: Brightness.light,
  );

  static ColorScheme get darkScheme => ColorScheme.fromSeed(
    seedColor: primarySeed,
    brightness: Brightness.dark,
  );
}
