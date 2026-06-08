import 'dart:async';
import 'package:hive/hive.dart';
import '../domain/entities/training_entry.dart';
import '../domain/repositories/training_repository.dart';

class HiveTrainingRepository implements TrainingRepository {
  final Box<TrainingEntry> _box;

  HiveTrainingRepository(this._box);

  @override
  Stream<List<TrainingEntry>> watchAll() {
    return Stream<List<TrainingEntry>>.multi((controller) {
      void emit() {
        if (!controller.isClosed) {
          controller.add(_box.values.toList());
        }
      }

      emit();
      final sub = _box.watch().listen((_) => emit());
      controller.onCancel = sub.cancel;
    }, isBroadcast: true);
  }

  @override
  Stream<List<TrainingEntry>> watchRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    return Stream<List<TrainingEntry>>.multi((controller) {
      void emit() {
        if (!controller.isClosed) {
          controller.add(_entriesInRange(startInclusive, endExclusive));
        }
      }

      emit();
      final sub = _box.watch().listen((_) => emit());
      controller.onCancel = sub.cancel;
    }, isBroadcast: true);
  }

  @override
  Stream<List<TrainingEntry>> watchRecent({
    required int limit,
    bool includeMatches = true,
  }) {
    return Stream<List<TrainingEntry>>.multi((controller) {
      void emit() {
        if (!controller.isClosed) {
          controller.add(
              _recentEntries(limit: limit, includeMatches: includeMatches));
        }
      }

      emit();
      final sub = _box.watch().listen((_) => emit());
      controller.onCancel = sub.cancel;
    }, isBroadcast: true);
  }

  @override
  Future<List<TrainingEntry>> getAll() async {
    return _box.values.toList();
  }

  @override
  Future<List<TrainingEntry>> getRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) async {
    return _entriesInRange(startInclusive, endExclusive);
  }

  @override
  Future<List<TrainingEntry>> getRecent({
    required int limit,
    bool includeMatches = true,
  }) async {
    return _recentEntries(limit: limit, includeMatches: includeMatches);
  }

  @override
  Future<void> add(TrainingEntry entry) async {
    await _box.add(entry);
  }

  @override
  Future<void> update(int key, TrainingEntry entry) async {
    await _box.put(key, entry);
  }

  @override
  Future<void> delete(TrainingEntry entry) async {
    await entry.delete();
  }

  List<TrainingEntry> _entriesInRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    return _box.values
        .where(
          (entry) =>
              !entry.date.isBefore(startInclusive) &&
              entry.date.isBefore(endExclusive),
        )
        .toList(growable: false)
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<TrainingEntry> _recentEntries({
    required int limit,
    required bool includeMatches,
  }) {
    if (limit <= 0) return const <TrainingEntry>[];
    final entries = _box.values
        .where((entry) => includeMatches || !entry.isMatch)
        .toList(growable: false)
      ..sort(TrainingEntry.compareByRecentCreated);
    if (entries.length <= limit) return entries;
    return entries.take(limit).toList(growable: false);
  }
}
