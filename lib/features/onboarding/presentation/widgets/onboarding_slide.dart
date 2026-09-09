import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/onboarding_step.dart';

/// Single onboarding slide: illustration, title and description.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({required this.step, super.key});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primaryContainer,
          ),
          alignment: Alignment.center,
          child: Icon(
            step.icon,
            size: 72,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          step.title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          step.description,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
