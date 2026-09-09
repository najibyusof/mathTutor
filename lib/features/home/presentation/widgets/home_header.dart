import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/widgets.dart';

/// Home header: time-based greeting, student name and profile avatar.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.name,
    required this.initials,
    required this.subtitle,
    required this.now,
    required this.onAvatarTap,
    super.key,
  });

  final String name;
  final String initials;
  final String subtitle;
  final DateTime now;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                DateFormatter.greeting(now),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        AppAvatar(
          initials: initials,
          onTap: onAvatarTap,
          tooltip: name,
        ),
      ],
    );
  }
}
