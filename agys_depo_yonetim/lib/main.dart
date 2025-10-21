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
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/yerlesim': (_) => const YerlesimMapPage(),
      },
    );
  }
}
