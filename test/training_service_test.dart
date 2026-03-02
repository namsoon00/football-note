import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/infrastructure/hive_training_repository.dart';
import 'package:football_note/application/training_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<TrainingEntry> box;
  late TrainingService service;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('football_note_service');
    Hive.init(tempDir.path);
    Hive.registerAdapter(TrainingEntryAdapter());
    box = await Hive.openBox<TrainingEntry>('training_entries');
    service = TrainingService(HiveTrainingRepository(box));
  });

  tearDownAll(() async {
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('watchEntries emits when add and delete', () async {
    final emissions = <List<TrainingEntry>>[];
    final sub = service.watchEntries().listen(emissions.add);

    final entry = TrainingEntry(
      date: DateTime(2024, 1, 1),
      durationMinutes: 60,
      intensity: 3,
      type: '기술',
      mood: 3,
      injury: false,
      notes: '',
      location: '학교 운동장',
    );

    await service.add(entry);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(emissions.isNotEmpty, isTrue);
    expect(emissions.last.length, 1);

    await service.delete(emissions.last.first);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(emissions.last.length, 0);

    await sub.cancel();
  });
}
