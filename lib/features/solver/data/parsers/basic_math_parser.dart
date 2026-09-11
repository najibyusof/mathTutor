import '../../../../core/network/result.dart';
import '../../domain/models/math_problem.dart';
import '../../domain/services/solver_failures.dart';
import '../../domain/services/solver_services.dart';

/// Recursive-descent parser for finite arithmetic and polynomial expressions
/// involving at most `x²`.
class BasicMathParser implements MathParser {
  const BasicMathParser();

  @override
  Result<MathProblem> parse(String input) {
    final String source = input.trim();
    if (source.isEmpty) {
      return const Result<MathProblem>.failure(
        MathParserFailure(MathFailureMessages.invalidExpression),
      );
    }

    try {
      final _ExpressionParser parser = _ExpressionParser(source);
      final ParsedMathExpression parsed = parser.parse();
      final MathCategory category = parsed.isArithmetic
          ? MathCategory.arithmetic
          : parsed.isLinearEquation
          ? MathCategory.linearEquation
          : parsed.right != null
          ? MathCategory.quadraticEquation
          : MathCategory.arithmetic;

      return Result<MathProblem>.success(
        MathProblem(
          originalInput: source,
          normalizedExpression: parsed.normalized,
          category: category,
          parsed: parsed,
        ),
      );
    } on FormatException catch (error) {
      return Result<MathProblem>.failure(
        MathParserFailure(error.message.toString()),
      );
    }
  }
}

class _ExpressionParser {
  _ExpressionParser(this.source);

  final String source;
  late final List<String> _tokens = _lex(source);
  int _index = 0;

  ParsedMathExpression parse() {
    final Polynomial left = _expression();
    String relation = '=';
    Polynomial? right;

    if (_peek == '=' ||
        _peek == '<' ||
        _peek == '>' ||
        _peek == '<=' ||
        _peek == '>=') {
      relation = _consume();
      right = _expression();
    }

    if (_peek != null) {
      throw const FormatException(MathFailureMessages.invalidExpression);
    }
    if (!left.isFinite || !(right?.isFinite ?? true)) {
      throw const FormatException(MathFailureMessages.nonFinite);
    }

    return ParsedMathExpression(
      original: source,
      normalized: _normalize(left, right, relation),
      left: left,
      right: right,
      relation: relation,
    );
  }

  Polynomial _expression() {
    Polynomial value = _term();
    while (_peek == '+' || _peek == '-') {
      final String operation = _consume();
      final Polynomial next = _term();
      value = operation == '+' ? value + next : value - next;
    }
    return value;
  }

  Polynomial _term() {
    Polynomial value = _factor();
    while (_peek == '*' || _peek == '/' || _startsImplicitFactor(_peek)) {
      final String operation = _peek == null || _peek == '*' || _peek == '/'
          ? _consume()
          : '*';
      final Polynomial next = _factor();
      if (operation == '/') {
        if (!next.isConstant || next.constant == 0) {
          throw const FormatException(
            'Division by a variable or zero is not supported.',
          );
        }
        value = value.divideByConstant(next.constant);
      } else {
        value = value.multiply(next);
        if (!value.isFinite ||
            value.quadratic != 0 && !_withinSupportedDegree(value)) {
          throw const FormatException(
            'This expression is more complex than the current solver supports.',
          );
        }
      }
    }
    return value;
  }

  Polynomial _factor() {
    if (_peek == '-') {
      _consume();
      return -_factor();
    }

    Polynomial value;
    if (_peek == '(') {
      _consume();
      value = _expression();
      _expect(')');
    } else if (_peek != null && _isNumber(_peek!)) {
      value = Polynomial(constant: double.parse(_consume()));
    } else if (_peek == 'x') {
      _consume();
      value = const Polynomial(linear: 1);
    } else {
      throw const FormatException(MathFailureMessages.invalidExpression);
    }

    if (_peek == '^') {
      _consume();
      final String exponent = _consume();
      final double parsedExponent = double.tryParse(exponent) ?? double.nan;
      if (!parsedExponent.isFinite ||
          parsedExponent < 0 ||
          parsedExponent > 2 ||
          parsedExponent != parsedExponent.truncate()) {
        throw const FormatException(
          'Only powers 0, 1 and 2 are supported yet.',
        );
      }
      value = _power(value, parsedExponent.toInt());
    }
    return value;
  }

  Polynomial _power(Polynomial value, int exponent) {
    if (exponent == 0) {
      return const Polynomial(constant: 1);
    }
    if (exponent == 1) {
      return value;
    }
    final Polynomial result = value.multiply(value);
    if (!_withinSupportedDegree(result)) {
      throw const FormatException(
        'This expression is more complex than the current solver supports.',
      );
    }
    return result;
  }

  void _expect(String expected) {
    if (_peek != expected) {
      throw const FormatException(MathFailureMessages.invalidExpression);
    }
    _consume();
  }

  String _consume() {
    if (_index >= _tokens.length) {
      throw const FormatException(MathFailureMessages.invalidExpression);
    }
    return _tokens[_index++];
  }

  String? get _peek => _index < _tokens.length ? _tokens[_index] : null;

  static bool _startsImplicitFactor(String? token) =>
      token == '(' || token == 'x' || (token != null && _isNumber(token));

  static bool _withinSupportedDegree(Polynomial polynomial) =>
      polynomial.constant.isFinite &&
      polynomial.linear.isFinite &&
      polynomial.quadratic.isFinite;

  static bool _isNumber(String token) => double.tryParse(token) != null;

  static List<String> _lex(String value) {
    final List<String> result = <String>[];
    final RegExp pattern = RegExp(r'\d+(?:\.\d+)?|x|<=|>=|[()+\-*/^=<>]');
    int cursor = 0;
    for (final RegExpMatch match in pattern.allMatches(
      value.replaceAll('×', '*').replaceAll('÷', '/').replaceAll('−', '-'),
    )) {
      if (value.substring(cursor, match.start).trim().isNotEmpty) {
        throw const FormatException(MathFailureMessages.invalidExpression);
      }
      result.add(match.group(0)!);
      cursor = match.end;
    }
    if (value.substring(cursor).trim().isNotEmpty) {
      throw const FormatException(MathFailureMessages.invalidExpression);
    }
    return result;
  }

  static String _normalize(
    Polynomial left,
    Polynomial? right,
    String relation,
  ) {
    String polynomial(Polynomial value) {
      final List<String> parts = <String>[];
      if (value.quadratic != 0) {
        parts.add('${_number(value.quadratic)}x^2');
      }
      if (value.linear != 0) {
        parts.add('${_number(value.linear)}x');
      }
      if (value.constant != 0 || parts.isEmpty) {
        parts.add(_number(value.constant));
      }
      return parts.join('+').replaceAll('+-', '-');
    }

    return right == null
        ? polynomial(left)
        : '${polynomial(left)}$relation${polynomial(right)}';
  }

  static String _number(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}
