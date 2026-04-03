import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../quran_provider.dart';
import '../../../core/theme/app_theme.dart';

class SurahReaderScreen extends ConsumerStatefulWidget {
  final int surahNumber;

  const SurahReaderScreen({super.key, required this.surahNumber});

  @override
  ConsumerState<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen> {
  final _player       = AudioPlayer();
  int? _playingAyah;
  bool _showTranslation = true;
  double _arabicFontSize = 26;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playAyah(Ayah ayah) async {
    if (_playingAyah == ayah.number) {
      await _player.stop();
      setState(() => _playingAyah = null);
      return;
    }

    setState(() => _playingAyah = ayah.number);
    try {
      await _player.setUrl(ayah.audio ?? '');
      await _player.play();
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) setState(() => _playingAyah = null);
        }
      });
    } catch (_) {
      setState(() => _playingAyah = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surahAsync = ref.watch(surahDataProvider(widget.surahNumber));

    return Scaffold(
      appBar: AppBar(
        title: surahAsync.when(
          data: (d) => Text(d.surah.englishName, style: const TextStyle(fontFamily: 'Amiri')),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Surah'),
        ),
        actions: [
          // Translation toggle
          IconButton(
            icon: Icon(_showTranslation ? Icons.translate : Icons.translate_outlined,
              color: _showTranslation ? AppTheme.green : AppTheme.textMuted),
            onPressed: () => setState(() => _showTranslation = !_showTranslation),
            tooltip: 'Toggle translation',
          ),
          // Font size
          PopupMenuButton<double>(
            icon: const Icon(Icons.text_fields),
            itemBuilder: (_) => [20.0, 24.0, 28.0, 32.0, 36.0].map((s) =>
              PopupMenuItem(value: s, child: Text('${s.toInt()}px'))).toList(),
            onSelected: (s) => setState(() => _arabicFontSize = s),
          ),
        ],
      ),
      body: surahAsync.when(
        data: (data) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.ayahs.length + 1, // +1 for Bismillah header
          itemBuilder: (context, index) {
            if (index == 0) {
              return _BismillahHeader(surah: data.surah);
            }
            final ayah = data.ayahs[index - 1];
            return _AyahCard(
              ayah: ayah,
              isPlaying: _playingAyah == ayah.number,
              showTranslation: _showTranslation,
              arabicFontSize: _arabicFontSize,
              onAudioTap: () => _playAyah(ayah),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _friendlyErrorMessage(e),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.error),
            ),
          ),
        ),
      ),
    );
  }

  String _friendlyErrorMessage(Object error) {
    if (error is DioException && error.response?.statusCode == 502) {
      return 'Quran service is temporarily unavailable. Please try again shortly.';
    }
    return 'Unable to load this surah right now.';
  }
}

class _BismillahHeader extends StatelessWidget {
  final SurahMeta surah;

  const _BismillahHeader({required this.surah});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppTheme.navyLight, AppTheme.cardBg],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.gold.withAlpha(77)),
    ),
    child: Column(
      children: [
        Text(surah.name, style: const TextStyle(
          fontFamily: 'Amiri', fontSize: 40, color: AppTheme.gold,
        )),
        const SizedBox(height: 4),
        Text(surah.englishName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(surah.englishNameTranslation, style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 12),
        if (surah.number != 1 && surah.number != 9)
          const Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            style: TextStyle(fontFamily: 'Amiri', fontSize: 26, color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
      ],
    ),
  );
}

class _AyahCard extends StatelessWidget {
  final Ayah ayah;
  final bool isPlaying;
  final bool showTranslation;
  final double arabicFontSize;
  final VoidCallback onAudioTap;

  const _AyahCard({
    required this.ayah,
    required this.isPlaying,
    required this.showTranslation,
    required this.arabicFontSize,
    required this.onAudioTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isPlaying ? AppTheme.green.withAlpha(20) : AppTheme.cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isPlaying ? AppTheme.green : AppTheme.divider,
        width: isPlaying ? 2 : 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ayah number + audio icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.green.withAlpha(51),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${ayah.numberInSurah}',
                style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const Spacer(),
            if (ayah.audio != null)
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle : Icons.play_circle_outline,
                  color: isPlaying ? AppTheme.green : AppTheme.textMuted,
                  size: 28,
                ),
                onPressed: onAudioTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Arabic text (RTL)
        Text(
          ayah.text,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: arabicFontSize,
            height: 2.0,
            color: AppTheme.textPrimary,
          ),
        ),

        if (showTranslation && ayah.translation.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(thickness: 0.5),
          const SizedBox(height: 8),
          Text(
            ayah.translation,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.6),
          ),
        ],
      ],
    ),
  );
}
