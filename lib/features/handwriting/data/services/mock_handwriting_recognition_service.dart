import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/handwriting_sample.dart';
import '../../domain/entities/recognition_result.dart';
import 'handwriting_recognition_service.dart';

/// Returns sample expressions so the handwriting flow is testable before any
/// OCR/AI engine exists. Selection is deterministic, never random.
class MockHandwritingRecognitionService
    implements HandwritingRecognitionService {
  const MockHandwritingRecognitionService({
    this.latency = const Duration(milliseconds: 900),
  });

  final Duration latency;

  static const List<RecognitionResult> samples = <RecognitionResult>[
    RecognitionResult(
      expression: '2*x+5=15',
      confidence: 0.94,
      alternatives: <String>['2*x+5=16', '2*x+6=15'],
    ),
    RecognitionResult(
      expression: '(x+3)/2=7',
      confidence: 0.88,
      alternatives: <String>['(x+3)/2=1', '(x+8)/2=7'],
    ),
    RecognitionResult(
      expression: 'x^(2)+5*x+6=0',
      confidence: 0.91,
      alternatives: <String>['x^(2)+5*x+8=0'],
    ),
    RecognitionResult(
      expression: 'sqrt(49)+12',
      confidence: 0.76,
      alternatives: <String>['sqrt(48)+12'],
    ),
  ];

  @override
  Future<RecognitionResult> recognize(HandwritingSample sample) async {
    if (sample.isEmpty) {
      throw const ValidationException(
        'Write a question before submitting it.',
        statusCode: 422,
      );
    }

    await Future<void>.delayed(latency);
    return samples[sample.strokeCount % samples.length];
  }
}
