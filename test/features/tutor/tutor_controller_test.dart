import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/features/solver/domain/models/math_problem.dart';
import 'package:mathtutor/features/solver/domain/models/solution.dart';
import 'package:mathtutor/features/tutor/data/tutor_question_factory.dart';
import 'package:mathtutor/features/tutor/domain/models/tutor_models.dart';
import 'package:mathtutor/features/tutor/presentation/controllers/tutor_controller.dart';

const Solution _solution = Solution(
  problem: MathProblem(
    originalInput: '2x + 8 = 20',
    normalizedExpression: '2x+8=20',
    category: MathCategory.linearEquation,
    parsed: ParsedMathExpression(
      original: '2x + 8 = 20',
      normalized: '2x+8=20',
      left: Polynomial(constant: 8, linear: 2),
      right: Polynomial(constant: 20),
    ),
  ),
  steps: <SolutionStep>[
    SolutionStep(
      stepNumber: 1,
      expression: '2x + 8 - 8 = 20 - 8',
      explanation: 'Subtract 8 from both sides.',
      operation: 'subtract',
    ),
    SolutionStep(
      stepNumber: 2,
      expression: '2x = 12',
      explanation: 'Simplify both sides.',
      operation: 'simplify',
    ),
    SolutionStep(
      stepNumber: 3,
      expression: 'x = 6',
      explanation: 'Divide both sides by 2.',
      operation: 'divide',
    ),
  ],
  finalAnswer: FinalAnswer(expression: 'x = 6', numericValue: 6),
);

void main() {
  test('factory creates prompts from solver operations', () {
    final List<TutorQuestion> questions = const TutorQuestionFactory()
        .fromSolution(_solution);

    expect(questions, hasLength(3));
    expect(questions.first.correctOptionId, 'subtract');
    expect(
      questions.first.options.map((TutorOption item) => item.label),
      contains('Subtract the constant'),
    );
    expect(questions.last.correctOptionId, 'divide');
  });

  test('correct answers advance one structured step at a time', () {
    final TutorController controller = TutorController(solution: _solution);
    addTearDown(controller.dispose);

    final TutorQuestion first = controller.currentQuestion!;
    final TutorOption correct = first.options.firstWhere(
      (TutorOption option) => option.id == first.correctOptionId,
    );

    final TutorResponse response = controller.selectOption(correct);

    expect(response.status, TutorResponseStatus.correct);
    expect(controller.progress.completedSteps, 1);
    expect(controller.currentQuestion?.step.stepNumber, 2);
    expect(controller.solution.finalAnswer.expression, 'x = 6');
  });

  test('incorrect answers show a hint and do not advance', () {
    final TutorController controller = TutorController(solution: _solution);
    addTearDown(controller.dispose);

    final TutorOption wrong = controller.currentQuestion!.options.firstWhere(
      (TutorOption option) =>
          option.id != controller.currentQuestion!.correctOptionId,
    );
    final TutorResponse response = controller.selectOption(wrong);

    expect(response.status, TutorResponseStatus.incorrect);
    expect(response.hint, contains('remove'));
    expect(controller.progress.completedSteps, 0);
    expect(controller.currentQuestion?.step.stepNumber, 1);
    expect(controller.isComplete, isFalse);
  });

  test('show hint and show solution are explicit actions', () {
    final TutorController controller = TutorController(solution: _solution);
    addTearDown(controller.dispose);

    controller.toggleHint();
    expect(controller.showHint, isTrue);
    expect(controller.isComplete, isFalse);

    controller.revealSolution();
    expect(controller.showSolution, isTrue);
    expect(controller.isComplete, isTrue);
    expect(controller.solution.finalAnswer.expression, 'x = 6');
  });

  test('try again hides a revealed solution without changing it', () {
    final TutorController controller = TutorController(solution: _solution);
    addTearDown(controller.dispose);

    controller.revealSolution();
    controller.tryAgain();

    expect(controller.isComplete, isFalse);
    expect(controller.currentQuestion?.step.stepNumber, 1);
    expect(controller.solution.finalAnswer.expression, 'x = 6');
  });

  test('completes only after every correct option', () {
    final TutorController controller = TutorController(solution: _solution);
    addTearDown(controller.dispose);

    while (!controller.isComplete) {
      final TutorQuestion question = controller.currentQuestion!;
      final TutorOption option = question.options.firstWhere(
        (TutorOption item) => item.id == question.correctOptionId,
      );
      controller.selectOption(option);
    }

    expect(controller.progress.completedSteps, 3);
    expect(controller.currentQuestion, isNull);
    expect(controller.solution.finalAnswer.expression, 'x = 6');
  });
}
