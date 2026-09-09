import 'package:flutter/material.dart';

import 'math_token.dart';

/// What pressing a key does to the expression.
enum MathKeyAction { insert, backspace, clear, undo, moveLeft, moveRight }

/// Definition of one keyboard key, independent of how it is rendered.
class MathKey {
  const MathKey({
    required this.label,
    this.action = MathKeyAction.insert,
    this.tokens = const <MathToken>[],
    this.cursorOffset,
    this.icon,
    this.semanticsLabel,
    this.isEmphasized = false,
  });

  final String label;
  final MathKeyAction action;
  final List<MathToken> tokens;

  /// Caret position relative to the start of [tokens]; `null` means "after".
  final int? cursorOffset;
  final IconData? icon;
  final String? semanticsLabel;

  /// Renders with the accent colour (used by the control keys).
  final bool isEmphasized;

  static MathKey token(MathToken token, {String? label}) =>
      MathKey(label: label ?? token.value, tokens: <MathToken>[token]);
}

/// Pages of the keyboard, kept short so every key stays reachable on a phone.
enum MathKeyboardSection {
  basic('123'),
  math('f(x)'),
  algebra('abc'),
  compare('<>');

  const MathKeyboardSection(this.label);

  final String label;
}

/// Static key layout for every section plus the shared control row.
abstract final class MathKeyboardLayout {
  const MathKeyboardLayout._();

  static const List<MathKey> controls = <MathKey>[
    MathKey(
      label: 'Undo',
      action: MathKeyAction.undo,
      icon: Icons.undo,
      semanticsLabel: 'Undo',
      isEmphasized: true,
    ),
    MathKey(
      label: 'Left',
      action: MathKeyAction.moveLeft,
      icon: Icons.chevron_left,
      semanticsLabel: 'Move cursor left',
      isEmphasized: true,
    ),
    MathKey(
      label: 'Right',
      action: MathKeyAction.moveRight,
      icon: Icons.chevron_right,
      semanticsLabel: 'Move cursor right',
      isEmphasized: true,
    ),
    MathKey(
      label: 'Backspace',
      action: MathKeyAction.backspace,
      icon: Icons.backspace_outlined,
      semanticsLabel: 'Backspace',
      isEmphasized: true,
    ),
    MathKey(
      label: 'Clear',
      action: MathKeyAction.clear,
      icon: Icons.delete_outline,
      semanticsLabel: 'Clear',
      isEmphasized: true,
    ),
  ];

  static final Map<MathKeyboardSection, List<List<MathKey>>> sections =
      <MathKeyboardSection, List<List<MathKey>>>{
        MathKeyboardSection.basic: <List<MathKey>>[
          <MathKey>[
            MathKey.token(MathToken.digit('7')),
            MathKey.token(MathToken.digit('8')),
            MathKey.token(MathToken.digit('9')),
            MathKey.token(MathToken.divide),
            _parentheses,
          ],
          <MathKey>[
            MathKey.token(MathToken.digit('4')),
            MathKey.token(MathToken.digit('5')),
            MathKey.token(MathToken.digit('6')),
            MathKey.token(MathToken.times),
            _fraction,
          ],
          <MathKey>[
            MathKey.token(MathToken.digit('1')),
            MathKey.token(MathToken.digit('2')),
            MathKey.token(MathToken.digit('3')),
            MathKey.token(MathToken.minus),
            MathKey.token(MathToken.equals),
          ],
          <MathKey>[
            MathKey.token(MathToken.digit('0')),
            MathKey.token(MathToken.decimalPoint),
            MathKey.token(MathToken.percent),
            MathKey.token(MathToken.plus),
            _square,
          ],
        ],
        MathKeyboardSection.math: <List<MathKey>>[
          <MathKey>[_fraction, _square, _power, _sqrt],
          <MathKey>[
            MathKey.token(MathToken.pi),
            MathKey.token(MathToken.percent),
            _parentheses,
            MathKey.token(MathToken.divide),
          ],
        ],
        MathKeyboardSection.algebra: <List<MathKey>>[
          <MathKey>[
            MathKey.token(MathToken.variable('x')),
            MathKey.token(MathToken.variable('y')),
            MathKey.token(MathToken.variable('a')),
            MathKey.token(MathToken.variable('b')),
            MathKey.token(MathToken.variable('c')),
          ],
          <MathKey>[_square, _power, _sqrt, _fraction, _parentheses],
        ],
        MathKeyboardSection.compare: <List<MathKey>>[
          <MathKey>[
            MathKey.token(MathToken.equals),
            MathKey.token(MathToken.lessThan),
            MathKey.token(MathToken.greaterThan),
            MathKey.token(MathToken.lessOrEqual),
            MathKey.token(MathToken.greaterOrEqual),
          ],
        ],
      };

  static const MathKey _parentheses = MathKey(
    label: '( )',
    tokens: <MathToken>[MathToken.open, MathToken.close],
    cursorOffset: 1,
    semanticsLabel: 'Parentheses',
  );

  /// Inserts an empty fraction and places the caret in the numerator.
  static const MathKey _fraction = MathKey(
    label: '▫/▫',
    tokens: <MathToken>[
      MathToken.open,
      MathToken.close,
      MathToken.fraction,
      MathToken.open,
      MathToken.close,
    ],
    cursorOffset: 1,
    semanticsLabel: 'Fraction',
  );

  static const MathKey _square = MathKey(
    label: 'x²',
    tokens: <MathToken>[
      MathToken.exponent,
      MathToken.open,
      MathToken(MathTokenType.digit, '2'),
      MathToken.close,
    ],
    semanticsLabel: 'Squared',
  );

  static const MathKey _power = MathKey(
    label: 'xⁿ',
    tokens: <MathToken>[MathToken.exponent, MathToken.open, MathToken.close],
    cursorOffset: 2,
    semanticsLabel: 'Exponent',
  );

  static const MathKey _sqrt = MathKey(
    label: '√',
    tokens: <MathToken>[MathToken.sqrt, MathToken.open, MathToken.close],
    cursorOffset: 2,
    semanticsLabel: 'Square root',
  );
}
