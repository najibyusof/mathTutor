import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../routes/app_router.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/models/math_problem.dart';
import '../../domain/models/solution.dart';
import '../widgets/solution_widgets.dart';

/// Displays a validated solution and keeps every action close to the result.
class SolutionScreen extends StatelessWidget {
  const SolutionScreen({required this.solution, super.key});

  final Solution solution;

  String get _shareText {
    final StringBuffer text = StringBuffer()
      ..writeln('Solve: ${solution.problem.originalInput}')
      ..writeln();
    for (final SolutionStep step in solution.steps) {
      text
        ..writeln('Step ${step.stepNumber}')
        ..writeln(step.expression)
        ..writeln(step.explanation)
        ..writeln();
    }
    text
      ..writeln('Final Answer')
      ..writeln(solution.finalAnswer.expression);
    return text.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solution'),
        actions: <Widget>[
          IconButton(
            tooltip: 'View history',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.history),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.pageVertical,
            ),
            children: <Widget>[
              _QuestionHeader(problem: solution.problem),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Step-by-step solution'),
              const SizedBox(height: AppSpacing.sm),
              for (final SolutionStep step in solution.steps)
                SolutionStepCard(step: step),
              const SizedBox(height: AppSpacing.sm),
              FinalAnswerCard(answer: solution.finalAnswer),
              const SizedBox(height: AppSpacing.md),
              VerificationBanner(solution: solution),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Learn interactively',
                icon: Icons.school_outlined,
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRoutes.tutor,
                  arguments: SolverArgs(
                    expression: solution.problem.normalizedExpression,
                    solution: solution,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _Actions(
                onTryAnother: () =>
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.mathInput,
                      (Route<dynamic> route) => route.isFirst,
                    ),
                onSave: () => _showSaved(context),
                onShare: () => _share(context),
                onHistory: () =>
                    Navigator.of(context).pushNamed(AppRoutes.history),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaved(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Solution saved to your history.')),
    );
  }

  Future<void> _share(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _shareText));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Solution copied to the clipboard.')),
    );
  }
}

class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({required this.problem});

  final MathProblem problem;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String readable = problem.parsed.normalized;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Solve', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
              readable,
              style: AppTypography.mathExpression.copyWith(
                fontSize: 24,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.onTryAnother,
    required this.onSave,
    required this.onShare,
    required this.onHistory,
  });

  final VoidCallback onTryAnother;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PrimaryButton(
          label: 'Try another question',
          icon: Icons.add_circle_outline,
          onPressed: onTryAnother,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: SecondaryButton(
                label: 'Save solution',
                icon: Icons.bookmark_outline,
                onPressed: onSave,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SecondaryButton(
                label: 'Share solution',
                icon: Icons.share_outlined,
                onPressed: onShare,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton.icon(
          onPressed: onHistory,
          icon: const Icon(Icons.history),
          label: const Text('View history'),
        ),
      ],
    );
  }
}
