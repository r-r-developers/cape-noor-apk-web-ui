import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../core/theme/app_theme.dart';

// ─── Static Islamic events (Gregorian approximate dates for 2025/2026) ─────────
const _islamicEvents = <String, String>{
  '2025-04-01': 'Ramadan begins',
  '2025-05-01': 'Eid al-Fitr',
  '2025-06-07': 'Eid al-Adha',
  '2025-06-27': 'Islamic New Year',
  '2025-09-05': 'Prophet\'s Birthday (Mawlid)',
  '2026-03-20': 'Ramadan begins',
  '2026-04-20': 'Eid al-Fitr',
  '2026-05-27': 'Eid al-Adha',
};

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
  }

  void _previousMonth() => setState(() =>
    _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1));

  void _nextMonth() => setState(() =>
    _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    final firstDay    = _displayMonth;
    final lastDay     = DateTime(_displayMonth.year, _displayMonth.month + 1, 0);
    final startOffset = (firstDay.weekday % 7); // 0=Sun
    final totalCells  = startOffset + lastDay.day;
    final rows        = (totalCells / 7).ceil();
    final today       = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Islamic Calendar'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: _previousMonth),
              Column(
                children: [
                  Text(_monthName(_displayMonth.month, _displayMonth.year),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(_hijriMonthLabel(firstDay),
                    style: const TextStyle(color: AppTheme.gold, fontSize: 12)),
                ],
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Day-of-week header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                .map((d) => Expanded(child: Center(child: Text(d,
                    style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12,
                      color: d == 'Fr' ? AppTheme.green : AppTheme.textSecondary)))))
                .toList(),
            ),
          ),

          // Calendar grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 0.85),
              itemCount: rows * 7,
              itemBuilder: (_, index) {
                final dayNum = index - startOffset + 1;
                if (dayNum < 1 || dayNum > lastDay.day) return const SizedBox();
                final date     = DateTime(_displayMonth.year, _displayMonth.month, dayNum);
                final key      = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
                final event    = _islamicEvents[key];
                final isToday  = date.year == today.year && date.month == today.month && date.day == today.day;
                final hijri    = HijriCalendar.fromDate(date);
                final isFri    = date.weekday == DateTime.friday;

                return _DayCell(
                  gregorian: dayNum,
                  hijri: hijri.hDay,
                  isToday: isToday,
                  event: event,
                  isFriday: isFri,
                );
              },
            ),
          ),

          // Upcoming events list
          Container(
            height: 160,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Upcoming Events',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.gold)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _islamicEvents.entries
                      .where((e) => DateTime.parse(e.key).isAfter(today.subtract(const Duration(days: 1))))
                      .take(6)
                      .map((e) => _EventChip(date: e.key, label: e.value))
                      .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month, int year) {
    const months = ['January','February','March','April','May','June',
                    'July','August','September','October','November','December'];
    return '${months[month - 1]} $year';
  }

  String _hijriMonthLabel(DateTime date) {
    final h = HijriCalendar.fromDate(date);
    const months = ['Muharram','Safar','Rabi\' al-Awwal','Rabi\' al-Thani',
                    'Jumada al-Awwal','Jumada al-Thani','Rajab','Sha\'ban',
                    'Ramadan','Shawwal','Dhul Qa\'dah','Dhul Hijjah'];
    return '${months[h.hMonth - 1]} ${h.hYear} AH';
  }
}

class _DayCell extends StatelessWidget {
  final int gregorian;
  final int hijri;
  final bool isToday;
  final String? event;
  final bool isFriday;

  const _DayCell({
    required this.gregorian,
    required this.hijri,
    required this.isToday,
    this.event,
    required this.isFriday,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isToday ? AppTheme.green.withOpacity(0.2) : AppTheme.cardBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isToday ? AppTheme.green : event != null ? AppTheme.gold : AppTheme.divider,
        width: isToday || event != null ? 2 : 1,
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$gregorian', style: TextStyle(
          fontSize: 14, fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          color: isFriday ? AppTheme.green : AppTheme.textPrimary)),
        Text('$hijri', style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
        if (event != null) Container(
          width: 5, height: 5,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.gold)),
      ],
    ),
  );
}

class _EventChip extends StatelessWidget {
  final String date;
  final String label;

  const _EventChip({required this.date, required this.label});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.parse(date);
    final diff = dt.difference(DateTime.now()).inDays;
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2),
          const SizedBox(height: 4),
          Text(diff == 0 ? 'Today!' : 'In $diff days',
            style: TextStyle(color: diff <= 7 ? AppTheme.gold : AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
