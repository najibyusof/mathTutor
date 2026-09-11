import 'package:flutter/foundation.dart';

import '../../../solver/domain/models/solution.dart';
import '../../data/tutor_question_factory.dart';
import '../../domain/models/tutor_models.dart';

/// Deterministic interactive tutor state machine.
class TutorController extends ChangeNotifier {
  TutorController({required Solution solution})
    : _solution = solution,
      _questions = const TutorQuestionFactory().fromSolution(solution);

  final Solution _solution;
  final List<TutorQuestion> _questions;
  int _index = 0;
  bool _showHint = false;
  bool _showSolution = false;
  TutorResponse? _lastResponse;

  Solution get solution => _solution;
  TutorProgress get progress => TutorProgress(
    currentStep: _index + 1,
    totalSteps: _questions.length,
    completedSteps: _index,
    isComplete: isComplete,
  );
  TutorQuestion? get currentQuestion => isComplete ? null : _questions[_index];
  TutorResponse? get lastResponse => _lastResponse;
  bool get showHint => _showHint;
  bool get showSolution => _showSolution;
  bool get isComplete => _index >= _questions.length || _showSolution;

  TutorResponse selectOption(TutorOption option) {
    if (isComplete) {
      return const TutorResponse(status: TutorResponseStatus.alreadyComplete);
    }

    final TutorQuestion question = _questions[_index];
    if (option.id == question.correctOptionId) {
      _index++;
      _showHint = false;
      _lastResponse = const TutorResponse(
        status: TutorResponseStatus.correct,
        message: 'Correct! Let’s continue.',
      );
    } else {
      _lastResponse = TutorResponse(
        status: TutorResponseStatus.incorrect,
        message: 'Not quite. Think about the operation that changes the term.',
        hint: question.hint,
      );
    }
    notifyListeners();
    return _lastResponse!;
  }

  void toggleHint() {
    if (isComplete) {
      return;
    }
    _showHint = !_showHint;
    notifyListeners();
  }

  void revealSolution() {
    _showSolution = true;
    _showHint = false;
    notifyListeners();
  }

  void tryAgain() {
    if (_showSolution) {
      _showSolution = false;
    }
    _lastResponse = null;
    _showHint = false;
    notifyListeners();
  }
}
