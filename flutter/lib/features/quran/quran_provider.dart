import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/api/api_client.dart';
import '../../core/storage/app_database.dart';

class SurahMeta {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  const SurahMeta({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory SurahMeta.fromJson(Map<String, dynamic> json) => SurahMeta(
    number:                   json['number'] as int,
    name:                     json['name'] as String? ?? '',
    englishName:              json['englishName'] as String? ?? '',
    englishNameTranslation:   json['englishNameTranslation'] as String? ?? '',
    numberOfAyahs:            json['numberOfAyahs'] as int? ?? 0,
    revelationType:           json['revelationType'] as String? ?? '',
  );
}

class Ayah {
  final int number;
  final int numberInSurah;
  final String text;
  final String translation;
  final String? audio;

  const Ayah({
    required this.number,
    required this.numberInSurah,
    required this.text,
    required this.translation,
    this.audio,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) => Ayah(
    number:          json['number'] as int,
    numberInSurah:   json['numberInSurah'] as int,
    text:            json['text'] as String,
    translation:     json['translation'] as String? ?? '',
    audio:           json['audio'] as String?,
  );
}

class SurahData {
  final SurahMeta surah;
  final List<Ayah> ayahs;

  const SurahData({required this.surah, required this.ayahs});

  factory SurahData.fromJson(Map<String, dynamic> json) => SurahData(
    surah: SurahMeta.fromJson(json['surah'] as Map<String, dynamic>),
    ayahs: (json['ayahs'] as List).map((e) => Ayah.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

final AppDatabase _db = AppDatabase();
const int _surahListCacheKey = 0;

// ── Providers ─────────────────────────────────────────────────────────────────

final surahListProvider = FutureProvider<List<SurahMeta>>((ref) async {
  try {
    final response = await ApiClient.dio.get(
      '/quran/surahs',
      options: Options(receiveTimeout: const Duration(seconds: 45)),
    );

    await _db.cacheSurah(QuranSurahCacheCompanion(
      surahNumber: const Value(_surahListCacheKey),
      jsonData: Value(jsonEncode({'surahs': response.data['surahs']})),
    ));

    final list = response.data['surahs'] as List;
    return list.map((e) => SurahMeta.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    final cached = await _db.getCachedSurah(_surahListCacheKey);
    if (cached != null) {
      final data = jsonDecode(cached.jsonData) as Map<String, dynamic>;
      final list = (data['surahs'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
      return list.map(SurahMeta.fromJson).toList();
    }
    throw e;
  }
});

final surahDataProvider = FutureProvider.family<SurahData, int>((ref, number) async {
  try {
    final response = await ApiClient.dio.get(
      '/quran/surahs/$number',
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );

    await _db.cacheSurah(QuranSurahCacheCompanion(
      surahNumber: Value(number),
      jsonData: Value(jsonEncode(response.data)),
    ));

    return SurahData.fromJson(response.data as Map<String, dynamic>);
  } catch (e) {
    final cached = await _db.getCachedSurah(number);
    if (cached != null) {
      return SurahData.fromJson(jsonDecode(cached.jsonData) as Map<String, dynamic>);
    }
    throw e;
  }
});

final quranSearchProvider = FutureProvider.family<List<dynamic>, String>((ref, q) async {
  if (q.isEmpty) return [];
  final response = await ApiClient.dio.get(
    '/quran/search',
    queryParameters: {'q': q},
    options: Options(receiveTimeout: const Duration(seconds: 45)),
  );
  return response.data['matches'] as List;
});

final downloadedSurahNumbersProvider = FutureProvider<Set<int>>((ref) async {
  final nums = await _db.getDownloadedSurahNumbers();
  return nums.toSet();
});

final quranOfflineActionsProvider = Provider<QuranOfflineActions>((ref) {
  return QuranOfflineActions(ref);
});

class QuranOfflineActions {
  final Ref _ref;

  QuranOfflineActions(this._ref);

  Future<void> downloadSurah(int number) async {
    final response = await ApiClient.dio.get(
      '/quran/surahs/$number',
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
    await _db.cacheSurah(QuranSurahCacheCompanion(
      surahNumber: Value(number),
      jsonData: Value(jsonEncode(response.data)),
    ));
    _ref.invalidate(downloadedSurahNumbersProvider);
  }

  Future<void> deleteSurahDownload(int number) async {
    await _db.removeCachedSurah(number);
    _ref.invalidate(downloadedSurahNumbersProvider);
  }
}
