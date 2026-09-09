/// What the recognition engine made of a handwriting sample.
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
