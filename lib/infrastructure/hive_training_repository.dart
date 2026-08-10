import 'dart:async';

import 'package:hive/hive.dart';

import '../domain/entities/training_entry.dart';
import '../domain/repositories/training_repository.dart';

class HiveTrainingRepository implements TrainingRepository {
  HiveTrainingRepository(
    this._box, {
    Box<dynamic>? indexBox,
  }) : _indexBox = indexBox {
    if (_indexBox != null) {
      _boxSubscription = _box.watch().listen(
        (event) {
          unawaited(_queueBoxEventForReadyIndex(event));
        },
        onError: (_) {
          _indexReady = false;
        },
      );
    }
  }

  static const int indexVersion = 1;
  static const String _metaKey = '__meta__';
  static const String _recentKey = 'recent';
  static const String _monthPrefix = 'month:';
  static const String _sourceBoxNameKey = 'sourceBoxName';
  static const String _versionKey = 'version';
  static const String _entryCountKey = 'entryCount';
  static const String _monthKeysKey = 'monthKeys';

  final Box<TrainingEntry> _box;
  final Box<dynamic>? _indexBox;
  final HiveTrainingRepositoryDebugCounters debugCounters =
      HiveTrainingRepositoryDebugCounters();
  StreamSubscription<BoxEvent>? _boxSubscription;
  bool _indexReady = false;
  Future<bool>? _indexReadiness;
  Future<void> _indexEventTail = Future<void>.value();

  static String indexBoxNameFor(String trainingBoxName) {
    return '${trainingBoxName}_query_index_v1';
  }

  static bool trainingEntryCompactionStrategy(
    int entries,
    int deletedEntries,
  ) {
    if (deletedEntries < 100) return false;
    return deletedEntries > entries * 0.25;
  }

  Future<void> ensureIndexReady() async {
    await _ensureIndexReady();
  }

  Future<void> dispose() async {
    await _boxSubscription?.cancel();
    _boxSubscription = null;
  }

  @override
  Stream<List<TrainingEntry>> watchAll() {
    return Stream<List<TrainingEntry>>.multi((controller) {
      var active = true;
      var keyedEntries = <dynamic, TrainingEntry>{};
      var tail = Future<void>.value();

      Future<void> emit() async {
        if (!active || controller.isClosed) return;
        controller.add(_entriesInHiveKeyOrder(keyedEntries));
      }

      Future<void> initialize() async {
        debugCounters.sourceScanCount += 1;
        final snapshot = _box.toMap();
        debugCounters.sourceEntryVisitCount += snapshot.length;
        keyedEntries = snapshot;
        await emit();
      }

      Future<void> applyAndEmit(BoxEvent event) async {
        if (event.deleted) {
          keyedEntries.remove(event.key);
        } else if (event.value is TrainingEntry) {
          keyedEntries[event.key] = event.value as TrainingEntry;
        } else {
          debugCounters.sourceScanCount += 1;
          final snapshot = _box.toMap();
          debugCounters.sourceEntryVisitCount += snapshot.length;
          keyedEntries = snapshot;
        }
        await emit();
      }

      void schedule(Future<void> Function() action) {
        tail = tail.then((_) => action()).catchError((Object error) {
          if (!active || controller.isClosed) return;
          controller.addError(error);
        });
      }

      schedule(initialize);
      final sub = _box.watch().listen((event) {
        schedule(() => applyAndEmit(event));
      });
      controller.onCancel = () async {
        active = false;
        await sub.cancel();
      };
    }, isBroadcast: true);
  }

  @override
  Stream<List<TrainingEntry>> watchRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    return Stream<List<TrainingEntry>>.multi((controller) {
      var active = true;
      var tail = Future<void>.value();

      Future<void> emit() async {
        final entries = await getRange(startInclusive, endExclusive);
        if (!active || controller.isClosed) return;
        controller.add(entries);
      }

      void schedule([BoxEvent? event]) {
        tail = tail.then((_) async {
          if (event != null) {
            await _queueBoxEventForReadyIndex(event);
          }
          await emit();
        }).catchError((Object error) {
          if (!active || controller.isClosed) return;
          controller.addError(error);
        });
      }

      schedule();
      final sub = _box.watch().listen(schedule);
      controller.onCancel = () async {
        active = false;
        await sub.cancel();
      };
    }, isBroadcast: true);
  }

  @override
  Stream<List<TrainingEntry>> watchRecent({
    required int limit,
    bool includeMatches = true,
    String? sportId,
  }) {
    return Stream<List<TrainingEntry>>.multi((controller) {
      var active = true;
      var tail = Future<void>.value();

      Future<void> emit() async {
        final entries = await getRecent(
          limit: limit,
          includeMatches: includeMatches,
          sportId: sportId,
        );
        if (!active || controller.isClosed) return;
        controller.add(entries);
      }

      void schedule([BoxEvent? event]) {
        tail = tail.then((_) async {
          if (event != null) {
            await _queueBoxEventForReadyIndex(event);
          }
          await emit();
        }).catchError((Object error) {
          if (!active || controller.isClosed) return;
          controller.addError(error);
        });
      }

      schedule();
      final sub = _box.watch().listen(schedule);
      controller.onCancel = () async {
        active = false;
        await sub.cancel();
      };
    }, isBroadcast: true);
  }

  @override
  Future<List<TrainingEntry>> getAll() async {
    debugCounters.sourceScanCount += 1;
    final entries = _box.values.toList(growable: false);
    debugCounters.sourceEntryVisitCount += entries.length;
    return entries
        .where((entry) => entry.deletedAt == null)
        .toList(growable: false);
  }

  @override
  Future<List<TrainingEntry>> getRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) async {
    if (!startInclusive.isBefore(endExclusive)) {
      return const <TrainingEntry>[];
    }
    if (await _ensureIndexReady()) {
      try {
        return await _entriesInRangeFromIndex(startInclusive, endExclusive);
      } on _StaleTrainingIndexException {
        if (await _rebuildReadyIndex()) {
          return _entriesInRangeFromReadyIndex(
            startInclusive,
            endExclusive,
          );
        }
      } catch (_) {
        _indexReady = false;
      }
    }
    return _entriesInRangeByFullScan(startInclusive, endExclusive);
  }

  @override
  Future<List<TrainingEntry>> getRecent({
    required int limit,
    bool includeMatches = true,
    String? sportId,
  }) async {
    if (limit <= 0) return const <TrainingEntry>[];
    if (await _ensureIndexReady()) {
      try {
        return await _recentEntriesFromIndex(
          limit: limit,
          includeMatches: includeMatches,
          sportId: sportId,
        );
      } on _StaleTrainingIndexException {
        if (await _rebuildReadyIndex()) {
          return _recentEntriesFromReadyIndex(
            limit: limit,
            includeMatches: includeMatches,
            sportId: sportId,
          );
        }
      } catch (_) {
        _indexReady = false;
      }
    }
    return _recentEntriesByFullScan(
      limit: limit,
      includeMatches: includeMatches,
      sportId: sportId,
    );
  }

  @override
  Future<void> add(TrainingEntry entry) async {
    final now = DateTime.now();
    final stored = entry.copyWithSyncMetadata(
      recordId: entry.effectiveRecordId,
      updatedAt: entry.updatedAt ?? now,
      revision: entry.revision < 1 ? 1 : entry.revision,
    );
    final key = await _box.add(stored);
    await _tryUpdateIndexAfterSourceWrite(
      () => _upsertIndexRecord(key, stored),
    );
  }

  @override
  Future<void> update(int key, TrainingEntry entry) async {
    final previous = _box.get(key);
    final stored = entry.copyWithSyncMetadata(
      recordId: previous?.effectiveRecordId ?? entry.effectiveRecordId,
      updatedAt: DateTime.now(),
      revision: (previous?.revision ?? entry.revision) + 1,
      originDeviceId: entry.originDeviceId.trim().isNotEmpty
          ? entry.originDeviceId
          : previous?.originDeviceId,
    );
    await _box.put(key, stored);
    await _tryUpdateIndexAfterSourceWrite(
      () => _upsertIndexRecord(key, stored),
    );
  }

  @override
  Future<void> delete(TrainingEntry entry) async {
    final key = entry.key;
    if (key == null) return;
    final deletedAt = DateTime.now();
    final tombstone = entry.copyWithSyncMetadata(
      recordId: entry.effectiveRecordId,
      updatedAt: deletedAt,
      revision: entry.revision + 1,
      deletedAt: deletedAt,
    );
    await _box.put(key, tombstone);
    await _tryUpdateIndexAfterSourceWrite(
      () => _removeIndexRecord(key),
    );
  }

  Future<bool> _ensureIndexReady() async {
    if (_indexBox == null) return false;
    if (_indexReady) return true;
    final inFlight = _indexReadiness;
    if (inFlight != null) return inFlight;

    final readiness = _validateOrRebuildIndex();
    _indexReadiness = readiness;
    try {
      return await readiness;
    } finally {
      if (identical(_indexReadiness, readiness)) {
        _indexReadiness = null;
      }
    }
  }

  Future<bool> _validateOrRebuildIndex() async {
    try {
      final expected = _sourceIndexSnapshot();
      if (_persistedIndexMatches(expected)) {
        _indexReady = true;
        return true;
      }
      await _writeIndexSnapshot(expected);
      debugCounters.indexRebuildCount += 1;
      _indexReady = true;
      return true;
    } catch (_) {
      _indexReady = false;
      return false;
    }
  }

  Future<bool> _rebuildReadyIndex() async {
    if (_indexBox == null) return false;
    try {
      await _writeIndexSnapshot(_sourceIndexSnapshot());
      debugCounters.indexRebuildCount += 1;
      _indexReady = true;
      return true;
    } catch (_) {
      _indexReady = false;
      return false;
    }
  }

  _TrainingIndexSnapshot _sourceIndexSnapshot() {
    debugCounters.sourceScanCount += 1;
    final source = _box.toMap();
    debugCounters.sourceEntryVisitCount += source.length;
    final records = <_TrainingEntryIndexRecord>[];
    source.forEach((key, entry) {
      if (entry.deletedAt != null) return;
      records.add(_TrainingEntryIndexRecord.fromEntry(key, entry));
    });
    return _TrainingIndexSnapshot.fromRecords(
      sourceBoxName: _box.name,
      records: records,
    );
  }

  bool _persistedIndexMatches(_TrainingIndexSnapshot expected) {
    final box = _indexBox;
    if (box == null) return false;
    final meta = box.get(_metaKey);
    if (meta is! Map) return false;
    if ((meta[_versionKey] as num?)?.toInt() != indexVersion) return false;
    if (meta[_sourceBoxNameKey] != _box.name) return false;
    if ((meta[_entryCountKey] as num?)?.toInt() != expected.records.length) {
      return false;
    }
    final monthKeys = (meta[_monthKeysKey] as List?)
            ?.map((item) => item.toString())
            .toList(growable: false) ??
        const <String>[];
    if (!_sameStringList(monthKeys, expected.monthKeys)) return false;
    if (!_sameRecordList(
        _readRecordList(box.get(_recentKey)), expected.recentRecords)) {
      return false;
    }
    for (final monthKey in expected.monthKeys) {
      if (!_sameRecordList(
        _readRecordList(box.get('$_monthPrefix$monthKey')),
        expected.monthRecords[monthKey] ?? const <_TrainingEntryIndexRecord>[],
      )) {
        return false;
      }
    }
    final persistedMonthKeys = box.keys
        .whereType<String>()
        .where((key) => key.startsWith(_monthPrefix))
        .map((key) => key.substring(_monthPrefix.length))
        .toList(growable: false)
      ..sort();
    return _sameStringList(persistedMonthKeys, expected.monthKeys);
  }

  Future<void> _writeIndexSnapshot(_TrainingIndexSnapshot snapshot) async {
    final box = _indexBox;
    if (box == null) return;
    await box.clear();
    final values = <dynamic, dynamic>{
      _recentKey: snapshot.recentRecords
          .map((record) => record.toMap())
          .toList(growable: false),
    };
    for (final monthKey in snapshot.monthKeys) {
      values['$_monthPrefix$monthKey'] = snapshot.monthRecords[monthKey]
              ?.map((record) => record.toMap())
              .toList(growable: false) ??
          const <Map<String, dynamic>>[];
    }
    await box.putAll(values);
    await _writeMeta(
      entryCount: snapshot.records.length,
      monthKeys: snapshot.monthKeys,
    );
  }

  Future<void> _writeMeta({
    required int entryCount,
    required List<String> monthKeys,
  }) async {
    final box = _indexBox;
    if (box == null) return;
    await box.put(_metaKey, <String, dynamic>{
      _versionKey: indexVersion,
      _sourceBoxNameKey: _box.name,
      _entryCountKey: entryCount,
      _monthKeysKey: monthKeys,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> _tryUpdateIndexAfterSourceWrite(
    Future<void> Function() action,
  ) async {
    if (_indexBox == null || !_indexReady) return;
    try {
      await action();
    } catch (_) {
      _indexReady = false;
    }
  }

  Future<void> _applyBoxEventToReadyIndex(BoxEvent event) async {
    if (_indexBox == null || !_indexReady) return;
    try {
      if (event.deleted) {
        await _removeIndexRecord(event.key);
      } else if (event.value is TrainingEntry) {
        await _upsertIndexRecord(event.key, event.value as TrainingEntry);
      } else {
        _indexReady = false;
      }
    } catch (_) {
      _indexReady = false;
    }
  }

  Future<void> _queueBoxEventForReadyIndex(BoxEvent event) {
    final next = _indexEventTail.then((_) => _applyBoxEventToReadyIndex(event));
    _indexEventTail = next.catchError((_) {});
    return next;
  }

  Future<void> _upsertIndexRecord(dynamic key, TrainingEntry entry) async {
    final box = _indexBox;
    if (box == null) return;
    if (entry.deletedAt != null) {
      await _removeIndexRecord(key);
      return;
    }
    final record = _TrainingEntryIndexRecord.fromEntry(key, entry);
    final recent = _readRecordList(box.get(_recentKey))
      ..removeWhere((item) => item.key == key)
      ..add(record)
      ..sort(_compareRecentRecords);
    final monthKeys = _monthKeysFromMeta();
    for (final monthKey in monthKeys.toList(growable: false)) {
      final boxKey = '$_monthPrefix$monthKey';
      final records = _readRecordList(box.get(boxKey))
        ..removeWhere((item) => item.key == key);
      if (records.isEmpty) {
        await box.delete(boxKey);
        monthKeys.remove(monthKey);
      } else {
        await box.put(
          boxKey,
          records.map((item) => item.toMap()).toList(growable: false),
        );
      }
    }
    final monthKey = _monthKeyForDate(entry.date);
    final monthRecords = _readRecordList(box.get('$_monthPrefix$monthKey'))
      ..removeWhere((item) => item.key == key)
      ..add(record)
      ..sort(_compareDateRecords);
    if (!monthKeys.contains(monthKey)) {
      monthKeys.add(monthKey);
      monthKeys.sort();
    }
    await box.put(
      _recentKey,
      recent.map((item) => item.toMap()).toList(growable: false),
    );
    await box.put(
      '$_monthPrefix$monthKey',
      monthRecords.map((item) => item.toMap()).toList(growable: false),
    );
    await _writeMeta(entryCount: recent.length, monthKeys: monthKeys);
  }

  Future<void> _removeIndexRecord(dynamic key) async {
    final box = _indexBox;
    if (box == null) return;
    final recent = _readRecordList(box.get(_recentKey))
      ..removeWhere((item) => item.key == key);
    final monthKeys = _monthKeysFromMeta();
    for (final monthKey in monthKeys.toList(growable: false)) {
      final boxKey = '$_monthPrefix$monthKey';
      final records = _readRecordList(box.get(boxKey))
        ..removeWhere((item) => item.key == key);
      if (records.isEmpty) {
        await box.delete(boxKey);
        monthKeys.remove(monthKey);
      } else {
        await box.put(
          boxKey,
          records.map((item) => item.toMap()).toList(growable: false),
        );
      }
    }
    await box.put(
      _recentKey,
      recent.map((item) => item.toMap()).toList(growable: false),
    );
    await _writeMeta(entryCount: recent.length, monthKeys: monthKeys);
  }

  Future<List<TrainingEntry>> _entriesInRangeFromIndex(
    DateTime startInclusive,
    DateTime endExclusive,
  ) async {
    try {
      return _entriesInRangeFromReadyIndex(startInclusive, endExclusive);
    } on _StaleTrainingIndexException {
      rethrow;
    } catch (_) {
      throw const _StaleTrainingIndexException();
    }
  }

  List<TrainingEntry> _entriesInRangeFromReadyIndex(
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    final box = _indexBox;
    if (box == null) return const <TrainingEntry>[];
    final startMicros = startInclusive.microsecondsSinceEpoch;
    final endMicros = endExclusive.microsecondsSinceEpoch;
    final entries = <TrainingEntry>[];
    for (final monthKey in _monthKeysForRange(startInclusive, endExclusive)) {
      final records = _readRecordList(box.get('$_monthPrefix$monthKey'));
      for (final record in records) {
        debugCounters.indexRecordVisitCount += 1;
        if (record.dateMicros < startMicros || record.dateMicros >= endMicros) {
          continue;
        }
        final entry = _entryForRecord(record);
        if (entry == null ||
            entry.date.microsecondsSinceEpoch != record.dateMicros ||
            entry.createdAt.microsecondsSinceEpoch != record.createdAtMicros ||
            entry.sportId != record.sportId ||
            entry.isMatch != record.isMatch) {
          throw const _StaleTrainingIndexException();
        }
        if (!entry.date.isBefore(startInclusive) &&
            entry.date.isBefore(endExclusive)) {
          entries.add(entry);
        }
      }
    }
    entries.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return _compareHiveKeys(a.key, b.key);
    });
    return entries;
  }

  Future<List<TrainingEntry>> _recentEntriesFromIndex({
    required int limit,
    required bool includeMatches,
    required String? sportId,
  }) async {
    try {
      return _recentEntriesFromReadyIndex(
        limit: limit,
        includeMatches: includeMatches,
        sportId: sportId,
      );
    } on _StaleTrainingIndexException {
      rethrow;
    } catch (_) {
      throw const _StaleTrainingIndexException();
    }
  }

  List<TrainingEntry> _recentEntriesFromReadyIndex({
    required int limit,
    required bool includeMatches,
    required String? sportId,
  }) {
    final box = _indexBox;
    if (box == null || limit <= 0) return const <TrainingEntry>[];
    final records = _readRecordList(box.get(_recentKey));
    final entries = <TrainingEntry>[];
    for (final record in records) {
      debugCounters.indexRecordVisitCount += 1;
      if (sportId != null && record.sportId != sportId) continue;
      if (!includeMatches && record.isMatch) continue;
      final entry = _entryForRecord(record);
      if (entry == null ||
          entry.date.microsecondsSinceEpoch != record.dateMicros ||
          entry.createdAt.microsecondsSinceEpoch != record.createdAtMicros ||
          entry.sportId != record.sportId ||
          entry.isMatch != record.isMatch) {
        throw const _StaleTrainingIndexException();
      }
      entries.add(entry);
      if (entries.length >= limit) break;
    }
    return entries;
  }

  TrainingEntry? _entryForRecord(_TrainingEntryIndexRecord record) {
    debugCounters.trainingEntryFetchCount += 1;
    final entry = _box.get(record.key);
    return entry?.deletedAt == null ? entry : null;
  }

  List<TrainingEntry> _entriesInRangeByFullScan(
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    debugCounters.sourceScanCount += 1;
    final entries = <TrainingEntry>[];
    for (final entry in _box.values) {
      debugCounters.sourceEntryVisitCount += 1;
      if (entry.deletedAt != null) continue;
      if (!entry.date.isBefore(startInclusive) &&
          entry.date.isBefore(endExclusive)) {
        entries.add(entry);
      }
    }
    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  List<TrainingEntry> _recentEntriesByFullScan({
    required int limit,
    required bool includeMatches,
    String? sportId,
  }) {
    if (limit <= 0) return const <TrainingEntry>[];
    debugCounters.sourceScanCount += 1;
    final entries = <TrainingEntry>[];
    for (final entry in _box.values) {
      debugCounters.sourceEntryVisitCount += 1;
      if (entry.deletedAt != null) continue;
      if ((sportId == null || entry.sportId == sportId) &&
          (includeMatches || !entry.isMatch)) {
        entries.add(entry);
      }
    }
    entries.sort(TrainingEntry.compareByRecentCreated);
    if (entries.length <= limit) return entries;
    return entries.take(limit).toList(growable: false);
  }

  List<String> _monthKeysFromMeta() {
    final raw = _indexBox?.get(_metaKey);
    if (raw is! Map) return <String>[];
    return (raw[_monthKeysKey] as List?)
            ?.map((item) => item.toString())
            .toList(growable: true) ??
        <String>[];
  }

  List<_TrainingEntryIndexRecord> _readRecordList(dynamic raw) {
    if (raw is! List) return <_TrainingEntryIndexRecord>[];
    final records = <_TrainingEntryIndexRecord>[];
    for (final item in raw) {
      final record = _TrainingEntryIndexRecord.tryRead(item);
      if (record == null) {
        throw const _StaleTrainingIndexException();
      }
      records.add(record);
    }
    return records;
  }

  List<TrainingEntry> _entriesInHiveKeyOrder(
    Map<dynamic, TrainingEntry> keyedEntries,
  ) {
    final keys = keyedEntries.keys.toList(growable: false)
      ..sort(_compareHiveKeys);
    return keys
        .map((key) => keyedEntries[key])
        .whereType<TrainingEntry>()
        .where((entry) => entry.deletedAt == null)
        .toList(growable: false);
  }

  bool _sameRecordList(
    List<_TrainingEntryIndexRecord> a,
    List<_TrainingEntryIndexRecord> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _sameStringList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  List<String> _monthKeysForRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    if (!startInclusive.isBefore(endExclusive)) return const <String>[];
    final keys = <String>[];
    var cursor = DateTime(startInclusive.year, startInclusive.month);
    while (cursor.isBefore(endExclusive)) {
      keys.add(_monthKeyForDate(cursor));
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return keys;
  }

  static String _monthKeyForDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  static int _compareRecentRecords(
    _TrainingEntryIndexRecord a,
    _TrainingEntryIndexRecord b,
  ) {
    final createdCompare = b.createdAtMicros.compareTo(a.createdAtMicros);
    if (createdCompare != 0) return createdCompare;
    final dateCompare = b.dateMicros.compareTo(a.dateMicros);
    if (dateCompare != 0) return dateCompare;
    return _compareHiveKeys(b.key, a.key);
  }

  static int _compareDateRecords(
    _TrainingEntryIndexRecord a,
    _TrainingEntryIndexRecord b,
  ) {
    final dateCompare = a.dateMicros.compareTo(b.dateMicros);
    if (dateCompare != 0) return dateCompare;
    return _compareHiveKeys(a.key, b.key);
  }

  static int _compareHiveKeys(dynamic a, dynamic b) {
    if (a is int) {
      if (b is int) return a.compareTo(b);
      return -1;
    }
    if (a is String && b is String) return a.compareTo(b);
    if (b is int || b is String) return 1;
    return a.toString().compareTo(b.toString());
  }
}

class HiveTrainingRepositoryDebugCounters {
  int sourceScanCount = 0;
  int sourceEntryVisitCount = 0;
  int indexRecordVisitCount = 0;
  int trainingEntryFetchCount = 0;
  int indexRebuildCount = 0;

  void reset() {
    sourceScanCount = 0;
    sourceEntryVisitCount = 0;
    indexRecordVisitCount = 0;
    trainingEntryFetchCount = 0;
    indexRebuildCount = 0;
  }
}

class _TrainingIndexSnapshot {
  _TrainingIndexSnapshot({
    required this.sourceBoxName,
    required this.records,
    required this.recentRecords,
    required this.monthRecords,
    required this.monthKeys,
  });

  factory _TrainingIndexSnapshot.fromRecords({
    required String sourceBoxName,
    required List<_TrainingEntryIndexRecord> records,
  }) {
    final allRecords = records.toList(growable: false);
    final recentRecords = allRecords.toList(growable: false)
      ..sort(HiveTrainingRepository._compareRecentRecords);
    final monthRecords = <String, List<_TrainingEntryIndexRecord>>{};
    for (final record in allRecords) {
      final monthKey = HiveTrainingRepository._monthKeyForDate(
        DateTime.fromMicrosecondsSinceEpoch(record.dateMicros),
      );
      monthRecords
          .putIfAbsent(monthKey, () => <_TrainingEntryIndexRecord>[])
          .add(record);
    }
    for (final records in monthRecords.values) {
      records.sort(HiveTrainingRepository._compareDateRecords);
    }
    final monthKeys = monthRecords.keys.toList(growable: false)..sort();
    return _TrainingIndexSnapshot(
      sourceBoxName: sourceBoxName,
      records: allRecords,
      recentRecords: recentRecords,
      monthRecords: monthRecords,
      monthKeys: monthKeys,
    );
  }

  final String sourceBoxName;
  final List<_TrainingEntryIndexRecord> records;
  final List<_TrainingEntryIndexRecord> recentRecords;
  final Map<String, List<_TrainingEntryIndexRecord>> monthRecords;
  final List<String> monthKeys;
}

class _TrainingEntryIndexRecord {
  const _TrainingEntryIndexRecord({
    required this.key,
    required this.dateMicros,
    required this.createdAtMicros,
    required this.sportId,
    required this.isMatch,
  });

  factory _TrainingEntryIndexRecord.fromEntry(
    dynamic key,
    TrainingEntry entry,
  ) {
    return _TrainingEntryIndexRecord(
      key: key,
      dateMicros: entry.date.microsecondsSinceEpoch,
      createdAtMicros: entry.createdAt.microsecondsSinceEpoch,
      sportId: entry.sportId,
      isMatch: entry.isMatch,
    );
  }

  static _TrainingEntryIndexRecord? tryRead(dynamic raw) {
    if (raw is! Map) return null;
    final dateMicros = _readInt(raw['dateMicros']);
    final createdAtMicros = _readInt(raw['createdAtMicros']);
    final sportId = raw['sportId'];
    final isMatch = raw['isMatch'];
    if (!raw.containsKey('key') ||
        dateMicros == null ||
        createdAtMicros == null ||
        sportId is! String ||
        isMatch is! bool) {
      return null;
    }
    return _TrainingEntryIndexRecord(
      key: raw['key'],
      dateMicros: dateMicros,
      createdAtMicros: createdAtMicros,
      sportId: sportId,
      isMatch: isMatch,
    );
  }

  final dynamic key;
  final int dateMicros;
  final int createdAtMicros;
  final String sportId;
  final bool isMatch;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'key': key,
      'dateMicros': dateMicros,
      'createdAtMicros': createdAtMicros,
      'sportId': sportId,
      'isMatch': isMatch,
    };
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  @override
  bool operator ==(Object other) {
    return other is _TrainingEntryIndexRecord &&
        other.key == key &&
        other.dateMicros == dateMicros &&
        other.createdAtMicros == createdAtMicros &&
        other.sportId == sportId &&
        other.isMatch == isMatch;
  }

  @override
  int get hashCode {
    return Object.hash(
      key,
      dateMicros,
      createdAtMicros,
      sportId,
      isMatch,
    );
  }
}

class _StaleTrainingIndexException implements Exception {
  const _StaleTrainingIndexException();
}
