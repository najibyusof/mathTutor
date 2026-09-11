import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/config/app_config.dart';

void main() {
  test('production configuration reports HTTPS status', () {
    const AppConfig secure = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://api.mathtutor.app/api',
      apiTimeout: Duration(seconds: 30),
      enableLogging: false,
    );
    const AppConfig insecure = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'http://api.mathtutor.app/api',
      apiTimeout: Duration(seconds: 30),
      enableLogging: false,
    );

    expect(secure.usesHttps, isTrue);
    expect(insecure.usesHttps, isFalse);
  });
}
