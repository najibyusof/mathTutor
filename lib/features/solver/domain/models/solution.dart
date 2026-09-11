import 'math_problem.dart';

/// One transformation in a worked solution.
class SolutionStep {
  const SolutionStep({
    required this.stepNumber,
    required this.expression,
    required this.explanation,
    this.operation,
    this.result,
  });

  final int stepNumber;
  final String expression;
  final String explanation;
  final String? operation;
  final String? result;
}

/// Final value produced by a solver.
class FinalAnswer {
  const FinalAnswer({required this.expression, this.numericValue});

  final String expression;
  final double? numericValue;

  bool get hasFiniteNumericValue =>
      numericValue == null || numericValue!.isFinite;
}

/// Complete solution, including its category and audit-friendly steps.
class Solution {
  const Solution({
    required this.problem,
    required this.steps,
    required this.finalAnswer,
    this.id,
  });

  final MathProblem problem;
  final List<SolutionStep> steps;
  final FinalAnswer finalAnswer;

  /// Server-assigned solution id (from the Laravel API). Null for solutions
  /// that only exist client-side (e.g. before being persisted/solved
  /// remotely). Required to call `/solutions/{id}/explanation` or `/hint`.
  final int? id;
}
