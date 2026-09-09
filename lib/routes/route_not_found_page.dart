import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/widgets/widgets.dart';

/// Fallback screen shown for unknown or malformed routes.
class RouteNotFoundPage extends StatelessWidget {
  const RouteNotFoundPage({this.routeName, super.key});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: ErrorMessage(
        title: AppStrings.unknownRoute,
        message: routeName,
        icon: Icons.explore_off_outlined,
        onRetry: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
