import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/constants/app_strings.dart';
import 'package:mathtutor/core/theme/app_theme.dart';
import 'package:mathtutor/features/math_input/presentation/pages/math_input_page.dart';
import 'package:mathtutor/features/math_input/presentation/widgets/math_input_widget.dart';
import 'package:mathtutor/features/math_input/presentation/widgets/math_keyboard_widget.dart';
import 'package:mathtutor/features/recognition/presentation/pages/recognition_review_screen.dart';
import 'package:mathtutor/routes/app_router.dart';

Future<void> _pumpPage(WidgetTester tester, {MathInputArgs? args}) async {
  tester.view.physicalSize = const Size(420, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: MathInputPage(args: args),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(InkWell, label).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the editor with a disabled solve action', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester);

    expect(find.byType(MathInputWidget), findsOneWidget);
    expect(find.byType(MathKeyboardWidget), findsOneWidget);

    final FilledButton solve = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(solve.onPressed, isNull);
  });

  testWidgets('typing enables solve and hands the expression to review', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester);

    await _tapKey(tester, '2');
    await _tapKey(tester, '+');
    await _tapKey(tester, '3');

    expect(find.text('2 + 3'), findsOneWidget);

    await tester.tap(find.text(AppStrings.solveQuestion));
    await tester.pumpAndSettle();

    expect(find.byType(RecognitionReviewScreen), findsOneWidget);
    expect(find.text('Confidence: High'), findsOneWidget);
  });

  testWidgets('opens with an existing expression for editing', (
    WidgetTester tester,
  ) async {
    await _pumpPage(
      tester,
      args: const MathInputArgs(initialExpression: 'x^(2)+6=0'),
    );

    expect(find.text('x² + 6 = 0'), findsOneWidget);

    await tester.tap(find.widgetWithIcon(InkWell, Icons.backspace_outlined));
    await tester.pumpAndSettle();

    expect(find.text('x² + 6 ='), findsOneWidget);
  });
}
