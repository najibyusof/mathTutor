import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/di/app_dependencies.dart';
import 'core/di/app_scope.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/controllers/auth_scope.dart';
import 'routes/app_router.dart';
import 'routes/app_routes.dart';

/// Root widget: wires the Material 3 themes, auth state and named navigation.
class MathTutorApp extends StatelessWidget {
  const MathTutorApp({
    required this.dependencies,
    this.themeMode = ThemeMode.system,
    this.initialRoute = AppRoutes.splash,
    super.key,
  });

  final AppDependencies dependencies;
  final ThemeMode themeMode;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: dependencies,
      child: AuthScope(
        controller: dependencies.authController,
        child: MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          initialRoute: initialRoute,
          onGenerateInitialRoutes: (String route) => <Route<dynamic>>[
            AppRouter.onGenerateRoute(RouteSettings(name: route)),
          ],
          onGenerateRoute: AppRouter.onGenerateRoute,
          onUnknownRoute: AppRouter.onUnknownRoute,
        ),
      ),
    );
  }
}
