import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'app_database.g.dart';

// ── Table definitions ──────────────────────────────────────────────────────────

class PrayerTimesCache extends Table {
  TextColumn  get monthKey => text()();           // 'YYYY-MM'
  TextColumn  get dateStr  => text()();           // 'YYYY-MM-DD'
  TextColumn  get dayName  => text()();
  TextColumn  get fajr     => text()();
  TextColumn  get thuhr    => text()();
  TextColumn  get asr      => text()();
  TextColumn  get maghrib  => text()();
  TextColumn  get isha     => text()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {dateStr};
}

class QuranSurahCache extends Table {
  IntColumn  get surahNumber => integer()();
  TextColumn get jsonData    => text()();   // Raw JSON blob
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {surahNumber};
}

class LocalPrayerLogs extends Table {
  TextColumn get dateStr => text()();   // 'YYYY-MM-DD'
  TextColumn get prayer  => text()();   // Fajr|Thuhr|Asr|Maghrib|Isha
  TextColumn get status  => text()();   // prayed|missed|qadha
  DateTimeColumn get loggedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {dateStr, prayer};
}

class LocalQuranBookmarks extends Table {
  IntColumn get surahNumber => integer()();
  IntColumn get ayahNumber  => integer()();
  TextColumn get note       => text().withDefault(const Constant(''))();
  DateTimeColumn get savedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {surahNumber, ayahNumber};
}

// ── Database class ─────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  PrayerTimesCache,
  QuranSurahCache,
  LocalPrayerLogs,
  LocalQuranBookmarks,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ── Prayer times ─────────────────────────────────────────────────────────────

  Future<List<PrayerTimesCacheData>> getPrayerTimesForMonth(String monthKey) =>
    (select(prayerTimesCache)..where((t) => t.monthKey.equals(monthKey))).get();

  Future<PrayerTimesCacheData?> getPrayerTimesForDate(String dateStr) =>
    (select(prayerTimesCache)..where((t) => t.dateStr.equals(dateStr))).getSingleOrNull();

  Future<void> upsertPrayerTimes(PrayerTimesCacheCompanion entry) =>
    into(prayerTimesCache).insertOnConflictUpdate(entry);

  Future<void> upsertPrayerTimesBatch(List<PrayerTimesCacheCompanion> entries) =>
    batch((b) => b.insertAllOnConflictUpdate(prayerTimesCache, entries));

  // ── Quran cache ───────────────────────────────────────────────────────────────

  Future<QuranSurahCacheData?> getCachedSurah(int number) =>
    (select(quranSurahCache)..where((t) => t.surahNumber.equals(number))).getSingleOrNull();

  Future<void> cacheSurah(QuranSurahCacheCompanion entry) =>
    into(quranSurahCache).insertOnConflictUpdate(entry);

  Future<List<int>> getDownloadedSurahNumbers() async {
    final rows = await (select(quranSurahCache)
      ..where((t) => t.surahNumber.isBiggerThanValue(0))).get();
    return rows.map((r) => r.surahNumber).toList();
  }

  Future<int> removeCachedSurah(int number) =>
    (delete(quranSurahCache)..where((t) => t.surahNumber.equals(number))).go();

  Future<int> clearCachedSurahs() =>
    (delete(quranSurahCache)..where((t) => t.surahNumber.isBiggerThanValue(0))).go();

  // ── Prayer logs ───────────────────────────────────────────────────────────────

  Future<List<LocalPrayerLog>> getLogsForDate(String dateStr) =>
    (select(localPrayerLogs)..where((t) => t.dateStr.equals(dateStr))).get();

  Future<List<LocalPrayerLog>> getLogsForDateRange(String from, String to) =>
    (select(localPrayerLogs)
      ..where((t) => t.dateStr.isBetweenValues(from, to))
      ..orderBy([(t) => OrderingTerm(expression: t.dateStr)])).get();

  Future<void> upsertPrayerLog(LocalPrayerLogsCompanion entry) =>
    into(localPrayerLogs).insertOnConflictUpdate(entry);

  // ── Quran bookmarks ───────────────────────────────────────────────────────────

  Future<List<LocalQuranBookmark>> getAllBookmarks() =>
    (select(localQuranBookmarks)
      ..orderBy([(t) => OrderingTerm(expression: t.savedAt, mode: OrderingMode.desc)])).get();

  Future<bool> isBookmarked(int surah, int ayah) async {
    final row = await (select(localQuranBookmarks)
      ..where((t) => t.surahNumber.equals(surah) & t.ayahNumber.equals(ayah)))
      .getSingleOrNull();
    return row != null;
  }

  Future<void> addBookmark(LocalQuranBookmarksCompanion entry) =>
    into(localQuranBookmarks).insertOnConflictUpdate(entry);

  Future<int> removeBookmark(int surah, int ayah) =>
    (delete(localQuranBookmarks)
      ..where((t) => t.surahNumber.equals(surah) & t.ayahNumber.equals(ayah))).go();
}

// ── Connection helper ──────────────────────────────────────────────────────────

LazyDatabase _openConnection() => LazyDatabase(() async {
  await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  final dbFolder = await getApplicationDocumentsDirectory();
  final file     = File(p.join(dbFolder.path, 'cape_noor.db'));
  return NativeDatabase.createInBackground(file);
});
