import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../routes/app_router.dart';

/// Step-by-step solution screen. The solver engine is implemented in a
/// later phase; this screen only echoes the incoming expression.
class SolverPage extends StatelessWidget {
  const SolverPage({this.args, super.key});

  final SolverArgs? args;

  @override
  Widget build(BuildContext context) {
    return PlaceholderPage(
      title: AppStrings.solverTitle,
      icon: Icons.functions,
      description: args?.expression,
    );
  }
}
