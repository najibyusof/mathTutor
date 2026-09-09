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
        originalInput: '2x + 5 = 17',
        normalizedExpression: '2*x+5=17',
        inputMethod: QuestionInputMethod.keyboard,
        confidence: 1,
        createdAt: now.subtract(const Duration(minutes: 25)),
      ),
      MathQuestion(
        id: 'q-2',
        originalInput: '6 handwritten strokes',
        normalizedExpression: '3*x-7=14',
        inputMethod: QuestionInputMethod.handwriting,
        confidence: 0.92,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      MathQuestion(
        id: 'q-3',
        originalInput: 'Photo 1600×1200 (240 KB)',
        normalizedExpression: 'x^(2)-7*x+12=0',
        inputMethod: QuestionInputMethod.camera,
        confidence: 0.78,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      MathQuestion(
        id: 'q-4',
        originalInput: '(x + 3)/2 = 7',
        normalizedExpression: '(x+3)/2=7',
        inputMethod: QuestionInputMethod.keyboard,
        confidence: 1,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }
}
