import '../../../../core/errors/exceptions.dart';
import '../../../../models/recognition_result.dart';
import '../../domain/entities/math_image.dart';
import 'math_image_recognition_service.dart';

/// Returns sample expressions so the scan flow works before any OCR engine
/// exists. Selection is deterministic, never random.
class MockMathImageRecognitionService implements MathImageRecognitionService {
  const MockMathImageRecognitionService({
    this.latency = const Duration(milliseconds: 1200),
  });

  final Duration latency;

  static const List<RecognitionResult> samples = <RecognitionResult>[
    RecognitionResult(
      expression: '3*x-7=14',
      confidence: 0.93,
      alternatives: <String>['3*x-7=11', '8*x-7=14'],
    ),
    RecognitionResult(
      expression: 'x^(2)-9=0',
      confidence: 0.87,
      alternatives: <String>['x^(2)-8=0'],
    ),
    RecognitionResult(
      expression: '(2*x+4)/6=3',
      confidence: 0.81,
      alternatives: <String>['(2*x+4)/5=3'],
    ),
    RecognitionResult(
      expression: '15%*200',
      confidence: 0.74,
      alternatives: <String>['15%*260'],
    ),
  ];

  @override
  Future<RecognitionResult> recognize(MathImage image) async {
    if (image.sizeBytes == 0) {
      throw const InvalidImageException('That picture appears to be empty.');
    }

    await Future<void>.delayed(latency);
    return samples[image.sizeBytes % samples.length];
  }
}
