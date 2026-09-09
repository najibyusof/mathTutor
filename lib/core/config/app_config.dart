/// Build flavors supported by the application.
enum AppEnvironment {
  development,
  staging,
  production;

  bool get isDevelopment => this == AppEnvironment.development;
  bool get isProduction => this == AppEnvironment.production;
}

/// Immutable, environment-specific application configuration.
///
/// Values are resolved from `--dart-define` at build time so no secrets or
/// environment-specific URLs are hardcoded into a single build:
///
/// ```
/// flutter run --dart-define=APP_ENV=production \
///             --dart-define=API_BASE_URL=https://api.mathtutor.app
/// ```
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.apiTimeout,
    required this.enableLogging,
    this.useMockApi = false,
  });

  final AppEnvironment environment;

  /// Root URL of the Laravel REST API, without a trailing slash.
  final String apiBaseUrl;

  /// Timeout applied to every REST request.
  final Duration apiTimeout;

  /// Whether verbose logging (network, navigation) is enabled.
  final bool enableLogging;

  /// Serves canned API responses so the app runs without a backend.
  /// Always disabled in production builds.
  final bool useMockApi;

  static const String _envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  static const int _apiTimeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT_SECONDS',
    defaultValue: 30,
  );

  static const bool _useMockApi = bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: true,
  );

  /// Default API roots per environment; overridable via `API_BASE_URL`.
  static const Map<AppEnvironment, String> defaultApiBaseUrls =
      <AppEnvironment, String>{
        // 10.0.2.2 is the host machine as seen from the Android emulator.
        AppEnvironment.development: 'http://10.0.2.2:8000/api',
        AppEnvironment.staging: 'https://staging.mathtutor.app/api',
        AppEnvironment.production: 'https://api.mathtutor.app/api',
      };

  /// Builds the configuration for the current build using compile-time
  /// environment values.
  factory AppConfig.fromEnvironment() {
    final AppEnvironment environment = _parseEnvironment(_envName);
    final String baseUrl = _apiBaseUrlOverride.isNotEmpty
        ? _apiBaseUrlOverride
        : defaultApiBaseUrls[environment]!;

    return AppConfig(
      environment: environment,
      apiBaseUrl: _stripTrailingSlash(baseUrl),
      apiTimeout: const Duration(seconds: _apiTimeoutSeconds),
      enableLogging: !environment.isProduction,
      useMockApi: _useMockApi && !environment.isProduction,
    );
  }

  static AppEnvironment _parseEnvironment(String value) {
    return AppEnvironment.values.firstWhere(
      (AppEnvironment env) => env.name == value.toLowerCase(),
      orElse: () => AppEnvironment.development,
    );
  }

  static String _stripTrailingSlash(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}

/// Holds the configuration resolved at application start-up.
abstract final class AppConfigScope {
  const AppConfigScope._();

  static AppConfig _current = AppConfig.fromEnvironment();

  static AppConfig get current => _current;

  /// Overrides the active configuration. Intended for `main_*.dart` entry
  /// points and tests.
  static void override(AppConfig config) => _current = config;
}
