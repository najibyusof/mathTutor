import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/errors/exceptions.dart';
import 'package:mathtutor/core/network/result.dart';
import 'package:mathtutor/features/handwriting/data/repositories/handwriting_repository_impl.dart';
import 'package:mathtutor/features/handwriting/data/services/handwriting_recognition_service.dart';
import 'package:mathtutor/features/handwriting/domain/entities/handwriting_sample.dart';
import 'package:mathtutor/models/recognition_result.dart';
import 'package:mathtutor/features/handwriting/domain/repositories/handwriting_repository.dart';
import 'package:mathtutor/features/handwriting/presentation/controllers/handwriting_controller.dart';

class _StubService implements HandwritingRecognitionService {
  _StubService({this.result, this.error});

  final RecognitionResult? result;
  final Object? error;

  @override
  Future<RecognitionResult> recognize(HandwritingSample sample) async {
    if (error != null) {
      throw error!;
    }
    return result!;
  }
}

HandwritingRepository _repository({
  RecognitionResult? result,
  Object? error,
}) => HandwritingRepositoryImpl(
  _StubService(
    result: result ?? const RecognitionResult(expression: '2*x=8'),
    error: error,
  ),
);

HandwritingController _controller({
  RecognitionResult? result,
  Object? error,
}) => HandwritingController(
  repository: _repository(result: result, error: error),
);

void _draw(HandwritingController controller, List<Offset> points) {
  controller.startStroke(points.first);
  for (final Offset point in points.skip(1)) {
    controller.extendStroke(point);
  }
  controller.endStroke();
}

void main() {
  test('drawing adds a stroke and keeps the live layer clean', () {
    final HandwritingController controller = _controller();
    addTearDown(controller.dispose);

    expect(controller.isEmpty, isTrue);

    _draw(controller, <Offset>[
      const Offset(0, 0),
      const Offset(20, 20),
      const Offset(40, 0),
    ]);

    expect(controller.strokes, hasLength(1));
    expect(controller.strokes.first.points, hasLength(3));
    expect(controller.activeStroke.value, isNull);
    expect(controller.isEmpty, isFalse);
  });

  test('samples closer than the minimum distance are dropped', () {
    final HandwritingController controller = _controller();
    addTearDown(controller.dispose);

    controller.startStroke(Offset.zero);
    controller.extendStroke(const Offset(0.5, 0));
    controller.extendStroke(const Offset(0.9, 0));
    controller.extendStroke(const Offset(30, 0));
    controller.endStroke();

    expect(controller.strokes.first.points, hasLength(2));
  });

  test('undo and redo walk the stroke history', () {
    final HandwritingController controller = _controller();
    addTearDown(controller.dispose);

    _draw(controller, <Offset>[const Offset(0, 0), const Offset(10, 10)]);
    _draw(controller, <Offset>[const Offset(40, 0), const Offset(50, 10)]);
    expect(controller.strokes, hasLength(2));

    controller.undo();
    expect(controller.strokes, hasLength(1));
    expect(controller.canRedo, isTrue);

    controller.redo();
    expect(controller.strokes, hasLength(2));
    expect(controller.canRedo, isFalse);

    controller.undo();
    controller.undo();
    expect(controller.strokes, isEmpty);
    expect(controller.canUndo, isFalse);
  });

  test('drawing after undo clears the redo stack', () {
    final HandwritingController controller = _controller();
    addTearDown(controller.dispose);

    _draw(controller, <Offset>[const Offset(0, 0), const Offset(10, 10)]);
    controller.undo();
    expect(controller.canRedo, isTrue);

    _draw(controller, <Offset>[const Offset(20, 0), const Offset(30, 10)]);
    expect(controller.canRedo, isFalse);
  });

  test('eraser removes touched strokes and one drag is a single undo step', () {
    final HandwritingController controller = _controller();
    addTearDown(controller.dispose);

    _draw(controller, <Offset>[const Offset(0, 0), const Offset(10, 0)]);
    _draw(controller, <Offset>[const Offset(100, 0), const Offset(110, 0)]);

    controller.tool = HandwritingTool.eraser;
    controller.startStroke(const Offset(5, 0));
    controller.extendStroke(const Offset(105, 0));
    controller.endStroke();

    expect(controller.strokes, isEmpty);

    controller.undo();
    expect(controller.strokes, hasLength(2));
  });

  test('clear can be undone', () {
    final HandwritingController controller = _controller();
    addTearDown(controller.dispose);

    _draw(controller, <Offset>[const Offset(0, 0), const Offset(10, 10)]);
    controller.clear();
    expect(controller.strokes, isEmpty);

    controller.undo();
    expect(controller.strokes, hasLength(1));
  });

  test('recognition exposes the result from the repository', () async {
    final HandwritingController controller = _controller(
      result: const RecognitionResult(
        expression: '(x+3)/2=7',
        confidence: 0.88,
      ),
    );
    addTearDown(controller.dispose);

    _draw(controller, <Offset>[const Offset(0, 0), const Offset(10, 10)]);

    final bool succeeded = await controller.recognize(const Size(300, 200));

    expect(succeeded, isTrue);
    expect(controller.result?.expression, '(x+3)/2=7');
    expect(controller.isRecognizing, isFalse);
    expect(controller.errorMessage, isNull);
  });

  test('recognition failures surface a friendly message', () async {
    final HandwritingController controller = _controller(
      error: const NetworkException('offline'),
    );
    addTearDown(controller.dispose);

    _draw(controller, <Offset>[const Offset(0, 0), const Offset(10, 10)]);

    final bool succeeded = await controller.recognize(const Size(300, 200));

    expect(succeeded, isFalse);
    expect(controller.result, isNull);
    expect(controller.errorMessage, contains('No internet connection'));
  });

  test('recognition is skipped on an empty canvas', () async {
    final HandwritingController controller = _controller();
    addTearDown(controller.dispose);

    expect(await controller.recognize(const Size(300, 200)), isFalse);
  });

  test('editing the sketch drops a stale result', () async {
    final HandwritingController controller = _controller();
    addTearDown(controller.dispose);

    _draw(controller, <Offset>[const Offset(0, 0), const Offset(10, 10)]);
    await controller.recognize(const Size(300, 200));
    expect(controller.result, isNotNull);

    _draw(controller, <Offset>[const Offset(20, 0), const Offset(30, 10)]);
    expect(controller.result, isNull);
  });

  test('the repository is the only recognition dependency', () async {
    // A stub repository proves the controller never reaches for a service or
    // the API directly.
    final HandwritingController controller = HandwritingController(
      repository: _FakeRepository(),
    );
    addTearDown(controller.dispose);

    _draw(controller, <Offset>[const Offset(0, 0), const Offset(10, 10)]);
    await controller.recognize(const Size(100, 100));

    expect(controller.result?.expression, 'swapped-engine');
  });
}

class _FakeRepository implements HandwritingRepository {
  @override
  Future<Result<RecognitionResult>> recognizeHandwriting(
    HandwritingSample sample,
  ) async => const Result<RecognitionResult>.success(
    RecognitionResult(expression: 'swapped-engine', confidence: 1),
  );
}
