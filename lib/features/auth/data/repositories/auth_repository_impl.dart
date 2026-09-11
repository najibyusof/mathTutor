import '../../../../core/errors/failures.dart';
import '../../../../core/network/result.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Coordinates the auth endpoints with secure token persistence.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required TokenStorage tokenStorage,
  }) : _remote = remote,
       _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  @override
  Future<bool> hasStoredToken() async =>
      (await _tokenStorage.readToken())?.isNotEmpty ?? false;

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) {
    return _guard<AuthUser>(() async {
      final AuthSession session = await _remote.login(
        email: email.trim(),
        password: password,
      );
      await _tokenStorage.writeToken(session.token);
      return session.user;
    });
  }

  @override
  Future<Result<AuthUser>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) {
    return _guard<AuthUser>(() async {
      final AuthSession session = await _remote.register(
        name: name.trim(),
        email: email.trim(),
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      await _tokenStorage.writeToken(session.token);
      return session.user;
    });
  }

  @override
  Future<Result<String>> forgotPassword({required String email}) {
    return _guard<String>(() => _remote.forgotPassword(email: email.trim()));
  }

  @override
  Future<Result<void>> logout() async {
    // The local token is dropped even when the server call fails, so the
    // device never keeps a session the user asked to end.
    try {
      await _remote.logout();
      return const Result<void>.success(null);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Logout request failed',
        error: error,
        stackTrace: stackTrace,
      );
      return Result<void>.failure(mapExceptionToFailure(error));
    } finally {
      await _tokenStorage.clear();
    }
  }

  @override
  Future<void> clearStoredSession() => _tokenStorage.clear();

  @override
  Future<Result<AuthUser>> currentUser() async {
    if (!await hasStoredToken()) {
      return const Result<AuthUser>.failure(
        UnauthorizedFailure('No stored session.'),
      );
    }

    final Result<AuthUser> result = await _guard<AuthUser>(_remote.currentUser);
    if (result.failureOrNull is UnauthorizedFailure) {
      await _tokenStorage.clear();
    }
    return result;
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result<T>.success(await action());
    } catch (error, stackTrace) {
      AppLogger.error(
        'Auth request failed',
        error: error,
        stackTrace: stackTrace,
      );
      return Result<T>.failure(mapExceptionToFailure(error));
    }
  }
}
