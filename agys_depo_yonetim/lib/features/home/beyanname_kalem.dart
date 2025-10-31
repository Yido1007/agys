import 'package:antrepo_client/core/api_service.dart';
import 'package:antrepo_client/features/home/home.dart';
import 'package:antrepo_client/features/home/stok_tutarlilik_service.dart';
import 'package:antrepo_client/features/home/models.dart';
import 'package:flutter/material.dart';

class BeyannameKalemPage extends StatefulWidget {
  final int antrepoId;
  final String beyannameNo;
  const BeyannameKalemPage(
      {super.key, required this.antrepoId, required this.beyannameNo});

  @override
  State<BeyannameKalemPage> createState() => _BeyannameKalemPageState();
}

class _BeyannameKalemPageState extends State<BeyannameKalemPage> {
  late final StokTutarlilikService _svc;
  bool _loading = true;
  String? _err;
  List<StokTutarlilikDTO> _rows = const [];

  @override
  void initState() {
    super.initState();
    _svc = StokTutarlilikService(ApiService.instance.dio);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
      _rows = const [];
    });
    try {
      final data = await _svc.beyanname(
          widget.antrepoId, widget.beyannameNo.trim().toUpperCase());
      setState(() => _rows = data);
    } catch (e) {
      setState(() => _err = 'Kalemler yüklenemedi');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openDetay(int gb, int gd) async {
    final d = await _svc.detay(gb, gd);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BeyanDetaySheet(model: d),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
        'Beyanname: ${widget.beyannameNo}',
        style: TextStyle(fontSize: 15),
      )),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _err != null
              ? Center(child: Text(_err!))
              : _rows.isEmpty
                  ? const Center(child: Text('Kayıt yok'))
                  : ListView.separated(
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
                    ),
    );
  }
}
