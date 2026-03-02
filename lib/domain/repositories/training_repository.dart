import '../entities/training_entry.dart';

abstract class TrainingRepository {
  Stream<List<TrainingEntry>> watchAll();
  Future<List<TrainingEntry>> getAll();
  Future<void> add(TrainingEntry entry);
  Future<void> update(int key, TrainingEntry entry);
  Future<void> delete(TrainingEntry entry);
}
