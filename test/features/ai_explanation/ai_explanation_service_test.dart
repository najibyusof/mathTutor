import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/errors/exceptions.dart';
import 'package:mathtutor/core/errors/failures.dart';
import 'package:mathtutor/core/network/result.dart';
import 'package:mathtutor/features/ai_explanation/data/providers/mock_ai_explanation_provider.dart';
import 'package:mathtutor/features/ai_explanation/data/services/ai_explanation_service_impl.dart';
import 'package:mathtutor/features/ai_explanation/domain/models/ai_explanation_models.dart';
import 'package:mathtutor/features/ai_explanation/domain/services/ai_explanation_service.dart';
import 'package:mathtutor/features/solver/domain/models/math_problem.dart';
import 'package:mathtutor/features/solver/domain/models/solution.dart';

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

class _FakeProvider implements AIExplanationProvider {
  _FakeProvider({this.failuresBeforeSuccess = 0, this.error, this.delay});

  final int failuresBeforeSuccess;
  final Object? error;
  final Duration? delay;
  int calls = 0;

  @override
  Future<AIExplanation> generate(AIExplanationRequest request) async {
    calls++;
    if (delay != null) {
      await Future<void>.delayed(delay!);
    }
    if (calls <= failuresBeforeSuccess) {
      throw const NetworkException('temporary failure');
    }
    if (error != null) {
      throw error!;
    }
    return const AIExplanation(
      explanation: 'Keep both sides balanced.',
      concept: 'Linear equations',
      hints: <String>['Subtract the constant first.'],
    );
  }

  @override
  Future<String> generateHint(AIExplanationRequest request) async =>
      'Look at both sides.';

  @override
  Future<String> identifyConcept(AIExplanationRequest request) async =>
      'Linear equations';

  @override
  Future<String> simplify(AIExplanationRequest request) async =>
      'Keep both sides balanced.';
}

void main() {
  test('mock provider consumes structured solver output', () async {
    const MockAIExplanationProvider provider = MockAIExplanationProvider();

    final AIExplanation result = await provider.generate(
      const AIExplanationRequest(
        solution: _solution,
        difficulty: ExplanationDifficulty.beginner,
      ),
    );

    expect(result.concept, 'Solving a linear equation');
    expect(result.explanation, contains('Subtract 8 from both sides.'));
    expect(result.simplifiedExplanation, isNotNull);
    expect(_solution.finalAnswer.expression, 'x = 6');
  });

  test(
    'request serializes structured problem and steps, not only raw text',
    () {
      final Map<String, dynamic> json = const AIExplanationRequest(
        solution: _solution,
      ).toJson();

      expect(json['problem'], isA<Map<String, dynamic>>());
      expect(json['solution'], 'x = 6');
      expect(json['steps'], hasLength(3));
      expect(json['difficulty'], 'intermediate');
    },
  );

  test('retries a transient provider failure and succeeds', () async {
    final _FakeProvider provider = _FakeProvider(failuresBeforeSuccess: 1);
    final AIExplanationService service = AIExplanationServiceImpl(
      provider,
      timeout: const Duration(seconds: 1),
      maxRetries: 2,
    );

    final Result<AIExplanation> result = await service.generateExplanation(
      _solution,
    );

    expect(result.isSuccess, isTrue);
    expect(provider.calls, 2);
  });

  test('returns a provider failure after retry budget is exhausted', () async {
    final _FakeProvider provider = _FakeProvider(failuresBeforeSuccess: 5);
    final AIExplanationService service = AIExplanationServiceImpl(
      provider,
      timeout: const Duration(seconds: 1),
      maxRetries: 2,
    );

    final Result<AIExplanation> result = await service.generateExplanation(
      _solution,
    );

    expect(result.failureOrNull, isA<NetworkFailure>());
    expect(provider.calls, 3);
  });

  test('does not retry malformed provider responses', () async {
    final _FakeProvider provider = _FakeProvider(
      error: const FormatException('missing explanation'),
    );
    final AIExplanationService service = AIExplanationServiceImpl(
      provider,
      maxRetries: 3,
    );

    final Result<AIExplanation> result = await service.generateExplanation(
      _solution,
    );

    expect(result.failureOrNull, isA<AIResponseFailure>());
    expect(provider.calls, 1);
  });

  test('maps timeout to a retryable AI failure', () async {
    final _FakeProvider provider = _FakeProvider(
      delay: const Duration(milliseconds: 50),
    );
    final AIExplanationService service = AIExplanationServiceImpl(
      provider,
      timeout: const Duration(milliseconds: 1),
      maxRetries: 1,
    );

    final Result<AIExplanation> result = await service.generateExplanation(
      _solution,
    );

    expect(result.failureOrNull, isA<AIExplanationFailure>());
    expect(provider.calls, 2);
  });

  test(
    'supports hint, concept and simplified explanation operations',
    () async {
      final AIExplanationService service = AIExplanationServiceImpl(
        _FakeProvider(),
      );

      expect(
        (await service.generateHint(_solution)).valueOrNull?.text,
        isNotEmpty,
      );
      expect(
        (await service.identifyConcept(_solution)).valueOrNull,
        'Linear equations',
      );
      expect(
        (await service.simplifyExplanation(_solution)).valueOrNull,
        isNotEmpty,
      );
    },
  );
}
