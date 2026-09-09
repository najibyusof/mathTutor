import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/errors/failures.dart';
import 'package:mathtutor/core/network/result.dart';
import 'package:mathtutor/features/auth/domain/entities/auth_user.dart';
import 'package:mathtutor/features/auth/domain/repositories/auth_repository.dart';
import 'package:mathtutor/features/auth/presentation/controllers/auth_controller.dart';

const AuthUser _user = AuthUser(
  id: 1,
  name: 'Alex Morgan',
  email: 'student@mathtutor.app',
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.storedToken = false,
    this.loginResult = const Result<AuthUser>.success(_user),
    this.currentUserResult = const Result<AuthUser>.success(_user),
  });

  bool storedToken;
  Result<AuthUser> loginResult;
  Result<AuthUser> currentUserResult;
  int logoutCalls = 0;

  @override
  Future<bool> hasStoredToken() async => storedToken;

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) async => loginResult;

  @override
  Future<Result<AuthUser>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async => loginResult;

  @override
  Future<Result<String>> forgotPassword({required String email}) async =>
      const Result<String>.success('We have emailed your reset link.');

  @override
  Future<Result<void>> logout() async {
    logoutCalls++;
    storedToken = false;
    return const Result<void>.success(null);
  }

  @override
  Future<Result<AuthUser>> currentUser() async => currentUserResult;
}

void main() {
  test('starts in the unknown state', () {
    final AuthController controller = AuthController(_FakeAuthRepository());

    expect(controller.status, AuthStatus.unknown);
    expect(controller.isAuthenticated, isFalse);
  });

  test('bootstrap signs in when a stored token is still valid', () async {
    final AuthController controller = AuthController(
      _FakeAuthRepository(storedToken: true),
    );

    await controller.bootstrap();

    expect(controller.status, AuthStatus.authenticated);
    expect(controller.user?.email, _user.email);
  });

  test('bootstrap stays signed out without a token', () async {
    final AuthController controller = AuthController(_FakeAuthRepository());

    await controller.bootstrap();

    expect(controller.status, AuthStatus.unauthenticated);
  });

  test('bootstrap stays signed out when the token expired', () async {
    final AuthController controller = AuthController(
      _FakeAuthRepository(
        storedToken: true,
        currentUserResult: const Result<AuthUser>.failure(
          UnauthorizedFailure('Unauthenticated.'),
        ),
      ),
    );

    await controller.bootstrap();

    expect(controller.status, AuthStatus.unauthenticated);
    expect(controller.user, isNull);
  });

  test('login exposes a friendly message on invalid credentials', () async {
    final AuthController controller = AuthController(
      _FakeAuthRepository(
        loginResult: const Result<AuthUser>.failure(
          UnauthorizedFailure('These credentials do not match our records.'),
        ),
      ),
    );

    final bool succeeded = await controller.login(
      email: 'a@b.c',
      password: 'nope',
    );

    expect(succeeded, isFalse);
    expect(controller.status, AuthStatus.unknown);
    expect(
      controller.errorMessage,
      'These credentials do not match our records.',
    );
  });

  test('login exposes per-field validation errors', () async {
    final AuthController controller = AuthController(
      _FakeAuthRepository(
        loginResult: const Result<AuthUser>.failure(
          ValidationFailure(
            'The given data was invalid.',
            fieldErrors: <String, List<String>>{
              'email': <String>['This email address is already registered.'],
            },
          ),
        ),
      ),
    );

    await controller.login(email: 'a@b.c', password: 'secret123');

    expect(
      controller.fieldError('email'),
      'This email address is already registered.',
    );
  });

  test('network failures report an offline message', () async {
    final AuthController controller = AuthController(
      _FakeAuthRepository(
        loginResult: const Result<AuthUser>.failure(
          NetworkFailure('SocketException'),
        ),
      ),
    );

    await controller.login(email: 'a@b.c', password: 'secret123');

    expect(controller.errorMessage, contains('No internet connection'));
  });

  test('logout clears the session', () async {
    final _FakeAuthRepository repository = _FakeAuthRepository(
      storedToken: true,
    );
    final AuthController controller = AuthController(repository);
    await controller.bootstrap();

    await controller.logout();

    expect(repository.logoutCalls, 1);
    expect(controller.status, AuthStatus.unauthenticated);
    expect(controller.user, isNull);
  });

  test('an expired session signs the user out with a message', () async {
    final AuthController controller = AuthController(
      _FakeAuthRepository(storedToken: true),
    );
    await controller.bootstrap();

    controller.handleExpiredSession();

    expect(controller.status, AuthStatus.unauthenticated);
    expect(controller.errorMessage, contains('session has expired'));
  });
}
