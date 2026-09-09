import 'package:flutter/foundation.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Lifecycle of the session as observed by the UI.
enum AuthStatus {
  /// Start-up check has not finished yet.
  unknown,
  authenticated,
  unauthenticated,
}

/// Holds authentication state and exposes the auth use cases to the UI.
class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;
  bool _isBusy = false;
  String? _errorMessage;
  String? _statusMessage;
  Map<String, List<String>> _fieldErrors = const <String, List<String>>{};

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  bool get isBusy => _isBusy;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  Map<String, List<String>> get fieldErrors => _fieldErrors;

  /// First error reported for [field], if any.
  String? fieldError(String field) => _fieldErrors[field]?.firstOrNull;

  /// Restores a previous session at start-up; an expired or missing token
  /// simply leaves the user signed out.
  Future<void> bootstrap() async {
    if (!await _repository.hasStoredToken()) {
      _setUnauthenticated();
      return;
    }

    final Result<AuthUser> result = await _repository.currentUser();
    result.when(
      onSuccess: _setAuthenticated,
      onFailure: (Failure _) => _setUnauthenticated(),
    );
  }

  Future<bool> login({required String email, required String password}) {
    return _run(
      () => _repository.login(email: email, password: password),
      onSuccess: _setAuthenticated,
    );
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) {
    return _run(
      () => _repository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      ),
      onSuccess: _setAuthenticated,
    );
  }

  /// Requests a reset link; [statusMessage] holds the confirmation on success.
  Future<bool> forgotPassword({required String email}) {
    return _run<String>(
      () => _repository.forgotPassword(email: email),
      onSuccess: (String message) => _statusMessage = message,
    );
  }

  Future<void> logout() async {
    _setBusy(true);
    await _repository.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _clearMessages();
    _setBusy(false);
  }

  /// Drops the session locally after the API rejected the stored token.
  void handleExpiredSession() {
    if (_status == AuthStatus.unauthenticated) {
      return;
    }
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = 'Your session has expired. Please sign in again.';
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null && _fieldErrors.isEmpty) {
      return;
    }
    _clearMessages();
    notifyListeners();
  }

  Future<bool> _run<T>(
    Future<Result<T>> Function() action, {
    required void Function(T value) onSuccess,
  }) async {
    _clearMessages();
    _setBusy(true);

    final Result<T> result = await action();
    final bool succeeded = result.when<bool>(
      onSuccess: (T value) {
        onSuccess(value);
        return true;
      },
      onFailure: (Failure failure) {
        _errorMessage = friendlyMessage(failure);
        if (failure is ValidationFailure) {
          _fieldErrors = failure.fieldErrors;
        }
        return false;
      },
    );

    _setBusy(false);
    return succeeded;
  }

  void _setAuthenticated(AuthUser user) {
    _user = user;
    _status = AuthStatus.authenticated;
  }

  void _setUnauthenticated() {
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _statusMessage = null;
    _fieldErrors = const <String, List<String>>{};
  }
}
