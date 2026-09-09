import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/errors/exceptions.dart';
import 'package:mathtutor/core/errors/failures.dart';
import 'package:mathtutor/core/network/result.dart';
import 'package:mathtutor/features/camera/domain/entities/math_image.dart';
import 'package:mathtutor/features/camera/domain/repositories/math_image_repository.dart';
import 'package:mathtutor/features/handwriting/domain/entities/handwriting_sample.dart';
import 'package:mathtutor/features/handwriting/domain/entities/stroke.dart';
import 'package:mathtutor/features/handwriting/domain/repositories/handwriting_repository.dart';
import 'package:mathtutor/features/recognition/data/services/question_recognition_service_impl.dart';
import 'package:mathtutor/features/recognition/domain/entities/recognition_request.dart';
import 'package:mathtutor/features/recognition/domain/services/question_recognition_service.dart';
import 'package:mathtutor/models/math_question.dart';
import 'package:mathtutor/models/question_input_method.dart';
import 'package:mathtutor/models/recognition_result.dart';

class _StubHandwriting implements HandwritingRepository {
  _StubHandwriting({this.result, this.failure});

  final RecognitionResult? result;
  final Failure? failure;
  int calls = 0;

  @override
  Future<Result<RecognitionResult>> recognizeHandwriting(
    HandwritingSample sample,
  ) async {
    calls++;
    return failure != null
        ? Result<RecognitionResult>.failure(failure!)
        : Result<RecognitionResult>.success(result!);
  }
}

class _StubImage implements MathImageRepository {
  _StubImage({this.result});

  final RecognitionResult? result;
  int calls = 0;

  @override
  Future<Result<RecognitionResult>> recognizeMathImage(MathImage image) async {
    calls++;
    return Result<RecognitionResult>.success(result!);
  }
}

HandwritingSample _sample() => HandwritingSample.fromStrokes(
  <Stroke>[
    Stroke(
      points: const <StrokePoint>[
        StrokePoint(Offset(0, 0)),
        StrokePoint(Offset(10, 10)),
      ],
    ),
  ],
  const Size(100, 100),
);

MathImage _image() => MathImage(
  bytes: Uint8List.fromList(<int>[1, 2, 3]),
  width: 1600,
  height: 1200,
  source: MathImageSource.camera,
);

void main() {
  group('MathQuestion', () {
    test('buckets confidence into high, medium and low', () {
      MathQuestion build(double confidence) => MathQuestion.create(
        originalInput: 'photo',
        normalizedExpression: '1+1=2',
        inputMethod: QuestionInputMethod.camera,
        confidence: confidence,
      );

      expect(build(0.95).confidenceLevel, RecognitionConfidence.high);
      expect(build(0.85).confidenceLevel, RecognitionConfidence.high);
      expect(build(0.7).confidenceLevel, RecognitionConfidence.medium);
      expect(build(0.4).confidenceLevel, RecognitionConfidence.low);
      expect(build(0.4).needsVerification, isTrue);
      expect(build(0.9).needsVerification, isFalse);
      expect(build(0.9).confidencePercent, 90);
    });

    test('generates an id and defaults typed input to full confidence', () {
      final MathQuestion question = MathQuestion.create(
        originalInput: '2x + 5 = 15',
        normalizedExpression: '2*x+5=15',
        inputMethod: QuestionInputMethod.keyboard,
      );

      expect(question.id, isNotEmpty);
      expect(question.confidence, 1);
      expect(question.confidenceLevel, RecognitionConfidence.high);
      expect(question.inputMethod.isRecognized, isFalse);
    });

    test('round-trips through JSON with the input method name', () {
      final MathQuestion question = MathQuestion.create(
        id: 'q-7',
        originalInput: '4 handwritten strokes',
        normalizedExpression: '3*x-7=14',
        inputMethod: QuestionInputMethod.handwriting,
        confidence: 0.72,
        createdAt: DateTime(2026, 3, 18, 10),
      );

      final Map<String, dynamic> json = question.toJson();
      expect(json['input_method'], 'handwriting');

      final MathQuestion restored = MathQuestion.fromJson(json);
      expect(restored.id, 'q-7');
      expect(restored.normalizedExpression, '3*x-7=14');
      expect(restored.inputMethod, QuestionInputMethod.handwriting);
      expect(restored.confidence, closeTo(0.72, 0.001));
      expect(restored.createdAt, question.createdAt);
    });

    test('copyWith keeps identity while updating the expression', () {
      final MathQuestion question = MathQuestion.create(
        id: 'q-1',
        originalInput: 'photo',
        normalizedExpression: '2*x=9',
        inputMethod: QuestionInputMethod.camera,
        confidence: 0.5,
      );

      final MathQuestion edited = question.copyWith(
        normalizedExpression: '2*x=8',
        confidence: 1,
      );

      expect(edited.id, 'q-1');
      expect(edited.inputMethod, QuestionInputMethod.camera);
      expect(edited.normalizedExpression, '2*x=8');
      expect(edited.confidenceLevel, RecognitionConfidence.high);
    });
  });

  group('QuestionRecognitionService', () {
    test('keyboard input becomes a question without calling an engine', () async {
      final _StubHandwriting handwriting = _StubHandwriting();
      final _StubImage image = _StubImage();
      final QuestionRecognitionService service =
          QuestionRecognitionServiceImpl(
            handwriting: handwriting,
            image: image,
          );

      final Result<MathQuestion> result = await service.recognize(
        const KeyboardInput('2*x+5=15'),
      );

      final MathQuestion question = result.valueOrNull!;
      expect(question.inputMethod, QuestionInputMethod.keyboard);
      expect(question.normalizedExpression, '2*x+5=15');
      expect(question.confidence, 1);
      expect(handwriting.calls, 0);
      expect(image.calls, 0);
    });

    test('empty keyboard input is rejected', () async {
      final Result<MathQuestion> result =
          await QuestionRecognitionServiceImpl(
            handwriting: _StubHandwriting(),
            image: _StubImage(),
          ).recognize(const KeyboardInput('   '));

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('handwriting is normalized into the same model', () async {
      final _StubHandwriting handwriting = _StubHandwriting(
        result: const RecognitionResult(
          expression: '3*x-7=14',
          confidence: 0.92,
        ),
      );
      final QuestionRecognitionService service =
          QuestionRecognitionServiceImpl(
            handwriting: handwriting,
            image: _StubImage(),
          );

      final Result<MathQuestion> result = await service.recognize(
        HandwritingInput(_sample()),
      );

      final MathQuestion question = result.valueOrNull!;
      expect(handwriting.calls, 1);
      expect(question.inputMethod, QuestionInputMethod.handwriting);
      expect(question.normalizedExpression, '3*x-7=14');
      expect(question.confidenceLevel, RecognitionConfidence.high);
      expect(question.originalInput, '1 handwritten stroke');
    });

    test('a photo is normalized into the same model', () async {
      final _StubImage image = _StubImage(
        result: const RecognitionResult(
          expression: 'x^(2)-9=0',
          confidence: 0.55,
        ),
      );
      final QuestionRecognitionService service =
          QuestionRecognitionServiceImpl(
            handwriting: _StubHandwriting(),
            image: image,
          );

      final Result<MathQuestion> result = await service.recognize(
        PhotoInput(_image()),
      );

      final MathQuestion question = result.valueOrNull!;
      expect(image.calls, 1);
      expect(question.inputMethod, QuestionInputMethod.camera);
      expect(question.confidenceLevel, RecognitionConfidence.low);
      expect(question.needsVerification, isTrue);
      expect(question.originalInput, contains('1600×1200'));
    });

    test('engine failures are passed through', () async {
      final Result<MathQuestion> result =
          await QuestionRecognitionServiceImpl(
            handwriting: _StubHandwriting(
              failure: const NetworkFailure('offline'),
            ),
            image: _StubImage(),
          ).recognize(HandwritingInput(_sample()));

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('only recognized sources can be retried', () {
      expect(const KeyboardInput('1+1').isRetryable, isFalse);
      expect(HandwritingInput(_sample()).isRetryable, isTrue);
      expect(PhotoInput(_image()).isRetryable, isTrue);
    });
  });

  test('exceptions from an engine still map to failures', () {
    expect(
      mapExceptionToFailure(const InvalidImageException('bad')),
      isA<ValidationFailure>(),
    );
  });
}
