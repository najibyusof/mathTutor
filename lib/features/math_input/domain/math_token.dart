/// Kind of a single atom in an expression.
enum MathTokenType {
  digit,
  decimal,
  variable,
  constant,
  /// `+ − × ÷`
  operator,
  /// `= < > ≤ ≥`
  relation,
  percent,
  open,
  close,
  /// Marks the group that follows as an exponent.
  exponent,
  /// Marks the group that follows as a radicand.
  sqrt,
  /// Separates the two groups of a fraction.
  fraction,
}

/// Smallest editable unit of a [MathExpression].
class MathToken {
  const MathToken(this.type, this.value);

  final MathTokenType type;
  final String value;

  static const MathToken plus = MathToken(MathTokenType.operator, '+');
  static const MathToken minus = MathToken(MathTokenType.operator, '−');
  static const MathToken times = MathToken(MathTokenType.operator, '×');
  static const MathToken divide = MathToken(MathTokenType.operator, '÷');
  static const MathToken equals = MathToken(MathTokenType.relation, '=');
  static const MathToken lessThan = MathToken(MathTokenType.relation, '<');
  static const MathToken greaterThan = MathToken(MathTokenType.relation, '>');
  static const MathToken lessOrEqual = MathToken(MathTokenType.relation, '≤');
  static const MathToken greaterOrEqual = MathToken(
    MathTokenType.relation,
    '≥',
  );
  static const MathToken decimalPoint = MathToken(MathTokenType.decimal, '.');
  static const MathToken percent = MathToken(MathTokenType.percent, '%');
  static const MathToken pi = MathToken(MathTokenType.constant, 'π');
  static const MathToken open = MathToken(MathTokenType.open, '(');
  static const MathToken close = MathToken(MathTokenType.close, ')');
  static const MathToken exponent = MathToken(MathTokenType.exponent, '^');
  static const MathToken sqrt = MathToken(MathTokenType.sqrt, '√');
  static const MathToken fraction = MathToken(MathTokenType.fraction, '/');

  static MathToken digit(String value) => MathToken(MathTokenType.digit, value);

  static MathToken variable(String name) =>
      MathToken(MathTokenType.variable, name);

  /// Tokens that can end a value: `2`, `x`, `π`, `)`, `%`.
  bool get isValueEnd =>
      type == MathTokenType.digit ||
      type == MathTokenType.variable ||
      type == MathTokenType.constant ||
      type == MathTokenType.close ||
      type == MathTokenType.percent;

  /// Tokens that can start a value.
  bool get isValueStart =>
      type == MathTokenType.digit ||
      type == MathTokenType.variable ||
      type == MathTokenType.constant ||
      type == MathTokenType.open ||
      type == MathTokenType.sqrt;

  @override
  bool operator ==(Object other) =>
      other is MathToken && other.type == type && other.value == value;

  @override
  int get hashCode => Object.hash(type, value);

  @override
  String toString() => value;
}
