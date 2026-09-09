/// Authenticated user as exposed to the rest of the app.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
  });

  final int id;
  final String name;
  final String email;
  final DateTime? emailVerifiedAt;

  bool get isEmailVerified => emailVerifiedAt != null;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  String get initials {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
