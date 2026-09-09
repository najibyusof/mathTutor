import 'question_input_method.dart';

/// Coarse buckets shown to the student instead of a raw percentage.
enum RecognitionConfidence {
  high('High'),
  medium('Medium'),
  low('Low');

  const RecognitionConfidence(this.label);

  final String label;
}

/// Normalized question produced by every input method.
///
/// Keyboard, handwriting and camera all converge on this model, so review and
/// solving never care where the question came from.
class MathQuestion {
  const MathQuestion({
    required this.id,
    required this.originalInput,
    required this.normalizedExpression,
    required this.inputMethod,
    required this.confidence,
    required this.createdAt,
  });

  final String id;

  /// What the user actually supplied: typed text, a stroke summary or a photo
  /// description.
  final String originalInput;

  /// Solver-friendly expression, e.g. `2*x+5=15`.
  final String normalizedExpression;

  final QuestionInputMethod inputMethod;

  /// `0..1`; typed input is always `1`.
  final double confidence;

  final DateTime createdAt;

  static const double highThreshold = 0.85;
  static const double mediumThreshold = 0.6;

  RecognitionConfidence get confidenceLevel {
    if (confidence >= highThreshold) {
      return RecognitionConfidence.high;
    }
    return confidence >= mediumThreshold
        ? RecognitionConfidence.medium
        : RecognitionConfidence.low;
  }

  /// Low readings must be verified by the student before solving.
  bool get needsVerification => confidenceLevel == RecognitionConfidence.low;

  int get confidencePercent => (confidence * 100).round();

  /// Creates a question, generating an id when none is supplied.
  factory MathQuestion.create({
    required String originalInput,
    required String normalizedExpression,
    required QuestionInputMethod inputMethod,
    double confidence = 1,
    String? id,
    DateTime? createdAt,
  }) {
    final DateTime timestamp = createdAt ?? DateTime.now();
    return MathQuestion(
      id: id ?? 'q-${timestamp.microsecondsSinceEpoch}',
      originalInput: originalInput,
      normalizedExpression: normalizedExpression,
      inputMethod: inputMethod,
      confidence: confidence.clamp(0, 1),
      createdAt: timestamp,
    );
  }

  MathQuestion copyWith({String? normalizedExpression, double? confidence}) =>
      MathQuestion(
        id: id,
        originalInput: originalInput,
        normalizedExpression: normalizedExpression ?? this.normalizedExpression,
        inputMethod: inputMethod,
        confidence: (confidence ?? this.confidence).clamp(0, 1),
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'original_input': originalInput,
    'normalized_expression': normalizedExpression,
    'input_method': inputMethod.name,
    'confidence': confidence,
    'created_at': createdAt.toIso8601String(),
  };

  factory MathQuestion.fromJson(Map<String, dynamic> json) => MathQuestion(
    id: json['id'] as String,
    originalInput: json['original_input'] as String? ?? '',
    normalizedExpression: json['normalized_expression'] as String? ?? '',
    inputMethod: QuestionInputMethod.values.firstWhere(
      (QuestionInputMethod method) => method.name == json['input_method'],
      orElse: () => QuestionInputMethod.keyboard,
    ),
    confidence: (json['confidence'] as num?)?.toDouble() ?? 1,
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
  );
}
