import 'dart:async';
import 'dart:convert';

import '../domain/entities/meal_entry.dart';
import '../domain/entities/training_entry.dart';
import '../domain/repositories/option_repository.dart';

class MealLogService {
  static const String storageKey = 'meal_logs_v1';
  static const double expectedBowlsPerDay = 3;

  final OptionRepository _options;
  final StreamController<List<MealEntry>> _controller =
      StreamController<List<MealEntry>>.broadcast();
  late final Stream<List<MealEntry>> _entriesStream =
      Stream<List<MealEntry>>.multi((controller) {
    controller.add(allEntries());
    final subscription = _controller.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  }, isBroadcast: true);

  MealLogService(this._options);

  Stream<List<MealEntry>> watchEntries() => _entriesStream;

  List<MealEntry> allEntries() {
    final raw = _options.getValue<String>(storageKey) ?? '[]';
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <MealEntry>[];
    return decoded
        .whereType<Map>()
        .map((item) => MealEntry.fromMap(item.cast<String, dynamic>()))
        .where((entry) => entry.hasRecords)
        .toList(growable: false)
      ..sort(MealEntry.compareByRecentCreated);
  }

  MealEntry? entryForDay(
    DateTime day, {
    List<MealEntry>? entries,
    List<TrainingEntry> legacyEntries = const <TrainingEntry>[],
  }) {
    final directEntries = entries ?? allEntries();
    final normalizedDay = _normalizeDay(day);
    for (final entry in directEntries) {
      if (_normalizeDay(entry.date) == normalizedDay) {
        return entry;
      }
    }
    final legacy = _legacyEntryForDay(normalizedDay, legacyEntries);
    if (legacy == null) return null;
    return MealEntry.fromTrainingEntry(legacy);
  }

  List<MealEntry> mergedEntries({
    List<MealEntry>? directEntries,
    List<TrainingEntry> legacyEntries = const <TrainingEntry>[],
  }) {
    final byDay = <String, MealEntry>{};
    for (final entry in legacyEntries) {
      if (!_hasLegacyMealData(entry)) continue;
      final normalizedDay = _normalizeDay(entry.date);
      final token = _dayToken(normalizedDay);
      final converted = MealEntry.fromTrainingEntry(entry);
      final previous = byDay[token];
      if (previous == null || converted.createdAt.isAfter(previous.createdAt)) {
        byDay[token] = converted;
      }
    }
    for (final entry in directEntries ?? allEntries()) {
      byDay[_dayToken(_normalizeDay(entry.date))] = entry;
    }
    final merged = byDay.values.where((entry) => entry.hasRecords).toList();
    merged.sort(MealEntry.compareByRecentCreated);
    return merged;
  }

  Future<void> save(MealEntry entry) async {
    final normalizedDay = _normalizeDay(entry.date);
    final nextEntries = allEntries().where((item) {
      return _normalizeDay(item.date) != normalizedDay;
    }).toList(growable: true);
    if (entry.hasRecords) {
      nextEntries.add(
        entry.copyWith(date: normalizedDay, createdAt: entry.createdAt),
      );
    }
    nextEntries.sort(MealEntry.compareByRecentCreated);
    await _persist(nextEntries);
  }

  Future<void> deleteDay(DateTime day) async {
    final normalizedDay = _normalizeDay(day);
    final nextEntries = allEntries().where((item) {
      return _normalizeDay(item.date) != normalizedDay;
    }).toList(growable: false);
    await _persist(nextEntries);
  }

  Future<void> _persist(List<MealEntry> entries) async {
    final payload = jsonEncode(
      entries.map((entry) => entry.toMap()).toList(growable: false),
    );
    await _options.setValue(storageKey, payload);
    _controller.add(List<MealEntry>.unmodifiable(entries));
  }

  TrainingEntry? _legacyEntryForDay(DateTime day, List<TrainingEntry> entries) {
    TrainingEntry? latest;
    for (final entry in entries) {
      if (!_hasLegacyMealData(entry)) continue;
      if (_normalizeDay(entry.date) != day) continue;
      if (latest == null || entry.createdAt.isAfter(latest.createdAt)) {
        latest = entry;
      }
    }
    return latest;
  }

  bool _hasLegacyMealData(TrainingEntry entry) {
    return entry.breakfastDone || entry.lunchDone || entry.dinnerDone;
  }

  DateTime _normalizeDay(DateTime day) {
    return DateTime(day.year, day.month, day.day);
  }

  String _dayToken(DateTime day) {
    return '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
  }
}
