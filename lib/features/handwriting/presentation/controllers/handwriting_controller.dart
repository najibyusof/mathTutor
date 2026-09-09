import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/result.dart';
import '../../domain/entities/handwriting_sample.dart';
import '../../domain/entities/recognition_result.dart';
import '../../domain/entities/stroke.dart';
import '../../domain/repositories/handwriting_repository.dart';

enum HandwritingTool { pen, eraser }

/// Owns the sketch, its undo/redo history and the recognition request.
///
/// The in-progress stroke lives in [activeStroke] so that drawing repaints a
/// single layer instead of the whole canvas.
class HandwritingController extends ChangeNotifier {
  HandwritingController({required HandwritingRepository repository})
    : _repository = repository;

  final HandwritingRepository _repository;

  /// Points closer than this to the previous one are dropped.
  static const double minPointDistance = 1.5;

  static const double eraserRadius = 14;

  final List<Stroke> _strokes = <Stroke>[];
  final List<_SketchAction> _undoStack = <_SketchAction>[];
  final List<_SketchAction> _redoStack = <_SketchAction>[];
  final List<_ErasedStroke> _pendingErased = <_ErasedStroke>[];

  final ValueNotifier<Stroke?> activeStroke = ValueNotifier<Stroke?>(null);

  HandwritingTool _tool = HandwritingTool.pen;
  bool _isRecognizing = false;
  RecognitionResult? _result;
  String? _errorMessage;

  List<Stroke> get strokes => List<Stroke>.unmodifiable(_strokes);
  HandwritingTool get tool => _tool;
  bool get isEmpty => _strokes.isEmpty && activeStroke.value == null;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get isRecognizing => _isRecognizing;
  RecognitionResult? get result => _result;
  String? get errorMessage => _errorMessage;

  set tool(HandwritingTool value) {
    if (_tool == value) {
      return;
    }
    _tool = value;
    notifyListeners();
  }

  void startStroke(
    Offset position, {
    double pressure = 1,
    bool isStylus = false,
    double width = Stroke.defaultWidth,
  }) {
    _clearResult();

    if (_tool == HandwritingTool.eraser) {
      eraseAt(position);
      return;
    }

    activeStroke.value = Stroke(
      points: <StrokePoint>[StrokePoint(position, pressure: pressure)],
      width: width,
      isStylus: isStylus,
    );
  }

  void extendStroke(Offset position, {double pressure = 1}) {
    if (_tool == HandwritingTool.eraser) {
      eraseAt(position);
      return;
    }

    final Stroke? current = activeStroke.value;
    if (current == null) {
      return;
    }

    final Offset last = current.points.last.offset;
    if ((position - last).distance < minPointDistance) {
      return;
    }

    activeStroke.value = current.copyWith(
      points: <StrokePoint>[
        ...current.points,
        StrokePoint(position, pressure: pressure),
      ],
    );
  }

  void endStroke() {
    if (_tool == HandwritingTool.eraser) {
      if (_pendingErased.isNotEmpty) {
        _pushAction(
          _EraseStrokes(List<_ErasedStroke>.of(_pendingErased)),
        );
        _pendingErased.clear();
      }
      return;
    }

    final Stroke? current = activeStroke.value;
    activeStroke.value = null;
    if (current == null || current.points.length < 2) {
      // A tap without movement still leaves a dot.
      if (current != null) {
        _strokes.add(current);
        _pushAction(_AddStroke(current));
        notifyListeners();
      }
      return;
    }

    _strokes.add(current);
    _pushAction(_AddStroke(current));
    notifyListeners();
  }

  /// Removes whole strokes touched by the eraser, which keeps the sketch a
  /// vector model (no bitmap masking).
  void eraseAt(Offset position) {
    bool changed = false;

    for (int i = _strokes.length - 1; i >= 0; i--) {
      if (_strokes[i].isNear(position, eraserRadius)) {
        _pendingErased.add(_ErasedStroke(i, _strokes.removeAt(i)));
        changed = true;
      }
    }

    if (changed) {
      _clearResult();
      notifyListeners();
    }
  }

  void clear() {
    if (_strokes.isEmpty) {
      return;
    }
    _pushAction(_ClearCanvas(List<Stroke>.of(_strokes)));
    _strokes.clear();
    activeStroke.value = null;
    _clearResult();
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty) {
      return;
    }
    final _SketchAction action = _undoStack.removeLast();
    action.undo(_strokes);
    _redoStack.add(action);
    _clearResult();
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) {
      return;
    }
    final _SketchAction action = _redoStack.removeLast();
    action.redo(_strokes);
    _undoStack.add(action);
    _clearResult();
    notifyListeners();
  }

  /// Sends the strokes to the recognition engine through the repository.
  Future<bool> recognize(Size canvasSize) async {
    if (_strokes.isEmpty || _isRecognizing) {
      return false;
    }

    _isRecognizing = true;
    _errorMessage = null;
    _result = null;
    notifyListeners();

    final Result<RecognitionResult> result = await _repository
        .recognizeHandwriting(
          HandwritingSample.fromStrokes(_strokes, canvasSize),
        );

    final bool succeeded = result.when<bool>(
      onSuccess: (RecognitionResult value) {
        _result = value;
        return true;
      },
      onFailure: (Failure failure) {
        _errorMessage = friendlyMessage(failure);
        return false;
      },
    );

    _isRecognizing = false;
    notifyListeners();
    return succeeded;
  }

  void dismissResult() {
    if (_result == null && _errorMessage == null) {
      return;
    }
    _clearResult();
    notifyListeners();
  }

  void _pushAction(_SketchAction action) {
    _undoStack.add(action);
    _redoStack.clear();
  }

  void _clearResult() {
    _result = null;
    _errorMessage = null;
  }

  @override
  void dispose() {
    activeStroke.dispose();
    super.dispose();
  }
}

class _ErasedStroke {
  const _ErasedStroke(this.index, this.stroke);

  final int index;
  final Stroke stroke;
}

/// Undo entries store stroke references, not canvas snapshots.
sealed class _SketchAction {
  const _SketchAction();

  void undo(List<Stroke> strokes);
  void redo(List<Stroke> strokes);
}

class _AddStroke extends _SketchAction {
  const _AddStroke(this.stroke);

  final Stroke stroke;

  @override
  void undo(List<Stroke> strokes) => strokes.remove(stroke);

  @override
  void redo(List<Stroke> strokes) => strokes.add(stroke);
}

class _EraseStrokes extends _SketchAction {
  const _EraseStrokes(this.erased);

  final List<_ErasedStroke> erased;

  @override
  void undo(List<Stroke> strokes) {
    for (final _ErasedStroke item in erased.reversed) {
      strokes.insert(item.index.clamp(0, strokes.length), item.stroke);
    }
  }

  @override
  void redo(List<Stroke> strokes) {
    for (final _ErasedStroke item in erased) {
      strokes.remove(item.stroke);
    }
  }
}

class _ClearCanvas extends _SketchAction {
  const _ClearCanvas(this.previous);

  final List<Stroke> previous;

  @override
  void undo(List<Stroke> strokes) => strokes.addAll(previous);

  @override
  void redo(List<Stroke> strokes) => strokes.clear();
}
