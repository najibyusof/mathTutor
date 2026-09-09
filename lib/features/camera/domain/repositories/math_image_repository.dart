import '../../../../core/network/result.dart';
import '../../../../models/recognition_result.dart';
import '../entities/math_image.dart';

/// Boundary between the capture UI and whichever OCR engine reads the photo.
///
/// The screen never talks to a camera plugin, an OCR SDK or the API directly.
abstract interface class MathImageRepository {
  Future<Result<RecognitionResult>> recognizeMathImage(MathImage image);
}
