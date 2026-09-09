import 'package:flutter/material.dart';

import '../../models/math_question.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/date_formatter.dart';
import 'app_card.dart';
import 'app_logo.dart';

/// Row showing one asked question with its topic, age and answer preview.
class QuestionTile extends StatelessWidget {
  const QuestionTile({
    required this.question,
    required this.now,
    required this.onTap,
    super.key,
  });

  final MathQuestion question;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: <Widget>[
          AppIconBadge(
            icon: question.inputMethod.icon,
            background: theme.colorScheme.surfaceContainerHighest,
            foreground: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  question.expression,
                  style: AppTypography.mathExpression.copyWith(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${question.topic} • '
                  '${DateFormatter.relative(question.createdAt, now: now)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (question.answerPreview != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            Text(
              question.answerPreview!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
