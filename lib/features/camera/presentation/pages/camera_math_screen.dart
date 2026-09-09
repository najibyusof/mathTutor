import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/app_scope.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/question_input_method.dart';
import '../../../../routes/app_router.dart';
import '../../../../routes/app_routes.dart';
import '../../data/services/image_source_service.dart';
import '../../domain/entities/image_crop.dart';
import '../../domain/entities/math_image.dart';
import '../../domain/repositories/math_image_repository.dart';
import '../controllers/camera_math_controller.dart';
import '../widgets/capture_options.dart';
import '../widgets/crop_overlay.dart';

/// Scan-a-question screen: capture or pick a photo, crop it, then send it for
/// recognition. Knows nothing about OCR or the camera plugin.
class CameraMathScreen extends StatefulWidget {
  const CameraMathScreen({this.repository, this.imageSource, super.key});

  /// Injected in tests; resolved from [AppScope] otherwise.
  final MathImageRepository? repository;
  final ImageSourceService? imageSource;

  @override
  State<CameraMathScreen> createState() => _CameraMathScreenState();
}

class _CameraMathScreenState extends State<CameraMathScreen> {
  CameraMathController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= CameraMathController(
      repository: widget.repository ?? AppScope.of(context).mathImageRepository,
      imageSource: widget.imageSource ?? AppScope.of(context).imageSourceService,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _useExpression(String expression) {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.mathInput,
      arguments: MathInputArgs(
        method: QuestionInputMethod.scan,
        initialExpression: expression,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CameraMathController controller = _controller!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.cameraTitle),
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
                  if (controller.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: _ErrorBanner(message: controller.errorMessage!),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: controller.hasImage
                          ? _preview(controller)
                          : CaptureOptions(
                              isBusy: controller.isBusy,
                              onCamera: controller.captureFromCamera,
                              onGallery: controller.pickFromGallery,
                            ),
                    ),
                  ),
                  if (controller.result != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: RecognitionResultCard(
                        result: controller.result!,
                        onAccept: _useExpression,
                        onDismiss: controller.dismissResult,
                      ),
                    )
                  else if (controller.hasImage)
                    _previewActions(controller),
                  const SizedBox(height: AppSpacing.lg),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _preview(CameraMathController controller) {
    final MathImage image = controller.image!;

    return Column(
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Center(
                    child: AspectRatio(
                      aspectRatio: image.aspectRatio,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          Image.memory(
                            image.bytes,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          ),
                          if (controller.result == null)
                            CropOverlay(
                              crop: controller.crop,
                              onCropChanged: controller.setCrop,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (controller.stage == CameraStage.recognizing)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x66000000),
                        child: LoadingIndicator(
                          message: 'Reading the question…',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _imageMeta(controller),
      ],
    );
  }

  Widget _imageMeta(CameraMathController controller) {
    final ThemeData theme = Theme.of(context);
    final MathImage image = controller.preparedImage ?? controller.image!;
    final ImageCrop crop = controller.crop;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            '${image.width}×${image.height} • '
            '${image.sizeKb.toStringAsFixed(0)} KB'
            '${crop.isFull ? '' : ' • cropped'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (!crop.isFull && controller.result == null)
          TextButton.icon(
            onPressed: controller.resetCrop,
            icon: const Icon(Icons.crop_free, size: AppSizes.iconSm),
            label: const Text('Reset crop'),
          ),
      ],
    );
  }

  Widget _previewActions(CameraMathController controller) {
    return Row(
      children: <Widget>[
        Expanded(
          child: SecondaryButton(
            label: 'Retake',
            icon: Icons.refresh,
            onPressed: controller.isBusy ? null : controller.retake,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: PrimaryButton(
            label: 'Use photo',
            icon: Icons.check,
            isLoading: controller.stage == CameraStage.recognizing,
            onPressed: controller.confirmAndRecognize,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
            size: AppSizes.iconMd,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
