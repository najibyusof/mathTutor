import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/config/app_config.dart';
import 'package:mathtutor/core/network/api_endpoints.dart';

void main() {
  tearDown(() => AppConfigScope.override(AppConfig.fromEnvironment()));

  group('AppConfig', () {
    test('defaults to the development environment', () {
      final AppConfig config = AppConfig.fromEnvironment();

      expect(config.environment, AppEnvironment.development);
      expect(config.enableLogging, isTrue);
      expect(
        config.apiBaseUrl,
        AppConfig.defaultApiBaseUrls[AppEnvironment.development],
      );
    });

    test('defines a base URL for every environment', () {
      for (final AppEnvironment env in AppEnvironment.values) {
        expect(AppConfig.defaultApiBaseUrls[env], isNotNull);
        expect(AppConfig.defaultApiBaseUrls[env], isNotEmpty);
      }
    });

    test('production disables logging', () {
      const AppConfig config = AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: 'https://api.mathtutor.app/api/v1',
        apiTimeout: Duration(seconds: 30),
        enableLogging: false,
      );

      expect(config.environment.isProduction, isTrue);
      expect(config.enableLogging, isFalse);
    });
  });

  group('ApiEndpoints', () {
    test('builds absolute URLs from the active configuration', () {
      AppConfigScope.override(
        const AppConfig(
          environment: AppEnvironment.staging,
          apiBaseUrl: 'https://staging.mathtutor.app/api/v1',
          apiTimeout: Duration(seconds: 10),
          enableLogging: true,
        ),
      );

      expect(
        ApiEndpoints.url(ApiEndpoints.history).toString(),
        'https://staging.mathtutor.app/api/v1/history',
      );
      expect(
        ApiEndpoints.url(
          ApiEndpoints.history,
          queryParameters: <String, dynamic>{'page': 2},
        ).toString(),
        'https://staging.mathtutor.app/api/v1/history?page=2',
      );
    });
  });
}
