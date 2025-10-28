import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'models.dart';
import 'yerlesim_service.dart';

class YerlesimMapPage extends StatefulWidget {
  const YerlesimMapPage({super.key});
  @override
  State<YerlesimMapPage> createState() => _YerlesimMapPageState();
}

class _YerlesimMapPageState extends State<YerlesimMapPage> {
  void _openByKod(String kod) async {
    // Kodları string olarak karşılaştır
    final norm = kod.trim();

    // 1) Lokal arama
    YerlesimYeri? target;
    try {
      target = _all.firstWhere(
        (e) => (e.kod).trim() == norm,
      );
    } catch (_) {
      target = null;
    }

    // 2) Gerekirse sunucudan kod ile çek (opsiyonel: servisinizde “getByKod” varsa kullanın)
    target ??= await _svc.getByKod.call(norm);

    if (target == null) {
      setState(() => _error = 'Kayıt bulunamadı: $norm');
      return;
    }

    // 3) Hiyerarşik yolu kur ve “içine” gir
    final byId = {for (final e in _all) e.id: e};
    final path = <YerlesimYeri>[];
    YerlesimYeri? cur = target;
    while (cur?.ustYerlesimId != null && cur!.ustYerlesimId != cur.id) {
      final p = byId[cur.ustYerlesimId!];
      if (p == null) break;
      path.add(p);
      cur = p;
    }

    setState(() {
      _path
        ..clear()
        ..addAll(path.reversed)
        ..add(target!);
      _currentParentId = target.id; // içine gir
      _applyFilter();
    });
  }

  final _svc = YerlesimService();
  final _antrepoIdCtrl =
      TextEditingController(text: '3'); // login sonrası set edilebilir
  bool _loading = false;
  String? _error;

  // Hiyerarşi durumu
  List<YerlesimYeri> _all = []; // tüm kayıtlar
  List<YerlesimYeri> _view = []; // ekranda görünen altlar
  int? _currentParentId; // null = kök
  final List<YerlesimYeri> _path = []; // breadcrumb yolu

  // Seçim modu
  final Set<int> _selected = {};
  bool _selectionMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode ? 'Seçim modu' : 'Yerleştirme'),
        leading: _selectionMode
            ? IconButton(
                tooltip: 'Seçimi iptal et',
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : (_currentParentId != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => _goToPathIndex(_path.length - 2),
                  )
                : null),
        actions: [
          if (_selectionMode) ...[
            IconButton(
              tooltip: 'Seçilenleri sil',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _selected.isEmpty ? null : _deleteSelected,
            ),
          ] else ...[
            IconButton(
              tooltip: 'Toplu Ekle',
              icon: const Icon(Icons.playlist_add),
              onPressed: _openBulkCreateDialog,
            ),
            IconButton(
              tooltip: 'Yenile',
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _load,
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () async {
                final scanned = await showDialog<String>(
                  context: context,
                  barrierDismissible: true,
                  builder: (_) => const _QrScanDialog(),
                );
                if (scanned == null || scanned.trim().isEmpty) return;
                _openByKod(scanned.trim());
              },
            ),
          ],
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
                const Spacer(),
                if (!_selectionMode)
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
            const SizedBox(height: 12),

            // Breadcrumb
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFFF7F9FC),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  InkWell(
                    onTap: _selectionMode ? null : _goRoot,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Text('Kök', style: TextStyle(color: Colors.blue)),
                    ),
                  ),
                  for (int i = 0; i < _path.length; i++) ...[
                    const Text(' / ', style: TextStyle(color: Colors.black54)),
                    InkWell(
                      onTap: _selectionMode ? null : () => _goToPathIndex(i),
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

            // Liste
            Expanded(
              child: _view.isEmpty
                  ? const Center(child: Text('Kayıt yok'))
                  : ListView.separated(
                      itemCount: _view.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final y = _view[i];
                        final hasChild = _hasChildLocal(y.id);
                        final childCount = _childCount(y.id);
                        final selected = _selected.contains(y.id);

                        return ListTile(
                          onTap: () {
                            if (_selectionMode) {
                              _toggleSelected(y.id);
                            } else {
                              _open(y);
                            }
                          },
                          onLongPress: () {
                            if (!_selectionMode) {
                              _selectionMode = true;
                              _selected.clear();
                            }
                            _toggleSelected(y.id);
                          },
                          leading: _selectionMode
                              ? Checkbox(
                                  value: selected,
                                  onChanged: (_) => _toggleSelected(y.id),
                                )
                              : null,
                          title: Text(y.kod),
                          subtitle: Text('$childCount alt öğe'),
                          trailing: _selectionMode
                              ? null
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.chevron_right),
                                    const SizedBox(width: 4),
                                    PopupMenuButton<String>(
                                      onSelected: (v) async {
                                        if (v == 'add_before') {
                                          await _openRelativeCreate(y,
                                              before: true);
                                        } else if (v == 'add_after') {
                                          await _openRelativeCreate(y,
                                              before: false);
                                        } else if (v == 'edit') {
                                          await _openEditDialog(y);
                                        } else if (v == 'delete') {
                                          await _delete(y);
                                        } else if (v == 'cascade') {
                                          await _deleteCascade(y);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'add_before',
                                          child: ListTile(
                                            leading: Icon(
                                                Icons.arrow_upward_outlined),
                                            title: Text('Öncesine ekle'),
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'add_after',
                                          child: ListTile(
                                            leading: Icon(
                                                Icons.arrow_downward_outlined),
                                            title: Text('Sonrasına ekle'),
                                          ),
                                        ),
                                        const PopupMenuDivider(),
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: ListTile(
                                            leading: Icon(Icons.edit_outlined),
                                            title: Text('Düzenle'),
                                          ),
                                        ),
                                        if (!hasChild)
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: ListTile(
                                              leading:
                                                  Icon(Icons.delete_outline),
                                              title: Text('Sil'),
                                            ),
                                          ),
                                        if (hasChild)
                                          const PopupMenuItem(
                                            value: 'cascade',
                                            child: ListTile(
                                              leading: Icon(Icons
                                                  .cleaning_services_outlined),
                                              title: Text('Altlarıyla sil'),
                                            ),
                                          ),
                                      ],
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

  // ---------- Hiyerarşi yardımcıları ----------
  bool _isChildOf(YerlesimYeri c, int pid) =>
      c.id != c.ustYerlesimId && (c.ustYerlesimId ?? -1) == pid;

  bool _hasChildLocal(int id) => _all.any((e) => _isChildOf(e, id));

  int _childCount(int id) => _all.where((e) => _isChildOf(e, id)).length;

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

  // ---------- Seçim modu ----------
  void _toggleSelected(int id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
    setState(() {});
  }

  void _exitSelectionMode() {
    _selectionMode = false;
    _selected.clear();
    setState(() {});
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    int ok = 0, skipped = 0;
    for (final id in _selected.toList()) {
      final y = _all.firstWhere(
        (e) => e.id == id,
        orElse: () => YerlesimYeri(
            id: id, antrepoId: int.tryParse(_antrepoIdCtrl.text) ?? 3, kod: ''),
      );
      if (_hasChildLocal(y.id)) {
        skipped++;
        continue;
      }
      try {
        await _svc.delete(y.id, antrepoId: y.antrepoId);
        ok++;
      } catch (_) {
        skipped++;
      }
    }
    _exitSelectionMode();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Silinen: $ok • Atlanan: $skipped')),
    );
  }

  // ---------- Veri işlemleri ----------
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = int.tryParse(_antrepoIdCtrl.text) ?? 3;
      _all = await _svc.getAntrepoYerlesimler(id);
      _applyFilter();
    } catch (e) {
      setState(() {
        _error = 'Yükleme hatası: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _delete(YerlesimYeri y) async {
    try {
      await _svc.delete(y.id, antrepoId: y.antrepoId);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Silindi')));
    } catch (e) {
      setState(() => _error = 'Silme hatası: $e');
    }
  }

  // Kademeli sil (altlarıyla)
  Future<void> _deleteCascade(YerlesimYeri root) async {
    setState(() => _error = null);

    if (root.ustYerlesimId == root.id) {
      try {
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
      } catch (_) {}
    }

    await _load();
    bool hasChildLocal(int id) => _all.any((e) => _isChildOf(e, id));

    if (!hasChildLocal(root.id)) {
      await _delete(root);
      return;
    }

    final byParent = <int, List<YerlesimYeri>>{};
    for (final e in _all) {
      if (e.id == e.ustYerlesimId) continue;
      (byParent[e.ustYerlesimId ?? -1] ??= []).add(e);
    }

    final order = <YerlesimYeri>[];
    void dfs(int id) {
      for (final c in byParent[id] ?? const <YerlesimYeri>[]) {
        dfs(c.id);
        order.add(c);
      }
    }

    dfs(root.id);
    order.add(root);

    for (final n in order) {
      try {
        await _svc.delete(n.id, antrepoId: n.antrepoId);
      } catch (e) {
        setState(() => _error = 'Silme hatası (id=${n.id}): $e');
        return;
      }
    }

    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kademeli silme tamamlandı')));
  }

  Future<void> _openRelativeCreate(YerlesimYeri ref,
      {required bool before}) async {
    final antrepoId = int.tryParse(_antrepoIdCtrl.text) ?? 3;
    // Yeni öğe, referans ile aynı ebeveyn altında
    final created = await showDialog<YerlesimYeri>(
      context: context,
      builder: (_) => _YerlesimDialog(
        antrepoId: antrepoId,
        parentId: ref.ustYerlesimId,
      ),
    );
    if (created == null) return;

    // Sıra değerini referansa göre ayarla
    final baseSira = ref.sira ?? 0;
    final siraVal = before ? (baseSira - 1) : (baseSira + 1);

    final y = YerlesimYeri(
      id: 0,
      antrepoId: antrepoId,
      ustYerlesimId: ref.ustYerlesimId,
      kod: created.kod,
      sira: siraVal,
      tip: created.tip,
      aciklama: created.aciklama,
      aktif: created.aktif,
    );

    try {
      await _svc.create(y);
      await _load();
    } catch (e) {
      setState(() => _error = 'Oluşturma hatası: $e');
    }
  }

// ---------- Oluştur / Düzenle ----------
  Future<void> _openCreateDialog() async {
    final antrepoId = int.tryParse(_antrepoIdCtrl.text) ?? 3;
    final created = await showDialog<YerlesimYeri>(
      context: context,
      builder: (_) => _YerlesimDialog(
        antrepoId: antrepoId,
        parentId: _currentParentId, // aktif ebeveyn altında oluştur
      ),
    );
    if (created != null) {
      try {
        await _svc.create(created);
        await _load();
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

  // ---------- Toplu ekleme ----------
  Future<void> _openBulkCreateDialog() async {
    final res = await showDialog<_BulkParams>(
      context: context,
      builder: (_) => const _BulkDialog(),
    );
    if (res == null) return;
    await _bulkCreate(res);
  }

  Future<void> _bulkCreate(_BulkParams p) async {
    final antrepoId = int.tryParse(_antrepoIdCtrl.text) ?? 3;
    final parentId = _currentParentId;
    int done = 0;

    for (var i = 0; i < p.count; i++) {
      final name = '${p.base}${p.sep}${p.start + i}'.trim();
      try {
        await _svc.create(YerlesimYeri(
          id: 0,
          antrepoId: antrepoId,
          ustYerlesimId: parentId,
          kod: name,
          tip: p.tip,
          aciklama: p.aciklama.isEmpty ? 'toplu' : p.aciklama,
          aktif: true,
        ));
        done++;
      } catch (_) {}
    }
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Eklenen: $done / ${p.count}')),
    );
  }
}

// ---------- Dialoglar ----------
class _YerlesimDialog extends StatefulWidget {
  final int antrepoId;
  final int? parentId;
  final YerlesimYeri? editing;
  const _YerlesimDialog({required this.antrepoId, this.parentId, this.editing});

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
            child: const Text('Vazgeç')),
        ElevatedButton(onPressed: _onSubmit, child: const Text('Kaydet')),
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
        ustYerlesimId: widget.parentId, // aktif ebeveyn altında oluştur
        kod: _kodCtrl.text.trim(),
        sira: siraVal,
        tip: tipVal,
        aciklama: aciklamaVal,
        aktif: _aktif,
      );
      Navigator.pop(context, y);
    } else {
      final y = YerlesimYeri(
        id: widget.editing!.id,
        antrepoId: widget.antrepoId,
        ustYerlesimId: widget.editing!.ustYerlesimId,
        kod: _kodCtrl.text.trim(),
        sira: siraVal,
        tip: tipVal,
        aciklama: aciklamaVal,
        aktif: _aktif,
      );
      Navigator.pop(context, y);
    }
  }
}

class _TemplateParams {
  final String koridorAd;
  final String rafAd;
  final int rafSayisi;
  final String gozAd;
  final int gozSayisi;
  _TemplateParams(
      this.koridorAd, this.rafAd, this.rafSayisi, this.gozAd, this.gozSayisi);
}

class _TemplateDialog extends StatefulWidget {
  const _TemplateDialog();
  @override
  State<_TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends State<_TemplateDialog> {
  final _koridor = TextEditingController(text: 'Koridor-A');
  final _rafAd = TextEditingController(text: 'Raf');
  final _rafSay = TextEditingController(text: '2');
  final _gozAd = TextEditingController(text: 'Göz');
  final _gozSay = TextEditingController(text: '2');
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _koridor.dispose();
    _rafAd.dispose();
    _rafSay.dispose();
    _gozAd.dispose();
    _gozSay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Şablondan Ekle'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                  controller: _koridor,
                  decoration: const InputDecoration(labelText: 'Koridor Adı'),
                  validator: (v) => v!.trim().isEmpty ? 'Gerekli' : null),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                          controller: _rafAd,
                          decoration:
                              const InputDecoration(labelText: 'Raf Adı'),
                          validator: (v) =>
                              v!.trim().isEmpty ? 'Gerekli' : null)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: _rafSay,
                      decoration:
                          const InputDecoration(labelText: 'Raf Sayısı'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (int.tryParse(v ?? '') ?? 0) > 0 ? null : '>0 olmalı',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                          controller: _gozAd,
                          decoration:
                              const InputDecoration(labelText: 'Göz Adı'),
                          validator: (v) =>
                              v!.trim().isEmpty ? 'Gerekli' : null)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: _gozSay,
                      decoration:
                          const InputDecoration(labelText: 'Göz Sayısı'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (int.tryParse(v ?? '') ?? 0) > 0 ? null : '>0 olmalı',
                    ),
                  ),
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
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(
              context,
              _TemplateParams(
                _koridor.text.trim(),
                _rafAd.text.trim(),
                int.parse(_rafSay.text.trim()),
                _gozAd.text.trim(),
                int.parse(_gozSay.text.trim()),
              ),
            );
          },
          child: const Text('Oluştur'),
        ),
      ],
    );
  }
}

class _BulkParams {
  final String base;
  final int count;
  final int start;
  final String sep;
  final String tip;
  final String aciklama;
  _BulkParams(
      this.base, this.count, this.start, this.sep, this.tip, this.aciklama);
}

class _BulkDialog extends StatefulWidget {
  const _BulkDialog();
  @override
  State<_BulkDialog> createState() => _BulkDialogState();
}

class _BulkDialogState extends State<_BulkDialog> {
  final _base = TextEditingController();
  final _count = TextEditingController(text: '1');
  final _start = TextEditingController(text: '1');
  final _sep = TextEditingController(text: '-');
  final _tip = TextEditingController(text: 'bolge');
  final _ack = TextEditingController(text: 'toplu ekleme');
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _base.dispose();
    _count.dispose();
    _start.dispose();
    _sep.dispose();
    _tip.dispose();
    _ack.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Toplu Ekle'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                  controller: _base,
                  decoration: const InputDecoration(labelText: 'Ad (taban)'),
                  validator: (v) => v!.trim().isEmpty ? 'Gerekli' : null),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _count,
                      decoration: const InputDecoration(labelText: 'Adet'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (int.tryParse(v ?? '') ?? 0) > 0 ? null : '>0 olmalı',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _start,
                      decoration: const InputDecoration(labelText: 'Başlangıç'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                  controller: _sep,
                  decoration: const InputDecoration(labelText: 'Ayraç')),
              const SizedBox(height: 8),
              TextFormField(
                  controller: _tip,
                  decoration: const InputDecoration(labelText: 'Tip')),
              const SizedBox(height: 8),
              TextFormField(
                  controller: _ack,
                  decoration: const InputDecoration(labelText: 'Açıklama')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç')),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(
              context,
              _BulkParams(
                _base.text.trim(),
                int.tryParse(_count.text.trim()) ?? 1,
                int.tryParse(_start.text.trim()) ?? 1,
                _sep.text.isEmpty ? '-' : _sep.text,
                _tip.text.trim().isEmpty ? 'bolge' : _tip.text.trim(),
                _ack.text.trim(),
              ),
            );
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}

class _QrScanDialog extends StatefulWidget {
  const _QrScanDialog({Key? key}) : super(key: key);
  @override
  State<_QrScanDialog> createState() => _QrScanDialogState();
}

class _QrScanDialogState extends State<_QrScanDialog> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 360,
        height: 420,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MobileScanner(
                onDetect: (capture) {
                  if (_done) return;
                  final barcodes = capture.barcodes;
                  final raw = barcodes.isNotEmpty
                      ? (barcodes.first.rawValue ?? '')
                      : '';
                  if (raw.isEmpty) return;
                  _done = true;
                  Navigator.of(context).pop(raw);
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
