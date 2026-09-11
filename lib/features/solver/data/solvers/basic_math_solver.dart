import '../../../../core/network/result.dart';
import '../../domain/models/math_problem.dart';
import '../../domain/models/solution.dart';
import '../../domain/services/solver_failures.dart';
import '../../domain/services/solver_services.dart';

/// Solves finite arithmetic and one-variable linear equations.
class BasicMathSolver implements MathSolver {
  const BasicMathSolver();

  @override
  Result<Solution> solve(MathProblem problem) {
    switch (problem.category) {
      case MathCategory.arithmetic:
        return _solveArithmetic(problem);
      case MathCategory.linearEquation:
        return _solveLinear(problem);
      default:
        return const Result<Solution>.failure(
          MathSolverFailure(MathFailureMessages.unsupportedCategory),
        );
    }
  }

  Result<Solution> _solveArithmetic(MathProblem problem) {
    final double value = problem.parsed.left.constant;
    if (!value.isFinite) {
      return const Result<Solution>.failure(
        MathSolverFailure(MathFailureMessages.nonFinite),
      );
    }

    final String result = _format(value);
    return Result<Solution>.success(
      Solution(
        problem: problem,
        steps: <SolutionStep>[
          SolutionStep(
            stepNumber: 1,
            expression: '${problem.normalizedExpression} = $result',
            explanation: 'Evaluate the arithmetic expression.',
            operation: 'calculate',
            result: result,
          ),
        ],
        finalAnswer: FinalAnswer(expression: result, numericValue: value),
      ),
    );
  }

  Result<Solution> _solveLinear(MathProblem problem) {
    final Polynomial left = problem.parsed.left;
    final Polynomial right = problem.parsed.right!;
    final double coefficient = left.linear - right.linear;
    final double constant = right.constant - left.constant;

    if (!coefficient.isFinite || !constant.isFinite) {
      return const Result<Solution>.failure(
        MathSolverFailure(MathFailureMessages.nonFinite),
      );
    }
    if (coefficient == 0 && constant == 0) {
      return const Result<Solution>.failure(
        MathSolverFailure('This equation has infinitely many solutions.'),
      );
    }
    if (coefficient == 0) {
      return const Result<Solution>.failure(
        MathSolverFailure('This equation has no solution.'),
      );
    }

    final double answer = constant / coefficient;
    if (!answer.isFinite) {
      return const Result<Solution>.failure(
        MathSolverFailure(MathFailureMessages.nonFinite),
      );
    }

    final String answerText = _format(answer);
    final String coefficientText = _format(coefficient.abs());
    final String constantText = _format(constant.abs());
    final String signedConstant = constant < 0
        ? '- $constantText'
        : '+ $constantText';

    final List<SolutionStep> steps = <SolutionStep>[
      SolutionStep(
        stepNumber: 1,
        expression:
            '${coefficient < 0 ? '-' : ''}${coefficientText}x $signedConstant = 0',
        explanation: 'Move the constant term to the other side.',
        operation: 'rearrange',
      ),
      SolutionStep(
        stepNumber: 2,
        expression: '${coefficientText}x = ${_format(constant)}',
        explanation: 'Simplify both sides of the equation.',
        operation: 'simplify',
      ),
      SolutionStep(
        stepNumber: 3,
        expression: 'x = $answerText',
        explanation: 'Divide both sides by $coefficientText.',
        operation: 'divide',
        result: answerText,
      ),
    ];

    return Result<Solution>.success(
      Solution(
        problem: problem,
        steps: steps,
        finalAnswer: FinalAnswer(
          expression: 'x = $answerText',
          numericValue: answer,
        ),
      ),
    );
  }

  static String _format(double value) {
    if (!value.isFinite) {
      return 'undefined';
    }
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(6)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
