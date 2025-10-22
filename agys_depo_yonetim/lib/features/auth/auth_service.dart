import 'package:dio/dio.dart';
import '../../core/api_service.dart';
import '../../core/storage.dart';

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

    if (res.statusCode != 200) {
      throw DioException.badResponse(
        statusCode: res.statusCode ?? 500,
        requestOptions: res.requestOptions,
        response: res,
      );
    }

    // token çıkar
    String _clean(String s) => s.replaceAll('"', '').trim();
    final d = res.data;
    final raw = d is String
        ? d
        : (d['token'] ?? d['access_token'] ?? d['accessToken'])?.toString() ??
            '';
    final token = _clean(raw);
    if (token.isEmpty) {
      throw Exception('Token yok: ${res.data}');
    }

    // başlığa yaz + sakla
    _dio.options.headers['Authorization'] = 'Bearer $token';
    await AppStorage.saveToken(token);
    return token;
  }

  Future<void> logout() async {
    await AppStorage.clearToken();
    _dio.options.headers.remove('Authorization');
  }
}
