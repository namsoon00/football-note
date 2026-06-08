import '../entities/training_entry.dart';

abstract class TrainingRepository {
  Stream<List<TrainingEntry>> watchAll();
  Stream<List<TrainingEntry>> watchRange(
    DateTime startInclusive,
    DateTime endExclusive,
  );
  Future<List<TrainingEntry>> getAll();
  Future<List<TrainingEntry>> getRange(
    DateTime startInclusive,
    DateTime endExclusive,
  );
  Future<List<TrainingEntry>> getRecent({
    required int limit,
    bool includeMatches = true,
  });
  Stream<List<TrainingEntry>> watchRecent({
    required int limit,
    bool includeMatches = true,
  });
  Future<void> add(TrainingEntry entry);
  Future<void> update(int key, TrainingEntry entry);
  Future<void> delete(TrainingEntry entry);
}
