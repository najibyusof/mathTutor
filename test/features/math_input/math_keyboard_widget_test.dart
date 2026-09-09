import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/theme/app_theme.dart';
import 'package:mathtutor/features/math_input/domain/math_expression.dart';
import 'package:mathtutor/features/math_input/domain/math_keys.dart';
import 'package:mathtutor/features/math_input/presentation/controllers/math_expression_controller.dart';
import 'package:mathtutor/features/math_input/presentation/widgets/math_input_widget.dart';
import 'package:mathtutor/features/math_input/presentation/widgets/math_keyboard_widget.dart';

Future<MathExpressionController> _pumpEditor(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
  Size size = const Size(400, 1400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final MathExpressionController controller = MathExpressionController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ValueListenableBuilder<MathExpression>(
            valueListenable: controller,
            builder: (BuildContext context, MathExpression expression, _) {
              return Column(
                children: <Widget>[
                  MathInputWidget(expression: expression),
                  MathKeyboardWidget(
                    canUndo: controller.canUndo,
                    onKeyPressed: controller.handleKey,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _tapKey(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(InkWell, label).first);
  await tester.pumpAndSettle();
}

Future<void> _tapControl(WidgetTester tester, IconData icon) async {
  await tester.tap(find.widgetWithIcon(InkWell, icon).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('typing on the keyboard updates the expression', (
    WidgetTester tester,
  ) async {
    final MathExpressionController controller = await _pumpEditor(tester);

    await _tapKey(tester, '2');
    await _tapKey(tester, '+');
    await _tapKey(tester, '3');

    expect(controller.value.displayText, '2 + 3');
    expect(find.text('2'), findsWidgets);
  });

  testWidgets('section tabs expose the algebra and comparison keys', (
    WidgetTester tester,
  ) async {
    final MathExpressionController controller = await _pumpEditor(tester);

    await _tapKey(tester, '2');
    await tester.tap(find.text(MathKeyboardSection.algebra.label));
    await tester.pumpAndSettle();
    await _tapKey(tester, 'x');

    await tester.tap(find.text(MathKeyboardSection.compare.label));
    await tester.pumpAndSettle();
    await _tapKey(tester, '≥');

    await tester.tap(find.text(MathKeyboardSection.basic.label));
    await tester.pumpAndSettle();
    await _tapKey(tester, '9');

    expect(controller.value.displayText, '2x ≥ 9');
  });

  testWidgets('backspace, clear and undo work from the control row', (
    WidgetTester tester,
  ) async {
    final MathExpressionController controller = await _pumpEditor(tester);

    await _tapKey(tester, '4');
    await _tapKey(tester, '5');
    await _tapControl(tester, Icons.backspace_outlined);
    expect(controller.value.displayText, '4');

    await _tapControl(tester, Icons.delete_outline);
    expect(controller.value.isEmpty, isTrue);

    await _tapControl(tester, Icons.undo);
    expect(controller.value.displayText, '4');
  });

  testWidgets('undo is disabled until something has been typed', (
    WidgetTester tester,
  ) async {
    await _pumpEditor(tester);

    final InkWell undo = tester.widget<InkWell>(
      find.widgetWithIcon(InkWell, Icons.undo).first,
    );
    expect(undo.onTap, isNull);

    await _tapKey(tester, '1');

    final InkWell enabledUndo = tester.widget<InkWell>(
      find.widgetWithIcon(InkWell, Icons.undo).first,
    );
    expect(enabledUndo.onTap, isNotNull);
  });

  testWidgets('cursor keys move the caret and insert in place', (
    WidgetTester tester,
  ) async {
    final MathExpressionController controller = await _pumpEditor(tester);

    await _tapKey(tester, '1');
    await _tapKey(tester, '3');
    await _tapControl(tester, Icons.chevron_left);
    await _tapKey(tester, '2');

    expect(controller.value.displayText, '123');
    expect(controller.value.cursor, 2);

    await _tapControl(tester, Icons.chevron_right);
    expect(controller.value.cursor, 3);
  });

  testWidgets('structure keys build fractions, roots and powers', (
    WidgetTester tester,
  ) async {
    final MathExpressionController controller = await _pumpEditor(tester);

    await _tapKey(tester, '▫/▫');
    await _tapKey(tester, '9');
    await _tapControl(tester, Icons.chevron_right);
    await _tapControl(tester, Icons.chevron_right);
    await _tapControl(tester, Icons.chevron_right);
    await _tapKey(tester, '4');

    expect(controller.value.displayText, '(9)/(4)');
    expect(controller.value.isBalanced, isTrue);

    // Leave the denominator before appending the root.
    await _tapControl(tester, Icons.chevron_right);

    await tester.tap(find.text(MathKeyboardSection.math.label));
    await tester.pumpAndSettle();
    await _tapKey(tester, '√');

    await tester.tap(find.text(MathKeyboardSection.basic.label));
    await tester.pumpAndSettle();
    await _tapKey(tester, '2');

    expect(controller.value.rawInput, '(9)/(4)*sqrt(2)');
  });

  testWidgets('renders in the dark theme without overflow', (
    WidgetTester tester,
  ) async {
    final MathExpressionController controller = await _pumpEditor(
      tester,
      brightness: Brightness.dark,
      size: const Size(320, 1400),
    );

    await _tapKey(tester, '7');
    await _tapKey(tester, 'x²');

    expect(controller.value.displayText, '7²');
    expect(tester.takeException(), isNull);
  });
}
