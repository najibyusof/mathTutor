import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/mock_api_client.dart';
import '../storage/token_storage.dart';

/// Composition root: builds the object graph once at start-up.
class AppDependencies {
  AppDependencies._({
    required this.tokenStorage,
    required this.apiClient,
    required this.authRepository,
    required this.authController,
  });

  final TokenStorage tokenStorage;
  final ApiClient apiClient;
  final AuthRepository authRepository;
  final AuthController authController;

  /// Wires the graph for [config]; mock mode keeps the app usable without the
  /// Laravel backend. Overrides exist for tests.
  factory AppDependencies.create({
    AppConfig? config,
    TokenStorage? tokenStorage,
    ApiClient? apiClient,
  }) {
    final AppConfig activeConfig = config ?? AppConfigScope.current;
    final TokenStorage storage =
        tokenStorage ??
        (activeConfig.useMockApi
            ? InMemoryTokenStorage()
            : const SecureTokenStorage());

    late final AuthController controller;

    final ApiClient client =
        apiClient ??
        (activeConfig.useMockApi
            ? MockApiClient(tokenStorage: storage)
            : HttpApiClient(
                tokenStorage: storage,
                config: activeConfig,
                onUnauthorized: () async => controller.handleExpiredSession(),
              ));

    final AuthRepository repository = AuthRepositoryImpl(
      remote: AuthRemoteDataSource(client),
      tokenStorage: storage,
    );
    controller = AuthController(repository);

    return AppDependencies._(
      tokenStorage: storage,
      apiClient: client,
      authRepository: repository,
      authController: controller,
    );
  }
}
