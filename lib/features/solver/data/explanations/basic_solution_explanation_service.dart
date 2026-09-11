import '../../domain/models/solution.dart';
import '../../domain/services/solver_services.dart';

/// Default explanation service for the current rule-based solver.
///
/// It returns the solver's auditable steps; a richer localization layer can be
/// introduced later without changing parsing or calculation.
class BasicSolutionExplanationService implements SolutionExplanationService {
  const BasicSolutionExplanationService();

  @override
  List<SolutionStep> explain(Solution solution) => solution.steps;
}
