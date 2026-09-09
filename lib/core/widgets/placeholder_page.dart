import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import 'empty_state.dart';

/// Scaffolded placeholder for features that are not implemented in this phase.
///
/// Keeps navigation testable end-to-end while the real screens are built.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    required this.title,
    required this.icon,
    this.description,
    super.key,
  });

  final String title;
  final IconData icon;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: EmptyState(
          title: AppStrings.comingSoon,
          message: description,
          icon: icon,
        ),
      ),
    );
  }
}
