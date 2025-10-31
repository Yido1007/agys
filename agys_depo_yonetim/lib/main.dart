import 'package:antrepo_client/core/home_shell.dart';
import 'package:flutter/material.dart';
import 'features/auth/login_page.dart';
import 'features/yerlesim/yerlesim_map_page.dart';

void main() {
  runApp(const AntrepoApp());
}

class AntrepoApp extends StatelessWidget {
  const AntrepoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Antrepo',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/yerlesim': (_) => const YerlesimMapPage(),
        '/home': (_) => const HomeShell(), // ← eklendi
      },
    );
  }
}
