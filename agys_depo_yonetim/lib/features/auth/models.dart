class KullaniciGirisDTO {
  final String eposta;
  final String sifre;
  final String antrepoKodu;

  KullaniciGirisDTO({
    required this.eposta,
    required this.sifre,
    required this.antrepoKodu,
  });

  Map<String, dynamic> toJson() => {
        'eposta': eposta,
        'sifre': sifre,
        'antrepoKodu': antrepoKodu,
      };
}
