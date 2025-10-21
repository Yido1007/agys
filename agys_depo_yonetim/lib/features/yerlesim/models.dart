class YerlesimYeri {
  final int id;
  final int? ustYerlesimId;
  final int antrepoId;
  final String kod;
  final int? sira;
  final String? tip;
  final String? aciklama;
  final bool? aktif;

  YerlesimYeri({
    required this.id,
    required this.antrepoId,
    required this.kod,
    this.ustYerlesimId,
    this.sira,
    this.tip,
    this.aciklama,
    this.aktif,
  });

  factory YerlesimYeri.fromJson(Map<String, dynamic> j) => YerlesimYeri(
        id: j['id'] as int,
        ustYerlesimId: j['ustYerlesimId'] as int?,
        antrepoId: j['antrepoId'] as int? ?? j['antrepoID'] as int? ?? 0,
        kod: j['kod']?.toString() ?? '',
        sira: j['sira'] as int?,
        tip: j['tip']?.toString(),
        aciklama: j['aciklama']?.toString(),
        aktif: j['aktif'] as bool?,
      );

  Map<String, dynamic> toCreateJson() => {
        'antrepoId': antrepoId,
        'ustYerlesimId': ustYerlesimId,
        'kod': kod,
        'sira': sira ?? 0,
        'tip': tip,
        'aciklama': aciklama,
        'aktif': aktif ?? true,
      };

  Map<String, dynamic> toUpdateJson() => {
        'id': id,
        'ustYerlesimId': ustYerlesimId,
        'kod': kod,
        'sira': sira,
        'tip': tip,
        'aciklama': aciklama,
        'aktif': aktif,
      };
}
