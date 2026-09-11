/// Mathematical categories recognized by the solver architecture.
enum MathCategory {
  arithmetic,
  linearEquation,
  quadraticEquation,
  fraction,
  percentage,
  simultaneousEquations,
  inequality,
  powers,
  roots,
  trigonometry,
  calculus,
}

/// A finite polynomial up to degree two: `constant + linear*x + quadratic*x²`.
class Polynomial {
  const Polynomial({this.constant = 0, this.linear = 0, this.quadratic = 0});

  final double constant;
  final double linear;
  final double quadratic;

  bool get isFinite =>
      constant.isFinite && linear.isFinite && quadratic.isFinite;
  bool get hasVariable => linear != 0 || quadratic != 0;
  bool get isConstant => !hasVariable;
  bool get isLinear => quadratic == 0;

  Polynomial operator +(Polynomial other) => Polynomial(
    constant: constant + other.constant,
    linear: linear + other.linear,
    quadratic: quadratic + other.quadratic,
  );

  Polynomial operator -(Polynomial other) => Polynomial(
    constant: constant - other.constant,
    linear: linear - other.linear,
    quadratic: quadratic - other.quadratic,
  );

  Polynomial operator -() =>
      Polynomial(constant: -constant, linear: -linear, quadratic: -quadratic);

  Polynomial multiply(Polynomial other) => Polynomial(
    constant: constant * other.constant,
    linear: linear * other.constant + constant * other.linear,
    quadratic:
        quadratic * other.constant +
        linear * other.linear +
        constant * other.quadratic,
  );

  Polynomial divideByConstant(double divisor) => Polynomial(
    constant: constant / divisor,
    linear: linear / divisor,
    quadratic: quadratic / divisor,
  );

  @override
  String toString() => 'Polynomial($constant, $linear, $quadratic)';
}

/// Parser output shared by validators and solvers.
class ParsedMathExpression {
  const ParsedMathExpression({
    required this.original,
    required this.normalized,
    required this.left,
    this.right,
    this.relation = '=',
  });

  final String original;
  final String normalized;
  final Polynomial left;
  final Polynomial? right;
  final String relation;

  bool get isEquation => right != null;
  bool get isArithmetic => right == null && left.isConstant;
  bool get isLinearEquation =>
      right != null && left.isLinear && right!.isLinear;
}

/// User-facing problem passed from parser to solver.
class MathProblem {
  const MathProblem({
    required this.originalInput,
    required this.normalizedExpression,
    required this.category,
    required this.parsed,
  });

  final String originalInput;
  final String normalizedExpression;
  final MathCategory category;
  final ParsedMathExpression parsed;
}
