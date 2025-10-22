import 'package:dio/dio.dart';
import '../../core/api_service.dart';
import 'models.dart';

class YerlesimService {
  final Dio _dio = ApiService.instance.dio;

  Future<List<YerlesimYeri>> getAntrepoYerlesimler(int antrepoId) async {
    final r = await _dio.get('/api/YerlesimYeri/antrepo/$antrepoId');
    if (r.statusCode == 200) {
      final d = r.data;
      List list;
      if (d is List) {
        list = d;
      } else if (d is Map<String, dynamic>) {
        list = (d['items'] ?? d['data'] ?? d['result'] ?? d['value'] ?? [])
            as List;
      } else {
        list = const [];
      }
      return list
          .map((e) => YerlesimYeri.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw DioException.badResponse(
      requestOptions: r.requestOptions,
      response: r,
      statusCode: r.statusCode ?? 500,
    );
  }

  Future<YerlesimYeri> create(YerlesimYeri y) async {
    final r = await _dio.post('/api/YerlesimYeri', data: y.toCreateJson());
    if (r.statusCode == 200 || r.statusCode == 201) {
      if (r.data is Map<String, dynamic>) {
        final map = Map<String, dynamic>.from(r.data);
        final payload = map['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(map['data'])
            : map;
        return YerlesimYeri.fromJson(payload);
      }
      return y;
    }
    throw DioException.badResponse(
      requestOptions: r.requestOptions,
      response: r,
      statusCode: r.statusCode ?? 500,
    );
  }

  Future<void> update(YerlesimYeri y) async {
    if (y.id <= 0) throw ArgumentError('id<=0');

    Response r;

    // 1) PUT gövde
    r = await _dio.put('/api/YerlesimYeri', data: y.toUpdateJson());
    if (r.statusCode == 200 || r.statusCode == 204) return;

    // 2) PUT path + gövde
    r = await _dio.put('/api/YerlesimYeri/${y.id}', data: y.toUpdateJson());
    if (r.statusCode == 200 || r.statusCode == 204) return;

    // 3) POST /update
    r = await _dio.post('/api/YerlesimYeri/update', data: y.toUpdateJson());
    if (r.statusCode == 200 || r.statusCode == 204) return;

    // 4) Method-Override
    r = await _dio.post(
      '/api/YerlesimYeri',
      data: y.toUpdateJson(),
      options: Options(headers: {'X-HTTP-Method-Override': 'PUT'}),
    );
    if (r.statusCode == 200 || r.statusCode == 204) return;

    throw DioException.badResponse(
      requestOptions: r.requestOptions,
      response: r,
      statusCode: r.statusCode ?? 500,
    );
  }

  Future<bool> delete(int id, {required int antrepoId}) async {
    Response r;

    bool ok(Response x) {
      if (x.statusCode == 204) return true;
      if (x.statusCode == 200) {
        final d = x.data;
        if (d == null || d.toString().isEmpty) return true;
        if (d is Map) {
          if (d['success'] == true) return true;
          if (d['data'] == true) return true;
        }
      }
      return false;
    }

    Future<bool> verifyGone() async {
      try {
        final g = await _dio.get('/api/YerlesimYeri/$id');
        // bazı API’ler bulunamayınca 404 veya null/data:false döner
        final d = g.data;
        final notFound = g.statusCode == 404 ||
            (d is Map && (d['success'] == false || d['data'] == null)) ||
            d == null;
        return notFound;
      } catch (e) {
        // 404 gibi durumlarda Dio hata atar → silinmiş say
        return true;
      }
    }

    // V1: DELETE /{id}
    r = await _dio.delete('/api/YerlesimYeri/$id');
    if (ok(r)) return true;
    if (await verifyGone()) return true;

    // V2: POST /delete  (id + antrepoId)
    r = await _dio.post('/api/YerlesimYeri/delete',
        data: {'id': id, 'antrepoId': antrepoId});
    if (ok(r)) return true;
    if (await verifyGone()) return true;

    // V3: DELETE ?id=&antrepoId=
    r = await _dio.delete('/api/YerlesimYeri',
        queryParameters: {'id': id, 'antrepoId': antrepoId});
    if (ok(r)) return true;
    if (await verifyGone()) return true;

    // logla
    // ignore: avoid_print
    print('[DELETE-ERR] id=$id code=${r.statusCode} body=${r.data}');
    return false;
  }
}
