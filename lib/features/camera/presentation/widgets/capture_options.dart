import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';

/// Capture options shown before a picture exists.
class CaptureOptions extends StatelessWidget {
  const CaptureOptions({
    required this.onCamera,
    required this.onGallery,
    required this.isBusy,
    super.key,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.document_scanner_outlined,
            size: AppSizes.iconXl,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Point at the question and take a photo',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Keep the page flat and well lit for the best reading.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Open camera',
            icon: Icons.photo_camera_outlined,
            isExpanded: false,
            isLoading: isBusy,
            onPressed: onCamera,
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: 'Choose from gallery',
            icon: Icons.photo_library_outlined,
            isExpanded: false,
            onPressed: isBusy ? null : onGallery,
          ),
        ],
      ),
    );
  }
}
