import '../../solver/domain/models/solution.dart';
import '../domain/models/tutor_models.dart';

/// Builds deterministic tutor prompts from solver operations.
class TutorQuestionFactory {
  const TutorQuestionFactory();

  List<TutorQuestion> fromSolution(Solution solution) {
    return solution.steps.map(_fromStep).toList(growable: false);
  }

  TutorQuestion _fromStep(SolutionStep step) {
    final String operation = step.operation?.toLowerCase() ?? 'simplify';
    final _Prompt prompt = _promptFor(operation);
    return TutorQuestion(
      step: step,
      prompt: prompt.prompt,
      options: prompt.options,
      correctOptionId: prompt.correctOptionId,
      hint: prompt.hint,
    );
  }

  _Prompt _promptFor(String operation) {
    return switch (operation) {
      'subtract' => const _Prompt(
        prompt: 'What should we do first?',
        correctOptionId: 'subtract',
        hint: 'Think about what operation can remove the positive constant.',
        options: <TutorOption>[
          TutorOption(id: 'add', label: 'Add the constant'),
          TutorOption(id: 'subtract', label: 'Subtract the constant'),
          TutorOption(id: 'multiply', label: 'Multiply by the constant'),
          TutorOption(id: 'divide', label: 'Divide by the constant'),
        ],
      ),
      'add' => const _Prompt(
        prompt: 'Which operation keeps both sides balanced?',
        correctOptionId: 'add',
        hint: 'Use the inverse of subtracting a number.',
        options: <TutorOption>[
          TutorOption(id: 'add', label: 'Add the same value to both sides'),
          TutorOption(id: 'subtract', label: 'Subtract the value'),
          TutorOption(id: 'multiply', label: 'Multiply one side'),
          TutorOption(id: 'divide', label: 'Divide one side'),
        ],
      ),
      'divide' => const _Prompt(
        prompt: 'How can we get the variable by itself?',
        correctOptionId: 'divide',
        hint: 'Look at the number multiplied by the variable.',
        options: <TutorOption>[
          TutorOption(id: 'add', label: 'Add the coefficient'),
          TutorOption(id: 'subtract', label: 'Subtract the coefficient'),
          TutorOption(id: 'multiply', label: 'Multiply by the coefficient'),
          TutorOption(id: 'divide', label: 'Divide by the coefficient'),
        ],
      ),
      _ => const _Prompt(
        prompt: 'What should we do next?',
        correctOptionId: 'simplify',
        hint: 'Combine like terms and simplify both sides carefully.',
        options: <TutorOption>[
          TutorOption(id: 'simplify', label: 'Simplify both sides'),
          TutorOption(id: 'add', label: 'Add a new term'),
          TutorOption(id: 'multiply', label: 'Multiply one side'),
          TutorOption(id: 'skip', label: 'Skip this step'),
        ],
      ),
    };
  }
}

class _Prompt {
  const _Prompt({
    required this.prompt,
    required this.options,
    required this.correctOptionId,
    required this.hint,
  });

  final String prompt;
  final List<TutorOption> options;
  final String correctOptionId;
  final String hint;
}
