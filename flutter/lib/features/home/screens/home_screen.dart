import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import '../home_provider.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final times = ref.read(prayerTimesProvider).valueOrNull;
      if (times != null) {
        setState(() => _remaining = times.timeToNextPrayer);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timesAsync  = ref.watch(prayerTimesProvider);
    final mosqueAsync = ref.watch(defaultMosqueProvider);
    final hijri       = HijriCalendar.now();
    final todayGreg   = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
    final hijriStr    = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ───────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        mosqueAsync.when(
                          data: (m) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.name, style: const TextStyle(
                                fontFamily: 'Amiri', fontSize: 22,
                                fontWeight: FontWeight.bold, color: AppTheme.gold,
                              )),
                              Text(todayGreg, style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12,
                              )),
                            ],
                          ),
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(hijriStr, style: const TextStyle(
                              color: AppTheme.gold, fontSize: 12,
                            )),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Next Prayer Countdown ─────────────────────────────────────
            SliverToBoxAdapter(
              child: timesAsync.when(
                data: (times) => _CountdownCard(times: times, remaining: _remaining),
                loading: () => const _LoadingCard(height: 120),
                error: (e, _) => _ErrorCard(message: e.toString()),
              ),
            ),

            // ── Prayer Cards ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: timesAsync.when(
                  data: (times) => _PrayerGrid(times: times),
                  loading: () => const _LoadingCard(height: 300),
                  error: (e, _) => _ErrorCard(message: e.toString()),
                ),
              ),
            ),

            // ── Announcements ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: mosqueAsync.when(
                data: (mosque) => mosque.announcements.isEmpty
                  ? const SizedBox.shrink()
                  : _AnnouncementsSection(announcements: mosque.announcements),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CountdownCard extends StatelessWidget {
  final DayTimes times;
  final Duration remaining;

  const _CountdownCard({required this.times, required this.remaining});

  @override
  Widget build(BuildContext context) {
    final next = times.nextPrayerName;
    final h    = remaining.inHours;
    final m    = remaining.inMinutes % 60;
    final s    = remaining.inSeconds % 60;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.navyLight, AppTheme.cardBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withAlpha(77)),
      ),
      child: Column(
        children: [
          Text('Next Prayer', style: Theme.of(context).textTheme.bodyMedium),
          Text(next, style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.gold,
          )),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimeUnit(value: h.toString().padLeft(2, '0'), label: 'HRS'),
              const _Colon(),
              _TimeUnit(value: m.toString().padLeft(2, '0'), label: 'MIN'),
              const _Colon(),
              _TimeUnit(value: s.toString().padLeft(2, '0'), label: 'SEC'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeUnit extends StatelessWidget {
  final String value;
  final String label;

  const _TimeUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
    ],
  );
}

class _Colon extends StatelessWidget {
  const _Colon();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Text(':', style: TextStyle(fontSize: 32, color: AppTheme.gold, fontWeight: FontWeight.bold)),
  );
}

class _PrayerGrid extends StatelessWidget {
  final DayTimes times;

  const _PrayerGrid({required this.times});

  static final _prayers = [
    ('fajr',    'Fajr',    Icons.wb_twilight),
    ('thuhr',   'Thuhr',   Icons.wb_sunny),
    ('asr',     'Asr',     Icons.light_mode),
    ('maghrib', 'Maghrib', Icons.wb_twilight),
    ('isha',    'Isha',    Icons.nightlight),
  ];

  @override
  Widget build(BuildContext context) {
    final current = times.currentPrayerName.toLowerCase();

    return Column(
      children: _prayers.map((p) {
        final key       = p.$1;
        final name      = p.$2;
        final icon      = p.$3;
        final timeStr   = switch (key) {
          'fajr'    => times.fajr,
          'thuhr'   => times.thuhr,
          'asr'     => times.asr,
          'maghrib' => times.maghrib,
          'isha'    => times.isha,
          _         => '',
        };
        final isActive   = current == key;
        final color      = AppTheme.prayerColors[key] ?? AppTheme.green;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? color.withAlpha(26) : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? color : AppTheme.divider,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(name, style: TextStyle(
                fontSize: 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? color : AppTheme.textPrimary,
              )),
              const Spacer(),
              Text(timeStr, style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isActive ? color : AppTheme.textPrimary,
              )),
              if (isActive) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('NOW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AnnouncementsSection extends StatefulWidget {
  final List<String> announcements;

  const _AnnouncementsSection({required this.announcements});

  @override
  State<_AnnouncementsSection> createState() => _AnnouncementsSectionState();
}

class _AnnouncementsSectionState extends State<_AnnouncementsSection> {
  late final PageController _ctrl;
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
    if (widget.announcements.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 7), (_) {
        final next = (_current + 1) % widget.announcements.length;
        _ctrl.animateToPage(next, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        setState(() => _current = next);
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    height: 72,
    decoration: BoxDecoration(
      color: AppTheme.cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.gold.withAlpha(77)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: const Icon(Icons.campaign_outlined, color: AppTheme.gold),
        ),
        Expanded(
          child: PageView(
            controller: _ctrl,
            children: widget.announcements.map((a) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(a, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
              ),
            )).toList(),
          ),
        ),
      ],
    ),
  );
}

class _LoadingCard extends StatelessWidget {
  final double height;
  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(16),
    height: height,
    decoration: BoxDecoration(
      color: AppTheme.cardBg,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Center(child: CircularProgressIndicator()),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.error.withAlpha(26),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.error),
    ),
    child: Text(message, style: const TextStyle(color: AppTheme.error)),
  );
}

