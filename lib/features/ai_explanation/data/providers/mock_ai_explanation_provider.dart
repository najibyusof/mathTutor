import '../../../solver/domain/models/math_problem.dart';
import '../../../solver/domain/models/solution.dart';
import '../../domain/models/ai_explanation_models.dart';
import '../../domain/services/ai_explanation_service.dart';

/// Deterministic provider used until Laravel exposes the AI explanation API.
///
/// It uses solver-provided operations and expressions only; it never computes
/// a new result or changes [Solution.finalAnswer].
class MockAIExplanationProvider implements AIExplanationProvider {
  const MockAIExplanationProvider({this.latency = Duration.zero});

  final Duration latency;

  @override
  Future<AIExplanation> generate(AIExplanationRequest request) async {
    await Future<void>.delayed(latency);
    final String concept = _concept(request.solution.problem.category);
    final String explanation = request.solution.steps
        .map(
          (SolutionStep step) => 'Step ${step.stepNumber}: ${step.explanation}',
        )
        .join(' ');

    return AIExplanation(
      explanation: explanation,
      concept: concept,
      hints: <String>[
        'Look at the operation in each step before doing the arithmetic.',
        'Check the final answer in the original equation.',
      ],
      simplifiedExplanation:
          request.difficulty == ExplanationDifficulty.beginner
          ? 'We change both sides in the same way until the unknown is alone.'
          : null,
    );
  }

  @override
  Future<String> generateHint(AIExplanationRequest request) async {
    await Future<void>.delayed(latency);
    final SolutionStep? next = request.solution.steps.firstOrNull;
    return next == null
        ? 'Start by identifying the operation that keeps both sides equal.'
        : 'Try this step: ${next.explanation}';
  }

  @override
  Future<String> identifyConcept(AIExplanationRequest request) async {
    await Future<void>.delayed(latency);
    return _concept(request.solution.problem.category);
  }

  @override
  Future<String> simplify(AIExplanationRequest request) async {
    await Future<void>.delayed(latency);
    return 'Apply the same operation to both sides, then simplify each side.';
  }

  static String _concept(MathCategory category) => switch (category) {
    MathCategory.arithmetic => 'Arithmetic operations',
    MathCategory.linearEquation => 'Solving a linear equation',
    MathCategory.quadraticEquation => 'Quadratic equations',
    MathCategory.fraction => 'Fractions',
    MathCategory.percentage => 'Percentages',
    MathCategory.simultaneousEquations => 'Simultaneous equations',
    MathCategory.inequality => 'Inequalities',
    MathCategory.powers => 'Powers and exponents',
    MathCategory.roots => 'Roots',
    MathCategory.trigonometry => 'Trigonometry',
    MathCategory.calculus => 'Calculus',
  };
}
