import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Centered progress indicator with an optional caption.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    this.message,
    this.size = AppSizes.iconLg,
    super.key,
  });

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message ?? 'Loading',
      liveRegion: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox.square(
              dimension: size,
              child: const CircularProgressIndicator(),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
