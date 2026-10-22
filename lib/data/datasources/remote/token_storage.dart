import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Antarmuka penyimpanan token (dapat diuji tanpa plugin platform).
abstract class TokenStore {
  Future<String?> readToken();
  Future<void> saveToken(String token);
  Future<void> clearToken();
}

/// Penyimpanan token Sanctum di secure storage perangkat.
class TokenStorage implements TokenStore {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'tahandulu_access_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}

/// Implementasi in-memory untuk pengujian (tanpa plugin platform).
class MemoryTokenStore implements TokenStore {
  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<void> clearToken() async => _token = null;
}
