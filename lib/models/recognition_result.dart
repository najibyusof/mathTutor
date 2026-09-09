/// What a recognition engine (handwriting or image OCR) made of an input.
///
/// Shared by every input method so the recognized expression can be handed to
/// the math editor for review before solving.
class RecognitionResult {
  const RecognitionResult({
    required this.expression,
    this.confidence = 0,
    this.alternatives = const <String>[],
  });

  /// Recognized expression in solver-friendly form, e.g. `2*x+5=15`.
  final String expression;

  /// `0..1` certainty reported by the engine.
  final double confidence;

  /// Other candidates, best first.
  final List<String> alternatives;

  bool get isConfident => confidence >= 0.8;

  factory RecognitionResult.fromJson(Map<String, dynamic> json) {
    final Object? alternatives = json['alternatives'];

    return RecognitionResult(
      expression: json['expression'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      alternatives: alternatives is List
          ? alternatives.map((Object? item) => '$item').toList(growable: false)
          : const <String>[],
    );
  }
}
