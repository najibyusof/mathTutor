import '../../../../core/network/result.dart';
import '../entities/auth_user.dart';

/// Contract the UI depends on; implemented in the data layer.
///
/// Every method returns a [Result] so callers handle failures explicitly
/// instead of catching transport exceptions.
abstract interface class AuthRepository {
  /// Whether a bearer token is currently stored on the device.
  Future<bool> hasStoredToken();

  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  });

  Future<Result<AuthUser>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  });

  /// Requests a reset link; resolves to the API's confirmation message.
  Future<Result<String>> forgotPassword({required String email});

  /// Revokes the token server-side and always clears it locally.
  Future<Result<void>> logout();

  /// Restores the session at start-up using the stored token.
  Future<Result<AuthUser>> currentUser();
}
