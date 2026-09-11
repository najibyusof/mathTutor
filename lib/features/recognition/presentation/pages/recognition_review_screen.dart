import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/math_question.dart';
import '../../../../routes/app_router.dart';
import '../../../../routes/app_routes.dart';
import '../../../math/presentation/controllers/math_api_controller.dart';
import '../../../math_input/domain/math_expression.dart';
import '../../../math_input/presentation/widgets/math_input_widget.dart';
import '../../domain/entities/recognition_request.dart';
import '../../domain/services/question_recognition_service.dart';
import '../controllers/recognition_review_controller.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/expression_editor_sheet.dart';

/// Arguments for [AppRoutes.review].
class RecognitionReviewArgs {
  const RecognitionReviewArgs({required this.question, this.source});

  final MathQuestion question;

  /// Original input, kept so recognition can be retried.
  final RecognitionRequest? source;
}

/// Last stop before solving: shows the recognized question, how sure the
/// engine is, and lets the student edit or re-run recognition.
class RecognitionReviewScreen extends StatefulWidget {
  const RecognitionReviewScreen({required this.args, this.service, super.key});

  final RecognitionReviewArgs args;

  /// Injected in tests; resolved from [AppScope] otherwise.
  final QuestionRecognitionService? service;

  @override
  State<RecognitionReviewScreen> createState() =>
      _RecognitionReviewScreenState();
}

class _RecognitionReviewScreenState extends State<RecognitionReviewScreen> {
  RecognitionReviewController? _controller;
  MathApiController? _mathController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= RecognitionReviewController(
      question: widget.args.question,
      source: widget.args.source,
      service: widget.service ?? AppScope.maybeOf(context)?.recognitionService,
    );
    _mathController ??= AppScope.maybeOf(context)?.mathController;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _solve(MathQuestion question) async {
    final MathApiController? mathController = _mathController;
    if (mathController == null) {
      return;
    }
    final bool solved = await mathController.solve(question);
    if (!mounted) {
      return;
    }
    if (solved && mathController.solution != null) {
      Navigator.of(context).pushNamed(
        AppRoutes.solver,
        arguments: SolverArgs(
          expression: question.normalizedExpression,
          source: question.inputMethod.name,
          solution: mathController.solution,
        ),
      );
      return;
    }
    final String message =
        mathController.errorMessage ??
        'We could not solve this question. Please try again.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final RecognitionReviewController controller = _controller!;

    return Scaffold(
      appBar: AppBar(title: const Text('Review your question')),
      body: SafeArea(
        child: ResponsiveContent(
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[
              controller,
              ?_mathController,
            ]),
            builder: (BuildContext context, _) {
              final MathQuestion question = controller.question;

              if (controller.isEditing) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.pageVertical,
                  ),
                  child: ExpressionEditorSheet(
                    initialExpression: question.normalizedExpression,
                    onSave: controller.applyEdit,
                    onCancel: controller.cancelEditing,
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.pageVertical,
                ),
                children: <Widget>[
                  _sourceLine(question),
                  const SizedBox(height: AppSpacing.md),
                  const SectionHeader(title: 'Recognized question'),
                  const SizedBox(height: AppSpacing.sm),
                  MathInputWidget(
                    expression: MathExpression.parse(
                      question.normalizedExpression,
                    ),
                    showCaret: false,
                    placeholder: 'Nothing recognized yet',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: <Widget>[
                      ConfidenceBadge(question: question),
                      const Spacer(),
                      Text(
                        '${question.confidencePercent}%',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                  if (question.needsVerification) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    const _VerifyWarning(),
                  ],
                  if (controller.errorMessage != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    ErrorMessage(
                      title: 'Recognition failed',
                      message: controller.errorMessage,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: SecondaryButton(
                          label: 'Edit',
                          icon: Icons.edit_outlined,
                          onPressed: controller.startEditing,
                        ),
                      ),
                      if (controller.canRetry ||
                          controller.isRetrying) ...<Widget>[
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: SecondaryButton(
                            label: 'Retry',
                            icon: Icons.refresh,
                            isLoading: controller.isRetrying,
                            onPressed: controller.retryRecognition,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: 'Solve',
                    icon: Icons.auto_awesome,
                    isLoading: _mathController?.isLoading ?? false,
                    onPressed:
                        question.normalizedExpression.isEmpty ||
                            (_mathController?.isLoading ?? false)
                        ? null
                        : () => _solve(question),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _sourceLine(MathQuestion question) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Icon(
          question.inputMethod.icon,
          size: AppSizes.iconSm,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            '${question.inputMethod.label} • ${question.originalInput}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerifyWarning extends StatelessWidget {
  const _VerifyWarning();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.warning_amber_outlined,
            color: theme.colorScheme.onErrorContainer,
            size: AppSizes.iconMd,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'We are not sure we read this correctly. '
              'Please check the equation and edit it before solving.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
