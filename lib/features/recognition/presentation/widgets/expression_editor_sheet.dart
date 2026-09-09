import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../math_input/domain/math_expression.dart';
import '../../../math_input/presentation/controllers/math_expression_controller.dart';
import '../../../math_input/presentation/widgets/math_input_widget.dart';
import '../../../math_input/presentation/widgets/math_keyboard_widget.dart';

/// Inline editor used on the review screen so a recognized question can always
/// be corrected before solving.
class ExpressionEditorSheet extends StatefulWidget {
  const ExpressionEditorSheet({
    required this.initialExpression,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  /// Raw expression, e.g. `2*x+5=15`.
  final String initialExpression;

  /// Receives the edited expression in raw form.
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;

  @override
  State<ExpressionEditorSheet> createState() => _ExpressionEditorSheetState();
}

class _ExpressionEditorSheetState extends State<ExpressionEditorSheet> {
  late final MathExpressionController _controller =
      MathExpressionController.fromRaw(widget.initialExpression);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MathExpression>(
      valueListenable: _controller,
      builder: (BuildContext context, MathExpression expression, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SectionHeader(title: 'Edit the question'),
            const SizedBox(height: AppSpacing.sm),
            MathInputWidget(expression: expression),
            const SizedBox(height: AppSpacing.lg),
            MathKeyboardWidget(
              canUndo: _controller.canUndo,
              onKeyPressed: _controller.handleKey,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: SecondaryButton(
                    label: 'Cancel',
                    onPressed: widget.onCancel,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: 'Save',
                    onPressed: expression.isEmpty
                        ? null
                        : () => widget.onSave(expression.rawInput),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
