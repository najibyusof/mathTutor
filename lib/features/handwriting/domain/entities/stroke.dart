import 'dart:ui';

/// One sampled point of a stroke.
class StrokePoint {
  const StrokePoint(this.offset, {this.pressure = 1});

  final Offset offset;

  /// Normalized pen pressure; `1` for input devices that report none.
  final double pressure;
}

/// A single continuous pen/finger movement.
///
/// Strokes are kept as vectors rather than pixels so undo, erase and export
/// stay cheap in memory.
class Stroke {
  Stroke({
    required this.points,
    this.width = defaultWidth,
    this.isStylus = false,
  });

  static const double defaultWidth = 3.5;

  final List<StrokePoint> points;
  final double width;
  final bool isStylus;

  bool get isEmpty => points.isEmpty;

  Rect get bounds {
    if (points.isEmpty) {
      return Rect.zero;
    }
    double left = points.first.offset.dx;
    double top = points.first.offset.dy;
    double right = left;
    double bottom = top;

    for (final StrokePoint point in points) {
      left = left < point.offset.dx ? left : point.offset.dx;
      top = top < point.offset.dy ? top : point.offset.dy;
      right = right > point.offset.dx ? right : point.offset.dx;
      bottom = bottom > point.offset.dy ? bottom : point.offset.dy;
    }
    return Rect.fromLTRB(left, top, right, bottom).inflate(width);
  }

  /// Whether any sampled point lies within [radius] of [position].
  bool isNear(Offset position, double radius) {
    if (!bounds.inflate(radius).contains(position)) {
      return false;
    }
    final double squared = radius * radius;
    for (final StrokePoint point in points) {
      if ((point.offset - position).distanceSquared <= squared) {
        return true;
      }
    }
    return false;
  }

  Stroke copyWith({List<StrokePoint>? points}) =>
      Stroke(points: points ?? this.points, width: width, isStylus: isStylus);
}
