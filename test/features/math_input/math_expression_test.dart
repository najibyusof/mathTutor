import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/features/math_input/domain/math_expression.dart';
import 'package:mathtutor/features/math_input/domain/math_token.dart';

MathExpression _typed(List<MathToken> tokens) {
  MathExpression expression = MathExpression.empty;
  for (final MathToken token in tokens) {
    expression = expression.insert(<MathToken>[token]);
  }
  return expression;
}

const List<MathToken> _square = <MathToken>[
  MathToken.exponent,
  MathToken.open,
  MathToken(MathTokenType.digit, '2'),
  MathToken.close,
];

void main() {
  group('editing', () {
    test('typing builds a readable expression', () {
      final MathExpression expression = _typed(<MathToken>[
        MathToken.digit('2'),
        MathToken.variable('x'),
        MathToken.plus,
        MathToken.digit('5'),
        MathToken.equals,
        MathToken.digit('1'),
        MathToken.digit('5'),
      ]);

      expect(expression.displayText, '2x + 5 = 15');
      expect(expression.rawInput, '2*x+5=15');
      expect(expression.cursor, expression.tokens.length);
    });

    test('renders exponents with superscripts', () {
      MathExpression expression = _typed(<MathToken>[MathToken.variable('x')]);
      expression = expression.insert(_square);
      expression = expression.insert(<MathToken>[MathToken.plus]);
      expression = expression.insert(<MathToken>[
        MathToken.digit('5'),
        MathToken.variable('x'),
      ]);

      expect(expression.displayText, 'x² + 5x');
      expect(expression.rawInput, 'x^(2)+5*x');
    });

    test('inserts at the caret instead of at the end', () {
      MathExpression expression = _typed(<MathToken>[
        MathToken.digit('1'),
        MathToken.plus,
        MathToken.digit('3'),
      ]);

      expression = expression.moveLeft();
      expression = expression.insert(<MathToken>[MathToken.digit('2')]);

      expect(expression.displayText, '1 + 23');
      expect(expression.cursor, 3);
    });

    test('supports reopening a stored expression for editing', () {
      final MathExpression expression = MathExpression.parse(
        '(x + 3)/2 = 7',
      ).moveToEnd();

      expect(expression.displayText, '(x + 3)/2 = 7');
      expect(expression.rawInput, '(x+3)/2=7');
      expect(expression.cursor, expression.tokens.length);
    });

    test('cursor movement stops at both ends', () {
      MathExpression expression = _typed(<MathToken>[MathToken.digit('9')]);

      expect(expression.moveRight().cursor, 1);
      expression = expression.moveLeft();
      expect(expression.cursor, 0);
      expect(expression.moveLeft().cursor, 0);
    });
  });

  group('validation', () {
    test('rejects a leading operator but allows a leading minus', () {
      expect(
        MathExpression.empty.insert(<MathToken>[MathToken.plus]).isEmpty,
        isTrue,
      );
      expect(
        MathExpression.empty
            .insert(<MathToken>[MathToken.minus])
            .displayText,
        '−',
      );
    });

    test('replaces a trailing operator instead of stacking operators', () {
      MathExpression expression = _typed(<MathToken>[
        MathToken.digit('4'),
        MathToken.plus,
      ]);
      expression = expression.insert(<MathToken>[MathToken.times]);

      expect(expression.displayText, '4 ×');
      expect(expression.tokens.length, 2);
    });

    test('allows only one decimal point per number', () {
      MathExpression expression = _typed(<MathToken>[
        MathToken.digit('1'),
        MathToken.decimalPoint,
        MathToken.digit('5'),
        MathToken.decimalPoint,
      ]);

      expect(expression.displayText, '1.5');

      expression = expression.insert(<MathToken>[MathToken.plus]);
      expression = expression.insert(<MathToken>[MathToken.decimalPoint]);
      expect(expression.displayText, '1.5 + .');
    });

    test('rejects a relation after an operator', () {
      final MathExpression expression = _typed(<MathToken>[
        MathToken.digit('2'),
        MathToken.plus,
        MathToken.equals,
      ]);

      expect(expression.displayText, '2 +');
    });

    test('rejects percent and exponent without a preceding value', () {
      expect(
        MathExpression.empty.insert(<MathToken>[MathToken.percent]).isEmpty,
        isTrue,
      );
      expect(MathExpression.empty.insert(_square).isEmpty, isTrue);
    });

    test('rejects an unmatched closing parenthesis', () {
      expect(
        MathExpression.empty.insert(<MathToken>[MathToken.close]).isEmpty,
        isTrue,
      );
    });
  });

  group('backspace', () {
    test('removes the token before the caret', () {
      final MathExpression expression = _typed(<MathToken>[
        MathToken.digit('1'),
        MathToken.digit('2'),
      ]).backspace();

      expect(expression.displayText, '1');
      expect(expression.cursor, 1);
    });

    test('steps inside a group before deleting its content', () {
      MathExpression expression = MathExpression.empty.insert(
        <MathToken>[MathToken.open, MathToken.close],
        cursorOffset: 1,
      );
      expression = expression.insert(<MathToken>[MathToken.variable('x')]);
      expression = expression.moveRight();

      expression = expression.backspace();
      expect(expression.displayText, '(x)');
      expect(expression.cursor, 2);

      expression = expression.backspace();
      expect(expression.displayText, '()');
    });

    test('deletes both parentheses of an empty group', () {
      MathExpression expression = _typed(<MathToken>[MathToken.digit('2')]);
      expression = expression.insert(
        <MathToken>[MathToken.open, MathToken.close],
        cursorOffset: 2,
      );

      expression = expression.backspace();

      expect(expression.displayText, '2');
      expect(expression.isBalanced, isTrue);
    });

    test('deletes an exponent together with its marker', () {
      MathExpression expression = _typed(<MathToken>[MathToken.variable('x')]);
      expression = expression.insert(<MathToken>[
        MathToken.exponent,
        MathToken.open,
        MathToken.close,
      ]);

      expression = expression.backspace();

      expect(expression.displayText, 'x');
      expect(expression.tokens.length, 1);
    });

    test('keeps parentheses balanced when the opening one is deleted', () {
      MathExpression expression = MathExpression.empty.insert(
        <MathToken>[MathToken.open, MathToken.close],
        cursorOffset: 1,
      );
      expression = expression.insert(<MathToken>[MathToken.variable('y')]);
      expression = expression.moveLeft();

      expression = expression.backspace();

      expect(expression.displayText, 'y');
      expect(expression.isBalanced, isTrue);
    });

    test('does nothing at the start of the expression', () {
      expect(MathExpression.empty.backspace().isEmpty, isTrue);
    });
  });

  test('clear empties the expression', () {
    expect(
      _typed(<MathToken>[MathToken.digit('7')]).clear().isEmpty,
      isTrue,
    );
  });

  test('fraction and root render in the readable and raw forms', () {
    MathExpression expression = MathExpression.empty.insert(
      <MathToken>[
        MathToken.open,
        MathToken.close,
        MathToken.fraction,
        MathToken.open,
        MathToken.close,
      ],
      cursorOffset: 1,
    );
    expression = expression.insert(<MathToken>[
      MathToken.variable('x'),
      MathToken.plus,
      MathToken.digit('3'),
    ]);
    expression = expression.moveRight().moveRight().moveRight();
    expression = expression.insert(<MathToken>[MathToken.digit('2')]);

    expect(expression.displayText, '(x + 3)/(2)');
    expect(expression.rawInput, '(x+3)/(2)');
    expect(expression.isBalanced, isTrue);
  });
}
