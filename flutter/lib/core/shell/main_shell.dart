import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const MainShell({super.key, required this.shell});

  static const _tabs = [
    _Tab(label: 'Home',    icon: Icons.home_outlined,       activeIcon: Icons.home),
    _Tab(label: 'Quran',   icon: Icons.menu_book_outlined,  activeIcon: Icons.menu_book),
    _Tab(label: 'Qibla',   icon: Icons.explore_outlined,    activeIcon: Icons.explore),
    _Tab(label: 'Mosques', icon: Icons.mosque_outlined,     activeIcon: Icons.mosque),
    _Tab(label: 'More',    icon: Icons.apps_outlined,       activeIcon: Icons.apps),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = shell.currentIndex;

    return Scaffold(
      body: shell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.navyMid,
          border: const Border(top: BorderSide(color: AppTheme.divider)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: _tabs.asMap().entries.map((entry) {
                final i      = entry.key;
                final tab    = entry.value;
                final active = i == selectedIndex;

                return Expanded(
                  child: InkWell(
                    onTap: () => shell.goBranch(
                      i,
                      initialLocation: i == selectedIndex,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          active ? tab.activeIcon : tab.icon,
                          size: 24,
                          color: active ? AppTheme.green : AppTheme.textMuted,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: active ? AppTheme.green : AppTheme.textMuted,
                            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _Tab({required this.label, required this.icon, required this.activeIcon});
}
