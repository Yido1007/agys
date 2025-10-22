import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/api_service.dart';

class ApiDiagnosticsPage extends StatefulWidget {
  const ApiDiagnosticsPage({super.key});
  @override
  State<ApiDiagnosticsPage> createState() => _ApiDiagnosticsPageState();
}

class _ApiDiagnosticsPageState extends State<ApiDiagnosticsPage> {
  final _dio = ApiService.instance.dio;
  final _log = <String>[];
  int antrepoId = 3; // login payloadına göre güncelle
  int? lastCreatedId;

  void _add(String s) => setState(() => _log.insert(0, s));

  Future<void> _run() async {
    setState(() => _log.clear());
    try {
      // 1) LIST
      final list = await _dio.get('/api/YerlesimYeri/antrepo/$antrepoId');
      _add('[LIST] ${list.statusCode} body=${_short(list.data)}');

      // 2) CREATE (minimal DTO)
      final createBody = {
        "antrepoId": antrepoId,
        "kod": "DBG-${DateTime.now().millisecondsSinceEpoch}",
        "tip": "raf",
        "aciklama": "otomatik test kaydı"
      };
      final crt = await _dio.post('/api/YerlesimYeri', data: createBody);
      _add('[CREATE] ${crt.statusCode} body=${_short(crt.data)}');

      // id yakala (farklı şemalara toleranslı)
      lastCreatedId = _pickId(crt.data);
      if (lastCreatedId == null) {
        // bazı API'ler gövde döndürmez; listeden son elemanı almayı dene
        final l2 = await _dio.get('/api/YerlesimYeri/antrepo/$antrepoId');
        lastCreatedId = _pickLastId(l2.data);
      }
      _add('[ID] createdId=$lastCreatedId');

      // 3) UPDATE
      if (lastCreatedId != null) {
        final updBody = {
          "id": lastCreatedId,
          "kod": "DBG-UPDATED",
          "antrepoId": antrepoId
        };
        // V1: PUT body
        var upd = await _dio.put('/api/YerlesimYeri', data: updBody);
        _add('[UPDATE v1 PUT body] ${upd.statusCode} body=${_short(upd.data)}');
        if (upd.statusCode == 405 ||
            upd.statusCode == 404 ||
            (upd.statusCode ?? 0) >= 400) {
          // V2: PUT path
          upd =
              await _dio.put('/api/YerlesimYeri/$lastCreatedId', data: updBody);
          _add(
              '[UPDATE v2 PUT path] ${upd.statusCode} body=${_short(upd.data)}');
          if ((upd.statusCode ?? 0) >= 400) {
            // V3: POST /update
            upd = await _dio.post('/api/YerlesimYeri/update', data: updBody);
            _add(
                '[UPDATE v3 POST /update] ${upd.statusCode} body=${_short(upd.data)}');
            if ((upd.statusCode ?? 0) >= 400) {
              // V4: Method-Override
              upd = await _dio.post('/api/YerlesimYeri',
                  data: updBody,
                  options: Options(headers: {'X-HTTP-Method-Override': 'PUT'}));
              _add(
                  '[UPDATE v4 override] ${upd.statusCode} body=${_short(upd.data)}');
            }
          }
        }
      }

      // 4) DELETE
      if (lastCreatedId != null) {
        // V1: REST
        var del = await _dio.delete('/api/YerlesimYeri/$lastCreatedId');
        _add('[DELETE v1 /{id}] ${del.statusCode} body=${_short(del.data)}');
        if (del.statusCode == 405 || (del.statusCode ?? 0) >= 400) {
          // V2: POST /delete
          del = await _dio.post('/api/YerlesimYeri/delete',
              data: {'id': lastCreatedId, 'antrepoId': antrepoId});
          _add(
              '[DELETE v2 /delete] ${del.statusCode} body=${_short(del.data)}');
          if ((del.statusCode ?? 0) >= 400) {
            // V3: DELETE ?id=
            del = await _dio.delete('/api/YerlesimYeri',
                queryParameters: {'id': lastCreatedId});
            _add('[DELETE v3 ?id=] ${del.statusCode} body=${_short(del.data)}');
            if ((del.statusCode ?? 0) >= 400) {
              // V4: Method-Override
              del = await _dio.post('/api/YerlesimYeri',
                  data: {'id': lastCreatedId, 'antrepoId': antrepoId},
                  options:
                      Options(headers: {'X-HTTP-Method-Override': 'DELETE'}));
              _add(
                  '[DELETE v4 override] ${del.statusCode} body=${_short(del.data)}');
            }
          }
        }
      }
    } catch (e) {
      _add('[ERR] $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Diagnostics')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Antrepo ID'),
                    keyboardType: TextInputType.number,
                    onChanged: (s) => antrepoId = int.tryParse(s) ?? antrepoId,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _run, child: const Text('Run All')),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _log.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_log[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// helpers
String _short(dynamic d) {
  try {
    final s = d is String ? d : jsonEncode(d);
    return s.length <= 500 ? s : '${s.substring(0, 500)}...';
  } catch (_) {
    return d.toString();
  }
}

int? _pickId(dynamic data) {
  try {
    if (data is Map<String, dynamic>) {
      for (final k in [
        'id',
        'Id',
        'ID',
        'yerlesimYeriId',
        'YerlesimYeriId',
        'YerlesimYeriID'
      ]) {
        final v = data[k];
        if (v is int) return v;
        final p = int.tryParse('$v');
        if (p != null) return p;
      }
    }
  } catch (_) {}
  return null;
}

int? _pickLastId(dynamic listData) {
  try {
    if (listData is List && listData.isNotEmpty) {
      final last = listData.last;
      if (last is Map<String, dynamic>) return _pickId(last);
    }
    if (listData is Map &&
        listData['items'] is List &&
        (listData['items'] as List).isNotEmpty) {
      final last = (listData['items'] as List).last;
      if (last is Map<String, dynamic>)
        return _pickId(Map<String, dynamic>.from(last));
    }
  } catch (_) {}
  return null;
}
