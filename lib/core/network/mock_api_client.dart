import '../errors/exceptions.dart';
import '../storage/token_storage.dart';
import '../../features/solver/data/explanations/basic_solution_explanation_service.dart';
import '../../features/solver/data/parsers/basic_math_parser.dart';
import '../../features/solver/data/services/basic_math_solving_service.dart';
import '../../features/solver/data/solvers/basic_math_solver.dart';
import '../../features/solver/data/validators/basic_solution_validator.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

/// In-memory stand-in for the Laravel API so the app is runnable before the
/// backend exists. Never used in production builds.
class MockApiClient implements ApiClient {
  MockApiClient({
    required TokenStorage tokenStorage,
    this.latency = const Duration(milliseconds: 600),
  }) : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;
  final Duration latency;

  /// Seeded demo account for local-only mock mode.
  static const String demoEmail = 'student@mathtutor.app';

  final Map<String, _MockAccount> _accounts = <String, _MockAccount>{
    demoEmail: const _MockAccount(id: 1, name: 'Alex Morgan', email: demoEmail),
  };

  final Map<String, String> _tokensByEmail = <String, String>{};
  final Map<String, String> _questions = <String, String>{};
  final List<Map<String, dynamic>> _questionRecords = <Map<String, dynamic>>[];
  int _nextId = 2;
  int _nextQuestionId = 1;

  BasicMathSolvingService get _solver => const BasicMathSolvingService(
    parser: BasicMathParser(),
    solver: BasicMathSolver(),
    validator: BasicSolutionValidator(),
    explainer: BasicSolutionExplanationService(),
  );

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
  }) async {
    await Future<void>.delayed(latency);

    if (path == ApiEndpoints.user) {
      final _MockAccount account = await _requireAccount();
      return <String, dynamic>{'data': account.toJson()};
    }
    if (path == ApiEndpoints.history) {
      return <String, dynamic>{
        'data': List<Map<String, dynamic>>.of(_questionRecords),
        'meta': <String, dynamic>{
          'current_page': 1,
          'per_page': queryParameters?['per_page'] ?? 20,
          'last_page': 1,
          'total': _questionRecords.length,
        },
      };
    }
    throw ServerException('Unhandled mock route: $path', statusCode: 404);
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    await Future<void>.delayed(latency);
    final Map<String, dynamic> payload = body ?? <String, dynamic>{};

    final String questionPrefix = '${ApiEndpoints.questions}/';
    if (path.startsWith(questionPrefix) && path.endsWith('/solve')) {
      final String id = path.substring(
        questionPrefix.length,
        path.length - '/solve'.length,
      );
      return _solveQuestion(id);
    }

    return switch (path) {
      ApiEndpoints.login => _login(payload),
      ApiEndpoints.register => _register(payload),
      ApiEndpoints.forgotPassword => _forgotPassword(payload),
      ApiEndpoints.logout => _logout(),
      ApiEndpoints.questions => _createQuestion(payload),
      _ => throw ServerException(
        'Unhandled mock route: $path',
        statusCode: 404,
      ),
    };
  }

  Map<String, dynamic> _createQuestion(Map<String, dynamic> body) {
    final String expression =
        '${body['normalized_expression'] ?? body['original_expression'] ?? ''}'
            .trim();
    final String id = 'q-${_nextQuestionId++}';
    _questions[id] = expression;
    final Map<String, dynamic> record = <String, dynamic>{
      'id': id,
      'original_expression': body['original_expression'] ?? expression,
      'normalized_expression': expression,
      'input_method': body['input_method'] ?? 'keyboard',
      'recognition_confidence': body['recognition_confidence'] ?? 1,
      'created_at': DateTime.now().toIso8601String(),
    };
    _questionRecords.removeWhere((item) => item['id'] == id);
    _questionRecords.insert(0, record);
    return <String, dynamic>{'data': record};
  }

  Map<String, dynamic> _solveQuestion(String id) {
    final String? expression = _questions[id];
    if (expression == null) {
      throw const NotFoundException('The mock question was not found.');
    }
    final solution = _solver.solve(expression).valueOrNull;
    if (solution == null) {
      throw const ValidationException(
        'The mock solver could not solve this expression.',
        statusCode: 422,
      );
    }
    return <String, dynamic>{
      'data': <String, dynamic>{
        'normalized_expression': expression,
        'steps': solution.steps
            .map(
              (step) => <String, dynamic>{
                'step_number': step.stepNumber,
                'expression': step.expression,
                'explanation': step.explanation,
                'operation': step.operation,
                'result': step.result,
              },
            )
            .toList(growable: false),
        'final_answer': solution.finalAnswer.expression,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
  }) async {
    await Future<void>.delayed(latency);
    if (path.startsWith(ApiEndpoints.history)) {
      return <String, dynamic>{'message': 'Deleted.'};
    }
    throw ServerException('Unhandled mock route: $path', statusCode: 404);
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
    await Future<void>.delayed(latency);
    throw ServerException('Unhandled mock route: $path', statusCode: 404);
  }

  Map<String, dynamic> _login(Map<String, dynamic> body) {
    final String email = '${body['email'] ?? ''}'.trim().toLowerCase();
    final String password = '${body['password'] ?? ''}';
    final _MockAccount? account = _accounts[email];

    if (account == null || password.isEmpty) {
      throw const UnauthorizedException(
        'These credentials do not match our records.',
        statusCode: 401,
      );
    }
    return _sessionFor(account);
  }

  Map<String, dynamic> _register(Map<String, dynamic> body) {
    final String name = '${body['name'] ?? ''}'.trim();
    final String email = '${body['email'] ?? ''}'.trim().toLowerCase();
    if (_accounts.containsKey(email)) {
      throw const ValidationException(
        'The given data was invalid.',
        statusCode: 422,
        fieldErrors: <String, List<String>>{
          'email': <String>['This email address is already registered.'],
        },
      );
    }

    final _MockAccount account = _MockAccount(
      id: _nextId++,
      name: name,
      email: email,
    );
    _accounts[email] = account;
    return _sessionFor(account);
  }

  Map<String, dynamic> _forgotPassword(Map<String, dynamic> body) {
    final String email = '${body['email'] ?? ''}'.trim().toLowerCase();
    if (!_accounts.containsKey(email)) {
      throw const ValidationException(
        'The given data was invalid.',
        statusCode: 422,
        fieldErrors: <String, List<String>>{
          'email': <String>['We could not find a user with that email.'],
        },
      );
    }
    return <String, dynamic>{
      'message': 'We have emailed your password reset link.',
    };
  }

  Map<String, dynamic> _logout() {
    _tokensByEmail.clear();
    return <String, dynamic>{'message': 'Signed out.'};
  }

  Map<String, dynamic> _sessionFor(_MockAccount account) {
    final String token =
        'mock-token-${account.id}-${DateTime.now().millisecondsSinceEpoch}';
    _tokensByEmail[account.email] = token;
    return <String, dynamic>{
      'token': token,
      'token_type': 'Bearer',
      'user': account.toJson(),
    };
  }

  Future<_MockAccount> _requireAccount() async {
    final String? token = await _tokenStorage.readToken();
    final String? email = _tokensByEmail.entries
        .where((MapEntry<String, String> entry) => entry.value == token)
        .map((MapEntry<String, String> entry) => entry.key)
        .firstOrNull;

    final _MockAccount? account = email == null ? null : _accounts[email];
    if (account == null) {
      throw const UnauthorizedException(
        'Your session has expired. Please sign in again.',
        statusCode: 401,
      );
    }
    return account;
  }
}

class _MockAccount {
  const _MockAccount({
    required this.id,
    required this.name,
    required this.email,
  });

  final int id;
  final String name;
  final String email;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'email': email,
    'email_verified_at': null,
  };
}
