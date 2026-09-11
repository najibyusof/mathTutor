import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mathtutor/core/config/app_config.dart';
import 'package:mathtutor/core/errors/exceptions.dart';
import 'package:mathtutor/core/network/api_client.dart';
import 'package:mathtutor/core/storage/token_storage.dart';

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient({required this.handler});

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  handler;
  int calls = 0;
  Uri? lastUri;
  Map<String, String>? lastHeaders;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls++;
    lastUri = request.url;
    lastHeaders = request.headers;
    return handler(request);
  }
}

http.StreamedResponse _jsonResponse(int status, Map<String, dynamic> body) =>
    http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(jsonEncode(body))),
      status,
      headers: <String, String>{'content-type': 'application/json'},
    );

AppConfig _config({Duration timeout = const Duration(seconds: 1)}) => AppConfig(
  environment: AppEnvironment.staging,
  apiBaseUrl: 'https://api.test.local/api',
  apiTimeout: timeout,
  enableLogging: false,
);

void main() {
  test('maps a 200 JSON response and attaches the bearer token', () async {
    final _FakeHttpClient client = _FakeHttpClient(
      handler: (_) async => _jsonResponse(200, <String, dynamic>{'ok': true}),
    );
    final HttpApiClient api = HttpApiClient(
      tokenStorage: InMemoryTokenStorage('token-123'),
      httpClient: client,
      config: _config(),
    );

    final Map<String, dynamic> response = await api.get('/user');

    expect(response['ok'], isTrue);
    expect(client.lastHeaders?['Authorization'], 'Bearer token-123');
    expect(client.lastHeaders?['Accept'], 'application/json');
  });

  test('maps 401 and invokes the unauthorized callback', () async {
    bool invalidated = false;
    final HttpApiClient api = HttpApiClient(
      tokenStorage: InMemoryTokenStorage('token'),
      httpClient: _FakeHttpClient(
        handler: (_) async => _jsonResponse(401, <String, dynamic>{}),
      ),
      config: _config(),
      onUnauthorized: () async => invalidated = true,
    );

    await expectLater(api.get('/user'), throwsA(isA<UnauthorizedException>()));
    expect(invalidated, isTrue);
  });

  test('maps 422 validation errors', () async {
    final HttpApiClient api = HttpApiClient(
      tokenStorage: InMemoryTokenStorage(),
      httpClient: _FakeHttpClient(
        handler: (_) async => _jsonResponse(422, <String, dynamic>{
          'message': 'Invalid data',
          'errors': <String, dynamic>{
            'email': <String>['Email is invalid'],
          },
        }),
      ),
      config: _config(),
    );

    try {
      await api.post('/login', authenticated: false);
      fail('Expected validation exception');
    } on ValidationException catch (error) {
      expect(error.fieldErrors['email'], contains('Email is invalid'));
    }
  });

  test('maps 404 to a distinct not-found error, not a server outage', () async {
    final HttpApiClient api = HttpApiClient(
      tokenStorage: InMemoryTokenStorage(),
      httpClient: _FakeHttpClient(
        handler: (_) async => _jsonResponse(404, <String, dynamic>{
          'message': 'Resource not found',
        }),
      ),
      config: _config(),
    );

    try {
      await api.post('/register', authenticated: false);
      fail('Expected a not-found exception');
    } on NotFoundException catch (error) {
      expect(error.message, 'Resource not found');
      expect(error.statusCode, 404);
    }
  });

  test('maps 500 server errors', () async {
    final HttpApiClient api = HttpApiClient(
      tokenStorage: InMemoryTokenStorage(),
      httpClient: _FakeHttpClient(
        handler: (_) async => _jsonResponse(500, <String, dynamic>{}),
      ),
      config: _config(),
    );

    await expectLater(api.get('/math/solve'), throwsA(isA<ServerException>()));
  });

  test('maps network unavailability', () async {
    final _FakeHttpClient client = _FakeHttpClient(
      handler: (_) async => throw const SocketException('offline'),
    );
    final HttpApiClient api = HttpApiClient(
      tokenStorage: InMemoryTokenStorage(),
      httpClient: client,
      config: _config(),
    );

    await expectLater(
      api.post('/math/solve'),
      throwsA(isA<NetworkException>()),
    );
    expect(client.calls, 1);
  });

  test('retries a GET once after a timeout but never retries a POST', () async {
    late final _FakeHttpClient getClient;
    getClient = _FakeHttpClient(
      handler: (_) async {
        if (getClient.calls == 1) {
          await Future<void>.delayed(const Duration(milliseconds: 30));
        }
        return _jsonResponse(200, <String, dynamic>{'ok': true});
      },
    );
    final HttpApiClient getApi = HttpApiClient(
      tokenStorage: InMemoryTokenStorage(),
      httpClient: getClient,
      config: _config(timeout: const Duration(milliseconds: 5)),
    );

    final Map<String, dynamic> retried = await getApi.get('/history');
    expect(retried['ok'], isTrue);
    expect(getClient.calls, 2);

    final _FakeHttpClient postClient = _FakeHttpClient(
      handler: (_) async => Future<http.StreamedResponse>.delayed(
        const Duration(milliseconds: 30),
        () => _jsonResponse(200, <String, dynamic>{}),
      ),
    );
    final HttpApiClient postApi = HttpApiClient(
      tokenStorage: InMemoryTokenStorage(),
      httpClient: postClient,
      config: _config(timeout: const Duration(milliseconds: 5)),
    );

    try {
      await postApi.post('/math/solve');
      fail('Expected a timeout network exception');
    } on NetworkException {
      // Expected: POST requests fail once and are not retried.
    }
    expect(postClient.calls, 1);
  });

  test('does not send an authorization header without a token', () async {
    final _FakeHttpClient client = _FakeHttpClient(
      handler: (_) async => _jsonResponse(200, <String, dynamic>{}),
    );
    final HttpApiClient api = HttpApiClient(
      tokenStorage: InMemoryTokenStorage(),
      httpClient: client,
      config: _config(),
    );

    await api.get('/login', authenticated: false);

    expect(client.lastHeaders?.containsKey('Authorization'), isFalse);
  });
}
