import 'dart:async';

import '../domain/entities/training_entry.dart';
import '../domain/repositories/training_repository.dart';
import 'backup_service.dart';

class TrainingService {
  final TrainingRepository _repository;
  final BackupService? _backupService;

  TrainingService(this._repository, {BackupService? backupService})
      : _backupService = backupService;

  Stream<List<TrainingEntry>> watchEntries() => _repository.watchAll();

  Future<List<TrainingEntry>> allEntries() => _repository.getAll();

  Future<TrainingEntry?> latestEntry() async {
    final entries = await _repository.getAll();
    if (entries.isEmpty) return null;
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries.first;
  }

  Future<TrainingEntry?> latestWithGrowth() async {
    final entries = await _repository.getAll();
    if (entries.isEmpty) return null;
    entries.sort((a, b) => b.date.compareTo(a.date));
    for (final entry in entries) {
      if (entry.heightCm != null || entry.weightKg != null) {
        return entry;
      }
    }
    return null;
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
}
