import '../../../../core/errors/failures.dart';
import '../../../../core/network/result.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../models/math_question.dart';
import '../../../solver/domain/models/solution.dart';
import '../../../solver/domain/models/math_problem.dart';
import '../../domain/repositories/math_repository.dart';
import '../../domain/models/history_page.dart';
import '../datasources/math_remote_data_source.dart';

/// Converts Laravel transport exceptions into domain Results for controllers.
class MathRepositoryImpl implements MathRepository {
  const MathRepositoryImpl(this._remote);

  final MathRemoteDataSource _remote;

  @override
  Future<Result<MathQuestion>> submitQuestion(MathQuestion question) =>
      _guard(() => _remote.submitQuestion(question));

  @override
  Future<Result<Solution>> solve(MathQuestion question) =>
      _guard(() => _remote.solve(question));

  @override
  Future<Result<HistoryPage>> history({
    int page = 1,
    int perPage = 20,
    String? query,
    MathCategory? category,
  }) => _guard(
    () => _remote.history(
      page: page,
      perPage: perPage,
      query: query,
      category: category,
    ),
  );

  @override
  Future<Result<MathQuestion>> historyItem(String id) =>
      _guard(() => _remote.historyItem(id));

  @override
  Future<Result<void>> deleteHistoryItem(String id) async {
    try {
      await _remote.deleteHistoryItem(id);
      return const Result<void>.success(null);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Deleting math history failed',
        error: error,
        stackTrace: stackTrace,
      );
      return Result<void>.failure(mapExceptionToFailure(error));
    }
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result<T>.success(await action());
    } catch (error, stackTrace) {
      AppLogger.error(
        'Math API request failed',
        error: error,
        stackTrace: stackTrace,
      );
      return Result<T>.failure(mapExceptionToFailure(error));
    }
  }
}
