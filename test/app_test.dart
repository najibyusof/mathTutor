import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/app.dart';
import 'package:mathtutor/core/constants/app_strings.dart';
import 'package:mathtutor/features/auth/presentation/pages/login_page.dart';
import 'package:mathtutor/features/home/presentation/pages/home_page.dart';
import 'package:mathtutor/features/math_input/presentation/pages/math_input_page.dart';
import 'package:mathtutor/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:mathtutor/features/splash/presentation/pages/splash_page.dart';
import 'package:mathtutor/routes/app_routes.dart';

import 'support/test_dependencies.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  String initialRoute = AppRoutes.splash,
}) {
  return tester.pumpWidget(
    MathTutorApp(
      dependencies: buildTestDependencies(),
      initialRoute: initialRoute,
    ),
  );
}

void main() {
  group('MathTutorApp', () {
    testWidgets('starts on the splash screen', (WidgetTester tester) async {
      await _pumpApp(tester);
      await tester.pump();

      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.text(AppStrings.appName), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('splash hands off to onboarding when signed out', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester);
      await tester.pump(SplashPage.displayDuration);
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('onboarding skip goes to the login screen', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, initialRoute: AppRoutes.onboarding);
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.onboardingSkip));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('uses Material 3 for both themes', (WidgetTester tester) async {
      await _pumpApp(tester, initialRoute: AppRoutes.home);

      final MaterialApp app = tester.widget<MaterialApp>(
        find.byType(MaterialApp),
      );
      expect(app.theme?.useMaterial3, isTrue);
      expect(app.darkTheme?.useMaterial3, isTrue);
      expect(app.theme?.brightness, Brightness.light);
      expect(app.darkTheme?.brightness, Brightness.dark);
    });

    testWidgets('home opens the math input screen', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, initialRoute: AppRoutes.home);
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);

      await tester.tap(find.text(AppStrings.askQuestion));
      await tester.pumpAndSettle();

      expect(find.byType(MathInputPage), findsOneWidget);
    });

    testWidgets('shows a not-found page for unknown routes', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, initialRoute: AppRoutes.home);
      await tester.pumpAndSettle();

      final NavigatorState navigator = tester.state<NavigatorState>(
        find.byType(Navigator),
      );
      navigator.pushNamed('/does-not-exist');
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.unknownRoute), findsOneWidget);
    });
  });
}
