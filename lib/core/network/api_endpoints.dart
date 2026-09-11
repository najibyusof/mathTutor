import '../config/app_config.dart';

/// Central registry of Laravel REST API paths.
///
/// Paths are relative to [AppConfig.apiBaseUrl]; use [url] to build an
/// absolute URL for the active environment.
abstract final class ApiEndpoints {
  const ApiEndpoints._();

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String forgotPassword = '/auth/forgot-password';
  static const String logout = '/auth/logout';
  static const String user = '/auth/user';

  // Questions
  static const String questions = '/questions';
  static String questionItem(String id) => '/questions/$id';
  static String questionSolve(String id) => '/questions/$id/solve';
  static String questionSolution(String id) => '/questions/$id/solution';

  // Recognition (async: submit then poll)
  static const String recognitionImage = '/recognition/image';
  static const String recognitionHandwriting = '/recognition/handwriting';
  static String recognitionItem(String id) => '/recognition/$id';

  // Solutions (AI explanations attach to an already-solved question)
  static String solutionVerify(String id) => '/solutions/$id/verify';
  static String solutionExplanation(String id) => '/solutions/$id/explanation';
  static String solutionHint(String id) => '/solutions/$id/hint';

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
        (String key, dynamic value) => MapEntry<String, String>(key, '$value'),
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
