class YerlesimYeri {
  final int id;
  final int? ustYerlesimId;
  final int antrepoId;
  final String kod;
  final int? sira;
  final String? tip;
  final String? aciklama;
  final bool? aktif;
  final String? barkod;

  YerlesimYeri(
      {required this.id,
      required this.antrepoId,
      required this.kod,
      this.ustYerlesimId,
      this.sira,
      this.tip,
      this.aciklama,
      this.aktif,
      this.barkod});

  factory YerlesimYeri.fromJson(Map<String, dynamic> j) {
    int _i(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
    int? _in(dynamic v) =>
        v == null ? null : (v is int ? v : int.tryParse('$v'));
    String? _s(dynamic v) => v == null ? null : v.toString();
    bool? _b(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      final s = v.toString().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
      return null;
    }

    return YerlesimYeri(
      id: _i(j['id']), // null gelirse 0
      ustYerlesimId: _in(j['ustYerlesimId']),
      antrepoId: _i(j['antrepoId'] ?? j['antrepoID']), // null gelirse 0
      kod: _s(j['kod']) ?? '',
      sira: _in(j['sira']),
      tip: _s(j['tip']),
      aciklama: _s(j['aciklama']),
      aktif: _b(j['aktif']),
      barkod: j['barkod'] ?? j['Barkod'],
    );
  }

  Map<String, dynamic> toCreateJson() {
    final m = {
      'antrepoId': antrepoId, // zorunlu
      'ustYerlesimId': ustYerlesimId, // yoksa gönderme
      'kod': kod, // zorunlu
      'sira': sira, // int?
      'tip': tip?.substring(0, tip!.length > 50 ? 50 : tip!.length),
      'aciklama': aciklama?.substring(
          0, aciklama!.length > 500 ? 500 : aciklama!.length),
      'aktif': aktif, // bool
      'barkod': barkod ?? '',
    };
    m.removeWhere((k, v) => v == null);
    return m;
  }

  Map<String, dynamic> toUpdateJson() => _clean({
        'id': id,
        'ustYerlesimId': ustYerlesimId,
        'kod': kod,
        'sira': sira,
        'tip': _clip(tip, 50),
        'aciklama': _clip(aciklama, 500),
        'aktif': aktif,
        'barkod': barkod ?? '',
      });
}

Map<String, dynamic> _clean(Map<String, dynamic> m) {
  m.removeWhere((k, v) => v == null);
  return m;
}

String? _clip(String? s, int n) =>
    s == null ? null : (s.length <= n ? s : s.substring(0, n));
