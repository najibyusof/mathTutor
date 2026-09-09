import '../errors/exceptions.dart';
import '../storage/token_storage.dart';
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

  /// Seeded demo account; the password is only a fixture for the mock backend.
  static const String demoEmail = 'student@mathtutor.app';
  static const String demoPassword = 'password123';

  final Map<String, _MockAccount> _accounts = <String, _MockAccount>{
    demoEmail: const _MockAccount(
      id: 1,
      name: 'Alex Morgan',
      email: demoEmail,
      password: demoPassword,
    ),
  };

  final Map<String, String> _tokensByEmail = <String, String>{};
  int _nextId = 2;

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

    return switch (path) {
      ApiEndpoints.login => _login(payload),
      ApiEndpoints.register => _register(payload),
      ApiEndpoints.forgotPassword => _forgotPassword(payload),
      ApiEndpoints.logout => _logout(),
      _ => throw ServerException('Unhandled mock route: $path', statusCode: 404),
    };
  }

  Map<String, dynamic> _login(Map<String, dynamic> body) {
    final String email = '${body['email'] ?? ''}'.trim().toLowerCase();
    final String password = '${body['password'] ?? ''}';
    final _MockAccount? account = _accounts[email];

    if (account == null || account.password != password) {
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
    final String password = '${body['password'] ?? ''}';

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
      password: password,
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
    required this.password,
  });

  final int id;
  final String name;
  final String email;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'email': email,
    'email_verified_at': null,
  };
}
