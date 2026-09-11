import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/constants/app_strings.dart';
import 'package:mathtutor/core/network/mock_api_client.dart';
import 'package:mathtutor/core/theme/app_theme.dart';
import 'package:mathtutor/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mathtutor/features/auth/presentation/controllers/auth_scope.dart';
import 'package:mathtutor/features/auth/presentation/pages/login_page.dart';
import 'package:mathtutor/features/home/presentation/pages/home_page.dart';
import 'package:mathtutor/routes/app_router.dart';
import 'package:mathtutor/routes/app_routes.dart';

import '../../support/test_dependencies.dart';

Future<AuthController> _pumpLogin(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final AuthController controller = buildTestDependencies().authController;
  await tester.pumpWidget(
    AuthScope(
      controller: controller,
      child: MaterialApp(
        theme: AppTheme.light,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRoutes.login,
        onGenerateInitialRoutes: (String route) => <Route<dynamic>>[
          AppRouter.onGenerateRoute(RouteSettings(name: route)),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _fillLogin(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, AppStrings.emailLabel),
    email,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, AppStrings.passwordLabel),
    password,
  );
}

void main() {
  testWidgets('validates the form before calling the API', (
    WidgetTester tester,
  ) async {
    final AuthController controller = await _pumpLogin(tester);

    await tester.tap(find.widgetWithText(FilledButton, AppStrings.signIn));
    await tester.pumpAndSettle();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
    expect(controller.status, AuthStatus.unknown);
  });

  testWidgets('shows a friendly message for invalid credentials', (
    WidgetTester tester,
  ) async {
    await _pumpLogin(tester);

    await _fillLogin(
      tester,
      email: 'unknown@mathtutor.app',
      password: 'local-test-password',
    );
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.signIn));
    await tester.pumpAndSettle();

    expect(
      find.text('These credentials do not match our records.'),
      findsOneWidget,
    );
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('signs in and lands on home', (WidgetTester tester) async {
    final AuthController controller = await _pumpLogin(tester);

    await _fillLogin(
      tester,
      email: MockApiClient.demoEmail,
      password: 'local-test-password',
    );
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.signIn));
    await tester.pumpAndSettle();

    expect(controller.isAuthenticated, isTrue);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('opens the forgot password screen', (WidgetTester tester) async {
    await _pumpLogin(tester);

    await tester.tap(find.text(AppStrings.forgotPasswordLink));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.forgotPasswordTitle), findsOneWidget);
  });

  testWidgets('opens the registration screen', (WidgetTester tester) async {
    await _pumpLogin(tester);

    await tester.tap(find.widgetWithText(TextButton, AppStrings.signUp));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.registerTitle), findsOneWidget);
  });
}
