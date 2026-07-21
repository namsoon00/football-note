import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:football_note/application/backup_asset_store_types.dart';
import 'package:football_note/application/coach_roster_service.dart';
import 'package:football_note/application/drive_connection_info.dart';
import 'package:football_note/application/drive_backup_service.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/meal_log_service.dart';
import 'package:football_note/application/player_level_service.dart';
import 'package:football_note/application/sprint_capture_calibration_service.dart';
import 'package:football_note/application/training_plan_reminder_service.dart';
import 'package:football_note/domain/entities/meal_entry.dart';
import 'package:football_note/domain/entities/sport_definition.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/infrastructure/hive_option_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

final String _legacyBackupFormat = String.fromCharCodes(
  const <int>[
    116,
    97,
    101,
    111,
    95,
    110,
    111,
    116,
    101,
    95,
    98,
    97,
    99,
    107,
    117,
    112,
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<TrainingEntry> trainingBox;
  late Box optionBox;
  late DriveBackupService service;
  late _FakeBackupAssetFileStore assetStore;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('teo_note_backup');
    Hive.init(tempDir.path);
    Hive.registerAdapter(TrainingEntryAdapter());
    trainingBox = await Hive.openBox<TrainingEntry>('training_entries');
    optionBox = await Hive.openBox('options');
  });

  setUp(() {
    assetStore = _FakeBackupAssetFileStore();
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
    );
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

  test('uses teo as the user-facing Drive backup folder name', () {
    expect(DriveBackupService.backupFolderName, 'teo');
    expect(
      DriveBackupService.backupDisplayPath,
      contains('Google Drive > teo >'),
    );
  });

  test('uses active player backup filenames in coach mode', () async {
    expect(service.backupFileNameForTesting(), 'teo_note_backup.json');

    await optionBox.put(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.coach.name,
    );
    await optionBox.put(CoachRosterService.activePlayerIdKey, 'minjun');

    expect(service.backupFileNameForTesting(), 'player_minjun_backup.json');
    expect(
      service.previousBackupFileNameForTesting(),
      'player_minjun_backup_previous.json',
    );
    expect(
      DriveBackupService.playerBackupDisplayPath('minjun'),
      'Google Drive > teo > player_minjun_backup.json',
    );
  });

  test('stores connected Drive metadata on active coach player', () async {
    await optionBox.put(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.coach.name,
    );
    final roster = CoachRosterService(HiveOptionRepository(optionBox));
    final player = await roster.addPlayer(displayName: 'Minjun');
    await roster.setActivePlayer(player.id);
    final coachDriveService = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'coach-minjun@example.com',
        displayName: 'Coach Drive',
        subjectId: 'coach-subject-minjun',
      ),
    );

    await coachDriveService.getDriveConnectionInfo();

    final updated = CoachRosterService(
      HiveOptionRepository(optionBox),
    ).loadState().activePlayer;
    expect(updated?.id, player.id);
    expect(updated?.driveEmail, 'coach-minjun@example.com');
    expect(updated?.driveLabel, 'Coach Drive · coach-minjun@example.com');
    expect(updated?.driveSubjectId, 'coach-subject-minjun');
  });

  test('backs up and restores player data while skipping local device settings',
      () async {
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
        yellowCards: 1,
        redCards: 1,
        matchKind: 'league',
        leagueTeamNames: const <String>['Blue FC', 'Red FC'],
        leaguePoints: 3,
        matchCompetitionName: 'Weekend League',
        matchStage: 'Round 2',
        isLesson: true,
        lessonDetail: 'Dribbling private lesson',
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
      'club_morning_workout_alert_enabled': true,
      'club_morning_workout_alert_time': '06:15',
      'club_morning_workout_alert_weekdays': [1, 3, 5],
      'default_duration': 90,
      'default_location': 'A Ground',
      'type_options': ['technique', 'tactics'],
      'drive_auto_daily': false,
      'drive_auto_on_save': true,
      'drive_last_backup': '2026-01-07T10:00:00.000',
      'local_pre_restore_backup': '{"should":"be excluded"}',
      'local_pre_restore_backup_at': '2026-01-01T00:00:00.000',
      SprintCaptureCalibrationProfileService.selectedProfileOptionKey:
          'responsive',
    });

    final backup = service.buildBackupForTesting();
    final backupOptions = backup['options'] as Map<String, dynamic>;
    final backedUpEntry =
        (backup['entries'] as List).single as Map<String, dynamic>;
    final family = backup['family'] as Map<String, dynamic>;

    expect(backup['format'], 'teo_note_backup');
    expect(backup['version'], 6);
    expect(backedUpEntry['sportId'], SportCatalog.footballId);
    expect(backedUpEntry['matchCompetitionName'], 'Weekend League');
    expect(backedUpEntry['matchStage'], 'Round 2');
    expect(backedUpEntry['leaguePoints'], 3);
    expect(backedUpEntry['yellowCards'], 1);
    expect(backedUpEntry['redCards'], 1);
    expect(backedUpEntry['isLesson'], isTrue);
    expect(backedUpEntry['lessonDetail'], 'Dribbling private lesson');
    expect(backupOptions['profile_name'], 'Lee');
    expect(backupOptions['default_duration'], 90);
    expect(backupOptions['type_options'], ['technique', 'tactics']);
    expect(backupOptions.containsKey('theme_mode'), isFalse);
    expect(backupOptions.containsKey('reminder_enabled'), isFalse);
    expect(backupOptions.containsKey('reminder_time'), isFalse);
    expect(
      backupOptions.containsKey(
        SprintCaptureCalibrationProfileService.selectedProfileOptionKey,
      ),
      isFalse,
    );
    expect(
      backupOptions.containsKey('club_morning_workout_alert_enabled'),
      isFalse,
    );
    expect(
      backupOptions.containsKey('club_morning_workout_alert_time'),
      isFalse,
    );
    expect(
      backupOptions.containsKey('club_morning_workout_alert_weekdays'),
      isFalse,
    );
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
    expect(trainingBox.values.first.sportId, SportCatalog.footballId);
    expect(trainingBox.values.first.opponentTeam, 'Blue FC');
    expect(trainingBox.values.first.scoredGoals, 2);
    expect(trainingBox.values.first.concededGoals, 1);
    expect(trainingBox.values.first.yellowCards, 1);
    expect(trainingBox.values.first.redCards, 1);
    expect(trainingBox.values.first.matchCompetitionName, 'Weekend League');
    expect(trainingBox.values.first.matchStage, 'Round 2');
    expect(trainingBox.values.first.leaguePoints, 3);
    expect(trainingBox.values.first.isLesson, isTrue);
    expect(trainingBox.values.first.lessonDetail, 'Dribbling private lesson');

    expect(optionBox.get('profile_name'), 'Lee');
    expect(optionBox.get('profile_height_cm'), '160.5');
    expect(optionBox.get('theme_mode'), isNull);
    expect(optionBox.get('reminder_enabled'), isNull);
    expect(optionBox.get('reminder_time'), isNull);
    expect(optionBox.get('default_duration'), 90);
    expect(optionBox.get('type_options'), ['technique', 'tactics']);
  });

  test('auto backup defaults to daily and on-save enabled', () {
    expect(service.isAutoDailyEnabled(), isTrue);
    expect(service.isAutoOnSaveEnabled(), isTrue);
  });

  test(
    'backs up option-backed app records used outside training entries',
    () async {
      await optionBox.putAll({
        'training_plans_v1': '[{"id":"plan-1"}]',
        'meal_logs_v1': '[{"id":"meal-1"}]',
        'training_boards_v1': '[{"id":"board-1"}]',
        'family_parent_training_feedback_v1': '{"items":[]}',
        CoachRosterService.rosterPlayersKey: <Map<String, Object>>[
          <String, Object>{'id': 'minjun', 'displayName': 'Minjun'},
        ],
        CoachRosterService.scopedOptionKey(
          FamilyAccessService.parentTrainingFeedbackKey,
          'minjun',
        ): <String, Object>{'entry-1': 'Nice first touch'},
        PlayerLevelService.customRewardNamesKey: <String, String>{
          '2': 'New boots',
        },
        CoachRosterService.scopedOptionKey(
          PlayerLevelService.customRewardNamesKey,
          'minjun',
        ): <String, String>{'2': 'Coach boots'},
        PlayerLevelService.claimedRewardLevelsKey: <int>[2],
        PlayerLevelService.rewardClaimMessagesKey: <Map<String, Object>>[
          <String, Object>{
            'id': 'reward-2-1',
            'level': 2,
            'rewardName': 'New boots',
            'claimedAt': '2026-04-20T08:00:00.000',
          },
        ],
        'skill_quiz_history_v1': '[{"id":"quiz-1"}]',
        'skill_quiz_pending_wrong_schedule_v2': '[{"id":"wrong-1"}]',
        'news_opened_items_v1': '[{"id":"news-1"}]',
        'home_hub_sections_v1': '{"sections":[]}',
      });

      final backup = service.buildBackupForTesting();
      final backupOptions = backup['options'] as Map<String, dynamic>;

      expect(backupOptions['training_plans_v1'], '[{"id":"plan-1"}]');
      expect(backupOptions['meal_logs_v1'], '[{"id":"meal-1"}]');
      expect(backupOptions['training_boards_v1'], '[{"id":"board-1"}]');
      expect(
        backupOptions['family_parent_training_feedback_v1'],
        '{"items":[]}',
      );
      expect(
        backupOptions[CoachRosterService.rosterPlayersKey],
        isA<List>(),
      );
      expect(
        backupOptions[CoachRosterService.scopedOptionKey(
          FamilyAccessService.parentTrainingFeedbackKey,
          'minjun',
        )],
        <String, Object>{'entry-1': 'Nice first touch'},
      );
      expect(
        backupOptions[PlayerLevelService.customRewardNamesKey],
        <String, String>{'2': 'New boots'},
      );
      expect(
        backupOptions[CoachRosterService.scopedOptionKey(
          PlayerLevelService.customRewardNamesKey,
          'minjun',
        )],
        <String, String>{'2': 'Coach boots'},
      );
      expect(backupOptions[PlayerLevelService.claimedRewardLevelsKey], <int>[
        2,
      ]);
      expect(
        backupOptions[PlayerLevelService.rewardClaimMessagesKey],
        isA<List>(),
      );
      expect(backupOptions['skill_quiz_history_v1'], '[{"id":"quiz-1"}]');
      expect(
        backupOptions['skill_quiz_pending_wrong_schedule_v2'],
        '[{"id":"wrong-1"}]',
      );
      expect(backupOptions['news_opened_items_v1'], '[{"id":"news-1"}]');
      expect(backupOptions['home_hub_sections_v1'], '{"sections":[]}');
    },
  );

  test('restore keeps local backup metadata unchanged', () async {
    await optionBox.put('drive_last_backup', '2026-02-01T08:00:00.000');
    final backup = <String, dynamic>{
      'version': 5,
      'createdAt': '2026-02-02T08:00:00.000',
      'entries': const [],
      'options': <String, dynamic>{
        'drive_last_backup': '2026-01-01T08:00:00.000',
        'default_location': 'Remote Ground',
        'theme_mode': 'dark',
      },
      'optionRecords': const [
        {'key': 'drive_last_backup', 'value': '2026-01-01T08:00:00.000'},
        {'key': 'default_location', 'value': 'Remote Ground'},
        {'key': 'theme_mode', 'value': 'dark'},
      ],
      'family': const <String, dynamic>{
        'updatedByRole': 'child',
        'familyLayerOnly': false,
      },
    };

    await service.restoreFromMapForTesting(backup);

    expect(optionBox.get('drive_last_backup'), '2026-02-01T08:00:00.000');
    expect(optionBox.get('default_location'), 'Remote Ground');
    expect(optionBox.get('theme_mode'), isNull);
  });

  test('restore preserves local device settings and notification caches',
      () async {
    await optionBox.put('theme_mode', 'dark');
    await optionBox.put('locale', 'ko');
    await optionBox.put(TrainingPlanReminderService.reminderIdsKey, <int>[77]);
    await optionBox.put('benchmark_synced_at_v2', 'local-cache');
    await optionBox.put('training_plan_last_reminder_minutes_before_v1', 60);
    await optionBox.put('club_morning_workout_alert_time', '06:15');
    await optionBox.put('club_morning_workout_alert_weekdays', <int>[1, 3, 5]);
    await optionBox.put('league_standings_last_selected_type_v1', 'epl');
    await optionBox.put('welcome_seen_v1', true);
    await optionBox.put('tab_quick_guide_seen_parent_mode_v1', true);
    await optionBox.put('tab_quick_guide_seen_v1_0', true);
    await optionBox.put(
      SprintCaptureCalibrationProfileService.selectedProfileOptionKey,
      'responsive',
    );

    await service.restoreFromMapForTesting(<String, dynamic>{
      'version': 6,
      'createdAt': '2026-02-02T08:00:00.000',
      'entries': const <dynamic>[],
      'options': <String, dynamic>{
        'profile_name': 'Remote player',
        'theme_mode': 'light',
        'locale': 'en',
        TrainingPlanReminderService.reminderIdsKey: <int>[1],
        'benchmark_synced_at_v2': 'remote-cache',
        'training_plan_last_reminder_minutes_before_v1': 15,
        'club_morning_workout_alert_time': '05:00',
        'club_morning_workout_alert_weekdays': <int>[2, 4],
        'league_standings_last_selected_type_v1': 'kLeague1',
        SprintCaptureCalibrationProfileService.selectedProfileOptionKey:
            'conservative',
      },
      'optionRecords': <Map<String, dynamic>>[
        <String, dynamic>{
          'key': 'profile_name',
          'value': 'Remote player',
        },
        <String, dynamic>{'key': 'theme_mode', 'value': 'light'},
        <String, dynamic>{'key': 'locale', 'value': 'en'},
        <String, dynamic>{
          'key': TrainingPlanReminderService.reminderIdsKey,
          'value': <int>[1],
        },
        <String, dynamic>{
          'key': 'benchmark_synced_at_v2',
          'value': 'remote-cache',
        },
        <String, dynamic>{
          'key': 'training_plan_last_reminder_minutes_before_v1',
          'value': 15,
        },
        <String, dynamic>{
          'key': 'club_morning_workout_alert_time',
          'value': '05:00',
        },
        <String, dynamic>{
          'key': 'club_morning_workout_alert_weekdays',
          'value': <int>[2, 4],
        },
        <String, dynamic>{
          'key': 'league_standings_last_selected_type_v1',
          'value': 'kLeague1',
        },
        <String, dynamic>{
          'key':
              SprintCaptureCalibrationProfileService.selectedProfileOptionKey,
          'value': 'conservative',
        },
      ],
      'family': const <String, dynamic>{
        'updatedByRole': 'child',
        'familyLayerOnly': false,
      },
    });

    expect(optionBox.get('profile_name'), 'Remote player');
    expect(optionBox.get('theme_mode'), 'dark');
    expect(optionBox.get('locale'), 'ko');
    expect(optionBox.get(TrainingPlanReminderService.reminderIdsKey), <int>[
      77,
    ]);
    expect(optionBox.get('benchmark_synced_at_v2'), 'local-cache');
    expect(optionBox.get('training_plan_last_reminder_minutes_before_v1'), 60);
    expect(optionBox.get('club_morning_workout_alert_time'), '06:15');
    expect(optionBox.get('club_morning_workout_alert_weekdays'), <int>[
      1,
      3,
      5,
    ]);
    expect(optionBox.get('league_standings_last_selected_type_v1'), 'epl');
    expect(optionBox.get('welcome_seen_v1'), isTrue);
    expect(optionBox.get('tab_quick_guide_seen_parent_mode_v1'), isTrue);
    expect(optionBox.get('tab_quick_guide_seen_v1_0'), isTrue);
    expect(
      optionBox.get(
        SprintCaptureCalibrationProfileService.selectedProfileOptionKey,
      ),
      'responsive',
    );
  });

  test('restore keeps local sport selection when remote omits startup sport',
      () async {
    await optionBox.put(
      SportCatalog.currentSportOptionKey,
      SportCatalog.basketballId,
    );

    await service.restoreFromMapForTesting(<String, dynamic>{
      'version': 6,
      'createdAt': '2026-02-02T08:00:00.000',
      'entries': const <dynamic>[],
      'options': const <String, dynamic>{'profile_name': 'Remote player'},
      'optionRecords': const <Map<String, dynamic>>[
        <String, dynamic>{'key': 'profile_name', 'value': 'Remote player'},
      ],
      'family': const <String, dynamic>{
        'updatedByRole': 'child',
        'familyLayerOnly': false,
      },
    });

    expect(
      optionBox.get(SportCatalog.currentSportOptionKey),
      SportCatalog.basketballId,
    );
  });

  test('restore uses remote sport selection when backup provides it', () async {
    await optionBox.put(
      SportCatalog.currentSportOptionKey,
      SportCatalog.basketballId,
    );

    await service.restoreFromMapForTesting(<String, dynamic>{
      'version': 6,
      'createdAt': '2026-02-02T08:00:00.000',
      'entries': const <dynamic>[],
      'options': const <String, dynamic>{
        SportCatalog.currentSportOptionKey: SportCatalog.tennisId,
      },
      'optionRecords': const <Map<String, dynamic>>[
        <String, dynamic>{
          'key': SportCatalog.currentSportOptionKey,
          'value': SportCatalog.tennisId,
        },
      ],
      'family': const <String, dynamic>{
        'updatedByRole': 'child',
        'familyLayerOnly': false,
      },
    });

    expect(
      optionBox.get(SportCatalog.currentSportOptionKey),
      SportCatalog.tennisId,
    );
  });

  test('backs up and restores typed option values in v2 schema', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final timestamp = DateTime(2026, 1, 6, 7, 30);
    await optionBox.put(
      PlayerLevelService.rewardClaimMessagesKey,
      <Map<String, Object>>[
        <String, Object>{
          'id': 'reward-typed',
          'claimedAt': timestamp,
          'payload': bytes,
        },
      ],
    );

    final backup = service.buildBackupForTesting();
    await optionBox.clear();

    await service.restoreFromMapForTesting(backup);

    final restored =
        optionBox.get(PlayerLevelService.rewardClaimMessagesKey) as List;
    final restoredItem = restored.single as Map;
    expect(restoredItem['claimedAt'], timestamp);
    expect(restoredItem['payload'], bytes);
  });

  test(
    'backs up and restores map option values with non-string keys',
    () async {
      await optionBox.put(
        PlayerLevelService.customRewardNamesKey,
        <int, String>{7: 'seven'},
      );
      await optionBox.put(PlayerLevelService.xpHistoryKey, <String, Object>{
        '__type': 'plain-user-data',
        'data': <int, String>{9: 'nine'},
      });

      final backup = service.buildBackupForTesting();
      await optionBox.clear();

      await service.restoreFromMapForTesting(backup);

      expect(
        optionBox.get(PlayerLevelService.customRewardNamesKey),
        <int, String>{7: 'seven'},
      );
      expect(optionBox.get(PlayerLevelService.xpHistoryKey), <String, Object>{
        '__type': 'plain-user-data',
        'data': <int, String>{9: 'nine'},
      });
    },
  );

  test('skips unknown and non-string option keys', () async {
    await optionBox.put(404, 'legacy_key_data');
    await optionBox.put(405, 123);
    await optionBox.put('experimental_temp', 'local experimental data');

    final backup = service.buildBackupForTesting();
    final backupOptions = backup['options'] as Map<String, dynamic>;
    final optionRecords = backup['optionRecords'] as List;

    expect(backupOptions.containsKey('experimental_temp'), isFalse);
    expect(
      optionRecords.any((record) => record is Map && record['key'] == 404),
      isFalse,
    );

    await optionBox.clear();

    await service.restoreFromMapForTesting(<String, dynamic>{
      'version': 6,
      'createdAt': '2026-01-01T00:00:00.000',
      'entries': const <dynamic>[],
      'options': const <String, dynamic>{
        'experimental_temp': 'remote experimental data',
        'profile_name': 'Remote player',
      },
      'optionRecords': const <Map<String, dynamic>>[
        <String, dynamic>{
          'key': 'experimental_temp',
          'value': 'remote experimental data',
        },
        <String, dynamic>{'key': 'profile_name', 'value': 'Remote player'},
        <String, dynamic>{'key': 404, 'value': 'remote legacy key'},
      ],
      'family': const <String, dynamic>{
        'updatedByRole': 'child',
        'familyLayerOnly': false,
      },
    });

    expect(optionBox.get('profile_name'), 'Remote player');
    expect(optionBox.get('experimental_temp'), isNull);
    expect(optionBox.get(404), isNull);
    expect(optionBox.get(405), isNull);
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

    expect(optionBox.get('theme_mode'), isNull);
    expect(optionBox.get('type_options'), ['technique', 'tactics']);
  });

  test('restores legacy entries without sport id as football', () async {
    final legacy = <String, dynamic>{
      'version': 5,
      'createdAt': '2026-01-01T00:00:00.000',
      'entries': <Map<String, dynamic>>[
        <String, dynamic>{
          'date': '2026-01-01T00:00:00.000',
          'createdAt': '2026-01-01T09:00:00.000',
          'durationMinutes': 60,
          'intensity': 3,
          'type': 'passing',
          'mood': 4,
          'injury': false,
          'notes': '',
          'location': 'main field',
        },
      ],
      'options': const <String, dynamic>{},
    };

    await service.restoreFromMapForTesting(legacy);

    expect(trainingBox.values.single.sportId, SportCatalog.footballId);
  });

  test('restores supported sport ids from backup entries', () async {
    final backup = <String, dynamic>{
      'version': 6,
      'createdAt': '2026-01-01T00:00:00.000',
      'entries': <Map<String, dynamic>>[
        <String, dynamic>{
          'date': '2026-01-01T00:00:00.000',
          'createdAt': '2026-01-01T09:00:00.000',
          'sportId': SportCatalog.tennisId,
          'durationMinutes': 60,
          'intensity': 3,
          'type': 'Serve',
          'mood': 4,
          'injury': false,
          'notes': '',
          'location': 'court',
        },
      ],
      'options': const <String, dynamic>{},
    };

    await service.restoreFromMapForTesting(backup);

    expect(trainingBox.values.single.sportId, SportCatalog.tennisId);
  });

  test('restores backups saved with previous internal format ids', () async {
    final footballNoteFormat = String.fromCharCodes(
      const <int>[
        102,
        111,
        111,
        116,
        98,
        97,
        108,
        108,
        95,
        110,
        111,
        116,
        101,
        95,
        98,
        97,
        99,
        107,
        117,
        112,
      ],
    );

    for (final format in <String>[footballNoteFormat, _legacyBackupFormat]) {
      await optionBox.clear();
      await service.restoreFromMapForTesting(<String, dynamic>{
        'format': format,
        'version': 6,
        'createdAt': '2026-01-01T00:00:00.000',
        'entries': const <dynamic>[],
        'options': const <String, dynamic>{'profile_name': 'teo'},
      });

      expect(optionBox.get('profile_name'), 'teo');
    }
  });

  test('rejects backups created by a newer schema version', () async {
    expect(
      () => service.restoreFromMapForTesting(<String, dynamic>{
        'format': 'teo_note_backup',
        'version': 999,
        'createdAt': '2026-01-01T00:00:00.000',
        'entries': const <dynamic>[],
        'options': const <String, dynamic>{},
      }),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          DriveBackupService.unsupportedBackupVersionErrorCode,
        ),
      ),
    );
  });

  test('rejects malformed backup payload maps', () async {
    expect(
      () => service.restoreFromMapForTesting(<String, dynamic>{
        'format': 'teo_note_backup',
        'version': 5,
        'createdAt': '2026-01-01T00:00:00.000',
        'entries': const <String, dynamic>{'unexpected': true},
        'options': const <String, dynamic>{},
      }),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          DriveBackupService.invalidBackupPayloadErrorCode,
        ),
      ),
    );
  });

  test(
    'parent restore applies child backup and keeps parent local flags',
    () async {
      await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
      await optionBox.put(FamilyAccessService.familyIdKey, 'family-1');
      await optionBox.put(FamilyAccessService.childNameKey, 'Local player');
      await optionBox.put(FamilyAccessService.parentNameKey, 'Local parent');
      await optionBox.put(
        DriveBackupService.sharedChildDriveEmailKey,
        'local-player@example.com',
      );
      await optionBox.put(
        DriveBackupService.sharedChildDriveLabelKey,
        'Local player · local-player@example.com',
      );
      await optionBox.put('player_custom_reward_names_v1', <String, String>{
        '2': 'Local ball',
      });
      await optionBox.put(
        FamilyAccessService.parentTrainingFeedbackKey,
        <String, dynamic>{
          'training_1': <String, dynamic>{'message': 'Local parent feedback'},
        },
      );
      await optionBox.put('profile_name', 'Local player profile');
      await optionBox.put(
        DriveBackupService.connectedDriveEmailLocalKey,
        'child@example.com',
      );
      await optionBox.put(
        DriveBackupService.connectedDriveLabelLocalKey,
        'Child Account',
      );
      await trainingBox.add(
        TrainingEntry(
          date: DateTime(2026, 4, 18),
          createdAt: DateTime(2026, 4, 18, 9),
          durationMinutes: 40,
          intensity: 3,
          type: 'passing',
          mood: 4,
          injury: false,
          notes: 'keep local player record',
          location: 'local ground',
        ),
      );

      final remote = <String, dynamic>{
        'version': 5,
        'createdAt': '2026-04-18T10:00:00.000',
        'entries': <Map<String, dynamic>>[
          <String, dynamic>{
            'date': '2026-04-18T00:00:00.000',
            'createdAt': '2026-04-18T08:10:00.000',
            'durationMinutes': 75,
            'intensity': 4,
            'type': 'dribble',
            'mood': 4,
            'injury': false,
            'notes': 'remote player record',
            'location': 'remote field',
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
          'profile_name': 'Remote player profile',
          FamilyAccessService.familyIdKey: 'family-1',
          FamilyAccessService.childNameKey: 'Remote player',
          FamilyAccessService.parentNameKey: 'Remote parent',
          DriveBackupService.sharedChildDriveEmailKey:
              'remote-player@example.com',
          DriveBackupService.sharedChildDriveLabelKey:
              'Remote player · remote-player@example.com',
          'player_custom_reward_names_v1': <String, String>{
            '4': 'Remote boots',
          },
          FamilyAccessService.parentTrainingFeedbackKey: <String, dynamic>{
            'training_1713427800000000': <String, dynamic>{
              'message': 'Remote parent feedback',
            },
          },
        },
        'optionRecords': <Map<String, dynamic>>[
          <String, dynamic>{
            'key': FamilyAccessService.familyIdKey,
            'value': 'family-1',
          },
          <String, dynamic>{
            'key': FamilyAccessService.childNameKey,
            'value': 'Remote player',
          },
          <String, dynamic>{
            'key': FamilyAccessService.parentNameKey,
            'value': 'Remote parent',
          },
          <String, dynamic>{
            'key': DriveBackupService.sharedChildDriveEmailKey,
            'value': 'remote-player@example.com',
          },
          <String, dynamic>{
            'key': DriveBackupService.sharedChildDriveLabelKey,
            'value': 'Remote player · remote-player@example.com',
          },
          <String, dynamic>{
            'key': 'player_custom_reward_names_v1',
            'value': <String, String>{'4': 'Remote boots'},
          },
          <String, dynamic>{
            'key': FamilyAccessService.parentTrainingFeedbackKey,
            'value': <String, dynamic>{
              'training_1713427800000000': <String, dynamic>{
                'message': 'Remote parent feedback',
              },
            },
          },
          <String, dynamic>{
            'key': 'profile_name',
            'value': 'Remote player profile',
          },
        ],
        'family': const <String, dynamic>{
          'familyId': 'family-1',
          'updatedByRole': 'child',
          'familyLayerOnly': false,
        },
      };

      await service.restoreFromMapForTesting(remote);

      expect(trainingBox.length, 1);
      expect(trainingBox.values.first.notes, 'remote player record');
      expect(optionBox.get('profile_name'), 'Remote player profile');
      expect(optionBox.get(FamilyAccessService.childNameKey), 'Remote player');
      expect(optionBox.get(FamilyAccessService.parentNameKey), 'Remote parent');
      expect(optionBox.get(FamilyAccessService.messagesKey), isNull);
      expect(
        (optionBox.get('player_custom_reward_names_v1') as Map)['4'],
        'Remote boots',
      );
      expect(
        (optionBox.get('player_custom_reward_names_v1') as Map).containsKey(
          '2',
        ),
        isFalse,
      );
      expect(
        ((optionBox.get(FamilyAccessService.parentTrainingFeedbackKey)
            as Map)['training_1713427800000000'] as Map)['message'],
        'Remote parent feedback',
      );
      expect(
        optionBox.get(DriveBackupService.sharedChildDriveEmailKey),
        'remote-player@example.com',
      );
      expect(
        optionBox.get(DriveBackupService.sharedChildDriveLabelKey),
        'Remote player · remote-player@example.com',
      );
      expect(
        optionBox.get(FamilyAccessService.currentRoleLocalKey),
        FamilyRole.parent.name,
      );
      expect(
        optionBox.get(DriveBackupService.connectedDriveEmailLocalKey),
        'child@example.com',
      );
      expect(
        optionBox.get(DriveBackupService.connectedDriveLabelLocalKey),
        'Child Account',
      );
    },
  );

  test(
    'parent restore replaces option-backed child data when remote omits it',
    () async {
      await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
      await optionBox.put(FamilyAccessService.familyIdKey, 'family-1');
      await optionBox.put('profile_name', 'Local child profile');
      await optionBox.put(PlayerLevelService.totalXpKey, 240);
      await optionBox.put(
        PlayerLevelService.xpHistoryKey,
        <Map<String, Object>>[
          <String, Object>{'deltaXp': 15, 'totalXp': 240},
        ],
      );
      await optionBox.put(PlayerLevelService.diaryCreatedDayKey, '2026-04-18');
      await optionBox.put(MealLogService.storageKey, '[{"id":"meal-local"}]');
      await optionBox.put(
        'custom_diary_entries_v3',
        '{"2026-04-18":{"body":"local diary"}}',
      );

      await service.restoreFromMapForTesting(<String, dynamic>{
        'version': 5,
        'createdAt': '2026-04-19T10:00:00.000',
        'entries': const <Map<String, dynamic>>[],
        'options': <String, dynamic>{
          FamilyAccessService.familyIdKey: 'family-1',
          FamilyAccessService.childNameKey: 'Remote player',
        },
        'family': const <String, dynamic>{
          'familyId': 'family-1',
          'updatedByRole': 'child',
          'familyLayerOnly': false,
        },
      });

      expect(optionBox.get('profile_name'), isNull);
      expect(optionBox.get(PlayerLevelService.totalXpKey), isNull);
      expect(optionBox.get(PlayerLevelService.xpHistoryKey), isNull);
      expect(optionBox.get(PlayerLevelService.diaryCreatedDayKey), isNull);
      expect(optionBox.get(MealLogService.storageKey), isNull);
      expect(optionBox.get('custom_diary_entries_v3'), isNull);
      expect(optionBox.get(FamilyAccessService.childNameKey), 'Remote player');
    },
  );

  test('parent restore uses remote critical options when present', () async {
    await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
    await optionBox.put(FamilyAccessService.familyIdKey, 'family-1');
    await optionBox.put(PlayerLevelService.totalXpKey, 240);
    await optionBox.put(MealLogService.storageKey, '[{"id":"meal-local"}]');

    await service.restoreFromMapForTesting(<String, dynamic>{
      'version': 5,
      'createdAt': '2026-04-19T10:00:00.000',
      'entries': const <Map<String, dynamic>>[],
      'options': <String, dynamic>{
        FamilyAccessService.familyIdKey: 'family-1',
        PlayerLevelService.totalXpKey: 0,
        MealLogService.storageKey: '[]',
      },
      'family': const <String, dynamic>{
        'familyId': 'family-1',
        'updatedByRole': 'child',
        'familyLayerOnly': false,
      },
    });

    expect(optionBox.get(PlayerLevelService.totalXpKey), 0);
    expect(optionBox.get(MealLogService.storageKey), '[]');
  });

  test(
    'account switch restore replaces stale diary and meal data and notifies meal listeners',
    () async {
      final optionRepository = HiveOptionRepository(optionBox);
      final mealLogService = MealLogService(optionRepository);
      final observedMeals = <List<MealEntry>>[];
      final mealSubscription = mealLogService.watchEntries().listen(
            observedMeals.add,
          );
      final dataSubscription = service.dataChanges().listen((_) {
        mealLogService.reloadFromStorage();
      });

      await mealLogService.save(
        MealEntry(
          date: DateTime(2026, 4, 18),
          breakfastRiceBowls: 1,
          lunchRiceBowls: 1,
        ),
      );
      await optionBox.put(
        'custom_diary_entries_v3',
        '{"2026-04-18":{"body":"local diary"}}',
      );
      await Future<void>.delayed(Duration.zero);
      expect(observedMeals.last, hasLength(1));

      await service.restoreFromMapForTesting(<String, dynamic>{
        'version': 5,
        'createdAt': '2026-04-19T10:00:00.000',
        'entries': const <Map<String, dynamic>>[],
        'options': <String, dynamic>{
          MealLogService.storageKey: '[]',
          'custom_diary_entries_v3': '{"2026-04-19":{"body":"remote diary"}}',
        },
        'family': const <String, dynamic>{
          'updatedByRole': 'child',
          'familyLayerOnly': false,
        },
      });
      await Future<void>.delayed(Duration.zero);

      expect(optionBox.get(MealLogService.storageKey), '[]');
      expect(
        optionBox.get('custom_diary_entries_v3'),
        '{"2026-04-19":{"body":"remote diary"}}',
      );
      expect(mealLogService.allEntries(), isEmpty);
      expect(observedMeals.last, isEmpty);

      await dataSubscription.cancel();
      await mealSubscription.cancel();
      await mealLogService.dispose();
    },
  );

  test('stores record mode drive account separately', () async {
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'player@example.com',
        displayName: 'Player',
        subjectId: 'player-subject',
      ),
    );

    await service.rememberRecordDriveConnection();

    expect(service.getSavedRecordDriveEmail(), 'player@example.com');
    expect(service.getSavedRecordDriveLabel(), 'Player · player@example.com');
    expect(
      optionBox.get(DriveBackupService.recordDriveSubjectLocalKey),
      'player-subject',
    );
  });

  test('stores parent mode drive account separately', () async {
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'parent@example.com',
        displayName: 'Parent',
        subjectId: 'parent-subject',
      ),
    );

    await service.rememberParentDriveConnection();

    expect(service.getSavedParentDriveEmail(), 'parent@example.com');
    expect(service.getSavedParentDriveLabel(), 'Parent · parent@example.com');
    expect(
      optionBox.get(DriveBackupService.parentDriveSubjectLocalKey),
      'parent-subject',
    );
  });

  test('backs up shared child drive subject id', () async {
    await optionBox.put(
      DriveBackupService.sharedChildDriveEmailKey,
      'child@example.com',
    );
    await optionBox.put(
      DriveBackupService.sharedChildDriveLabelKey,
      'Child · child@example.com',
    );
    await optionBox.put(
      DriveBackupService.sharedChildDriveSubjectLocalKey,
      'child-subject',
    );

    final backup = service.buildBackupForTesting();
    final backupOptions = backup['options'] as Map<String, dynamic>;

    expect(
      backupOptions[DriveBackupService.sharedChildDriveSubjectLocalKey],
      'child-subject',
    );
  });

  test(
    'restore keeps saved record and parent drive caches unchanged',
    () async {
      await optionBox.put(
        DriveBackupService.recordDriveEmailLocalKey,
        'record@example.com',
      );
      await optionBox.put(
        DriveBackupService.recordDriveLabelLocalKey,
        'Record · record@example.com',
      );
      await optionBox.put(
        DriveBackupService.recordDriveSubjectLocalKey,
        'record-subject',
      );
      await optionBox.put(
        DriveBackupService.parentDriveEmailLocalKey,
        'parent@example.com',
      );
      await optionBox.put(
        DriveBackupService.parentDriveLabelLocalKey,
        'Parent · parent@example.com',
      );
      await optionBox.put(
        DriveBackupService.parentDriveSubjectLocalKey,
        'parent-subject',
      );

      await service.restoreFromMapForTesting(<String, dynamic>{
        'version': 5,
        'createdAt': '2026-04-19T08:00:00.000',
        'entries': const <dynamic>[],
        'options': <String, dynamic>{'default_location': 'Remote Ground'},
        'optionRecords': const <Map<String, dynamic>>[
          <String, dynamic>{
            'key': 'default_location',
            'value': 'Remote Ground',
          },
        ],
        'family': const <String, dynamic>{
          'updatedByRole': 'child',
          'familyLayerOnly': false,
        },
      });

      expect(
        optionBox.get(DriveBackupService.recordDriveEmailLocalKey),
        'record@example.com',
      );
      expect(
        optionBox.get(DriveBackupService.recordDriveLabelLocalKey),
        'Record · record@example.com',
      );
      expect(
        optionBox.get(DriveBackupService.parentDriveEmailLocalKey),
        'parent@example.com',
      );
      expect(
        optionBox.get(DriveBackupService.parentDriveLabelLocalKey),
        'Parent · parent@example.com',
      );
      expect(optionBox.get('default_location'), 'Remote Ground');
    },
  );

  test(
    'parent auto refresh checks remote freshness against last push and pull',
    () async {
      await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
      await service.recordFamilySyncPushForTesting(DateTime(2026, 4, 19, 10));
      await service.recordFamilySyncPullForTesting(DateTime(2026, 4, 19, 11));

      expect(
        service.shouldRefreshParentSharedDataForTesting(
          remoteModifiedAt: DateTime(2026, 4, 19, 10, 30),
        ),
        isFalse,
      );
      expect(
        service.shouldRefreshParentSharedDataForTesting(
          remoteModifiedAt: DateTime(2026, 4, 19, 11, 1),
        ),
        isTrue,
      );
    },
  );

  test(
    'last family refresh tracks pull time separately from remote modified time',
    () async {
      await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
      await service.recordFamilySyncPullForTesting(
        DateTime(2026, 4, 19, 11),
        remoteModifiedAt: DateTime(2026, 4, 19, 10, 30),
      );

      expect(service.getLastFamilyRefresh(), DateTime(2026, 4, 19, 11));
      expect(
        service.shouldRefreshParentSharedDataForTesting(
          remoteModifiedAt: DateTime(2026, 4, 19, 10, 30),
        ),
        isFalse,
      );
    },
  );

  test(
    'parent auto refresh is blocked while local shared changes are pending',
    () async {
      await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
      await service.markParentSharedDataDirtyForTesting();

      expect(service.hasPendingParentSharedChanges(), isTrue);
      expect(
        service.shouldRefreshParentSharedDataForTesting(
          remoteModifiedAt: DateTime(2026, 4, 19, 12),
        ),
        isFalse,
      );
    },
  );

  test('role mode change resets local backup status', () async {
    final familyService = FamilyAccessService(HiveOptionRepository(optionBox));
    await optionBox.put('drive_last_backup', '2026-04-18T09:00:00.000');
    await optionBox.put(
      'drive_last_record_backup_v1',
      '2026-04-18T09:00:00.000',
    );
    await optionBox.put(
      'drive_previous_backup_created_at_v1',
      '2026-04-17T09:00:00.000',
    );
    await service.recordFamilySyncPushForTesting(DateTime(2026, 4, 18, 10));
    await service.recordFamilySyncPullForTesting(DateTime(2026, 4, 18, 11));
    await service.markParentSharedDataDirtyForTesting();
    await familyService.recordSharedBackupSync(
      role: FamilyRole.child,
      syncedAt: DateTime(2026, 4, 18, 12),
    );

    await service.setCurrentFamilyRole(FamilyRole.parent);

    final state = familyService.loadState();
    expect(state.currentRole, FamilyRole.parent);
    expect(service.getLastBackup(), isNull);
    expect(service.getPreviousBackupCreatedAt(), isNull);
    expect(service.getLastFamilySyncPush(), isNull);
    expect(service.getLastFamilyRefresh(), isNull);
    expect(service.hasPendingParentSharedChanges(), isFalse);
    expect(state.lastSharedSyncAt, isNull);
    expect(state.lastSharedSyncRole, isNull);
  });

  test(
    'parent merge keeps remote entries and updates family layer only',
    () async {
      await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
      await optionBox.put(FamilyAccessService.familyIdKey, 'family-1');
      await optionBox.put(FamilyAccessService.parentNameKey, 'Dad');
      await optionBox.put(FamilyAccessService.childNameKey, 'Minjun');
      await optionBox.put('player_custom_reward_names_v1', <String, String>{
        '2': 'New boots',
        '3': 'Recovery socks',
      });
      await optionBox.put(
        FamilyAccessService.parentTrainingFeedbackKey,
        <String, dynamic>{
          'training_1713427800000000': <String, dynamic>{
            'message': 'Check the first touch after scanning.',
          },
        },
      );
      await optionBox.put('profile_name', 'Parent local stale value');
      await optionBox.put(
        DriveBackupService.connectedDriveEmailLocalKey,
        'child@example.com',
      );

      final remote = <String, dynamic>{
        'version': 5,
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
          FamilyAccessService.familyIdKey: 'family-1',
          DriveBackupService.sharedChildDriveEmailKey: 'child@example.com',
          'player_custom_reward_names_v1': <String, String>{'2': 'Ball'},
          PlayerLevelService.claimedRewardLevelsKey: <int>[2],
          PlayerLevelService.rewardClaimMessagesKey: <Map<String, Object>>[
            <String, Object>{
              'id': 'reward-2-remote',
              'level': 2,
              'rewardName': 'Ball',
              'claimedAt': '2026-04-18T11:00:00.000',
            },
          ],
          FamilyAccessService.parentTrainingFeedbackKey: <String, dynamic>{
            'training_1713000000000000': <String, dynamic>{
              'message': 'Existing remote feedback',
            },
          },
        },
        'optionRecords': <Map<String, dynamic>>[
          <String, dynamic>{
            'key': FamilyAccessService.familyIdKey,
            'value': 'family-1',
          },
          <String, dynamic>{
            'key': DriveBackupService.sharedChildDriveEmailKey,
            'value': 'child@example.com',
          },
          <String, dynamic>{
            'key': 'profile_name',
            'value': 'Real child profile',
          },
          <String, dynamic>{
            'key': 'player_custom_reward_names_v1',
            'value': <String, String>{'2': 'Ball'},
          },
          <String, dynamic>{
            'key': PlayerLevelService.claimedRewardLevelsKey,
            'value': <int>[2],
          },
          <String, dynamic>{
            'key': PlayerLevelService.rewardClaimMessagesKey,
            'value': <Map<String, Object>>[
              <String, Object>{
                'id': 'reward-2-remote',
                'level': 2,
                'rewardName': 'Ball',
                'claimedAt': '2026-04-18T11:00:00.000',
              },
            ],
          },
          <String, dynamic>{
            'key': FamilyAccessService.parentTrainingFeedbackKey,
            'value': <String, dynamic>{
              'training_1713000000000000': <String, dynamic>{
                'message': 'Existing remote feedback',
              },
            },
          },
        ],
        'family': const <String, dynamic>{
          'familyId': 'family-1',
          'updatedByRole': 'child',
          'familyLayerOnly': false,
        },
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
        mergedOptions.containsKey(FamilyAccessService.messagesKey),
        isFalse,
      );
      expect(
        (mergedOptions['player_custom_reward_names_v1'] as Map)['3'],
        'Recovery socks',
      );
      expect(
        (mergedOptions['player_custom_reward_names_v1'] as Map)['2'],
        'New boots',
      );
      expect(mergedOptions[PlayerLevelService.claimedRewardLevelsKey], <int>[
        2,
      ]);
      expect(
        ((mergedOptions[PlayerLevelService.rewardClaimMessagesKey] as List)
            .single as Map)['rewardName'],
        'Ball',
      );
      expect(
        ((mergedOptions[FamilyAccessService.parentTrainingFeedbackKey]
            as Map)['training_1713427800000000'] as Map)['message'],
        'Check the first touch after scanning.',
      );
      expect(family['updatedByRole'], 'parent');
      expect(family['familyLayerOnly'], isTrue);
    },
  );

  test(
    'child shared restore imports parent feedback and reward names',
    () async {
      await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'child');
      await optionBox.put(
        PlayerLevelService.rewardClaimMessagesKey,
        <Map<String, Object>>[
          <String, Object>{
            'id': 'reward-local',
            'level': 2,
            'rewardName': 'Local claim',
          },
        ],
      );

      final result = await service.restoreSharedOptionsFromMapForTesting(
        <String, dynamic>{
          'version': 5,
          'createdAt': '2026-04-20T09:00:00.000',
          'entries': const <dynamic>[],
          'options': const <String, dynamic>{},
          'optionRecords': <Map<String, dynamic>>[
            <String, dynamic>{
              'key': FamilyAccessService.parentTrainingFeedbackKey,
              'value': <String, dynamic>{
                'training_1713427800000000': <String, dynamic>{
                  'message': 'Great first touch.',
                },
              },
            },
            <String, dynamic>{
              'key': PlayerLevelService.customRewardNamesKey,
              'value': <String, String>{'3': 'Recovery kit'},
            },
            <String, dynamic>{
              'key': PlayerLevelService.rewardClaimMessagesKey,
              'value': <Map<String, Object>>[
                <String, Object>{
                  'id': 'reward-remote',
                  'level': 3,
                  'rewardName': 'Remote claim',
                },
              ],
            },
          ],
          'family': const <String, dynamic>{
            'updatedByRole': 'parent',
            'familyLayerOnly': true,
          },
        },
      );

      expect(result.newParentFeedbackCount, 1);
      expect(result.rewardNamesChanged, isTrue);
      expect(
        ((optionBox.get(FamilyAccessService.parentTrainingFeedbackKey)
            as Map)['training_1713427800000000'] as Map)['message'],
        'Great first touch.',
      );
      expect(
        (optionBox.get(PlayerLevelService.customRewardNamesKey) as Map)['3'],
        'Recovery kit',
      );
      expect(
        ((optionBox.get(PlayerLevelService.rewardClaimMessagesKey) as List)
            .single as Map)['rewardName'],
        'Local claim',
      );
    },
  );

  test(
    'backs up and restores local media files through asset records',
    () async {
      await optionBox.put('profile_photo_url', '/tmp/profile_photo.jpg');
      await trainingBox.add(
        TrainingEntry(
          date: DateTime(2026, 1, 5),
          createdAt: DateTime(2026, 1, 5, 10),
          durationMinutes: 50,
          intensity: 3,
          type: 'dribble',
          mood: 4,
          injury: false,
          notes: 'media backup',
          location: 'ground',
          imagePath: '/tmp/training_photo.jpg',
          imagePaths: const ['/tmp/training_photo.jpg'],
        ),
      );
      assetStore.seedRead(
        '/tmp/profile_photo.jpg',
        fileName: 'profile_photo.jpg',
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        restoredPath: '/restored/profile_photo.jpg',
      );
      assetStore.seedRead(
        '/tmp/training_photo.jpg',
        fileName: 'training_photo.jpg',
        bytes: Uint8List.fromList(<int>[4, 5, 6]),
        restoredPath: '/restored/training_photo.jpg',
      );

      final backup = service.buildBackupForTesting();
      final backupOptions = backup['options'] as Map<String, dynamic>;
      final assetRecords = backup['assetRecords'] as Map<String, dynamic>;
      final entry = (backup['entries'] as List).first as Map<String, dynamic>;

      expect(
        backupOptions['profile_photo_url'],
        'backup_asset://option:profile_photo_url',
      );
      expect(assetRecords.containsKey('option:profile_photo_url'), isTrue);
      expect(entry['imagePath'], startsWith('backup_asset://training:'));

      await trainingBox.clear();
      await optionBox.clear();

      await service.restoreFromMapForTesting(backup);

      expect(optionBox.get('profile_photo_url'), '/restored/profile_photo.jpg');
      expect(
        trainingBox.values.first.imagePath,
        '/restored/training_photo.jpg',
      );
      expect(trainingBox.values.first.imagePaths, const <String>[
        '/restored/training_photo.jpg',
      ]);
    },
  );

  test('restore keeps existing data when staged asset restore fails', () async {
    await trainingBox.add(
      TrainingEntry(
        date: DateTime(2026, 1, 5),
        createdAt: DateTime(2026, 1, 5, 10),
        durationMinutes: 50,
        intensity: 3,
        type: 'dribble',
        mood: 4,
        injury: false,
        notes: 'remote media backup',
        location: 'remote ground',
        imagePath: '/tmp/remote_training_photo.jpg',
        imagePaths: const ['/tmp/remote_training_photo.jpg'],
      ),
    );
    assetStore.seedRead(
      '/tmp/remote_training_photo.jpg',
      fileName: 'remote_training_photo.jpg',
      bytes: Uint8List.fromList(<int>[7, 8, 9]),
      restoredPath: '/restored/remote_training_photo.jpg',
    );
    final backup = service.buildBackupForTesting();
    final entry = (backup['entries'] as List).single as Map<String, dynamic>;
    final imageRef = entry['imagePath'] as String;
    final failingAssetId = imageRef.replaceFirst('backup_asset://', '');

    await trainingBox.clear();
    await optionBox.clear();
    await trainingBox.add(
      TrainingEntry(
        date: DateTime(2026, 1, 4),
        createdAt: DateTime(2026, 1, 4, 10),
        durationMinutes: 30,
        intensity: 2,
        type: 'passing',
        mood: 3,
        injury: false,
        notes: 'old local data',
        location: 'old ground',
      ),
    );
    await optionBox.put('profile_name', 'Old local player');
    assetStore.throwOnRestore(failingAssetId);

    await expectLater(
      service.restoreFromMapForTesting(backup),
      throwsA(isA<StateError>()),
    );

    expect(trainingBox.length, 1);
    expect(trainingBox.values.single.notes, 'old local data');
    expect(optionBox.get('profile_name'), 'Old local player');
  });

  test('parent merge is blocked when family id differs', () async {
    await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
    await optionBox.put(FamilyAccessService.familyIdKey, 'family-local');
    await optionBox.put(
      DriveBackupService.connectedDriveEmailLocalKey,
      'child@example.com',
    );

    expect(
      () => service.mergeParentBackupForTesting(
        remote: <String, dynamic>{
          'version': 5,
          'entries': const <dynamic>[],
          'options': <String, dynamic>{
            FamilyAccessService.familyIdKey: 'family-remote',
            DriveBackupService.sharedChildDriveEmailKey: 'child@example.com',
          },
          'optionRecords': const <dynamic>[],
          'family': const <String, dynamic>{'familyId': 'family-remote'},
        },
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          DriveBackupService.parentFamilyMismatchErrorCode,
        ),
      ),
    );
  });

  test(
    'parent merge is blocked when connected drive is not the child drive',
    () async {
      await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
      await optionBox.put(FamilyAccessService.familyIdKey, 'family-1');
      await optionBox.put(
        DriveBackupService.connectedDriveEmailLocalKey,
        'parent@example.com',
      );
      await optionBox.put(
        DriveBackupService.sharedChildDriveEmailKey,
        'child@example.com',
      );

      expect(
        () => service.mergeParentBackupForTesting(
          remote: <String, dynamic>{
            'version': 5,
            'entries': const <dynamic>[],
            'options': <String, dynamic>{
              FamilyAccessService.familyIdKey: 'family-1',
              DriveBackupService.sharedChildDriveEmailKey: 'child@example.com',
            },
            'optionRecords': const <dynamic>[],
            'family': const <String, dynamic>{'familyId': 'family-1'},
          },
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            DriveBackupService.parentDriveMismatchErrorCode,
          ),
        ),
      );
    },
  );

  test(
    'parent merge is blocked when child drive subject differs',
    () async {
      await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
      await optionBox.put(FamilyAccessService.familyIdKey, 'family-1');
      await optionBox.put(
        DriveBackupService.connectedDriveEmailLocalKey,
        'child@example.com',
      );
      await optionBox.put(
        DriveBackupService.connectedDriveSubjectLocalKey,
        'connected-child-subject',
      );

      expect(
        () => service.mergeParentBackupForTesting(
          remote: <String, dynamic>{
            'version': 6,
            'entries': const <dynamic>[],
            'options': <String, dynamic>{
              FamilyAccessService.familyIdKey: 'family-1',
              DriveBackupService.sharedChildDriveEmailKey: 'child@example.com',
              DriveBackupService.sharedChildDriveSubjectLocalKey:
                  'remote-child-subject',
            },
            'optionRecords': const <dynamic>[],
            'family': const <String, dynamic>{'familyId': 'family-1'},
          },
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            DriveBackupService.parentDriveMismatchErrorCode,
          ),
        ),
      );
    },
  );

  test(
    'parent restore is blocked when connected drive is not the child drive',
    () async {
      await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
      await optionBox.put(FamilyAccessService.familyIdKey, 'family-1');
      await optionBox.put(
        DriveBackupService.connectedDriveEmailLocalKey,
        'parent@example.com',
      );
      await optionBox.put(
        DriveBackupService.sharedChildDriveEmailKey,
        'child@example.com',
      );

      expect(
        () => service.validateRestoreBindingForTesting(<String, dynamic>{
          'version': 5,
          'entries': const <dynamic>[],
          'options': <String, dynamic>{
            FamilyAccessService.familyIdKey: 'family-1',
            DriveBackupService.sharedChildDriveEmailKey: 'child@example.com',
          },
          'optionRecords': const <dynamic>[],
          'family': const <String, dynamic>{'familyId': 'family-1'},
        }),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            DriveBackupService.parentDriveMismatchErrorCode,
          ),
        ),
      );
    },
  );

  test(
    'player account switch restores remote backup before adopting the new drive',
    () async {
      await optionBox.put(
        DriveBackupService.recordDriveEmailLocalKey,
        'old@example.com',
      );
      await optionBox.put(
        DriveBackupService.recordDriveLabelLocalKey,
        'Old Player · old@example.com',
      );
      await trainingBox.add(
        TrainingEntry(
          date: DateTime(2026, 4, 20),
          createdAt: DateTime(2026, 4, 20, 7),
          durationMinutes: 45,
          intensity: 3,
          type: 'passing',
          mood: 3,
          injury: false,
          notes: 'old local player data',
          location: 'old field',
        ),
      );

      final switchedAccount = await service.syncConnectedPlayerBackupForTesting(
        connectedAccount: const DriveConnectionInfo(
          email: 'new@example.com',
          displayName: 'New Player',
          subjectId: 'new-subject',
        ),
        remoteBackup: <String, dynamic>{
          'format': 'teo_note_backup',
          'version': 5,
          'createdAt': '2026-04-20T09:00:00.000',
          'entries': <Map<String, dynamic>>[
            <String, dynamic>{
              'date': '2026-04-20T00:00:00.000',
              'createdAt': '2026-04-20T08:00:00.000',
              'durationMinutes': 70,
              'intensity': 4,
              'type': 'dribble',
              'mood': 4,
              'injury': false,
              'notes': 'new remote player data',
              'location': 'new field',
              'program': 'Switch',
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
          'options': <String, dynamic>{'profile_name': 'New Player'},
          'optionRecords': const <Map<String, dynamic>>[
            <String, dynamic>{'key': 'profile_name', 'value': 'New Player'},
          ],
          'family': const <String, dynamic>{
            'updatedByRole': 'child',
            'familyLayerOnly': false,
          },
        },
      );

      expect(switchedAccount, isTrue);
      expect(trainingBox.length, 1);
      expect(trainingBox.values.first.notes, 'new remote player data');
      expect(service.getSavedRecordDriveEmail(), 'new@example.com');
      expect(
        service.getSavedRecordDriveLabel(),
        'New Player · new@example.com',
      );
      expect(
        optionBox.get(DriveBackupService.sharedChildDriveEmailKey),
        'new@example.com',
      );
      expect(service.hasLocalPreRestoreBackup(), isTrue);
    },
  );

  test('changed player drive detection requires subject id when available',
      () async {
    await optionBox.put(
      DriveBackupService.recordDriveEmailLocalKey,
      'player@example.com',
    );
    await optionBox.put(
      DriveBackupService.recordDriveSubjectLocalKey,
      'saved-subject',
    );
    await optionBox.put(
      DriveBackupService.connectedDriveEmailLocalKey,
      'player@example.com',
    );
    await optionBox.put(
      DriveBackupService.connectedDriveSubjectLocalKey,
      'connected-subject',
    );

    expect(service.hasChangedPlayerDriveConnection(), isTrue);

    await optionBox.delete(DriveBackupService.recordDriveSubjectLocalKey);

    expect(service.hasChangedPlayerDriveConnection(), isTrue);

    await optionBox.delete(DriveBackupService.connectedDriveSubjectLocalKey);

    expect(service.hasChangedPlayerDriveConnection(), isFalse);
  });

  test('generic player restore is blocked while Drive account changed',
      () async {
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'new@example.com',
        displayName: 'New Player',
        subjectId: 'new-subject',
      ),
    );
    await optionBox.put(
      DriveBackupService.recordDriveEmailLocalKey,
      'old@example.com',
    );
    await optionBox.put(
      DriveBackupService.recordDriveSubjectLocalKey,
      'old-subject',
    );

    expect(
      service.ensureGenericRestoreAllowedForTesting,
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          DriveBackupService.changedPlayerDriveConnectionErrorCode,
        ),
      ),
    );
  });

  test('manual player backup is blocked while Drive account changed', () async {
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'new@example.com',
        displayName: 'New Player',
        subjectId: 'new-subject',
      ),
    );
    await optionBox.put(
      DriveBackupService.recordDriveEmailLocalKey,
      'old@example.com',
    );
    await optionBox.put(
      DriveBackupService.recordDriveSubjectLocalKey,
      'old-subject',
    );

    expect(
      service.backup(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          DriveBackupService.changedPlayerDriveConnectionErrorCode,
        ),
      ),
    );
  });

  test(
    'manual player backup is blocked before resolving unsaved drive account',
    () async {
      var driveApiRequested = false;
      final driveClient = _RemoteBackupDriveClient(hasBackup: false);
      service = DriveBackupService(
        trainingBox,
        optionBox,
        backupAssetFileStore: assetStore,
        driveConnectionLoader: () async => const DriveConnectionInfo(
          email: 'new@example.com',
          displayName: 'New Player',
          subjectId: 'new-subject',
        ),
        driveApiLoader: ({required bool requireInteractive}) async {
          driveApiRequested = true;
          return drive.DriveApi(driveClient);
        },
      );

      await expectLater(
        service.backup(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            DriveBackupService.changedPlayerDriveConnectionErrorCode,
          ),
        ),
      );

      expect(service.getSavedRecordDriveEmail(), isEmpty);
      expect(driveApiRequested, isFalse);
      expect(driveClient.writeRequestCount, 0);
      expect(driveClient.listRequestCount, 0);
    },
  );

  test(
    'backup refuses to overwrite meaningful remote data with empty local data',
    () async {
      final driveClient = _OverwriteGuardDriveClient(
        remoteBackup: <String, dynamic>{
          'format': 'teo_note_backup',
          'version': 6,
          'createdAt': '2026-04-20T09:00:00.000',
          'entries': const <Map<String, dynamic>>[
            <String, dynamic>{'notes': 'remote player data'},
          ],
          'options': const <String, dynamic>{},
          'optionRecords': const <Map<String, dynamic>>[],
          'family': const <String, dynamic>{
            'updatedByRole': 'child',
            'familyLayerOnly': false,
          },
          'driveAccount': const <String, dynamic>{
            'email': 'player@example.com',
            'label': 'Player · player@example.com',
            'subjectId': 'player-subject',
          },
        },
      );
      service = DriveBackupService(
        trainingBox,
        optionBox,
        backupAssetFileStore: assetStore,
        driveConnectionLoader: () async => const DriveConnectionInfo(
          email: 'player@example.com',
          displayName: 'Player',
          subjectId: 'player-subject',
        ),
        driveApiLoader: ({required bool requireInteractive}) async {
          return drive.DriveApi(driveClient);
        },
      );
      await optionBox.put(
        DriveBackupService.recordDriveEmailLocalKey,
        'player@example.com',
      );
      await optionBox.put(
        DriveBackupService.recordDriveSubjectLocalKey,
        'player-subject',
      );
      await optionBox.put(
        SportCatalog.currentSportOptionKey,
        SportCatalog.tennisId,
      );
      await optionBox.put('profile_name', 'Reinstalled Player');

      await expectLater(
        service.backup(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            DriveBackupService.remoteBackupOverwriteBlockedErrorCode,
          ),
        ),
      );

      expect(driveClient.mediaDownloadCount, 1);
      expect(driveClient.writeRequestCount, 0);
    },
  );

  test(
    'backup refuses sharp core record drops before overwriting remote data',
    () async {
      final driveClient = _OverwriteGuardDriveClient(
        remoteBackup: <String, dynamic>{
          'format': 'teo_note_backup',
          'version': 6,
          'createdAt': '2026-04-20T09:00:00.000',
          'entries': List<Map<String, dynamic>>.generate(
            9,
            (index) => <String, dynamic>{'notes': 'remote-$index'},
          ),
          'options': const <String, dynamic>{},
          'optionRecords': const <Map<String, dynamic>>[],
          'family': const <String, dynamic>{
            'updatedByRole': 'child',
            'familyLayerOnly': false,
          },
          'driveAccount': const <String, dynamic>{
            'email': 'player@example.com',
            'label': 'Player · player@example.com',
            'subjectId': 'player-subject',
          },
        },
      );
      service = DriveBackupService(
        trainingBox,
        optionBox,
        backupAssetFileStore: assetStore,
        driveConnectionLoader: () async => const DriveConnectionInfo(
          email: 'player@example.com',
          displayName: 'Player',
          subjectId: 'player-subject',
        ),
        driveApiLoader: ({required bool requireInteractive}) async {
          return drive.DriveApi(driveClient);
        },
      );
      await optionBox.put(
        DriveBackupService.recordDriveEmailLocalKey,
        'player@example.com',
      );
      await optionBox.put(
        DriveBackupService.recordDriveSubjectLocalKey,
        'player-subject',
      );
      await trainingBox.add(
        TrainingEntry(
          date: DateTime(2026, 4, 20),
          createdAt: DateTime(2026, 4, 20, 7),
          durationMinutes: 45,
          intensity: 3,
          type: 'passing',
          mood: 3,
          injury: false,
          notes: 'single local record',
          location: 'local field',
        ),
      );

      await expectLater(
        service.backup(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            DriveBackupService.remoteBackupOverwriteBlockedErrorCode,
          ),
        ),
      );

      expect(driveClient.writeRequestCount, 0);
    },
  );

  test('backup payload records connected Drive account subject id', () async {
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'player@example.com',
        displayName: 'Player',
        subjectId: 'player-subject',
      ),
    );

    await service.getDriveConnectionInfo();

    final backup = service.buildBackupForTesting();
    final driveAccount = backup['driveAccount'] as Map<String, dynamic>;

    expect(driveAccount['email'], 'player@example.com');
    expect(driveAccount['subjectId'], 'player-subject');
  });

  test('backup payload includes safety manifest with record counts', () async {
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'player@example.com',
        displayName: 'Player',
        subjectId: 'player-subject',
      ),
    );
    await service.getDriveConnectionInfo();
    await trainingBox.add(
      TrainingEntry(
        date: DateTime(2026, 4, 20),
        createdAt: DateTime(2026, 4, 20, 7),
        durationMinutes: 45,
        intensity: 3,
        type: 'passing',
        mood: 3,
        injury: false,
        notes: 'manifest record',
        location: 'local field',
      ),
    );

    final backup = service.buildBackupForTesting();
    final manifest = backup['safetyManifest'] as Map<String, dynamic>;
    final recordCounts = manifest['recordCounts'] as Map<String, dynamic>;

    expect(manifest['datasetId'], startsWith('dataset-'));
    expect(manifest['deviceId'], startsWith('device-'));
    expect(manifest['accountSubjectId'], 'player-subject');
    expect(
        manifest['contentHash'],
        isA<String>().having(
          (value) => value.length,
          'length',
          8,
        ));
    expect(recordCounts['trainingEntries'], 1);
    expect(recordCounts['coreRecords'], 1);
  });

  test('restore adopts dataset id from safety manifest', () async {
    await service.restoreFromMapForTesting(<String, dynamic>{
      'format': 'teo_note_backup',
      'version': 6,
      'createdAt': '2026-04-20T09:00:00.000',
      'entries': const <Map<String, dynamic>>[],
      'options': const <String, dynamic>{'profile_name': 'Remote Player'},
      'optionRecords': const <Map<String, dynamic>>[
        <String, dynamic>{'key': 'profile_name', 'value': 'Remote Player'},
      ],
      'family': const <String, dynamic>{
        'updatedByRole': 'child',
        'familyLayerOnly': false,
      },
      'safetyManifest': const <String, dynamic>{
        'schemaVersion': 1,
        'datasetId': 'dataset-remote',
        'deviceId': 'device-remote',
        'recordCounts': <String, dynamic>{'coreRecords': 0},
        'contentHash': 'abc12345',
      },
    });

    final backup = service.buildBackupForTesting();
    final manifest = backup['safetyManifest'] as Map<String, dynamic>;

    expect(manifest['datasetId'], 'dataset-remote');
  });

  test('backup preserves timestamped history before overwriting remote',
      () async {
    final driveClient = _HistoryPreservingDriveClient(
      remoteBackup: <String, dynamic>{
        'format': 'teo_note_backup',
        'version': 6,
        'createdAt': '2026-04-20T09:00:00.000',
        'entries': const <Map<String, dynamic>>[
          <String, dynamic>{'notes': 'remote player data'},
        ],
        'options': const <String, dynamic>{},
        'optionRecords': const <Map<String, dynamic>>[],
        'family': const <String, dynamic>{
          'updatedByRole': 'child',
          'familyLayerOnly': false,
        },
        'driveAccount': const <String, dynamic>{
          'email': 'player@example.com',
          'label': 'Player · player@example.com',
          'subjectId': 'player-subject',
        },
      },
      historyPrefix: service.historyBackupFileNamePrefixForTesting(),
    );
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'player@example.com',
        displayName: 'Player',
        subjectId: 'player-subject',
      ),
      driveApiLoader: ({required bool requireInteractive}) async {
        return drive.DriveApi(driveClient);
      },
    );
    await optionBox.put(
      DriveBackupService.recordDriveEmailLocalKey,
      'player@example.com',
    );
    await optionBox.put(
      DriveBackupService.recordDriveSubjectLocalKey,
      'player-subject',
    );
    await trainingBox.add(
      TrainingEntry(
        date: DateTime(2026, 4, 20),
        createdAt: DateTime(2026, 4, 20, 7),
        durationMinutes: 45,
        intensity: 3,
        type: 'passing',
        mood: 3,
        injury: false,
        notes: 'local player data',
        location: 'local field',
      ),
    );

    await service.backup();

    expect(driveClient.createdHistoryCount, 1);
    expect(driveClient.createdPreviousCount, 1);
    expect(driveClient.updatedActiveCount, 1);
    expect(driveClient.deletedHistoryCount, 1);
  });

  test(
    'public empty start flow clears stale data and adopts changed drive',
    () async {
      service = DriveBackupService(
        trainingBox,
        optionBox,
        backupAssetFileStore: assetStore,
        driveConnectionLoader: () async => const DriveConnectionInfo(
          email: 'new@example.com',
          displayName: 'New Player',
          subjectId: 'new-subject',
        ),
      );
      await optionBox.put(
        DriveBackupService.recordDriveEmailLocalKey,
        'old@example.com',
      );
      await optionBox.put(
        DriveBackupService.recordDriveLabelLocalKey,
        'Old Player · old@example.com',
      );
      await trainingBox.add(
        TrainingEntry(
          date: DateTime(2026, 4, 20),
          createdAt: DateTime(2026, 4, 20, 7),
          durationMinutes: 45,
          intensity: 3,
          type: 'passing',
          mood: 3,
          injury: false,
          notes: 'old local player data',
          location: 'old field',
        ),
      );
      await optionBox.put(
        'custom_diary_entries_v3',
        '{"2026-04-18":{"body":"old diary"}}',
      );
      await optionBox.put(
        SportCatalog.currentSportOptionKey,
        SportCatalog.tennisId,
      );

      final switchedAccount =
          await service.startChangedPlayerDriveWithEmptyData();

      expect(switchedAccount, isTrue);
      expect(trainingBox.length, 0);
      expect(optionBox.get('custom_diary_entries_v3'), isNull);
      expect(service.getSavedRecordDriveEmail(), 'new@example.com');
      expect(
        service.getSavedRecordDriveLabel(),
        'New Player · new@example.com',
      );
      expect(
        optionBox.get(DriveBackupService.sharedChildDriveEmailKey),
        'new@example.com',
      );
      expect(
        optionBox.get(DriveBackupService.sharedChildDriveSubjectLocalKey),
        'new-subject',
      );
      expect(service.hasLocalPreRestoreBackup(), isTrue);
      expect(service.hasChangedPlayerDriveConnection(), isFalse);
      expect(
        optionBox.get(SportCatalog.currentSportOptionKey),
        SportCatalog.tennisId,
      );
    },
  );

  test(
    'player account switch without remote backup clears stale local data',
    () async {
      final familyService = FamilyAccessService(
        HiveOptionRepository(optionBox),
      );
      await optionBox.put(
        DriveBackupService.recordDriveEmailLocalKey,
        'old@example.com',
      );
      await optionBox.put(
        DriveBackupService.recordDriveLabelLocalKey,
        'Old Player · old@example.com',
      );
      await trainingBox.add(
        TrainingEntry(
          date: DateTime(2026, 4, 20),
          createdAt: DateTime(2026, 4, 20, 7),
          durationMinutes: 45,
          intensity: 3,
          type: 'passing',
          mood: 3,
          injury: false,
          notes: 'old local player data',
          location: 'old field',
        ),
      );
      await optionBox.put(
        'custom_diary_entries_v3',
        '{"2026-04-18":{"body":"old diary"}}',
      );
      await optionBox.put('drive_last_backup', '2026-04-18T09:00:00.000');
      await optionBox.put(
        'drive_last_record_backup_v1',
        '2026-04-18T09:00:00.000',
      );
      await optionBox.put(
        'drive_previous_backup_created_at_v1',
        '2026-04-17T09:00:00.000',
      );
      await service.recordFamilySyncPushForTesting(DateTime(2026, 4, 18, 10));
      await service.recordFamilySyncPullForTesting(DateTime(2026, 4, 18, 11));
      await service.markParentSharedDataDirtyForTesting();
      await familyService.recordSharedBackupSync(
        role: FamilyRole.child,
        syncedAt: DateTime(2026, 4, 18, 12),
      );

      final switchedAccount = await service.syncConnectedPlayerBackupForTesting(
        connectedAccount: const DriveConnectionInfo(
          email: 'new@example.com',
          displayName: 'New Player',
          subjectId: 'new-subject',
        ),
        remoteBackup: null,
      );

      expect(switchedAccount, isTrue);
      expect(trainingBox.length, 0);
      expect(optionBox.get('custom_diary_entries_v3'), isNull);
      expect(service.getSavedRecordDriveEmail(), 'new@example.com');
      expect(
        service.getSavedRecordDriveLabel(),
        'New Player · new@example.com',
      );
      expect(
        optionBox.get(DriveBackupService.sharedChildDriveEmailKey),
        'new@example.com',
      );
      expect(service.hasLocalPreRestoreBackup(), isTrue);
      expect(service.getLastBackup(), isNull);
      expect(service.getPreviousBackupCreatedAt(), isNull);
      expect(service.getLastFamilySyncPush(), isNull);
      expect(service.getLastFamilyRefresh(), isNull);
      expect(service.hasPendingParentSharedChanges(), isFalse);
      final state = familyService.loadState();
      expect(state.lastSharedSyncAt, isNull);
      expect(state.lastSharedSyncRole, isNull);
    },
  );
}

class _RemoteBackupDriveClient extends http.BaseClient {
  _RemoteBackupDriveClient({required this.hasBackup});

  final bool hasBackup;
  int listRequestCount = 0;
  int writeRequestCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method != 'GET' ||
        !request.url.path.endsWith('/drive/v3/files')) {
      writeRequestCount += 1;
      throw StateError('Unexpected Drive write request: ${request.method}');
    }

    listRequestCount += 1;
    final query = request.url.queryParameters['q'] ?? '';
    if (query.contains("mimeType='application/vnd.google-apps.folder'") &&
        query.contains("name='${DriveBackupService.backupFolderName}'")) {
      return _jsonResponse(request, <String, Object?>{
        'files': <Map<String, String>>[
          <String, String>{
            'id': 'folder-id',
            'name': DriveBackupService.backupFolderName,
          },
        ],
      });
    }
    if (query.contains("'folder-id' in parents") &&
        query.contains("name='${DriveBackupService.backupFileName}'")) {
      return _jsonResponse(request, <String, Object?>{
        'files': hasBackup
            ? <Map<String, String>>[
                <String, String>{
                  'id': 'backup-id',
                  'name': DriveBackupService.backupFileName,
                  'modifiedTime': '2026-03-22T10:00:00.000Z',
                },
              ]
            : const <Map<String, String>>[],
      });
    }
    return _jsonResponse(request, const <String, Object?>{'files': []});
  }

  http.StreamedResponse _jsonResponse(
    http.BaseRequest request,
    Map<String, Object?> payload,
  ) {
    final bytes = utf8.encode(jsonEncode(payload));
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      200,
      request: request,
      headers: const <String, String>{'content-type': 'application/json'},
    );
  }
}

class _OverwriteGuardDriveClient extends http.BaseClient {
  _OverwriteGuardDriveClient({required this.remoteBackup});

  final Map<String, dynamic> remoteBackup;
  int mediaDownloadCount = 0;
  int writeRequestCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method == 'GET' &&
        request.url.path.endsWith('/drive/v3/files')) {
      final query = request.url.queryParameters['q'] ?? '';
      if (query.contains("mimeType='application/vnd.google-apps.folder'") &&
          query.contains("name='${DriveBackupService.backupFolderName}'")) {
        return _jsonResponse(request, <String, Object?>{
          'files': <Map<String, String>>[
            <String, String>{
              'id': 'folder-id',
              'name': DriveBackupService.backupFolderName,
            },
          ],
        });
      }
      if (query.contains("'folder-id' in parents") &&
          query.contains("name='${DriveBackupService.backupFileName}'")) {
        return _jsonResponse(request, <String, Object?>{
          'files': <Map<String, String>>[
            <String, String>{
              'id': 'backup-id',
              'name': DriveBackupService.backupFileName,
              'modifiedTime': '2026-04-20T10:00:00.000Z',
            },
          ],
        });
      }
      return _jsonResponse(request, const <String, Object?>{'files': []});
    }
    if (request.method == 'GET' &&
        request.url.path.endsWith('/drive/v3/files/backup-id')) {
      mediaDownloadCount += 1;
      final bytes = utf8.encode(jsonEncode(remoteBackup));
      return http.StreamedResponse(
        Stream<List<int>>.value(bytes),
        200,
        request: request,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    }
    writeRequestCount += 1;
    throw StateError('Unexpected Drive write request: ${request.method}');
  }

  http.StreamedResponse _jsonResponse(
    http.BaseRequest request,
    Map<String, Object?> payload,
  ) {
    final bytes = utf8.encode(jsonEncode(payload));
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      200,
      request: request,
      headers: const <String, String>{'content-type': 'application/json'},
    );
  }
}

class _HistoryPreservingDriveClient extends http.BaseClient {
  _HistoryPreservingDriveClient({
    required this.remoteBackup,
    required this.historyPrefix,
  });

  final Map<String, dynamic> remoteBackup;
  final String historyPrefix;
  int createdHistoryCount = 0;
  int createdPreviousCount = 0;
  int updatedActiveCount = 0;
  int deletedHistoryCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method == 'GET' &&
        request.url.path.endsWith('/drive/v3/files')) {
      final query = request.url.queryParameters['q'] ?? '';
      if (query.contains("mimeType='application/vnd.google-apps.folder'") &&
          query.contains("name='${DriveBackupService.backupFolderName}'")) {
        return _jsonResponse(request, <String, Object?>{
          'files': <Map<String, String>>[
            <String, String>{
              'id': 'folder-id',
              'name': DriveBackupService.backupFolderName,
            },
          ],
        });
      }
      if (query.contains("name contains '$historyPrefix'")) {
        return _jsonResponse(request, <String, Object?>{
          'files': List<Map<String, String>>.generate(
            11,
            (index) => <String, String>{
              'id': 'history-$index',
              'name': '$historyPrefix${index.toString().padLeft(2, '0')}.json',
              'modifiedTime':
                  '2026-04-20T10:${index.toString().padLeft(2, '0')}:00.000Z',
            },
          ),
        });
      }
      if (query.contains("'folder-id' in parents") &&
          query.contains(
              "name='${DriveBackupService.previousBackupFileName}'")) {
        return _jsonResponse(request, const <String, Object?>{
          'files': <Map<String, String>>[],
        });
      }
      if (query.contains("'folder-id' in parents") &&
          query.contains("name='${DriveBackupService.backupFileName}'")) {
        return _jsonResponse(request, <String, Object?>{
          'files': <Map<String, String>>[
            <String, String>{
              'id': 'backup-id',
              'name': DriveBackupService.backupFileName,
              'modifiedTime': '2026-04-20T10:00:00.000Z',
            },
          ],
        });
      }
      return _jsonResponse(request, const <String, Object?>{'files': []});
    }
    if (request.method == 'GET' &&
        request.url.path.endsWith('/drive/v3/files/backup-id')) {
      final bytes = utf8.encode(jsonEncode(remoteBackup));
      return http.StreamedResponse(
        Stream<List<int>>.value(bytes),
        200,
        request: request,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    }
    if (request.method == 'POST' &&
        request.url.path.endsWith('/upload/drive/v3/files')) {
      final body = await utf8.decoder.bind(request.finalize()).join();
      if (body.contains(historyPrefix)) {
        createdHistoryCount += 1;
        return _jsonResponse(request, const <String, Object?>{
          'id': 'created-history-id',
          'modifiedTime': '2026-04-20T10:01:00.000Z',
        });
      }
      if (body.contains(DriveBackupService.previousBackupFileName)) {
        createdPreviousCount += 1;
        return _jsonResponse(request, const <String, Object?>{
          'id': 'previous-id',
          'modifiedTime': '2026-04-20T10:02:00.000Z',
        });
      }
    }
    if (request.method == 'PATCH' &&
        request.url.path.endsWith('/upload/drive/v3/files/backup-id')) {
      updatedActiveCount += 1;
      return _jsonResponse(request, const <String, Object?>{
        'id': 'backup-id',
        'modifiedTime': '2026-04-20T10:03:00.000Z',
      });
    }
    if (request.method == 'DELETE' &&
        request.url.path.contains('/drive/v3/files/history-')) {
      deletedHistoryCount += 1;
      return http.StreamedResponse(
        const Stream<List<int>>.empty(),
        204,
        request: request,
      );
    }
    throw StateError(
      'Unexpected Drive request: ${request.method} ${request.url}',
    );
  }

  http.StreamedResponse _jsonResponse(
    http.BaseRequest request,
    Map<String, Object?> payload,
  ) {
    final bytes = utf8.encode(jsonEncode(payload));
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      200,
      request: request,
      headers: const <String, String>{'content-type': 'application/json'},
    );
  }
}

class _FakeBackupAssetFileStore implements BackupAssetFileStore {
  final Map<String, _SeededAsset> _seededByPath = <String, _SeededAsset>{};
  final Map<String, String> _restoredByAssetId = <String, String>{};
  final Set<String> _throwOnRestoreAssetIds = <String>{};

  void seedRead(
    String sourcePath, {
    required String fileName,
    required Uint8List bytes,
    required String restoredPath,
  }) {
    _seededByPath[sourcePath] = _SeededAsset(
      fileName: fileName,
      bytesBase64: base64Encode(bytes),
      restoredPath: restoredPath,
    );
  }

  void throwOnRestore(String assetId) {
    _throwOnRestoreAssetIds.add(assetId);
  }

  @override
  BackupAssetRecord? readFileSync({
    required String assetId,
    required String sourcePath,
    String? preferredFileName,
  }) {
    final seeded = _seededByPath[sourcePath];
    if (seeded == null) {
      return null;
    }
    _restoredByAssetId[assetId] = seeded.restoredPath;
    return BackupAssetRecord(
      assetId: assetId,
      fileName: preferredFileName ?? seeded.fileName,
      bytesBase64: seeded.bytesBase64,
    );
  }

  @override
  Future<String?> restoreFile(BackupAssetRecord record) async {
    if (_throwOnRestoreAssetIds.contains(record.assetId)) {
      throw StateError('restore failed for ${record.assetId}');
    }
    return _restoredByAssetId[record.assetId];
  }
}

class _SeededAsset {
  final String fileName;
  final String bytesBase64;
  final String restoredPath;

  const _SeededAsset({
    required this.fileName,
    required this.bytesBase64,
    required this.restoredPath,
  });
}
