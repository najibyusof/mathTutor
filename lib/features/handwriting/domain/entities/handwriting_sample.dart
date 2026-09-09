import 'dart:ui';

import 'stroke.dart';

/// Device-independent description of what the user wrote.
///
/// Points are normalized to the `0..1` range so the recognition engine never
/// depends on screen size or pixel density, and no bitmap needs to be kept in
/// memory to describe the input.
class HandwritingSample {
  const HandwritingSample({
    required this.strokes,
    required this.canvasSize,
  });

  /// Normalized strokes: a list of `[x, y]` pairs per stroke.
  final List<List<List<double>>> strokes;

  final Size canvasSize;

  int get strokeCount => strokes.length;

  bool get isEmpty => strokes.isEmpty;

  factory HandwritingSample.fromStrokes(
    List<Stroke> strokes,
    Size canvasSize,
  ) {
    final double width = canvasSize.width <= 0 ? 1 : canvasSize.width;
    final double height = canvasSize.height <= 0 ? 1 : canvasSize.height;

    return HandwritingSample(
      canvasSize: canvasSize,
      strokes: <List<List<double>>>[
        for (final Stroke stroke in strokes)
          <List<double>>[
            for (final StrokePoint point in stroke.points)
              <double>[
                double.parse((point.offset.dx / width).toStringAsFixed(4)),
                double.parse((point.offset.dy / height).toStringAsFixed(4)),
              ],
          ],
      ],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'canvas': <String, double>{
      'width': canvasSize.width,
      'height': canvasSize.height,
    },
    'strokes': strokes,
  };
}
