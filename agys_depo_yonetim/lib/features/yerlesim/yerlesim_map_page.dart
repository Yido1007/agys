import 'package:flutter/material.dart';
import 'models.dart';
import 'yerlesim_service.dart';

class YerlesimMapPage extends StatefulWidget {
  const YerlesimMapPage({super.key});
  @override
  State<YerlesimMapPage> createState() => _YerlesimMapPageState();
}

class _YerlesimMapPageState extends State<YerlesimMapPage> {
  // class _YerlesimMapPageState içinde:
  List<YerlesimYeri> _all = []; // tüm liste
  List<YerlesimYeri> _view = []; // ekranda görünen altlar
  int? _currentParentId; // null = kök
  final List<YerlesimYeri> _path = []; // breadcrumb

  bool _isChildOf(YerlesimYeri c, int pid) =>
      c.id != c.ustYerlesimId && (c.ustYerlesimId ?? -1) == pid;

  bool _hasChildLocal(int id) => _items.any((e) => _isChildOf(e, id));

  final _svc = YerlesimService();
  final _antrepoIdCtrl =
      TextEditingController(text: '3'); // login'e göre güncelle
  bool _loading = false;
  String? _error;
  List<YerlesimYeri> _items = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yerleştirme'),
        leading: _currentParentId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _goToPathIndex(_path.length - 2),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _antrepoIdCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Antrepo ID'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _load,
                  child: const Text('Yükle'),
                ),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFFF7F9FC),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  InkWell(
                    onTap: _goRoot,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Text('Kök', style: TextStyle(color: Colors.blue)),
                    ),
                  ),
                  for (int i = 0; i < _path.length; i++) ...[
                    const Text(' / ', style: TextStyle(color: Colors.black54)),
                    InkWell(
                      onTap: () => _goToPathIndex(i),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(_path[i].kod,
                            style: const TextStyle(color: Colors.blue)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _view.isEmpty
                  ? const Center(child: Text('Kayıt yok'))
                  : ListView.separated(
                      itemCount: _view.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final y = _view[i];
                        final hasChild = _hasChild(y.id);
                        return ListTile(
                          onTap: () => _open(y), // ← içeri gir
                          title: Text(y.kod),
                          subtitle: Text(
                              'id=${y.id} • üst=${y.ustYerlesimId ?? '-'} • tip=${y.tip ?? '-'}'),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              // Altlarıyla sil butonun varsa bırak
                              // ...
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip:
                                    hasChild ? 'Önce altları silin' : 'Sil',
                                onPressed: hasChild ? null : () => _delete(y),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _openEditDialog(y),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }

  void _applyFilter() {
    final parentKey = _currentParentId ?? -1;
    _view = _all.where((e) => (e.ustYerlesimId ?? -1) == parentKey).toList();
    setState(() {});
  }

  void _open(YerlesimYeri y) {
    _currentParentId = y.id;
    _path.add(y);
    _applyFilter();
  }

  void _goRoot() {
    _currentParentId = null;
    _path.clear();
    _applyFilter();
  }

  void _goToPathIndex(int i) {
    _currentParentId = i >= 0 ? _path[i].id : null;
    if (i >= 0) {
      _path.removeRange(i + 1, _path.length);
    } else {
      _path.clear();
    }
    _applyFilter();
  }

  bool _hasChild(int id) => _all.any((e) => _isChildOf(e, id));

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = int.tryParse(_antrepoIdCtrl.text) ?? 3;
      _all = await _svc.getAntrepoYerlesimler(id);
      _applyFilter(); // <- hiyerarşiye göre görünümü kur
    } catch (e) {
      setState(() => _error = 'Yükleme hatası: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(YerlesimYeri y) async {
    final ok = await _svc.delete(y.id, antrepoId: y.antrepoId);
    if (!ok) {
      setState(() => _error = 'Silinemedi (id=${y.id})');
      return;
    }
    await _load();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Silindi')));
  }

  Future<void> _deleteCascade(YerlesimYeri root) async {
    setState(() => _error = null);

    // self-parent düzelt
    if (root.ustYerlesimId == root.id) {
      await _svc.update(YerlesimYeri(
        id: root.id,
        ustYerlesimId: null,
        antrepoId: root.antrepoId,
        kod: root.kod,
        sira: root.sira,
        tip: root.tip,
        aciklama: root.aciklama,
        aktif: root.aktif,
      ));
    }

    await _load();
    bool isChildOf(YerlesimYeri c, int pid) =>
        c.id != c.ustYerlesimId && (c.ustYerlesimId ?? -1) == pid;
    bool hasChildLocal(int id) => _items.any((e) => isChildOf(e, id));

    // çocuk yoksa tek sil
    if (!hasChildLocal(root.id)) {
      await _delete(root);
      return;
    }

    // ebeveyn->çocuklar
    final byParent = <int, List<YerlesimYeri>>{};
    for (final e in _items) {
      if (e.id == e.ustYerlesimId) continue;
      (byParent[e.ustYerlesimId ?? -1] ??= []).add(e);
    }

    // post-order
    final order = <YerlesimYeri>[];
    void dfs(int id) {
      for (final c in byParent[id] ?? const <YerlesimYeri>[]) {
        dfs(c.id);
        order.add(c);
      }
    }

    dfs(root.id);
    order.add(root);

    // tek tek ve doğrulamalı sil
    for (final n in order) {
      final ok = await _svc.delete(n.id, antrepoId: n.antrepoId);
      if (!ok) {
        setState(() => _error = 'Silinemedi (id=${n.id})');
        return;
      }
    }

    await _load();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kademeli silme tamamlandı')),
    );
  }

  Future<void> _openCreateDialog() async {
    final antrepoId = int.tryParse(_antrepoIdCtrl.text) ?? 3;
    final created = await showDialog<YerlesimYeri>(
      context: context,
      builder: (_) => _YerlesimDialog(
        antrepoId: antrepoId,
        parentId: _currentParentId, // ← aktif ebeveyn
      ),
    );
    if (created != null) {
      try {
        await _svc.create(created);
        await _load(); // görünüm zaten _currentParentId ile filtreli
      } catch (e) {
        setState(() => _error = 'Oluşturma hatası: $e');
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
        await _load();
      } catch (e) {
        setState(() => _error = 'Güncelleme hatası: $e');
      }
    }
  }
}

class _YerlesimDialog extends StatefulWidget {
  final int antrepoId;
  final int? parentId;
  final YerlesimYeri? editing;
  const _YerlesimDialog({required this.antrepoId, this.editing, this.parentId});

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
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.parentId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Üst ID: ${widget.parentId}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              TextFormField(
                controller: _kodCtrl,
                decoration: const InputDecoration(labelText: 'Kod'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Gerekli' : null,
              ),
              TextFormField(
                controller: _siraCtrl,
                decoration: const InputDecoration(labelText: 'Sıra'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _tipCtrl,
                decoration: const InputDecoration(labelText: 'Tip'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Gerekli' : null,
              ),
              TextFormField(
                controller: _aciklamaCtrl,
                decoration: const InputDecoration(labelText: 'Açıklama'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Gerekli' : null,
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
          child: const Text('Vazgeç'),
        ),
        ElevatedButton(
          onPressed: _onSubmit,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final siraVal = int.tryParse(_siraCtrl.text);
    final tipVal = _tipCtrl.text.trim();
    final aciklamaVal = _aciklamaCtrl.text.trim();

    if (widget.editing == null) {
      final y = YerlesimYeri(
        id: 0,
        antrepoId: widget.antrepoId,
        ustYerlesimId: widget.parentId, // ← ebeveyn burada set
        kod: _kodCtrl.text.trim(),
        sira: int.tryParse(_siraCtrl.text),
        tip: _tipCtrl.text.trim(),
        aciklama: _aciklamaCtrl.text.trim(),
        aktif: _aktif,
      );
      Navigator.pop(context, y);
    } else {
      final y = YerlesimYeri(
        id: widget.editing!.id,
        antrepoId: widget.antrepoId,
        kod: _kodCtrl.text.trim(),
        sira: siraVal,
        tip: tipVal,
        aciklama: aciklamaVal,
        aktif: _aktif,
        ustYerlesimId: widget.editing!.ustYerlesimId,
      );
      Navigator.pop(context, y);
    }
  }
}
