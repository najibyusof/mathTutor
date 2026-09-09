/// Envelope returned by the Laravel API for single-resource endpoints.
///
/// ```json
/// { "success": true, "message": "OK", "data": { ... } }
/// ```
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors = const <String, List<String>>{},
  });

  final bool success;
  final String? message;
  final T? data;
  final Map<String, List<String>> errors;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? data)? parseData,
  ) {
    final Object? rawData = json['data'];
    return ApiResponse<T>(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
      data: parseData == null || rawData == null ? null : parseData(rawData),
      errors: parseErrors(json['errors']),
    );
  }

  /// Normalizes Laravel's `errors` bag into `field -> messages`.
  static Map<String, List<String>> parseErrors(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return const <String, List<String>>{};
    }
    return raw.map(
      (String key, dynamic value) => MapEntry<String, List<String>>(
        key,
        value is List
            ? value.map((Object? item) => '$item').toList(growable: false)
            : <String>['$value'],
      ),
    );
  }
}
