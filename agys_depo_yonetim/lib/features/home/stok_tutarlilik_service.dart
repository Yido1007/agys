// lib/features/stok_tutarlilik/stok_tutarlilik_service.dart
import 'package:dio/dio.dart';
import 'models.dart';

class StokTutarlilikService {
  final Dio _dio;
  StokTutarlilikService(this._dio);

  // 5.1 Antrepo listesi: GET /antrepo/{antrepoId} → StokTutarlilikDTO[]  :contentReference[oaicite:6]{index=6}
  Future<List<BeyannameOzet>> listByAntrepo(int antrepoId) async {
    final r = await _dio.get('/api/StokTutarlilik/antrepo/$antrepoId');
    final data = r.data;
    List list;
    if (data is List) {
      list = data;
    } else if (data is Map && (data['data'] is List)) {
      list = data['data'];
    } else {
      list = const [];
    }
    return list
        .whereType<Map>()
        .map((e) => BeyannameOzet.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // 5.2 Filtre: POST /filtrele  body: StokTutarlilikKriterDTO  → StokTutarlilikDTO[]  :contentReference[oaicite:7]{index=7}
  Future<List<StokTutarlilikDTO>> filtrele(
      StokTutarlilikKriterDTO kriter) async {
    final r =
        await _dio.post('/api/StokTutarlilik/filtrele', data: kriter.toJson());
    final env = ApiEnvelope.fromJson<List<StokTutarlilikDTO>>(
      _asMap(r.data),
      (v) => _mapList(v, (e) => StokTutarlilikDTO.fromJson(e)),
    );
    return env.data ?? const [];
  }

  // 5.3 Detay: GET /detay/{girisBaslikId}/{girisDetayId} → StokTutarlilikDetayDTO  :contentReference[oaicite:8]{index=8}
  Future<StokTutarlilikDetayDTO?> detay(
      int girisBaslikId, int girisDetayId) async {
    final r = await _dio
        .get('/api/StokTutarlilik/detay/$girisBaslikId/$girisDetayId');
    final env = ApiEnvelope.fromJson<StokTutarlilikDetayDTO?>(
      _asMap(r.data),
      (v) => v is Map
          ? StokTutarlilikDetayDTO.fromJson(Map<String, dynamic>.from(v))
          : null,
    );
    return env.data;
  }

  // 5.4 Uyumsuzlar: GET /uyumsuzlar/{antrepoId} → StokTutarlilikDTO[]  :contentReference[oaicite:9]{index=9}
  Future<List<StokTutarlilikDTO>> uyumsuzlar(int antrepoId) async {
    final r = await _dio.get('/api/StokTutarlilik/uyumsuzlar/$antrepoId');
    final env = ApiEnvelope.fromJson<List<StokTutarlilikDTO>>(
      _asMap(r.data),
      (v) => _mapList(v, (e) => StokTutarlilikDTO.fromJson(e)),
    );
    return env.data ?? const [];
  }

  // 5.5 Beyanname: GET /beyanname/{antrepoId}/{beyannameNo} → StokTutarlilikDTO[]  :contentReference[oaicite:10]{index=10}
  Future<List<StokTutarlilikDTO>> beyanname(
      int antrepoId, String beyannameNo) async {
    final enc = Uri.encodeComponent(beyannameNo.trim());
    final r = await _dio.get('/api/StokTutarlilik/beyanname/$antrepoId/$enc');
    final env = ApiEnvelope.fromJson<List<StokTutarlilikDTO>>(
      _asMap(r.data),
      (v) => _mapList(v, (e) => StokTutarlilikDTO.fromJson(e)),
    );
    return env.data ?? const [];
  }

  // 5.6 Benim Antrepom: GET /benimantrepom → {antrepoId, data[], count}  :contentReference[oaicite:11]{index=11}
  Future<(int? antrepoId, List<StokTutarlilikDTO> data)> benimAntrepom() async {
    final r = await _dio.get('/api/StokTutarlilik/benimantrepom');
    final m = _asMap(r.data);
    final id = m['antrepoId'] as int?;
    final list = _mapList(m['data'], (e) => StokTutarlilikDTO.fromJson(e));
    return (id, list);
  }

  // --- yardımcılar ---
  Map<String, dynamic> _asMap(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  List<T> _mapList<T>(Object? v, T Function(Map<String, dynamic>) parse) {
    if (v is List) {
      return v
          .whereType<Map>()
          .map((e) => parse(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }
}
