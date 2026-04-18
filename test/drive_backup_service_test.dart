import 'dart:io';
import 'dart:typed_data';

import 'package:football_note/application/drive_backup_service.dart';
import 'package:football_note/application/family_access_service.dart';
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
        opponentTeam: 'Blue FC',
        scoredGoals: 2,
        concededGoals: 1,
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
      'drive_last_backup': '2026-01-07T10:00:00.000',
      'local_pre_restore_backup': '{"should":"be excluded"}',
      'local_pre_restore_backup_at': '2026-01-01T00:00:00.000',
    });

    final backup = service.buildBackupForTesting();
    final backupOptions = backup['options'] as Map<String, dynamic>;
    final family = backup['family'] as Map<String, dynamic>;

    expect(backup['version'], 4);
    expect(backupOptions['profile_name'], 'Lee');
    expect(backupOptions['theme_mode'], 'dark');
    expect(backupOptions['reminder_enabled'], false);
    expect(backupOptions['default_duration'], 90);
    expect(backupOptions['type_options'], ['technique', 'tactics']);
    expect(backupOptions.containsKey('drive_last_backup'), isFalse);
    expect(backupOptions.containsKey('local_pre_restore_backup'), isFalse);
    expect(backupOptions.containsKey('local_pre_restore_backup_at'), isFalse);
    expect(family['updatedByRole'], 'child');
    expect(family['familyLayerOnly'], isFalse);

    await trainingBox.clear();
    await optionBox.clear();

    await service.restoreFromMapForTesting(backup);

    expect(trainingBox.length, 1);
    expect(trainingBox.values.first.durationMinutes, 75);
    expect(trainingBox.values.first.opponentTeam, 'Blue FC');
    expect(trainingBox.values.first.scoredGoals, 2);
    expect(trainingBox.values.first.concededGoals, 1);

    expect(optionBox.get('profile_name'), 'Lee');
    expect(optionBox.get('profile_height_cm'), '160.5');
    expect(optionBox.get('theme_mode'), 'dark');
    expect(optionBox.get('reminder_enabled'), false);
    expect(optionBox.get('reminder_time'), '07:30');
    expect(optionBox.get('default_duration'), 90);
    expect(optionBox.get('type_options'), ['technique', 'tactics']);
  });

  test('restore keeps local backup metadata unchanged', () async {
    await optionBox.put('drive_last_backup', '2026-02-01T08:00:00.000');
    final backup = <String, dynamic>{
      'version': 4,
      'createdAt': '2026-02-02T08:00:00.000',
      'entries': const [],
      'options': <String, dynamic>{
        'drive_last_backup': '2026-01-01T08:00:00.000',
        'theme_mode': 'dark',
      },
      'optionRecords': const [
        {
          'key': 'drive_last_backup',
          'value': '2026-01-01T08:00:00.000',
        },
        {
          'key': 'theme_mode',
          'value': 'dark',
        },
      ],
      'family': const <String, dynamic>{
        'updatedByRole': 'child',
        'familyLayerOnly': false,
      },
    };

    await service.restoreFromMapForTesting(backup);

    expect(optionBox.get('drive_last_backup'), '2026-02-01T08:00:00.000');
    expect(optionBox.get('theme_mode'), 'dark');
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
    await optionBox.put(405, 123);

    final backup = service.buildBackupForTesting();
    await optionBox.clear();

    await service.restoreFromMapForTesting(backup);

    expect(optionBox.get(404), 'legacy_key_data');
    expect(optionBox.get(405), 123);
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

  test('parent merge keeps remote entries and updates family layer only',
      () async {
    await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
    await optionBox.put(FamilyAccessService.parentNameKey, 'Dad');
    await optionBox.put(FamilyAccessService.childNameKey, 'Minjun');
    await optionBox.put(
      FamilyAccessService.messagesKey,
      <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'local-1',
          'authorRole': 'parent',
          'authorName': 'Dad',
          'kind': 'feedback',
          'body': 'Nice effort today.',
          'createdAt': '2026-04-18T09:00:00.000',
        },
      ],
    );
    await optionBox.put(
      'player_custom_reward_names_v1',
      <String, String>{'3': 'New boots'},
    );
    await optionBox.put('profile_name', 'Parent local stale value');

    final remote = <String, dynamic>{
      'version': 3,
      'createdAt': '2026-04-18T08:00:00.000',
      'entries': <Map<String, dynamic>>[
        <String, dynamic>{
          'date': '2026-04-18T00:00:00.000',
          'createdAt': '2026-04-18T08:10:00.000',
          'durationMinutes': 75,
          'intensity': 4,
          'type': 'dribble',
          'mood': 4,
          'injury': false,
          'notes': 'remote child data',
          'location': 'main field',
          'program': 'Finishing',
          'drills': '',
          'club': '',
          'injuryPart': '',
          'rehab': false,
          'goal': '',
          'feedback': '',
          'imagePath': '',
          'imagePaths': <String>[],
          'status': 'normal',
          'liftingByPart': <String, int>{},
          'goalFocuses': <String>[],
          'goodPoints': '',
          'improvements': '',
          'nextGoal': '',
          'jumpRopeCount': 0,
          'jumpRopeMinutes': 0,
          'jumpRopeEnabled': false,
          'jumpRopeNote': '',
          'breakfastDone': false,
          'breakfastRiceBowls': 0,
          'lunchDone': false,
          'lunchRiceBowls': 0,
          'dinnerDone': false,
          'dinnerRiceBowls': 0,
        },
      ],
      'options': <String, dynamic>{
        'profile_name': 'Real child profile',
        FamilyAccessService.messagesKey: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'old-1',
            'authorRole': 'child',
            'authorName': 'Minjun',
            'kind': 'note',
            'body': 'Old note',
            'createdAt': '2026-04-17T09:00:00.000',
          },
        ],
        'player_custom_reward_names_v1': <String, String>{'2': 'Ball'},
      },
      'optionRecords': <Map<String, dynamic>>[
        <String, dynamic>{
          'key': FamilyAccessService.messagesKey,
          'value': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'old-1',
              'authorRole': 'child',
              'authorName': 'Minjun',
              'kind': 'note',
              'body': 'Old note',
              'createdAt': '2026-04-17T09:00:00.000',
            },
          ]
        },
        <String, dynamic>{'key': 'profile_name', 'value': 'Real child profile'},
        <String, dynamic>{
          'key': 'player_custom_reward_names_v1',
          'value': <String, String>{'2': 'Ball'}
        },
      ],
    };

    final merged = service.mergeParentBackupForTesting(remote: remote);
    final mergedOptions = merged['options'] as Map<String, dynamic>;
    final family = merged['family'] as Map<String, dynamic>;

    expect((merged['entries'] as List), hasLength(1));
    expect(
      ((merged['entries'] as List).first as Map<String, dynamic>)['notes'],
      'remote child data',
    );
    expect(mergedOptions['profile_name'], 'Real child profile');
    expect(
      (mergedOptions[FamilyAccessService.messagesKey] as List).first['body'],
      'Nice effort today.',
    );
    expect(
      (mergedOptions['player_custom_reward_names_v1'] as Map)['3'],
      'New boots',
    );
    expect(family['updatedByRole'], 'parent');
    expect(family['familyLayerOnly'], isTrue);
  });
}
