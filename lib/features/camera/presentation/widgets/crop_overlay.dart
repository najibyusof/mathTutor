import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/image_crop.dart';

/// Draggable crop window over the captured photo.
///
/// Emits normalized [ImageCrop] values so the processor can crop the original
/// bytes regardless of how the preview is scaled.
class CropOverlay extends StatelessWidget {
  const CropOverlay({
    required this.crop,
    required this.onCropChanged,
    super.key,
  });

  final ImageCrop crop;
  final ValueChanged<ImageCrop> onCropChanged;

  static const double _handleSize = 28;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = constraints.biggest;
        final Rect rect = crop.toRect(size);

        void dragCorner(
          DragUpdateDetails details, {
          required bool isLeft,
          required bool isTop,
        }) {
          final double dx = details.delta.dx / size.width;
          final double dy = details.delta.dy / size.height;
          onCropChanged(
            crop.copyWith(
              left: isLeft ? crop.left + dx : null,
              top: isTop ? crop.top + dy : null,
              right: isLeft ? null : crop.right + dx,
              bottom: isTop ? null : crop.bottom + dy,
            ),
          );
        }

        return Stack(
          children: <Widget>[
            IgnorePointer(
              child: CustomPaint(
                size: size,
                painter: _CropMaskPainter(
                  rect: rect,
                  border: colors.primary,
                  shade: colors.scrim.withValues(alpha: 0.45),
                ),
              ),
            ),
            _handle(
              key: const Key('crop-handle-top-left'),
              left: rect.left,
              top: rect.top,
              color: colors.primary,
              onDrag: (DragUpdateDetails details) =>
                  dragCorner(details, isLeft: true, isTop: true),
            ),
            _handle(
              key: const Key('crop-handle-bottom-right'),
              left: rect.right - _handleSize,
              top: rect.bottom - _handleSize,
              color: colors.primary,
              onDrag: (DragUpdateDetails details) =>
                  dragCorner(details, isLeft: false, isTop: false),
            ),
          ],
        );
      },
    );
  }

  Widget _handle({
    required Key key,
    required double left,
    required double top,
    required Color color,
    required ValueChanged<DragUpdateDetails> onDrag,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        key: key,
        behavior: HitTestBehavior.opaque,
        onPanUpdate: onDrag,
        child: Container(
          width: _handleSize,
          height: _handleSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
    );
  }
}

class _CropMaskPainter extends CustomPainter {
  const _CropMaskPainter({
    required this.rect,
    required this.border,
    required this.shade,
  });

  final Rect rect;
  final Color border;
  final Color shade;

  @override
  void paint(Canvas canvas, Size size) {
    final Path mask = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRect(rect),
    );
    canvas.drawPath(mask, Paint()..color = shade);
    canvas.drawRect(
      rect,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_CropMaskPainter oldDelegate) =>
      oldDelegate.rect != rect || oldDelegate.border != border;
}
