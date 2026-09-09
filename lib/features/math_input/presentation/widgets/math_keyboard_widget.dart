import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/math_keys.dart';

/// Sectioned math keypad. Reports key presses; it holds no expression state.
class MathKeyboardWidget extends StatefulWidget {
  const MathKeyboardWidget({
    required this.onKeyPressed,
    this.canUndo = false,
    this.initialSection = MathKeyboardSection.basic,
    super.key,
  });

  final ValueChanged<MathKey> onKeyPressed;
  final bool canUndo;
  final MathKeyboardSection initialSection;

  @override
  State<MathKeyboardWidget> createState() => _MathKeyboardWidgetState();
}

class _MathKeyboardWidgetState extends State<MathKeyboardWidget> {
  late MathKeyboardSection _section = widget.initialSection;

  @override
  Widget build(BuildContext context) {
    final List<List<MathKey>> rows =
        MathKeyboardLayout.sections[_section] ?? <List<MathKey>>[];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Keys shrink on narrow phones so a full row always fits.
        final double keyHeight = constraints.maxWidth < 360 ? 44 : 52;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _sectionTabs(),
            const SizedBox(height: AppSpacing.md),
            _controlRow(keyHeight),
            const SizedBox(height: AppSpacing.sm),
            for (final List<MathKey> row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: <Widget>[
                    for (int i = 0; i < row.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _KeyButton(
                          mathKey: row[i],
                          height: keyHeight,
                          onPressed: () => widget.onKeyPressed(row[i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _sectionTabs() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: MathKeyboardSection.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final MathKeyboardSection section =
              MathKeyboardSection.values[index];
          return ChoiceChip(
            label: Text(section.label),
            selected: section == _section,
            onSelected: (_) => setState(() => _section = section),
          );
        },
      ),
    );
  }

  Widget _controlRow(double keyHeight) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < MathKeyboardLayout.controls.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _KeyButton(
              mathKey: MathKeyboardLayout.controls[i],
              height: keyHeight,
              onPressed:
                  MathKeyboardLayout.controls[i].action == MathKeyAction.undo &&
                      !widget.canUndo
                  ? null
                  : () => widget.onKeyPressed(MathKeyboardLayout.controls[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.mathKey,
    required this.height,
    required this.onPressed,
  });

  final MathKey mathKey;
  final double height;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool enabled = onPressed != null;

    final Color background = mathKey.isEmphasized
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final Color foreground = mathKey.isEmphasized
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onSurface;

    return Semantics(
      button: true,
      label: mathKey.semanticsLabel ?? mathKey.label,
      child: SizedBox(
        height: height,
        child: Material(
          color: enabled
              ? background
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: mathKey.icon != null
                  ? Icon(
                      mathKey.icon,
                      size: AppSizes.iconMd,
                      color: enabled
                          ? foreground
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                    )
                  : Text(
                      mathKey.label,
                      style: AppTypography.mathExpression.copyWith(
                        fontSize: mathKey.label.length > 2 ? 15 : 20,
                        color: foreground,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
