import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/ai_explanation/data/providers/mock_ai_explanation_provider.dart';
import '../../features/ai_explanation/data/providers/remote_ai_explanation_provider.dart';
import '../../features/ai_explanation/data/services/ai_explanation_service_impl.dart';
import '../../features/ai_explanation/domain/services/ai_explanation_service.dart';
import '../../features/camera/data/repositories/math_image_repository_impl.dart';
import '../../features/camera/data/services/image_source_service.dart';
import '../../features/camera/data/services/math_image_recognition_service.dart';
import '../../features/camera/data/services/mock_math_image_recognition_service.dart';
import '../../features/camera/data/services/remote_math_image_recognition_service.dart';
import '../../features/camera/domain/repositories/math_image_repository.dart';
import '../../features/handwriting/data/repositories/handwriting_repository_impl.dart';
import '../../features/handwriting/data/services/handwriting_recognition_service.dart';
import '../../features/handwriting/data/services/mock_handwriting_recognition_service.dart';
import '../../features/handwriting/data/services/remote_handwriting_recognition_service.dart';
import '../../features/handwriting/domain/repositories/handwriting_repository.dart';
import '../../features/math/data/datasources/math_remote_data_source.dart';
import '../../features/math/data/repositories/math_repository_impl.dart';
import '../../features/math/domain/repositories/math_repository.dart';
import '../../features/math/presentation/controllers/math_api_controller.dart';
import '../../features/recognition/data/services/question_recognition_service_impl.dart';
import '../../features/recognition/domain/services/question_recognition_service.dart';
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
    required this.handwritingRepository,
    required this.mathImageRepository,
    required this.imageSourceService,
    required this.recognitionService,
    required this.aiExplanationService,
    required this.mathRepository,
    required this.mathController,
  });

  final TokenStorage tokenStorage;
  final ApiClient apiClient;
  final AuthRepository authRepository;
  final AuthController authController;
  final HandwritingRepository handwritingRepository;
  final MathImageRepository mathImageRepository;
  final ImageSourceService imageSourceService;
  final QuestionRecognitionService recognitionService;
  final AIExplanationService aiExplanationService;
  final MathRepository mathRepository;
  final MathApiController mathController;

  /// Wires the graph for [config]; mock mode keeps the app usable without the
  /// Laravel backend. Overrides exist for tests.
  factory AppDependencies.create({
    AppConfig? config,
    TokenStorage? tokenStorage,
    ApiClient? apiClient,
    HandwritingRecognitionService? handwritingRecognition,
    MathImageRecognitionService? imageRecognition,
    ImageSourceService? imageSourceService,
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

    final HandwritingRecognitionService recognition =
        handwritingRecognition ??
        (activeConfig.useMockApi
            ? const MockHandwritingRecognitionService()
            : RemoteHandwritingRecognitionService(client));

    final MathImageRecognitionService imageEngine =
        imageRecognition ??
        (activeConfig.useMockApi
            ? const MockMathImageRecognitionService()
            : RemoteMathImageRecognitionService(client));

    final HandwritingRepository handwritingRepository =
        HandwritingRepositoryImpl(recognition);
    final MathImageRepository imageRepository = MathImageRepositoryImpl(
      imageEngine,
    );
    final MathRepository mathRepository = MathRepositoryImpl(
      MathRemoteDataSource(client),
    );

    return AppDependencies._(
      tokenStorage: storage,
      apiClient: client,
      authRepository: repository,
      authController: controller,
      handwritingRepository: handwritingRepository,
      mathImageRepository: imageRepository,
      imageSourceService: imageSourceService ?? ImagePickerSourceService(),
      recognitionService: QuestionRecognitionServiceImpl(
        handwriting: handwritingRepository,
        image: imageRepository,
      ),
      aiExplanationService: AIExplanationServiceImpl(
        activeConfig.useMockApi
            ? const MockAIExplanationProvider()
            : RemoteAIExplanationProvider(client),
      ),
      mathRepository: mathRepository,
      mathController: MathApiController(mathRepository),
    );
  }
}
