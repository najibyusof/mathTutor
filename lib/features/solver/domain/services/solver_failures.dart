export '../../../../core/errors/failures.dart';

class MathFailureMessages {
  const MathFailureMessages._();

  static const String unsupportedCategory =
      'This type of problem is not supported yet.';
  static const String invalidExpression =
      'We could not parse that mathematical expression.';
  static const String nonFinite =
      'The calculation produced an invalid number. Check the expression.';
}
