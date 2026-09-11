import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/result.dart';
import '../../../../models/math_question.dart';
import '../../../../models/question_input_method.dart';
import '../../../solver/data/parsers/basic_math_parser.dart';
import '../../../solver/domain/models/math_problem.dart';
import '../../../solver/domain/models/solution.dart';

/// DTO for Laravel math question/history payloads.
class MathQuestionDto {
  const MathQuestionDto(this.question);

  final MathQuestion question;

  factory MathQuestionDto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> payload = _payload(json);
    final Object? id = payload['id'];
    if (id == null) {
      throw const ParsingException('The math question response has no id.');
    }
    return MathQuestionDto(
      MathQuestion(
        id: '$id',
        originalInput:
            payload['original_expression'] as String? ??
            payload['original_input'] as String? ??
            payload['question'] as String? ??
            '',
        normalizedExpression:
            payload['normalized_expression'] as String? ??
            payload['expression'] as String? ??
            '',
        inputMethod: QuestionInputMethod.values.firstWhere(
          (QuestionInputMethod method) =>
              method.name == payload['input_method'],
          orElse: () => QuestionInputMethod.keyboard,
        ),
        confidence:
            (payload['recognition_confidence'] as num?)?.toDouble() ??
            (payload['confidence'] as num?)?.toDouble() ??
            1,
        createdAt:
            DateTime.tryParse(payload['created_at'] as String? ?? '') ??
            DateTime.now(),
      ),
    );
  }

  Map<String, dynamic> toJson() => question.toJson();

  /// Body for `POST /questions`. The real API expects `original_expression`
  /// (required) and `input_method` (required); `user_id` must never be sent.
  Map<String, dynamic> toCreateJson() => <String, dynamic>{
    'original_expression': question.originalInput,
    if (question.normalizedExpression.isNotEmpty)
      'normalized_expression': question.normalizedExpression,
    'input_method': question.inputMethod.name,
    if (question.confidence != 1) 'recognition_confidence': question.confidence,
  };
}

/// DTO that turns the Laravel structured solution into the domain model.
class SolutionDto {
  const SolutionDto(this.solution);

  final Solution solution;

  factory SolutionDto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> payload = _payload(json);
    final Object? rawSolution = payload['solution'];
    final int? solutionId = rawSolution is Map<String, dynamic>
        ? (rawSolution['id'] as num?)?.toInt()
        : null;
    final String expression =
        payload['normalized_expression'] as String? ??
        payload['expression'] as String? ??
        (payload['problem'] is String ? payload['problem'] as String : null) ??
        payload['question'] as String? ??
        '';
    final Result<MathProblem> parsed = const BasicMathParser().parse(
      expression,
    );
    final MathProblem? problem = parsed.valueOrNull;
    if (problem == null) {
      throw const ParsingException('The solution problem could not be parsed.');
    }

    final Object? rawSteps = payload['steps'] ?? payload['solution_steps'];
    if (rawSteps is! List) {
      throw const ParsingException('The solution response has no steps.');
    }
    final List<SolutionStep> steps = rawSteps
        .map((Object? item) {
          if (item is! Map<String, dynamic>) {
            throw const ParsingException('A solution step was malformed.');
          }
          final int? number = (item['step_number'] as num?)?.toInt();
          final String? stepExpression = item['expression'] as String?;
          final String? explanation = item['explanation'] as String?;
          if (number == null || stepExpression == null || explanation == null) {
            throw const ParsingException('A solution step was incomplete.');
          }
          return SolutionStep(
            stepNumber: number,
            expression: stepExpression,
            explanation: explanation,
            operation: item['operation'] as String?,
            result: item['result'] as String?,
          );
        })
        .toList(growable: false);

    final Object? rawAnswer = payload['final_answer'] ?? payload['answer'];
    final String answer;
    final double? numeric;
    if (rawAnswer is Map<String, dynamic>) {
      answer = rawAnswer['expression'] as String? ?? '';
      numeric = (rawAnswer['numeric_value'] as num?)?.toDouble();
    } else if (rawAnswer is String) {
      answer = rawAnswer;
      numeric = null;
    } else {
      throw const ParsingException(
        'The solution response has no final answer.',
      );
    }
    if (answer.trim().isEmpty) {
      throw const ParsingException('The final answer was empty.');
    }

    return SolutionDto(
      Solution(
        problem: problem,
        steps: steps,
        finalAnswer: FinalAnswer(expression: answer, numericValue: numeric),
        id: solutionId,
      ),
    );
  }
}

Map<String, dynamic> _payload(Map<String, dynamic> json) {
  final Object? data = json['data'];
  return data is Map<String, dynamic> ? data : json;
}
