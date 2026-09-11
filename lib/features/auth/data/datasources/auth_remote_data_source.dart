import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/auth_models.dart';

/// Talks to the auth endpoints of the Laravel API.
///
/// Throws `AppException`s; translating them into failures is the repository's
/// job.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final ApiClient _client;

  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> json = await _client.post(
      ApiEndpoints.login,
      authenticated: false,
      body: <String, dynamic>{'email': email, 'password': password},
    );
    return AuthSessionModel.fromJson(json);
  }

  Future<AuthSessionModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final Map<String, dynamic> json = await _client.post(
      ApiEndpoints.register,
      authenticated: false,
      body: <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return AuthSessionModel.fromJson(json);
  }

  Future<String> forgotPassword({required String email}) async {
    final Map<String, dynamic> json = await _client.post(
      ApiEndpoints.forgotPassword,
      authenticated: false,
      body: <String, dynamic>{'email': email},
    );
    return json['message'] as String? ??
        'If that email exists, a reset link is on its way.';
  }

  Future<void> logout() => _client.post(ApiEndpoints.logout);

  Future<AuthUserModel> currentUser() async {
    final Map<String, dynamic> json = await _client.get(ApiEndpoints.user);
    final Map<String, dynamic> data =
        json['data'] as Map<String, dynamic>? ?? json;
    // The real API wraps the user one level deeper: data.user, not data.
    final Map<String, dynamic> user =
        data['user'] as Map<String, dynamic>? ?? data;
    return AuthUserModel.fromJson(user);
  }
}
