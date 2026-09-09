import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/question_input_method.dart';

/// Tappable card for one input method (type, write or scan).
class InputMethodCard extends StatelessWidget {
  const InputMethodCard({
    required this.method,
    required this.onTap,
    super.key,
  });

  final QuestionInputMethod method;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIconBadge(icon: method.icon),
          const SizedBox(height: AppSpacing.md),
          Text(
            method.label,
            style: theme.textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            method.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Responsive row/grid of every [QuestionInputMethod].
class InputMethodGrid extends StatelessWidget {
  const InputMethodGrid({required this.onMethodSelected, super.key});

  final ValueChanged<QuestionInputMethod> onMethodSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isWide = constraints.maxWidth >= 420;
        final List<Widget> cards = QuestionInputMethod.values
            .map(
              (QuestionInputMethod method) => InputMethodCard(
                method: method,
                onTap: () => onMethodSelected(method),
              ),
            )
            .toList(growable: false);

        if (!isWide) {
          return Column(
            children: <Widget>[
              for (int i = 0; i < cards.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                cards[i],
              ],
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < cards.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                Expanded(child: cards[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}
