import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/widgets.dart';

/// Handwriting/stylus input screen. Ink capture and recognition arrive in a
/// later phase.
class HandwritingPage extends StatelessWidget {
  const HandwritingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: AppStrings.handwritingTitle,
      icon: Icons.draw_outlined,
      description: AppStrings.handwritingSubtitle,
    );
  }
}
