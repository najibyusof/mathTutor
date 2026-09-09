import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Filled, high-emphasis action button.
///
/// Renders a centered progress indicator and blocks taps while [isLoading].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
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
        ? FilledButton.icon(
            onPressed: enabled ? onPressed : null,
            icon: Icon(icon),
            label: child,
          )
        : FilledButton(onPressed: enabled ? onPressed : null, child: child);

    return isExpanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
