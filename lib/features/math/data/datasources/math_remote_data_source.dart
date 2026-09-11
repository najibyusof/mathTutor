import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../models/math_question.dart';
import '../../../solver/domain/models/solution.dart';
import '../models/math_api_models.dart';
import '../../domain/models/history_page.dart';
import '../../../solver/domain/models/math_problem.dart';

/// Laravel REST data source. It contains transport DTO mapping only; callers
/// receive domain models and never see JSON.
class MathRemoteDataSource {
  const MathRemoteDataSource(this._client);

  final ApiClient _client;

  /// Creates the question server-side (required before it can be solved).
  Future<MathQuestion> submitQuestion(MathQuestion question) async {
    final Map<String, dynamic> json = await _client.post(
      ApiEndpoints.questions,
      body: MathQuestionDto(question).toCreateJson(),
    );
    return MathQuestionDto.fromJson(json).question;
  }

  /// Solves a question that already has a real, server-assigned [id] (i.e.
  /// one returned by [submitQuestion]).
  Future<Solution> solve(MathQuestion question) async {
    final Map<String, dynamic> json = await _client.post(
      ApiEndpoints.questionSolve(question.id),
    );
    return SolutionDto.fromJson(json).solution;
  }

  Future<HistoryPage> history({
    int page = 1,
    int perPage = 20,
    String? query,
    MathCategory? category,
  }) async {
    final Map<String, dynamic> json = await _client.get(
      ApiEndpoints.history,
      queryParameters: <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (query != null && query.trim().isNotEmpty) 'search': query.trim(),
        if (category != null) 'category': category.name,
      },
    );
    final Object? raw = _dataOrList(json);
    if (raw is! List) {
      throw const FormatException('The history response was malformed.');
    }
    final Map<String, dynamic> root = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : json;
    final List<MathQuestion> items = raw
        .whereType<Map<String, dynamic>>()
        .map(
          (Map<String, dynamic> item) =>
              MathQuestionDto.fromJson(item).question,
        )
        .toList(growable: false);
    return HistoryPage(
      items: items,
      currentPage: (root['current_page'] as num?)?.toInt() ?? page,
      lastPage: (root['last_page'] as num?)?.toInt() ?? page,
      total: (root['total'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<MathQuestion> historyItem(String id) async {
    final Map<String, dynamic> json = await _client.get(
      ApiEndpoints.historyItem(id),
    );
    return MathQuestionDto.fromJson(json).question;
  }

  Future<void> deleteHistoryItem(String id) async {
    await _client.delete(ApiEndpoints.historyItem(id));
  }

  static Object? _dataOrList(Map<String, dynamic> json) => json['data'] ?? json;
}
