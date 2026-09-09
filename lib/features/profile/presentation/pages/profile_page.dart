import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../features/auth/domain/entities/auth_user.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../features/auth/presentation/controllers/auth_scope.dart';
import '../../../../routes/app_routes.dart';

/// Account screen: identity summary and sign-out.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AuthController? auth = AuthScope.maybeOf(context);
    final AuthUser? user = auth?.user;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileTitle)),
      body: SafeArea(
        child: ResponsiveContent(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.pageVertical,
            ),
            children: <Widget>[
              Row(
                children: <Widget>[
                  AppAvatar(
                    initials: user?.initials ?? MockData.currentUser.initials,
                    size: 64,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          user?.name ?? MockData.currentUser.displayName,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          user?.email ?? MockData.currentUser.gradeLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: AppStrings.profileSubtitle),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text(AppStrings.historyTitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.history),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.logout, color: theme.colorScheme.error),
                      title: Text(
                        AppStrings.signOut,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      enabled: auth != null && !auth.isBusy,
                      onTap: () => _confirmSignOut(context, auth!),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    AuthController auth,
  ) async {
    final NavigatorState navigator = Navigator.of(context);
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text(AppStrings.signOutConfirmTitle),
            content: const Text(AppStrings.signOutConfirmMessage),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text(AppStrings.signOut),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await auth.logout();
    navigator.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (Route<dynamic> route) => false,
    );
  }
}
