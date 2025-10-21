import 'package:dio/dio.dart';
import 'settings.dart';
import 'storage.dart';

class ApiService {
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: Settings.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      validateStatus: (s) => s != null && s < 500,
    ));

    // mevcut token'ı başlatırken yükle
    AppStorage.readToken().then((t) {
      if (t != null && t.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $t';
      }
    });

    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  static final ApiService instance = ApiService._internal();
  late final Dio _dio;
  Dio get dio => _dio;
}
