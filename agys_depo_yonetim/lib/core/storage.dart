import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppStorage {
  static const _tokenKey = 'auth_token';
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> readToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
