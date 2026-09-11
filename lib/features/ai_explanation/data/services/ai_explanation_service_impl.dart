import 'dart:async';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/result.dart';
import '../../domain/models/ai_explanation_models.dart';
import '../../domain/services/ai_explanation_service.dart';
import '../../../solver/domain/models/solution.dart';

/// Adds timeout, bounded retry and failure normalization around a provider.
class AIExplanationServiceImpl implements AIExplanationService {
  const AIExplanationServiceImpl(
    this._provider, {
    this.timeout = const Duration(seconds: 12),
    this.maxRetries = 2,
  });

  final AIExplanationProvider _provider;
  final Duration timeout;
  final int maxRetries;

  @override
  Future<Result<AIExplanation>> generateExplanation(
    Solution solution, {
    ExplanationDifficulty difficulty = ExplanationDifficulty.intermediate,
  }) => _run<AIExplanation>(
    () => _provider.generate(
      AIExplanationRequest(solution: solution, difficulty: difficulty),
    ),
  );

  @override
  Future<Result<AIHint>> generateHint(
    Solution solution, {
    ExplanationDifficulty difficulty = ExplanationDifficulty.intermediate,
  }) =>
      _run<String>(
        () => _provider.generateHint(
          AIExplanationRequest(solution: solution, difficulty: difficulty),
        ),
      ).then(
        (Result<String> result) => result.when<Result<AIHint>>(
          onSuccess: (String text) => Result<AIHint>.success(AIHint(text)),
          onFailure: (Failure failure) => Result<AIHint>.failure(failure),
        ),
      );

  @override
  Future<Result<String>> identifyConcept(Solution solution) => _run<String>(
    () => _provider.identifyConcept(AIExplanationRequest(solution: solution)),
  );

  @override
  Future<Result<String>> simplifyExplanation(
    Solution solution, {
    ExplanationDifficulty difficulty = ExplanationDifficulty.beginner,
  }) => _run<String>(
    () => _provider.simplify(
      AIExplanationRequest(solution: solution, difficulty: difficulty),
    ),
  );

  Future<Result<T>> _run<T>(Future<T> Function() operation) async {
    final int attempts = maxRetries < 0 ? 1 : maxRetries + 1;
    Failure? lastFailure;

    for (int attempt = 0; attempt < attempts; attempt++) {
      try {
        final T value = await operation().timeout(timeout);
        if (value is String && value.trim().isEmpty) {
          return Result<T>.failure(
            const AIResponseFailure('The AI returned an empty response.'),
          );
        }
        return Result<T>.success(value);
      } on TimeoutException {
        lastFailure = const AIExplanationFailure(
          'The explanation service took too long. Please try again.',
        );
      } on FormatException catch (error) {
        return Result<T>.failure(AIResponseFailure(error.message));
      } on AppException catch (error) {
        lastFailure = mapExceptionToFailure(error);
      } catch (error) {
        lastFailure = AIExplanationFailure(error.toString());
      }

      if (!_isRetryable(lastFailure) || attempt == attempts - 1) {
        break;
      }
    }

    return Result<T>.failure(
      lastFailure ??
          const AIExplanationFailure(
            'The explanation service is unavailable. Please try again.',
          ),
    );
  }

  bool _isRetryable(Failure? failure) =>
      failure is NetworkFailure ||
      failure is ServerFailure ||
      failure is AIExplanationFailure;
}
