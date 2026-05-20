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
  Future<List<TrainingEntry>> getAll() async {
    return _box.values.toList();
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
}
