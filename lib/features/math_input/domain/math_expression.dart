import 'math_token.dart';

/// Immutable expression plus the caret position, with all editing rules.
///
/// The model is UI-independent: widgets render it and send edits back, but the
/// validity rules live here.
class MathExpression {
  const MathExpression._(this.tokens, this.cursor);

  /// Tokens in reading order.
  final List<MathToken> tokens;

  /// Caret position, from `0` (before the first token) to `tokens.length`.
  final int cursor;

  static const MathExpression empty = MathExpression._(<MathToken>[], 0);

  factory MathExpression.fromTokens(List<MathToken> tokens, {int? cursor}) {
    final List<MathToken> copy = List<MathToken>.unmodifiable(tokens);
    return MathExpression._(copy, (cursor ?? copy.length).clamp(0, copy.length));
  }

  /// Rebuilds an expression from stored text so a saved question can be
  /// edited again.
  factory MathExpression.parse(String raw) =>
      MathExpression.fromTokens(_tokenize(raw));

  bool get isEmpty => tokens.isEmpty;
  bool get isNotEmpty => tokens.isNotEmpty;

  /// Whether every `(` has a matching `)`.
  bool get isBalanced {
    int depth = 0;
    for (final MathToken token in tokens) {
      if (token.type == MathTokenType.open) {
        depth++;
      } else if (token.type == MathTokenType.close) {
        depth--;
        if (depth < 0) {
          return false;
        }
      }
    }
    return depth == 0;
  }

  MathToken? get tokenBeforeCursor =>
      cursor > 0 ? tokens[cursor - 1] : null;

  /// Inserts [insertion] at the caret, or returns `this` when the edit would
  /// produce obviously invalid input.
  ///
  /// [cursorOffset] positions the caret relative to the start of the
  /// insertion; it defaults to the end of the inserted tokens.
  MathExpression insert(List<MathToken> insertion, {int? cursorOffset}) {
    if (insertion.isEmpty) {
      return this;
    }

    final MathToken first = insertion.first;
    final MathToken? previous = tokenBeforeCursor;

    // Typing an operator right after another one replaces it.
    if (first.type == MathTokenType.operator &&
        previous?.type == MathTokenType.operator &&
        insertion.length == 1) {
      final List<MathToken> next = List<MathToken>.of(tokens)
        ..[cursor - 1] = first;
      return MathExpression._(List<MathToken>.unmodifiable(next), cursor);
    }

    if (!_allows(first)) {
      return this;
    }

    final List<MathToken> next = List<MathToken>.of(tokens)
      ..insertAll(cursor, insertion);
    return MathExpression._(
      List<MathToken>.unmodifiable(next),
      cursor + (cursorOffset ?? insertion.length),
    );
  }

  /// Deletes backwards, keeping parentheses balanced.
  MathExpression backspace() {
    if (cursor == 0) {
      return this;
    }

    final MathToken previous = tokens[cursor - 1];

    if (previous.type == MathTokenType.close) {
      final int open = _matchingOpen(cursor - 1)!;
      final bool isEmptyGroup = open == cursor - 2;
      if (!isEmptyGroup) {
        // Step inside the group instead of destroying its content.
        return MathExpression._(tokens, cursor - 1);
      }
      final int start = _markerBefore(open) ?? open;
      return _removeRange(start, cursor, start);
    }

    if (previous.type == MathTokenType.open) {
      final int close = _matchingClose(cursor - 1)!;
      final int start = _markerBefore(cursor - 1) ?? cursor - 1;
      final List<MathToken> next = List<MathToken>.of(tokens)
        ..removeAt(close)
        ..removeRange(start, cursor);
      return MathExpression._(List<MathToken>.unmodifiable(next), start);
    }

    return _removeRange(cursor - 1, cursor, cursor - 1);
  }

  MathExpression clear() => empty;

  MathExpression moveLeft() =>
      cursor == 0 ? this : MathExpression._(tokens, cursor - 1);

  MathExpression moveRight() =>
      cursor >= tokens.length ? this : MathExpression._(tokens, cursor + 1);

  MathExpression moveToEnd() => MathExpression._(tokens, tokens.length);

  /// Index of the `)` that closes the `(` at [index].
  int? matchingClose(int index) => _matchingClose(index);

  /// Human-readable form, e.g. `x² + 5x + 6 = 0`.
  String get displayText {
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < tokens.length; i++) {
      final MathToken token = tokens[i];

      if (token.type == MathTokenType.exponent) {
        final int? close = i + 1 < tokens.length ? _matchingClose(i + 1) : null;
        final String? superscript = close == null
            ? null
            : _superscript(tokens.sublist(i + 2, close));
        if (superscript != null) {
          buffer.write(superscript);
          i = close!;
          continue;
        }
      }

      if (token.type == MathTokenType.operator ||
          token.type == MathTokenType.relation) {
        buffer.write(' ${token.value} ');
      } else {
        buffer.write(token.value);
      }
    }

    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Solver-friendly form with explicit multiplication, e.g. `2*x+5=15`.
  ///
  /// Nothing evaluates this yet; it is the hand-off format for the solver
  /// phase.
  String get rawInput {
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < tokens.length; i++) {
      final MathToken token = tokens[i];
      final MathToken? previous = i > 0 ? tokens[i - 1] : null;

      // Digits of the same number must not be split by an implicit `*`.
      final bool sameNumber =
          previous != null &&
          _isNumberPart(previous.type) &&
          _isNumberPart(token.type);

      if (previous != null &&
          !sameNumber &&
          previous.isValueEnd &&
          token.isValueStart) {
        buffer.write('*');
      }

      buffer.write(switch (token.type) {
        MathTokenType.constant => 'pi',
        MathTokenType.sqrt => 'sqrt',
        MathTokenType.fraction => '/',
        MathTokenType.operator => switch (token.value) {
          '×' => '*',
          '÷' => '/',
          '−' => '-',
          _ => token.value,
        },
        MathTokenType.relation => switch (token.value) {
          '≤' => '<=',
          '≥' => '>=',
          _ => token.value,
        },
        _ => token.value,
      });
    }

    return buffer.toString();
  }

  bool _allows(MathToken token) {
    final MathToken? previous = tokenBeforeCursor;

    switch (token.type) {
      case MathTokenType.operator:
        if (previous == null) {
          return token == MathToken.minus;
        }
        return previous.isValueEnd;
      case MathTokenType.relation:
        return previous != null && previous.isValueEnd;
      case MathTokenType.percent:
      case MathTokenType.exponent:
        return previous != null && previous.isValueEnd;
      case MathTokenType.decimal:
        return !_numberBeforeCursorHasDecimal();
      case MathTokenType.close:
        return _openDepthBeforeCursor() > 0;
      case MathTokenType.fraction:
        return previous != null && previous.isValueEnd;
      case MathTokenType.digit:
      case MathTokenType.variable:
      case MathTokenType.constant:
      case MathTokenType.open:
      case MathTokenType.sqrt:
        return true;
    }
  }

  static bool _isNumberPart(MathTokenType type) =>
      type == MathTokenType.digit || type == MathTokenType.decimal;

  bool _numberBeforeCursorHasDecimal() {    for (int i = cursor - 1; i >= 0; i--) {
      final MathTokenType type = tokens[i].type;
      if (type == MathTokenType.decimal) {
        return true;
      }
      if (type != MathTokenType.digit) {
        return false;
      }
    }
    return false;
  }

  int _openDepthBeforeCursor() {
    int depth = 0;
    for (int i = 0; i < cursor; i++) {
      if (tokens[i].type == MathTokenType.open) {
        depth++;
      } else if (tokens[i].type == MathTokenType.close) {
        depth--;
      }
    }
    return depth;
  }

  /// Index of a `^` or `√` marker directly before [openIndex].
  int? _markerBefore(int openIndex) {
    if (openIndex == 0) {
      return null;
    }
    final MathTokenType type = tokens[openIndex - 1].type;
    return type == MathTokenType.exponent || type == MathTokenType.sqrt
        ? openIndex - 1
        : null;
  }

  int? _matchingClose(int openIndex) {
    if (openIndex >= tokens.length ||
        tokens[openIndex].type != MathTokenType.open) {
      return null;
    }
    int depth = 0;
    for (int i = openIndex; i < tokens.length; i++) {
      if (tokens[i].type == MathTokenType.open) {
        depth++;
      } else if (tokens[i].type == MathTokenType.close) {
        depth--;
        if (depth == 0) {
          return i;
        }
      }
    }
    return null;
  }

  int? _matchingOpen(int closeIndex) {
    int depth = 0;
    for (int i = closeIndex; i >= 0; i--) {
      if (tokens[i].type == MathTokenType.close) {
        depth++;
      } else if (tokens[i].type == MathTokenType.open) {
        depth--;
        if (depth == 0) {
          return i;
        }
      }
    }
    return null;
  }

  MathExpression _removeRange(int start, int end, int nextCursor) {
    final List<MathToken> next = List<MathToken>.of(tokens)
      ..removeRange(start, end);
    return MathExpression._(List<MathToken>.unmodifiable(next), nextCursor);
  }

  static const Map<String, String> _superscriptDigits = <String, String>{
    '0': '⁰',
    '1': '¹',
    '2': '²',
    '3': '³',
    '4': '⁴',
    '5': '⁵',
    '6': '⁶',
    '7': '⁷',
    '8': '⁸',
    '9': '⁹',
  };

  static String? _superscript(List<MathToken> exponent) {
    if (exponent.isEmpty) {
      return null;
    }
    final StringBuffer buffer = StringBuffer();
    for (final MathToken token in exponent) {
      final String? mapped = _superscriptDigits[token.value];
      if (token.type != MathTokenType.digit || mapped == null) {
        return null;
      }
      buffer.write(mapped);
    }
    return buffer.toString();
  }

  static List<MathToken> _tokenize(String raw) {
    final List<MathToken> tokens = <MathToken>[];
    int i = 0;

    while (i < raw.length) {
      final String char = raw[i];

      if (char.trim().isEmpty) {
        i++;
        continue;
      }
      if (raw.startsWith('sqrt', i)) {
        tokens.add(MathToken.sqrt);
        i += 4;
        continue;
      }
      if (raw.startsWith('pi', i)) {
        tokens.add(MathToken.pi);
        i += 2;
        continue;
      }
      if (raw.startsWith('<=', i)) {
        tokens.add(MathToken.lessOrEqual);
        i += 2;
        continue;
      }
      if (raw.startsWith('>=', i)) {
        tokens.add(MathToken.greaterOrEqual);
        i += 2;
        continue;
      }

      final MathToken? token = _tokenForChar(char);
      if (token != null) {
        tokens.add(token);
      }
      i++;
    }

    return tokens;
  }

  static MathToken? _tokenForChar(String char) {
    if (RegExp(r'[0-9]').hasMatch(char)) {
      return MathToken.digit(char);
    }
    if (RegExp('[a-zA-Z]').hasMatch(char)) {
      return MathToken.variable(char);
    }
    return switch (char) {
      '.' => MathToken.decimalPoint,
      '+' => MathToken.plus,
      '-' || '−' => MathToken.minus,
      '*' || '×' => MathToken.times,
      '÷' => MathToken.divide,
      '/' => MathToken.fraction,
      '=' => MathToken.equals,
      '<' => MathToken.lessThan,
      '>' => MathToken.greaterThan,
      '≤' => MathToken.lessOrEqual,
      '≥' => MathToken.greaterOrEqual,
      '%' => MathToken.percent,
      'π' => MathToken.pi,
      '(' => MathToken.open,
      ')' => MathToken.close,
      '^' => MathToken.exponent,
      '√' => MathToken.sqrt,
      _ => null,
    };
  }

  @override
  String toString() => 'MathExpression($displayText, cursor: $cursor)';
}
