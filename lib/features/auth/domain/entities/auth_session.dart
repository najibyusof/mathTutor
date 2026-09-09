import 'auth_user.dart';

/// A bearer token together with the user it belongs to.
class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
    this.tokenType = 'Bearer',
  });

  final String token;
  final AuthUser user;
  final String tokenType;
}
