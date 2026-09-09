import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'widgets.dart';
import '../../models/recognition_result.dart';

/// Shows what the recognition engine read, with the option to accept an
/// alternative reading.
class RecognitionResultCard extends StatelessWidget {
  const RecognitionResultCard({
    required this.result,
    required this.onAccept,
    required this.onDismiss,
    super.key,
  });

  final RecognitionResult result;

  /// Called with the chosen expression in raw form.
  final ValueChanged<String> onAccept;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'We read this as',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(
                  '${(result.confidence * 100).round()}% sure',
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            result.expression,
            style: AppTypography.mathExpression.copyWith(
              fontSize: 24,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (result.alternatives.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Not quite? Pick another reading:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final String alternative in result.alternatives)
                  ActionChip(
                    label: Text(alternative),
                    onPressed: () => onAccept(alternative),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: SecondaryButton(
                  label: 'Rewrite',
                  onPressed: onDismiss,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PrimaryButton(
                  label: 'Use this',
                  onPressed: () => onAccept(result.expression),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
