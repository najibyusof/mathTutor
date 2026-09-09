import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/errors/exceptions.dart';
import 'package:mathtutor/core/errors/failures.dart';
import 'package:mathtutor/core/network/result.dart';
import 'package:mathtutor/features/handwriting/data/repositories/handwriting_repository_impl.dart';
import 'package:mathtutor/features/handwriting/data/services/handwriting_recognition_service.dart';
import 'package:mathtutor/features/handwriting/data/services/mock_handwriting_recognition_service.dart';
import 'package:mathtutor/features/handwriting/domain/entities/handwriting_sample.dart';
import 'package:mathtutor/models/recognition_result.dart';
import 'package:mathtutor/features/handwriting/domain/entities/stroke.dart';
import 'package:mathtutor/features/handwriting/domain/repositories/handwriting_repository.dart';

/// Engine stub that either returns a result or throws.
class _StubService implements HandwritingRecognitionService {
  _StubService({this.result, this.error});

  final RecognitionResult? result;
  final Object? error;
  HandwritingSample? received;

  @override
  Future<RecognitionResult> recognize(HandwritingSample sample) async {
    received = sample;
    if (error != null) {
      throw error!;
    }
    return result!;
  }
}

Stroke _stroke(List<Offset> points) => Stroke(
  points: points.map(StrokePoint.new).toList(growable: false),
);

void main() {
  group('HandwritingSample', () {
    test('normalizes points to the 0..1 range', () {
      final HandwritingSample sample = HandwritingSample.fromStrokes(
        <Stroke>[
          _stroke(<Offset>[const Offset(0, 0), const Offset(100, 50)]),
        ],
        const Size(200, 100),
      );

      expect(sample.strokeCount, 1);
      expect(sample.strokes.first, <List<double>>[
        <double>[0, 0],
        <double>[0.5, 0.5],
      ]);
    });

    test('serializes strokes without any image data', () {
      final Map<String, dynamic> json = HandwritingSample.fromStrokes(
        <Stroke>[
          _stroke(<Offset>[const Offset(10, 10)]),
        ],
        const Size(100, 100),
      ).toJson();

      expect(json.keys, containsAll(<String>['canvas', 'strokes']));
      expect(json.toString(), isNot(contains('image')));
    });
  });

  group('mock recognition service', () {
    test('returns a sample expression deterministically', () async {
      const MockHandwritingRecognitionService service =
          MockHandwritingRecognitionService(latency: Duration.zero);

      final RecognitionResult result = await service.recognize(
        HandwritingSample.fromStrokes(
          <Stroke>[
            _stroke(<Offset>[const Offset(1, 1)]),
          ],
          const Size(100, 100),
        ),
      );

      expect(result.expression, MockHandwritingRecognitionService
          .samples[1]
          .expression);
      expect(result.confidence, greaterThan(0));
    });

    test('rejects an empty sample', () {
      const MockHandwritingRecognitionService service =
          MockHandwritingRecognitionService(latency: Duration.zero);

      expect(
        () => service.recognize(
          HandwritingSample.fromStrokes(const <Stroke>[], const Size(10, 10)),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('HandwritingRepositoryImpl', () {
    test('passes the sample through and returns the result', () async {
      final _StubService service = _StubService(
        result: const RecognitionResult(expression: '1+1=2', confidence: 0.9),
      );
      final HandwritingRepository repository = HandwritingRepositoryImpl(
        service,
      );

      final Result<RecognitionResult> result = await repository
          .recognizeHandwriting(
            HandwritingSample.fromStrokes(
              <Stroke>[
                _stroke(<Offset>[const Offset(5, 5)]),
              ],
              const Size(50, 50),
            ),
          );

      expect(result.valueOrNull?.expression, '1+1=2');
      expect(service.received?.strokeCount, 1);
    });

    test('maps engine errors onto failures', () async {
      final HandwritingRepository repository = HandwritingRepositoryImpl(
        _StubService(error: const NetworkException('offline')),
      );

      final Result<RecognitionResult> result = await repository
          .recognizeHandwriting(
            HandwritingSample.fromStrokes(const <Stroke>[], Size.zero),
          );

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('treats an empty expression as a failure', () async {
      final HandwritingRepository repository = HandwritingRepositoryImpl(
        _StubService(result: const RecognitionResult(expression: '')),
      );

      final Result<RecognitionResult> result = await repository
          .recognizeHandwriting(
            HandwritingSample.fromStrokes(const <Stroke>[], Size.zero),
          );

      expect(result.failureOrNull, isA<UnexpectedFailure>());
    });
  });
}
