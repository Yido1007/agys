import 'package:flutter/material.dart';
import 'yerlesim_service.dart';
import 'models.dart';

class YerlesimMapPage extends StatefulWidget {
  const YerlesimMapPage({super.key});

  @override
  State<YerlesimMapPage> createState() => _YerlesimMapPageState();
}

class _YerlesimMapPageState extends State<YerlesimMapPage> {
  final _svc = YerlesimService();
  final _antrepoIdCtrl = TextEditingController(text: '3');
  bool _loading = false;
  String? _error;
  List<YerlesimYeri> _items = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yerleştirme'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _antrepoIdCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Antrepo ID',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                    onPressed: _loading ? null : _load,
                    child: const Text('Yükle')),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _openCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Yerleşim'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('Kayıt yok'))
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final y = _items[i];
                        return ListTile(
                          title: Text(y.kod),
                          subtitle: Text(
                              'id=${y.id} • tip=${y.tip ?? '-'} • sıra=${y.sira ?? 0}'),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _openEditDialog(y),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(y),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = int.tryParse(_antrepoIdCtrl.text) ?? 1;
      final list = await _svc.getAntrepoYerlesimler(id);
      setState(() {
        _items = list;
      });
    } catch (e) {
      setState(() {
        _error = 'Yükleme hatası: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _delete(YerlesimYeri y) async {
    try {
      await _svc.delete(y.id);
      _load();
    } catch (e) {
      setState(() {
        _error = 'Silme hatası: $e';
      });
    }
  }

  Future<void> _openCreateDialog() async {
    final created = await showDialog<YerlesimYeri>(
      context: context,
      builder: (_) =>
          _YerlesimDialog(antrepoId: int.tryParse(_antrepoIdCtrl.text) ?? 1),
    );
    if (created != null) {
      try {
        await _svc.create(created);
        _load();
      } catch (e) {
        setState(() {
          _error = 'Oluşturma hatası: $e';
        });
      }
    }
  }

  Future<void> _openEditDialog(YerlesimYeri y) async {
    final updated = await showDialog<YerlesimYeri>(
      context: context,
      builder: (_) => _YerlesimDialog(editing: y, antrepoId: y.antrepoId),
    );
    if (updated != null) {
      try {
        await _svc.update(updated);
        _load();
      } catch (e) {
        setState(() {
          _error = 'Güncelleme hatası: $e';
        });
      }
    }
  }
}

class _YerlesimDialog extends StatefulWidget {
  final int antrepoId;
  final YerlesimYeri? editing;
  const _YerlesimDialog({required this.antrepoId, this.editing});

  @override
  State<_YerlesimDialog> createState() => _YerlesimDialogState();
}

class _YerlesimDialogState extends State<_YerlesimDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kodCtrl;
  late final TextEditingController _siraCtrl;
  late final TextEditingController _tipCtrl;
  late final TextEditingController _aciklamaCtrl;
  bool _aktif = true;

  @override
  void initState() {
    super.initState();
    _kodCtrl = TextEditingController(text: widget.editing?.kod ?? '');
    _siraCtrl =
        TextEditingController(text: (widget.editing?.sira ?? 0).toString());
    _tipCtrl = TextEditingController(text: widget.editing?.tip ?? '');
    _aciklamaCtrl = TextEditingController(text: widget.editing?.aciklama ?? '');
    _aktif = widget.editing?.aktif ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.editing == null ? 'Yeni Yerleşim' : 'Yerleşim Düzenle'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _kodCtrl,
                decoration: const InputDecoration(labelText: 'Kod'),
                validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
              ),
              TextFormField(
                controller: _siraCtrl,
                decoration: const InputDecoration(labelText: 'Sıra'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _tipCtrl,
                decoration: const InputDecoration(labelText: 'Tip'),
              ),
              TextFormField(
                controller: _aciklamaCtrl,
                decoration: const InputDecoration(labelText: 'Açıklama'),
              ),
              Row(
                children: [
                  const Text('Aktif'),
                  Switch(
                      value: _aktif,
                      onChanged: (v) => setState(() => _aktif = v)),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            if (widget.editing == null) {
              final y = YerlesimYeri(
                id: 0,
                antrepoId: widget.antrepoId,
                kod: _kodCtrl.text.trim(),
                sira: int.tryParse(_siraCtrl.text),
                tip: _tipCtrl.text.trim().isEmpty ? null : _tipCtrl.text.trim(),
                aciklama: _aciklamaCtrl.text.trim().isEmpty
                    ? null
                    : _aciklamaCtrl.text.trim(),
                aktif: _aktif,
              );
              Navigator.pop(context, y);
            } else {
              final y = YerlesimYeri(
                id: widget.editing!.id,
                antrepoId: widget.antrepoId,
                kod: _kodCtrl.text.trim(),
                sira: int.tryParse(_siraCtrl.text),
                tip: _tipCtrl.text.trim().isEmpty ? null : _tipCtrl.text.trim(),
                aciklama: _aciklamaCtrl.text.trim().isEmpty
                    ? null
                    : _aciklamaCtrl.text.trim(),
                aktif: _aktif,
                ustYerlesimId: widget.editing!.ustYerlesimId,
              );
              Navigator.pop(context, y);
            }
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
