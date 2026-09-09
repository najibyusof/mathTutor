import '../../../../core/network/result.dart';
import '../entities/handwriting_sample.dart';
import '../../../../models/recognition_result.dart';

/// Boundary between the drawing UI and whichever engine reads the strokes.
///
/// The canvas never talks to a service or the API directly; swapping the mock
/// engine for a real one requires no UI change.
abstract interface class HandwritingRepository {
  Future<Result<RecognitionResult>> recognizeHandwriting(
    HandwritingSample sample,
  );
}
