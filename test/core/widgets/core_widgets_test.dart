import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/theme/app_theme.dart';
import 'package:mathtutor/core/widgets/widgets.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('PrimaryButton', () {
    testWidgets('invokes onPressed when enabled', (WidgetTester tester) async {
      int taps = 0;
      await _pump(
        tester,
        PrimaryButton(label: 'Solve', onPressed: () => taps++),
      );

      await tester.tap(find.text('Solve'));
      expect(taps, 1);
    });

    testWidgets('shows a spinner and blocks taps while loading', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await _pump(
        tester,
        PrimaryButton(
          label: 'Solve',
          isLoading: true,
          onPressed: () => taps++,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Solve'), findsNothing);

      await tester.tap(find.byType(FilledButton));
      expect(taps, 0);
    });
  });

  group('SecondaryButton', () {
    testWidgets('renders an icon variant', (WidgetTester tester) async {
      await _pump(
        tester,
        SecondaryButton(
          label: 'Retake',
          icon: Icons.refresh,
          onPressed: () {},
        ),
      );

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('Retake'), findsOneWidget);
    });

    testWidgets('is disabled when onPressed is null', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const SecondaryButton(label: 'Retake', onPressed: null),
      );

      final OutlinedButton button = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(button.onPressed, isNull);
    });
  });

  testWidgets('LoadingIndicator shows its message', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const LoadingIndicator(message: 'Solving...'));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Solving...'), findsOneWidget);
  });

  testWidgets('ErrorMessage exposes a retry action', (
    WidgetTester tester,
  ) async {
    int retries = 0;
    await _pump(
      tester,
      ErrorMessage(
        title: 'Failed',
        message: 'No connection',
        onRetry: () => retries++,
      ),
    );

    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('No connection'), findsOneWidget);

    await tester.tap(find.byType(OutlinedButton));
    expect(retries, 1);
  });

  testWidgets('EmptyState renders an optional action', (
    WidgetTester tester,
  ) async {
    int actions = 0;
    await _pump(
      tester,
      EmptyState(
        title: 'Nothing here',
        actionLabel: 'Add one',
        onAction: () => actions++,
      ),
    );

    await tester.tap(find.text('Add one'));
    expect(actions, 1);
  });

  testWidgets('AppCard forwards taps', (WidgetTester tester) async {
    int taps = 0;
    await _pump(
      tester,
      AppCard(onTap: () => taps++, child: const Text('Content')),
    );

    await tester.tap(find.text('Content'));
    expect(taps, 1);
  });

  testWidgets('SectionHeader renders title, subtitle and action', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const SectionHeader(
        title: 'Recent',
        subtitle: 'Last 7 days',
        action: Text('See all'),
      ),
    );

    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('See all'), findsOneWidget);
  });
}
