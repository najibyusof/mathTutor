import 'question_input_method.dart';

/// A math question entered by the user.
///
/// Only the fields needed by the UI exist in this phase; solving data is added
/// when the solver feature is implemented.
class MathQuestion {
  const MathQuestion({
    required this.id,
    required this.expression,
    required this.topic,
    required this.inputMethod,
    required this.createdAt,
    this.answerPreview,
  });

  final String id;
  final String expression;
  final String topic;
  final QuestionInputMethod inputMethod;
  final DateTime createdAt;

  /// Short answer summary shown in lists; `null` while unsolved.
  final String? answerPreview;

  bool get isSolved => answerPreview != null;
}
