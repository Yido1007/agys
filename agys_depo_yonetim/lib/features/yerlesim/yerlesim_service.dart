import 'package:dio/dio.dart';
import '../../core/api_service.dart';
import 'models.dart';

class YerlesimService {
  final Dio _dio = ApiService.instance.dio;

  bool _ok(Response r) =>
      r.statusCode != null && r.statusCode! >= 200 && r.statusCode! < 300;

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
          .map((e) => YerlesimYeri.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    }
    return <YerlesimYeri>[];
  }

  Future<YerlesimYeri?> getById(int id) async {
    final r = await _dio.get('/api/YerlesimYeri/$id');
    if (_ok(r) && r.data != null) {
      return YerlesimYeri.fromJson((r.data as Map).cast<String, dynamic>());
    }
    return null;
  }

  Future<YerlesimYeri> create(YerlesimYeri y) async {
    Response r;

    // V1: POST gövde
    r = await _dio.post('/api/YerlesimYeri', data: {
      ...y.toCreateJson(),
      'barkod': (y.barkod ?? ''),
    });
    if (_ok(r))
      return YerlesimYeri.fromJson((r.data as Map).cast<String, dynamic>());

    // V2: POST /create
    r = await _dio.post('/api/YerlesimYeri/create', data: {
      ...y.toCreateJson(),
      'barkod': (y.barkod ?? ''),
    });
    if (_ok(r))
      return YerlesimYeri.fromJson((r.data as Map).cast<String, dynamic>());

    // V3: Alternatif query
    r = await _dio.post('/api/YerlesimYeri', queryParameters: {
      ...y.toCreateJson(),
      'barkod': (y.barkod ?? ''),
    });
    if (_ok(r))
      return YerlesimYeri.fromJson((r.data as Map).cast<String, dynamic>());

    throw DioException(
      requestOptions: r.requestOptions,
      response: r,
      error: 'Create failed status=${r.statusCode}',
      type: DioExceptionType.badResponse,
    );
  }

  Future<void> update(YerlesimYeri y) async {
    if (y.id <= 0) throw ArgumentError('id<=0');

    Response r;

    // V1: PUT gövde
    r = await _dio.put('/api/YerlesimYeri', data: {
      ...y.toUpdateJson(),
      'barkod': (y.barkod ?? ''),
    });
    if (_ok(r)) return;

    // V2: PUT path + gövde
    r = await _dio.put('/api/YerlesimYeri/${y.id}', data: {
      ...y.toUpdateJson(),
      'barkod': (y.barkod ?? ''),
    });
    if (_ok(r)) return;

    // V3: POST /update
    r = await _dio.post('/api/YerlesimYeri/update', data: {
      ...y.toUpdateJson(),
      'barkod': (y.barkod ?? ''),
    });
    if (_ok(r)) return;

    throw DioException(
      requestOptions: r.requestOptions,
      response: r,
      error: 'Update failed status=${r.statusCode}',
      type: DioExceptionType.badResponse,
    );
  }

  Future<bool> delete(int id, {int? antrepoId}) async {
    Response r;

    Future<bool> verifyGone() async {
      try {
        final g = await _dio.get('/api/YerlesimYeri/$id');
        return g.statusCode == 404 || g.data == null || g.data == false;
      } catch (_) {
        return true; // 404 vb. durumları "yok" say
      }
    }

    // V1: DELETE /{id} + body (bazı API'lar DELETE body kabul ediyor)
    try {
      r = await _dio.delete('/api/YerlesimYeri/$id', data: {'barkod': ''});
      if (_ok(r)) return true;
      if (await verifyGone()) return true;
    } catch (_) {}

    // V2: POST /delete
    try {
      r = await _dio.post('/api/YerlesimYeri/delete',
          data: {
            'id': id,
            'antrepoId': antrepoId,
            'barkod': '',
          }..removeWhere((k, v) => v == null));
      final ok = (r.data == true) ||
          (r.data is Map &&
              (((r.data as Map)['success'] == true) ||
                  ((r.data as Map)['data'] == true)));
      if (ok) return true;
      if (await verifyGone()) return true;
    } catch (_) {}

    // V3: DELETE ?id=&antrepoId=&barkod=
    try {
      r = await _dio.delete('/api/YerlesimYeri',
          queryParameters: {
            'id': id,
            'antrepoId': antrepoId,
            'barkod': '',
          }..removeWhere((k, v) => v == null));
      if (_ok(r)) return true;
      if (await verifyGone()) return true;
    } catch (_) {}

    // log
    // ignore: avoid_print
    print('[DELETE-ERR] id=$id antrepoId=$antrepoId');
    return false;
  }

  Future<List<YerlesimYeri>> createMany(List<YerlesimYeri> items) async {
    final payloads = items
        .map((e) => {
              ...e.toCreateJson(),
              'barkod': (e.barkod ?? ''),
            })
        .toList();

    Response r;

    // V1
    r = await _dio.post('/api/YerlesimYeri/bulk', data: payloads);
    if (_ok(r)) {
      final d = r.data;
      final list = d is List
          ? d
          : (d['items'] ?? d['data'] ?? d['result'] ?? []) as List;
      return list
          .map((e) => YerlesimYeri.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    }

    // V2
    r = await _dio.post('/api/YerlesimYeri/createMany', data: payloads);
    if (_ok(r)) {
      final d = r.data;
      final list = d is List
          ? d
          : (d['items'] ?? d['data'] ?? d['result'] ?? []) as List;
      return list
          .map((e) => YerlesimYeri.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    }

    throw DioException(
      requestOptions: r.requestOptions,
      response: r,
      error: 'Bulk create failed status=${r.statusCode}',
      type: DioExceptionType.badResponse,
    );
  }

  Future<int> deleteMany(List<int> ids, {int? antrepoId}) async {
    Response r;

    // V1: POST /bulkDelete
    r = await _dio.post('/api/YerlesimYeri/bulkDelete',
        data: {
          'ids': ids,
          'antrepoId': antrepoId,
          'barkod': '',
        }..removeWhere((k, v) => v == null));
    if (_ok(r)) {
      if (r.data is int) return r.data as int;
      if (r.data is Map && (r.data['deleted'] is int))
        return r.data['deleted'] as int;
      if (r.data is List) return (r.data as List).length;
      return ids.length; // başarı say
    }

    // V2: DELETE ?ids=&antrepoId=&barkod=
    r = await _dio.delete('/api/YerlesimYeri',
        queryParameters: {
          'ids': ids,
          'antrepoId': antrepoId,
          'barkod': '',
        }..removeWhere((k, v) => v == null));
    if (_ok(r)) {
      if (r.data is int) return r.data as int;
      if (r.data is Map && (r.data['deleted'] is int))
        return r.data['deleted'] as int;
      if (r.data is List) return (r.data as List).length;
      return ids.length;
    }

    throw DioException(
      requestOptions: r.requestOptions,
      response: r,
      error: 'Bulk delete failed status=${r.statusCode}',
      type: DioExceptionType.badResponse,
    );
  }

  // Şimdilik kullanmıyoruz; uç hazır dursun.
  Future<YerlesimYeri?> getByKod(String kod) async {
    try {
      final res = await _dio
          .get('/api/YerlesimYeri/by-kod', queryParameters: {'kod': kod});
      if (res.statusCode == 200 && res.data != null) {
        return YerlesimYeri.fromJson(res.data);
      }
    } catch (_) {}
    return null;
  }
}
