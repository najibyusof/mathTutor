import 'package:flutter/material.dart';

import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/camera/presentation/pages/camera_math_screen.dart';
import '../features/handwriting/presentation/pages/handwriting_page.dart';
import '../features/history/presentation/pages/history_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/math_input/presentation/pages/math_input_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/recognition/presentation/pages/recognition_review_screen.dart';
import '../features/solver/presentation/pages/solver_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../models/question_input_method.dart';
import 'app_routes.dart';
import 'route_not_found_page.dart';

/// Arguments accepted by [AppRoutes.solver].
class SolverArgs {
  const SolverArgs({required this.expression, this.source = 'keyboard'});

  final String expression;

  /// Origin of the expression: `type`, `write` or `scan`.
  final String source;
}

/// Arguments accepted by [AppRoutes.mathInput].
class MathInputArgs {
  const MathInputArgs({
    this.method = QuestionInputMethod.keyboard,
    this.initialExpression,
  });

  final QuestionInputMethod method;

  /// Raw expression to load into the editor, e.g. when reopening a question.
  final String? initialExpression;
}

/// Central `onGenerateRoute` implementation for named navigation.
abstract final class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      AppRoutes.splash => _page(const SplashPage(), settings),
      AppRoutes.onboarding => _page(const OnboardingPage(), settings),
      AppRoutes.home => _page(const HomePage(), settings),
      AppRoutes.login => _page(const LoginPage(), settings),
      AppRoutes.register => _page(const RegisterPage(), settings),
      AppRoutes.forgotPassword => _page(const ForgotPasswordPage(), settings),
      AppRoutes.handwriting => _page(const HandwritingPage(), settings),
      AppRoutes.camera => _page(const CameraMathScreen(), settings),
      AppRoutes.history => _page(const HistoryPage(), settings),
      AppRoutes.profile => _page(const ProfilePage(), settings),
      AppRoutes.mathInput => _page(
        MathInputPage(args: settings.arguments as MathInputArgs?),
        settings,
      ),
      AppRoutes.review => _page(
        RecognitionReviewScreen(
          args: settings.arguments! as RecognitionReviewArgs,
        ),
        settings,
      ),
      AppRoutes.solver => _page(
        SolverPage(args: settings.arguments as SolverArgs?),
        settings,
      ),
      _ => _page(RouteNotFoundPage(routeName: settings.name), settings),
    };
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) =>
      _page(RouteNotFoundPage(routeName: settings.name), settings);

  static MaterialPageRoute<dynamic> _page(Widget child, RouteSettings settings) {
    return MaterialPageRoute<dynamic>(
      builder: (BuildContext context) => child,
      settings: settings,
    );
  }
}
