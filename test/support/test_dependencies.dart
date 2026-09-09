import 'package:mathtutor/core/config/app_config.dart';
import 'package:mathtutor/core/di/app_dependencies.dart';
import 'package:mathtutor/core/network/mock_api_client.dart';
import 'package:mathtutor/core/storage/token_storage.dart';

const AppConfig testConfig = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: 'https://test.mathtutor.app/api',
  apiTimeout: Duration(seconds: 5),
  enableLogging: false,
  useMockApi: true,
);

/// Dependency graph backed by the in-memory API with no artificial latency.
AppDependencies buildTestDependencies({TokenStorage? tokenStorage}) {
  final TokenStorage storage = tokenStorage ?? InMemoryTokenStorage();
  return AppDependencies.create(
    config: testConfig,
    tokenStorage: storage,
    apiClient: MockApiClient(tokenStorage: storage, latency: Duration.zero),
  );
}
