import '../../../solver/domain/models/solution.dart';

/// Difficulty target for generated educational language.
enum ExplanationDifficulty { beginner, intermediate, advanced }

/// Structured solver output sent to an explanation provider.
class AIExplanationRequest {
  const AIExplanationRequest({
    required this.solution,
    this.difficulty = ExplanationDifficulty.intermediate,
  });

  final Solution solution;
  final ExplanationDifficulty difficulty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'problem': <String, dynamic>{
      'original_input': solution.problem.originalInput,
      'normalized_expression': solution.problem.normalizedExpression,
      'category': solution.problem.category.name,
    },
    'solution': solution.finalAnswer.expression,
    'steps': solution.steps
        .map(
          (SolutionStep step) => <String, dynamic>{
            'step_number': step.stepNumber,
            'expression': step.expression,
            'explanation': step.explanation,
            'operation': step.operation,
            'result': step.result,
          },
        )
        .toList(growable: false),
    'difficulty': difficulty.name,
  };
}

/// Provider output. The provider can enrich language, but the final answer is
/// always retained from the deterministic [Solution].
class AIExplanation {
  const AIExplanation({
    required this.explanation,
    required this.concept,
    this.hints = const <String>[],
    this.simplifiedExplanation,
  });

  final String explanation;
  final String concept;
  final List<String> hints;
  final String? simplifiedExplanation;

  factory AIExplanation.fromJson(Map<String, dynamic> json) {
    final String? explanation = json['explanation'] as String?;
    final String? concept = json['concept'] as String?;
    if (explanation == null || explanation.trim().isEmpty) {
      throw const FormatException('AI response is missing an explanation.');
    }
    if (concept == null || concept.trim().isEmpty) {
      throw const FormatException('AI response is missing a concept.');
    }

    final Object? rawHints = json['hints'];
    final List<String> hints = rawHints is List
        ? rawHints
              .whereType<String>()
              .where((String hint) => hint.trim().isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    return AIExplanation(
      explanation: explanation.trim(),
      concept: concept.trim(),
      hints: hints,
      simplifiedExplanation: (json['simplified_explanation'] as String?)
          ?.trim(),
    );
  }
}

class AIHint {
  const AIHint(this.text);

  final String text;
}
