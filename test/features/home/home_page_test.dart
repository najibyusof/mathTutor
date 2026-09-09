import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/constants/app_strings.dart';
import 'package:mathtutor/core/mock/mock_data.dart';
import 'package:mathtutor/core/theme/app_theme.dart';
import 'package:mathtutor/core/widgets/widgets.dart';
import 'package:mathtutor/features/home/presentation/pages/home_page.dart';
import 'package:mathtutor/features/home/presentation/widgets/input_method_card.dart';
import 'package:mathtutor/models/question_input_method.dart';
import 'package:mathtutor/routes/app_router.dart';

Future<void> _pumpHome(WidgetTester tester, {Size? size}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: HomePage(now: DateTime(2026, 3, 18, 9)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders greeting, avatar and educational message', (
    WidgetTester tester,
  ) async {
    await _pumpHome(tester);

    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text(MockData.currentUser.firstName), findsOneWidget);
    expect(find.byType(AppAvatar), findsOneWidget);
    expect(find.text(AppStrings.tipOfTheDay), findsOneWidget);
  });

  testWidgets('renders the main action and every input method', (
    WidgetTester tester,
  ) async {
    await _pumpHome(tester);

    expect(find.text(AppStrings.askQuestion), findsOneWidget);
    for (final QuestionInputMethod method in QuestionInputMethod.values) {
      expect(find.text(method.label), findsOneWidget);
    }
  });

  testWidgets('renders recent questions and the history action', (
    WidgetTester tester,
  ) async {
    await _pumpHome(tester, size: const Size(420, 1600));

    expect(find.text(AppStrings.recentQuestions), findsOneWidget);
    expect(find.text(AppStrings.viewHistory), findsOneWidget);
    expect(find.byType(QuestionTile), findsWidgets);
  });

  testWidgets('lays out input methods in a row on tablet widths', (
    WidgetTester tester,
  ) async {
    await _pumpHome(tester, size: const Size(1024, 1366));

    expect(find.byType(InputMethodCard), findsNWidgets(3));
    expect(find.byType(IntrinsicHeight), findsOneWidget);
  });
}
