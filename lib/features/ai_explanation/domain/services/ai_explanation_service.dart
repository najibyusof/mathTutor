import '../models/ai_explanation_models.dart';
import '../../../solver/domain/models/solution.dart';
import '../../../../core/network/result.dart';

/// Provider boundary. API keys and provider-specific credentials stay on the
/// Laravel backend behind the remote implementation.
abstract interface class AIExplanationProvider {
  Future<AIExplanation> generate(AIExplanationRequest request);

  Future<String> generateHint(AIExplanationRequest request);

  Future<String> identifyConcept(AIExplanationRequest request);

  Future<String> simplify(AIExplanationRequest request);
}

/// Public application service for AI-assisted educational language.
abstract interface class AIExplanationService {
  Future<Result<AIExplanation>> generateExplanation(
    Solution solution, {
    ExplanationDifficulty difficulty = ExplanationDifficulty.intermediate,
  });

  Future<Result<AIHint>> generateHint(
    Solution solution, {
    ExplanationDifficulty difficulty = ExplanationDifficulty.intermediate,
  });

  Future<Result<String>> identifyConcept(Solution solution);

  Future<Result<String>> simplifyExplanation(
    Solution solution, {
    ExplanationDifficulty difficulty = ExplanationDifficulty.beginner,
  });
}
