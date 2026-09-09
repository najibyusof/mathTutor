import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/features/math_input/domain/math_expression.dart';
import 'package:mathtutor/features/math_input/domain/math_keys.dart';
import 'package:mathtutor/features/math_input/domain/math_token.dart';
import 'package:mathtutor/features/math_input/presentation/controllers/math_expression_controller.dart';

MathKey _key(MathToken token) => MathKey.token(token);

void main() {
  test('key presses build the expression', () {
    final MathExpressionController controller = MathExpressionController();
    addTearDown(controller.dispose);

    controller.handleKey(_key(MathToken.digit('2')));
    controller.handleKey(_key(MathToken.variable('x')));
    controller.handleKey(_key(MathToken.plus));
    controller.handleKey(_key(MathToken.digit('5')));

    expect(controller.value.displayText, '2x + 5');
  });

  test('undo restores the previous state and stops when empty', () {
    final MathExpressionController controller = MathExpressionController();
    addTearDown(controller.dispose);

    expect(controller.canUndo, isFalse);

    controller.handleKey(_key(MathToken.digit('4')));
    controller.handleKey(_key(MathToken.digit('2')));
    expect(controller.value.displayText, '42');
    expect(controller.canUndo, isTrue);

    controller.undo();
    expect(controller.value.displayText, '4');

    controller.undo();
    expect(controller.value.isEmpty, isTrue);
    expect(controller.canUndo, isFalse);

    controller.undo();
    expect(controller.value.isEmpty, isTrue);
  });

  test('undo restores a cleared expression', () {
    final MathExpressionController controller = MathExpressionController();
    addTearDown(controller.dispose);

    controller.handleKey(_key(MathToken.digit('7')));
    controller.handleKey(
      const MathKey(label: 'Clear', action: MathKeyAction.clear),
    );
    expect(controller.value.isEmpty, isTrue);

    controller.undo();
    expect(controller.value.displayText, '7');
  });

  test('rejected input is not recorded in history', () {
    final MathExpressionController controller = MathExpressionController();
    addTearDown(controller.dispose);

    controller.handleKey(_key(MathToken.plus));

    expect(controller.value.isEmpty, isTrue);
    expect(controller.canUndo, isFalse);
  });

  test('backspace and cursor keys are applied', () {
    final MathExpressionController controller = MathExpressionController();
    addTearDown(controller.dispose);

    controller.handleKey(_key(MathToken.digit('1')));
    controller.handleKey(_key(MathToken.digit('2')));
    controller.handleKey(
      const MathKey(label: 'Backspace', action: MathKeyAction.backspace),
    );
    expect(controller.value.displayText, '1');

    controller.handleKey(
      const MathKey(label: 'Left', action: MathKeyAction.moveLeft),
    );
    expect(controller.value.cursor, 0);

    controller.handleKey(
      const MathKey(label: 'Right', action: MathKeyAction.moveRight),
    );
    expect(controller.value.cursor, 1);
  });

  test('loads an existing expression for editing', () {
    final MathExpressionController controller =
        MathExpressionController.fromRaw('x^(2)+5x+6=0');
    addTearDown(controller.dispose);

    expect(controller.value.displayText, 'x² + 5x + 6 = 0');
    expect(controller.value.cursor, controller.value.tokens.length);

    controller.handleKey(
      const MathKey(label: 'Backspace', action: MathKeyAction.backspace),
    );
    expect(controller.value.displayText, 'x² + 5x + 6 =');
  });

  test('setExpression replaces the value and drops the history', () {
    final MathExpressionController controller = MathExpressionController();
    addTearDown(controller.dispose);

    controller.handleKey(_key(MathToken.digit('3')));
    controller.setExpression(MathExpression.parse('y=2'));

    expect(controller.value.displayText, 'y = 2');
    expect(controller.canUndo, isFalse);
  });
}
