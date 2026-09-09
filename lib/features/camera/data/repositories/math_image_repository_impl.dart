import '../../../../core/errors/failures.dart';
import '../../../../core/network/result.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../models/recognition_result.dart';
import '../../domain/entities/math_image.dart';
import '../../domain/repositories/math_image_repository.dart';
import '../services/math_image_recognition_service.dart';

class MathImageRepositoryImpl implements MathImageRepository {
  const MathImageRepositoryImpl(this._service);

  final MathImageRecognitionService _service;

  @override
  Future<Result<RecognitionResult>> recognizeMathImage(MathImage image) async {
    try {
      final RecognitionResult result = await _service.recognize(image);
      if (result.expression.isEmpty) {
        return const Result<RecognitionResult>.failure(
          UnexpectedFailure(
            'We could not find a question in that picture. '
            'Try again with better lighting.',
          ),
        );
      }
      return Result<RecognitionResult>.success(result);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Image recognition failed',
        error: error,
        stackTrace: stackTrace,
      );
      return Result<RecognitionResult>.failure(mapExceptionToFailure(error));
    }
  }
}
