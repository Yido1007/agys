import 'package:antrepo_client/core/app_prefs.dart';
import 'package:antrepo_client/features/home/home.dart';
import 'package:antrepo_client/features/home/settings_page.dart';
import 'package:antrepo_client/features/yerlesim/yerlesim_map_page.dart';
import 'package:flutter/material.dart';

/// HomeShell with dynamic tab for Locations controlled by Settings switch.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final AppPrefs prefs = AppPrefs();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: prefs,
      builder: (context, _) {
        final showMap = prefs.showMapping;
        final tabs = <Widget>[
          const HomeTab(),
          if (showMap) const YerlesimMapPage(),
          SettingsPage(prefs: prefs)
        ];
        final items = <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Ana sayfa'),
          if (showMap)
            const BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'Haritalandırma'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Ayarlar'),
        ];

        // Clamp index if Locations tab is hidden
        if (!showMap && _index == 1) {
          _index = 1; // points to Settings now
        }
        final maxIndex = items.length - 1;
        if (_index > maxIndex) _index = maxIndex;

        return Scaffold(
          body: IndexedStack(index: _index, children: tabs),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: items,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            showUnselectedLabels: true,
          ),
        );
      },
    );
  }
}
