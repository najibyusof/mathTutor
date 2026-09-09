import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/stroke.dart';
import '../controllers/handwriting_controller.dart';
import 'stroke_painter.dart';

/// Drawing surface for finger, stylus and Apple Pencil input.
///
/// Reports the laid-out canvas size through [onSizeChanged] so the recognition
/// layer can normalize the strokes without knowing about widgets.
class HandwritingCanvas extends StatelessWidget {
  const HandwritingCanvas({
    required this.controller,
    this.onSizeChanged,
    this.showGuideLines = true,
    super.key,
  });

  final HandwritingController controller;
  final ValueChanged<Size>? onSizeChanged;
  final bool showGuideLines;

  static const double _stylusWidth = 3;
  static const double _touchWidth = 4.5;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color inkColor = theme.colorScheme.onSurface;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onSizeChanged?.call(size);
        });

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            color: theme.colorScheme.surfaceContainerLowest,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (PointerDownEvent event) =>
                  _onDown(event, constraints.biggest),
              onPointerMove: (PointerMoveEvent event) =>
                  _onMove(event, constraints.biggest),
              onPointerUp: (_) => controller.endStroke(),
              onPointerCancel: (_) => controller.endStroke(),
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: showGuideLines
                      ? _GuideLinesPainter(
                          color: theme.colorScheme.outlineVariant,
                        )
                      : null,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      // Settled strokes: repaint only when the sketch changes.
                      RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: controller,
                          builder: (BuildContext context, _) => CustomPaint(
                            painter: StrokePainter(
                              strokes: controller.strokes,
                              color: inkColor,
                            ),
                          ),
                        ),
                      ),
                      // Live stroke on its own layer to keep drawing smooth.
                      RepaintBoundary(
                        child: ValueListenableBuilder<Stroke?>(
                          valueListenable: controller.activeStroke,
                          builder: (BuildContext context, Stroke? stroke, _) =>
                              CustomPaint(
                                painter: StrokePainter(
                                  strokes: const <Stroke>[],
                                  activeStroke: stroke,
                                  color: inkColor,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onDown(PointerDownEvent event, Size size) {
    if (!_isSupported(event.kind)) {
      return;
    }
    controller.startStroke(
      _clamp(event.localPosition, size),
      pressure: _pressure(event),
      isStylus: _isStylus(event.kind),
      width: _isStylus(event.kind) ? _stylusWidth : _touchWidth,
    );
  }

  void _onMove(PointerMoveEvent event, Size size) {
    if (!_isSupported(event.kind)) {
      return;
    }
    controller.extendStroke(
      _clamp(event.localPosition, size),
      pressure: _pressure(event),
    );
  }

  static bool _isStylus(PointerDeviceKind kind) =>
      kind == PointerDeviceKind.stylus ||
      kind == PointerDeviceKind.invertedStylus;

  static bool _isSupported(PointerDeviceKind kind) =>
      kind == PointerDeviceKind.touch ||
      kind == PointerDeviceKind.mouse ||
      _isStylus(kind);

  static double _pressure(PointerEvent event) {
    if (event.pressureMax <= event.pressureMin) {
      return 1;
    }
    return event.pressure.clamp(event.pressureMin, event.pressureMax);
  }

  static Offset _clamp(Offset position, Size size) => Offset(
    position.dx.clamp(0, size.width),
    position.dy.clamp(0, size.height),
  );
}

/// Faint ruled lines that help students write on a straight baseline.
class _GuideLinesPainter extends CustomPainter {
  const _GuideLinesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const double spacing = 56;
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GuideLinesPainter oldDelegate) =>
      oldDelegate.color != color;
}
