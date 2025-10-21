import 'package:antrepo_client/core/storage.dart';
import 'package:dio/dio.dart';
import '../../core/api_service.dart';
import 'models.dart';

class YerlesimService {
  final _dio = ApiService.instance.dio;

  Future<List<YerlesimYeri>> getAntrepoYerlesimler(int antrepoId) async {
    final res = await _dio.get('/api/YerlesimYeri/antrepo/$antrepoId');
    if (res.statusCode == 200) {
      final data = res.data;
      if (data is List) {
        return data
            .map((e) => YerlesimYeri.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else if (data is Map<String, dynamic> && data['items'] is List) {
        return (data['items'] as List)
            .map((e) => YerlesimYeri.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        // Try single
        return [];
      }
    } else {
      throw DioException.badResponse(
        statusCode: res.statusCode ?? 500,
        requestOptions: res.requestOptions,
        response: res,
      );
    }
  }

  Future<YerlesimYeri> getById(int id) async {
    final res = await _dio.get('/api/YerlesimYeri/$id');
    if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
      return YerlesimYeri.fromJson(Map<String, dynamic>.from(res.data));
    }
    throw DioException.badResponse(
      statusCode: res.statusCode ?? 500,
      requestOptions: res.requestOptions,
      response: res,
    );
  }

  Future<void> delete(int id) async {
    final res = await _dio.delete('/api/YerlesimYeri/$id');
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw DioException.badResponse(
        statusCode: res.statusCode ?? 500,
        requestOptions: res.requestOptions,
        response: res,
      );
    }
  }

  Future<YerlesimYeri> create(YerlesimYeri y) async {
    final t = await AppStorage.readToken();
    if (t == null || t.isEmpty) throw StateError('Token yok');

    final res = await _dio.post(
      '/api/YerlesimYeri',
      data: y.toCreateJson(), // {antrepoId,...}
      options: Options(headers: {'Authorization': 'Bearer $t'}),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      if (res.data is Map<String, dynamic>) {
        return YerlesimYeri.fromJson(Map<String, dynamic>.from(res.data));
      }
      return y; // API body döndürmüyorsa
    }

    throw DioException.badResponse(
      statusCode: res.statusCode ?? 500,
      requestOptions: res.requestOptions,
      response: res,
    );
  }

  Future<void> update(YerlesimYeri y) async {
    final t = await AppStorage.readToken();
    if (t == null || t.isEmpty) throw StateError('Token yok');

    final res = await _dio.put(
      '/api/YerlesimYeri',
      data: y.toUpdateJson(),
      options: Options(headers: {'Authorization': 'Bearer $t'}),
    );

    if (res.statusCode == 200 || res.statusCode == 204) return;

    throw DioException.badResponse(
      statusCode: res.statusCode ?? 500,
      requestOptions: res.requestOptions,
      response: res,
    );
  }
}
