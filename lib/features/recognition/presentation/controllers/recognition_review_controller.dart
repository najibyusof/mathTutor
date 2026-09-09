import 'package:flutter/foundation.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/result.dart';
import '../../../../models/math_question.dart';
import '../../domain/entities/recognition_request.dart';
import '../../domain/services/question_recognition_service.dart';

/// Holds the question under review, plus editing and retry state.
class RecognitionReviewController extends ChangeNotifier {
  RecognitionReviewController({
    required MathQuestion question,
    QuestionRecognitionService? service,
    RecognitionRequest? source,
  }) : _question = question,
       _service = service,
       _source = source;

  final QuestionRecognitionService? _service;
  final RecognitionRequest? _source;

  MathQuestion _question;
  bool _isRetrying = false;
  bool _isEditing = false;
  String? _errorMessage;

  MathQuestion get question => _question;
  bool get isRetrying => _isRetrying;
  bool get isEditing => _isEditing;
  String? get errorMessage => _errorMessage;

  /// Retry needs both an engine and a recognized source to repeat.
  bool get canRetry =>
      _service != null && (_source?.isRetryable ?? false) && !_isRetrying;

  void startEditing() {
    if (_isEditing) {
      return;
    }
    _isEditing = true;
    _errorMessage = null;
    notifyListeners();
  }

  void cancelEditing() {
    if (!_isEditing) {
      return;
    }
    _isEditing = false;
    notifyListeners();
  }

  /// Applies a user correction; a verified expression is fully trusted.
  void applyEdit(String normalizedExpression) {
    final String trimmed = normalizedExpression.trim();
    if (trimmed.isEmpty) {
      _errorMessage = 'The question cannot be empty.';
      notifyListeners();
      return;
    }

    _question = _question.copyWith(
      normalizedExpression: trimmed,
      confidence: 1,
    );
    _isEditing = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> retryRecognition() async {
    final QuestionRecognitionService? service = _service;
    final RecognitionRequest? source = _source;
    if (service == null || source == null || !source.isRetryable) {
      return false;
    }

    _isRetrying = true;
    _errorMessage = null;
    notifyListeners();

    final Result<MathQuestion> result = await service.recognize(source);
    final bool succeeded = result.when<bool>(
      onSuccess: (MathQuestion value) {
        _question = value;
        return true;
      },
      onFailure: (Failure failure) {
        _errorMessage = friendlyMessage(failure);
        return false;
      },
    );

    _isRetrying = false;
    notifyListeners();
    return succeeded;
  }
}
