import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/theme/app_theme.dart';
import 'package:mathtutor/features/solver/domain/models/math_problem.dart';
import 'package:mathtutor/features/solver/domain/models/solution.dart';
import 'package:mathtutor/features/tutor/presentation/pages/tutor_screen.dart';

const Solution _solution = Solution(
  problem: MathProblem(
    originalInput: '2x + 8 = 20',
    normalizedExpression: '2x+8=20',
    category: MathCategory.linearEquation,
    parsed: ParsedMathExpression(
      original: '2x + 8 = 20',
      normalized: '2x+8=20',
      left: Polynomial(constant: 8, linear: 2),
      right: Polynomial(constant: 20),
    ),
  ),
  steps: <SolutionStep>[
    SolutionStep(
      stepNumber: 1,
      expression: '2x + 8 - 8 = 20 - 8',
      explanation: 'Subtract 8 from both sides.',
      operation: 'subtract',
    ),
    SolutionStep(
      stepNumber: 2,
      expression: '2x = 12',
      explanation: 'Simplify both sides.',
      operation: 'simplify',
    ),
  ],
  finalAnswer: FinalAnswer(expression: 'x = 6', numericValue: 6),
);

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: const TutorScreen(solution: _solution),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the tutor prompt and options', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    expect(find.text('What should we do first?'), findsOneWidget);
    expect(find.text('Subtract the constant'), findsOneWidget);
    expect(find.text('Show hint'), findsOneWidget);
    expect(find.text('Show solution'), findsOneWidget);
    expect(find.text('Step 1 of 2'), findsOneWidget);
  });

  testWidgets('wrong option gives feedback without revealing the step', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Add the constant'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'Not quite. Think about the operation that changes the term.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Think about what operation can remove the positive constant.',
      ),
      findsOneWidget,
    );
    expect(find.text('2x + 8 - 8 = 20 - 8'), findsNothing);
    expect(find.text('Step 1 of 2'), findsOneWidget);
  });

  testWidgets('correct option advances and shows correct feedback', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Subtract the constant'));
    await tester.pumpAndSettle();

    expect(find.text('Correct! Let’s continue.'), findsOneWidget);
    expect(find.text('What should we do next?'), findsOneWidget);
    expect(find.text('Step 2 of 2'), findsOneWidget);
  });

  testWidgets('show solution reveals the structured steps', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Show solution'));
    await tester.pumpAndSettle();

    expect(find.text('Here is the solution'), findsOneWidget);
    expect(find.text('2x + 8 - 8 = 20 - 8'), findsOneWidget);
    expect(find.text('Subtract 8 from both sides.'), findsOneWidget);
    expect(find.text('Final answer: x = 6'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('hint toggles without changing tutor progress', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Show hint'));
    await tester.pumpAndSettle();

    expect(
      find.text('Think about what operation can remove the positive constant.'),
      findsOneWidget,
    );
    expect(find.text('Step 1 of 2'), findsOneWidget);
  });
}
