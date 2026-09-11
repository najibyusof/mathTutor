import '../../../../core/network/result.dart';
import '../models/math_problem.dart';
import '../models/solution.dart';

/// Parses input without attempting to solve it.
abstract interface class MathParser {
  Result<MathProblem> parse(String input);
}

/// Calculates a solution from a parsed problem.
abstract interface class MathSolver {
  Result<Solution> solve(MathProblem problem);
}

/// Checks that a solution is finite, coherent and valid for its problem.
abstract interface class SolutionValidator {
  Result<void> validate(MathProblem problem, Solution solution);
}

/// Converts a validated solution into student-facing explanation copy.
abstract interface class SolutionExplanationService {
  List<SolutionStep> explain(Solution solution);
}
