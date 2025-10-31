class ApiEnvelope<T> {
  final bool success;
  final T? data;
  final int? count;
  final String? message;
  final int? antrepoId; // sadece "benimantrepom" için gelebilir

  ApiEnvelope(
      {required this.success,
      this.data,
      this.count,
      this.message,
      this.antrepoId});

  static ApiEnvelope<R> fromJson<R>(
    Map<String, dynamic> j,
    R Function(Object? v) dataParser,
  ) {
    return ApiEnvelope<R>(
      success: j['success'] == true,
      data: dataParser(j['data']),
      count: j['count'] is int ? j['count'] as int : null,
      message: j['message'] as String?,
      antrepoId: j['antrepoId'] as int?,
    );
  }
}

// === DTO'lar ===

// 4.1 StokTutarlilikDTO  (alanlar: GirisBaslikId, GirisDetayId, BeyannameNo, KalemNo, UrunStokNo,
// TicariTanim, Gtip, BirimAdi, GirenMiktar, CikanMiktar, Ek83DefterKaydi, DevamEdenGiris,
// DevamEdenCikis, DevamEdenIslemlerDahil, DepoAlani, RafNo) :contentReference[oaicite:1]{index=1}
class StokTutarlilikDTO {
  final int girisBaslikId;
  final int girisDetayId;
  final String beyannameNo;
  final int kalemNo;
  final String? urunStokNo;
  final String? ticariTanim;
  final String? gtip;
  final String? birimAdi;
  final double? girenMiktar;
  final double? cikanMiktar;
  final double? ek83DefterKaydi;
  final double? devamEdenGiris;
  final double? devamEdenCikis;
  final double? devamEdenIslemlerDahil;
  final String? depoAlani;
  final String? rafNo;

  StokTutarlilikDTO({
    required this.girisBaslikId,
    required this.girisDetayId,
    required this.beyannameNo,
    required this.kalemNo,
    this.urunStokNo,
    this.ticariTanim,
    this.gtip,
    this.birimAdi,
    this.girenMiktar,
    this.cikanMiktar,
    this.ek83DefterKaydi,
    this.devamEdenGiris,
    this.devamEdenCikis,
    this.devamEdenIslemlerDahil,
    this.depoAlani,
    this.rafNo,
  });

  factory StokTutarlilikDTO.fromJson(Map<String, dynamic> j) =>
      StokTutarlilikDTO(
        girisBaslikId: j['girisBaslikId'] as int,
        girisDetayId: j['girisDetayId'] as int,
        beyannameNo: j['beyannameNo'] as String,
        kalemNo: j['kalemNo'] as int,
        urunStokNo: j['urunStokNo'] as String?,
        ticariTanim: j['ticariTanim'] as String?,
        gtip: j['gtip'] as String?,
        birimAdi: j['birimAdi'] as String?,
        girenMiktar: (j['girenMiktar'] as num?)?.toDouble(),
        cikanMiktar: (j['cikanMiktar'] as num?)?.toDouble(),
        ek83DefterKaydi: (j['ek83DefterKaydi'] as num?)?.toDouble(),
        devamEdenGiris: (j['devamEdenGiris'] as num?)?.toDouble(),
        devamEdenCikis: (j['devamEdenCikis'] as num?)?.toDouble(),
        devamEdenIslemlerDahil:
            (j['devamEdenIslemlerDahil'] as num?)?.toDouble(),
        depoAlani: j['depoAlani'] as String?,
        rafNo: j['rafNo'] as String?,
      );
}

// 4.2 StokTutarlilikKriterDTO (AntrepoId zorunlu; BeyannameNo, SadeceUyumsuzlar opsiyonel) :contentReference[oaicite:2]{index=2}
class StokTutarlilikKriterDTO {
  final int antrepoId;
  final String? beyannameNo;
  final bool? sadeceUyumsuzlar;

  StokTutarlilikKriterDTO(
      {required this.antrepoId, this.beyannameNo, this.sadeceUyumsuzlar});

  Map<String, dynamic> toJson() => {
        'antrepoId': antrepoId,
        if (beyannameNo?.isNotEmpty == true) 'beyannameNo': beyannameNo,
        if (sadeceUyumsuzlar != null) 'sadeceUyumsuzlar': sadeceUyumsuzlar,
      };
}

// 4.3 StokTutarlilikDetayDTO (üst alanlar + alt listeler) :contentReference[oaicite:5]{index=5}
class StokTutarlilikDetayDTO {
  final int girisBaslikId;
  final int girisDetayId;
  final String beyannameNo;
  final int kalemNo;
  final String? ticariTanim;
  final String? gtip;
  final String? birimAdi;
  final double? girenMiktar;
  final double? cikanMiktar;
  final double? ek83DefterKaydi;
  final double? devamEdenGiris;
  final double? devamEdenCikis;
  final double? devamEdenIslemlerDahil;
  final DateTime? girisTarihi;
  final String? gonderici;
  final String? aliciFirmaAdi;
  final String? urunStokNo;
  final List<CikisHareketDTO> cikisHareketleri;
  final List<DevamEdenIslemDTO> devamEdenIslemler;

  StokTutarlilikDetayDTO({
    required this.girisBaslikId,
    required this.girisDetayId,
    required this.beyannameNo,
    required this.kalemNo,
    this.ticariTanim,
    this.gtip,
    this.birimAdi,
    this.girenMiktar,
    this.cikanMiktar,
    this.ek83DefterKaydi,
    this.devamEdenGiris,
    this.devamEdenCikis,
    this.devamEdenIslemlerDahil,
    this.girisTarihi,
    this.gonderici,
    this.aliciFirmaAdi,
    this.urunStokNo,
    this.cikisHareketleri = const [],
    this.devamEdenIslemler = const [],
  });

  factory StokTutarlilikDetayDTO.fromJson(Map<String, dynamic> j) =>
      StokTutarlilikDetayDTO(
        girisBaslikId: j['girisBaslikId'] as int,
        girisDetayId: j['girisDetayId'] as int,
        beyannameNo: j['beyannameNo'] as String,
        kalemNo: j['kalemNo'] as int,
        ticariTanim: j['ticariTanim'] as String?,
        gtip: j['gtip'] as String?,
        birimAdi: j['birimAdi'] as String?,
        girenMiktar: (j['girenMiktar'] as num?)?.toDouble(),
        cikanMiktar: (j['cikanMiktar'] as num?)?.toDouble(),
        ek83DefterKaydi: (j['ek83DefterKaydi'] as num?)?.toDouble(),
        devamEdenGiris: (j['devamEdenGiris'] as num?)?.toDouble(),
        devamEdenCikis: (j['devamEdenCikis'] as num?)?.toDouble(),
        devamEdenIslemlerDahil:
            (j['devamEdenIslemlerDahil'] as num?)?.toDouble(),
        girisTarihi: j['girisTarihi'] != null
            ? DateTime.parse(j['girisTarihi'] as String)
            : null,
        gonderici: j['gonderici'] as String?,
        aliciFirmaAdi: j['aliciFirmaAdi'] as String?,
        urunStokNo: j['urunStokNo'] as String?,
        cikisHareketleri: (j['cikisHareketleri'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => CikisHareketDTO.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        devamEdenIslemler: (j['devamEdenIslemler'] as List? ?? const [])
            .whereType<Map>()
            .map(
                (e) => DevamEdenIslemDTO.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

// 4.4 CikisHareketDTO :contentReference[oaicite:3]{index=3}
class CikisHareketDTO {
  final String? cikisBeyannameNo;
  final int? cikisKalemNo;
  final double? cikanMiktar;
  final DateTime? cikisTarihi;
  final bool? onaylandi;

  CikisHareketDTO({
    this.cikisBeyannameNo,
    this.cikisKalemNo,
    this.cikanMiktar,
    this.cikisTarihi,
    this.onaylandi,
  });

  factory CikisHareketDTO.fromJson(Map<String, dynamic> j) => CikisHareketDTO(
        cikisBeyannameNo: j['cikisBeyannameNo'] as String?,
        cikisKalemNo: j['cikisKalemNo'] as int?,
        cikanMiktar: (j['cikanMiktar'] as num?)?.toDouble(),
        cikisTarihi: j['cikisTarihi'] != null
            ? DateTime.parse(j['cikisTarihi'] as String)
            : null,
        onaylandi: j['onaylandi'] as bool?,
      );
}

// 4.5 DevamEdenIslemDTO :contentReference[oaicite:4]{index=4}
class DevamEdenIslemDTO {
  final String? islemTuru;
  final String? beyannameNo;
  final int? kalemNo;
  final double? miktar;
  final DateTime? islemTarihi;
  final String? tutanakNo;

  DevamEdenIslemDTO({
    this.islemTuru,
    this.beyannameNo,
    this.kalemNo,
    this.miktar,
    this.islemTarihi,
    this.tutanakNo,
  });

  factory DevamEdenIslemDTO.fromJson(Map<String, dynamic> j) =>
      DevamEdenIslemDTO(
        islemTuru: j['islemTuru'] as String?,
        beyannameNo: j['beyannameNo'] as String?,
        kalemNo: j['kalemNo'] as int?,
        miktar: (j['miktar'] as num?)?.toDouble(),
        islemTarihi: j['islemTarihi'] != null
            ? DateTime.parse(j['islemTarihi'] as String)
            : null,
        tutanakNo: j['tutanakNo'] as String?,
      );
}
