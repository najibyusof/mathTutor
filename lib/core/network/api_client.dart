import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../errors/exceptions.dart';
import '../storage/token_storage.dart';
import '../utils/app_logger.dart';
import 'api_endpoints.dart';

/// Transport abstraction used by every repository.
///
/// Keeps features free of `package:http` and of token handling.
abstract interface class ApiClient {
  /// Sends a GET request and returns the decoded JSON object.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
  });

  /// Sends a POST request with a JSON body and returns the decoded response.
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  });

  /// Sends an authenticated DELETE request.
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
  });

  /// Uploads a single file as `multipart/form-data` and returns the decoded
  /// JSON response. Used by endpoints that accept an image (e.g. recognition
  /// submission), which the Laravel API does not accept as a JSON body.
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
    Map<String, String>? fields,
    bool authenticated = true,
  });
}

/// `package:http` implementation that attaches the bearer token, applies the
/// configured timeout and maps transport/HTTP errors onto [AppException]s.
class HttpApiClient implements ApiClient {
  HttpApiClient({
    required TokenStorage tokenStorage,
    http.Client? httpClient,
    AppConfig? config,
    this.onUnauthorized,
  }) : _tokenStorage = tokenStorage,
       _client = httpClient ?? http.Client(),
       _config = config;

  final TokenStorage _tokenStorage;
  final http.Client _client;
  final AppConfig? _config;

  /// Invoked when the API rejects the stored token (expired or revoked).
  final Future<void> Function()? onUnauthorized;

  AppConfig get _activeConfig => _config ?? AppConfigScope.current;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
  }) {
    return _send(
      'GET',
      path,
      queryParameters: queryParameters,
      authenticated: authenticated,
    );
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _send('POST', path, body: body, authenticated: authenticated);
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
  }) => _send(
    'DELETE',
    path,
    queryParameters: queryParameters,
    authenticated: authenticated,
  );

  @override
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
    Map<String, String>? fields,
    bool authenticated = true,
  }) async {
    final Uri uri = ApiEndpoints.url(path);
    if (_activeConfig.environment.isProduction && uri.scheme != 'https') {
      throw StateError('Production API requests require HTTPS.');
    }
    final Map<String, String> headers = Map<String, String>.of(
      await _headers(authenticated),
    );
    headers.remove(ApiHeaders.contentType);

    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers)
      ..fields.addAll(fields ?? const <String, String>{})
      ..files.add(
        http.MultipartFile.fromBytes(fieldName, bytes, filename: filename),
      );

    try {
      final http.StreamedResponse streamed = await _client
          .send(request)
          .timeout(_activeConfig.apiTimeout);
      final http.Response response = await http.Response.fromStream(streamed);
      return await _handleResponse(response);
    } on SocketException {
      throw const NetworkException(
        'No internet connection. Check your network and try again.',
      );
    } on http.ClientException catch (error) {
      throw NetworkException(error.message);
    } on TimeoutException {
      throw const NetworkException(
        'The request took too long. Please try again.',
      );
    } on FormatException {
      throw const ParsingException('The server returned an invalid response.');
    }
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? body,
    required bool authenticated,
    bool allowRetry = true,
  }) async {
    final Uri uri = ApiEndpoints.url(path, queryParameters: queryParameters);
    if (_activeConfig.environment.isProduction && uri.scheme != 'https') {
      throw StateError('Production API requests require HTTPS.');
    }
    final Map<String, String> headers = await _headers(authenticated);

    try {
      final http.Response response = await switch (method) {
        'POST' => _client.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ),
        'DELETE' => _client.delete(uri, headers: headers),
        _ => _client.get(uri, headers: headers),
      }.timeout(_activeConfig.apiTimeout);

      return await _handleResponse(response);
    } on SocketException {
      if (method == 'GET' && allowRetry) {
        return _send(
          method,
          path,
          queryParameters: queryParameters,
          body: body,
          authenticated: authenticated,
          allowRetry: false,
        );
      }
      throw const NetworkException(
        'No internet connection. Check your network and try again.',
      );
    } on http.ClientException catch (error) {
      throw NetworkException(error.message);
    } on TimeoutException {
      if (method == 'GET' && allowRetry) {
        return _send(
          method,
          path,
          queryParameters: queryParameters,
          body: body,
          authenticated: authenticated,
          allowRetry: false,
        );
      }
      throw const NetworkException(
        'The request took too long. Please try again.',
      );
    } on FormatException {
      throw const ParsingException('The server returned an invalid response.');
    }
  }

  Future<Map<String, String>> _headers(bool authenticated) async {
    if (!authenticated) {
      return ApiHeaders.json;
    }
    final String? token = await _tokenStorage.readToken();
    return token == null ? ApiHeaders.json : ApiHeaders.bearer(token);
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final Map<String, dynamic> json = _decode(response.body);
    final int status = response.statusCode;

    if (status >= 200 && status < 300) {
      return json;
    }

    final String message = json['message'] as String? ?? '';
    AppLogger.debug(
      'API response status=$status method=${response.request?.method ?? 'unknown'}',
    );

    if (status == 401 || status == 403) {
      await onUnauthorized?.call();
      throw UnauthorizedException(
        message.isEmpty
            ? 'Your session has expired. Please sign in again.'
            : message,
        statusCode: status,
      );
    }
    if (status == 422) {
      throw ValidationException(
        message.isEmpty ? 'Please check the highlighted fields.' : message,
        statusCode: status,
        fieldErrors: _fieldErrors(json['errors']),
      );
    }
    if (status == 404) {
      throw NotFoundException(
        message.isEmpty ? 'The requested resource was not found.' : message,
        statusCode: status,
      );
    }
    if (status >= 500) {
      throw ServerException(
        message.isEmpty
            ? 'The server is not responding. Please try again later.'
            : message,
        statusCode: status,
      );
    }
    throw ServerException(
      message.isEmpty ? 'Something went wrong.' : message,
      statusCode: status,
    );
  }

  Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }
    final Object? decoded = jsonDecode(body);
    return decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};
  }

  Map<String, List<String>> _fieldErrors(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return const <String, List<String>>{};
    }
    return raw.map(
      (String field, dynamic messages) => MapEntry<String, List<String>>(
        field,
        messages is List
            ? messages.map((Object? item) => '$item').toList(growable: false)
            : <String>['$messages'],
      ),
    );
  }
}
