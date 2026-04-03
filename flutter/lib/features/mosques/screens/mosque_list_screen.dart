import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../mosque_provider.dart';

class MosqueListScreen extends ConsumerWidget {
  const MosqueListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mosquesAsync = ref.watch(mosquesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mosques')),
      body: mosquesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (mosques) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: mosques.length,
          itemBuilder: (_, i) => _MosqueCard(mosque: mosques[i]),
        ),
      ),
    );
  }
}

class _MosqueCard extends StatelessWidget {
  final MosqueSummary mosque;

  const _MosqueCard({required this.mosque});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(
      builder: (_) => MosqueDetailScreen(slug: mosque.slug, name: mosque.name))),
    borderRadius: BorderRadius.circular(14),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppTheme.navyLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: mosque.logoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(mosque.logoUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.mosque, color: AppTheme.gold)))
              : const Icon(Icons.mosque, color: AppTheme.gold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mosque.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (mosque.area != null)
                  Text(mosque.area!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textMuted),
        ],
      ),
    ),
  );
}

// ─── Mosque Detail ─────────────────────────────────────────────────────────────

class MosqueDetailScreen extends ConsumerWidget {
  final String slug;
  final String name;

  const MosqueDetailScreen({super.key, required this.slug, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(mosqueDetailProvider(slug));
    return detailAsync.when(
      loading: () => Scaffold(appBar: AppBar(title: Text(name)),
        body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(title: Text(name)),
        body: Center(child: Text('Error: $e'))),
      data: (mosque) => _MosqueDetailBody(mosque: mosque),
    );
  }
}

class _MosqueDetailBody extends StatelessWidget {
  final MosqueDetail mosque;
  const _MosqueDetailBody({required this.mosque});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(mosque.name, style: const TextStyle(fontSize: 14)),
            background: mosque.logoUrl != null
              ? Image.network(mosque.logoUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _MosquePlaceholder())
              : const _MosquePlaceholder(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SectionHeader('Information'),
              if (mosque.area    != null) _InfoRow(Icons.location_on, mosque.area!),
              if (mosque.phone   != null) _InfoRow(Icons.phone,       mosque.phone!),
              if (mosque.email   != null) _InfoRow(Icons.email,       mosque.email!),
              if (mosque.website != null) _InfoRow(Icons.language,    mosque.website!),
              if (mosque.fajr    != null) ...[  
                const SizedBox(height: 16),
                _SectionHeader('Prayer Times Today'),
                ...{
                  'Fajr': mosque.fajr, 'Thuhr': mosque.thuhr,
                  'Asr': mosque.asr,   'Maghrib': mosque.maghrib, 'Isha': mosque.isha,
                }.entries.where((e) => e.value != null).map((e) =>
                  _PrayerTimeRow(prayer: e.key, time: e.value!)),
              ],
              if (mosque.announcement != null) ...[  
                const SizedBox(height: 16),
                _SectionHeader('Announcement'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
                  ),
                  child: Text(mosque.announcement!, style: const TextStyle(height: 1.6)),
                ),
              ],
            ]),
          ),
        ),
      ],
    ),
  );
}

class _MosquePlaceholder extends StatelessWidget {
  const _MosquePlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    color: AppTheme.navyLight,
    alignment: Alignment.center,
    child: const Icon(Icons.mosque, size: 80, color: AppTheme.gold),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title,
      style: const TextStyle(
        fontWeight: FontWeight.bold, color: AppTheme.gold, fontSize: 14)),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textSecondary))),
      ],
    ),
  );
}

class _PrayerTimeRow extends StatelessWidget {
  final String prayer;
  final String time;
  const _PrayerTimeRow({required this.prayer, required this.time});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(prayer, style: const TextStyle(color: AppTheme.textSecondary)),
        Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
