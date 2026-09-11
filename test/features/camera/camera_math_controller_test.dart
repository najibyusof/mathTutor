import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mathtutor/core/errors/exceptions.dart';
import 'package:mathtutor/core/errors/failures.dart';
import 'package:mathtutor/core/network/result.dart';
import 'package:mathtutor/features/camera/data/services/image_processor.dart';
import 'package:mathtutor/features/camera/data/services/image_source_service.dart';
import 'package:mathtutor/features/camera/domain/entities/image_crop.dart';
import 'package:mathtutor/features/camera/domain/entities/math_image.dart';
import 'package:mathtutor/features/camera/domain/repositories/math_image_repository.dart';
import 'package:mathtutor/features/camera/presentation/controllers/camera_math_controller.dart';
import 'package:mathtutor/models/recognition_result.dart';

Uint8List samplePng({int width = 400, int height = 300}) {
  final img.Image image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(240, 240, 240));
  img.fillRect(
    image,
    x1: 20,
    y1: 20,
    x2: width ~/ 2,
    y2: height ~/ 2,
    color: img.ColorRgb8(20, 20, 20),
  );
  return img.encodePng(image);
}

/// Scripted camera/gallery replacement.
class FakeImageSource implements ImageSourceService {
  FakeImageSource({this.cameraBytes, this.galleryBytes, this.error});

  final Uint8List? cameraBytes;
  final Uint8List? galleryBytes;
  final Object? error;
  int cameraCalls = 0;
  int galleryCalls = 0;

  @override
  Future<Uint8List?> capturePhoto() async {
    cameraCalls++;
    if (error != null) {
      throw error!;
    }
    return cameraBytes;
  }

  @override
  Future<Uint8List?> pickFromGallery() async {
    galleryCalls++;
    if (error != null) {
      throw error!;
    }
    return galleryBytes;
  }
}

class FakeImageRepository implements MathImageRepository {
  FakeImageRepository({this.result, this.failure});

  final RecognitionResult? result;
  final Object? failure;
  MathImage? received;

  @override
  Future<Result<RecognitionResult>> recognizeMathImage(MathImage image) async {
    received = image;
    if (failure != null) {
      return Result<RecognitionResult>.failure(mapExceptionToFailure(failure!));
    }
    return Result<RecognitionResult>.success(
      result ?? const RecognitionResult(expression: '3*x-7=14'),
    );
  }
}

CameraMathController _controller({
  ImageSourceService? source,
  MathImageRepository? repository,
}) => CameraMathController(
  repository: repository ?? FakeImageRepository(),
  imageSource: source ?? FakeImageSource(cameraBytes: samplePng()),
  processor: const DartImageProcessor(),
);

void main() {
  test('capturing moves to preview and keeps the picture', () async {
    final FakeImageSource source = FakeImageSource(cameraBytes: samplePng());
    final CameraMathController controller = _controller(source: source);
    addTearDown(controller.dispose);

    expect(controller.stage, CameraStage.idle);

    await controller.captureFromCamera();

    expect(source.cameraCalls, 1);
    expect(controller.stage, CameraStage.preview);
    expect(controller.image?.width, 400);
    expect(controller.image?.source, MathImageSource.camera);
    expect(controller.errorMessage, isNull);
  });

  test('gallery selection is supported', () async {
    final FakeImageSource source = FakeImageSource(galleryBytes: samplePng());
    final CameraMathController controller = _controller(source: source);
    addTearDown(controller.dispose);

    await controller.pickFromGallery();

    expect(source.galleryCalls, 1);
    expect(controller.image?.source, MathImageSource.gallery);
  });

  test('backing out of the picker leaves the stage unchanged', () async {
    final CameraMathController controller = _controller(
      source: FakeImageSource(),
    );
    addTearDown(controller.dispose);

    await controller.captureFromCamera();

    expect(controller.hasImage, isFalse);
    expect(controller.stage, CameraStage.idle);
    expect(controller.errorMessage, isNull);
  });

  test('denied permission produces a friendly message', () async {
    final CameraMathController controller = _controller(
      source: FakeImageSource(
        error: const PermissionDeniedException('Enable camera access.'),
      ),
    );
    addTearDown(controller.dispose);

    await controller.captureFromCamera();

    expect(controller.stage, CameraStage.idle);
    expect(controller.errorMessage, 'Enable camera access.');
  });

  test('an unavailable camera is reported without crashing', () async {
    final CameraMathController controller = _controller(
      source: FakeImageSource(
        error: const DeviceUnavailableException('No camera on this device.'),
      ),
    );
    addTearDown(controller.dispose);

    await controller.captureFromCamera();

    expect(controller.errorMessage, 'No camera on this device.');
    expect(controller.hasImage, isFalse);
  });

  test('an unreadable file is rejected', () async {
    final CameraMathController controller = _controller(
      source: FakeImageSource(
        cameraBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
      ),
    );
    addTearDown(controller.dispose);

    await controller.captureFromCamera();

    expect(controller.hasImage, isFalse);
    expect(controller.errorMessage, contains('not a picture'));
  });

  test('retake clears the picture and the crop', () async {
    final CameraMathController controller = _controller();
    addTearDown(controller.dispose);

    await controller.captureFromCamera();
    controller.setCrop(
      const ImageCrop(left: 0.1, top: 0.1, right: 0.8, bottom: 0.8),
    );

    controller.retake();

    expect(controller.hasImage, isFalse);
    expect(controller.crop.isFull, isTrue);
    expect(controller.stage, CameraStage.idle);
  });

  test('confirming crops, compresses and sends the picture', () async {
    final FakeImageRepository repository = FakeImageRepository();
    final CameraMathController controller = _controller(
      repository: repository,
      source: FakeImageSource(cameraBytes: samplePng(width: 800, height: 600)),
    );
    addTearDown(controller.dispose);

    await controller.captureFromCamera();
    controller.setCrop(
      const ImageCrop(left: 0, top: 0, right: 0.5, bottom: 0.5),
    );

    final bool succeeded = await controller.confirmAndRecognize();

    expect(succeeded, isTrue);
    expect(controller.stage, CameraStage.result);
    expect(controller.result?.expression, '3*x-7=14');
    expect(repository.received?.width, 400);
    expect(repository.received?.height, 300);
    expect(repository.received?.mimeType, 'image/jpeg');
    expect(
      repository.received!.sizeBytes,
      lessThanOrEqualTo(DartImageProcessor.maxUploadBytes),
    );
  });

  test('a recognition failure returns to preview with a message', () async {
    final CameraMathController controller = _controller(
      repository: FakeImageRepository(
        failure: const NetworkException('offline'),
      ),
    );
    addTearDown(controller.dispose);

    await controller.captureFromCamera();
    final bool succeeded = await controller.confirmAndRecognize();

    expect(succeeded, isFalse);
    expect(controller.stage, CameraStage.preview);
    expect(
      controller.errorMessage,
      contains('Unable to connect to the server'),
    );
    expect(controller.hasImage, isTrue);
  });

  test('confirming without a picture does nothing', () async {
    final CameraMathController controller = _controller();
    addTearDown(controller.dispose);

    expect(await controller.confirmAndRecognize(), isFalse);
  });

  test('dismissing the result returns to preview', () async {
    final CameraMathController controller = _controller();
    addTearDown(controller.dispose);

    await controller.captureFromCamera();
    await controller.confirmAndRecognize();
    expect(controller.result, isNotNull);

    controller.dismissResult();

    expect(controller.result, isNull);
    expect(controller.stage, CameraStage.preview);
  });
}
