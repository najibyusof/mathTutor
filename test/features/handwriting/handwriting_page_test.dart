import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/network/result.dart';
import 'package:mathtutor/core/theme/app_theme.dart';
import 'package:mathtutor/features/handwriting/domain/entities/handwriting_sample.dart';
import 'package:mathtutor/models/recognition_result.dart';
import 'package:mathtutor/features/handwriting/domain/repositories/handwriting_repository.dart';
import 'package:mathtutor/features/handwriting/presentation/pages/handwriting_page.dart';
import 'package:mathtutor/features/handwriting/presentation/widgets/handwriting_canvas.dart';
import 'package:mathtutor/features/recognition/presentation/pages/recognition_review_screen.dart';
import 'package:mathtutor/routes/app_router.dart';

class _FakeRepository implements HandwritingRepository {
  int calls = 0;
  HandwritingSample? lastSample;

  @override
  Future<Result<RecognitionResult>> recognizeHandwriting(
    HandwritingSample sample,
  ) async {
    calls++;
    lastSample = sample;
    return const Result<RecognitionResult>.success(
      RecognitionResult(
        expression: '2*x+5=15',
        confidence: 0.94,
        alternatives: <String>['2*x+5=16'],
      ),
    );
  }
}

Future<_FakeRepository> _pumpPage(
  WidgetTester tester, {
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
      home: HandwritingPage(repository: repository),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

/// Draws a short line on the canvas with the given input device.
Future<void> _write(
  WidgetTester tester, {
  PointerDeviceKind kind = PointerDeviceKind.touch,
  Offset start = const Offset(-60, 0),
}) async {
  final Offset center = tester.getCenter(find.byType(HandwritingCanvas));
  final TestGesture gesture = await tester.startGesture(
    center + start,
    kind: kind,
  );
  await gesture.moveBy(const Offset(30, 20));
  await gesture.moveBy(const Offset(30, -20));
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts with an empty canvas and disabled actions', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester);

    expect(find.byType(HandwritingCanvas), findsOneWidget);
    expect(find.text('Write the problem by hand'), findsOneWidget);

    final FilledButton recognize = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(recognize.onPressed, isNull);

    for (final IconData icon in <IconData>[
      Icons.undo,
      Icons.redo,
      Icons.delete_outline,
      Icons.image_outlined,
    ]) {
      final IconButton button = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, icon),
      );
      expect(button.onPressed, isNull, reason: '$icon should start disabled');
    }
  });

  testWidgets('writing with a finger enables the tools', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester);
    await _write(tester);

    final FilledButton recognize = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(recognize.onPressed, isNotNull);

    final IconButton undo = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.undo),
    );
    expect(undo.onPressed, isNotNull);
  });

  testWidgets('writing with a stylus is supported', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester);
    await _write(tester, kind: PointerDeviceKind.stylus);

    final IconButton clear = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.delete_outline),
    );
    expect(clear.onPressed, isNotNull);
  });

  testWidgets('undo and clear are wired to the toolbar', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester);
    await _write(tester);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.undo));
    await tester.pumpAndSettle();

    final FilledButton recognize = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(recognize.onPressed, isNull);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.redo));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithIcon(IconButton, Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Write the problem by hand'), findsOneWidget);
  });

  testWidgets('submitting sends normalized strokes and shows the reading', (
    WidgetTester tester,
  ) async {
    final _FakeRepository repository = await _pumpPage(tester);
    await _write(tester);

    await tester.tap(find.text('Recognize handwriting'));
    await tester.pumpAndSettle();

    expect(repository.calls, 1);
    expect(repository.lastSample?.strokeCount, 1);
    expect(repository.lastSample?.canvasSize.width, greaterThan(0));

    expect(find.text('2*x+5=15'), findsOneWidget);
    expect(find.text('94% sure'), findsOneWidget);
    expect(find.text('2*x+5=16'), findsOneWidget);
  });

  testWidgets('accepting a reading opens the review screen', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester);
    await _write(tester);

    await tester.tap(find.text('Recognize handwriting'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this'));
    await tester.pumpAndSettle();

    expect(find.byType(RecognitionReviewScreen), findsOneWidget);
    expect(find.text('Confidence: High'), findsOneWidget);
    expect(find.textContaining('handwritten stroke'), findsOneWidget);
  });

  testWidgets('rewrite dismisses the reading and keeps the strokes', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester);
    await _write(tester);

    await tester.tap(find.text('Recognize handwriting'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rewrite'));
    await tester.pumpAndSettle();

    expect(find.text('2*x+5=15'), findsNothing);
    final FilledButton recognize = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(recognize.onPressed, isNotNull);
  });

  testWidgets('exports the sketch as a PNG preview', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester);
    await _write(tester);

    // Rasterizing needs real async: ui.Picture.toImage never completes in the
    // fake-async test zone.
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithIcon(IconButton, Icons.image_outlined));
      for (int i = 0; i < 40 && find.text('Handwriting image').evaluate().isEmpty; i++) {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pump();

    expect(find.text('Handwriting image'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('renders on a small dark-theme screen without errors', (
    WidgetTester tester,
  ) async {
    await _pumpPage(
      tester,
      brightness: Brightness.dark,
      size: const Size(320, 640),
    );
    await _write(tester, start: const Offset(-30, 0));

    expect(tester.takeException(), isNull);
  });
}
