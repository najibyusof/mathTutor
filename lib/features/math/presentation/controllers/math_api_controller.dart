import 'package:flutter/foundation.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/result.dart';
import '../../../../models/math_question.dart';
import '../../../solver/domain/models/solution.dart';
import '../../domain/repositories/math_repository.dart';
import '../../domain/models/history_page.dart';
import '../../../solver/domain/models/math_problem.dart';

enum MathApiStatus { idle, loading, success, failure }

/// UI-facing coordinator for the Laravel math workflow.
class MathApiController extends ChangeNotifier {
  MathApiController(this._repository);

  final MathRepository _repository;

  MathApiStatus _status = MathApiStatus.idle;
  MathQuestion? _question;
  Solution? _solution;
  List<MathQuestion> _history = const <MathQuestion>[];
  String? _errorMessage;
  String? _historyError;
  bool _isHistoryLoading = false;
  bool _hasMoreHistory = true;
  int _historyPage = 0;
  String _historyQuery = '';
  MathCategory? _historyCategory;

  MathApiStatus get status => _status;
  MathQuestion? get question => _question;
  Solution? get solution => _solution;
  List<MathQuestion> get history => _history;
  String? get errorMessage => _errorMessage;
  String? get historyError => _historyError;
  bool get isLoading => _status == MathApiStatus.loading;
  bool get isHistoryLoading => _isHistoryLoading;
  bool get hasMoreHistory => _hasMoreHistory;
  String get historyQuery => _historyQuery;
  MathCategory? get historyCategory => _historyCategory;

  Future<bool> submitQuestion(MathQuestion question) async {
    _begin();
    final Result<MathQuestion> result = await _repository.submitQuestion(
      question,
    );
    return result.when<bool>(
      onSuccess: (MathQuestion value) {
        _question = value;
        _succeed();
        return true;
      },
      onFailure: _fail,
    );
  }

  /// Persists the question first so the backend can assign its id, then solves
  /// that server-owned question via POST /questions/{id}/solve.
  Future<bool> solve(MathQuestion question) async {
    _begin();
    final Result<MathQuestion> saved = await _repository.submitQuestion(
      question,
    );
    final MathQuestion? persisted = saved.valueOrNull;
    if (persisted == null) {
      return _fail(saved.failureOrNull!);
    }
    final Result<Solution> result = await _repository.solve(persisted);
    final Solution? value = result.valueOrNull;
    if (value == null) {
      return _fail(result.failureOrNull!);
    }
    _question = persisted;
    _solution = value;
    _succeed();
    return true;
  }

  Future<bool> loadHistory({
    bool refresh = true,
    String? query,
    MathCategory? category,
  }) async {
    if (_isHistoryLoading || (!refresh && !_hasMoreHistory)) {
      return false;
    }
    if (refresh) {
      _historyPage = 0;
      _hasMoreHistory = true;
      _history = const <MathQuestion>[];
    }
    _historyQuery = query ?? _historyQuery;
    _historyCategory = category ?? _historyCategory;
    _historyError = null;
    _isHistoryLoading = true;
    notifyListeners();
    final Result<HistoryPage> result = await _repository.history(
      page: _historyPage + 1,
      query: _historyQuery,
      category: _historyCategory,
    );
    return result.when<bool>(
      onSuccess: (HistoryPage value) {
        _history = <MathQuestion>[..._history, ...value.items];
        _historyPage = value.currentPage;
        _hasMoreHistory = value.hasNextPage;
        _isHistoryLoading = false;
        notifyListeners();
        return true;
      },
      onFailure: (Failure failure) {
        _historyError = friendlyMessage(failure);
        _isHistoryLoading = false;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> loadNextHistoryPage() => loadHistory(refresh: false);

  Future<bool> searchHistory(String query) =>
      loadHistory(refresh: true, query: query, category: _historyCategory);

  Future<bool> filterHistory(MathCategory? category) {
    _historyCategory = category;
    return loadHistory(refresh: true, query: _historyQuery);
  }

  Future<bool> clearHistory() async {
    while (_hasMoreHistory) {
      final bool loaded = await loadNextHistoryPage();
      if (!loaded && _hasMoreHistory) {
        return false;
      }
    }
    final List<MathQuestion> current = List<MathQuestion>.of(_history);
    for (final MathQuestion item in current) {
      if (!await deleteHistoryItem(item.id)) {
        return false;
      }
    }
    return true;
  }

  Future<bool> deleteHistoryItem(String id) async {
    final Result<void> result = await _repository.deleteHistoryItem(id);
    return result.when<bool>(
      onSuccess: (_) {
        _history = _history
            .where((MathQuestion item) => item.id != id)
            .toList();
        notifyListeners();
        return true;
      },
      onFailure: (Failure failure) {
        _historyError = friendlyMessage(failure);
        notifyListeners();
        return false;
      },
    );
  }

  void clearError() {
    _errorMessage = null;
    if (_status == MathApiStatus.failure) {
      _status = MathApiStatus.idle;
    }
    notifyListeners();
  }

  void _begin() {
    _status = MathApiStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _succeed() {
    _status = MathApiStatus.success;
    notifyListeners();
  }

  bool _fail(Failure failure) {
    _status = MathApiStatus.failure;
    _errorMessage = friendlyMessage(failure);
    notifyListeners();
    return false;
  }
}
