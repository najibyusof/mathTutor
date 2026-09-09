import '../../../../models/recognition_result.dart';
import '../../domain/entities/math_image.dart';

/// OCR engine contract. Implementations throw `AppException`s; the repository
/// converts them into failures.
abstract interface class MathImageRecognitionService {
  Future<RecognitionResult> recognize(MathImage image);
}
