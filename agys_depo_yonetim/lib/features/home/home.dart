import 'package:antrepo_client/core/api_service.dart';
import 'package:antrepo_client/features/home/beyanname_kalem.dart';
import 'package:antrepo_client/features/home/models.dart';
import 'package:antrepo_client/features/home/stok_tutarlilik_service.dart';
import 'package:flutter/material.dart';

class HomeTab extends StatefulWidget {
  const HomeTab();

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  void _openBeyanname(String beyannameNo) {
    final id = _antrepoId;
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BeyannameKalemPage(
          antrepoId: id,
          beyannameNo: beyannameNo,
        ),
      ),
    );
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
      builder: (_) => BeyanDetaySheet(model: _detay),
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

class BeyanDetaySheet extends StatelessWidget {
  final StokTutarlilikDetayDTO? model;
  const BeyanDetaySheet({required this.model});

  String _n(num? v, {int frac = 2}) =>
      v == null ? '-' : v.toStringAsFixed(frac);

  @override
  Widget build(BuildContext context) {
    if (model == null) {
      return const SafeArea(
        child: SizedBox(
            height: 240, child: Center(child: CircularProgressIndicator())),
      );
    }
    final m = model!;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Scaffold(
          appBar: AppBar(title: const Text('Kalem Detayı')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // === ÜST BİLGİLER ===
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EFFA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description_outlined,
                          color: Color(0xFF0B60D0)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (m.ticariTanim ?? '—'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                              'Beyanname: ${m.beyannameNo} • Kalem: ${m.kalemNo}',
                              style: const TextStyle(color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // === TEMEL ALANLAR ===
                _InfoRow(label: 'GTIP', value: m.gtip),
                _InfoRow(label: 'Birim', value: m.birimAdi),

                const SizedBox(height: 12),

                // === MİKTAR KARTLARI ===
                Row(
                  children: [
                    Expanded(
                        child: _StatCard(
                            title: 'Giren', value: _n(m.girenMiktar))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _StatCard(
                            title: 'Çıkan', value: _n(m.cikanMiktar))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _StatCard(
                            title: 'Devam Eden Giriş',
                            value: _n(m.devamEdenGiris))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _StatCard(
                            title: 'Devam Eden Çıkış',
                            value: _n(m.devamEdenCikis))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _StatCard(
                            title: 'İşlemler Dahil',
                            value: _n(m.devamEdenIslemlerDahil))),
                    const SizedBox(width: 8),
                    const Expanded(child: SizedBox()), // grid dengeleme
                  ],
                ),

                const SizedBox(height: 16),

                // === ÇIKIŞ HAREKETLERİ ===
                const _SectionTitle('Çıkış Hareketleri'),
                if (m.cikisHareketleri.isEmpty)
                  const _EmptyHint('Kayıt yok')
                else
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: m.cikisHareketleri.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final e = m.cikisHareketleri[i];
                        final sub = <String>[
                          if (e.cikanMiktar != null)
                            'Miktar: ${_n(e.cikanMiktar)}',
                          if (e.cikisTarihi != null)
                            'Tarih: ${e.cikisTarihi!.toLocal().toString().split('.').first}',
                          if (e.onaylandi != null)
                            'Onay: ${e.onaylandi! ? 'Evet' : 'Hayır'}',
                        ].join(' • ');
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.call_made,
                              color: Color(0xFFEF4444)),
                          title: Text(
                            '${e.cikisBeyannameNo ?? '—'}'
                            '${e.cikisKalemNo != null ? ' / ${e.cikisKalemNo}' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: sub.isEmpty ? null : Text(sub),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// === küçük yardımcılar (aynı dosyaya ekleyin) ===
class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  const _InfoRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
              width: 96,
              child: Text(label,
                  style: const TextStyle(color: Color(0xFF64748B)))),
          Expanded(child: Text(value!)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)));
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 18, color: Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Flexible(
                child: Text(text,
                    style: const TextStyle(color: Color(0xFF94A3B8)))),
          ],
        ),
      );
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
