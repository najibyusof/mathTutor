import 'package:flutter/material.dart';

/// Content of a single onboarding slide.
class OnboardingStep {
  const OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  static const List<OnboardingStep> steps = <OnboardingStep>[
    OnboardingStep(
      title: 'Ask any math question',
      description:
          'Type it with the math keyboard, write it by hand, or scan it '
          'straight from your notebook.',
      icon: Icons.edit_note_outlined,
    ),
    OnboardingStep(
      title: 'Understand every step',
      description:
          'MathTutor explains the solution step by step, so you learn the '
          'method instead of copying an answer.',
      icon: Icons.school_outlined,
    ),
    OnboardingStep(
      title: 'Keep track of progress',
      description:
          'Your solved questions stay in your history, ready to review '
          'before the next test.',
      icon: Icons.insights_outlined,
    ),
  ];
}
