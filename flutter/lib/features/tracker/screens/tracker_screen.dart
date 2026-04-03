import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';

const _prayers = ['Fajr', 'Thuhr', 'Asr', 'Maghrib', 'Isha'];

enum PrayerStatus { none, prayed, missed, qadha }

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  late DateTime _selectedDate;

  // dateKey -> prayer -> status
  final Map<String, Map<String, PrayerStatus>> _logs = {};

  @override
  void initState() {
    super.initState();
    _tab          = TabController(length: 2, vsync: this);
    _selectedDate = DateTime.now();
    _loadLogs();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String _key(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString('prayer_tracker_logs');
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _logs.clear();
        for (final entry in decoded.entries) {
          _logs[entry.key] = (entry.value as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, PrayerStatus.values.byName(v as String)));
        }
      });
    }
  }

  Future<void> _saveLogs() async {
    final prefs   = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_logs.map((dk, pm) =>
      MapEntry(dk, pm.map((k, v) => MapEntry(k, v.name)))));
    await prefs.setString('prayer_tracker_logs', encoded);
  }

  void _setStatus(String prayer, PrayerStatus status) {
    final dk = _key(_selectedDate);
    setState(() {
      _logs.putIfAbsent(dk, () => {});
      _logs[dk]![prayer] = status;
    });
    _saveLogs();
  }

  PrayerStatus _getStatus(String prayer) {
    final dk = _key(_selectedDate);
    return _logs[dk]?[prayer] ?? PrayerStatus.none;
  }

  int _currentStreak() {
    int streak = 0;
    DateTime d = DateTime.now();
    while (true) {
      final dk   = _key(d);
      final log  = _logs[dk] ?? {};
      final done = _prayers.every((p) => log[p] == PrayerStatus.prayed);
      if (!done) break;
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Prayer Tracker'),
      bottom: TabBar(
        controller: _tab,
        tabs: const [Tab(text: 'Today'), Tab(text: 'History')],
      ),
    ),
    body: TabBarView(
      controller: _tab,
      children: [
        _DailyTrackerTab(
          selectedDate: _selectedDate,
          onDateChanged: (d) => setState(() => _selectedDate = d),
          getStatus: _getStatus,
          setStatus: _setStatus,
          streak: _currentStreak(),
        ),
        _HistoryTab(logs: _logs),
      ],
    ),
  );
}

class _DailyTrackerTab extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final PrayerStatus Function(String) getStatus;
  final void Function(String, PrayerStatus) setStatus;
  final int streak;

  const _DailyTrackerTab({
    required this.selectedDate,
    required this.onDateChanged,
    required this.getStatus,
    required this.setStatus,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = selectedDate.year == today.year &&
                    selectedDate.month == today.month &&
                    selectedDate.day == today.day;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => onDateChanged(selectedDate.subtract(const Duration(days: 1)))),
            Text(isToday ? 'Today' :
              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: Icon(Icons.chevron_right,
                color: isToday ? AppTheme.textMuted : AppTheme.textPrimary),
              onPressed: isToday ? null : () => onDateChanged(selectedDate.add(const Duration(days: 1)))),
          ],
        ),

        if (streak > 0) ...[
          const SizedBox(height: 8),
          Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.gold),
            ),
            child: Text('🔥 $streak day streak!',
              style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
          )),
        ],

        const SizedBox(height: 16),

        ..._prayers.map((prayer) => _PrayerRow(
          prayer: prayer,
          status: getStatus(prayer),
          onStatus: (s) => setStatus(prayer, s),
        )),
      ],
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final String prayer;
  final PrayerStatus status;
  final ValueChanged<PrayerStatus> onStatus;

  const _PrayerRow({required this.prayer, required this.status, required this.onStatus});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _statusColor(status).withOpacity(0.5)),
    ),
    child: Row(
      children: [
        Expanded(child: Text(prayer,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        ...[
          (PrayerStatus.prayed, Icons.check_circle, 'Prayed'),
          (PrayerStatus.missed, Icons.cancel_outlined, 'Missed'),
          (PrayerStatus.qadha,  Icons.history,         'Qadha'),
        ].map(((PrayerStatus s, IconData ic, String label) tuple) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: GestureDetector(
            onTap: () => onStatus(status == tuple.$1 ? PrayerStatus.none : tuple.$1),
            child: Column(
              children: [
                Icon(tuple.$2,
                  color: status == tuple.$1 ? _statusColor(tuple.$1) : AppTheme.textMuted,
                  size: 26),
                Text(tuple.$3, style: TextStyle(
                  fontSize: 9,
                  color: status == tuple.$1 ? _statusColor(tuple.$1) : AppTheme.textMuted)),
              ],
            ),
          ),
        )),
      ],
    ),
  );

  Color _statusColor(PrayerStatus s) => switch(s) {
    PrayerStatus.prayed => AppTheme.green,
    PrayerStatus.missed => Colors.red,
    PrayerStatus.qadha  => AppTheme.gold,
    PrayerStatus.none   => AppTheme.textMuted,
  };
}

class _HistoryTab extends StatelessWidget {
  final Map<String, Map<String, PrayerStatus>> logs;

  const _HistoryTab({required this.logs});

  @override
  Widget build(BuildContext context) {
    final sorted = logs.keys.toList()..sort((a, b) => b.compareTo(a));

    if (sorted.isEmpty) {
      return const Center(
        child: Text('No history yet.', style: TextStyle(color: AppTheme.textMuted)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final dk  = sorted[i];
        final log = logs[dk]!;
        final prayed = _prayers.where((p) => log[p] == PrayerStatus.prayed).length;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(child: Text(dk,
                style: const TextStyle(fontWeight: FontWeight.bold))),
              Row(children: _prayers.map((p) {
                final s = log[p] ?? PrayerStatus.none;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    s == PrayerStatus.prayed ? Icons.circle : Icons.circle_outlined,
                    size: 14,
                    color: s == PrayerStatus.prayed ? AppTheme.green
                         : s == PrayerStatus.missed ? Colors.red
                         : s == PrayerStatus.qadha  ? AppTheme.gold
                         : AppTheme.textMuted),
                );
              }).toList()),
              const SizedBox(width: 8),
              Text('$prayed/5', style: TextStyle(
                color: prayed == 5 ? AppTheme.green : AppTheme.textSecondary,
                fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
}
