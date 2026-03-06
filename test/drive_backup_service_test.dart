import 'dart:io';
import 'dart:typed_data';

import 'package:football_note/application/drive_backup_service.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<TrainingEntry> trainingBox;
  late Box optionBox;
  late DriveBackupService service;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('football_note_backup');
    Hive.init(tempDir.path);
    Hive.registerAdapter(TrainingEntryAdapter());
    trainingBox = await Hive.openBox<TrainingEntry>('training_entries');
    optionBox = await Hive.openBox('options');
    service = DriveBackupService(trainingBox, optionBox);
  });

  tearDown(() async {
    await trainingBox.clear();
    await optionBox.clear();
  });

  tearDownAll(() async {
    await trainingBox.close();
    await optionBox.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('backs up and restores profile, settings, and option values', () async {
    await trainingBox.add(
      TrainingEntry(
        date: DateTime(2026, 1, 5),
        durationMinutes: 75,
        intensity: 4,
        type: 'dribble',
        mood: 5,
        injury: false,
        notes: 'focus touch',
        location: 'main field',
      ),
    );

    await optionBox.putAll({
      'profile_name': 'Lee',
      'profile_photo_url': 'data:image/png;base64,abc',
      'profile_birth_date': '2012-03-10T00:00:00.000',
      'profile_soccer_start_date': '2020-09-01T00:00:00.000',
      'profile_height_cm': '160.5',
      'profile_weight_kg': '48.2',
      'theme_mode': 'dark',
      'reminder_enabled': false,
      'reminder_time': '07:30',
      'default_duration': 90,
      'default_location': 'A Ground',
      'type_options': ['technique', 'tactics'],
      'drive_auto_daily': false,
      'drive_auto_on_save': true,
      'local_pre_restore_backup': '{"should":"be excluded"}',
      'local_pre_restore_backup_at': '2026-01-01T00:00:00.000',
    });

    final backup = service.buildBackupForTesting();
    final backupOptions = backup['options'] as Map<String, dynamic>;

    expect(backupOptions['profile_name'], 'Lee');
    expect(backupOptions['theme_mode'], 'dark');
    expect(backupOptions['reminder_enabled'], false);
    expect(backupOptions['default_duration'], 90);
    expect(backupOptions['type_options'], ['technique', 'tactics']);
    expect(backupOptions.containsKey('local_pre_restore_backup'), isFalse);
    expect(backupOptions.containsKey('local_pre_restore_backup_at'), isFalse);

    await trainingBox.clear();
    await optionBox.clear();

    await service.restoreFromMapForTesting(backup);

    expect(trainingBox.length, 1);
    expect(trainingBox.values.first.durationMinutes, 75);

    expect(optionBox.get('profile_name'), 'Lee');
    expect(optionBox.get('profile_height_cm'), '160.5');
    expect(optionBox.get('theme_mode'), 'dark');
    expect(optionBox.get('reminder_enabled'), false);
    expect(optionBox.get('reminder_time'), '07:30');
    expect(optionBox.get('default_duration'), 90);
    expect(optionBox.get('type_options'), ['technique', 'tactics']);
  });

  test('backs up and restores typed option values in v2 schema', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final timestamp = DateTime(2026, 1, 6, 7, 30);
    await optionBox.put('binary_blob', bytes);
    await optionBox.put('session_started_at', timestamp);

    final backup = service.buildBackupForTesting();
    await optionBox.clear();

    await service.restoreFromMapForTesting(backup);

    expect(optionBox.get('binary_blob'), bytes);
    expect(optionBox.get('session_started_at'), timestamp);
  });

  test('backs up and restores non-string option keys with v3 schema', () async {
    await optionBox.put(404, 'legacy_key_data');
    await optionBox.put(true, 123);

    final backup = service.buildBackupForTesting();
    await optionBox.clear();

    await service.restoreFromMapForTesting(backup);

    expect(optionBox.get(404), 'legacy_key_data');
    expect(optionBox.get(true), 123);
  });

  test('restores legacy v1 backup payload', () async {
    final legacy = <String, dynamic>{
      'version': 1,
      'createdAt': '2026-01-01T00:00:00.000',
      'entries': const [],
      'options': <String, dynamic>{
        'theme_mode': 'dark',
        'type_options': ['technique', 'tactics'],
      },
    };

    await service.restoreFromMapForTesting(legacy);

    expect(optionBox.get('theme_mode'), 'dark');
    expect(optionBox.get('type_options'), ['technique', 'tactics']);
  });
}
