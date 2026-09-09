import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../features/auth/domain/entities/auth_user.dart';
import '../../../../features/auth/presentation/controllers/auth_scope.dart';
import '../../../../models/math_question.dart';
import '../../../../models/question_input_method.dart';
import '../../../../models/user_profile.dart';
import '../../../../routes/app_router.dart';
import '../../../../routes/app_routes.dart';
import '../widgets/ask_question_card.dart';
import '../widgets/home_header.dart';
import '../widgets/input_method_card.dart';
import '../widgets/study_tip_banner.dart';

/// Landing screen: greeting, main action, input methods and recent activity.
class HomePage extends StatelessWidget {
  const HomePage({this.now, super.key});

  /// Injectable clock so greetings and relative times stay testable.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final DateTime timestamp = now ?? DateTime.now();
    const UserProfile profile = MockData.currentUser;
    final AuthUser? user = AuthScope.maybeOf(context)?.user;
    final List<MathQuestion> recent = MockData.recentQuestions();

    return Scaffold(
      body: SafeArea(
        child: ResponsiveContent(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.pageVertical,
            ),
            children: <Widget>[
              HomeHeader(
                name: user?.firstName ?? profile.firstName,
                initials: user?.initials ?? profile.initials,
                subtitle: profile.gradeLabel,
                now: timestamp,
                onAvatarTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.profile),
              ),
              const SizedBox(height: AppSpacing.lg),
              StudyTipBanner(tip: MockData.tipOfTheDay(timestamp)),
              const SizedBox(height: AppSpacing.xl),
              AskQuestionCard(
                onTap: () => _openInput(context, QuestionInputMethod.type),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: AppStrings.chooseInputMethod),
              const SizedBox(height: AppSpacing.sm),
              InputMethodGrid(
                onMethodSelected: (QuestionInputMethod method) =>
                    _openInput(context, method),
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: AppStrings.recentQuestions,
                action: TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.history),
                  child: const Text(AppStrings.viewHistory),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (recent.isEmpty)
                const EmptyState(
                  title: AppStrings.emptyHistoryTitle,
                  message: AppStrings.emptyHistoryMessage,
                  icon: Icons.history,
                )
              else
                for (final MathQuestion question in recent)
                  QuestionTile(
                    question: question,
                    now: timestamp,
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.solver,
                      arguments: SolverArgs(
                        expression: question.expression,
                        source: question.inputMethod.name,
                      ),
                    ),
                  ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  void _openInput(BuildContext context, QuestionInputMethod method) {
    Navigator.of(context).pushNamed(
      AppRoutes.mathInput,
      arguments: MathInputArgs(method: method),
    );
  }
}
