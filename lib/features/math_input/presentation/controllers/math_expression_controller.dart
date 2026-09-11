import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/math_expression.dart';
import '../../domain/math_keys.dart';

/// Applies key presses to a [MathExpression] and keeps an undo history.
class MathExpressionController extends ValueNotifier<MathExpression> {
  MathExpressionController({MathExpression? initial})
    : super(initial ?? MathExpression.empty);

  /// Seeds the editor from stored text, e.g. when reopening a question.
  MathExpressionController.fromRaw(String raw)
    : super(MathExpression.parse(raw).moveToEnd());

  final List<MathExpression> _history = <MathExpression>[];

  static const int _maxHistory = 50;

  bool get canUndo => _history.isNotEmpty;

  void handleKey(MathKey key) {
    switch (key.action) {
      case MathKeyAction.insert:
        if (value.tokens.length + key.tokens.length >
            AppConstants.maxExpressionLength) {
          return;
        }
        _apply(value.insert(key.tokens, cursorOffset: key.cursorOffset));
      case MathKeyAction.backspace:
        _apply(value.backspace());
      case MathKeyAction.clear:
        _apply(value.clear());
      case MathKeyAction.undo:
        undo();
      case MathKeyAction.moveLeft:
        value = value.moveLeft();
      case MathKeyAction.moveRight:
        value = value.moveRight();
    }
  }

  /// Replaces the expression without recording history (external edits).
  void setExpression(MathExpression expression) {
    _history.clear();
    value = expression;
  }

  void undo() {
    if (_history.isEmpty) {
      return;
    }
    value = _history.removeLast();
  }

  void _apply(MathExpression next) {
    if (identical(next, value)) {
      return;
    }
    _history.add(value);
    if (_history.length > _maxHistory) {
      _history.removeAt(0);
    }
    value = next;
  }
}
