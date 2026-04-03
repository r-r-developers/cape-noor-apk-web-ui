import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../quran_provider.dart';
import '../../../core/theme/app_theme.dart';

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  final _searchCtrl = TextEditingController();
  String _query     = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahListProvider);
    final downloadedAsync = ref.watch(downloadedSurahNumbersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن الكريم'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search surah or verse...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    })
                  : null,
              ),
            ),
          ),
        ),
      ),
      body: surahsAsync.when(
        data: (surahs) {
          final filtered = _query.isEmpty
            ? surahs
            : surahs.where((s) =>
                s.englishName.toLowerCase().contains(_query.toLowerCase()) ||
                s.number.toString() == _query
              ).toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final surah = filtered[i];
              final downloaded = downloadedAsync.valueOrNull?.contains(surah.number) ?? false;
              return _SurahTile(
                surah: surah,
                downloaded: downloaded,
                onDownloadToggle: () => _toggleDownload(context, surah.number, downloaded),
              );
            },
          );
        },
        loading: () => _ShimmerList(),
        error: (e, _) => _QuranErrorView(message: _friendlyErrorMessage(e)),
      ),
    );
  }

  String _friendlyErrorMessage(Object error) {
    if (error is DioException && error.response?.statusCode == 502) {
      return 'Quran service is temporarily unavailable. Please try again shortly.';
    }
    return 'Unable to load Quran data right now.';
  }

  Future<void> _toggleDownload(BuildContext context, int surahNumber, bool downloaded) async {
    final actions = ref.read(quranOfflineActionsProvider);
    try {
      if (downloaded) {
        await actions.deleteSurahDownload(surahNumber);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed Surah $surahNumber from offline storage')),
        );
      } else {
        await actions.downloadSurah(surahNumber);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded Surah $surahNumber for offline use')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download action failed: $e')),
      );
    }
  }
}

class _QuranErrorView extends StatelessWidget {
  final String message;

  const _QuranErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.error, fontSize: 14),
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  final SurahMeta surah;
  final bool downloaded;
  final VoidCallback onDownloadToggle;

  const _SurahTile({required this.surah, required this.downloaded, required this.onDownloadToggle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/quran/surah/${surah.number}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            // Number badge
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.green.withAlpha(26),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.green.withAlpha(77)),
              ),
              child: Center(child: Text(
                surah.number.toString(),
                style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold, fontSize: 13),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(surah.englishName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(surah.englishNameTranslation, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  Text('${surah.numberOfAyahs} verses · ${surah.revelationType}',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              onPressed: onDownloadToggle,
              tooltip: downloaded ? 'Remove download' : 'Download for offline',
              icon: Icon(
                downloaded ? Icons.delete_outline : Icons.download_for_offline_outlined,
                color: downloaded ? AppTheme.error : AppTheme.green,
              ),
            ),
            Text(surah.name, style: const TextStyle(fontFamily: 'Amiri', fontSize: 22, color: AppTheme.gold)),
          ],
        ),
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: AppTheme.cardBg,
    highlightColor: AppTheme.navyLight,
    child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 20,
      itemBuilder: (_, __) => Container(
        height: 72, margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
