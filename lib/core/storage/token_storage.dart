import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistence contract for the bearer token and its owner.
///
/// Kept as an interface so the storage backend can be swapped (and faked in
/// tests) without touching the auth feature.
abstract interface class TokenStorage {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<void> clear();
}

/// Platform keychain/keystore backed implementation.
///
/// Tokens must never be written to SharedPreferences; the defaults of
/// `flutter_secure_storage` use the iOS Keychain and Android Keystore.
class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'mathtutor.auth.token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _tokenKey);
}

/// Non-persistent implementation used by tests and the mock API mode.
class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage([this._token]);

  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> writeToken(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
