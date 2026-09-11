import '../../../../core/network/result.dart';
import '../../../../models/math_question.dart';
import '../../../solver/domain/models/solution.dart';
import '../models/history_page.dart';
import '../../../solver/domain/models/math_problem.dart';

/// Repository boundary for Laravel-backed math workflows.
abstract interface class MathRepository {
  Future<Result<MathQuestion>> submitQuestion(MathQuestion question);

  Future<Result<Solution>> solve(MathQuestion question);

  Future<Result<HistoryPage>> history({
    int page = 1,
    int perPage = 20,
    String? query,
    MathCategory? category,
  });

  Future<Result<MathQuestion>> historyItem(String id);

  Future<Result<void>> deleteHistoryItem(String id);
}
