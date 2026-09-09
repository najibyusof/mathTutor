import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/errors/exceptions.dart';
import 'package:mathtutor/core/network/result.dart';
import 'package:mathtutor/core/theme/app_theme.dart';
import 'package:mathtutor/features/camera/domain/entities/math_image.dart';
import 'package:mathtutor/features/camera/domain/repositories/math_image_repository.dart';
import 'package:mathtutor/features/camera/presentation/pages/camera_math_screen.dart';
import 'package:mathtutor/features/camera/presentation/widgets/crop_overlay.dart';
import 'package:mathtutor/features/math_input/presentation/pages/math_input_page.dart';
import 'package:mathtutor/models/recognition_result.dart';
import 'package:mathtutor/routes/app_router.dart';

import 'camera_math_controller_test.dart' show FakeImageSource, samplePng;

class _FakeRepository implements MathImageRepository {
  int calls = 0;
  MathImage? received;

  @override
  Future<Result<RecognitionResult>> recognizeMathImage(MathImage image) async {
    calls++;
    received = image;
    return const Result<RecognitionResult>.success(
      RecognitionResult(
        expression: '3*x-7=14',
        confidence: 0.93,
        alternatives: <String>['3*x-7=11'],
      ),
    );
  }
}

Future<_FakeRepository> _pumpScreen(
  WidgetTester tester, {
  Uint8List? cameraBytes,
  Uint8List? galleryBytes,
  Object? sourceError,
  Brightness brightness = Brightness.light,
  Size size = const Size(420, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final _FakeRepository repository = _FakeRepository();
  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: CameraMathScreen(
        repository: repository,
        imageSource: FakeImageSource(
          cameraBytes: cameraBytes,
          galleryBytes: galleryBytes,
          error: sourceError,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('offers camera and gallery before a picture exists', (
    WidgetTester tester,
  ) async {
    await _pumpScreen(tester);

    expect(find.text('Open camera'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.byType(CropOverlay), findsNothing);
  });

  testWidgets('capturing shows a preview with crop, retake and confirm', (
    WidgetTester tester,
  ) async {
    await _pumpScreen(tester, cameraBytes: samplePng());

    await tester.tap(find.text('Open camera'));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(CropOverlay), findsOneWidget);
    expect(find.text('Retake'), findsOneWidget);
    expect(find.text('Use photo'), findsOneWidget);
  });

  testWidgets('a gallery picture can be used too', (
    WidgetTester tester,
  ) async {
    await _pumpScreen(tester, galleryBytes: samplePng());

    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(find.byType(CropOverlay), findsOneWidget);
  });

  testWidgets('retake returns to the capture options', (
    WidgetTester tester,
  ) async {
    await _pumpScreen(tester, cameraBytes: samplePng());

    await tester.tap(find.text('Open camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retake'));
    await tester.pumpAndSettle();

    expect(find.text('Open camera'), findsOneWidget);
    expect(find.byType(CropOverlay), findsNothing);
  });

  testWidgets('dragging a handle crops the picture', (
    WidgetTester tester,
  ) async {
    final _FakeRepository repository = await _pumpScreen(
      tester,
      cameraBytes: samplePng(width: 800, height: 600),
    );

    await tester.tap(find.text('Open camera'));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('crop-handle-bottom-right')),
      const Offset(-80, -60),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('cropped'), findsOneWidget);
    expect(find.text('Reset crop'), findsOneWidget);

    await tester.tap(find.text('Use photo'));
    await tester.pumpAndSettle();

    expect(repository.calls, 1);
    expect(repository.received!.width, lessThan(800));
  });

  testWidgets('confirming shows the reading and opens the editor', (
    WidgetTester tester,
  ) async {
    await _pumpScreen(tester, cameraBytes: samplePng());

    await tester.tap(find.text('Open camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use photo'));
    await tester.pumpAndSettle();

    expect(find.text('3*x-7=14'), findsOneWidget);
    expect(find.text('93% sure'), findsOneWidget);

    await tester.tap(find.text('Use this'));
    await tester.pumpAndSettle();

    expect(find.byType(MathInputPage), findsOneWidget);
    expect(find.text('3 × x − 7 = 14'), findsOneWidget);
  });

  testWidgets('a denied permission is explained in the UI', (
    WidgetTester tester,
  ) async {
    await _pumpScreen(
      tester,
      sourceError: const PermissionDeniedException(
        'MathTutor needs camera access to scan a question.',
      ),
    );

    await tester.tap(find.text('Open camera'));
    await tester.pumpAndSettle();

    expect(
      find.text('MathTutor needs camera access to scan a question.'),
      findsOneWidget,
    );
    expect(find.text('Open camera'), findsOneWidget);
  });

  testWidgets('an unavailable camera keeps the screen usable', (
    WidgetTester tester,
  ) async {
    await _pumpScreen(
      tester,
      sourceError: const DeviceUnavailableException(
        'No camera is available on this device.',
      ),
    );

    await tester.tap(find.text('Open camera'));
    await tester.pumpAndSettle();

    expect(
      find.text('No camera is available on this device.'),
      findsOneWidget,
    );
    expect(find.text('Choose from gallery'), findsOneWidget);
  });

  testWidgets('renders on a small dark screen without errors', (
    WidgetTester tester,
  ) async {
    await _pumpScreen(
      tester,
      cameraBytes: samplePng(),
      brightness: Brightness.dark,
      size: const Size(320, 640),
    );

    await tester.tap(find.text('Open camera'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
