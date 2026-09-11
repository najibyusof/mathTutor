import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/solution.dart';

/// Visually distinct but restrained card for one transformation in a solution.
class SolutionStepCard extends StatelessWidget {
  const SolutionStepCard({required this.step, super.key});

  final SolutionStep step;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: Text('${step.stepNumber}'),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Step ${step.stepNumber}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: SelectableText(
                step.expression,
                style: AppTypography.mathExpression.copyWith(
                  fontSize: 21,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.lightbulb_outline,
                  size: AppSizes.iconMd,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    step.explanation,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Final answer treatment shared by solution results.
class FinalAnswerCard extends StatelessWidget {
  const FinalAnswerCard({required this.answer, super.key});

  final FinalAnswer answer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Final Answer',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SelectableText(
              answer.expression,
              style: AppTypography.mathExpression.copyWith(
                fontSize: 30,
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clear verification state derived from the validated solution contract.
class VerificationBanner extends StatelessWidget {
  const VerificationBanner({required this.solution, super.key});

  final Solution solution;

  bool get _isVerified =>
      solution.finalAnswer.hasFiniteNumericValue &&
      solution.steps.isNotEmpty &&
      solution.steps.every(
        (SolutionStep step) =>
            step.stepNumber > 0 &&
            step.expression.trim().isNotEmpty &&
            step.explanation.trim().isNotEmpty,
      );

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color background = _isVerified
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.errorContainer;
    final Color foreground = _isVerified
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onErrorContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            _isVerified ? Icons.verified_outlined : Icons.error_outline,
            color: foreground,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _isVerified
                  ? 'Verified: the final answer satisfies the problem.'
                  : 'This solution needs checking before it can be trusted.',
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
