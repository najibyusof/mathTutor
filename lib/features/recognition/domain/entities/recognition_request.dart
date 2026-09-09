import '../../../../features/camera/domain/entities/math_image.dart';
import '../../../../features/handwriting/domain/entities/handwriting_sample.dart';
import '../../../../models/question_input_method.dart';

/// What the student supplied, kept so recognition can be retried unchanged.
sealed class RecognitionRequest {
  const RecognitionRequest();

  QuestionInputMethod get method;

  /// Short human description stored as `MathQuestion.originalInput`.
  String get describeInput;

  /// Typed input needs no engine, so it cannot be retried.
  bool get isRetryable => method.isRecognized;
}

class KeyboardInput extends RecognitionRequest {
  const KeyboardInput(this.expression);

  /// Raw expression from the math keyboard, e.g. `2*x+5=15`.
  final String expression;

  @override
  QuestionInputMethod get method => QuestionInputMethod.keyboard;

  @override
  String get describeInput => expression;
}

class HandwritingInput extends RecognitionRequest {
  const HandwritingInput(this.sample);

  final HandwritingSample sample;

  @override
  QuestionInputMethod get method => QuestionInputMethod.handwriting;

  @override
  String get describeInput =>
      '${sample.strokeCount} handwritten stroke'
      '${sample.strokeCount == 1 ? '' : 's'}';
}

class PhotoInput extends RecognitionRequest {
  const PhotoInput(this.image);

  final MathImage image;

  @override
  QuestionInputMethod get method => QuestionInputMethod.camera;

  @override
  String get describeInput =>
      'Photo ${image.width}×${image.height} '
      '(${image.sizeKb.toStringAsFixed(0)} KB)';
}
