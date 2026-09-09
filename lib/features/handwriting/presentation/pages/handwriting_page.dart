import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/app_scope.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/question_input_method.dart';
import '../../../../routes/app_router.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/repositories/handwriting_repository.dart';
import '../controllers/handwriting_controller.dart';
import '../widgets/handwriting_canvas.dart';
import '../widgets/handwriting_toolbar.dart';
import '../widgets/stroke_painter.dart';

/// Write-a-question screen: a large canvas plus the tools around it.
///
/// The screen knows nothing about how recognition works; it only calls the
/// repository through [HandwritingController].
class HandwritingPage extends StatefulWidget {
  const HandwritingPage({this.repository, super.key});

  /// Injected in tests; resolved from [AppScope] otherwise.
  final HandwritingRepository? repository;

  @override
  State<HandwritingPage> createState() => _HandwritingPageState();
}

class _HandwritingPageState extends State<HandwritingPage> {
  HandwritingController? _controller;
  Size _canvasSize = Size.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= HandwritingController(
      repository:
          widget.repository ?? AppScope.of(context).handwritingRepository,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final HandwritingController controller = _controller!;
    await controller.recognize(_canvasSize);

    if (!mounted || controller.errorMessage == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(controller.errorMessage!)),
    );
  }

  Future<void> _export() async {
    final HandwritingController controller = _controller!;
    final Color inkColor = Theme.of(context).colorScheme.onSurface;

    final Uint8List? png = await exportSketchAsPng(
      strokes: controller.strokes,
      size: _canvasSize,
      strokeColor: inkColor,
    );

    if (!mounted) {
      return;
    }
    if (png == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to export yet.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Handwriting image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: Image.memory(png, fit: BoxFit.contain),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('PNG • ${(png.lengthInBytes / 1024).toStringAsFixed(1)} KB'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.close),
          ),
        ],
      ),
    );
  }

  void _useExpression(String expression) {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.mathInput,
      arguments: MathInputArgs(
        method: QuestionInputMethod.write,
        initialExpression: expression,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final HandwritingController controller = _controller!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.handwritingTitle),
        actions: <Widget>[
          IconButton(
            tooltip: AppStrings.mathInputTitle,
            icon: const Icon(Icons.keyboard_alt_outlined),
            onPressed: () => Navigator.of(
              context,
            ).pushReplacementNamed(AppRoutes.mathInput),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: 900,
          child: AnimatedBuilder(
            animation: controller,
            builder: (BuildContext context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: AppSpacing.md),
                  HandwritingToolbar(
                    controller: controller,
                    onExport: _export,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: Stack(
                      children: <Widget>[
                        HandwritingCanvas(
                          controller: controller,
                          onSizeChanged: (Size size) => _canvasSize = size,
                        ),
                        if (controller.isEmpty)
                          const IgnorePointer(child: _CanvasHint()),
                        if (controller.isRecognizing)
                          const Positioned.fill(
                            child: ColoredBox(
                              color: Color(0x66000000),
                              child: LoadingIndicator(
                                message: 'Reading your handwriting…',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (controller.result != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: RecognitionResultCard(
                        result: controller.result!,
                        onAccept: _useExpression,
                        onDismiss: controller.dismissResult,
                      ),
                    )
                  else
                    PrimaryButton(
                      label: 'Recognize handwriting',
                      icon: Icons.auto_fix_high_outlined,
                      isLoading: controller.isRecognizing,
                      onPressed: controller.strokes.isEmpty ? null : _submit,
                    ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CanvasHint extends StatelessWidget {
  const _CanvasHint();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.gesture,
            size: AppSizes.iconXl,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.handwritingSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
