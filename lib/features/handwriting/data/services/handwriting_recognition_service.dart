import '../../domain/entities/handwriting_sample.dart';
import '../../domain/entities/recognition_result.dart';

/// Engine contract. Implementations throw `AppException`s; the repository
/// converts them into failures.
abstract interface class HandwritingRecognitionService {
  Future<RecognitionResult> recognize(HandwritingSample sample);
}
