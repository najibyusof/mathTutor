import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/math_question.dart';
import '../../../../models/question_input_method.dart';
import '../../../../routes/app_router.dart';
import '../../../../routes/app_routes.dart';
import '../../../recognition/domain/entities/recognition_request.dart';
import '../../../recognition/presentation/pages/recognition_review_screen.dart';
import '../../domain/math_expression.dart';
import '../controllers/math_expression_controller.dart';
import '../widgets/input_method_selector.dart';
import '../widgets/math_input_widget.dart';
import '../widgets/math_keyboard_widget.dart';

/// Screen where the student composes a question with the math keyboard.
class MathInputPage extends StatefulWidget {
  const MathInputPage({this.args, super.key});

  final MathInputArgs? args;

  @override
  State<MathInputPage> createState() => _MathInputPageState();
}

class _MathInputPageState extends State<MathInputPage> {
  late final MathExpressionController _controller =
      widget.args?.initialExpression == null
      ? MathExpressionController()
      : MathExpressionController.fromRaw(widget.args!.initialExpression!);

  late QuestionInputMethod _method =
      widget.args?.method ?? QuestionInputMethod.keyboard;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onMethodSelected(QuestionInputMethod method) {
    if (method == _method) {
      return;
    }
    setState(() => _method = method);

    switch (method) {
      case QuestionInputMethod.keyboard:
        break;
      case QuestionInputMethod.handwriting:
        Navigator.of(context).pushNamed(AppRoutes.handwriting);
      case QuestionInputMethod.camera:
        Navigator.of(context).pushNamed(AppRoutes.camera);
    }
  }

  /// Typed questions go through the same review step as recognized ones.
  void _review(MathExpression expression) {
    Navigator.of(context).pushNamed(
      AppRoutes.review,
      arguments: RecognitionReviewArgs(
        question: MathQuestion.create(
          originalInput: expression.displayText,
          normalizedExpression: expression.rawInput,
          inputMethod: QuestionInputMethod.keyboard,
        ),
        source: KeyboardInput(expression.rawInput),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.askQuestion),
        actions: <Widget>[
          IconButton(
            tooltip: AppStrings.historyTitle,
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.history),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: ValueListenableBuilder<MathExpression>(
            valueListenable: _controller,
            builder: (BuildContext context, MathExpression expression, _) {
              final bool canSolve = expression.isNotEmpty;

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: <Widget>[
                  Center(
                    child: InputMethodSelector(
                      selected: _method,
                      onSelected: _onMethodSelected,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SectionHeader(
                    title: AppStrings.questionInputTitle,
                    subtitle: expression.isEmpty
                        ? AppStrings.questionInputHint
                        : expression.displayText,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MathInputWidget(
                    expression: expression,
                    placeholder: AppStrings.questionInputHint,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MathKeyboardWidget(
                    canUndo: _controller.canUndo,
                    onKeyPressed: _controller.handleKey,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: AppStrings.solveQuestion,
                    icon: Icons.auto_awesome,
                    onPressed: canSolve ? () => _review(expression) : null,
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
}
