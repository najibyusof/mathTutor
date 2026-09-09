import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Wordless app mark: a rounded tile with the MathTutor glyph.
///
/// Drawn with framework primitives so no image assets are required.
class AppLogo extends StatelessWidget {
  const AppLogo({this.size = 72, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[colors.primary, colors.tertiary],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.functions,
        size: size * 0.52,
        color: colors.onPrimary,
      ),
    );
  }
}

/// Small square badge used in headers and list rows.
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    required this.icon,
    this.size = 44,
    this.background,
    this.foreground,
    super.key,
  });

  final IconData icon;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? colors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: size * 0.5,
        color: foreground ?? colors.onSecondaryContainer,
      ),
    );
  }
}
