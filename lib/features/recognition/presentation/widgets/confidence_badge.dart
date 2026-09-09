import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../models/math_question.dart';

/// Confidence badge: High / Medium / Low.
class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({required this.question, super.key});

  final MathQuestion question;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final (Color background, Color foreground, IconData icon) = switch (
      question.confidenceLevel
    ) {
      RecognitionConfidence.high => (
        theme.colorScheme.secondaryContainer,
        theme.colorScheme.onSecondaryContainer,
        Icons.verified_outlined,
      ),
      RecognitionConfidence.medium => (
        theme.colorScheme.tertiaryContainer,
        theme.colorScheme.onTertiaryContainer,
        Icons.help_outline,
      ),
      RecognitionConfidence.low => (
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
        Icons.warning_amber_outlined,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: AppSizes.iconSm, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Confidence: ${question.confidenceLevel.label}',
            style: theme.textTheme.labelLarge?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
