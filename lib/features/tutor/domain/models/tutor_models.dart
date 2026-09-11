import '../../../solver/domain/models/solution.dart';

/// One operation prompt derived from a deterministic solver step.
class TutorQuestion {
  const TutorQuestion({
    required this.step,
    required this.prompt,
    required this.options,
    required this.correctOptionId,
    required this.hint,
  });

  final SolutionStep step;
  final String prompt;
  final List<TutorOption> options;
  final String correctOptionId;
  final String hint;
}

class TutorOption {
  const TutorOption({required this.id, required this.label});

  final String id;
  final String label;
}

/// Result of selecting an option.
enum TutorResponseStatus { correct, incorrect, alreadyComplete }

class TutorResponse {
  const TutorResponse({required this.status, this.message, this.hint});

  final TutorResponseStatus status;
  final String? message;
  final String? hint;

  bool get isCorrect => status == TutorResponseStatus.correct;
}

class TutorProgress {
  const TutorProgress({
    required this.currentStep,
    required this.totalSteps,
    required this.completedSteps,
    required this.isComplete,
  });

  final int currentStep;
  final int totalSteps;
  final int completedSteps;
  final bool isComplete;

  double get fraction => totalSteps == 0 ? 1 : completedSteps / totalSteps;
}
