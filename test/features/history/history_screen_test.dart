import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/errors/failures.dart';
import 'package:mathtutor/core/network/result.dart';
import 'package:mathtutor/core/theme/app_theme.dart';
import 'package:mathtutor/features/history/presentation/pages/history_screen.dart';
import 'package:mathtutor/features/history/presentation/widgets/history_item_tile.dart';
import 'package:mathtutor/features/math/domain/models/history_page.dart';
import 'package:mathtutor/features/math/domain/repositories/math_repository.dart';
import 'package:mathtutor/features/math/presentation/controllers/math_api_controller.dart';
import 'package:mathtutor/features/solver/domain/models/math_problem.dart';
import 'package:mathtutor/features/solver/domain/models/solution.dart';
import 'package:mathtutor/models/math_question.dart';
import 'package:mathtutor/models/question_input_method.dart';

MathQuestion _question({
  String id = 'q-1',
  String expression = '2*x+5=15',
  QuestionInputMethod method = QuestionInputMethod.keyboard,
}) => MathQuestion.create(
  id: id,
  originalInput: expression,
  normalizedExpression: expression,
  inputMethod: method,
  createdAt: DateTime(2026, 9, 11, 10),
);

class _FakeRepository implements MathRepository {
  _FakeRepository({this.failHistory = false, this.empty = false});

  final bool failHistory;
  final bool empty;
  int historyCalls = 0;
  final List<String> deleted = <String>[];

  @override
  Future<Result<HistoryPage>> history({
    int page = 1,
    int perPage = 20,
    String? query,
    MathCategory? category,
  }) async {
    historyCalls++;
    if (failHistory) {
      return const Result<HistoryPage>.failure(NetworkFailure('offline'));
    }
    final List<MathQuestion> items = empty
        ? <MathQuestion>[]
        : query == 'quadratic'
        ? <MathQuestion>[
            _question(
              id: 'q-2',
              expression: 'x^2+1=5',
              method: QuestionInputMethod.camera,
            ),
          ]
        : <MathQuestion>[
            _question(),
            _question(
              id: 'q-2',
              expression: 'x^2+1=5',
              method: QuestionInputMethod.camera,
            ),
          ];
    return Result<HistoryPage>.success(
      HistoryPage(
        items: items,
        currentPage: page,
        lastPage: page == 1 ? 2 : 2,
        total: 3,
      ),
    );
  }

  @override
  Future<Result<void>> deleteHistoryItem(String id) async {
    deleted.add(id);
    return const Result<void>.success(null);
  }

  @override
  Future<Result<MathQuestion>> submitQuestion(MathQuestion question) async =>
      Result<MathQuestion>.success(question);

  @override
  Future<Result<Solution>> solve(MathQuestion question) async =>
      Result<Solution>.failure(const NetworkFailure('not used'));

  @override
  Future<Result<MathQuestion>> historyItem(String id) async =>
      Result<MathQuestion>.success(_question(id: id));
}

Future<_FakeRepository> _pump(
  WidgetTester tester, {
  _FakeRepository? repository,
}) async {
  final _FakeRepository fake = repository ?? _FakeRepository();
  final MathApiController controller = MathApiController(fake);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: HistoryScreen(
        controller: controller,
        now: DateTime(2026, 9, 11, 12),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  testWidgets('loads and displays history items', (WidgetTester tester) async {
    await _pump(tester);

    expect(find.byType(HistoryItemTile), findsNWidgets(2));
    expect(find.text('Linear Equation'), findsWidgets);
    expect(find.text('Quadratic Equation'), findsWidgets);
    expect(find.textContaining('Answer:'), findsNWidgets(2));
  });

  testWidgets('shows empty history state', (WidgetTester tester) async {
    final _FakeRepository repository = _FakeRepository(empty: true);
    final MathApiController controller = MathApiController(repository);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HistoryScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No solved problems yet'), findsOneWidget);
  });

  testWidgets('shows retry on a history network error', (
    WidgetTester tester,
  ) async {
    final _FakeRepository repository = _FakeRepository(failHistory: true);
    await _pump(tester, repository: repository);

    expect(find.text('Could not load history'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('searches history through the controller', (
    WidgetTester tester,
  ) async {
    final _FakeRepository repository = await _pump(tester);

    await tester.enterText(find.byType(TextField), 'quadratic');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Quadratic Equation'), findsWidgets);
    expect(repository.historyCalls, greaterThanOrEqualTo(2));
  });

  testWidgets('deletes an item after confirmation', (
    WidgetTester tester,
  ) async {
    final _FakeRepository repository = await _pump(tester);

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.delete_outline).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Delete question?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository.deleted, contains('q-1'));
  });
}
