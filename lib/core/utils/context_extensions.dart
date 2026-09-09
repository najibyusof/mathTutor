import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;

  Size get screenSize => MediaQuery.sizeOf(this);
  bool get isCompact => MediaQuery.sizeOf(this).width < AppBreakpoints.compact;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

extension StringX on String {
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  bool get isBlank => trim().isEmpty;
}
