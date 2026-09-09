import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/entities/stroke.dart';

/// Paints strokes as smoothed paths.
///
/// Used both by the live canvas and by the PNG export so what the user sees is
/// exactly what gets exported.
class StrokePainter extends CustomPainter {
  StrokePainter({
    required this.strokes,
    required this.color,
    this.activeStroke,
    super.repaint,
  });

  final List<Stroke> strokes;
  final Stroke? activeStroke;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (final Stroke stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
    final Stroke? active = activeStroke;
    if (active != null) {
      _paintStroke(canvas, active);
    }
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.isEmpty) {
      return;
    }

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    if (stroke.points.length == 1) {
      canvas.drawCircle(
        stroke.points.first.offset,
        stroke.width / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    canvas.drawPath(buildPath(stroke), paint);
  }

  /// Quadratic curve through the midpoints of consecutive samples, which
  /// removes the jitter of raw pointer data.
  static Path buildPath(Stroke stroke) {
    final List<StrokePoint> points = stroke.points;
    final Path path = Path()
      ..moveTo(points.first.offset.dx, points.first.offset.dy);

    for (int i = 1; i < points.length - 1; i++) {
      final Offset current = points[i].offset;
      final Offset next = points[i + 1].offset;
      final Offset midpoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, midpoint.dx, midpoint.dy);
    }

    final Offset last = points.last.offset;
    path.lineTo(last.dx, last.dy);
    return path;
  }

  @override
  bool shouldRepaint(StrokePainter oldDelegate) =>
      oldDelegate.strokes.length != strokes.length ||
      oldDelegate.activeStroke != activeStroke ||
      oldDelegate.color != color;
}

/// Renders the sketch to PNG bytes on demand.
///
/// Nothing is rasterized while drawing; the bitmap only exists for the moment
/// it is exported.
Future<Uint8List?> exportSketchAsPng({
  required List<Stroke> strokes,
  required Size size,
  required Color strokeColor,
  Color background = const Color(0xFFFFFFFF),
  double pixelRatio = 2,
}) async {
  if (strokes.isEmpty || size.isEmpty) {
    return null;
  }

  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder)..scale(pixelRatio);
  canvas.drawRect(Offset.zero & size, Paint()..color = background);
  StrokePainter(strokes: strokes, color: strokeColor).paint(canvas, size);

  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(
    (size.width * pixelRatio).round(),
    (size.height * pixelRatio).round(),
  );
  final ByteData? data = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );

  picture.dispose();
  image.dispose();
  return data?.buffer.asUint8List();
}
