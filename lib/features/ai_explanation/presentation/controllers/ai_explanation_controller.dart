import 'package:flutter/foundation.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/result.dart';
import '../../domain/models/ai_explanation_models.dart';
import '../../domain/services/ai_explanation_service.dart';
import '../../../solver/domain/models/solution.dart';

enum AIExplanationStatus { idle, loading, success, failure }

/// UI-facing state for optional AI educational enhancements.
class AIExplanationController extends ChangeNotifier {
  AIExplanationController(this._service);

  final AIExplanationService _service;

  AIExplanationStatus _status = AIExplanationStatus.idle;
  AIExplanation? _explanation;
  String? _hint;
  String? _concept;
  String? _simplifiedExplanation;
  String? _errorMessage;

  AIExplanationStatus get status => _status;
  AIExplanation? get explanation => _explanation;
  String? get hint => _hint;
  String? get concept => _concept;
  String? get simplifiedExplanation => _simplifiedExplanation;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AIExplanationStatus.loading;

  Future<bool> generateExplanation(Solution solution) async {
    _begin();
    final Result<AIExplanation> result = await _service.generateExplanation(
      solution,
    );
    return result.when<bool>(
      onSuccess: (AIExplanation value) {
        _explanation = value;
        _hint = value.hints.firstOrNull;
        _concept = value.concept;
        _simplifiedExplanation = value.simplifiedExplanation;
        _succeed();
        return true;
      },
      onFailure: _fail,
    );
  }

  Future<bool> generateHint(Solution solution) async {
    _begin();
    final Result<AIHint> result = await _service.generateHint(solution);
    return result.when<bool>(
      onSuccess: (AIHint value) {
        _hint = value.text;
        _succeed();
        return true;
      },
      onFailure: _fail,
    );
  }

  Future<bool> identifyConcept(Solution solution) async {
    _begin();
    final Result<String> result = await _service.identifyConcept(solution);
    return result.when<bool>(
      onSuccess: (String value) {
        _concept = value;
        _succeed();
        return true;
      },
      onFailure: _fail,
    );
  }

  Future<bool> simplifyExplanation(Solution solution) async {
    _begin();
    final Result<String> result = await _service.simplifyExplanation(solution);
    return result.when<bool>(
      onSuccess: (String value) {
        _simplifiedExplanation = value;
        _succeed();
        return true;
      },
      onFailure: _fail,
    );
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    _status = AIExplanationStatus.idle;
    notifyListeners();
  }

  void _begin() {
    _status = AIExplanationStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _succeed() {
    _status = AIExplanationStatus.success;
    notifyListeners();
  }

  bool _fail(Failure failure) {
    _status = AIExplanationStatus.failure;
    _errorMessage = friendlyMessage(failure);
    notifyListeners();
    return false;
  }
}
