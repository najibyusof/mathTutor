import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/errors/failures.dart';
import 'package:mathtutor/core/network/result.dart';
import 'package:mathtutor/features/solver/data/parsers/basic_math_parser.dart';
import 'package:mathtutor/features/solver/data/services/basic_math_solving_service.dart';
import 'package:mathtutor/features/solver/data/solvers/basic_math_solver.dart';
import 'package:mathtutor/features/solver/data/validators/basic_solution_validator.dart';
import 'package:mathtutor/features/solver/data/explanations/basic_solution_explanation_service.dart';
import 'package:mathtutor/features/solver/domain/models/math_problem.dart';
import 'package:mathtutor/features/solver/domain/models/solution.dart';

BasicMathSolvingService _service() => BasicMathSolvingService(
  parser: const BasicMathParser(),
  solver: const BasicMathSolver(),
  validator: const BasicSolutionValidator(),
  explainer: const BasicSolutionExplanationService(),
);

void main() {
  group('BasicMathParser', () {
    const BasicMathParser parser = BasicMathParser();

    test('parses arithmetic with precedence and parentheses', () {
      final Result<MathProblem> result = parser.parse('(2 + 3) * 4');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.category, MathCategory.arithmetic);
      expect(result.valueOrNull?.parsed.left.constant, 20);
      expect(result.valueOrNull?.normalizedExpression, '20');
    });

    test('parses implicit multiplication in a linear equation', () {
      final Result<MathProblem> result = parser.parse('2x + 8 = 20');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.category, MathCategory.linearEquation);
      expect(result.valueOrNull?.parsed.left.linear, 2);
      expect(result.valueOrNull?.parsed.left.constant, 8);
      expect(result.valueOrNull?.parsed.right?.constant, 20);
    });

    test('accepts unicode operators from the math keyboard', () {
      final Result<MathProblem> result = parser.parse('18 ÷ 3 − 1');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.parsed.left.constant, 5);
    });

    test('rejects empty, malformed and unsafe expressions', () {
      for (final String input in <String>[
        '',
        '2 +',
        '2 / 0',
        'x / 0 = 4',
        '(2 + 3',
        '2 ** 3',
      ]) {
        final Result<MathProblem> result = parser.parse(input);
        expect(result.failureOrNull, isA<MathParserFailure>(), reason: input);
      }
    });

    test('rejects non-finite numeric literals', () {
      final Result<MathProblem> result = parser.parse('1e309');

      expect(result.failureOrNull, isA<MathParserFailure>());
    });

    test('parses a valid decimal and fraction expression', () {
      final Result<MathProblem> decimal = parser.parse('1.5 + 0.5');
      final Result<MathProblem> fraction = parser.parse('1 / 2');

      expect(decimal.valueOrNull?.parsed.left.constant, 2);
      expect(fraction.valueOrNull?.parsed.left.constant, 0.5);
    });

    test('rejects very long input instead of doing unbounded work', () {
      final Result<MathProblem> result = parser.parse('1' * 10001);

      expect(result.failureOrNull, isA<MathParserFailure>());
    });
  });

  group('BasicMathSolver', () {
    const BasicMathParser parser = BasicMathParser();
    const BasicMathSolver solver = BasicMathSolver();

    MathProblem parse(String input) => parser.parse(input).valueOrNull!;

    test('solves arithmetic', () {
      final Result<Solution> result = solver.solve(parse('2 + 3 * 4'));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.finalAnswer.expression, '14');
      expect(result.valueOrNull?.finalAnswer.numericValue, 14);
      expect(result.valueOrNull!.steps, hasLength(1));
    });

    test('solves a positive linear equation', () {
      final Result<Solution> result = solver.solve(parse('2x + 8 = 20'));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.finalAnswer.expression, 'x = 6');
      expect(result.valueOrNull?.finalAnswer.numericValue, 6);
      expect(
        result.valueOrNull!.steps.map((SolutionStep step) => step.stepNumber),
        <int>[1, 2, 3],
      );
    });

    test('solves a negative-coefficient linear equation', () {
      final Result<Solution> result = solver.solve(parse('5 - 2x = 11'));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.finalAnswer.expression, 'x = -3');
      expect(result.valueOrNull?.finalAnswer.numericValue, -3);
    });

    test('reports no solution and infinite solutions', () {
      expect(
        solver.solve(parse('x + 1 = x + 2')).failureOrNull,
        isA<MathSolverFailure>(),
      );
      expect(
        solver.solve(parse('x + 1 = x + 1')).failureOrNull,
        isA<MathSolverFailure>(),
      );
    });

    test('does not claim unsupported quadratic solving', () {
      final Result<Solution> result = solver.solve(parse('x^2 + 1 = 5'));

      expect(result.failureOrNull, isA<MathSolverFailure>());
      expect(result.failureOrNull?.message, contains('not supported'));
    });

    test('solves negative values, fractions and decimals', () {
      final Result<Solution> negative = solver.solve(parse('x + 5 = 2'));
      final Result<Solution> fraction = solver.solve(parse('0.5x = 1'));
      final Result<Solution> decimal = solver.solve(parse('1.5 + 0.5'));

      expect(negative.valueOrNull?.finalAnswer.expression, 'x = -3');
      expect(fraction.valueOrNull?.finalAnswer.numericValue, 2);
      expect(decimal.valueOrNull?.finalAnswer.numericValue, 2);
    });
  });

  group('pipeline', () {
    test('parses, solves, validates and explains in order', () {
      final Result<Solution> result = _service().solve('2x + 8 = 20');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.finalAnswer.expression, 'x = 6');
      expect(result.valueOrNull?.steps.first.explanation, isNotEmpty);
    });

    test('rejects invalid input without invoking a solver result', () {
      final Result<Solution> result = _service().solve('2 / 0');

      expect(result.failureOrNull, isA<MathParserFailure>());
    });

    test('validator rejects non-finite answers and incomplete steps', () {
      final MathProblem problem = const MathProblem(
        originalInput: '1 + 1',
        normalizedExpression: '2',
        category: MathCategory.arithmetic,
        parsed: ParsedMathExpression(
          original: '1 + 1',
          normalized: '2',
          left: Polynomial(constant: 2),
        ),
      );
      final Solution invalid = Solution(
        problem: problem,
        steps: <SolutionStep>[],
        finalAnswer: FinalAnswer(
          expression: 'undefined',
          numericValue: double.infinity,
        ),
      );

      final Result<void> result = const BasicSolutionValidator().validate(
        problem,
        invalid,
      );

      expect(result.failureOrNull, isA<SolutionValidationFailure>());
    });
  });
}
