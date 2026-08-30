import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:football_note/application/backup_asset_store_types.dart';
import 'package:football_note/application/backup_restore_plan.dart';
import 'package:football_note/application/coach_roster_service.dart';
import 'package:football_note/application/drive_connection_info.dart';
import 'package:football_note/application/drive_backup_service.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/family_drive_link_service.dart';
import 'package:football_note/application/meal_log_service.dart';
import 'package:football_note/application/player_level_service.dart';
import 'package:football_note/application/training_plan_reminder_service.dart';
import 'package:football_note/domain/entities/meal_entry.dart';
import 'package:football_note/domain/entities/sport_definition.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/infrastructure/hive_option_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
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

Map<String, dynamic> _remotePlayerBackup({
  String profileName = 'Remote player',
}) {
  return <String, dynamic>{
    'format': 'teo_note_backup',
    'version': 6,
    'createdAt': '2026-07-27T09:00:00.000Z',
    'entries': const <Map<String, dynamic>>[],
    'options': <String, dynamic>{'profile_name': profileName},
    'optionRecords': <Map<String, dynamic>>[
      <String, dynamic>{'key': 'profile_name', 'value': profileName},
    ],
    'assetRecords': const <String, dynamic>{},
    'family': const <String, dynamic>{
      'updatedByRole': 'child',
      'familyLayerOnly': false,
    },
  };
}

TrainingEntry _trainingEntry({
  required String recordId,
  required String notes,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? deletedAt,
}) {
  final created = createdAt ?? DateTime(2026, 4, 20, 9);
  return TrainingEntry(
    date: DateTime(created.year, created.month, created.day),
    createdAt: created,
    durationMinutes: 45,
    intensity: 3,
    type: 'passing',
    mood: 4,
    injury: false,
    notes: notes,
    location: 'main field',
    recordId: recordId,
    updatedAt: updatedAt ?? created,
    originDeviceId: 'device-test',
    deletedAt: deletedAt,
  );
}

FamilyDriveLinkRecord _familyLinkRecord({
  required String parentMemberId,
  required String parentSubjectId,
  String childSubjectId = 'child-subject',
  String familyId = 'family-v2',
  String datasetId = 'dataset-v2',
  String playerId = 'player-v2',
}) {
  return FamilyDriveLinkRecord(
    familyId: familyId,
    datasetId: datasetId,
    playerId: playerId,
    parentMemberId: parentMemberId,
    parentSubjectId: parentSubjectId,
    parentDisplayName: 'Parent',
    childSubjectId: childSubjectId,
    coreBackupFileId: 'core-$parentMemberId',
    contributionFileId: 'contribution-$parentMemberId',
    corePermissionId: 'core-permission-$parentMemberId',
    contributionPermissionId: 'contribution-permission-$parentMemberId',
    createdAt: DateTime.utc(2026, 8, 27, 10),
    updatedAt: DateTime.utc(2026, 8, 27, 10),
  );
}

Map<String, dynamic> _linkedContributionPayload(FamilyDriveLinkRecord link) {
  return <String, dynamic>{
    'format': BackupRestorePlanner.contributionFormatValue,
    'version': 6,
    'createdAt': '2026-08-27T12:00:00.000Z',
    'entries': const <Map<String, dynamic>>[],
    'options': <String, dynamic>{
      FamilyAccessService.parentTrainingFeedbackKey: <String, dynamic>{
        'entry-1': <String, dynamic>{
          'message': 'Keep scanning.',
          'reaction': 'thumbs_up',
          'updatedAt': '2026-08-27T12:00:00.000Z',
        },
      },
    },
    'optionRecords': <Map<String, dynamic>>[
      <String, dynamic>{
        'key': FamilyAccessService.parentTrainingFeedbackKey,
        'value': <String, dynamic>{
          'entry-1': <String, dynamic>{
            'message': 'Keep scanning.',
            'reaction': 'thumbs_up',
            'updatedAt': '2026-08-27T12:00:00.000Z',
          },
        },
      },
    ],
    'assetRecords': const <String, dynamic>{},
    'family': <String, dynamic>{
      'updatedByRole': 'parent',
      'familyLayerOnly': true,
      'familyId': link.familyId,
    },
    'safetyManifest': <String, dynamic>{
      'schemaVersion': 1,
      'datasetId': link.datasetId,
      'deviceId': 'device-parent',
      'playerId': link.playerId,
      'familyId': link.familyId,
      'recordCounts': const <String, dynamic>{'coreRecords': 0},
      'contentHash': 'legacy',
    },
  };
}

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

  test('does not bind a connected Drive account to an active coach player',
      () async {
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
    expect(updated?.driveEmail, isEmpty);
    expect(updated?.driveLabel, isEmpty);
    expect(updated?.driveSubjectId, isEmpty);
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
        penaltyShootoutGoalsFor: 4,
        penaltyShootoutGoalsAgainst: 3,
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
      'health_connect_jump_rope_changes_token_v1': 'local-token',
      'local_pre_restore_backup': '{"should":"be excluded"}',
      'local_pre_restore_backup_at': '2026-01-01T00:00:00.000',
    });

    final backup = service.buildBackupForTesting();
    final backupOptions = backup['options'] as Map<String, dynamic>;
    final backedUpEntry =
        (backup['entries'] as List).single as Map<String, dynamic>;
    final family = backup['family'] as Map<String, dynamic>;

    expect(backup['format'], 'teo_note_backup');
    expect(backup['version'], 7);
    expect(backedUpEntry['sportId'], SportCatalog.footballId);
    expect(backedUpEntry['matchCompetitionName'], 'Weekend League');
    expect(backedUpEntry['matchStage'], 'Round 2');
    expect(backedUpEntry['leaguePoints'], 3);
    expect(backedUpEntry['yellowCards'], 1);
    expect(backedUpEntry['redCards'], 1);
    expect(backedUpEntry['penaltyShootoutGoalsFor'], 4);
    expect(backedUpEntry['penaltyShootoutGoalsAgainst'], 3);
    expect(backedUpEntry['isLesson'], isTrue);
    expect(backedUpEntry['lessonDetail'], 'Dribbling private lesson');
    expect(backupOptions['profile_name'], 'Lee');
    expect(backupOptions['default_duration'], 90);
    expect(backupOptions['type_options'], ['technique', 'tactics']);
    expect(backupOptions.containsKey('theme_mode'), isFalse);
    expect(backupOptions.containsKey('reminder_enabled'), isFalse);
    expect(backupOptions.containsKey('reminder_time'), isFalse);
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
    expect(
      backupOptions.containsKey('health_connect_jump_rope_changes_token_v1'),
      isFalse,
    );
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
    expect(trainingBox.values.first.penaltyShootoutGoalsFor, 4);
    expect(trainingBox.values.first.penaltyShootoutGoalsAgainst, 3);
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
      'health_connect_jump_rope_changes_token_v1',
      'local-token',
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
        'health_connect_jump_rope_changes_token_v1': 'remote-token',
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
          'key': 'health_connect_jump_rope_changes_token_v1',
          'value': 'remote-token',
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
      optionBox.get('health_connect_jump_rope_changes_token_v1'),
      'local-token',
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

  test('safe restore conflicts on sport selection without baseline', () async {
    await optionBox.put(
      SportCatalog.currentSportOptionKey,
      SportCatalog.basketballId,
    );

    final remote = <String, dynamic>{
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
    };

    final plan = service.previewRestorePlanForTesting(remote);

    expect(
      plan.operations
          .singleWhere(
            (operation) =>
                operation.recordId == SportCatalog.currentSportOptionKey,
          )
          .type,
      RestoreOperationType.conflict,
    );

    await service.restoreFromMapForTesting(remote);

    expect(
      optionBox.get(SportCatalog.currentSportOptionKey),
      SportCatalog.basketballId,
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

      final plan = service.previewRestorePlanForTesting(remote);

      expect(
        plan.categoryCount(
          RestoreOperationCategory.training,
          RestoreOperationType.add,
        ),
        1,
      );
      expect(
        plan.categoryCount(
          RestoreOperationCategory.training,
          RestoreOperationType.skip,
        ),
        1,
      );
      expect(
        plan.categoryCount(
          RestoreOperationCategory.option,
          RestoreOperationType.conflict,
        ),
        greaterThanOrEqualTo(1),
      );

      await service.restoreFromMapForTesting(remote);

      expect(trainingBox.length, 2);
      expect(
        trainingBox.values.map((entry) => entry.notes),
        containsAll(<String>[
          'keep local player record',
          'remote player record',
        ]),
      );
      expect(optionBox.get('profile_name'), 'Local player profile');
      expect(optionBox.get(FamilyAccessService.childNameKey), 'Local player');
      expect(optionBox.get(FamilyAccessService.parentNameKey), 'Local parent');
      expect(optionBox.get(FamilyAccessService.messagesKey), isNull);
      expect(
        (optionBox.get('player_custom_reward_names_v1') as Map)['2'],
        'Local ball',
      );
      expect(
        (optionBox.get('player_custom_reward_names_v1') as Map).containsKey(
          '4',
        ),
        isFalse,
      );
      expect(
        ((optionBox.get(FamilyAccessService.parentTrainingFeedbackKey)
            as Map)['training_1'] as Map)['message'],
        'Local parent feedback',
      );
      expect(
        (optionBox.get(FamilyAccessService.parentTrainingFeedbackKey) as Map)
            .containsKey('training_1713427800000000'),
        isFalse,
      );
      expect(
        optionBox.get(DriveBackupService.sharedChildDriveEmailKey),
        'local-player@example.com',
      );
      expect(
        optionBox.get(DriveBackupService.sharedChildDriveLabelKey),
        'Local player · local-player@example.com',
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
    'safe parent restore keeps option-backed child data when remote omits it',
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

      expect(optionBox.get('profile_name'), 'Local child profile');
      expect(optionBox.get(PlayerLevelService.totalXpKey), 240);
      expect(optionBox.get(PlayerLevelService.xpHistoryKey), hasLength(1));
      expect(
          optionBox.get(PlayerLevelService.diaryCreatedDayKey), '2026-04-18');
      expect(optionBox.get(MealLogService.storageKey), '[{"id":"meal-local"}]');
      expect(
        optionBox.get('custom_diary_entries_v3'),
        '{"2026-04-18":{"body":"local diary"}}',
      );
      expect(optionBox.get(FamilyAccessService.childNameKey), 'Remote player');
    },
  );

  test('safe parent restore conflicts on critical options without baseline',
      () async {
    await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
    await optionBox.put(FamilyAccessService.familyIdKey, 'family-1');
    await optionBox.put(PlayerLevelService.totalXpKey, 240);
    await optionBox.put(MealLogService.storageKey, '[{"id":"meal-local"}]');

    final remote = <String, dynamic>{
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
    };

    final plan = service.previewRestorePlanForTesting(remote);

    expect(
      plan.operations
          .where(
            (operation) =>
                operation.category == RestoreOperationCategory.option &&
                operation.type == RestoreOperationType.conflict,
          )
          .map((operation) => operation.recordId),
      containsAll(<String>[
        PlayerLevelService.totalXpKey,
        MealLogService.storageKey,
      ]),
    );

    await service.restoreFromMapForTesting(remote);

    expect(optionBox.get(PlayerLevelService.totalXpKey), 240);
    expect(optionBox.get(MealLogService.storageKey), '[{"id":"meal-local"}]');
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

      await service.restoreFromMapForTesting(
        <String, dynamic>{
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
        },
        mode: RestoreMode.exactReplace,
      );
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

  test('does not create a record Drive binding before import or empty start',
      () async {
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

    expect(service.getSavedRecordDriveEmail(), isEmpty);
    expect(service.getSavedRecordDriveLabel(), isEmpty);
    expect(
        optionBox.get(DriveBackupService.recordDriveSubjectLocalKey), isNull);
  });

  test('does not create a parent Drive binding before import or empty start',
      () async {
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

    expect(service.getSavedParentDriveEmail(), isEmpty);
    expect(service.getSavedParentDriveLabel(), isEmpty);
    expect(
        optionBox.get(DriveBackupService.parentDriveSubjectLocalKey), isNull);
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

  test(
      'player drive binding distinguishes verified, legacy, and changed accounts',
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
    expect(
      service.getPlayerDriveBindingState(),
      PlayerDriveBindingState.accountMismatch,
    );

    await optionBox.delete(DriveBackupService.recordDriveSubjectLocalKey);

    expect(service.hasChangedPlayerDriveConnection(), isFalse);
    expect(service.hasLegacyPlayerDriveConnection(), isTrue);
    expect(service.needsPlayerDriveImportBeforeBackup(), isTrue);
    expect(
      service.getPlayerDriveBindingState(),
      PlayerDriveBindingState.legacyEmailMatch,
    );

    await optionBox.delete(DriveBackupService.connectedDriveSubjectLocalKey);

    expect(service.hasChangedPlayerDriveConnection(), isFalse);
    expect(service.hasLegacyPlayerDriveConnection(), isTrue);

    await optionBox.put(
      DriveBackupService.recordDriveSubjectLocalKey,
      'shared-subject',
    );
    await optionBox.put(
      DriveBackupService.connectedDriveSubjectLocalKey,
      'shared-subject',
    );

    expect(
      service.getPlayerDriveBindingState(),
      PlayerDriveBindingState.verified,
    );
    expect(service.needsPlayerDriveImportBeforeBackup(), isFalse);
  });

  test(
    'legacy matching email can restore safely before binding its Google subject id',
    () async {
      final driveClient = _OverwriteGuardDriveClient(
        remoteBackup: _remotePlayerBackup(profileName: 'Legacy player'),
      );
      service = DriveBackupService(
        trainingBox,
        optionBox,
        backupAssetFileStore: assetStore,
        driveConnectionLoader: () async => const DriveConnectionInfo(
          email: 'player@example.com',
          displayName: 'Player',
          subjectId: 'current-subject',
        ),
        driveApiLoader: ({required bool requireInteractive}) async {
          return drive.DriveApi(driveClient);
        },
      );
      await optionBox.put(
        DriveBackupService.recordDriveEmailLocalKey,
        'player@example.com',
      );

      await service.getDriveConnectionInfo();

      expect(service.hasChangedPlayerDriveConnection(), isFalse);
      expect(service.hasLegacyPlayerDriveConnection(), isTrue);
      expect(service.needsPlayerDriveImportBeforeBackup(), isTrue);

      await service.restoreLatest();

      expect(optionBox.get('profile_name'), 'Legacy player');
      expect(
        optionBox.get(DriveBackupService.recordDriveSubjectLocalKey),
        'current-subject',
      );
      expect(
        service.getPlayerDriveBindingState(),
        PlayerDriveBindingState.verified,
      );
      expect(service.needsPlayerDriveImportBeforeBackup(), isFalse);
      expect(driveClient.writeRequestCount, 0);
    },
  );

  test('legacy account remains blocked from backup before its first import',
      () async {
    var driveApiRequested = false;
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'player@example.com',
        displayName: 'Player',
        subjectId: 'current-subject',
      ),
      driveApiLoader: ({required bool requireInteractive}) async {
        driveApiRequested = true;
        throw StateError('Drive API must not be requested before import.');
      },
    );
    await optionBox.put(
      DriveBackupService.recordDriveEmailLocalKey,
      'player@example.com',
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

    expect(driveApiRequested, isFalse);
  });

  test('unbound connected account imports remote backup before binding',
      () async {
    final driveClient = _OverwriteGuardDriveClient(
      remoteBackup: _remotePlayerBackup(profileName: 'Reinstalled player'),
    );
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'new@example.com',
        displayName: 'New player',
        subjectId: 'new-subject',
      ),
      driveApiLoader: ({required bool requireInteractive}) async {
        return drive.DriveApi(driveClient);
      },
    );

    final imported = await service.importChangedPlayerDriveBackup();

    expect(imported, isTrue);
    expect(optionBox.get('profile_name'), 'Reinstalled player');
    expect(service.getSavedRecordDriveEmail(), 'new@example.com');
    expect(
      optionBox.get(DriveBackupService.recordDriveSubjectLocalKey),
      'new-subject',
    );
    expect(
      service.getPlayerDriveBindingState(),
      PlayerDriveBindingState.verified,
    );
    expect(driveClient.writeRequestCount, 0);
  });

  test('account backup import retries after Drive authorization expires',
      () async {
    final driveClient = _OverwriteGuardDriveClient(
      remoteBackup: _remotePlayerBackup(profileName: 'New account player'),
    );
    var driveApiAttempts = 0;
    var reauthenticationAttempts = 0;
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'new@example.com',
        displayName: 'New player',
        subjectId: 'new-subject',
      ),
      driveApiLoader: ({required bool requireInteractive}) async {
        driveApiAttempts += 1;
        if (driveApiAttempts == 1) {
          throw StateError('Google sign-in required.');
        }
        return drive.DriveApi(driveClient);
      },
      driveScopeReauthenticator: () async {
        reauthenticationAttempts += 1;
      },
    );
    await optionBox.put(
      DriveBackupService.recordDriveEmailLocalKey,
      'old@example.com',
    );
    await optionBox.put(
      DriveBackupService.recordDriveSubjectLocalKey,
      'old-subject',
    );

    final imported = await service.importChangedPlayerDriveBackup();

    expect(imported, isTrue);
    expect(driveApiAttempts, 2);
    expect(reauthenticationAttempts, 1);
    expect(optionBox.get('profile_name'), 'New account player');
    expect(service.getSavedRecordDriveEmail(), 'new@example.com');
    expect(driveClient.writeRequestCount, 0);
  });

  test('parent mode does not inherit child account import blocking', () async {
    await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
    await optionBox.put(
      DriveBackupService.recordDriveEmailLocalKey,
      'child@example.com',
    );
    await optionBox.put(
      DriveBackupService.connectedDriveEmailLocalKey,
      'parent@example.com',
    );

    expect(
      service.getPlayerDriveBindingState(),
      PlayerDriveBindingState.notApplicable,
    );
    expect(service.needsPlayerDriveImportBeforeBackup(), isFalse);
    expect(service.hasChangedPlayerDriveConnection(), isFalse);
  });

  test('generic player restore allows an explicit account migration', () async {
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

    await service.ensureGenericRestoreAllowedForTesting();
  });

  test('parent backup is blocked until the connected account is restored',
      () async {
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'new-parent@example.com',
        displayName: 'New parent',
        subjectId: 'new-parent-subject',
      ),
    );
    await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
    await optionBox.put(
      DriveBackupService.parentDriveEmailLocalKey,
      'saved-parent@example.com',
    );
    await optionBox.put(
      DriveBackupService.parentDriveSubjectLocalKey,
      'saved-parent-subject',
    );

    await expectLater(
      service.backup(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          DriveBackupService.driveAccountBindingRequiredErrorCode,
        ),
      ),
    );
  });

  test('coach backup is blocked until the active player account is restored',
      () async {
    await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'coach');
    final roster = CoachRosterService(HiveOptionRepository(optionBox));
    final player = await roster.addPlayer(displayName: 'Minjun');
    await roster.upsertPlayer(
      player.copyWith(
        driveEmail: 'saved-coach@example.com',
        driveSubjectId: 'saved-coach-subject',
      ),
    );
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'new-coach@example.com',
        displayName: 'New coach',
        subjectId: 'new-coach-subject',
      ),
    );

    await expectLater(
      service.backup(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          DriveBackupService.driveAccountBindingRequiredErrorCode,
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

  test(
      'backup blocks a remote revision that changed after this device restored',
      () async {
    final driveClient = _OverwriteGuardDriveClient(
      remoteBackup: _remotePlayerBackup(profileName: 'Restored player'),
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

    await service.restoreLatest();
    driveClient.remoteBackup = _remotePlayerBackup(
      profileName: 'Changed elsewhere',
    );

    await expectLater(
      service.backup(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          DriveBackupService.remoteBackupConflictErrorCode,
        ),
      ),
    );
    expect(driveClient.writeRequestCount, 0);
  });

  test('backup requires an explicit restore before overwriting a v2 manifest',
      () async {
    final remoteBackup = service.buildBackupForTesting();
    final driveClient = _OverwriteGuardDriveClient(remoteBackup: remoteBackup);
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

    await expectLater(
      service.backup(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          DriveBackupService.remoteBackupConflictErrorCode,
        ),
      ),
    );
    expect(driveClient.writeRequestCount, 0);
  });

  test('backup rejects a matching email when the Google subject differs',
      () async {
    final driveClient = _OverwriteGuardDriveClient(
      remoteBackup: <String, dynamic>{
        ..._remotePlayerBackup(profileName: 'Other identity'),
        'driveAccount': const <String, dynamic>{
          'email': 'player@example.com',
          'subjectId': 'remote-subject',
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
        subjectId: 'current-subject',
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
      'current-subject',
    );

    await expectLater(
      service.backup(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          DriveBackupService.backupOwnerMismatchErrorCode,
        ),
      ),
    );
    expect(driveClient.writeRequestCount, 0);
  });

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
    expect(manifest['schemaVersion'], 2);
    expect(manifest['hashAlgorithm'], 'sha256');
    expect(
        manifest['contentHash'],
        isA<String>().having(
          (value) => value.length,
          'length',
          64,
        ));
    expect(recordCounts['trainingEntries'], 1);
    expect(recordCounts['coreRecords'], 1);
  });

  test('safe restore adds remote-only entries and keeps local-only entries',
      () async {
    await trainingBox.add(_trainingEntry(
      recordId: 'remote-only',
      notes: 'remote only',
      createdAt: DateTime(2026, 4, 20, 8),
    ));
    final remote = service.buildBackupForTesting();

    await trainingBox.clear();
    await optionBox.clear();
    await trainingBox.add(_trainingEntry(
      recordId: 'local-only',
      notes: 'local only',
      createdAt: DateTime(2026, 4, 21, 8),
    ));

    final plan = service.previewRestorePlanForTesting(remote);
    expect(
      plan.categoryCount(
        RestoreOperationCategory.training,
        RestoreOperationType.add,
      ),
      1,
    );
    expect(
      plan.categoryCount(
        RestoreOperationCategory.training,
        RestoreOperationType.skip,
      ),
      1,
    );

    await service.restoreFromMapForTesting(remote);
    await service.restoreFromMapForTesting(remote);

    expect(trainingBox.length, 2);
    expect(
      trainingBox.values.map((entry) => entry.notes),
      containsAll(<String>['local only', 'remote only']),
    );
  });

  test('safe restore conflicts on same record without a baseline', () async {
    await trainingBox.add(_trainingEntry(
      recordId: 'entry-1',
      notes: 'remote edit',
      updatedAt: DateTime(2026, 4, 20, 11),
    ));
    final remote = service.buildBackupForTesting();

    await trainingBox.clear();
    await trainingBox.add(_trainingEntry(
      recordId: 'entry-1',
      notes: 'local edit',
      updatedAt: DateTime(2026, 4, 20, 10),
    ));

    final plan = service.previewRestorePlanForTesting(remote);
    expect(plan.count(RestoreOperationType.conflict), 1);

    await service.restoreFromMapForTesting(remote);

    expect(trainingBox.length, 1);
    expect(trainingBox.values.single.notes, 'local edit');
  });

  test(
      'safe restore updates remote-changed records when local matches baseline',
      () async {
    final baseEntry = _trainingEntry(
      recordId: 'entry-1',
      notes: 'baseline',
      updatedAt: DateTime(2026, 4, 20, 9),
    );
    await trainingBox.add(baseEntry);
    final baseline = service.buildBackupForTesting();
    await service.restoreFromMapForTesting(baseline);

    await trainingBox.clear();
    await trainingBox.add(_trainingEntry(
      recordId: 'entry-1',
      notes: 'remote changed',
      updatedAt: DateTime(2026, 4, 20, 12),
    ));
    final remote = service.buildBackupForTesting();

    await trainingBox.clear();
    await trainingBox.add(baseEntry);

    final plan = service.previewRestorePlanForTesting(remote);
    expect(plan.count(RestoreOperationType.update), 1);

    await service.restoreFromMapForTesting(remote);

    expect(trainingBox.length, 1);
    expect(trainingBox.values.single.notes, 'remote changed');
  });

  test(
      'safe restore applies explicit tombstones only against unchanged local data',
      () async {
    final baseEntry = _trainingEntry(recordId: 'entry-1', notes: 'baseline');
    await trainingBox.add(baseEntry);
    final baseline = service.buildBackupForTesting();
    await service.restoreFromMapForTesting(baseline);

    await trainingBox.clear();
    await trainingBox.add(_trainingEntry(
      recordId: 'entry-1',
      notes: 'baseline',
      deletedAt: DateTime(2026, 4, 21, 9),
    ));
    final tombstone = service.buildBackupForTesting();

    await trainingBox.clear();
    await trainingBox.add(baseEntry);

    final plan = service.previewRestorePlanForTesting(tombstone);
    expect(plan.count(RestoreOperationType.tombstone), 1);

    await service.restoreFromMapForTesting(tombstone);
    await service.restoreFromMapForTesting(tombstone);

    expect(trainingBox.length, 1);
    expect(trainingBox.values.single.deletedAt, isNotNull);
    expect(service.describeLocalBackup().counts.trainingEntries, 0);
  });

  test('safe restore conflicts when a tombstone races a local edit', () async {
    final baseEntry = _trainingEntry(recordId: 'entry-1', notes: 'baseline');
    await trainingBox.add(baseEntry);
    final baseline = service.buildBackupForTesting();
    await service.restoreFromMapForTesting(baseline);

    await trainingBox.clear();
    await trainingBox.add(_trainingEntry(
      recordId: 'entry-1',
      notes: 'baseline',
      deletedAt: DateTime(2026, 4, 21, 9),
    ));
    final tombstone = service.buildBackupForTesting();

    await trainingBox.clear();
    await trainingBox.add(_trainingEntry(
      recordId: 'entry-1',
      notes: 'local changed',
      updatedAt: DateTime(2026, 4, 21, 10),
    ));

    final plan = service.previewRestorePlanForTesting(tombstone);
    expect(plan.count(RestoreOperationType.conflict), 1);

    await service.restoreFromMapForTesting(tombstone);

    expect(trainingBox.length, 1);
    expect(trainingBox.values.single.notes, 'local changed');
  });

  test('parent contribution backup excludes player core records', () async {
    await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
    await optionBox.put(FamilyAccessService.familyIdKey, 'family-1');
    await optionBox.put(
      FamilyAccessService.parentTrainingFeedbackKey,
      <String, dynamic>{
        'entry-1': <String, dynamic>{'message': 'Good tempo.'},
      },
    );
    await optionBox.put(
      PlayerLevelService.customRewardNamesKey,
      <String, String>{'2': 'New boots'},
    );
    await optionBox.put(PlayerLevelService.totalXpKey, 999);
    await trainingBox.add(_trainingEntry(
      recordId: 'entry-1',
      notes: 'player training',
    ));

    final backup = service.buildFamilyContributionBackupForTesting();
    final options = backup['options'] as Map<String, dynamic>;

    expect(backup['format'], BackupRestorePlanner.contributionFormatValue);
    expect(backup['entries'], isEmpty);
    expect(options[FamilyAccessService.parentTrainingFeedbackKey], isNotNull);
    expect(options[PlayerLevelService.customRewardNamesKey], isNotNull);
    expect(options.containsKey(PlayerLevelService.totalXpKey), isFalse);
    expect(
      (backup['safetyManifest']
          as Map<String, dynamic>)['contributionLayerOnly'],
      isTrue,
    );
  });

  test('parent contribution merge preserves records from another device',
      () async {
    await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
    await optionBox.put(FamilyAccessService.familyIdKey, 'family-1');
    await optionBox.put(
      FamilyAccessService.parentTrainingFeedbackKey,
      <String, dynamic>{
        'entry-remote': <String, dynamic>{'message': 'Remote feedback'},
      },
    );
    final remote = service.buildFamilyContributionBackupForTesting();

    await optionBox.put(
      FamilyAccessService.parentTrainingFeedbackKey,
      <String, dynamic>{
        'entry-local': <String, dynamic>{'message': 'Local feedback'},
      },
    );
    final merged = service.mergeFamilyContributionBackupForTesting(remote);
    final options = merged['options'] as Map<String, dynamic>;
    final feedback = options[FamilyAccessService.parentTrainingFeedbackKey]
        as Map<String, dynamic>;

    expect(feedback.keys, containsAll(<String>['entry-remote', 'entry-local']));
    expect(merged['entries'], isEmpty);
    expect(
      merged['format'],
      BackupRestorePlanner.contributionFormatValue,
    );
  });

  test('full restore rejects a parent contribution file', () async {
    await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
    final contribution = service.buildFamilyContributionBackupForTesting();

    expect(
      () => service.restoreFromMapForTesting(contribution),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          DriveBackupService.invalidBackupPayloadErrorCode,
        ),
      ),
    );
  });

  test('restore rejects a plan that changed after preview', () async {
    await trainingBox.add(_trainingEntry(
      recordId: 'remote-entry',
      notes: 'remote',
    ));
    final remote = service.buildBackupForTesting();
    await trainingBox.clear();
    final preview = service.previewRestorePlanForTesting(remote);
    await trainingBox.add(_trainingEntry(
      recordId: 'new-local-entry',
      notes: 'created after preview',
    ));

    await expectLater(
      service.restoreFromMapForTesting(
        remote,
        expectedPlanHash: preview.planHash,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          DriveBackupService.backupPreviewChangedErrorCode,
        ),
      ),
    );
    expect(trainingBox.values.single.notes, 'created after preview');
    expect(service.hasPendingRestoreTransactionForTesting(), isFalse);
  });

  test('parent Drive backup writes only the contribution file', () async {
    await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
    await optionBox.put(FamilyAccessService.familyIdKey, 'family-1');
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
    await optionBox.put(
      FamilyAccessService.parentTrainingFeedbackKey,
      <String, dynamic>{
        'entry-1': <String, dynamic>{'message': 'Keep the shape.'},
      },
    );
    await optionBox.put(
      PlayerLevelService.customRewardNamesKey,
      <String, String>{'4': 'Recovery kit'},
    );
    await optionBox.put(PlayerLevelService.totalXpKey, 1200);
    await trainingBox.add(_trainingEntry(
      recordId: 'entry-1',
      notes: 'player-owned data',
    ));

    final contributionFileName = service.familyContributionFileNameForTesting();
    final driveClient = _ContributionWriteDriveClient(
      contributionFileName: contributionFileName,
    );
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'parent@example.com',
        displayName: 'Parent',
        subjectId: 'parent-subject',
      ),
      driveApiLoader: ({required bool requireInteractive}) async {
        return drive.DriveApi(driveClient);
      },
    );

    await service.backup();

    expect(driveClient.playerSnapshotWriteCount, 0);
    expect(driveClient.contributionWriteCount, 1);
    final uploaded = driveClient.uploadedContribution!;
    expect(uploaded['format'], BackupRestorePlanner.contributionFormatValue);
    expect(uploaded['entries'], isEmpty);
    final options = uploaded['options'] as Map<String, dynamic>;
    expect(options[FamilyAccessService.parentTrainingFeedbackKey], isNotNull);
    expect(options[PlayerLevelService.customRewardNamesKey], isNotNull);
    expect(options.containsKey(PlayerLevelService.totalXpKey), isFalse);
  });

  test('linked parent backup updates only its contribution file id', () async {
    await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
    await optionBox.put(FamilyAccessService.familyIdKey, 'family-v2');
    await optionBox.put(
      FamilyAccessService.parentTrainingFeedbackKey,
      <String, dynamic>{
        'entry-1': <String, dynamic>{'message': 'Keep the shape.'},
      },
    );
    await optionBox.put(
      PlayerLevelService.customRewardNamesKey,
      <String, String>{'4': 'Recovery kit'},
    );
    await optionBox.put(PlayerLevelService.totalXpKey, 1200);
    await trainingBox.add(_trainingEntry(
      recordId: 'entry-1',
      notes: 'player-owned data',
    ));
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
    await service.getDriveConnectionInfo();
    final localSnapshot = service.buildBackupForTesting();
    final safetyManifest =
        localSnapshot['safetyManifest'] as Map<String, dynamic>;
    final datasetId = safetyManifest['datasetId'] as String;
    final playerId = safetyManifest['playerId'] as String;
    final remoteContribution =
        service.buildFamilyContributionBackupForTesting();
    final link = FamilyDriveLinkRecord(
      familyId: 'family-v2',
      datasetId: datasetId,
      playerId: playerId,
      parentMemberId: 'parent-member-1',
      parentSubjectId: 'parent-subject',
      parentDisplayName: 'Parent',
      childSubjectId: 'child-subject',
      coreBackupFileId: 'child-core-file-id',
      contributionFileId: 'linked-contribution-file-id',
      corePermissionId: 'core-reader-permission',
      contributionPermissionId: 'contribution-writer-permission',
      createdAt: DateTime.utc(2026, 8, 27, 10),
      updatedAt: DateTime.utc(2026, 8, 27, 10),
    );
    await FamilyDriveLinkStore(HiveOptionRepository(optionBox))
        .saveRecord(link);

    final driveClient = _LinkedFamilyContributionDriveClient(
      remoteContribution: remoteContribution,
      contributionFileId: link.contributionFileId,
    );
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'parent@example.com',
        displayName: 'Parent',
        subjectId: 'parent-subject',
      ),
      driveApiLoader: ({required bool requireInteractive}) async {
        return drive.DriveApi(driveClient);
      },
    );

    await service.backup();

    expect(driveClient.coreWriteCount, 0);
    expect(driveClient.contributionDownloadCount, 1);
    expect(driveClient.contributionUpdateCount, 1);
    expect(
      driveClient.lastUploadedFileName,
      DriveBackupService.familyMemberContributionFileName(
        playerId: playerId,
        familyId: 'family-v2',
        parentMemberId: 'parent-member-1',
      ),
    );
    final uploaded = driveClient.uploadedContribution!;
    expect(uploaded['format'], BackupRestorePlanner.contributionFormatValue);
    expect(uploaded['entries'], isEmpty);
    expect(
      _containsValue(uploaded, 'parent@example.com'),
      isFalse,
    );
    final options = uploaded['options'] as Map<String, dynamic>;
    expect(options[FamilyAccessService.parentTrainingFeedbackKey], isNotNull);
    expect(options[PlayerLevelService.customRewardNamesKey], isNotNull);
    expect(options.containsKey(PlayerLevelService.totalXpKey), isFalse);
  });

  test('linked parent backup fails closed before upload under wrong subject',
      () async {
    await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
    await optionBox.put(FamilyAccessService.familyIdKey, 'family-v2');
    await FamilyDriveLinkStore(HiveOptionRepository(optionBox)).saveRecord(
      FamilyDriveLinkRecord(
        familyId: 'family-v2',
        datasetId: 'dataset-1',
        playerId: 'player-1',
        parentMemberId: 'parent-member-1',
        parentSubjectId: 'expected-parent-subject',
        parentDisplayName: 'Parent',
        childSubjectId: 'child-subject',
        coreBackupFileId: 'child-core-file-id',
        contributionFileId: 'linked-contribution-file-id',
        corePermissionId: 'core-reader-permission',
        contributionPermissionId: 'contribution-writer-permission',
        createdAt: DateTime.utc(2026, 8, 27, 10),
        updatedAt: DateTime.utc(2026, 8, 27, 10),
      ),
    );
    var driveApiRequested = false;
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'other-parent@example.com',
        displayName: 'Other Parent',
        subjectId: 'other-parent-subject',
      ),
      driveApiLoader: ({required bool requireInteractive}) async {
        driveApiRequested = true;
        throw StateError('Drive API must not be requested.');
      },
    );

    await expectLater(
      service.backup(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          DriveBackupService.driveAccountBindingRequiredErrorCode,
        ),
      ),
    );

    expect(driveApiRequested, isFalse);
  });

  test(
    'child family link recovery does not establish core backup binding',
    () async {
      final active = _familyLinkRecord(
        parentMemberId: 'parent-member-1',
        parentSubjectId: 'parent-subject-1',
      );
      final revoked = _familyLinkRecord(
        parentMemberId: 'parent-member-2',
        parentSubjectId: 'parent-subject-2',
      ).revoked(
        at: DateTime.utc(2026, 8, 27, 12),
        reason: 'child_unlinked',
      );
      final driveClient = _FamilyManifestRecoveryDriveClient(
        childManifest: FamilyDriveLinkManifest(
          ownerRole: FamilyDriveLinkOwnerRole.child,
          familyId: active.familyId,
          datasetId: active.datasetId,
          playerId: active.playerId,
          records: <FamilyDriveLinkRecord>[active, revoked],
          createdAt: DateTime.utc(2026, 8, 27, 10),
          updatedAt: DateTime.utc(2026, 8, 27, 12),
        ),
        contributionFileId: active.contributionFileId,
        contributionPayload: _linkedContributionPayload(active),
      );
      var driveApiRequests = 0;
      service = DriveBackupService(
        trainingBox,
        optionBox,
        backupAssetFileStore: assetStore,
        driveConnectionLoader: () async => const DriveConnectionInfo(
          email: 'child@example.com',
          displayName: 'Child',
          subjectId: 'child-subject',
        ),
        driveApiLoader: ({required bool requireInteractive}) async {
          driveApiRequests += 1;
          return drive.DriveApi(driveClient);
        },
      );

      final result = await service.refreshFamilySharedDataIfNeeded();

      expect(result.refreshed, isFalse);
      final records =
          FamilyDriveLinkStore(HiveOptionRepository(optionBox)).loadRecords();
      expect(records, hasLength(2));
      expect(
        records.map((record) => record.parentMemberId),
        containsAll(<String>['parent-member-1', 'parent-member-2']),
      );
      expect(records.where((record) => record.isRevoked), hasLength(1));
      expect(service.getActiveFamilyDriveLink()?.parentMemberId,
          'parent-member-1');
      expect(
        service.getCurrentRoleDriveBindingState(),
        PlayerDriveBindingState.unbound,
      );
      expect(service.needsPlayerDriveImportBeforeBackup(), isTrue);
      expect(optionBox.get(FamilyAccessService.familyIdKey), active.familyId);
      expect(
        optionBox.get(FamilyAccessService.parentTrainingFeedbackKey),
        isNull,
      );
      expect(driveClient.contributionDownloadCount, 0);
      expect(driveClient.writeRequestCount, 0);
      final recoveryDriveApiRequests = driveApiRequests;
      expect(recoveryDriveApiRequests, greaterThan(0));

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

      expect(driveApiRequests, recoveryDriveApiRequests);
      expect(driveClient.writeRequestCount, 0);
    },
  );

  test('child recovered link refreshes contribution after saved record import',
      () async {
    final active = _familyLinkRecord(
      parentMemberId: 'parent-member-1',
      parentSubjectId: 'parent-subject-1',
    );
    await optionBox.put(
      DriveBackupService.recordDriveSubjectLocalKey,
      active.childSubjectId,
    );
    await optionBox.put(
      DriveBackupService.recordDriveEmailLocalKey,
      'child@example.com',
    );
    final driveClient = _FamilyManifestRecoveryDriveClient(
      childManifest: FamilyDriveLinkManifest(
        ownerRole: FamilyDriveLinkOwnerRole.child,
        familyId: active.familyId,
        datasetId: active.datasetId,
        playerId: active.playerId,
        records: <FamilyDriveLinkRecord>[active],
        createdAt: DateTime.utc(2026, 8, 27, 10),
        updatedAt: DateTime.utc(2026, 8, 27, 12),
      ),
      contributionFileId: active.contributionFileId,
      contributionPayload: _linkedContributionPayload(active),
    );
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'child@example.com',
        displayName: 'Child',
        subjectId: 'child-subject',
      ),
      driveApiLoader: ({required bool requireInteractive}) async {
        return drive.DriveApi(driveClient);
      },
    );

    final result = await service.refreshFamilySharedDataIfNeeded();

    expect(result.refreshed, isTrue);
    expect(
      service.getCurrentRoleDriveBindingState(),
      PlayerDriveBindingState.verified,
    );
    expect(optionBox.get(FamilyAccessService.parentTrainingFeedbackKey),
        isNotNull);
    expect(driveClient.contributionDownloadCount, 1);
    expect(driveClient.writeRequestCount, 0);
  });

  test('missing family link manifest recovery is throttled in memory',
      () async {
    final driveClient = _FamilyManifestRecoveryDriveClient();
    var driveApiRequests = 0;
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'child@example.com',
        displayName: 'Child',
        subjectId: 'child-subject',
      ),
      driveApiLoader: ({required bool requireInteractive}) async {
        driveApiRequests += 1;
        return drive.DriveApi(driveClient);
      },
    );

    final first = await service.refreshFamilySharedDataIfNeeded();
    final second = await service.refreshFamilySharedDataIfNeeded();

    expect(first.refreshed, isFalse);
    expect(second.refreshed, isFalse);
    expect(driveApiRequests, 1);
    expect(driveClient.folderListCount, 1);
    expect(driveClient.childManifestListCount, 1);
    expect(driveClient.manifestDownloadCount, 0);
    expect(driveClient.writeRequestCount, 0);
  });

  test('transient family link recovery errors are not cooldown throttled',
      () async {
    final driveClient = _FamilyManifestRecoveryDriveClient(
      failingChildManifestListResponses: 1,
    );
    var driveApiRequests = 0;
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'child@example.com',
        displayName: 'Child',
        subjectId: 'child-subject',
      ),
      driveApiLoader: ({required bool requireInteractive}) async {
        driveApiRequests += 1;
        return drive.DriveApi(driveClient);
      },
    );

    final first = await service.refreshFamilySharedDataIfNeeded();
    final second = await service.refreshFamilySharedDataIfNeeded();

    expect(first.refreshed, isFalse);
    expect(second.refreshed, isFalse);
    expect(driveApiRequests, 2);
    expect(driveClient.childManifestListCount, 2);
    expect(driveClient.manifestDownloadCount, 0);
    expect(driveClient.writeRequestCount, 0);
  });

  test('child recovery subject mismatch fails closed before Drive write',
      () async {
    final record = _familyLinkRecord(
      parentMemberId: 'parent-member-1',
      parentSubjectId: 'parent-subject-1',
      childSubjectId: 'other-child-subject',
    );
    final driveClient = _FamilyManifestRecoveryDriveClient(
      childManifest: FamilyDriveLinkManifest(
        ownerRole: FamilyDriveLinkOwnerRole.child,
        familyId: record.familyId,
        datasetId: record.datasetId,
        playerId: record.playerId,
        records: <FamilyDriveLinkRecord>[record],
        createdAt: DateTime.utc(2026, 8, 27, 10),
        updatedAt: DateTime.utc(2026, 8, 27, 10),
      ),
    );
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'child@example.com',
        displayName: 'Child',
        subjectId: 'child-subject',
      ),
      driveApiLoader: ({required bool requireInteractive}) async {
        return drive.DriveApi(driveClient);
      },
    );

    final result = await service.refreshFamilySharedDataIfNeeded();

    expect(result.refreshed, isFalse);
    expect(
      FamilyDriveLinkStore(HiveOptionRepository(optionBox)).loadRecords(),
      isEmpty,
    );
    expect(driveClient.manifestDownloadCount, 1);
    expect(driveClient.writeRequestCount, 0);
  });

  test('parent recovery subject mismatch fails closed before Drive write',
      () async {
    await optionBox.put(FamilyAccessService.currentRoleLocalKey, 'parent');
    final record = _familyLinkRecord(
      parentMemberId: 'parent-member-1',
      parentSubjectId: 'other-parent-subject',
    );
    final driveClient = _FamilyManifestRecoveryDriveClient(
      parentManifest: FamilyDriveLinkManifest(
        ownerRole: FamilyDriveLinkOwnerRole.parent,
        familyId: record.familyId,
        datasetId: record.datasetId,
        playerId: record.playerId,
        records: <FamilyDriveLinkRecord>[record],
        createdAt: DateTime.utc(2026, 8, 27, 10),
        updatedAt: DateTime.utc(2026, 8, 27, 10),
      ),
    );
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'parent@example.com',
        displayName: 'Parent',
        subjectId: 'parent-subject',
      ),
      driveApiLoader: ({required bool requireInteractive}) async {
        return drive.DriveApi(driveClient);
      },
    );

    final result = await service.refreshFamilySharedDataIfNeeded();

    expect(result.refreshed, isFalse);
    expect(
      FamilyDriveLinkStore(HiveOptionRepository(optionBox)).loadRecords(),
      isEmpty,
    );
    expect(driveClient.manifestDownloadCount, 1);
    expect(driveClient.writeRequestCount, 0);
  });

  test('normal Drive sign-out never revokes OAuth access', () async {
    final google = _CountingGoogleSignIn();
    service = DriveBackupService(
      trainingBox,
      optionBox,
      googleSignIn: google,
      backupAssetFileStore: assetStore,
    );

    await service.signOut();
    await service.revokeGoogleAppAccess();

    expect(google.signOutCount, 1);
    expect(google.disconnectCount, 1);
    await google.close();
  });

  test('interrupted restore journal is rolled back on startup', () async {
    await trainingBox.add(_trainingEntry(
      recordId: 'entry-1',
      notes: 'before restore',
    ));
    await optionBox.put('profile_name', 'Before');
    final rollback = service.buildBackupForTesting();
    await service.writeRestoreTransactionJournalForTesting(
      rollback: rollback,
      planHash: 'test-plan',
      mode: RestoreMode.safeMerge,
    );

    await trainingBox.clear();
    await trainingBox.add(_trainingEntry(
      recordId: 'partial',
      notes: 'partial restore',
    ));
    await optionBox.put('profile_name', 'Partial');

    final recovered = await DriveBackupService.recoverInterruptedRestoreJournal(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
    );
    final recoveredAgain =
        await DriveBackupService.recoverInterruptedRestoreJournal(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
    );

    expect(recovered, isTrue);
    expect(recoveredAgain, isFalse);
    expect(trainingBox.length, 1);
    expect(trainingBox.values.single.notes, 'before restore');
    expect(optionBox.get('profile_name'), 'Before');
  });

  test('failed startup rollback retains the journal for another recovery',
      () async {
    await optionBox.put(
      'drive_restore_transaction_journal_v1',
      <String, dynamic>{
        'status': 'applying',
        'rollback': '{not-valid-json',
      },
    );

    await expectLater(
      DriveBackupService.recoverInterruptedRestoreJournal(
        trainingBox,
        optionBox,
        backupAssetFileStore: assetStore,
      ),
      throwsA(isA<StateError>()),
    );
    expect(service.hasPendingRestoreTransactionForTesting(), isTrue);
  });

  test('empty unbound install adopts the remote dataset and player ids',
      () async {
    final local = service.buildBackupForTesting();
    final remote = jsonDecode(jsonEncode(local)) as Map<String, dynamic>;
    final manifest = remote['safetyManifest'] as Map<String, dynamic>;
    manifest['datasetId'] = 'dataset-from-remote';
    manifest['playerId'] = 'player-from-remote';
    manifest['familyId'] = 'family-from-remote';

    expect(
      () => service.validateRestoreBindingForTesting(remote),
      returnsNormally,
    );
    await service.restoreFromMapForTesting(
      remote,
      mode: RestoreMode.exactReplace,
    );

    final restored = service.buildBackupForTesting();
    final restoredManifest = restored['safetyManifest'] as Map<String, dynamic>;
    expect(restoredManifest['datasetId'], 'dataset-from-remote');
    expect(restoredManifest['playerId'], 'player-from-remote');
    expect(
      optionBox.get(FamilyAccessService.familyIdKey),
      'family-from-remote',
    );
  });

  test('normal restore rejects different identity when local core data exists',
      () async {
    await trainingBox.add(_trainingEntry(
      recordId: 'local-entry',
      notes: 'local core data',
    ));
    final remote = jsonDecode(
      jsonEncode(service.buildBackupForTesting()),
    ) as Map<String, dynamic>;
    final manifest = remote['safetyManifest'] as Map<String, dynamic>;
    manifest['datasetId'] = 'different-dataset';
    manifest['playerId'] = 'different-player';

    expect(
      () => service.validateRestoreBindingForTesting(remote),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          DriveBackupService.backupDatasetMismatchErrorCode,
        ),
      ),
    );
  });

  test('explicit account import replaces prior local identity safely',
      () async {
    await optionBox.put(
      DriveBackupService.recordDriveEmailLocalKey,
      'old@example.com',
    );
    await optionBox.put(
      DriveBackupService.recordDriveSubjectLocalKey,
      'old-subject',
    );
    await trainingBox.add(_trainingEntry(
      recordId: 'entry-1',
      notes: 'remote player record',
    ));
    final remote = jsonDecode(
      jsonEncode(service.buildBackupForTesting()),
    ) as Map<String, dynamic>;
    final manifest = remote['safetyManifest'] as Map<String, dynamic>;
    manifest['datasetId'] = 'new-dataset';
    manifest['playerId'] = 'new-player';
    manifest['accountEmail'] = 'new@example.com';
    manifest['accountSubjectId'] = 'new-subject';
    remote['driveAccount'] = <String, dynamic>{
      'email': 'new@example.com',
      'label': 'New Player · new@example.com',
      'subjectId': 'new-subject',
    };

    final imported = await service.syncConnectedPlayerBackupForTesting(
      connectedAccount: const DriveConnectionInfo(
        email: 'new@example.com',
        displayName: 'New Player',
        subjectId: 'new-subject',
      ),
      remoteBackup: remote,
    );

    expect(imported, isTrue);
    final restoredManifest = service.buildBackupForTesting()['safetyManifest']
        as Map<String, dynamic>;
    expect(restoredManifest['datasetId'], 'new-dataset');
    expect(restoredManifest['playerId'], 'new-player');
    expect(service.getSavedRecordDriveEmail(), 'new@example.com');
  });

  test('rejects a backup whose SHA-256 safety hash was tampered', () async {
    final backup = service.buildBackupForTesting();
    (backup['entries'] as List).add(const <String, dynamic>{});

    expect(
      () => service.restoreFromMapForTesting(backup),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          DriveBackupService.invalidBackupPayloadErrorCode,
        ),
      ),
    );
  });

  test('keeps three local recovery points and restores a selected point',
      () async {
    for (final profileName in <String>['A', 'B', 'C', 'D']) {
      await optionBox.put('profile_name', profileName);
      await service.saveLocalPreRestoreForTesting();
    }
    final points = service.getLocalRecoveryPoints();
    expect(points, hasLength(3));

    await optionBox.put('profile_name', 'Temporary');
    await service.restoreLocalRecoveryPoint(points.last.id);

    expect(optionBox.get('profile_name'), 'B');
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

    expect(driveClient.copiedHistoryCount, 1);
    expect(driveClient.createdHistoryCount, 0);
    expect(driveClient.createdPreviousCount, 1);
    expect(driveClient.updatedActiveCount, 1);
    expect(driveClient.trashedHistoryCount, 1);
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
        driveApiLoader: ({required bool requireInteractive}) async {
          return drive.DriveApi(_RemoteBackupDriveClient(hasBackup: false));
        },
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

  test('empty start refuses to replace a meaningful backup on the new account',
      () async {
    final driveClient = _OverwriteGuardDriveClient(
      remoteBackup: _remotePlayerBackup(profileName: 'Protected player'),
    );
    service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: assetStore,
      driveConnectionLoader: () async => const DriveConnectionInfo(
        email: 'new@example.com',
        displayName: 'New player',
        subjectId: 'new-subject',
      ),
      driveApiLoader: ({required bool requireInteractive}) async {
        return drive.DriveApi(driveClient);
      },
    );
    await optionBox.put(
      DriveBackupService.recordDriveSubjectLocalKey,
      'old-subject',
    );

    await expectLater(
      service.startChangedPlayerDriveWithEmptyData(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          DriveBackupService.remoteBackupOverwriteBlockedErrorCode,
        ),
      ),
    );
    expect(driveClient.writeRequestCount, 0);
  });
}

bool _containsValue(Object? value, String expected) {
  if (value == expected) return true;
  if (value is Map) {
    return value.values.any((item) => _containsValue(item, expected));
  }
  if (value is Iterable) {
    return value.any((item) => _containsValue(item, expected));
  }
  return false;
}

class _LinkedFamilyContributionDriveClient extends http.BaseClient {
  _LinkedFamilyContributionDriveClient({
    required this.remoteContribution,
    required this.contributionFileId,
  });

  final Map<String, dynamic> remoteContribution;
  final String contributionFileId;
  int contributionDownloadCount = 0;
  int contributionUpdateCount = 0;
  int coreWriteCount = 0;
  String lastUploadedFileName = '';
  Map<String, dynamic>? uploadedContribution;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method == 'GET' &&
        request.url.path.endsWith('/drive/v3/files/$contributionFileId')) {
      contributionDownloadCount += 1;
      final bytes = utf8.encode(jsonEncode(remoteContribution));
      return http.StreamedResponse(
        Stream<List<int>>.value(bytes),
        200,
        request: request,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    }

    if (request.method == 'PATCH' &&
        request.url.path
            .endsWith('/upload/drive/v3/files/$contributionFileId')) {
      contributionUpdateCount += 1;
      final body = await utf8.decoder.bind(request.finalize()).join();
      uploadedContribution = _extractBackupPayloadFromMultipart(body);
      lastUploadedFileName =
          RegExp(r'"name":"([^"]+)"').firstMatch(body)?.group(1) ?? '';
      return _jsonResponse(request, const <String, Object?>{
        'id': 'linked-contribution-file-id',
        'modifiedTime': '2026-08-27T10:05:00.000Z',
      });
    }

    if (request.method != 'GET') {
      coreWriteCount += 1;
    }
    throw StateError(
      'Unexpected linked Drive request: ${request.method} ${request.url}',
    );
  }

  Map<String, dynamic> _extractBackupPayloadFromMultipart(String body) {
    final start = body.indexOf('{"format":');
    if (start >= 0) {
      final end = body.indexOf('\r\n--', start);
      final payload =
          (end < 0 ? body.substring(start) : body.substring(start, end)).trim();
      return jsonDecode(payload) as Map<String, dynamic>;
    }

    const transferEncodingMarker = 'Content-Transfer-Encoding: base64';
    final marker = body.indexOf(transferEncodingMarker);
    if (marker >= 0) {
      final bodyStart = body.indexOf('\r\n\r\n', marker);
      final normalizedStart =
          bodyStart >= 0 ? bodyStart + 4 : body.indexOf('\n\n', marker) + 2;
      if (normalizedStart > 1) {
        var bodyEnd = body.indexOf('\r\n--', normalizedStart);
        if (bodyEnd < 0) {
          bodyEnd = body.indexOf('\n--', normalizedStart);
        }
        final encoded = (bodyEnd < 0
                ? body.substring(normalizedStart)
                : body.substring(
                    normalizedStart,
                    bodyEnd,
                  ))
            .replaceAll(RegExp(r'\s+'), '');
        return jsonDecode(utf8.decode(base64Decode(encoded)))
            as Map<String, dynamic>;
      }
    }
    throw StateError('Linked contribution upload did not contain backup JSON.');
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

class _FamilyManifestRecoveryDriveClient extends http.BaseClient {
  _FamilyManifestRecoveryDriveClient({
    this.childManifest,
    this.parentManifest,
    this.contributionFileId = '',
    this.contributionPayload,
    this.failingChildManifestListResponses = 0,
  });

  final FamilyDriveLinkManifest? childManifest;
  final FamilyDriveLinkManifest? parentManifest;
  final String contributionFileId;
  final Map<String, dynamic>? contributionPayload;
  int failingChildManifestListResponses;
  int folderListCount = 0;
  int childManifestListCount = 0;
  int parentManifestListCount = 0;
  int manifestDownloadCount = 0;
  int contributionDownloadCount = 0;
  int writeRequestCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method == 'GET' &&
        request.url.path.endsWith('/drive/v3/files')) {
      final query = request.url.queryParameters['q'] ?? '';
      if (query.contains("mimeType='application/vnd.google-apps.folder'") &&
          query.contains("name='${DriveBackupService.backupFolderName}'")) {
        folderListCount += 1;
        return _jsonResponse(request, const <String, Object?>{
          'files': <Map<String, String>>[
            <String, String>{
              'id': 'folder-id',
              'name': DriveBackupService.backupFolderName,
            },
          ],
        });
      }
      if (query.contains("'folder-id' in parents") &&
          query.contains("value='childManifest'")) {
        childManifestListCount += 1;
        if (failingChildManifestListResponses > 0) {
          failingChildManifestListResponses -= 1;
          throw StateError('transient child manifest list failed');
        }
        return _manifestListResponse(
          request,
          fileId: 'child-manifest-id',
          manifest: childManifest,
        );
      }
      if (query.contains("'folder-id' in parents") &&
          query.contains("value='parentManifest'")) {
        parentManifestListCount += 1;
        return _manifestListResponse(
          request,
          fileId: 'parent-manifest-id',
          manifest: parentManifest,
        );
      }
      return _jsonResponse(request, const <String, Object?>{'files': []});
    }

    if (request.method == 'GET' &&
        request.url.path.endsWith('/drive/v3/files/child-manifest-id')) {
      manifestDownloadCount += 1;
      return _mapResponse(request, childManifest!.toMap());
    }
    if (request.method == 'GET' &&
        request.url.path.endsWith('/drive/v3/files/parent-manifest-id')) {
      manifestDownloadCount += 1;
      return _mapResponse(request, parentManifest!.toMap());
    }
    if (request.method == 'GET' &&
        contributionFileId.isNotEmpty &&
        request.url.path.endsWith('/drive/v3/files/$contributionFileId')) {
      if (request.url.queryParameters['alt'] == 'media') {
        contributionDownloadCount += 1;
        return _mapResponse(request, contributionPayload!);
      }
      return _jsonResponse(request, <String, Object?>{
        'id': contributionFileId,
        'name': 'family_contribution.json',
        'modifiedTime': '2026-08-27T12:00:00.000Z',
        'capabilities': const <String, Object?>{'canEdit': true},
        'trashed': false,
      });
    }

    if (request.method != 'GET') {
      writeRequestCount += 1;
      throw StateError('Unexpected Drive write request: ${request.method}');
    }
    return _jsonResponse(request, const <String, Object?>{'files': []});
  }

  http.StreamedResponse _manifestListResponse(
    http.BaseRequest request, {
    required String fileId,
    required FamilyDriveLinkManifest? manifest,
  }) {
    return _jsonResponse(request, <String, Object?>{
      'files': manifest == null
          ? const <Map<String, String>>[]
          : <Map<String, String>>[
              <String, String>{
                'id': fileId,
                'name': 'family_links_manifest_v2.json',
                'modifiedTime': '2026-08-27T12:00:00.000Z',
              },
            ],
    });
  }

  http.StreamedResponse _mapResponse(
    http.BaseRequest request,
    Map<String, dynamic> payload,
  ) {
    final bytes = utf8.encode(jsonEncode(payload));
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      200,
      request: request,
      headers: const <String, String>{'content-type': 'application/json'},
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

class _CountingGoogleSignIn extends GoogleSignIn {
  _CountingGoogleSignIn() : super(scopes: const <String>[]);

  final StreamController<GoogleSignInAccount?> _controller =
      StreamController<GoogleSignInAccount?>.broadcast();
  int signOutCount = 0;
  int disconnectCount = 0;

  @override
  Stream<GoogleSignInAccount?> get onCurrentUserChanged => _controller.stream;

  @override
  Future<GoogleSignInAccount?> signOut() async {
    signOutCount += 1;
    return null;
  }

  @override
  Future<GoogleSignInAccount?> disconnect() async {
    disconnectCount += 1;
    return null;
  }

  Future<void> close() => _controller.close();
}

class _ContributionWriteDriveClient extends http.BaseClient {
  _ContributionWriteDriveClient({required this.contributionFileName});

  final String contributionFileName;
  int contributionWriteCount = 0;
  int playerSnapshotWriteCount = 0;
  Map<String, dynamic>? uploadedContribution;

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
          query.contains("name='$contributionFileName'")) {
        return _jsonResponse(request, const <String, Object?>{
          'files': <Map<String, String>>[],
        });
      }
      if (query.contains("'folder-id' in parents") &&
          query.contains("name='${DriveBackupService.backupFileName}'")) {
        return _jsonResponse(request, <String, Object?>{
          'files': <Map<String, String>>[
            <String, String>{
              'id': 'player-backup-id',
              'name': DriveBackupService.backupFileName,
            },
          ],
        });
      }
      return _jsonResponse(request, const <String, Object?>{'files': []});
    }

    if (request.method == 'POST' &&
        request.url.path.endsWith('/upload/drive/v3/files')) {
      final body = await utf8.decoder.bind(request.finalize()).join();
      if (body.contains(DriveBackupService.backupFileName)) {
        playerSnapshotWriteCount += 1;
      }
      if (body.contains(contributionFileName)) {
        contributionWriteCount += 1;
        uploadedContribution = _extractBackupPayloadFromMultipart(body);
        return _jsonResponse(request, const <String, Object?>{
          'id': 'contribution-id',
          'modifiedTime': '2026-04-20T10:00:00.000Z',
        });
      }
    }

    if (request.method == 'PATCH' &&
        request.url.path.contains('/upload/drive/v3/files/player-backup-id')) {
      playerSnapshotWriteCount += 1;
    }
    throw StateError(
      'Unexpected Drive request: ${request.method} ${request.url}',
    );
  }

  Map<String, dynamic> _extractBackupPayloadFromMultipart(String body) {
    final start = body.indexOf('{"format":');
    if (start >= 0) {
      final end = body.indexOf('\r\n--', start);
      final payload =
          (end < 0 ? body.substring(start) : body.substring(start, end)).trim();
      return jsonDecode(payload) as Map<String, dynamic>;
    }

    const transferEncodingMarker = 'Content-Transfer-Encoding: base64';
    final marker = body.indexOf(transferEncodingMarker);
    if (marker >= 0) {
      final bodyStart = body.indexOf('\r\n\r\n', marker);
      final normalizedStart =
          bodyStart >= 0 ? bodyStart + 4 : body.indexOf('\n\n', marker) + 2;
      if (normalizedStart > 1) {
        var bodyEnd = body.indexOf('\r\n--', normalizedStart);
        if (bodyEnd < 0) {
          bodyEnd = body.indexOf('\n--', normalizedStart);
        }
        final encoded = (bodyEnd < 0
                ? body.substring(normalizedStart)
                : body.substring(
                    normalizedStart,
                    bodyEnd,
                  ))
            .replaceAll(RegExp(r'\s+'), '');
        return jsonDecode(utf8.decode(base64Decode(encoded)))
            as Map<String, dynamic>;
      }
    }
    throw StateError('Contribution upload did not contain backup JSON.');
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

  Map<String, dynamic> remoteBackup;
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
  int copiedHistoryCount = 0;
  int createdPreviousCount = 0;
  int updatedActiveCount = 0;
  int trashedHistoryCount = 0;

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
            13,
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
        request.url.path.endsWith('/drive/v3/files/backup-id/copy')) {
      copiedHistoryCount += 1;
      return _jsonResponse(request, const <String, Object?>{
        'id': 'copied-history-id',
        'modifiedTime': '2026-04-20T10:01:00.000Z',
      });
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
    if (request.method == 'PATCH' &&
        request.url.path.contains('/drive/v3/files/history-')) {
      trashedHistoryCount += 1;
      return _jsonResponse(request, const <String, Object?>{
        'id': 'history-12',
      });
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
