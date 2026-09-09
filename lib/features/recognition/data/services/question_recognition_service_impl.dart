import '../../../../core/errors/failures.dart';
import '../../../../core/network/result.dart';
import '../../../../models/math_question.dart';
import '../../../../models/recognition_result.dart';
import '../../../camera/domain/entities/math_image.dart';
import '../../../camera/domain/repositories/math_image_repository.dart';
import '../../../handwriting/domain/entities/handwriting_sample.dart';
import '../../../handwriting/domain/repositories/handwriting_repository.dart';
import '../../domain/entities/recognition_request.dart';
import '../../domain/services/question_recognition_service.dart';

/// Routes each request to the matching engine and normalizes the answer.
class QuestionRecognitionServiceImpl implements QuestionRecognitionService {
  const QuestionRecognitionServiceImpl({
    required HandwritingRepository handwriting,
    required MathImageRepository image,
  }) : _handwriting = handwriting,
       _image = image;

  final HandwritingRepository _handwriting;
  final MathImageRepository _image;

  @override
  Future<Result<MathQuestion>> recognize(RecognitionRequest request) async {
    return switch (request) {
      KeyboardInput(:final String expression) => _fromKeyboard(
        request,
        expression,
      ),
      HandwritingInput(:final HandwritingSample sample) => _toQuestion(
        request,
        await _handwriting.recognizeHandwriting(sample),
      ),
      PhotoInput(:final MathImage image) => _toQuestion(
        request,
        await _image.recognizeMathImage(image),
      ),
    };
  }

  Result<MathQuestion> _fromKeyboard(
    RecognitionRequest request,
    String expression,
  ) {
    if (expression.trim().isEmpty) {
      return const Result<MathQuestion>.failure(
        ValidationFailure('Enter a question before continuing.'),
      );
    }
    return Result<MathQuestion>.success(
      MathQuestion.create(
        originalInput: request.describeInput,
        normalizedExpression: expression.trim(),
        inputMethod: request.method,
      ),
    );
  }

  Result<MathQuestion> _toQuestion(
    RecognitionRequest request,
    Result<RecognitionResult> result,
  ) {
    return result.when<Result<MathQuestion>>(
      onSuccess: (RecognitionResult value) => Result<MathQuestion>.success(
        MathQuestion.create(
          originalInput: request.describeInput,
          normalizedExpression: value.expression,
          inputMethod: request.method,
          confidence: value.confidence,
        ),
      ),
      onFailure: (Failure failure) => Result<MathQuestion>.failure(failure),
    );
  }
}
