import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';

// ── Domain models ─────────────────────────────────────────────────────────────

class DayTimes {
  final String date;
  final String day;
  final String fajr;
  final String thuhr;
  final String asr;
  final String maghrib;
  final String isha;

  const DayTimes({
    required this.date,
    required this.day,
    required this.fajr,
    required this.thuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  factory DayTimes.fromJson(Map<String, dynamic> json) => DayTimes(
    date:    json['date'] as String,
    day:     json['day'] as String,
    fajr:    json['fajr'] as String,
    thuhr:   json['thuhr'] as String,
    asr:     json['asr'] as String,
    maghrib: json['maghrib'] as String,
    isha:    json['isha'] as String,
  );

  Map<String, String> get allPrayers => {
    'Fajr':    fajr,
    'Thuhr':   thuhr,
    'Asr':     asr,
    'Maghrib': maghrib,
    'Isha':    isha,
  };

  /// Returns the name of the current prayer or the next prayer.
  String get currentPrayerName {
    final now = _nowMinutes();
    final prayers = [
      MapEntry('Fajr',    _parseMinutes(fajr)),
      MapEntry('Thuhr',   _parseMinutes(thuhr)),
      MapEntry('Asr',     _parseMinutes(asr)),
      MapEntry('Maghrib', _parseMinutes(maghrib)),
      MapEntry('Isha',    _parseMinutes(isha)),
    ];

    String current = 'Isha';
    for (int i = prayers.length - 1; i >= 0; i--) {
      if (now >= prayers[i].value) {
        current = prayers[i].key;
        break;
      }
    }
    return current;
  }

  String get nextPrayerName {
    final now = _nowMinutes();
    final prayers = [
      MapEntry('Fajr',    _parseMinutes(fajr)),
      MapEntry('Thuhr',   _parseMinutes(thuhr)),
      MapEntry('Asr',     _parseMinutes(asr)),
      MapEntry('Maghrib', _parseMinutes(maghrib)),
      MapEntry('Isha',    _parseMinutes(isha)),
    ];

    for (final p in prayers) {
      if (now < p.value) return p.key;
    }
    return 'Fajr'; // next day
  }

  Duration get timeToNextPrayer {
    final now = _nowMinutes();
    final prayers = [
      _parseMinutes(fajr),
      _parseMinutes(thuhr),
      _parseMinutes(asr),
      _parseMinutes(maghrib),
      _parseMinutes(isha),
    ];

    for (final p in prayers) {
      if (now < p) return Duration(minutes: p - now);
    }
    // Next Fajr
    return Duration(minutes: (24 * 60 - now) + _parseMinutes(fajr));
  }

  int _nowMinutes() {
    final n = DateTime.now();
    return n.hour * 60 + n.minute;
  }

  int _parseMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

class MosqueProfile {
  final String slug;
  final String name;
  final String? logo;
  final bool showFasting;
  final List<String> announcements;

  const MosqueProfile({
    required this.slug,
    required this.name,
    this.logo,
    required this.showFasting,
    required this.announcements,
  });

  factory MosqueProfile.fromJson(Map<String, dynamic> json) => MosqueProfile(
    slug:         json['slug'] as String,
    name:         json['name'] as String,
    logo:         json['logo'] as String?,
    showFasting:  json['showFasting'] as bool? ?? true,
    announcements: (json['announcements'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [],
  );
}

// ── Providers ─────────────────────────────────────────────────────────────────

final prayerTimesProvider = FutureProvider<DayTimes>((ref) async {
  final now = DateTime.now();
  final month = DateFormat('yyyy-MM').format(now);
  final dateStr = DateFormat('yyyy-MM-dd').format(now);

  // Prefer month data and pick by local device date to avoid timezone drift.
  try {
    final monthRes = await ApiClient.dio.get(
      '/times',
      queryParameters: {'month': month},
      options: Options(receiveTimeout: const Duration(seconds: 45)),
    );
    final rows = (monthRes.data['times'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final match = rows.where((r) => (r['date'] as String? ?? '') == dateStr);
    if (match.isNotEmpty) {
      return DayTimes.fromJson(match.first);
    }
  } catch (_) {
    // Fall back to /times/today below.
  }

  final todayRes = await ApiClient.dio.get(
    '/times/today',
    options: Options(receiveTimeout: const Duration(seconds: 45)),
  );
  return DayTimes.fromJson(todayRes.data['today'] as Map<String, dynamic>);
});

final defaultMosqueProvider = FutureProvider<MosqueProfile>((ref) async {
  try {
    final response = await ApiClient.dio.get(
      '/mosques/default',
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );
    return MosqueProfile.fromJson(response.data['mosque'] as Map<String, dynamic>);
  } catch (_) {
    // Keep home screen usable even if no default mosque is configured yet.
    return const MosqueProfile(
      slug: 'default',
      name: 'Local Mosque',
      logo: null,
      showFasting: true,
      announcements: [],
    );
  }
});

final monthTimesProvider = FutureProvider.family<List<DayTimes>, String>((ref, month) async {
  final response = await ApiClient.dio.get(
    '/times',
    queryParameters: {'month': month},
    options: Options(receiveTimeout: const Duration(seconds: 45)),
  );
  final list     = response.data['times'] as List;
  return list.map((e) => DayTimes.fromJson(e as Map<String, dynamic>)).toList();
});
