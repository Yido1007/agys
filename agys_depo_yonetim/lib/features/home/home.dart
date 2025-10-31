import 'dart:convert';

import 'package:antrepo_client/core/api_service.dart';
import 'package:antrepo_client/features/home/models.dart';
import 'package:antrepo_client/features/home/stok_tutarlilik_service.dart';
import 'package:flutter/material.dart';

class HomeTab extends StatefulWidget {
  const HomeTab();

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Future<void> _araBeyan(String no) async {
    final id = _antrepoId;
    final beyan = no.trim().toUpperCase();
    if (id == null || beyan.isEmpty) return;

    setState(() {
      _searching = true;
      _err = null;
      _rows = const [];
    });
    try {
      final data = await _stokSvc.beyanname(id, beyan);
      setState(() => _rows = data);
    } catch (e) {
      setState(() => _err = 'Yükleme hatası');
    } finally {
      setState(() => _searching = false);
    }
  }

  bool _showingKalem = false;
  void _openBeyanname(String beyannameNo) {
    _araBeyan(beyannameNo); // Doğrudan içeri gir
  }

  void _backToBeyannameList() {
    setState(() {
      _rows = const []; // kalem listeyi temizle
      _showingKalem = false; // tile görünümüne dön
      _err = null;
    });
  }

  List<BeyannameOzet> _beyannameList = const [];
  bool _loadingBeyannameList = false;
  late final StokTutarlilikService _stokSvc;

  int? _antrepoId; // benimantrepom’dan gelir
  final _beyanCtl = TextEditingController();

  bool _loadingAntrepo = true;
  bool _searching = false;
  String? _err;

  List<StokTutarlilikDTO> _rows = const [];
  StokTutarlilikDetayDTO? _detay;

  @override
  void initState() {
    super.initState();
    _stokSvc = StokTutarlilikService(ApiService.instance.dio);
    _loadAntrepo(); // varsayılan antrepo çek
  }

  @override
  void dispose() {
    _beyanCtl.dispose();
    super.dispose();
  }

  List<BeyannameOzet> _dedupBeyanname(List<BeyannameOzet> items) {
    final seen = <String>{};
    final out = <BeyannameOzet>[];
    for (final x in items) {
      if (x.beyannameNo.isEmpty) continue;
      if (seen.add(x.beyannameNo)) out.add(x);
    }
    return out;
  }

  Future<void> _loadAntrepo() async {
    try {
      final (id, _) = await _stokSvc.benimAntrepom();
      setState(() {
        _antrepoId = id;
        _loadingAntrepo = false;
      });
      if (id != null) {
        _loadBeyannameList(id);
      }
    } catch (e) {
      setState(() {
        _err = 'Antrepo bilgisi alınamadı';
        _loadingAntrepo = false;
      });
    }
  }

  Future<void> _loadBeyannameList(int id) async {
    setState(() => _loadingBeyannameList = true);
    try {
      final raw = await _stokSvc.listByAntrepo(id); // List<BeyannameOzet>
      final uniq = _dedupBeyanname(raw);
      setState(() => _beyannameList = uniq);
    } catch (_) {
      // sessiz geç
    } finally {
      setState(() => _loadingBeyannameList = false);
    }
  }

  Future<void> _ara() async {
    final id = _antrepoId;
    final no = _beyanCtl.text.trim();
    if (id == null) {
      setState(() => _err = 'Antrepo seçili değil');
      return;
    }
    if (no.isEmpty) {
      setState(() => _err = 'Beyanname no girin');
      return;
    }
    setState(() {
      _searching = true;
      _err = null;
      _rows = const [];
    });
    try {
      final data = await _stokSvc.beyanname(id, no);
      setState(() => _rows = data);
      _showingKalem = true;
    } catch (e) {
      setState(() => _err = 'Yükleme hatası');
    } finally {
      setState(() => _searching = false);
    }
  }

  Future<void> _openDetay(int girisBaslikId, int girisDetayId) async {
    setState(() => _detay = null);
    final d = await _stokSvc.detay(girisBaslikId, girisDetayId);
    if (!mounted) return;
    setState(() => _detay = d);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BeyanDetaySheet(model: _detay),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: _rows.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _rows = const []; // kalem listesini temizle
                      _err = null;
                    });
                  },
                )
              : null,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Beyanname',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (_loadingAntrepo)
                    const LinearProgressIndicator()
                  else
                    Row(
                      children: [
                        // AntrepoId gösterimi (değiştirilebilir)
                        SizedBox(
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: null,
                            icon:
                                const Icon(Icons.warehouse_outlined, size: 18),
                            label: Text(_antrepoId == null
                                ? 'Antrepo yok'
                                : 'Antrepo: ${_antrepoId}'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _beyanCtl,
                            decoration: const InputDecoration(
                              labelText: 'Beyanname No',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _ara(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: _searching ? null : _ara,
                            icon: const Icon(Icons.search),
                            label: const Text('Ara'),
                          ),
                        ),
                      ],
                    ),
                  if (_searching)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(),
                    ),
                  if (_err != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_err!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _rows.isNotEmpty
                  ? ListView.separated(
                      itemCount: _rows.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final m = _rows[i];
                        final kalem = m.kalemNo.toString();
                        final stok =
                            m.urunStokNo ?? m.ticariTanim ?? m.gtip ?? '-';
                        final miktarIn = m.girenMiktar?.toStringAsFixed(2);
                        final miktarOut = m.cikanMiktar?.toStringAsFixed(2);

                        return ListTile(
                          leading: CircleAvatar(child: Text(kalem)),
                          title: Text(stok,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text([
                            if (miktarIn != null) 'Giriş: $miktarIn',
                            if (miktarOut != null) 'Çıkış: $miktarOut',
                          ].join(' • ')),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              _openDetay(m.girisBaslikId, m.girisDetayId),
                        );
                      },
                    )
                  : (_loadingAntrepo || _loadingBeyannameList)
                      ? const Center(child: CircularProgressIndicator())
                      : (_beyannameList.isEmpty
                          ? const Center(child: Text('Kayıt yok'))
                          : ListView.separated(
                              itemCount: _beyannameList.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final b = _beyannameList[i];
                                final subtitle = [
                                  if (b.tarihText != null)
                                    'Tarih: ${b.tarihText}',
                                  if (b.kalemSayisi != null)
                                    'Kalem: ${b.kalemSayisi}',
                                  if (b.durum != null) 'Durum: ${b.durum}',
                                ].join(' • ');

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  leading:
                                      const Icon(Icons.description_outlined),
                                  title: Text(b.beyannameNo,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle:
                                      subtitle.isEmpty ? null : Text(subtitle),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _openBeyanname(b.beyannameNo),
                                );
                              },
                            )),
            )
          ],
        ));
  }
}

class _BeyanDetaySheet extends StatelessWidget {
  final StokTutarlilikDetayDTO? model;
  const _BeyanDetaySheet({required this.model});

  @override
  Widget build(BuildContext context) {
    if (model == null) {
      return const SafeArea(
          child: SizedBox(
              height: 240, child: Center(child: CircularProgressIndicator())));
    }
    final m = model!;
    final pretty = const JsonEncoder.withIndent('  ').convert({
      'beyannameNo': m.beyannameNo,
      'kalemNo': m.kalemNo,
      'ticariTanim': m.ticariTanim,
      'gtip': m.gtip,
      'birimAdi': m.birimAdi,
      'girenMiktar': m.girenMiktar,
      'cikanMiktar': m.cikanMiktar,
      'devamEdenGiris': m.devamEdenGiris,
      'devamEdenCikis': m.devamEdenCikis,
      'devamEdenIslemlerDahil': m.devamEdenIslemlerDahil,
      'cikisHareketleri': m.cikisHareketleri
          .map((e) => {
                'cikisBeyannameNo': e.cikisBeyannameNo,
                'cikisKalemNo': e.cikisKalemNo,
                'cikanMiktar': e.cikanMiktar,
                'cikisTarihi': e.cikisTarihi?.toIso8601String(),
                'onaylandi': e.onaylandi,
              })
          .toList(),
      'devamEdenIslemler': m.devamEdenIslemler
          .map((e) => {
                'islemTuru': e.islemTuru,
                'beyannameNo': e.beyannameNo,
                'kalemNo': e.kalemNo,
                'miktar': e.miktar,
                'islemTarihi': e.islemTarihi?.toIso8601String(),
                'tutanakNo': e.tutanakNo,
              })
          .toList(),
    });

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Scaffold(
          appBar: AppBar(title: const Text('Kalem Detayı')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(pretty),
          ),
        ),
      ),
    );
  }
}

class BeyannameTile extends StatelessWidget {
  final String beyannameNo;
  final String? tarihText; // örn: "2025-10-31 13:45"
  final int? kalemSayisi; // örn: 12
  final String? durum; // örn: "Açık" / "Kapalı"
  final VoidCallback? onTap;

  const BeyannameTile({
    super.key,
    required this.beyannameNo,
    this.tarihText,
    this.kalemSayisi,
    this.durum,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sub = <String>[
      if (tarihText != null && tarihText!.isNotEmpty) 'Tarih: $tarihText',
      if (kalemSayisi != null) 'Kalem: $kalemSayisi',
      if (durum != null && durum!.isNotEmpty) 'Durum: $durum',
    ].join(' • ');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: const Icon(Icons.description_outlined),
      title: Text(
        beyannameNo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: sub.isEmpty ? null : Text(sub),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
