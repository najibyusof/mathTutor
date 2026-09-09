import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Outlined, medium-emphasis action button.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;
    final Widget child = isLoading
        ? const SizedBox.square(
            dimension: AppSizes.iconSm,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    final Widget button = icon != null && !isLoading
        ? OutlinedButton.icon(
            onPressed: enabled ? onPressed : null,
            icon: Icon(icon),
            label: child,
          )
        : OutlinedButton(onPressed: enabled ? onPressed : null, child: child);

    return isExpanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
