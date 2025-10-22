import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const _k = 'auth_token';
  static Future<void> saveToken(String t) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_k, t);
  }

  static Future<String?> readToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_k);
  }

  static Future<void> clearToken() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_k);
  }
}
