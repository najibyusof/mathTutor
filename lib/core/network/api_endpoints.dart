import '../config/app_config.dart';

/// Central registry of Laravel REST API paths.
///
/// Paths are relative to [AppConfig.apiBaseUrl]; use [url] to build an
/// absolute URL for the active environment.
abstract final class ApiEndpoints {
  const ApiEndpoints._();

  // Auth
  static const String register = '/register';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String logout = '/logout';
  static const String user = '/user';

  // Solver
  static const String solveExpression = '/solve/expression';
  static const String solveHandwriting = '/solve/handwriting';
  static const String solveImage = '/solve/image';

  // History
  static const String history = '/history';
  static String historyItem(String id) => '/history/$id';

  // Profile
  static const String profile = '/profile';

  /// Absolute URL for [path] using the currently active configuration.
  static Uri url(String path, {Map<String, dynamic>? queryParameters}) {
    final Uri base = Uri.parse('${AppConfigScope.current.apiBaseUrl}$path');
    if (queryParameters == null || queryParameters.isEmpty) {
      return base;
    }
    return base.replace(
      queryParameters: queryParameters.map(
        (String key, dynamic value) =>
            MapEntry<String, String>(key, '$value'),
      ),
    );
  }
}

/// Header names and values shared by every REST request.
abstract final class ApiHeaders {
  const ApiHeaders._();

  static const String accept = 'Accept';
  static const String contentType = 'Content-Type';
  static const String authorization = 'Authorization';

  static const Map<String, String> json = <String, String>{
    accept: 'application/json',
    contentType: 'application/json',
  };

  static Map<String, String> bearer(String token) => <String, String>{
    ...json,
    authorization: 'Bearer $token',
  };
}
