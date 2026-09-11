import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/errors/failures.dart';
import 'package:mathtutor/core/network/api_client.dart';
import 'package:mathtutor/core/network/result.dart';
import 'package:mathtutor/features/math/data/datasources/math_remote_data_source.dart';
import 'package:mathtutor/features/math/data/models/math_api_models.dart';
import 'package:mathtutor/features/math/data/repositories/math_repository_impl.dart';
import 'package:mathtutor/features/math/domain/repositories/math_repository.dart';
import 'package:mathtutor/features/math/domain/models/history_page.dart';
import 'package:mathtutor/features/math/presentation/controllers/math_api_controller.dart';
import 'package:mathtutor/features/solver/domain/models/math_problem.dart';
import 'package:mathtutor/features/solver/domain/models/solution.dart';
import 'package:mathtutor/models/math_question.dart';
import 'package:mathtutor/models/question_input_method.dart';

class _FakeApiClient implements ApiClient {
  _FakeApiClient({this.responses = const <String, Map<String, dynamic>>{}});

  final Map<String, Map<String, dynamic>> responses;
  final List<String> paths = <String>[];
  final List<Map<String, dynamic>?> bodies = <Map<String, dynamic>?>[];
  final List<String> deleted = <String>[];

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
  }) async {
    paths.add(path);
    bodies.add(null);
    return responses[path] ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    paths.add(path);
    bodies.add(body);
    return responses[path] ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
  }) async {
    paths.add(path);
    deleted.add(path);
    bodies.add(null);
    return responses[path] ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
    Map<String, String>? fields,
    bool authenticated = true,
  }) async {
    paths.add(path);
    bodies.add(null);
    return responses[path] ?? <String, dynamic>{};
  }
}

Map<String, dynamic> _questionJson({String id = 'q-1'}) => <String, dynamic>{
  'data': <String, dynamic>{
    'id': id,
    'original_input': '2x + 8 = 20',
    'normalized_expression': '2x+8=20',
    'input_method': 'keyboard',
    'confidence': 1,
    'created_at': '2026-09-11T10:00:00Z',
  },
};

Map<String, dynamic> _solutionJson() => <String, dynamic>{
  'data': <String, dynamic>{
    'normalized_expression': '2x+8=20',
    'steps': <Map<String, dynamic>>[
      <String, dynamic>{
        'step_number': 1,
        'expression': '2x = 12',
        'explanation': 'Subtract 8 from both sides.',
        'operation': 'subtract',
      },
    ],
    'final_answer': <String, dynamic>{
      'expression': 'x = 6',
      'numeric_value': 6,
    },
  },
};

MathQuestion _question() => MathQuestion.create(
  id: 'q-1',
  originalInput: '2x + 8 = 20',
  normalizedExpression: '2x+8=20',
  inputMethod: QuestionInputMethod.keyboard,
);

Solution _solution() => const Solution(
  problem: MathProblem(
    originalInput: '2x + 8 = 20',
    normalizedExpression: '2x+8=20',
    category: MathCategory.linearEquation,
    parsed: ParsedMathExpression(
      original: '2x + 8 = 20',
      normalized: '2x+8=20',
      left: Polynomial(constant: 8, linear: 2),
      right: Polynomial(constant: 20),
    ),
  ),
  steps: <SolutionStep>[
    SolutionStep(
      stepNumber: 1,
      expression: '2x = 12',
      explanation: 'Subtract 8 from both sides.',
    ),
  ],
  finalAnswer: FinalAnswer(expression: 'x = 6', numericValue: 6),
);

void main() {
  test('question DTO parses Laravel data and serializes API fields', () {
    final MathQuestion question = MathQuestionDto.fromJson(
      _questionJson(),
    ).question;

    expect(question.id, 'q-1');
    expect(question.normalizedExpression, '2x+8=20');
    expect(question.inputMethod, QuestionInputMethod.keyboard);
    expect(
      MathQuestionDto(question).toJson()['normalized_expression'],
      '2x+8=20',
    );
  });

  test('solution DTO parses structured steps and final answer', () {
    final Solution solution = SolutionDto.fromJson(_solutionJson()).solution;

    expect(solution.steps.single.explanation, 'Subtract 8 from both sides.');
    expect(solution.finalAnswer.expression, 'x = 6');
    expect(solution.finalAnswer.numericValue, 6);
  });

  test(
    'repository maps solve, explain, history and delete endpoints',
    () async {
      final _FakeApiClient client = _FakeApiClient(
        responses: <String, Map<String, dynamic>>{
          '/questions': _questionJson(),
          '/questions/q-1/solve': _solutionJson(),
          '/history': <String, dynamic>{
            'data': <Map<String, dynamic>>[
              _questionJson()['data'] as Map<String, dynamic>,
            ],
          },
          '/history/q-1': _questionJson(),
        },
      );
      final MathRepository repository = MathRepositoryImpl(
        MathRemoteDataSource(client),
      );

      expect((await repository.submitQuestion(_question())).isSuccess, isTrue);
      expect(
        (await repository.solve(
          _question(),
        )).valueOrNull?.finalAnswer.expression,
        'x = 6',
      );
      expect((await repository.history()).valueOrNull?.items, hasLength(1));
      expect((await repository.historyItem('q-1')).valueOrNull?.id, 'q-1');
      expect((await repository.deleteHistoryItem('q-1')).isSuccess, isTrue);
      expect(client.deleted, contains('/history/q-1'));
    },
  );

  test('repository maps malformed server data to a failure', () async {
    final MathRepository repository = MathRepositoryImpl(
      MathRemoteDataSource(
        _FakeApiClient(
          responses: <String, Map<String, dynamic>>{
            '/questions/q-1/solve': <String, dynamic>{
              'data': <String, dynamic>{},
            },
          },
        ),
      ),
    );

    final Result<Solution> result = await repository.solve(_question());

    expect(result.failureOrNull, isA<UnexpectedFailure>());
  });

  test('controller persists then solves successful questions', () async {
    final _ControllerRepository repository = _ControllerRepository();
    final MathApiController controller = MathApiController(repository);
    addTearDown(controller.dispose);

    expect(await controller.solve(_question()), isTrue);
    expect(repository.solveCalls, 1);
    expect(repository.submitCalls, 1);
    expect(controller.solution?.finalAnswer.expression, 'x = 6');
    expect(controller.status, MathApiStatus.success);
  });

  test('controller exposes API failures without widget coupling', () async {
    final _ControllerRepository repository = _ControllerRepository(
      failure: const NetworkFailure('offline'),
    );
    final MathApiController controller = MathApiController(repository);
    addTearDown(controller.dispose);

    expect(await controller.solve(_question()), isFalse);
    expect(controller.status, MathApiStatus.failure);
    expect(
      controller.errorMessage,
      contains('Unable to connect to the server'),
    );
  });
}

class _ControllerRepository implements MathRepository {
  _ControllerRepository({this.failure});

  final Failure? failure;
  int solveCalls = 0;
  int submitCalls = 0;

  @override
  Future<Result<MathQuestion>> submitQuestion(MathQuestion question) async {
    submitCalls++;
    return Result<MathQuestion>.success(question);
  }

  @override
  Future<Result<Solution>> solve(MathQuestion question) async {
    solveCalls++;
    if (failure != null) {
      return Result<Solution>.failure(failure!);
    }
    return Result<Solution>.success(_solution());
  }

  @override
  Future<Result<HistoryPage>> history({
    int page = 1,
    int perPage = 20,
    String? query,
    MathCategory? category,
  }) async => const Result<HistoryPage>.success(
    HistoryPage(items: <MathQuestion>[], currentPage: 1, lastPage: 1, total: 0),
  );

  @override
  Future<Result<MathQuestion>> historyItem(String id) async =>
      Result<MathQuestion>.success(_question());

  @override
  Future<Result<void>> deleteHistoryItem(String id) async =>
      const Result<void>.success(null);
}
