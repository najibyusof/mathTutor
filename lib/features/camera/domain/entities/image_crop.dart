import 'dart:ui';

/// Crop selection expressed in fractions of the image, so it survives any
/// preview scaling or rotation of the device.
class ImageCrop {
  const ImageCrop({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  static const ImageCrop full = ImageCrop(
    left: 0,
    top: 0,
    right: 1,
    bottom: 1,
  );

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;

  bool get isFull => left <= 0 && top <= 0 && right >= 1 && bottom >= 1;

  /// Minimum selectable fraction, guarding against unusable 1-pixel crops.
  static const double minSize = 0.1;

  Rect toRect(Size size) => Rect.fromLTRB(
    left * size.width,
    top * size.height,
    right * size.width,
    bottom * size.height,
  );

  ImageCrop copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    final double newLeft = (left ?? this.left).clamp(0.0, 1.0);
    final double newTop = (top ?? this.top).clamp(0.0, 1.0);
    final double newRight = (right ?? this.right).clamp(0.0, 1.0);
    final double newBottom = (bottom ?? this.bottom).clamp(0.0, 1.0);

    return ImageCrop(
      left: newLeft,
      top: newTop,
      right: newRight < newLeft + minSize ? newLeft + minSize : newRight,
      bottom: newBottom < newTop + minSize ? newTop + minSize : newBottom,
    );
  }
}
