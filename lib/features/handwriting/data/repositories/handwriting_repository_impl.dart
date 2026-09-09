import '../../../../core/errors/failures.dart';
import '../../../../core/network/result.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/handwriting_sample.dart';
import '../../../../models/recognition_result.dart';
import '../../domain/repositories/handwriting_repository.dart';
import '../services/handwriting_recognition_service.dart';

class HandwritingRepositoryImpl implements HandwritingRepository {
  const HandwritingRepositoryImpl(this._service);

  final HandwritingRecognitionService _service;

  @override
  Future<Result<RecognitionResult>> recognizeHandwriting(
    HandwritingSample sample,
  ) async {
    try {
      final RecognitionResult result = await _service.recognize(sample);
      if (result.expression.isEmpty) {
        return const Result<RecognitionResult>.failure(
          UnexpectedFailure('We could not read that. Try writing it larger.'),
        );
      }
      return Result<RecognitionResult>.success(result);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Handwriting recognition failed',
        error: error,
        stackTrace: stackTrace,
      );
      return Result<RecognitionResult>.failure(mapExceptionToFailure(error));
    }
  }
}
