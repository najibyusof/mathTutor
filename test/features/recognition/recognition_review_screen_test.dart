import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/config/app_config.dart';
import 'package:mathtutor/core/di/app_dependencies.dart';
import 'package:mathtutor/core/di/app_scope.dart';
import 'package:mathtutor/core/errors/failures.dart';
import 'package:mathtutor/core/network/result.dart';
import 'package:mathtutor/core/theme/app_theme.dart';
import 'package:mathtutor/features/handwriting/domain/entities/handwriting_sample.dart';
import 'package:mathtutor/features/handwriting/domain/entities/stroke.dart';
import 'package:mathtutor/features/recognition/domain/entities/recognition_request.dart';
import 'package:mathtutor/features/recognition/domain/services/question_recognition_service.dart';
import 'package:mathtutor/features/recognition/presentation/pages/recognition_review_screen.dart';
import 'package:mathtutor/features/solver/presentation/pages/solution_screen.dart';
import 'package:mathtutor/models/math_question.dart';
import 'package:mathtutor/models/question_input_method.dart';
import 'package:mathtutor/routes/app_router.dart';

class _StubService implements QuestionRecognitionService {
  _StubService({this.failure});

  final Failure? failure;
  int calls = 0;

  @override
  Future<Result<MathQuestion>> recognize(RecognitionRequest request) async {
    calls++;
    if (failure != null) {
      return Result<MathQuestion>.failure(failure!);
    }
    return Result<MathQuestion>.success(
      MathQuestion.create(
        originalInput: 'retry',
        normalizedExpression: '9*x=81',
        inputMethod: request.method,
        confidence: 0.97,
      ),
    );
  }
}

HandwritingInput _handwritingSource() => HandwritingInput(
  HandwritingSample.fromStrokes(<Stroke>[
    Stroke(
      points: const <StrokePoint>[
        StrokePoint(Offset(0, 0)),
        StrokePoint(Offset(9, 9)),
      ],
    ),
  ], const Size(100, 100)),
);

MathQuestion _question({
  double confidence = 0.94,
  QuestionInputMethod method = QuestionInputMethod.handwriting,
  String expression = '2*x+5=15',
}) => MathQuestion.create(
  id: 'q-1',
  originalInput: '5 handwritten strokes',
  normalizedExpression: expression,
  inputMethod: method,
  confidence: confidence,
  createdAt: DateTime(2026, 3, 18, 12),
);

Future<_StubService> _pumpReview(
  WidgetTester tester, {
  MathQuestion? question,
  RecognitionRequest? source,
  Failure? failure,
  Brightness brightness = Brightness.light,
  Size size = const Size(420, 1200),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final _StubService service = _StubService(failure: failure);
  await tester.pumpWidget(
    AppScope(
      dependencies: AppDependencies.create(
        config: const AppConfig(
          environment: AppEnvironment.development,
          apiBaseUrl: 'http://10.0.2.2:8000/api/v1',
          apiTimeout: Duration(seconds: 10),
          enableLogging: true,
          useMockApi: true,
        ),
      ),
      child: MaterialApp(
        theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: RecognitionReviewScreen(
          service: service,
          args: RecognitionReviewArgs(
            question: question ?? _question(),
            source: source,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return service;
}

void main() {
  testWidgets('shows the recognized question and its confidence', (
    WidgetTester tester,
  ) async {
    await _pumpReview(tester);

    expect(find.text('Recognized question'), findsOneWidget);
    expect(find.text('Confidence: High'), findsOneWidget);
    expect(find.text('94%'), findsOneWidget);
    expect(find.textContaining('handwritten strokes'), findsOneWidget);
  });

  testWidgets('warns the student when confidence is low', (
    WidgetTester tester,
  ) async {
    await _pumpReview(tester, question: _question(confidence: 0.42));

    expect(find.text('Confidence: Low'), findsOneWidget);
    expect(
      find.textContaining('check the equation and edit it before solving'),
      findsOneWidget,
    );
  });

  testWidgets('medium confidence is labelled without the warning', (
    WidgetTester tester,
  ) async {
    await _pumpReview(tester, question: _question(confidence: 0.7));

    expect(find.text('Confidence: Medium'), findsOneWidget);
    expect(
      find.textContaining('check the equation and edit it before solving'),
      findsNothing,
    );
  });

  testWidgets('the expression can always be edited before solving', (
    WidgetTester tester,
  ) async {
    await _pumpReview(tester, question: _question(confidence: 0.42));

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit the question'), findsOneWidget);

    await tester.tap(find.widgetWithIcon(InkWell, Icons.backspace_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InkWell, '9').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // A verified expression is trusted, so the warning disappears.
    expect(find.text('Confidence: High'), findsOneWidget);
    expect(
      find.textContaining('check the equation and edit it before solving'),
      findsNothing,
    );
  });

  testWidgets('editing can be cancelled', (WidgetTester tester) async {
    await _pumpReview(tester);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Recognized question'), findsOneWidget);
    expect(find.text('Confidence: High'), findsOneWidget);
  });

  testWidgets('retry is offered for recognized input only', (
    WidgetTester tester,
  ) async {
    await _pumpReview(tester);
    expect(find.text('Retry'), findsNothing);

    await _pumpReview(
      tester,
      question: _question(method: QuestionInputMethod.keyboard, confidence: 1),
      source: const KeyboardInput('2*x+5=15'),
    );
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('retry re-runs recognition with the same input', (
    WidgetTester tester,
  ) async {
    final _StubService service = await _pumpReview(
      tester,
      question: _question(confidence: 0.5),
      source: _handwritingSource(),
    );

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(service.calls, 1);
    expect(find.text('97%'), findsOneWidget);
    expect(find.text('Confidence: High'), findsOneWidget);
  });

  testWidgets('a failed retry keeps the question and explains the error', (
    WidgetTester tester,
  ) async {
    await _pumpReview(
      tester,
      question: _question(confidence: 0.5),
      source: _handwritingSource(),
      failure: const NetworkFailure('offline'),
    );

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Recognition failed'), findsOneWidget);
    expect(
      find.textContaining('Unable to connect to the server'),
      findsOneWidget,
    );
    expect(find.text('Confidence: Medium'), findsNothing);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('solve hands the normalized expression to the solver', (
    WidgetTester tester,
  ) async {
    await _pumpReview(tester);

    await tester.tap(find.text('Solve'));
    await tester.pumpAndSettle();

    expect(find.byType(SolutionScreen), findsOneWidget);
    expect(find.text('x = 5'), findsNWidgets(2));
  });
}
