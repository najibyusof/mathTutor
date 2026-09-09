import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/widgets.dart';

/// Camera/photo capture screen. Capture and OCR arrive in a later phase.
class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: AppStrings.cameraTitle,
      icon: Icons.photo_camera_outlined,
      description: AppStrings.cameraSubtitle,
    );
  }
}
