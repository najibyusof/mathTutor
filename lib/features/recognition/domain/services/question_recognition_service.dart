import '../../../../core/network/result.dart';
import '../../../../models/math_question.dart';
import '../entities/recognition_request.dart';

/// One entry point for all three input methods.
///
/// Whatever the source, the caller gets the same normalized [MathQuestion],
/// which is what the review and solve steps work with.
abstract interface class QuestionRecognitionService {
  Future<Result<MathQuestion>> recognize(RecognitionRequest request);
}
