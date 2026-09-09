/// The signed-in student. Populated from mock data until auth is implemented.
class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.gradeLabel,
    this.solvedCount = 0,
    this.streakDays = 0,
  });

  final String displayName;
  final String gradeLabel;
  final int solvedCount;
  final int streakDays;

  /// Up to two uppercase letters used by the avatar placeholder.
  String get initials {
    final List<String> parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get firstName => displayName.trim().split(RegExp(r'\s+')).first;
}
