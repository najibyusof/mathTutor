import '../../../../core/network/result.dart';
import '../../domain/models/math_problem.dart';
import '../../domain/models/solution.dart';
import '../../domain/services/solver_failures.dart';
import '../../domain/services/solver_services.dart';

/// Validates every numeric value and confirms the basic solver's contract.
class BasicSolutionValidator implements SolutionValidator {
  const BasicSolutionValidator();

  @override
  Result<void> validate(MathProblem problem, Solution solution) {
    if (!solution.finalAnswer.hasFiniteNumericValue) {
      return const Result<void>.failure(
        SolutionValidationFailure(MathFailureMessages.nonFinite),
      );
    }
    if (solution.steps.isEmpty) {
      return const Result<void>.failure(
        SolutionValidationFailure('A solution must contain at least one step.'),
      );
    }
    for (final SolutionStep step in solution.steps) {
      if (step.stepNumber < 1 ||
          step.expression.trim().isEmpty ||
          step.explanation.trim().isEmpty) {
        return const Result<void>.failure(
          SolutionValidationFailure(
            'The solution contains an incomplete step.',
          ),
        );
      }
    }
    if (problem.category == MathCategory.linearEquation &&
        solution.finalAnswer.numericValue != null) {
      final double answer = solution.finalAnswer.numericValue!;
      final Polynomial left = problem.parsed.left;
      final Polynomial right = problem.parsed.right!;
      final double residual =
          (left.linear * answer + left.constant) -
          (right.linear * answer + right.constant);
      if (!residual.isFinite || residual.abs() > 0.000001) {
        return const Result<void>.failure(
          SolutionValidationFailure(
            'The final answer does not satisfy the equation.',
          ),
        );
      }
    }
    return const Result<void>.success(null);
  }
}
