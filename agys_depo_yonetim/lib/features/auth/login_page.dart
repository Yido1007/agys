import 'dart:convert';

import 'package:antrepo_client/core/storage.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _antrepoCtrl = TextEditingController(text: 'C35000352'); // örnek
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giriş')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'E-posta'),
                validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Şifre'),
                obscureText: true,
                validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _antrepoCtrl,
                decoration: const InputDecoration(labelText: 'Antrepo Kodu'),
                validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _onLogin,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Giriş yap'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService().login(
        eposta: _emailCtrl.text.trim(),
        sifre: _passCtrl.text,
        antrepoKodu: _antrepoCtrl.text.trim(),
      );

      // JWT inceleme – BURAYA
      String _part(String t, int i) => utf8.decode(base64Url.decode(t
          .split('.')[i]
          .padRight((t.split('.')[i].length + 3) ~/ 4 * 4, '=')));
      final t = await AppStorage.readToken();
      if (t != null) {
        print('[JWT-HEADER] ${_part(t, 0)}');
        print('[JWT-PAYLOAD] ${_part(t, 1)}');
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/yerlesim');
    } catch (e) {
      setState(() {
        _error = 'Giriş başarısız: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
}
