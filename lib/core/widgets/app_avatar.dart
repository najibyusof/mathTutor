import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Circular avatar showing the user's initials.
///
/// Uses initials instead of a network image until profiles are backed by the
/// API.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.initials,
    this.size = 44,
    this.onTap,
    this.tooltip,
    super.key,
  });

  final String initials;
  final double size;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Widget avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primaryContainer,
      ),
      child: Text(
        initials,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontSize: size * 0.36,
        ),
      ),
    );

    final Widget interactive = onTap == null
        ? avatar
        : InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: avatar,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: tooltip == null
          ? interactive
          : Tooltip(message: tooltip!, child: interactive),
    );
  }
}
