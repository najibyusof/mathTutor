import '../../../../models/math_question.dart';

/// One server page of history results.
class HistoryPage {
  const HistoryPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<MathQuestion> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasNextPage => currentPage < lastPage;
}
