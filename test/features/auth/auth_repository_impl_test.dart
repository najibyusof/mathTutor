import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/errors/exceptions.dart';
import 'package:mathtutor/core/errors/failures.dart';
import 'package:mathtutor/core/network/api_client.dart';
import 'package:mathtutor/core/network/api_endpoints.dart';
import 'package:mathtutor/core/network/result.dart';
import 'package:mathtutor/core/storage/token_storage.dart';
import 'package:mathtutor/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mathtutor/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mathtutor/features/auth/domain/entities/auth_user.dart';
import 'package:mathtutor/features/auth/domain/repositories/auth_repository.dart';

/// Returns canned responses (or throws) per endpoint.
class _FakeApiClient implements ApiClient {
  _FakeApiClient({this.responses = const <String, Object>{}});

  /// Value per path: a JSON map to return, or an [Object] to throw.
  final Map<String, Object> responses;
  final List<String> calls = <String>[];

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
  }) => _resolve(path);

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) => _resolve(path);

  Future<Map<String, dynamic>> _resolve(String path) async {
    calls.add(path);
    final Object? response = responses[path];
    if (response is Map<String, dynamic>) {
      return response;
    }
    if (response != null) {
      throw response;
    }
    return <String, dynamic>{};
  }
}

Map<String, dynamic> _sessionJson({String token = 'token-123'}) =>
    <String, dynamic>{
      'token': token,
      'token_type': 'Bearer',
      'user': <String, dynamic>{
        'id': 7,
        'name': 'Alex Morgan',
        'email': 'student@mathtutor.app',
        'email_verified_at': null,
      },
    };

AuthRepository _buildRepository(
  _FakeApiClient client,
  TokenStorage storage,
) {
  return AuthRepositoryImpl(
    remote: AuthRemoteDataSource(client),
    tokenStorage: storage,
  );
}

void main() {
  group('login', () {
    test('stores the bearer token and returns the user', () async {
      final InMemoryTokenStorage storage = InMemoryTokenStorage();
      final AuthRepository repository = _buildRepository(
        _FakeApiClient(
          responses: <String, Object>{ApiEndpoints.login: _sessionJson()},
        ),
        storage,
      );

      final Result<AuthUser> result = await repository.login(
        email: 'student@mathtutor.app',
        password: 'password123',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.email, 'student@mathtutor.app');
      expect(await storage.readToken(), 'token-123');
    });

    test('maps invalid credentials to an unauthorized failure', () async {
      final InMemoryTokenStorage storage = InMemoryTokenStorage();
      final AuthRepository repository = _buildRepository(
        _FakeApiClient(
          responses: <String, Object>{
            ApiEndpoints.login: const UnauthorizedException(
              'These credentials do not match our records.',
              statusCode: 401,
            ),
          },
        ),
        storage,
      );

      final Result<AuthUser> result = await repository.login(
        email: 'student@mathtutor.app',
        password: 'wrong',
      );

      expect(result.failureOrNull, isA<UnauthorizedFailure>());
      expect(await storage.readToken(), isNull);
    });

    test('maps transport errors to a network failure', () async {
      final AuthRepository repository = _buildRepository(
        _FakeApiClient(
          responses: <String, Object>{
            ApiEndpoints.login: const NetworkException('offline'),
          },
        ),
        InMemoryTokenStorage(),
      );

      final Result<AuthUser> result = await repository.login(
        email: 'a@b.c',
        password: 'secret123',
      );

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('maps 5xx responses to a server failure', () async {
      final AuthRepository repository = _buildRepository(
        _FakeApiClient(
          responses: <String, Object>{
            ApiEndpoints.login: const ServerException('boom', statusCode: 500),
          },
        ),
        InMemoryTokenStorage(),
      );

      final Result<AuthUser> result = await repository.login(
        email: 'a@b.c',
        password: 'secret123',
      );

      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });

  test('register surfaces field-level validation errors', () async {
    final AuthRepository repository = _buildRepository(
      _FakeApiClient(
        responses: <String, Object>{
          ApiEndpoints.register: const ValidationException(
            'The given data was invalid.',
            statusCode: 422,
            fieldErrors: <String, List<String>>{
              'email': <String>['This email address is already registered.'],
            },
          ),
        },
      ),
      InMemoryTokenStorage(),
    );

    final Result<AuthUser> result = await repository.register(
      name: 'Alex',
      email: 'taken@mathtutor.app',
      password: 'secret123',
      passwordConfirmation: 'secret123',
    );

    final Failure? failure = result.failureOrNull;
    expect(failure, isA<ValidationFailure>());
    expect(
      (failure! as ValidationFailure).fieldErrors['email'],
      contains('This email address is already registered.'),
    );
  });

  group('currentUser', () {
    test('fails without calling the API when no token is stored', () async {
      final _FakeApiClient client = _FakeApiClient();
      final AuthRepository repository = _buildRepository(
        client,
        InMemoryTokenStorage(),
      );

      final Result<AuthUser> result = await repository.currentUser();

      expect(result.failureOrNull, isA<UnauthorizedFailure>());
      expect(client.calls, isEmpty);
    });

    test('clears an expired token', () async {
      final InMemoryTokenStorage storage = InMemoryTokenStorage('expired');
      final AuthRepository repository = _buildRepository(
        _FakeApiClient(
          responses: <String, Object>{
            ApiEndpoints.user: const UnauthorizedException(
              'Unauthenticated.',
              statusCode: 401,
            ),
          },
        ),
        storage,
      );

      final Result<AuthUser> result = await repository.currentUser();

      expect(result.failureOrNull, isA<UnauthorizedFailure>());
      expect(await storage.readToken(), isNull);
    });

    test('returns the user for a valid token', () async {
      final AuthRepository repository = _buildRepository(
        _FakeApiClient(
          responses: <String, Object>{
            ApiEndpoints.user: <String, dynamic>{
              'data': <String, dynamic>{
                'id': 7,
                'name': 'Alex Morgan',
                'email': 'student@mathtutor.app',
              },
            },
          },
        ),
        InMemoryTokenStorage('valid'),
      );

      final Result<AuthUser> result = await repository.currentUser();

      expect(result.valueOrNull?.name, 'Alex Morgan');
    });
  });

  test('logout clears the token even when the API call fails', () async {
    final InMemoryTokenStorage storage = InMemoryTokenStorage('token-123');
    final AuthRepository repository = _buildRepository(
      _FakeApiClient(
        responses: <String, Object>{
          ApiEndpoints.logout: const NetworkException('offline'),
        },
      ),
      storage,
    );

    final Result<void> result = await repository.logout();

    expect(result.failureOrNull, isA<NetworkFailure>());
    expect(await storage.readToken(), isNull);
  });
}
