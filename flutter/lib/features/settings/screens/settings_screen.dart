import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/auth_provider.dart';

// alias for brevity
final _authProvider = authNotifierProvider;

// ── Simple local settings state ────────────────────────────────────────────────

class _Prefs {
  final bool fajrAlert;
  final bool thuhrAlert;
  final bool asrAlert;
  final bool maghribAlert;
  final bool ishaAlert;
  final bool fastingAlert;
  final String madhab;
  final bool darkMode;

  const _Prefs({
    this.fajrAlert    = true,
    this.thuhrAlert   = true,
    this.asrAlert     = true,
    this.maghribAlert = true,
    this.ishaAlert    = true,
    this.fastingAlert = true,
    this.madhab       = 'shafi',
    this.darkMode     = true,
  });

  _Prefs copyWith({
    bool? fajrAlert, bool? thuhrAlert, bool? asrAlert,
    bool? maghribAlert, bool? ishaAlert, bool? fastingAlert,
    String? madhab, bool? darkMode,
  }) => _Prefs(
    fajrAlert:    fajrAlert    ?? this.fajrAlert,
    thuhrAlert:   thuhrAlert   ?? this.thuhrAlert,
    asrAlert:     asrAlert     ?? this.asrAlert,
    maghribAlert: maghribAlert ?? this.maghribAlert,
    ishaAlert:    ishaAlert    ?? this.ishaAlert,
    fastingAlert: fastingAlert ?? this.fastingAlert,
    madhab:       madhab       ?? this.madhab,
    darkMode:     darkMode     ?? this.darkMode,
  );
}

class _SettingsNotifier extends StateNotifier<_Prefs> {
  _SettingsNotifier() : super(const _Prefs()) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = _Prefs(
      fajrAlert:    p.getBool('alert_fajr')    ?? true,
      thuhrAlert:   p.getBool('alert_thuhr')   ?? true,
      asrAlert:     p.getBool('alert_asr')     ?? true,
      maghribAlert: p.getBool('alert_maghrib') ?? true,
      ishaAlert:    p.getBool('alert_isha')    ?? true,
      fastingAlert: p.getBool('alert_fasting') ?? true,
      madhab:       p.getString('madhab')       ?? 'shafi',
      darkMode:     p.getBool('dark_mode')      ?? true,
    );
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await Future.wait([
      p.setBool('alert_fajr',    state.fajrAlert),
      p.setBool('alert_thuhr',   state.thuhrAlert),
      p.setBool('alert_asr',     state.asrAlert),
      p.setBool('alert_maghrib', state.maghribAlert),
      p.setBool('alert_isha',    state.ishaAlert),
      p.setBool('alert_fasting', state.fastingAlert),
      p.setString('madhab',      state.madhab),
      p.setBool('dark_mode',     state.darkMode),
    ]);
  }

  void toggleAlert(String prayer, bool value) {
    state = switch (prayer) {
      'Fajr'    => state.copyWith(fajrAlert: value),
      'Thuhr'   => state.copyWith(thuhrAlert: value),
      'Asr'     => state.copyWith(asrAlert: value),
      'Maghrib' => state.copyWith(maghribAlert: value),
      'Isha'    => state.copyWith(ishaAlert: value),
      'Fasting' => state.copyWith(fastingAlert: value),
      _         => state,
    };
    _save();
  }

  void setMadhab(String value) {
    state = state.copyWith(madhab: value);
    _save();
  }

  void setDarkMode(bool value) {
    state = state.copyWith(darkMode: value);
    _save();
  }
}

final _settingsProvider = StateNotifierProvider<_SettingsNotifier, _Prefs>(
  (_) => _SettingsNotifier());

// ── Screen ─────────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs    = ref.watch(_settingsProvider);
    final notifier = ref.read(_settingsProvider.notifier);
    final auth     = ref.watch(_authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Notifications ─────────────────────────────────────────────────
          _SectionHeader('Prayer Notifications'),
          ...{
            'Fajr':    prefs.fajrAlert,
            'Thuhr':   prefs.thuhrAlert,
            'Asr':     prefs.asrAlert,
            'Maghrib': prefs.maghribAlert,
            'Isha':    prefs.ishaAlert,
            'Fasting': prefs.fastingAlert,
          }.entries.map((e) => SwitchListTile(
            title: Text(e.key),
            value: e.value,
            activeColor: AppTheme.green,
            onChanged: (v) => notifier.toggleAlert(e.key, v),
          )),

          const Divider(),

          // ── Juristic school ────────────────────────────────────────────────
          _SectionHeader('Juristic School (Madhab)'),
          RadioListTile<String>(
            title: const Text("Shafi'i / Maliki / Hanbali"),
            subtitle: const Text('Asr: shadow = 1× object height'),
            value: 'shafi',
            groupValue: prefs.madhab,
            activeColor: AppTheme.green,
            onChanged: (v) => notifier.setMadhab(v!),
          ),
          RadioListTile<String>(
            title: const Text('Hanafi'),
            subtitle: const Text('Asr: shadow = 2× object height'),
            value: 'hanafi',
            groupValue: prefs.madhab,
            activeColor: AppTheme.green,
            onChanged: (v) => notifier.setMadhab(v!),
          ),

          const Divider(),

          // ── Appearance ────────────────────────────────────────────────────
          _SectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: prefs.darkMode,
            activeColor: AppTheme.green,
            onChanged: (v) => notifier.setDarkMode(v),
          ),

          const Divider(),

          // ── Account ───────────────────────────────────────────────────────
          _SectionHeader('Account'),
          auth.when(
            loading: () => const SizedBox.shrink(),
            error:   (_, __) => const SizedBox.shrink(),
            data: (state) => state.isLoggedIn
              ? Column(children: [
                  ListTile(
                    leading: const Icon(Icons.person, color: AppTheme.gold),
                    title: Text(state.user?.email ?? 'Logged in'),
                    subtitle: const Text('Tap to manage account'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                    onTap: () => ref.read(_authProvider.notifier).logout(),
                  ),
                ])
              : Column(children: [
                  ListTile(
                    leading: const Icon(Icons.login, color: AppTheme.green),
                    title: const Text('Sign In'),
                    subtitle: const Text('Sync prayer tracker & bookmarks'),
                    onTap: () => Navigator.pushNamed(context, '/auth/login'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_add, color: AppTheme.gold),
                    title: const Text('Create Account'),
                    onTap: () => Navigator.pushNamed(context, '/auth/register'),
                  ),
                ]),
          ),

          const Divider(),

          // ── About ─────────────────────────────────────────────────────────
          _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppTheme.textMuted),
            title: const Text('Cape Noor'),
            subtitle: const Text('Version 2.0.0 • Cape Town Prayer Times'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.textMuted),
            title: const Text('Privacy Policy'),
            onTap: () {/* open webview */},
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.bold,
        color: AppTheme.gold, letterSpacing: 1)),
  );
}
