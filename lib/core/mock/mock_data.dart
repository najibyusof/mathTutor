import '../../models/math_question.dart';
import '../../models/question_input_method.dart';
import '../../models/user_profile.dart';

/// Static sample content used while the backend is not connected.
///
/// Replaced by repositories once the API layer lands.
abstract final class MockData {
  const MockData._();

  static const UserProfile currentUser = UserProfile(
    displayName: 'Alex Morgan',
    gradeLabel: 'Grade 10 • Algebra',
    solvedCount: 128,
    streakDays: 5,
  );

  /// Short educational nudges rotated on the home header.
  static const List<String> studyTips = <String>[
    'Break every problem into small steps — the steps are the real lesson.',
    'Check your answer by substituting it back into the original equation.',
    'Sketch the problem first; a diagram often reveals the method.',
    'Practise a little every day beats one long session each week.',
  ];

  /// Deterministic tip for [date] so the UI stays stable between rebuilds.
  static String tipOfTheDay(DateTime date) =>
      studyTips[date.day % studyTips.length];

  static List<MathQuestion> recentQuestions() {
    final DateTime now = DateTime(2026, 3, 18, 16, 30);
    return <MathQuestion>[
      MathQuestion(
        id: 'q-1',
        expression: '2x + 5 = 17',
        topic: 'Linear equations',
        inputMethod: QuestionInputMethod.type,
        createdAt: now.subtract(const Duration(minutes: 25)),
        answerPreview: 'x = 6',
      ),
      MathQuestion(
        id: 'q-2',
        expression: '∫ 3x² dx',
        topic: 'Integration',
        inputMethod: QuestionInputMethod.write,
        createdAt: now.subtract(const Duration(hours: 5)),
        answerPreview: 'x³ + C',
      ),
      MathQuestion(
        id: 'q-3',
        expression: 'x² − 7x + 12 = 0',
        topic: 'Quadratic equations',
        inputMethod: QuestionInputMethod.scan,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        answerPreview: 'x = 3 or x = 4',
      ),
      MathQuestion(
        id: 'q-4',
        expression: 'sin(θ) = 0.5',
        topic: 'Trigonometry',
        inputMethod: QuestionInputMethod.type,
        createdAt: now.subtract(const Duration(days: 3)),
        answerPreview: 'θ = 30°',
      ),
    ];
  }
}
