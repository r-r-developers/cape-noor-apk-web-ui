// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PrayerTimesCacheTable extends PrayerTimesCache
    with TableInfo<$PrayerTimesCacheTable, PrayerTimesCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrayerTimesCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _monthKeyMeta =
      const VerificationMeta('monthKey');
  @override
  late final GeneratedColumn<String> monthKey = GeneratedColumn<String>(
      'month_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateStrMeta =
      const VerificationMeta('dateStr');
  @override
  late final GeneratedColumn<String> dateStr = GeneratedColumn<String>(
      'date_str', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dayNameMeta =
      const VerificationMeta('dayName');
  @override
  late final GeneratedColumn<String> dayName = GeneratedColumn<String>(
      'day_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fajrMeta = const VerificationMeta('fajr');
  @override
  late final GeneratedColumn<String> fajr = GeneratedColumn<String>(
      'fajr', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _thuhrMeta = const VerificationMeta('thuhr');
  @override
  late final GeneratedColumn<String> thuhr = GeneratedColumn<String>(
      'thuhr', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _asrMeta = const VerificationMeta('asr');
  @override
  late final GeneratedColumn<String> asr = GeneratedColumn<String>(
      'asr', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _maghribMeta =
      const VerificationMeta('maghrib');
  @override
  late final GeneratedColumn<String> maghrib = GeneratedColumn<String>(
      'maghrib', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ishaMeta = const VerificationMeta('isha');
  @override
  late final GeneratedColumn<String> isha = GeneratedColumn<String>(
      'isha', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [monthKey, dateStr, dayName, fajr, thuhr, asr, maghrib, isha, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prayer_times_cache';
  @override
  VerificationContext validateIntegrity(
      Insertable<PrayerTimesCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('month_key')) {
      context.handle(_monthKeyMeta,
          monthKey.isAcceptableOrUnknown(data['month_key']!, _monthKeyMeta));
    } else if (isInserting) {
      context.missing(_monthKeyMeta);
    }
    if (data.containsKey('date_str')) {
      context.handle(_dateStrMeta,
          dateStr.isAcceptableOrUnknown(data['date_str']!, _dateStrMeta));
    } else if (isInserting) {
      context.missing(_dateStrMeta);
    }
    if (data.containsKey('day_name')) {
      context.handle(_dayNameMeta,
          dayName.isAcceptableOrUnknown(data['day_name']!, _dayNameMeta));
    } else if (isInserting) {
      context.missing(_dayNameMeta);
    }
    if (data.containsKey('fajr')) {
      context.handle(
          _fajrMeta, fajr.isAcceptableOrUnknown(data['fajr']!, _fajrMeta));
    } else if (isInserting) {
      context.missing(_fajrMeta);
    }
    if (data.containsKey('thuhr')) {
      context.handle(
          _thuhrMeta, thuhr.isAcceptableOrUnknown(data['thuhr']!, _thuhrMeta));
    } else if (isInserting) {
      context.missing(_thuhrMeta);
    }
    if (data.containsKey('asr')) {
      context.handle(
          _asrMeta, asr.isAcceptableOrUnknown(data['asr']!, _asrMeta));
    } else if (isInserting) {
      context.missing(_asrMeta);
    }
    if (data.containsKey('maghrib')) {
      context.handle(_maghribMeta,
          maghrib.isAcceptableOrUnknown(data['maghrib']!, _maghribMeta));
    } else if (isInserting) {
      context.missing(_maghribMeta);
    }
    if (data.containsKey('isha')) {
      context.handle(
          _ishaMeta, isha.isAcceptableOrUnknown(data['isha']!, _ishaMeta));
    } else if (isInserting) {
      context.missing(_ishaMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dateStr};
  @override
  PrayerTimesCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrayerTimesCacheData(
      monthKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}month_key'])!,
      dateStr: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date_str'])!,
      dayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day_name'])!,
      fajr: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fajr'])!,
      thuhr: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thuhr'])!,
      asr: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asr'])!,
      maghrib: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}maghrib'])!,
      isha: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}isha'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $PrayerTimesCacheTable createAlias(String alias) {
    return $PrayerTimesCacheTable(attachedDatabase, alias);
  }
}

class PrayerTimesCacheData extends DataClass
    implements Insertable<PrayerTimesCacheData> {
  final String monthKey;
  final String dateStr;
  final String dayName;
  final String fajr;
  final String thuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final DateTime cachedAt;
  const PrayerTimesCacheData(
      {required this.monthKey,
      required this.dateStr,
      required this.dayName,
      required this.fajr,
      required this.thuhr,
      required this.asr,
      required this.maghrib,
      required this.isha,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['month_key'] = Variable<String>(monthKey);
    map['date_str'] = Variable<String>(dateStr);
    map['day_name'] = Variable<String>(dayName);
    map['fajr'] = Variable<String>(fajr);
    map['thuhr'] = Variable<String>(thuhr);
    map['asr'] = Variable<String>(asr);
    map['maghrib'] = Variable<String>(maghrib);
    map['isha'] = Variable<String>(isha);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  PrayerTimesCacheCompanion toCompanion(bool nullToAbsent) {
    return PrayerTimesCacheCompanion(
      monthKey: Value(monthKey),
      dateStr: Value(dateStr),
      dayName: Value(dayName),
      fajr: Value(fajr),
      thuhr: Value(thuhr),
      asr: Value(asr),
      maghrib: Value(maghrib),
      isha: Value(isha),
      cachedAt: Value(cachedAt),
    );
  }

  factory PrayerTimesCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrayerTimesCacheData(
      monthKey: serializer.fromJson<String>(json['monthKey']),
      dateStr: serializer.fromJson<String>(json['dateStr']),
      dayName: serializer.fromJson<String>(json['dayName']),
      fajr: serializer.fromJson<String>(json['fajr']),
      thuhr: serializer.fromJson<String>(json['thuhr']),
      asr: serializer.fromJson<String>(json['asr']),
      maghrib: serializer.fromJson<String>(json['maghrib']),
      isha: serializer.fromJson<String>(json['isha']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'monthKey': serializer.toJson<String>(monthKey),
      'dateStr': serializer.toJson<String>(dateStr),
      'dayName': serializer.toJson<String>(dayName),
      'fajr': serializer.toJson<String>(fajr),
      'thuhr': serializer.toJson<String>(thuhr),
      'asr': serializer.toJson<String>(asr),
      'maghrib': serializer.toJson<String>(maghrib),
      'isha': serializer.toJson<String>(isha),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  PrayerTimesCacheData copyWith(
          {String? monthKey,
          String? dateStr,
          String? dayName,
          String? fajr,
          String? thuhr,
          String? asr,
          String? maghrib,
          String? isha,
          DateTime? cachedAt}) =>
      PrayerTimesCacheData(
        monthKey: monthKey ?? this.monthKey,
        dateStr: dateStr ?? this.dateStr,
        dayName: dayName ?? this.dayName,
        fajr: fajr ?? this.fajr,
        thuhr: thuhr ?? this.thuhr,
        asr: asr ?? this.asr,
        maghrib: maghrib ?? this.maghrib,
        isha: isha ?? this.isha,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  PrayerTimesCacheData copyWithCompanion(PrayerTimesCacheCompanion data) {
    return PrayerTimesCacheData(
      monthKey: data.monthKey.present ? data.monthKey.value : this.monthKey,
      dateStr: data.dateStr.present ? data.dateStr.value : this.dateStr,
      dayName: data.dayName.present ? data.dayName.value : this.dayName,
      fajr: data.fajr.present ? data.fajr.value : this.fajr,
      thuhr: data.thuhr.present ? data.thuhr.value : this.thuhr,
      asr: data.asr.present ? data.asr.value : this.asr,
      maghrib: data.maghrib.present ? data.maghrib.value : this.maghrib,
      isha: data.isha.present ? data.isha.value : this.isha,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrayerTimesCacheData(')
          ..write('monthKey: $monthKey, ')
          ..write('dateStr: $dateStr, ')
          ..write('dayName: $dayName, ')
          ..write('fajr: $fajr, ')
          ..write('thuhr: $thuhr, ')
          ..write('asr: $asr, ')
          ..write('maghrib: $maghrib, ')
          ..write('isha: $isha, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      monthKey, dateStr, dayName, fajr, thuhr, asr, maghrib, isha, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrayerTimesCacheData &&
          other.monthKey == this.monthKey &&
          other.dateStr == this.dateStr &&
          other.dayName == this.dayName &&
          other.fajr == this.fajr &&
          other.thuhr == this.thuhr &&
          other.asr == this.asr &&
          other.maghrib == this.maghrib &&
          other.isha == this.isha &&
          other.cachedAt == this.cachedAt);
}

class PrayerTimesCacheCompanion extends UpdateCompanion<PrayerTimesCacheData> {
  final Value<String> monthKey;
  final Value<String> dateStr;
  final Value<String> dayName;
  final Value<String> fajr;
  final Value<String> thuhr;
  final Value<String> asr;
  final Value<String> maghrib;
  final Value<String> isha;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const PrayerTimesCacheCompanion({
    this.monthKey = const Value.absent(),
    this.dateStr = const Value.absent(),
    this.dayName = const Value.absent(),
    this.fajr = const Value.absent(),
    this.thuhr = const Value.absent(),
    this.asr = const Value.absent(),
    this.maghrib = const Value.absent(),
    this.isha = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrayerTimesCacheCompanion.insert({
    required String monthKey,
    required String dateStr,
    required String dayName,
    required String fajr,
    required String thuhr,
    required String asr,
    required String maghrib,
    required String isha,
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : monthKey = Value(monthKey),
        dateStr = Value(dateStr),
        dayName = Value(dayName),
        fajr = Value(fajr),
        thuhr = Value(thuhr),
        asr = Value(asr),
        maghrib = Value(maghrib),
        isha = Value(isha);
  static Insertable<PrayerTimesCacheData> custom({
    Expression<String>? monthKey,
    Expression<String>? dateStr,
    Expression<String>? dayName,
    Expression<String>? fajr,
    Expression<String>? thuhr,
    Expression<String>? asr,
    Expression<String>? maghrib,
    Expression<String>? isha,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (monthKey != null) 'month_key': monthKey,
      if (dateStr != null) 'date_str': dateStr,
      if (dayName != null) 'day_name': dayName,
      if (fajr != null) 'fajr': fajr,
      if (thuhr != null) 'thuhr': thuhr,
      if (asr != null) 'asr': asr,
      if (maghrib != null) 'maghrib': maghrib,
      if (isha != null) 'isha': isha,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrayerTimesCacheCompanion copyWith(
      {Value<String>? monthKey,
      Value<String>? dateStr,
      Value<String>? dayName,
      Value<String>? fajr,
      Value<String>? thuhr,
      Value<String>? asr,
      Value<String>? maghrib,
      Value<String>? isha,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return PrayerTimesCacheCompanion(
      monthKey: monthKey ?? this.monthKey,
      dateStr: dateStr ?? this.dateStr,
      dayName: dayName ?? this.dayName,
      fajr: fajr ?? this.fajr,
      thuhr: thuhr ?? this.thuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (monthKey.present) {
      map['month_key'] = Variable<String>(monthKey.value);
    }
    if (dateStr.present) {
      map['date_str'] = Variable<String>(dateStr.value);
    }
    if (dayName.present) {
      map['day_name'] = Variable<String>(dayName.value);
    }
    if (fajr.present) {
      map['fajr'] = Variable<String>(fajr.value);
    }
    if (thuhr.present) {
      map['thuhr'] = Variable<String>(thuhr.value);
    }
    if (asr.present) {
      map['asr'] = Variable<String>(asr.value);
    }
    if (maghrib.present) {
      map['maghrib'] = Variable<String>(maghrib.value);
    }
    if (isha.present) {
      map['isha'] = Variable<String>(isha.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrayerTimesCacheCompanion(')
          ..write('monthKey: $monthKey, ')
          ..write('dateStr: $dateStr, ')
          ..write('dayName: $dayName, ')
          ..write('fajr: $fajr, ')
          ..write('thuhr: $thuhr, ')
          ..write('asr: $asr, ')
          ..write('maghrib: $maghrib, ')
          ..write('isha: $isha, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuranSurahCacheTable extends QuranSurahCache
    with TableInfo<$QuranSurahCacheTable, QuranSurahCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuranSurahCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _surahNumberMeta =
      const VerificationMeta('surahNumber');
  @override
  late final GeneratedColumn<int> surahNumber = GeneratedColumn<int>(
      'surah_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _jsonDataMeta =
      const VerificationMeta('jsonData');
  @override
  late final GeneratedColumn<String> jsonData = GeneratedColumn<String>(
      'json_data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [surahNumber, jsonData, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quran_surah_cache';
  @override
  VerificationContext validateIntegrity(
      Insertable<QuranSurahCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('surah_number')) {
      context.handle(
          _surahNumberMeta,
          surahNumber.isAcceptableOrUnknown(
              data['surah_number']!, _surahNumberMeta));
    }
    if (data.containsKey('json_data')) {
      context.handle(_jsonDataMeta,
          jsonData.isAcceptableOrUnknown(data['json_data']!, _jsonDataMeta));
    } else if (isInserting) {
      context.missing(_jsonDataMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {surahNumber};
  @override
  QuranSurahCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuranSurahCacheData(
      surahNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}surah_number'])!,
      jsonData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json_data'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $QuranSurahCacheTable createAlias(String alias) {
    return $QuranSurahCacheTable(attachedDatabase, alias);
  }
}

class QuranSurahCacheData extends DataClass
    implements Insertable<QuranSurahCacheData> {
  final int surahNumber;
  final String jsonData;
  final DateTime cachedAt;
  const QuranSurahCacheData(
      {required this.surahNumber,
      required this.jsonData,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['surah_number'] = Variable<int>(surahNumber);
    map['json_data'] = Variable<String>(jsonData);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  QuranSurahCacheCompanion toCompanion(bool nullToAbsent) {
    return QuranSurahCacheCompanion(
      surahNumber: Value(surahNumber),
      jsonData: Value(jsonData),
      cachedAt: Value(cachedAt),
    );
  }

  factory QuranSurahCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuranSurahCacheData(
      surahNumber: serializer.fromJson<int>(json['surahNumber']),
      jsonData: serializer.fromJson<String>(json['jsonData']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'surahNumber': serializer.toJson<int>(surahNumber),
      'jsonData': serializer.toJson<String>(jsonData),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  QuranSurahCacheData copyWith(
          {int? surahNumber, String? jsonData, DateTime? cachedAt}) =>
      QuranSurahCacheData(
        surahNumber: surahNumber ?? this.surahNumber,
        jsonData: jsonData ?? this.jsonData,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  QuranSurahCacheData copyWithCompanion(QuranSurahCacheCompanion data) {
    return QuranSurahCacheData(
      surahNumber:
          data.surahNumber.present ? data.surahNumber.value : this.surahNumber,
      jsonData: data.jsonData.present ? data.jsonData.value : this.jsonData,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuranSurahCacheData(')
          ..write('surahNumber: $surahNumber, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(surahNumber, jsonData, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuranSurahCacheData &&
          other.surahNumber == this.surahNumber &&
          other.jsonData == this.jsonData &&
          other.cachedAt == this.cachedAt);
}

class QuranSurahCacheCompanion extends UpdateCompanion<QuranSurahCacheData> {
  final Value<int> surahNumber;
  final Value<String> jsonData;
  final Value<DateTime> cachedAt;
  const QuranSurahCacheCompanion({
    this.surahNumber = const Value.absent(),
    this.jsonData = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  QuranSurahCacheCompanion.insert({
    this.surahNumber = const Value.absent(),
    required String jsonData,
    this.cachedAt = const Value.absent(),
  }) : jsonData = Value(jsonData);
  static Insertable<QuranSurahCacheData> custom({
    Expression<int>? surahNumber,
    Expression<String>? jsonData,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (surahNumber != null) 'surah_number': surahNumber,
      if (jsonData != null) 'json_data': jsonData,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  QuranSurahCacheCompanion copyWith(
      {Value<int>? surahNumber,
      Value<String>? jsonData,
      Value<DateTime>? cachedAt}) {
    return QuranSurahCacheCompanion(
      surahNumber: surahNumber ?? this.surahNumber,
      jsonData: jsonData ?? this.jsonData,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (surahNumber.present) {
      map['surah_number'] = Variable<int>(surahNumber.value);
    }
    if (jsonData.present) {
      map['json_data'] = Variable<String>(jsonData.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuranSurahCacheCompanion(')
          ..write('surahNumber: $surahNumber, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalPrayerLogsTable extends LocalPrayerLogs
    with TableInfo<$LocalPrayerLogsTable, LocalPrayerLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPrayerLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateStrMeta =
      const VerificationMeta('dateStr');
  @override
  late final GeneratedColumn<String> dateStr = GeneratedColumn<String>(
      'date_str', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _prayerMeta = const VerificationMeta('prayer');
  @override
  late final GeneratedColumn<String> prayer = GeneratedColumn<String>(
      'prayer', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _loggedAtMeta =
      const VerificationMeta('loggedAt');
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
      'logged_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [dateStr, prayer, status, loggedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_prayer_logs';
  @override
  VerificationContext validateIntegrity(Insertable<LocalPrayerLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date_str')) {
      context.handle(_dateStrMeta,
          dateStr.isAcceptableOrUnknown(data['date_str']!, _dateStrMeta));
    } else if (isInserting) {
      context.missing(_dateStrMeta);
    }
    if (data.containsKey('prayer')) {
      context.handle(_prayerMeta,
          prayer.isAcceptableOrUnknown(data['prayer']!, _prayerMeta));
    } else if (isInserting) {
      context.missing(_prayerMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('logged_at')) {
      context.handle(_loggedAtMeta,
          loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dateStr, prayer};
  @override
  LocalPrayerLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPrayerLog(
      dateStr: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date_str'])!,
      prayer: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prayer'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      loggedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}logged_at'])!,
    );
  }

  @override
  $LocalPrayerLogsTable createAlias(String alias) {
    return $LocalPrayerLogsTable(attachedDatabase, alias);
  }
}

class LocalPrayerLog extends DataClass implements Insertable<LocalPrayerLog> {
  final String dateStr;
  final String prayer;
  final String status;
  final DateTime loggedAt;
  const LocalPrayerLog(
      {required this.dateStr,
      required this.prayer,
      required this.status,
      required this.loggedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date_str'] = Variable<String>(dateStr);
    map['prayer'] = Variable<String>(prayer);
    map['status'] = Variable<String>(status);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    return map;
  }

  LocalPrayerLogsCompanion toCompanion(bool nullToAbsent) {
    return LocalPrayerLogsCompanion(
      dateStr: Value(dateStr),
      prayer: Value(prayer),
      status: Value(status),
      loggedAt: Value(loggedAt),
    );
  }

  factory LocalPrayerLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPrayerLog(
      dateStr: serializer.fromJson<String>(json['dateStr']),
      prayer: serializer.fromJson<String>(json['prayer']),
      status: serializer.fromJson<String>(json['status']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dateStr': serializer.toJson<String>(dateStr),
      'prayer': serializer.toJson<String>(prayer),
      'status': serializer.toJson<String>(status),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
    };
  }

  LocalPrayerLog copyWith(
          {String? dateStr,
          String? prayer,
          String? status,
          DateTime? loggedAt}) =>
      LocalPrayerLog(
        dateStr: dateStr ?? this.dateStr,
        prayer: prayer ?? this.prayer,
        status: status ?? this.status,
        loggedAt: loggedAt ?? this.loggedAt,
      );
  LocalPrayerLog copyWithCompanion(LocalPrayerLogsCompanion data) {
    return LocalPrayerLog(
      dateStr: data.dateStr.present ? data.dateStr.value : this.dateStr,
      prayer: data.prayer.present ? data.prayer.value : this.prayer,
      status: data.status.present ? data.status.value : this.status,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPrayerLog(')
          ..write('dateStr: $dateStr, ')
          ..write('prayer: $prayer, ')
          ..write('status: $status, ')
          ..write('loggedAt: $loggedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(dateStr, prayer, status, loggedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPrayerLog &&
          other.dateStr == this.dateStr &&
          other.prayer == this.prayer &&
          other.status == this.status &&
          other.loggedAt == this.loggedAt);
}

class LocalPrayerLogsCompanion extends UpdateCompanion<LocalPrayerLog> {
  final Value<String> dateStr;
  final Value<String> prayer;
  final Value<String> status;
  final Value<DateTime> loggedAt;
  final Value<int> rowid;
  const LocalPrayerLogsCompanion({
    this.dateStr = const Value.absent(),
    this.prayer = const Value.absent(),
    this.status = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPrayerLogsCompanion.insert({
    required String dateStr,
    required String prayer,
    required String status,
    this.loggedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : dateStr = Value(dateStr),
        prayer = Value(prayer),
        status = Value(status);
  static Insertable<LocalPrayerLog> custom({
    Expression<String>? dateStr,
    Expression<String>? prayer,
    Expression<String>? status,
    Expression<DateTime>? loggedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dateStr != null) 'date_str': dateStr,
      if (prayer != null) 'prayer': prayer,
      if (status != null) 'status': status,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPrayerLogsCompanion copyWith(
      {Value<String>? dateStr,
      Value<String>? prayer,
      Value<String>? status,
      Value<DateTime>? loggedAt,
      Value<int>? rowid}) {
    return LocalPrayerLogsCompanion(
      dateStr: dateStr ?? this.dateStr,
      prayer: prayer ?? this.prayer,
      status: status ?? this.status,
      loggedAt: loggedAt ?? this.loggedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dateStr.present) {
      map['date_str'] = Variable<String>(dateStr.value);
    }
    if (prayer.present) {
      map['prayer'] = Variable<String>(prayer.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPrayerLogsCompanion(')
          ..write('dateStr: $dateStr, ')
          ..write('prayer: $prayer, ')
          ..write('status: $status, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalQuranBookmarksTable extends LocalQuranBookmarks
    with TableInfo<$LocalQuranBookmarksTable, LocalQuranBookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalQuranBookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _surahNumberMeta =
      const VerificationMeta('surahNumber');
  @override
  late final GeneratedColumn<int> surahNumber = GeneratedColumn<int>(
      'surah_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _ayahNumberMeta =
      const VerificationMeta('ayahNumber');
  @override
  late final GeneratedColumn<int> ayahNumber = GeneratedColumn<int>(
      'ayah_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _savedAtMeta =
      const VerificationMeta('savedAt');
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
      'saved_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [surahNumber, ayahNumber, note, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_quran_bookmarks';
  @override
  VerificationContext validateIntegrity(Insertable<LocalQuranBookmark> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('surah_number')) {
      context.handle(
          _surahNumberMeta,
          surahNumber.isAcceptableOrUnknown(
              data['surah_number']!, _surahNumberMeta));
    } else if (isInserting) {
      context.missing(_surahNumberMeta);
    }
    if (data.containsKey('ayah_number')) {
      context.handle(
          _ayahNumberMeta,
          ayahNumber.isAcceptableOrUnknown(
              data['ayah_number']!, _ayahNumberMeta));
    } else if (isInserting) {
      context.missing(_ayahNumberMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('saved_at')) {
      context.handle(_savedAtMeta,
          savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {surahNumber, ayahNumber};
  @override
  LocalQuranBookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalQuranBookmark(
      surahNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}surah_number'])!,
      ayahNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ayah_number'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      savedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}saved_at'])!,
    );
  }

  @override
  $LocalQuranBookmarksTable createAlias(String alias) {
    return $LocalQuranBookmarksTable(attachedDatabase, alias);
  }
}

class LocalQuranBookmark extends DataClass
    implements Insertable<LocalQuranBookmark> {
  final int surahNumber;
  final int ayahNumber;
  final String note;
  final DateTime savedAt;
  const LocalQuranBookmark(
      {required this.surahNumber,
      required this.ayahNumber,
      required this.note,
      required this.savedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['surah_number'] = Variable<int>(surahNumber);
    map['ayah_number'] = Variable<int>(ayahNumber);
    map['note'] = Variable<String>(note);
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  LocalQuranBookmarksCompanion toCompanion(bool nullToAbsent) {
    return LocalQuranBookmarksCompanion(
      surahNumber: Value(surahNumber),
      ayahNumber: Value(ayahNumber),
      note: Value(note),
      savedAt: Value(savedAt),
    );
  }

  factory LocalQuranBookmark.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalQuranBookmark(
      surahNumber: serializer.fromJson<int>(json['surahNumber']),
      ayahNumber: serializer.fromJson<int>(json['ayahNumber']),
      note: serializer.fromJson<String>(json['note']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'surahNumber': serializer.toJson<int>(surahNumber),
      'ayahNumber': serializer.toJson<int>(ayahNumber),
      'note': serializer.toJson<String>(note),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  LocalQuranBookmark copyWith(
          {int? surahNumber,
          int? ayahNumber,
          String? note,
          DateTime? savedAt}) =>
      LocalQuranBookmark(
        surahNumber: surahNumber ?? this.surahNumber,
        ayahNumber: ayahNumber ?? this.ayahNumber,
        note: note ?? this.note,
        savedAt: savedAt ?? this.savedAt,
      );
  LocalQuranBookmark copyWithCompanion(LocalQuranBookmarksCompanion data) {
    return LocalQuranBookmark(
      surahNumber:
          data.surahNumber.present ? data.surahNumber.value : this.surahNumber,
      ayahNumber:
          data.ayahNumber.present ? data.ayahNumber.value : this.ayahNumber,
      note: data.note.present ? data.note.value : this.note,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalQuranBookmark(')
          ..write('surahNumber: $surahNumber, ')
          ..write('ayahNumber: $ayahNumber, ')
          ..write('note: $note, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(surahNumber, ayahNumber, note, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalQuranBookmark &&
          other.surahNumber == this.surahNumber &&
          other.ayahNumber == this.ayahNumber &&
          other.note == this.note &&
          other.savedAt == this.savedAt);
}

class LocalQuranBookmarksCompanion extends UpdateCompanion<LocalQuranBookmark> {
  final Value<int> surahNumber;
  final Value<int> ayahNumber;
  final Value<String> note;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const LocalQuranBookmarksCompanion({
    this.surahNumber = const Value.absent(),
    this.ayahNumber = const Value.absent(),
    this.note = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalQuranBookmarksCompanion.insert({
    required int surahNumber,
    required int ayahNumber,
    this.note = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : surahNumber = Value(surahNumber),
        ayahNumber = Value(ayahNumber);
  static Insertable<LocalQuranBookmark> custom({
    Expression<int>? surahNumber,
    Expression<int>? ayahNumber,
    Expression<String>? note,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (surahNumber != null) 'surah_number': surahNumber,
      if (ayahNumber != null) 'ayah_number': ayahNumber,
      if (note != null) 'note': note,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalQuranBookmarksCompanion copyWith(
      {Value<int>? surahNumber,
      Value<int>? ayahNumber,
      Value<String>? note,
      Value<DateTime>? savedAt,
      Value<int>? rowid}) {
    return LocalQuranBookmarksCompanion(
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      note: note ?? this.note,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (surahNumber.present) {
      map['surah_number'] = Variable<int>(surahNumber.value);
    }
    if (ayahNumber.present) {
      map['ayah_number'] = Variable<int>(ayahNumber.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalQuranBookmarksCompanion(')
          ..write('surahNumber: $surahNumber, ')
          ..write('ayahNumber: $ayahNumber, ')
          ..write('note: $note, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PrayerTimesCacheTable prayerTimesCache =
      $PrayerTimesCacheTable(this);
  late final $QuranSurahCacheTable quranSurahCache =
      $QuranSurahCacheTable(this);
  late final $LocalPrayerLogsTable localPrayerLogs =
      $LocalPrayerLogsTable(this);
  late final $LocalQuranBookmarksTable localQuranBookmarks =
      $LocalQuranBookmarksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [prayerTimesCache, quranSurahCache, localPrayerLogs, localQuranBookmarks];
}

typedef $$PrayerTimesCacheTableCreateCompanionBuilder
    = PrayerTimesCacheCompanion Function({
  required String monthKey,
  required String dateStr,
  required String dayName,
  required String fajr,
  required String thuhr,
  required String asr,
  required String maghrib,
  required String isha,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});
typedef $$PrayerTimesCacheTableUpdateCompanionBuilder
    = PrayerTimesCacheCompanion Function({
  Value<String> monthKey,
  Value<String> dateStr,
  Value<String> dayName,
  Value<String> fajr,
  Value<String> thuhr,
  Value<String> asr,
  Value<String> maghrib,
  Value<String> isha,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$PrayerTimesCacheTableFilterComposer
    extends Composer<_$AppDatabase, $PrayerTimesCacheTable> {
  $$PrayerTimesCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get monthKey => $composableBuilder(
      column: $table.monthKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dateStr => $composableBuilder(
      column: $table.dateStr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dayName => $composableBuilder(
      column: $table.dayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fajr => $composableBuilder(
      column: $table.fajr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thuhr => $composableBuilder(
      column: $table.thuhr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get asr => $composableBuilder(
      column: $table.asr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get maghrib => $composableBuilder(
      column: $table.maghrib, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get isha => $composableBuilder(
      column: $table.isha, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$PrayerTimesCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $PrayerTimesCacheTable> {
  $$PrayerTimesCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get monthKey => $composableBuilder(
      column: $table.monthKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dateStr => $composableBuilder(
      column: $table.dateStr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dayName => $composableBuilder(
      column: $table.dayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fajr => $composableBuilder(
      column: $table.fajr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thuhr => $composableBuilder(
      column: $table.thuhr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get asr => $composableBuilder(
      column: $table.asr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get maghrib => $composableBuilder(
      column: $table.maghrib, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get isha => $composableBuilder(
      column: $table.isha, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$PrayerTimesCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrayerTimesCacheTable> {
  $$PrayerTimesCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get monthKey =>
      $composableBuilder(column: $table.monthKey, builder: (column) => column);

  GeneratedColumn<String> get dateStr =>
      $composableBuilder(column: $table.dateStr, builder: (column) => column);

  GeneratedColumn<String> get dayName =>
      $composableBuilder(column: $table.dayName, builder: (column) => column);

  GeneratedColumn<String> get fajr =>
      $composableBuilder(column: $table.fajr, builder: (column) => column);

  GeneratedColumn<String> get thuhr =>
      $composableBuilder(column: $table.thuhr, builder: (column) => column);

  GeneratedColumn<String> get asr =>
      $composableBuilder(column: $table.asr, builder: (column) => column);

  GeneratedColumn<String> get maghrib =>
      $composableBuilder(column: $table.maghrib, builder: (column) => column);

  GeneratedColumn<String> get isha =>
      $composableBuilder(column: $table.isha, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$PrayerTimesCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PrayerTimesCacheTable,
    PrayerTimesCacheData,
    $$PrayerTimesCacheTableFilterComposer,
    $$PrayerTimesCacheTableOrderingComposer,
    $$PrayerTimesCacheTableAnnotationComposer,
    $$PrayerTimesCacheTableCreateCompanionBuilder,
    $$PrayerTimesCacheTableUpdateCompanionBuilder,
    (
      PrayerTimesCacheData,
      BaseReferences<_$AppDatabase, $PrayerTimesCacheTable,
          PrayerTimesCacheData>
    ),
    PrayerTimesCacheData,
    PrefetchHooks Function()> {
  $$PrayerTimesCacheTableTableManager(
      _$AppDatabase db, $PrayerTimesCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrayerTimesCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrayerTimesCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrayerTimesCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> monthKey = const Value.absent(),
            Value<String> dateStr = const Value.absent(),
            Value<String> dayName = const Value.absent(),
            Value<String> fajr = const Value.absent(),
            Value<String> thuhr = const Value.absent(),
            Value<String> asr = const Value.absent(),
            Value<String> maghrib = const Value.absent(),
            Value<String> isha = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PrayerTimesCacheCompanion(
            monthKey: monthKey,
            dateStr: dateStr,
            dayName: dayName,
            fajr: fajr,
            thuhr: thuhr,
            asr: asr,
            maghrib: maghrib,
            isha: isha,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String monthKey,
            required String dateStr,
            required String dayName,
            required String fajr,
            required String thuhr,
            required String asr,
            required String maghrib,
            required String isha,
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PrayerTimesCacheCompanion.insert(
            monthKey: monthKey,
            dateStr: dateStr,
            dayName: dayName,
            fajr: fajr,
            thuhr: thuhr,
            asr: asr,
            maghrib: maghrib,
            isha: isha,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PrayerTimesCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PrayerTimesCacheTable,
    PrayerTimesCacheData,
    $$PrayerTimesCacheTableFilterComposer,
    $$PrayerTimesCacheTableOrderingComposer,
    $$PrayerTimesCacheTableAnnotationComposer,
    $$PrayerTimesCacheTableCreateCompanionBuilder,
    $$PrayerTimesCacheTableUpdateCompanionBuilder,
    (
      PrayerTimesCacheData,
      BaseReferences<_$AppDatabase, $PrayerTimesCacheTable,
          PrayerTimesCacheData>
    ),
    PrayerTimesCacheData,
    PrefetchHooks Function()>;
typedef $$QuranSurahCacheTableCreateCompanionBuilder = QuranSurahCacheCompanion
    Function({
  Value<int> surahNumber,
  required String jsonData,
  Value<DateTime> cachedAt,
});
typedef $$QuranSurahCacheTableUpdateCompanionBuilder = QuranSurahCacheCompanion
    Function({
  Value<int> surahNumber,
  Value<String> jsonData,
  Value<DateTime> cachedAt,
});

class $$QuranSurahCacheTableFilterComposer
    extends Composer<_$AppDatabase, $QuranSurahCacheTable> {
  $$QuranSurahCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get surahNumber => $composableBuilder(
      column: $table.surahNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jsonData => $composableBuilder(
      column: $table.jsonData, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$QuranSurahCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $QuranSurahCacheTable> {
  $$QuranSurahCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get surahNumber => $composableBuilder(
      column: $table.surahNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jsonData => $composableBuilder(
      column: $table.jsonData, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$QuranSurahCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuranSurahCacheTable> {
  $$QuranSurahCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get surahNumber => $composableBuilder(
      column: $table.surahNumber, builder: (column) => column);

  GeneratedColumn<String> get jsonData =>
      $composableBuilder(column: $table.jsonData, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$QuranSurahCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuranSurahCacheTable,
    QuranSurahCacheData,
    $$QuranSurahCacheTableFilterComposer,
    $$QuranSurahCacheTableOrderingComposer,
    $$QuranSurahCacheTableAnnotationComposer,
    $$QuranSurahCacheTableCreateCompanionBuilder,
    $$QuranSurahCacheTableUpdateCompanionBuilder,
    (
      QuranSurahCacheData,
      BaseReferences<_$AppDatabase, $QuranSurahCacheTable, QuranSurahCacheData>
    ),
    QuranSurahCacheData,
    PrefetchHooks Function()> {
  $$QuranSurahCacheTableTableManager(
      _$AppDatabase db, $QuranSurahCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuranSurahCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuranSurahCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuranSurahCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> surahNumber = const Value.absent(),
            Value<String> jsonData = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
          }) =>
              QuranSurahCacheCompanion(
            surahNumber: surahNumber,
            jsonData: jsonData,
            cachedAt: cachedAt,
          ),
          createCompanionCallback: ({
            Value<int> surahNumber = const Value.absent(),
            required String jsonData,
            Value<DateTime> cachedAt = const Value.absent(),
          }) =>
              QuranSurahCacheCompanion.insert(
            surahNumber: surahNumber,
            jsonData: jsonData,
            cachedAt: cachedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$QuranSurahCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuranSurahCacheTable,
    QuranSurahCacheData,
    $$QuranSurahCacheTableFilterComposer,
    $$QuranSurahCacheTableOrderingComposer,
    $$QuranSurahCacheTableAnnotationComposer,
    $$QuranSurahCacheTableCreateCompanionBuilder,
    $$QuranSurahCacheTableUpdateCompanionBuilder,
    (
      QuranSurahCacheData,
      BaseReferences<_$AppDatabase, $QuranSurahCacheTable, QuranSurahCacheData>
    ),
    QuranSurahCacheData,
    PrefetchHooks Function()>;
typedef $$LocalPrayerLogsTableCreateCompanionBuilder = LocalPrayerLogsCompanion
    Function({
  required String dateStr,
  required String prayer,
  required String status,
  Value<DateTime> loggedAt,
  Value<int> rowid,
});
typedef $$LocalPrayerLogsTableUpdateCompanionBuilder = LocalPrayerLogsCompanion
    Function({
  Value<String> dateStr,
  Value<String> prayer,
  Value<String> status,
  Value<DateTime> loggedAt,
  Value<int> rowid,
});

class $$LocalPrayerLogsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPrayerLogsTable> {
  $$LocalPrayerLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dateStr => $composableBuilder(
      column: $table.dateStr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get prayer => $composableBuilder(
      column: $table.prayer, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
      column: $table.loggedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalPrayerLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPrayerLogsTable> {
  $$LocalPrayerLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dateStr => $composableBuilder(
      column: $table.dateStr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prayer => $composableBuilder(
      column: $table.prayer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
      column: $table.loggedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalPrayerLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPrayerLogsTable> {
  $$LocalPrayerLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dateStr =>
      $composableBuilder(column: $table.dateStr, builder: (column) => column);

  GeneratedColumn<String> get prayer =>
      $composableBuilder(column: $table.prayer, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);
}

class $$LocalPrayerLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalPrayerLogsTable,
    LocalPrayerLog,
    $$LocalPrayerLogsTableFilterComposer,
    $$LocalPrayerLogsTableOrderingComposer,
    $$LocalPrayerLogsTableAnnotationComposer,
    $$LocalPrayerLogsTableCreateCompanionBuilder,
    $$LocalPrayerLogsTableUpdateCompanionBuilder,
    (
      LocalPrayerLog,
      BaseReferences<_$AppDatabase, $LocalPrayerLogsTable, LocalPrayerLog>
    ),
    LocalPrayerLog,
    PrefetchHooks Function()> {
  $$LocalPrayerLogsTableTableManager(
      _$AppDatabase db, $LocalPrayerLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPrayerLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPrayerLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPrayerLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> dateStr = const Value.absent(),
            Value<String> prayer = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> loggedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalPrayerLogsCompanion(
            dateStr: dateStr,
            prayer: prayer,
            status: status,
            loggedAt: loggedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String dateStr,
            required String prayer,
            required String status,
            Value<DateTime> loggedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalPrayerLogsCompanion.insert(
            dateStr: dateStr,
            prayer: prayer,
            status: status,
            loggedAt: loggedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalPrayerLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalPrayerLogsTable,
    LocalPrayerLog,
    $$LocalPrayerLogsTableFilterComposer,
    $$LocalPrayerLogsTableOrderingComposer,
    $$LocalPrayerLogsTableAnnotationComposer,
    $$LocalPrayerLogsTableCreateCompanionBuilder,
    $$LocalPrayerLogsTableUpdateCompanionBuilder,
    (
      LocalPrayerLog,
      BaseReferences<_$AppDatabase, $LocalPrayerLogsTable, LocalPrayerLog>
    ),
    LocalPrayerLog,
    PrefetchHooks Function()>;
typedef $$LocalQuranBookmarksTableCreateCompanionBuilder
    = LocalQuranBookmarksCompanion Function({
  required int surahNumber,
  required int ayahNumber,
  Value<String> note,
  Value<DateTime> savedAt,
  Value<int> rowid,
});
typedef $$LocalQuranBookmarksTableUpdateCompanionBuilder
    = LocalQuranBookmarksCompanion Function({
  Value<int> surahNumber,
  Value<int> ayahNumber,
  Value<String> note,
  Value<DateTime> savedAt,
  Value<int> rowid,
});

class $$LocalQuranBookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $LocalQuranBookmarksTable> {
  $$LocalQuranBookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get surahNumber => $composableBuilder(
      column: $table.surahNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ayahNumber => $composableBuilder(
      column: $table.ayahNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
      column: $table.savedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalQuranBookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalQuranBookmarksTable> {
  $$LocalQuranBookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get surahNumber => $composableBuilder(
      column: $table.surahNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ayahNumber => $composableBuilder(
      column: $table.ayahNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
      column: $table.savedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalQuranBookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalQuranBookmarksTable> {
  $$LocalQuranBookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get surahNumber => $composableBuilder(
      column: $table.surahNumber, builder: (column) => column);

  GeneratedColumn<int> get ayahNumber => $composableBuilder(
      column: $table.ayahNumber, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$LocalQuranBookmarksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalQuranBookmarksTable,
    LocalQuranBookmark,
    $$LocalQuranBookmarksTableFilterComposer,
    $$LocalQuranBookmarksTableOrderingComposer,
    $$LocalQuranBookmarksTableAnnotationComposer,
    $$LocalQuranBookmarksTableCreateCompanionBuilder,
    $$LocalQuranBookmarksTableUpdateCompanionBuilder,
    (
      LocalQuranBookmark,
      BaseReferences<_$AppDatabase, $LocalQuranBookmarksTable,
          LocalQuranBookmark>
    ),
    LocalQuranBookmark,
    PrefetchHooks Function()> {
  $$LocalQuranBookmarksTableTableManager(
      _$AppDatabase db, $LocalQuranBookmarksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalQuranBookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalQuranBookmarksTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalQuranBookmarksTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> surahNumber = const Value.absent(),
            Value<int> ayahNumber = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<DateTime> savedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalQuranBookmarksCompanion(
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
            note: note,
            savedAt: savedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int surahNumber,
            required int ayahNumber,
            Value<String> note = const Value.absent(),
            Value<DateTime> savedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalQuranBookmarksCompanion.insert(
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
            note: note,
            savedAt: savedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalQuranBookmarksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalQuranBookmarksTable,
    LocalQuranBookmark,
    $$LocalQuranBookmarksTableFilterComposer,
    $$LocalQuranBookmarksTableOrderingComposer,
    $$LocalQuranBookmarksTableAnnotationComposer,
    $$LocalQuranBookmarksTableCreateCompanionBuilder,
    $$LocalQuranBookmarksTableUpdateCompanionBuilder,
    (
      LocalQuranBookmark,
      BaseReferences<_$AppDatabase, $LocalQuranBookmarksTable,
          LocalQuranBookmark>
    ),
    LocalQuranBookmark,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PrayerTimesCacheTableTableManager get prayerTimesCache =>
      $$PrayerTimesCacheTableTableManager(_db, _db.prayerTimesCache);
  $$QuranSurahCacheTableTableManager get quranSurahCache =>
      $$QuranSurahCacheTableTableManager(_db, _db.quranSurahCache);
  $$LocalPrayerLogsTableTableManager get localPrayerLogs =>
      $$LocalPrayerLogsTableTableManager(_db, _db.localPrayerLogs);
  $$LocalQuranBookmarksTableTableManager get localQuranBookmarks =>
      $$LocalQuranBookmarksTableTableManager(_db, _db.localQuranBookmarks);
}
