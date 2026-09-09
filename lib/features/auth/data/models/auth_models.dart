import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';

/// JSON mapping for the Laravel user resource.
class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.name,
    required super.email,
    super.emailVerifiedAt,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    if (id == null || json['email'] == null) {
      throw const ParsingException('The user response was incomplete.');
    }

    return AuthUserModel(
      id: id is int ? id : int.parse('$id'),
      name: json['name'] as String? ?? '',
      email: json['email'] as String,
      emailVerifiedAt: DateTime.tryParse(
        json['email_verified_at'] as String? ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'email': email,
    'email_verified_at': emailVerifiedAt?.toIso8601String(),
  };
}

/// JSON mapping for a login/register response.
class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.token,
    required AuthUserModel super.user,
    super.tokenType,
  });

  /// Accepts both a bare payload and one wrapped in `data`.
  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> payload =
        json['data'] as Map<String, dynamic>? ?? json;

    final String? token =
        payload['token'] as String? ?? payload['access_token'] as String?;
    final Map<String, dynamic>? user =
        payload['user'] as Map<String, dynamic>? ??
        payload['data'] as Map<String, dynamic>?;

    if (token == null || token.isEmpty || user == null) {
      throw const ParsingException(
        'The sign-in response did not contain a token.',
      );
    }

    return AuthSessionModel(
      token: token,
      user: AuthUserModel.fromJson(user),
      tokenType: payload['token_type'] as String? ?? 'Bearer',
    );
  }
}
