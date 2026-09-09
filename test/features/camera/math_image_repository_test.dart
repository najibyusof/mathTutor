import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mathtutor/core/errors/exceptions.dart';
import 'package:mathtutor/core/errors/failures.dart';
import 'package:mathtutor/core/network/result.dart';
import 'package:mathtutor/features/camera/data/repositories/math_image_repository_impl.dart';
import 'package:mathtutor/features/camera/data/services/image_processor.dart';
import 'package:mathtutor/features/camera/data/services/math_image_recognition_service.dart';
import 'package:mathtutor/features/camera/data/services/mock_math_image_recognition_service.dart';
import 'package:mathtutor/features/camera/domain/entities/image_crop.dart';
import 'package:mathtutor/features/camera/domain/entities/math_image.dart';
import 'package:mathtutor/features/camera/domain/repositories/math_image_repository.dart';
import 'package:mathtutor/models/recognition_result.dart';

/// A photo-like picture: smooth gradients with a few dark shapes, similar to
/// a page of homework.
Uint8List _photoBytes({int width = 2400, int height = 1800}) {
  final img.Image image = img.Image(width: width, height: height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final bool isInk = (y ~/ 40) % 3 == 0 && (x ~/ 60) % 4 != 0;
      final int shade = isInk ? 30 : 200 + (x * 40 ~/ width);
      image.setPixelRgb(x, y, shade, shade, shade);
    }
  }
  return img.encodePng(image);
}

class _StubEngine implements MathImageRecognitionService {
  _StubEngine({this.result, this.error});

  final RecognitionResult? result;
  final Object? error;
  MathImage? received;

  @override
  Future<RecognitionResult> recognize(MathImage image) async {
    received = image;
    if (error != null) {
      throw error!;
    }
    return result!;
  }
}

void main() {
  const DartImageProcessor processor = DartImageProcessor();

  group('decoding', () {
    test('reads the dimensions of a valid picture', () {
      final MathImage image = processor.decode(
        _photoBytes(width: 64, height: 32),
        MathImageSource.camera,
      );

      expect(image.width, 64);
      expect(image.height, 32);
      expect(image.source, MathImageSource.camera);
    });

    test('rejects empty and undecodable data', () {
      expect(
        () => processor.decode(Uint8List(0), MathImageSource.gallery),
        throwsA(isA<InvalidImageException>()),
      );
      expect(
        () => processor.decode(
          Uint8List.fromList(<int>[1, 2, 3, 4, 5]),
          MathImageSource.gallery,
        ),
        throwsA(isA<InvalidImageException>()),
      );
    });
  });

  group('preparing for upload', () {
    test('downscales large pictures and shrinks the payload', () {
      final MathImage original = processor.decode(
        _photoBytes(),
        MathImageSource.camera,
      );

      final MathImage prepared = processor.prepareForUpload(original);

      expect(prepared.width, DartImageProcessor.maxDimension);
      expect(prepared.height, lessThan(original.height));
      expect(
        prepared.sizeBytes,
        lessThanOrEqualTo(DartImageProcessor.maxUploadBytes),
      );
      expect(prepared.mimeType, 'image/jpeg');
    });

    test('applies the crop rectangle to the original pixels', () {
      final MathImage original = processor.decode(
        _photoBytes(width: 800, height: 400),
        MathImageSource.gallery,
      );

      final MathImage prepared = processor.prepareForUpload(
        original,
        crop: const ImageCrop(left: 0.25, top: 0, right: 0.75, bottom: 0.5),
      );

      expect(prepared.width, 400);
      expect(prepared.height, 200);
    });

    test('rejects bytes that are not an image', () {
      final MathImage broken = MathImage(
        bytes: Uint8List.fromList(<int>[9, 9, 9]),
        width: 10,
        height: 10,
        source: MathImageSource.camera,
      );

      expect(
        () => processor.prepareForUpload(broken),
        throwsA(isA<InvalidImageException>()),
      );
    });
  });

  group('ImageCrop', () {
    test('keeps a usable minimum size and stays inside the image', () {
      const ImageCrop crop = ImageCrop.full;

      final ImageCrop dragged = crop.copyWith(left: 0.98, top: -0.5);

      expect(dragged.left, 0.98);
      expect(dragged.top, 0);
      expect(dragged.right - dragged.left, greaterThanOrEqualTo(0.1));
      expect(crop.isFull, isTrue);
      expect(dragged.isFull, isFalse);
    });
  });

  group('mock OCR engine', () {
    test('returns a sample expression deterministically', () async {
      const MockMathImageRecognitionService engine =
          MockMathImageRecognitionService(latency: Duration.zero);
      final MathImage image = MathImage(
        bytes: Uint8List(9),
        width: 10,
        height: 10,
        source: MathImageSource.camera,
      );

      final RecognitionResult result = await engine.recognize(image);

      expect(
        result.expression,
        MockMathImageRecognitionService.samples[1].expression,
      );
    });

    test('rejects an empty picture', () {
      const MockMathImageRecognitionService engine =
          MockMathImageRecognitionService(latency: Duration.zero);

      expect(
        () => engine.recognize(
          MathImage(
            bytes: Uint8List(0),
            width: 0,
            height: 0,
            source: MathImageSource.camera,
          ),
        ),
        throwsA(isA<InvalidImageException>()),
      );
    });
  });

  group('MathImageRepositoryImpl', () {
    final MathImage image = MathImage(
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      width: 10,
      height: 10,
      source: MathImageSource.camera,
    );

    test('passes the image to the engine and returns the reading', () async {
      final _StubEngine engine = _StubEngine(
        result: const RecognitionResult(expression: '3*x-7=14'),
      );
      final MathImageRepository repository = MathImageRepositoryImpl(engine);

      final Result<RecognitionResult> result = await repository
          .recognizeMathImage(image);

      expect(result.valueOrNull?.expression, '3*x-7=14');
      expect(engine.received, same(image));
    });

    test('maps engine errors onto failures', () async {
      expect(
        (await MathImageRepositoryImpl(
          _StubEngine(error: const NetworkException('offline')),
        ).recognizeMathImage(image)).failureOrNull,
        isA<NetworkFailure>(),
      );
      expect(
        (await MathImageRepositoryImpl(
          _StubEngine(
            error: const InvalidImageException('not a picture'),
          ),
        ).recognizeMathImage(image)).failureOrNull,
        isA<ValidationFailure>(),
      );
      expect(
        (await MathImageRepositoryImpl(
          _StubEngine(error: const PermissionDeniedException('denied')),
        ).recognizeMathImage(image)).failureOrNull,
        isA<PermissionFailure>(),
      );
    });

    test('treats an empty reading as a failure', () async {
      final Result<RecognitionResult> result = await MathImageRepositoryImpl(
        _StubEngine(result: const RecognitionResult(expression: '')),
      ).recognizeMathImage(image);

      expect(result.failureOrNull, isA<UnexpectedFailure>());
    });
  });
}
