import 'dart:convert';

import '../domain/repositories/option_repository.dart';
import 'sport_scoped_storage.dart';

enum RunningSprintDistance {
  tenMeters(10),
  twentyMeters(20),
  thirtyMeters(30);

  final int meters;

  const RunningSprintDistance(this.meters);
}

enum RunningGrowthBadge {
  firstRun,
  recordBreaker,
  threeDaySpark,
  allRounder,
}

class RunningSprintRecord {
  final String id;
  final RunningSprintDistance distance;
  final double seconds;
  final DateTime recordedAt;

  const RunningSprintRecord({
    required this.id,
    required this.distance,
    required this.seconds,
    required this.recordedAt,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'distance': distance.name,
      'seconds': seconds,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory RunningSprintRecord.fromMap(Map<String, dynamic> map) {
    return RunningSprintRecord(
      id: map['id']?.toString() ?? '',
      distance: _distanceByName(
        map['distance']?.toString(),
        RunningSprintDistance.twentyMeters,
      ),
      seconds: _doubleValue(map['seconds']),
      recordedAt: DateTime.tryParse(map['recordedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class RunningRecordDelta {
  final RunningSprintRecord latest;
  final RunningSprintRecord previousBest;
  final double secondsImproved;

  const RunningRecordDelta({
    required this.latest,
    required this.previousBest,
    required this.secondsImproved,
  });

  bool get isPersonalBest => secondsImproved > 0;
}

class RunningGrowthSnapshot {
  final List<RunningSprintRecord> records;
  final DateTime now;

  const RunningGrowthSnapshot({
    required this.records,
    required this.now,
  });

  bool get hasRecords => records.isNotEmpty;

  int get totalAttempts => records.length;

  int get completedDistanceCount {
    return {
      for (final record in records) record.distance,
    }.length;
  }

  int get currentStreakDays {
    final recordDays = {
      for (final record in records) _dateOnly(record.recordedAt),
    };
    var cursor = _dateOnly(now);
    var streak = 0;
    while (recordDays.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  RunningSprintRecord? bestFor(RunningSprintDistance distance) {
    final distanceRecords = _recordsForDistance(distance);
    if (distanceRecords.isEmpty) return null;
    return distanceRecords.reduce(
      (best, record) => record.seconds < best.seconds ? record : best,
    );
  }

  RunningSprintRecord? latestFor(RunningSprintDistance distance) {
    final distanceRecords = _recordsForDistance(distance);
    if (distanceRecords.isEmpty) return null;
    return distanceRecords.reduce(
      (latest, record) =>
          record.recordedAt.isAfter(latest.recordedAt) ? record : latest,
    );
  }

  RunningRecordDelta? latestDeltaFor(RunningSprintDistance distance) {
    final latest = latestFor(distance);
    if (latest == null) return null;
    final previous = records
        .where(
          (record) =>
              record.distance == distance &&
              record.id != latest.id &&
              record.recordedAt.isBefore(latest.recordedAt),
        )
        .toList(growable: false);
    if (previous.isEmpty) return null;
    final previousBest = previous.reduce(
      (best, record) => record.seconds < best.seconds ? record : best,
    );
    return RunningRecordDelta(
      latest: latest,
      previousBest: previousBest,
      secondsImproved: previousBest.seconds - latest.seconds,
    );
  }

  List<RunningGrowthBadge> get earnedBadges {
    return <RunningGrowthBadge>[
      if (hasRecords) RunningGrowthBadge.firstRun,
      if (RunningSprintDistance.values.any(
        (distance) => latestDeltaFor(distance)?.isPersonalBest ?? false,
      ))
        RunningGrowthBadge.recordBreaker,
      if (currentStreakDays >= 3) RunningGrowthBadge.threeDaySpark,
      if (completedDistanceCount >= RunningSprintDistance.values.length)
        RunningGrowthBadge.allRounder,
    ];
  }

  List<RunningSprintRecord> _recordsForDistance(
      RunningSprintDistance distance) {
    return records
        .where((record) => record.distance == distance)
        .toList(growable: false);
  }
}

class RunningGrowthService {
  static const storageKey = 'running_growth_records_v1';
  static const maxStoredRecords = 80;

  final OptionRepository _options;
  final String? _sportId;

  const RunningGrowthService(this._options, {String? sportId})
      : _sportId = sportId;

  String get _storageKey => sportScopedOptionKey(
        _options,
        storageKey,
        sportId: _sportId,
      );

  RunningGrowthSnapshot snapshot({DateTime? now}) {
    return RunningGrowthSnapshot(
        records: allRecords(), now: now ?? DateTime.now());
  }

  List<RunningSprintRecord> allRecords() {
    final raw = _options.getValue<String>(_storageKey) ?? '[]';
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const <RunningSprintRecord>[];
    }
    if (decoded is! List) {
      return const <RunningSprintRecord>[];
    }
    final records = decoded
        .whereType<Map>()
        .map(
          (item) => RunningSprintRecord.fromMap(item.cast<String, dynamic>()),
        )
        .where(
          (record) =>
              record.id.isNotEmpty &&
              record.seconds.isFinite &&
              record.seconds > 0,
        )
        .toList(growable: false);
    records.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return List<RunningSprintRecord>.unmodifiable(records);
  }

  Future<RunningGrowthSnapshot> saveRecord({
    required RunningSprintDistance distance,
    required double seconds,
    DateTime? recordedAt,
  }) async {
    final sanitizedSeconds = _sanitizeSeconds(seconds);
    final timestamp = recordedAt ?? DateTime.now();
    final next = <RunningSprintRecord>[
      RunningSprintRecord(
        id: 'run-${timestamp.microsecondsSinceEpoch}-${distance.meters}',
        distance: distance,
        seconds: sanitizedSeconds,
        recordedAt: timestamp,
      ),
      ...allRecords(),
    ]..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final trimmed = next.take(maxStoredRecords).toList(growable: false);
    await _persist(trimmed);
    return RunningGrowthSnapshot(records: trimmed, now: timestamp);
  }

  Future<void> clear() async {
    await _persist(const <RunningSprintRecord>[]);
  }

  Future<void> _persist(List<RunningSprintRecord> records) async {
    final payload = jsonEncode(
      records.map((record) => record.toMap()).toList(growable: false),
    );
    await _options.setValue(_storageKey, payload);
  }
}

double _sanitizeSeconds(double seconds) {
  if (!seconds.isFinite || seconds <= 0) {
    throw ArgumentError.value(
        seconds, 'seconds', 'Record time must be positive.');
  }
  return double.parse(seconds.toStringAsFixed(2));
}

double _doubleValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

RunningSprintDistance _distanceByName(
  String? name,
  RunningSprintDistance fallback,
) {
  for (final distance in RunningSprintDistance.values) {
    if (distance.name == name) {
      return distance;
    }
  }
  return fallback;
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
