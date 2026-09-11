import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/errors/failures.dart';
import 'package:mathtutor/core/network/result.dart';
import 'package:mathtutor/features/ai_explanation/domain/models/ai_explanation_models.dart';
import 'package:mathtutor/features/ai_explanation/domain/services/ai_explanation_service.dart';
import 'package:mathtutor/features/ai_explanation/presentation/controllers/ai_explanation_controller.dart';
import 'package:mathtutor/features/solver/domain/models/math_problem.dart';
import 'package:mathtutor/features/solver/domain/models/solution.dart';

const Solution _solution = Solution(
  problem: MathProblem(
    originalInput: '2 + 3',
    normalizedExpression: '2+3',
    category: MathCategory.arithmetic,
    parsed: ParsedMathExpression(
      original: '2 + 3',
      normalized: '5',
      left: Polynomial(constant: 5),
    ),
  ),
  steps: <SolutionStep>[
    SolutionStep(
      stepNumber: 1,
      expression: '2 + 3 = 5',
      explanation: 'Add the numbers.',
    ),
  ],
  finalAnswer: FinalAnswer(expression: '5', numericValue: 5),
);

class _ControllerService implements AIExplanationService {
  _ControllerService({this.shouldFail = false});

  final bool shouldFail;

  @override
  Future<Result<AIExplanation>> generateExplanation(
    Solution solution, {
    ExplanationDifficulty difficulty = ExplanationDifficulty.intermediate,
  }) async {
    if (shouldFail) {
      return const Result<AIExplanation>.failure(
        AIExplanationFailure('AI unavailable.'),
      );
    }
    return const Result<AIExplanation>.success(
      AIExplanation(
        explanation: 'Add the values.',
        concept: 'Arithmetic operations',
        hints: <String>['Add carefully.'],
      ),
    );
  }

  @override
  Future<Result<AIHint>> generateHint(
    Solution solution, {
    ExplanationDifficulty difficulty = ExplanationDifficulty.intermediate,
  }) async => const Result<AIHint>.success(AIHint('Add the values.'));

  @override
  Future<Result<String>> identifyConcept(Solution solution) async =>
      const Result<String>.success('Arithmetic operations');

  @override
  Future<Result<String>> simplifyExplanation(
    Solution solution, {
    ExplanationDifficulty difficulty = ExplanationDifficulty.beginner,
  }) async => const Result<String>.success('Add the values.');
}

void main() {
  test('controller exposes loading and success state', () async {
    final AIExplanationController controller = AIExplanationController(
      _ControllerService(),
    );
    addTearDown(controller.dispose);

    final Future<bool> request = controller.generateExplanation(_solution);
    expect(controller.status, AIExplanationStatus.loading);

    expect(await request, isTrue);
    expect(controller.status, AIExplanationStatus.success);
    expect(controller.explanation?.concept, 'Arithmetic operations');
    expect(controller.hint, 'Add carefully.');
    expect(controller.isLoading, isFalse);
  });

  test('controller exposes a friendly failure state', () async {
    final AIExplanationController controller = AIExplanationController(
      _ControllerService(shouldFail: true),
    );
    addTearDown(controller.dispose);

    expect(await controller.generateExplanation(_solution), isFalse);
    expect(controller.status, AIExplanationStatus.failure);
    expect(
      controller.errorMessage,
      'The explanation service is unavailable. Please try again.',
    );
    expect(controller.isLoading, isFalse);

    controller.clearError();
    expect(controller.status, AIExplanationStatus.idle);
    expect(controller.errorMessage, isNull);
  });
}
