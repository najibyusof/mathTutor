import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/math_question.dart';
import '../../../../routes/app_routes.dart';
import '../../../recognition/presentation/pages/recognition_review_screen.dart';

/// List of previously asked questions. Backed by mock data in this phase.
class HistoryPage extends StatelessWidget {
  const HistoryPage({this.now, super.key});

  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final DateTime timestamp = now ?? DateTime.now();
    final List<MathQuestion> questions = MockData.recentQuestions();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.historyTitle)),
      body: SafeArea(
        child: questions.isEmpty
            ? const EmptyState(
                title: AppStrings.emptyHistoryTitle,
                message: AppStrings.emptyHistoryMessage,
                icon: Icons.history,
              )
            : ResponsiveContent(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.pageVertical,
                  ),
                  itemCount: questions.length,
                  itemBuilder: (BuildContext context, int index) {
                    final MathQuestion question = questions[index];
                    return QuestionTile(
                      question: question,
                      now: timestamp,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.review,
                        arguments: RecognitionReviewArgs(question: question),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
