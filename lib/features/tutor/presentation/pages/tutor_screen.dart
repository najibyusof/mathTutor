import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../solver/domain/models/solution.dart';
import '../controllers/tutor_controller.dart';
import '../../domain/models/tutor_models.dart';

/// Interactive learning mode driven entirely by structured solver steps.
class TutorScreen extends StatefulWidget {
  const TutorScreen({required this.solution, super.key});

  final Solution solution;

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  late final TutorController _controller = TutorController(
    solution: widget.solution,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutor mode')),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: 680,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, _) =>
                _controller.isComplete ? _completed() : _question(),
          ),
        ),
      ),
    );
  }

  Widget _question() {
    final TutorQuestion question = _controller.currentQuestion!;
    final TutorProgress progress = _controller.progress;
    final ThemeData theme = Theme.of(context);
    final TutorResponse? response = _controller.lastResponse;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.pageVertical),
      children: <Widget>[
        Text(
          'Learn this solution',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          widget.solution.problem.originalInput,
          style: AppTypography.mathExpression.copyWith(fontSize: 22),
        ),
        const SizedBox(height: AppSpacing.lg),
        LinearProgressIndicator(value: progress.fraction),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Step ${progress.currentStep} of ${progress.totalSteps}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(question.prompt, style: theme.textTheme.titleLarge),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final TutorOption option in question.options)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _OptionButton(
              option: option,
              onPressed: () => _controller.selectOption(option),
            ),
          ),
        if (response != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _ResponseBanner(response: response),
        ],
        if (_controller.showHint) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _HintCard(text: question.hint),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: SecondaryButton(
                label: _controller.showHint ? 'Hide hint' : 'Show hint',
                icon: Icons.lightbulb_outline,
                onPressed: _controller.toggleHint,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextButton(
                onPressed: _controller.revealSolution,
                child: const Text('Show solution'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _completed() {
    final ThemeData theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.pageVertical),
      children: <Widget>[
        Icon(
          Icons.emoji_events_outlined,
          size: AppSizes.iconXl,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          _controller.showSolution ? 'Here is the solution' : 'Great work!',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final SolutionStep step in _controller.solution.steps)
          AppCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Step ${step.stepNumber}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  step.expression,
                  style: AppTypography.mathExpression.copyWith(fontSize: 20),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(step.explanation),
              ],
            ),
          ),
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Final answer: ${_controller.solution.finalAnswer.expression}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SecondaryButton(
          label: 'Try again',
          icon: Icons.refresh,
          onPressed: _controller.tryAgain,
        ),
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.option, required this.onPressed});

  final TutorOption option;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
        ),
        child: Text(option.label),
      ),
    );
  }
}

class _ResponseBanner extends StatelessWidget {
  const _ResponseBanner({required this.response});

  final TutorResponse response;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool correct = response.isCorrect;
    final Color background = correct
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.tertiaryContainer;
    final Color foreground = correct
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onTertiaryContainer;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        [
          response.message,
          if (response.hint != null) 'Hint: ${response.hint}',
        ].whereType<String>().join('\n\n'),
        style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.lightbulb_outline,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
