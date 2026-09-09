/// Human-friendly date/time formatting without pulling in `intl`.
abstract final class DateFormatter {
  const DateFormatter._();

  /// Compact relative label such as `Just now`, `4h ago`, `Yesterday`.
  static String relative(DateTime value, {DateTime? now}) {
    final Duration diff = (now ?? DateTime.now()).difference(value);

    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) {
      return 'Yesterday';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${value.day}/${value.month}/${value.year}';
  }

  /// Greeting matching the time of day, e.g. `Good morning`.
  static String greeting(DateTime time) {
    final int hour = time.hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 18) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }
}
