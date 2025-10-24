import 'package:antrepo_client/core/app_prefs.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final AppPrefs prefs;
  const SettingsPage({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedBuilder(
        animation: prefs,
        builder: (context, _) {
          return ListView(
            children: [
              SwitchListTile(
                title: const Text('Depodaki yeri gösterilsin mi ?'),
                subtitle: const Text(
                    'Alt çubuktaki Haritalandırma sekmesini açın/kapatın'),
                value: prefs.showMapping,
                onChanged: prefs.setShowMapping,
              ),
            ],
          );
        },
      ),
    );
  }
}
