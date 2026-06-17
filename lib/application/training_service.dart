import 'dart:async';

import '../domain/entities/sport_definition.dart';
import '../domain/entities/training_entry.dart';
import '../domain/repositories/training_repository.dart';
import 'backup_service.dart';

class TrainingService {
  final TrainingRepository _repository;
  final BackupService? _backupService;

  TrainingService(this._repository, {BackupService? backupService})
      : _backupService = backupService;

  Stream<List<TrainingEntry>> watchEntries() => _repository.watchAll();

  Stream<List<TrainingEntry>> watchEntriesInRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) =>
      _repository.watchRange(startInclusive, endExclusive);

  Stream<List<TrainingEntry>> watchRecentEntries({
    required int limit,
    bool includeMatches = true,
    String? sportId,
  }) =>
      _repository.watchRecent(
        limit: limit,
        includeMatches: includeMatches,
        sportId: _normalizedSportIdOrNull(sportId),
      );

  Future<List<TrainingEntry>> allEntries() => _repository.getAll();

  Future<List<TrainingEntry>> entriesInRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) =>
      _repository.getRange(startInclusive, endExclusive);

  Future<List<TrainingEntry>> recentEntries({
    required int limit,
    bool includeMatches = true,
    String? sportId,
  }) =>
      _repository.getRecent(
        limit: limit,
        includeMatches: includeMatches,
        sportId: _normalizedSportIdOrNull(sportId),
      );

  Future<TrainingEntry?> latestEntry() async {
    final entries = await _repository.getRecent(limit: 1);
    if (entries.isEmpty) return null;
    entries.sort(TrainingEntry.compareByRecentCreated);
    return entries.first;
  }

  Future<TrainingEntry?> latestTrainingEntry() async {
    final entries = await _repository.getRecent(
      limit: 1,
      includeMatches: false,
    );
    if (entries.isEmpty) return null;
    return entries.first;
  }

  Future<TrainingEntry?> latestWithGrowth() async {
    final entries = await _repository.getRecent(limit: 300);
    if (entries.isEmpty) return null;
    final recentGrowthEntry = _latestWithGrowth(entries);
    if (recentGrowthEntry != null || entries.length < 300) {
      return recentGrowthEntry;
    }
    return _latestWithGrowth(await _repository.getAll());
  }

  Future<void> add(TrainingEntry entry) async {
    await _repository.add(entry);
    _triggerBackgroundBackup();
  }

  Future<void> update(int key, TrainingEntry entry) async {
    await _repository.update(key, entry);
    _triggerBackgroundBackup();
  }

  Future<void> delete(TrainingEntry entry) async {
    await _repository.delete(entry);
    _triggerBackgroundBackup();
  }

  void _triggerBackgroundBackup() {
    final backup = _backupService;
    if (backup == null) return;
    unawaited(backup.backupIfSignedIn(requireAutoOnSave: true));
  }

  String? _normalizedSportIdOrNull(String? sportId) {
    final normalized = SportCatalog.normalizeSportId(sportId);
    if (sportId == null || sportId.trim().isEmpty) return null;
    return normalized;
  }

  TrainingEntry? _latestWithGrowth(List<TrainingEntry> entries) {
    final sortedEntries = entries.toList(growable: false)
      ..sort(TrainingEntry.compareByRecentCreated);
    for (final entry in sortedEntries) {
      if (entry.heightCm != null || entry.weightKg != null) {
        return entry;
      }
    }
    return null;
  }
}
