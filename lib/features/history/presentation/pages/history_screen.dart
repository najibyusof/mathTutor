import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/app_scope.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/math_question.dart';
import '../../../../routes/app_routes.dart';
import '../../../recognition/presentation/pages/recognition_review_screen.dart';
import '../../../math/presentation/controllers/math_api_controller.dart';
import '../../../solver/domain/models/math_problem.dart';
import '../widgets/history_item_tile.dart';

/// Paginated, searchable history of successfully saved questions.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({this.now, this.controller, super.key});

  final DateTime? now;
  final MathApiController? controller;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final MathApiController _controller;
  late final TextEditingController _searchController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.loadHistory();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = widget.controller ?? AppScope.of(context).mathController;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _controller.searchHistory(value);
    });
  }

  Future<void> _delete(MathQuestion question) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Delete question?'),
            content: const Text(
              'This history item will be permanently removed.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      await _controller.deleteHistoryItem(question.id);
    }
  }

  Future<void> _clearHistory() async {
    if (_controller.history.isEmpty) {
      return;
    }
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Clear history?'),
            content: const Text(
              'Every saved question in your history will be permanently removed.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Clear history'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      await _controller.clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.historyTitle),
        actions: <Widget>[
          IconButton(
            tooltip: 'Clear history',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _controller.history.isEmpty ? null : _clearHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, _) => Column(
              children: <Widget>[
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search questions',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _controller.searchHistory('');
                            },
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _CategoryFilter(controller: _controller),
                const SizedBox(height: AppSpacing.md),
                Expanded(child: _body()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_controller.isHistoryLoading && _controller.history.isEmpty) {
      return const LoadingIndicator(message: 'Loading history…');
    }
    if (_controller.historyError != null && _controller.history.isEmpty) {
      return ErrorMessage(
        title: 'Could not load history',
        message: _controller.historyError,
        onRetry: () => _controller.loadHistory(),
      );
    }
    if (_controller.history.isEmpty) {
      return const EmptyState(
        title: AppStrings.emptyHistoryTitle,
        message: AppStrings.emptyHistoryMessage,
        icon: Icons.history,
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.metrics.extentAfter < 300 &&
            !_controller.isHistoryLoading &&
            _controller.hasMoreHistory) {
          _controller.loadNextHistoryPage();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        itemCount:
            _controller.history.length + (_controller.isHistoryLoading ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index == _controller.history.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final MathQuestion question = _controller.history[index];
          return HistoryItemTile(
            question: question,
            now: widget.now,
            onDelete: () => _delete(question),
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.review,
              arguments: RecognitionReviewArgs(question: question),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.controller});

  final MathApiController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          FilterChip(
            label: const Text('All'),
            selected: controller.historyCategory == null,
            onSelected: (_) => controller.filterHistory(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          for (final MathCategory category in <MathCategory>[
            MathCategory.arithmetic,
            MathCategory.linearEquation,
            MathCategory.quadraticEquation,
            MathCategory.fraction,
            MathCategory.percentage,
          ]) ...<Widget>[
            FilterChip(
              label: Text(_label(category)),
              selected: controller.historyCategory == category,
              onSelected: (_) => controller.filterHistory(category),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  String _label(MathCategory category) => switch (category) {
    MathCategory.linearEquation => 'Linear Equation',
    MathCategory.quadraticEquation => 'Quadratic Equation',
    MathCategory.simultaneousEquations => 'Simultaneous Equations',
    MathCategory.arithmetic => 'Arithmetic',
    MathCategory.fraction => 'Fractions',
    MathCategory.percentage => 'Percentages',
    MathCategory.inequality => 'Inequalities',
    MathCategory.powers => 'Powers',
    MathCategory.roots => 'Roots',
    MathCategory.trigonometry => 'Trigonometry',
    MathCategory.calculus => 'Calculus',
  };
}
