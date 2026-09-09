import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/math_expression.dart';
import '../../domain/math_token.dart';

/// Read/write display of a [MathExpression] in conventional math notation:
/// stacked fractions, radicals, superscripts and a caret.
///
/// Rendering only — edits arrive through the controller that owns the
/// expression.
class MathInputWidget extends StatelessWidget {
  const MathInputWidget({
    required this.expression,
    this.showCaret = true,
    this.placeholder,
    this.fontSize = 28,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });

  final MathExpression expression;
  final bool showCaret;
  final String? placeholder;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle style = AppTypography.mathExpression.copyWith(
      fontSize: fontSize,
      color: theme.colorScheme.onSurface,
    );

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: fontSize * 3),
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      alignment: Alignment.centerLeft,
      child: expression.isEmpty && !showCaret
          ? _placeholderText(theme, style)
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (expression.isEmpty && placeholder != null)
                    _placeholderText(theme, style),
                  ..._ExpressionRenderer(
                    expression: expression,
                    style: style,
                    caretColor: theme.colorScheme.primary,
                    placeholderColor: theme.colorScheme.outline,
                    showCaret: showCaret,
                  ).build(),
                ],
              ),
            ),
    );
  }

  Widget _placeholderText(ThemeData theme, TextStyle style) {
    return Text(
      placeholder ?? '',
      style: style.copyWith(
        fontSize: fontSize * 0.6,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Turns the flat token list into nested math layout widgets.
class _ExpressionRenderer {
  _ExpressionRenderer({
    required this.expression,
    required this.style,
    required this.caretColor,
    required this.placeholderColor,
    required this.showCaret,
  });

  final MathExpression expression;
  final TextStyle style;
  final Color caretColor;
  final Color placeholderColor;
  final bool showCaret;

  bool _caretPlaced = false;

  List<MathToken> get _tokens => expression.tokens;

  List<Widget> build() {
    final List<Widget> children = _buildRange(0, _tokens.length, style);
    if (showCaret && !_caretPlaced) {
      children.add(_caret(style));
    }
    return children;
  }

  List<Widget> _buildRange(int start, int end, TextStyle style) {
    final List<_Unit> units = <_Unit>[];
    int i = start;

    while (i < end) {
      final MathToken token = _tokens[i];

      if (token.type == MathTokenType.sqrt && _isOpenAt(i + 1)) {
        final int close = expression.matchingClose(i + 1) ?? end;
        units.add(
          _Unit(
            start: i,
            child: _radical(_buildRange(i + 2, close, style), style),
          ),
        );
        i = close + 1;
        continue;
      }

      if (token.type == MathTokenType.exponent && _isOpenAt(i + 1)) {
        final int close = expression.matchingClose(i + 1) ?? end;
        final TextStyle small = style.copyWith(fontSize: style.fontSize! * 0.6);
        final Widget superscript = Transform.translate(
          offset: Offset(0, -style.fontSize! * 0.35),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _buildRange(i + 2, close, small),
          ),
        );
        if (units.isEmpty) {
          units.add(_Unit(start: i, child: superscript));
        } else {
          final _Unit base = units.removeLast();
          units.add(
            _Unit(
              start: base.start,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[base.child, superscript],
              ),
            ),
          );
        }
        i = close + 1;
        continue;
      }

      if (token.type == MathTokenType.fraction && units.isNotEmpty) {
        final _Unit numerator = units.removeLast();
        final (Widget denominator, int nextIndex) = _readUnit(i + 1, end, style);
        units.add(
          _Unit(
            start: numerator.start,
            child: _fraction(numerator.child, denominator, style),
          ),
        );
        i = nextIndex;
        continue;
      }

      if (token.type == MathTokenType.open) {
        final int close = expression.matchingClose(i) ?? end;
        units.add(
          _Unit(
            start: i,
            child: _parenthesized(_buildRange(i + 1, close, style), style),
          ),
        );
        i = close + 1;
        continue;
      }

      units.add(_Unit(start: i, child: _tokenWidget(token, style)));
      i++;
    }

    final List<Widget> children = <Widget>[];
    for (final _Unit unit in units) {
      if (_shouldPlaceCaretAt(unit.start)) {
        children.add(_caret(style));
      }
      children.add(unit.child);
    }
    if (_shouldPlaceCaretAt(end)) {
      children.add(_caret(style));
    }
    if (children.isEmpty) {
      children.add(_emptySlot(style));
    }
    return children;
  }

  /// Reads the single unit that starts at [index], for fraction denominators.
  (Widget, int) _readUnit(int index, int end, TextStyle style) {
    if (index >= end) {
      return (_emptySlot(style), index);
    }
    if (_tokens[index].type == MathTokenType.open) {
      final int close = expression.matchingClose(index) ?? end;
      final List<Widget> content = _buildRange(index + 1, close, style);
      return (
        Row(mainAxisSize: MainAxisSize.min, children: content),
        close + 1,
      );
    }
    final List<Widget> content = _buildRange(index, index + 1, style);
    return (Row(mainAxisSize: MainAxisSize.min, children: content), index + 1);
  }

  bool _isOpenAt(int index) =>
      index < _tokens.length && _tokens[index].type == MathTokenType.open;

  bool _shouldPlaceCaretAt(int index) {
    if (!showCaret || _caretPlaced || expression.cursor != index) {
      return false;
    }
    _caretPlaced = true;
    return true;
  }

  Widget _tokenWidget(MathToken token, TextStyle style) {
    final bool spaced =
        token.type == MathTokenType.operator ||
        token.type == MathTokenType.relation;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spaced ? AppSpacing.xs : 0),
      child: Text(token.value, style: style),
    );
  }

  Widget _parenthesized(List<Widget> content, TextStyle style) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('(', style: style),
        ...content,
        Text(')', style: style),
      ],
    );
  }

  Widget _radical(List<Widget> content, TextStyle style) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text('√', style: style),
        Container(
          margin: EdgeInsets.only(top: style.fontSize! * 0.12),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: style.color!, width: 1.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: content),
        ),
      ],
    );
  }

  Widget _fraction(Widget numerator, Widget denominator, TextStyle style) {
    final TextStyle small = style.copyWith(fontSize: style.fontSize! * 0.8);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DefaultTextStyle.merge(style: small, child: numerator),
          Container(
            height: 1.4,
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            constraints: BoxConstraints(minWidth: style.fontSize!),
            color: style.color,
          ),
          DefaultTextStyle.merge(style: small, child: denominator),
        ],
      ),
    );
  }

  Widget _emptySlot(TextStyle style) {
    return Container(
      width: style.fontSize! * 0.55,
      height: style.fontSize! * 0.8,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      decoration: BoxDecoration(
        border: Border.all(color: placeholderColor),
        borderRadius: BorderRadius.circular(AppRadius.sm / 2),
      ),
    );
  }

  Widget _caret(TextStyle style) {
    return Container(
      width: 2,
      height: style.fontSize! * 1.1,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      color: caretColor,
    );
  }
}

class _Unit {
  const _Unit({required this.start, required this.child});

  /// Token index this unit begins at, used to position the caret.
  final int start;
  final Widget child;
}
