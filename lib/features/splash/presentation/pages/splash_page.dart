import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../features/auth/presentation/controllers/auth_scope.dart';
import '../../../../routes/app_routes.dart';

/// Branded launch screen that restores the session before routing on.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  /// Minimum time the brand stays on screen, so the check never flashes by.
  static const Duration displayDuration = Duration(milliseconds: 1600);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppConstants.longAnimation,
  )..forward();

  Timer? _handoffTimer;

  @override
  void initState() {
    super.initState();
    _handoffTimer = Timer(SplashPage.displayDuration, _continue);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthScope.read(context).bootstrap();
    });
  }

  Future<void> _continue() async {
    if (!mounted) {
      return;
    }
    final AuthController auth = AuthScope.read(context);
    if (auth.status == AuthStatus.unknown) {
      // The start-up check is still running; re-check shortly.
      _handoffTimer = Timer(AppConstants.mediumAnimation, _continue);
      return;
    }

    Navigator.of(context).pushReplacementNamed(
      auth.isAuthenticated ? AppRoutes.home : AppRoutes.onboarding,
    );
  }

  @override
  void dispose() {
    _handoffTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const AppLogo(size: 96),
              const SizedBox(height: AppSpacing.xl),
              Text(
                AppStrings.appName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.appTagline,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
