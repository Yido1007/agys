import '../../core/api_service.dart';
import '../../core/storage.dart';
import 'package:dio/dio.dart';

class AuthService {
  final _dio = ApiService.instance.dio;

  Future<String> login({
    required String eposta,
    required String sifre,
    required String antrepoKodu,
  }) async {
    final res = await _dio.post('/api/Auth/login', data: {
      'eposta': eposta,
      'sifre': sifre,
      'antrepoKodu': antrepoKodu,
    });

    String _clean(String s) => s.replaceAll('"', '').trim();
    final raw = res.data is String
        ? res.data as String
        : (res.data['token'] ??
                    res.data['access_token'] ??
                    res.data['accessToken'])
                ?.toString() ??
            '';
    final token = _clean(raw);
    if (token.isEmpty) {
      throw Exception('Token yok: ${res.data}');
    }

    _dio.options.headers['Authorization'] = 'Bearer $token';
    await AppStorage.saveToken(token);
    return token;
  }
}
