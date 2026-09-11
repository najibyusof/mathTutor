import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/theme/app_theme.dart';
import 'package:mathtutor/features/solver/domain/models/math_problem.dart';
import 'package:mathtutor/features/solver/domain/models/solution.dart';
import 'package:mathtutor/features/solver/presentation/pages/solution_screen.dart';
import 'package:mathtutor/features/solver/presentation/widgets/solution_widgets.dart';
import 'package:mathtutor/routes/app_router.dart';
import 'package:mathtutor/routes/app_routes.dart';

const MathProblem _problem = MathProblem(
  originalInput: '2x + 8 = 20',
  normalizedExpression: '2x+8=20',
  category: MathCategory.linearEquation,
  parsed: ParsedMathExpression(
    original: '2x + 8 = 20',
    normalized: '2x+8=20',
    left: Polynomial(constant: 8, linear: 2),
    right: Polynomial(constant: 20),
  ),
);

const Solution _solution = Solution(
  problem: _problem,
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
    SolutionStep(
      stepNumber: 3,
      expression: 'x = 6',
      explanation: 'Divide both sides by 2.',
      operation: 'divide',
      result: '6',
    ),
  ],
  finalAnswer: FinalAnswer(expression: 'x = 6', numericValue: 6),
);

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  onGenerateRoute: AppRouter.onGenerateRoute,
  home: child,
);

Future<void> _pumpSolution(
  WidgetTester tester, {
  Solution solution = _solution,
}) async {
  tester.view.physicalSize = const Size(420, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(SolutionScreen(solution: solution)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('displays original question, every step and final answer', (
    WidgetTester tester,
  ) async {
    await _pumpSolution(tester);

    expect(find.text('Solve'), findsOneWidget);
    expect(find.text('2x+8=20'), findsOneWidget);
    expect(find.byType(SolutionStepCard), findsNWidgets(3));
    expect(find.text('Step 1'), findsOneWidget);
    expect(find.text('Step 2'), findsOneWidget);
    expect(find.text('Step 3'), findsOneWidget);
    expect(find.text('Subtract 8 from both sides.'), findsOneWidget);
    expect(find.text('Simplify both sides.'), findsOneWidget);
    expect(find.text('Divide both sides by 2.'), findsOneWidget);
    expect(find.text('Final Answer'), findsOneWidget);
    expect(find.text('x = 6'), findsWidgets);
  });

  testWidgets('shows a positive verification result for a valid solution', (
    WidgetTester tester,
  ) async {
    await _pumpSolution(tester);

    expect(
      find.text('Verified: the final answer satisfies the problem.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
  });

  testWidgets('clearly reports an invalid verification result', (
    WidgetTester tester,
  ) async {
    const Solution invalid = Solution(
      problem: _problem,
      steps: <SolutionStep>[
        SolutionStep(
          stepNumber: 1,
          expression: 'x = undefined',
          explanation: 'The calculation failed.',
        ),
      ],
      finalAnswer: FinalAnswer(
        expression: 'undefined',
        numericValue: double.infinity,
      ),
    );

    await _pumpSolution(tester, solution: invalid);

    expect(
      find.text('This solution needs checking before it can be trusted.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('exposes all requested actions', (WidgetTester tester) async {
    await _pumpSolution(tester);

    expect(find.text('Try another question'), findsOneWidget);
    expect(find.text('Save solution'), findsOneWidget);
    expect(find.text('Share solution'), findsOneWidget);
    expect(find.text('View history'), findsOneWidget);
  });

  testWidgets('save and share show immediate feedback', (
    WidgetTester tester,
  ) async {
    await _pumpSolution(tester);

    await tester.tap(find.text('Save solution'));
    await tester.pump();
    expect(find.text('Solution saved to your history.'), findsOneWidget);

    await tester.tap(find.text('Share solution'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('try another question navigates back to input', (
    WidgetTester tester,
  ) async {
    await _pumpSolution(tester);

    await tester.tap(find.text('Try another question'));
    await tester.pumpAndSettle();

    expect(find.text('Your question'), findsOneWidget);
  });

  testWidgets('route renders SolutionScreen when a solution is supplied', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        initialRoute: AppRoutes.solver,
        onGenerateInitialRoutes: (String route) => <Route<dynamic>>[
          AppRouter.onGenerateRoute(
            RouteSettings(
              name: route,
              arguments: const SolverArgs(
                expression: '2x+8=20',
                solution: _solution,
              ),
            ),
          ),
        ],
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SolutionScreen), findsOneWidget);
    expect(find.text('x = 6'), findsWidgets);
  });
}
