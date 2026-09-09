/// Envelope returned by the Laravel API for paginated collections.
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasNextPage => currentPage < lastPage;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) parseItem,
  ) {
    final List<dynamic> rawItems = json['data'] as List<dynamic>? ?? <dynamic>[];
    final Map<String, dynamic> meta =
        json['meta'] as Map<String, dynamic>? ?? json;

    return PaginatedResponse<T>(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(parseItem)
          .toList(growable: false),
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
      perPage: meta['per_page'] as int? ?? rawItems.length,
      total: meta['total'] as int? ?? rawItems.length,
    );
  }
}
