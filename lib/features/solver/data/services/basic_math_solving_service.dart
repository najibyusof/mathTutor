import '../../../../core/errors/failures.dart';
import '../../../../core/network/result.dart';
import '../../domain/models/math_problem.dart';
import '../../domain/models/solution.dart';
import '../../domain/services/solver_services.dart';

/// Application-facing pipeline: parse, solve, validate, then explain.
class BasicMathSolvingService {
  const BasicMathSolvingService({
    required this.parser,
    required this.solver,
    required this.validator,
    required this.explainer,
  });

  final MathParser parser;
  final MathSolver solver;
  final SolutionValidator validator;
  final SolutionExplanationService explainer;

  Result<Solution> solve(String input) {
    final Result<MathProblem> parsed = parser.parse(input);
    return parsed.when<Result<Solution>>(
      onSuccess: (MathProblem problem) {
        final Result<Solution> solved = solver.solve(problem);
        return solved.when<Result<Solution>>(
          onSuccess: (Solution solution) {
            final Result<void> validation = validator.validate(
              problem,
              solution,
            );
            return validation.when<Result<Solution>>(
              onSuccess: (_) => Result<Solution>.success(
                Solution(
                  problem: problem,
                  steps: explainer.explain(solution),
                  finalAnswer: solution.finalAnswer,
                ),
              ),
              onFailure: (Failure failure) => Result<Solution>.failure(failure),
            );
          },
          onFailure: (Failure failure) => Result<Solution>.failure(failure),
        );
      },
      onFailure: (Failure failure) => Result<Solution>.failure(failure),
    );
  }
}
