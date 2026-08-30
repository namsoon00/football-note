import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import 'backup_asset_store.dart';
import 'backup_asset_store_types.dart';
import 'backup_restore_plan.dart';
import 'challenge_service.dart';
import 'club_schedule_service.dart';
import 'club_training_reminder_service.dart';
import 'coach_roster_service.dart';
import 'drive_connection_info.dart';
import 'family_drive_link_service.dart';
import 'league_fixture_reminder_service.dart';
import 'match_competition_service.dart';
import 'meal_log_service.dart';
import 'news_badge_service.dart';
import 'news_read_state.dart';
import '../domain/entities/training_entry.dart';
import '../domain/entities/sport_definition.dart';
import '../domain/repositories/backup_repository.dart';
import '../infrastructure/hive_option_repository.dart';
import 'family_access_service.dart';
import 'parent_shared_feedback_service.dart';
import 'player_level_service.dart';
import 'player_profile_service.dart';
import 'running_coach_history_service.dart';
import 'running_growth_service.dart';
import 'team_management_service.dart';
import 'training_board_service.dart';
import 'training_plan_reminder_service.dart';
import 'weather_reminder_service.dart';

enum PlayerDriveBindingState {
  notApplicable,
  notConnected,
  unbound,
  verified,
  legacyEmailMatch,
  accountMismatch,
}

class LocalBackupRecoveryPoint {
  const LocalBackupRecoveryPoint({
    required this.id,
    required this.createdAt,
  });

  final String id;
  final DateTime createdAt;
}

class DriveBackupService implements BackupRepository {
  DriveBackupService(
    this._trainingBox,
    this._optionBox, {
    GoogleSignIn? googleSignIn,
    FirebaseAuth? firebaseAuth,
    BackupAssetFileStore? backupAssetFileStore,
    Future<DriveConnectionInfo?> Function()? driveConnectionLoader,
    Future<drive.DriveApi> Function({required bool requireInteractive})?
        driveApiLoader,
    Future<void> Function()? driveScopeReauthenticator,
    String? webClientId,
  })  : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId: _googleClientIdForPlatform(webClientId),
              scopes: const ['email', _driveScope],
            ),
        _firebaseAuth = firebaseAuth ?? _safeFirebaseAuth(),
        _backupAssetFileStore =
            backupAssetFileStore ?? createBackupAssetFileStore(),
        _driveConnectionLoader = driveConnectionLoader,
        _driveApiLoader = driveApiLoader,
        _driveScopeReauthenticator = driveScopeReauthenticator {
    _bindDriveAccountStateChanges();
  }

  final Box<TrainingEntry> _trainingBox;
  final Box _optionBox;
  final GoogleSignIn? _googleSignIn;
  final FirebaseAuth? _firebaseAuth;
  final BackupAssetFileStore _backupAssetFileStore;
  final Future<DriveConnectionInfo?> Function()? _driveConnectionLoader;
  final Future<drive.DriveApi> Function({required bool requireInteractive})?
      _driveApiLoader;
  final Future<void> Function()? _driveScopeReauthenticator;
  final StreamController<void> _driveAccountStateController =
      StreamController<void>.broadcast();
  final StreamController<void> _dataChangeController =
      StreamController<void>.broadcast();
  Future<void> _driveMutationTail = Future<void>.value();
  String? _webAccessToken;
  StreamSubscription<GoogleSignInAccount?>? _googleAccountSubscription;
  StreamSubscription<User?>? _firebaseAuthSubscription;
  DriveConnectionInfo? _recentDriveConnection;
  DateTime? _recentDriveConnectionExpiresAt;
  GoogleSignInAccount? _lastSilentSignInAccount;
  DateTime? _lastSilentSignInAt;
  bool _familyLinkRecoveryInFlight = false;
  final Map<String, DateTime> _familyLinkNoManifestRecoveryCheckedAt =
      <String, DateTime>{};

  static const String _defaultWebClientId =
      '771305087734-atioeqhkpt2f0kqqhqq54nqkqi8630ju.apps.googleusercontent.com';

  static String? _googleClientIdForPlatform(String? webClientId) {
    final explicit = webClientId?.trim() ?? '';
    if (explicit.isNotEmpty) return explicit;
    return kIsWeb ? _defaultWebClientId : null;
  }

  static FirebaseAuth? _safeFirebaseAuth() {
    if (kIsWeb) {
      try {
        if (Firebase.apps.isEmpty) {
          return null;
        }
      } catch (_) {
        return null;
      }
    }
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> recoverInterruptedRestoreJournal(
    Box<TrainingEntry> trainingBox,
    Box optionBox, {
    BackupAssetFileStore? backupAssetFileStore,
  }) async {
    final raw = optionBox.get(_restoreTransactionJournalKey);
    if (raw is! Map || raw['status'] != 'applying') {
      return false;
    }
    final rollback = raw['rollback'];
    if (rollback is! String || rollback.trim().isEmpty) {
      await optionBox.delete(_restoreTransactionJournalKey);
      return false;
    }
    final service = DriveBackupService(
      trainingBox,
      optionBox,
      backupAssetFileStore: backupAssetFileStore,
    );
    await service
        ._restoreFromMapInternal(service._decodeBackupPayload(rollback));
    await optionBox.delete(_restoreTransactionJournalKey);
    return true;
  }

  static const _autoDailyKey = 'drive_auto_daily';
  static const _autoOnSaveKey = 'drive_auto_on_save';
  static const _lastBackupKey = 'drive_last_backup';
  static const _lastRecordBackupKey = 'drive_last_record_backup_v1';
  static const _previousBackupCreatedAtKey =
      'drive_previous_backup_created_at_v1';
  static const _localDatasetIdKey = 'drive_local_dataset_id_v1';
  static const _localDeviceIdKey = 'drive_local_device_id_v1';
  static const _localPlayerIdKey = 'drive_local_player_id_v1';
  static const _restoreBaselineHashesKey = 'drive_restore_baseline_hashes_v1';
  static const _restoreTransactionJournalKey =
      'drive_restore_transaction_journal_v1';
  static const _lastFamilySyncPushAtKey = 'drive_last_family_sync_push_v1';
  static const _lastFamilySyncPullAtKey = 'drive_last_family_sync_pull_v1';
  static const _lastFamilyRemoteSnapshotAtKey =
      'drive_last_family_remote_snapshot_v1';
  static const _parentSharedDataDirtyKey = 'drive_parent_shared_dirty_v1';
  static const _localPreRestoreKey = 'local_pre_restore_backup';
  static const _localPreRestoreAtKey = 'local_pre_restore_backup_at';
  static const _localPreRestoreSnapshotsKey = 'local_pre_restore_backups_v2';
  static const _remoteReceiptKeyPrefix = 'drive_remote_receipt_v2_';
  static const _lastRecoverySnapshotAtKeyPrefix =
      'drive_recovery_snapshot_at_v2_';
  static const _lastAutoOnSaveBackupAtKey =
      'drive_auto_on_save_last_backup_at_v2';
  static const connectedDriveEmailLocalKey = 'drive_connected_email_local_v1';
  static const connectedDriveLabelLocalKey = 'drive_connected_label_local_v1';
  static const connectedDriveSubjectLocalKey =
      'drive_connected_subject_local_v1';
  static const recordDriveEmailLocalKey = 'drive_player_email_local_v1';
  static const recordDriveLabelLocalKey = 'drive_player_label_local_v1';
  static const recordDriveSubjectLocalKey = 'drive_player_subject_local_v1';
  static const playerDriveEmailLocalKey = 'drive_player_email_local_v1';
  static const playerDriveLabelLocalKey = 'drive_player_label_local_v1';
  static const playerDriveSubjectLocalKey = 'drive_player_subject_local_v1';
  static const parentDriveEmailLocalKey = 'drive_parent_email_local_v1';
  static const parentDriveLabelLocalKey = 'drive_parent_label_local_v1';
  static const parentDriveSubjectLocalKey = 'drive_parent_subject_local_v1';
  static const sharedChildDriveEmailKey = 'drive_child_email_v1';
  static const sharedChildDriveLabelKey = 'drive_child_label_v1';
  static const sharedChildDriveSubjectLocalKey = 'drive_child_subject_v1';
  static const backupFolderName = 'teo';
  static final String _legacyKoreanBackupFolderName = String.fromCharCodes(
    const <int>[53468, 50724, 51032, 45432, 53944],
  );
  static final String _legacyFootballNoteBackupFolderName =
      String.fromCharCodes(
    const <int>[70, 111, 111, 116, 98, 97, 108, 108, 32, 78, 111, 116, 101],
  );
  static final List<String> _legacyBackupFolderNames = <String>[
    _legacyKoreanBackupFolderName,
    _legacyFootballNoteBackupFolderName,
  ];
  static const coachRosterFileName = 'coach_roster.json';
  static const backupFileName = 'teo_note_backup.json';
  static const previousBackupFileName = 'teo_note_backup_previous.json';
  static final String _legacyMisspelledFileName = String.fromCharCodes(
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
      46,
      106,
      115,
      111,
      110,
    ],
  );
  static final String _legacyFootballNoteFileName = String.fromCharCodes(
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
      46,
      106,
      115,
      111,
      110,
    ],
  );
  static final List<String> _legacyFileNames = <String>[
    _legacyMisspelledFileName,
    _legacyFootballNoteFileName,
  ];
  static final String _legacyPreviousMisspelledFileName = String.fromCharCodes(
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
      95,
      112,
      114,
      101,
      118,
      105,
      111,
      117,
      115,
      46,
      106,
      115,
      111,
      110,
    ],
  );
  static final String _legacyFootballNotePreviousFileName =
      String.fromCharCodes(
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
      95,
      112,
      114,
      101,
      118,
      105,
      111,
      117,
      115,
      46,
      106,
      115,
      111,
      110,
    ],
  );
  static final List<String> _legacyPreviousFileNames = <String>[
    _legacyPreviousMisspelledFileName,
    _legacyFootballNotePreviousFileName,
  ];
  static String get backupDisplayPath =>
      'Google Drive > $backupFolderName > $backupFileName';
  static String get previousBackupDisplayPath =>
      'Google Drive > $backupFolderName > $previousBackupFileName';
  static String playerBackupFileName(String playerId) =>
      'player_${CoachRosterService.fileSafePlayerId(playerId)}_backup.json';
  static String previousPlayerBackupFileName(String playerId) =>
      'player_${CoachRosterService.fileSafePlayerId(playerId)}_backup_previous.json';
  static String familyContributionFileName({
    required String playerId,
    required String familyId,
  }) {
    final safePlayerId = CoachRosterService.fileSafePlayerId(
      playerId.trim().isEmpty ? 'default_player' : playerId.trim(),
    );
    final safeFamilyId = CoachRosterService.fileSafePlayerId(
      familyId.trim().isEmpty ? 'unlinked_family' : familyId.trim(),
    );
    return 'family_${safePlayerId}_${safeFamilyId}_contribution.json';
  }

  static String familyMemberContributionFileName({
    required String playerId,
    required String familyId,
    required String parentMemberId,
  }) {
    final safePlayerId = CoachRosterService.fileSafePlayerId(
      playerId.trim().isEmpty ? 'default_player' : playerId.trim(),
    );
    final safeFamilyId = CoachRosterService.fileSafePlayerId(
      familyId.trim().isEmpty ? 'unlinked_family' : familyId.trim(),
    );
    final safeMemberId = CoachRosterService.fileSafePlayerId(
      parentMemberId.trim().isEmpty ? 'parent_member' : parentMemberId.trim(),
    );
    return 'family_${safePlayerId}_${safeFamilyId}_${safeMemberId}_contribution.json';
  }

  static String playerBackupDisplayPath(String playerId) =>
      'Google Drive > $backupFolderName > ${playerBackupFileName(playerId)}';
  static String previousPlayerBackupDisplayPath(String playerId) =>
      'Google Drive > $backupFolderName > ${previousPlayerBackupFileName(playerId)}';
  static String familyContributionDisplayPath({
    required String playerId,
    required String familyId,
  }) =>
      'Google Drive > $backupFolderName > ${familyContributionFileName(
        playerId: playerId,
        familyId: familyId,
      )}';
  static const _folderName = backupFolderName;
  static const _backupFolderMarkerKey = 'teoBackupFolder';
  static const _backupFolderMarkerValue = 'v1';
  static const _fileName = backupFileName;
  static const _previousFileName = previousBackupFileName;
  static const _historyBackupRetentionCount = 12;
  static const _localRecoverySnapshotRetentionCount = 3;
  static const _autoOnSaveMinimumInterval = Duration(minutes: 5);
  static const _driveScope = 'https://www.googleapis.com/auth/drive.file';
  static const parentDriveMismatchErrorCode = 'parent_drive_mismatch';
  static const parentFamilyMismatchErrorCode = 'parent_family_mismatch';
  static const recordDriveMismatchErrorCode = 'record_drive_mismatch';
  static const playerDriveMismatchErrorCode = recordDriveMismatchErrorCode;
  static const parentModeDriveMismatchErrorCode = 'parent_mode_drive_mismatch';
  static const changedPlayerDriveConnectionErrorCode =
      'changed_player_drive_connection';
  static const changedPlayerRemoteBackupMissingErrorCode =
      'changed_player_remote_backup_missing';
  static const remoteBackupOverwriteBlockedErrorCode =
      'remote_backup_overwrite_blocked';
  static const remoteBackupConflictErrorCode = 'remote_backup_conflict';
  static const driveAccountBindingRequiredErrorCode =
      'drive_account_binding_required';
  static const backupOwnerMismatchErrorCode = 'backup_owner_mismatch';
  static const backupDatasetMismatchErrorCode = 'backup_dataset_mismatch';
  static const backupPlayerMismatchErrorCode = 'backup_player_mismatch';
  static const familyLinkPermissionRevokedErrorCode =
      FamilyDriveLinkException.permissionRevoked;
  static const familyLinkAccountMismatchErrorCode =
      FamilyDriveLinkException.accountMismatch;
  static const backupPreviewChangedErrorCode = 'backup_preview_changed';
  static const invalidBackupPayloadErrorCode = 'invalid_backup_payload';
  static const unsupportedBackupVersionErrorCode = 'unsupported_backup_version';
  static const unsupportedBackupValueErrorCode = 'unsupported_backup_value';
  static const _recentDriveConnectionTtl = Duration(minutes: 5);
  static const _silentSignInTtl = Duration(minutes: 5);
  static const _familyLinkNoManifestRecoveryCooldown = Duration(minutes: 5);
  static const Set<String> _excludedOptionKeys = {
    _lastBackupKey,
    _lastRecordBackupKey,
    _previousBackupCreatedAtKey,
    _localDatasetIdKey,
    _localDeviceIdKey,
    _localPlayerIdKey,
    _restoreBaselineHashesKey,
    _restoreTransactionJournalKey,
    _lastFamilySyncPushAtKey,
    _lastFamilySyncPullAtKey,
    _lastFamilyRemoteSnapshotAtKey,
    _parentSharedDataDirtyKey,
    _localPreRestoreKey,
    _localPreRestoreAtKey,
    _localPreRestoreSnapshotsKey,
    FamilyAccessService.messagesKey,
    connectedDriveEmailLocalKey,
    connectedDriveLabelLocalKey,
    connectedDriveSubjectLocalKey,
    recordDriveEmailLocalKey,
    recordDriveLabelLocalKey,
    recordDriveSubjectLocalKey,
    parentDriveEmailLocalKey,
    parentDriveLabelLocalKey,
    parentDriveSubjectLocalKey,
    FamilyDriveLinkStore.activeLinkIdKey,
    FamilyDriveLinkStore.linkRecordsKey,
    FamilyDriveLinkStore.usedInviteIdsKey,
    FamilyDriveLinkStore.pendingOffersKey,
    ...FamilyAccessService.localOnlyOptionKeys,
  };
  static const Set<String> _backedUpOptionKeys = {
    // Profile and app-owned player state.
    ...PlayerProfileService.optionKeys,
    SportCatalog.currentSportOptionKey,

    // Training entry defaults and user-managed option lists.
    'durations',
    'default_duration',
    'default_location',
    'type_options',
    'programs',
    'daily_goals',
    'default_program',
    'injury_parts',
    'match_locations',

    // Primary user records stored in the option box.
    TrainingPlanReminderService.plansStorageKey,
    MealLogService.storageKey,
    TrainingBoardService.storageKey,
    TeamManagementService.storageKey,
    MatchCompetitionService.storageKey,
    ChallengeService.storageKey,
    RunningCoachHistoryService.storageKey,
    RunningGrowthService.storageKey,
    'custom_diary_entries_v3',
    'coach_diary_completed_day_v2',
    'diary_theme_v1',
    'home_hub_sections_v1',
    'home_hub_section_usage_v1',

    // Progression and reward state.
    PlayerLevelService.totalXpKey,
    PlayerLevelService.xpHistoryKey,
    PlayerLevelService.quizRewardDayKey,
    PlayerLevelService.awardedPlanIdsKey,
    PlayerLevelService.awardedMatchLogTokensKey,
    PlayerLevelService.awardedStreaksKey,
    PlayerLevelService.awardedBoardSaveTokensKey,
    PlayerLevelService.awardedRoutineDaysKey,
    PlayerLevelService.awardedDailyTaskCompletionDaysKey,
    PlayerLevelService.awardedChallengeRoundsKey,
    PlayerLevelService.awardedChallengeCompletionsKey,
    PlayerLevelService.diaryCreatedDayKey,
    PlayerLevelService.claimedRewardLevelsKey,
    PlayerLevelService.customRewardNamesKey,
    PlayerLevelService.rewardClaimMessagesKey,

    // Coach roster and active player selection.
    CoachRosterService.rosterPlayersKey,
    CoachRosterService.activePlayerIdKey,
    ClubScheduleService.storageKey,

    // Family-shared record layer.
    FamilyAccessService.linkedRoleKey,
    FamilyAccessService.familyIdKey,
    FamilyAccessService.childNameKey,
    FamilyAccessService.parentNameKey,
    FamilyAccessService.parentTrainingFeedbackKey,
    FamilyAccessService.lastSharedSyncAtKey,
    FamilyAccessService.lastSharedSyncRoleKey,
    sharedChildDriveEmailKey,
    sharedChildDriveLabelKey,
    sharedChildDriveSubjectLocalKey,

    // Quiz and game progress that is meaningful across devices.
    'skill_quiz_completed_at',
    'skill_quiz_session_v1',
    'skill_quiz_pending_wrong_v1',
    'skill_quiz_pending_wrong_schedule_v1',
    'skill_quiz_pending_wrong_schedule_v2',
    'skill_quiz_metrics_v1',
    'skill_quiz_recent_performance_v1',
    'skill_quiz_daily_questions_v2',
    'skill_quiz_daily_questions_day_v2',
    'skill_quiz_cleared_sets_v1',
    'skill_quiz_category_stats_v1',
    'skill_quiz_history_v1',
    'space_speed_ranking_history_v1',
    'space_speed_played_count_v1',

    // News, fixture, and tournament user state used by diary or favorites.
    'news_opened_items_v1',
    'news_scrapped_links',
    'news_scrapped_items_v1',
    'news_source_open_counts_v1',
    'news_blocked_domains',
    NewsReadState.readArticleKeysKey,
    LeagueFixtureReminderService.favoriteTeamKeysKey,
    'world_cup_support_country_v1',
    'world_cup_interest_countries_v1',
  };
  static const List<String> _backedUpOptionKeyPrefixes = [
    CoachRosterService.scopedOptionKeyPrefix,
    ...PlayerProfileService.sportScopedOptionKeyPrefixes,
    ...PlayerLevelService.sportScopedOptionKeyPrefixes,
    'programs_',
    'daily_goals_',
    'default_program_',
    'durations_',
    'default_duration_',
    'injury_parts_',
    'match_locations_',
    'training_plans_v1_',
    'meal_logs_v1_',
    'training_boards_v1_',
    'club_training_schedule_v1_',
    'match_managed_teams_v1_',
    'match_competitions_v1_',
    'challenge_runs_v1_',
    'running_coach_sessions_v1_',
    'running_growth_records_v1_',
    'custom_diary_entries_v3_',
    'coach_diary_completed_day_v2_',
    'diary_theme_v1_',
    'skill_quiz_completed_at_',
    'skill_quiz_session_v1_',
    'skill_quiz_pending_wrong_v1_',
    'skill_quiz_pending_wrong_schedule_v1_',
    'skill_quiz_pending_wrong_schedule_v2_',
    'skill_quiz_metrics_v1_',
    'skill_quiz_recent_performance_v1_',
    'skill_quiz_daily_questions_v2_',
    'skill_quiz_daily_questions_day_v2_',
    'skill_quiz_cleared_sets_v1_',
    'skill_quiz_category_stats_v1_',
    'skill_quiz_history_v1_',
    'news_opened_items_v1_',
    'news_scrapped_links_',
    'news_scrapped_items_v1_',
    'news_source_open_counts_v1_',
    'news_read_article_keys_v1_',
    'space_speed_ranking_history_v1_',
    'space_speed_played_count_v1_',
    'space_speed_weekly_best_',
  ];
  static const Set<String> _localDeviceOptionKeys = {
    _autoDailyKey,
    _autoOnSaveKey,
    'theme_mode',
    'locale',
    'reminder_enabled',
    'reminder_vibration_enabled',
    'reminder_time',
    'level_up_alert_enabled',
    'xp_alert_enabled',
    'inactivity_alert_enabled',
    'family_sync_alert_enabled',
    'league_fixture_alert_enabled',
    'weather_alert_enabled',
    'weather_alert_time',
    'club_training_alert_enabled',
    'club_training_alert_minutes_before',
    'club_morning_workout_alert_enabled',
    'club_morning_workout_alert_time',
    'club_morning_workout_alert_weekdays',
    'inactivity_alert_days',
    TrainingPlanReminderService.reminderIdsKey,
    TrainingPlanReminderService.reminderReadIdsKey,
    TrainingPlanReminderService.dismissedMessageKeysKey,
    TrainingPlanReminderService.xpMessageLogKey,
    TrainingPlanReminderService.xpMessageReadIdsKey,
    TrainingPlanReminderService.familyMessageLogKey,
    TrainingPlanReminderService.familyMessageReadIdsKey,
    TrainingPlanReminderService.alarmMutedUntilKey,
    TrainingPlanReminderService.inactivityReminderIdsKey,
    TrainingPlanReminderService.challengeReminderIdsKey,
    TrainingPlanReminderService.lastTrainingLogAtKey,
    LeagueFixtureReminderService.reminderIdsKey,
    LeagueFixtureReminderService.worldCupReminderIdsKey,
    LeagueFixtureReminderService.fixtureMessageLogKey,
    LeagueFixtureReminderService.fixtureMessageReadIdsKey,
    WeatherReminderService.reminderIdsKey,
    WeatherReminderService.messageLogKey,
    WeatherReminderService.messageReadIdsKey,
    ClubTrainingReminderService.reminderIdsKey,
    ClubTrainingReminderService.messageLogKey,
    ClubTrainingReminderService.messageReadIdsKey,
    NewsBadgeService.seenArticleKeysKey,
    NewsBadgeService.lastOpenedAtKey,
    NewsBadgeService.lastRefreshAtKey,
    'notification_seen_xp_ids_v1',
    'notification_show_inactivity_section_v1',
    'notification_show_xp_section_v1',
    'notification_show_plan_section_v1',
    'notification_show_family_section_v1',
    'notification_show_fixture_section_v1',
    'home_weather_snapshot_v1',
    'benchmark_physical_by_age_v2',
    'benchmark_lifting_by_age_v2',
    'benchmark_synced_at_v2',
    'calendar_expanded_v1',
    'calendar_format_v1',
    'last_training_plan_reminder_minutes_v1',
    'training_plan_last_reminder_minutes_before_v1',
    'last_training_plan_template_v1',
    'recent_board_id',
    'logs_layout',
    'logs_filter_status',
    'logs_filter_program',
    'logs_filter_injury_only',
    'logs_filter_jump_rope_only',
    'logs_filter_feedback_only',
    'logs_quick_guide_seen_v1',
    'welcome_seen_v1',
    'league_standings_last_selected_league_v1',
    'league_standings_last_selected_type_v1',
    'league_standings_favorite_fixture_filter_types_v1',
    'news_title_translate_enabled',
  };
  static const List<String> _localDeviceOptionKeyPrefixes = [
    'drive_',
    'health_connect_',
    'local_pre_restore_',
    'benchmark_',
    'news_badge_',
    'recent_board_id_',
    'notification_',
    'family_sync_message_',
    'xp_alert_message_',
    'training_plan_last_reminder_minutes_before_v1_',
    'last_training_plan_template_v1_',
    'training_plan_dismissed_message_keys_v1_',
    'last_training_log_at_v1_',
    'league_fixture_message_',
    'logs_filter_',
    'tab_quick_guide_seen_',
  ];
  static const _backupVersion = 7;
  static const _typedValueKey = '__type';
  static const _typedDataKey = 'data';
  static const _optionRecordsKey = 'optionRecords';
  static const _familyMetadataKey = 'family';
  static const _driveAccountMetadataKey = 'driveAccount';
  static const _backupSafetyManifestKey = 'safetyManifest';
  static const _assetRecordsKey = 'assetRecords';
  static const _assetRefPrefix = 'backup_asset://';
  static const _backupFormatKey = 'format';
  static const _backupFormatValue = 'teo_note_backup';
  static final String _legacyMisspelledBackupFormatValue = String.fromCharCodes(
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
  static final String _legacyFootballNoteBackupFormatValue =
      String.fromCharCodes(
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
  static final Set<String> _acceptedBackupFormatValues = <String>{
    _backupFormatValue,
    BackupRestorePlanner.contributionFormatValue,
    _legacyMisspelledBackupFormatValue,
    _legacyFootballNoteBackupFormatValue,
  };
  static const Set<String> _nonMeaningfulBackupOptionKeys = {
    SportCatalog.currentSportOptionKey,
    'durations',
    'default_duration',
    'default_location',
    'type_options',
    'programs',
    'daily_goals',
    'default_program',
    'injury_parts',
    'match_locations',
    FamilyAccessService.linkedRoleKey,
    FamilyAccessService.familyIdKey,
    FamilyAccessService.childNameKey,
    FamilyAccessService.parentNameKey,
    FamilyAccessService.lastSharedSyncAtKey,
    FamilyAccessService.lastSharedSyncRoleKey,
    sharedChildDriveEmailKey,
    sharedChildDriveLabelKey,
    sharedChildDriveSubjectLocalKey,
  };
  static const List<String> _nonMeaningfulBackupOptionKeyPrefixes = [
    'programs_',
    'daily_goals_',
    'default_program_',
    'durations_',
    'default_duration_',
    'injury_parts_',
    'match_locations_',
  ];
  static const Set<String> _coreRecordBackupOptionKeys = {
    TrainingPlanReminderService.plansStorageKey,
    MealLogService.storageKey,
    TrainingBoardService.storageKey,
    TeamManagementService.storageKey,
    MatchCompetitionService.storageKey,
    ChallengeService.storageKey,
    RunningCoachHistoryService.storageKey,
    RunningGrowthService.storageKey,
    'custom_diary_entries_v3',
    'coach_diary_completed_day_v2',
    PlayerLevelService.totalXpKey,
    PlayerLevelService.xpHistoryKey,
    PlayerLevelService.diaryCreatedDayKey,
    PlayerLevelService.claimedRewardLevelsKey,
    PlayerLevelService.rewardClaimMessagesKey,
    CoachRosterService.rosterPlayersKey,
    ClubScheduleService.storageKey,
    'skill_quiz_history_v1',
    'skill_quiz_cleared_sets_v1',
    'space_speed_ranking_history_v1',
    'news_scrapped_links',
    'news_scrapped_items_v1',
  };
  static const List<String> _coreRecordBackupOptionKeyPrefixes = [
    CoachRosterService.scopedOptionKeyPrefix,
    'training_plans_v1_',
    'meal_logs_v1_',
    'training_boards_v1_',
    'club_training_schedule_v1_',
    'match_managed_teams_v1_',
    'match_competitions_v1_',
    'challenge_runs_v1_',
    'running_coach_sessions_v1_',
    'running_growth_records_v1_',
    'custom_diary_entries_v3_',
    'coach_diary_completed_day_v2_',
    'player_total_xp_v1_',
    'player_xp_history_v1_',
    'player_diary_created_day_v2_',
    'player_claimed_reward_levels_v1_',
    'player_reward_claim_messages_v1_',
    'skill_quiz_history_v1_',
    'skill_quiz_cleared_sets_v1_',
    'space_speed_ranking_history_v1_',
    'news_scrapped_links_',
    'news_scrapped_items_v1_',
  ];
  Stream<void> driveAccountStateChanges() =>
      _driveAccountStateController.stream;

  Stream<void> dataChanges() => _dataChangeController.stream;

  String get _activeCoachPlayerId {
    return CoachRosterService.resolveScopedPlayerIdForOptions(
      HiveOptionRepository(_optionBox),
    );
  }

  String get _activeBackupFileName {
    final playerId = _activeCoachPlayerId;
    return playerId.isEmpty ? _fileName : playerBackupFileName(playerId);
  }

  String get _activePreviousBackupFileName {
    final playerId = _activeCoachPlayerId;
    return playerId.isEmpty
        ? _previousFileName
        : previousPlayerBackupFileName(playerId);
  }

  String get _activeHistoryBackupFileNamePrefix {
    final fileName = _activeBackupFileName;
    final stem = fileName.endsWith('.json')
        ? fileName.substring(0, fileName.length - '.json'.length)
        : fileName;
    return '${stem}_history_';
  }

  String get _activePlayerIdForMetadata {
    final coachPlayerId = _activeCoachPlayerId;
    if (coachPlayerId.isNotEmpty) return coachPlayerId;
    return _loadOrCreateLocalPlayerId();
  }

  String get _activeFamilyContributionFileName {
    final linkedParent = _activeFamilyDriveLink();
    if (linkedParent != null && _familyService.loadState().isParentRole) {
      return familyMemberContributionFileName(
        playerId: linkedParent.playerId,
        familyId: linkedParent.familyId,
        parentMemberId: linkedParent.parentMemberId,
      );
    }
    return familyContributionFileName(
      playerId: _activePlayerIdForMetadata,
      familyId: _familyService.loadState().familyId,
    );
  }

  @visibleForTesting
  String backupFileNameForTesting() => _activeBackupFileName;

  @visibleForTesting
  String previousBackupFileNameForTesting() => _activePreviousBackupFileName;

  @visibleForTesting
  String historyBackupFileNamePrefixForTesting() =>
      _activeHistoryBackupFileNamePrefix;

  @visibleForTesting
  String familyContributionFileNameForTesting() =>
      _activeFamilyContributionFileName;

  Future<T> _runDriveMutation<T>(Future<T> Function() action) async {
    final previous = _driveMutationTail.catchError((_) {});
    final completer = Completer<void>();
    _driveMutationTail = previous.whenComplete(() => completer.future);
    await previous;
    try {
      return await action();
    } finally {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  @override
  Future<void> backup() {
    return _runDriveMutation(_backup);
  }

  Future<void> _backup() async {
    try {
      await _syncConnectedDriveAccountCache();
      _throwIfDriveAccountNeedsResolutionBeforeBackup();
      final driveApi = await _driveApi(requireInteractive: kIsWeb);
      await _syncConnectedDriveAccountCache();
      _throwIfDriveAccountNeedsResolutionBeforeBackup();
      await _prepareConnectedDriveDataForCurrentRole(
        throwOnChangedPlayerDrive: true,
      );
      await _backupWithApi(driveApi);
    } catch (e, st) {
      if (!_isAuthError(e)) rethrow;
      debugPrint(
        'Drive sign-in/scope missing. Reauthenticating and retrying backup.',
      );
      debugPrintStack(stackTrace: st);
      await _reauthenticateForDriveScope();
      await _syncConnectedDriveAccountCache();
      _throwIfDriveAccountNeedsResolutionBeforeBackup();
      final retriedApi = await _driveApi(requireInteractive: false);
      await _syncConnectedDriveAccountCache();
      _throwIfDriveAccountNeedsResolutionBeforeBackup();
      await _prepareConnectedDriveDataForCurrentRole(
        throwOnChangedPlayerDrive: true,
      );
      await _backupWithApi(retriedApi);
    }
  }

  @override
  Future<bool> backupIfSignedIn({bool requireAutoOnSave = false}) async {
    return _runDriveMutation(
      () => _backupIfSignedIn(requireAutoOnSave: requireAutoOnSave),
    );
  }

  Future<bool> _backupIfSignedIn({bool requireAutoOnSave = false}) async {
    if (requireAutoOnSave && !isAutoOnSaveEnabled()) {
      return false;
    }
    if (requireAutoOnSave && _shouldThrottleAutoOnSaveBackup()) {
      return false;
    }
    if (kIsWeb) {
      var googleAccount = _googleSignIn?.currentUser;
      googleAccount ??= await _signInSilentlyThrottled();
      final firebaseSignedIn = _firebaseAuth?.currentUser != null;
      if (googleAccount == null &&
          !firebaseSignedIn &&
          _webAccessToken == null) {
        return false;
      }
      try {
        await _syncConnectedDriveAccountCache();
        if (_driveAccountNeedsResolutionBeforeBackup()) {
          return false;
        }
        final driveApi = await _driveApi(requireInteractive: false);
        await _syncConnectedDriveAccountCache();
        if (_driveAccountNeedsResolutionBeforeBackup()) {
          return false;
        }
        final switchedAccount =
            await _prepareConnectedDriveDataForCurrentRole();
        if (switchedAccount) {
          return false;
        }
        await _backupWithApi(driveApi);
        if (requireAutoOnSave) {
          await _setDateTimeOption(
            _lastAutoOnSaveBackupAtKey,
            DateTime.now(),
          );
        }
        return true;
      } catch (e, st) {
        if (_isAuthError(e)) {
          _webAccessToken = null;
          return false;
        }
        debugPrint('Drive auto backup skipped due to error: $e');
        debugPrintStack(stackTrace: st);
        return false;
      }
    }
    try {
      final google = _googleSignIn;
      if (google == null) {
        return false;
      }
      final account = await _signInSilentlyThrottled();
      if (account == null) {
        return false;
      }
      await _syncConnectedDriveAccountCache();
      if (_driveAccountNeedsResolutionBeforeBackup()) {
        return false;
      }
      final authHeaders = await account.authHeaders;
      final driveApi = drive.DriveApi(_GoogleAuthClient(authHeaders));
      await _syncConnectedDriveAccountCache();
      if (_driveAccountNeedsResolutionBeforeBackup()) {
        return false;
      }
      final switchedAccount = await _prepareConnectedDriveDataForCurrentRole();
      if (switchedAccount) {
        return false;
      }
      await _backupWithApi(driveApi);
      if (requireAutoOnSave) {
        await _setDateTimeOption(_lastAutoOnSaveBackupAtKey, DateTime.now());
      }
      return true;
    } catch (e, st) {
      if (_isInsufficientScopeError(e)) {
        return false;
      }
      debugPrint('Drive auto backup skipped due to error: $e');
      debugPrintStack(stackTrace: st);
      return false;
    }
  }

  @override
  Future<void> autoBackupDaily() async {
    if (_familyService.loadState().isSupportMode) {
      return;
    }
    if (!isAutoDailyEnabled()) {
      return;
    }
    final last = getLastRecordBackup();
    final now = DateTime.now();
    if (last != null && _isSameDay(last, now)) {
      return;
    }
    try {
      await backupIfSignedIn();
    } catch (_) {
      // Ignore auto-backup failures on app start.
    }
  }

  @override
  bool isAutoDailyEnabled() {
    return _optionBox.get(_autoDailyKey, defaultValue: true) as bool;
  }

  @override
  Future<void> setAutoDailyEnabled(bool value) async {
    await _optionBox.put(_autoDailyKey, value);
  }

  @override
  bool isAutoOnSaveEnabled() {
    return _optionBox.get(_autoOnSaveKey, defaultValue: true) as bool;
  }

  @override
  Future<void> setAutoOnSaveEnabled(bool value) async {
    await _optionBox.put(_autoOnSaveKey, value);
  }

  @override
  DateTime? getLastBackup() => getLastRecordBackup();

  DateTime? getLastRecordBackup() =>
      _getDateTimeOption(_lastRecordBackupKey) ??
      _getDateTimeOption(_lastBackupKey);

  bool _shouldThrottleAutoOnSaveBackup() {
    final last = _getDateTimeOption(_lastAutoOnSaveBackupAtKey);
    return last != null &&
        DateTime.now().difference(last) < _autoOnSaveMinimumInterval;
  }

  DateTime? getPreviousBackupCreatedAt() =>
      _getDateTimeOption(_previousBackupCreatedAtKey);

  DateTime? getLastFamilySyncPush() =>
      _getDateTimeOption(_lastFamilySyncPushAtKey);

  DateTime? getLastFamilySyncPull() => getLastFamilyRefresh();

  DateTime? getLastFamilyRefresh() =>
      _getDateTimeOption(_lastFamilySyncPullAtKey);

  bool hasPendingParentSharedChanges() {
    return _optionBox.get(_parentSharedDataDirtyKey, defaultValue: false) ==
        true;
  }

  Future<DriveConnectionInfo?> getDriveConnectionInfo() async {
    await _syncConnectedDriveAccountCache();
    final cached = _loadCachedDriveConnectionInfo();
    return cached?.isEmpty ?? true ? null : cached;
  }

  Future<DriveConnectionInfo?> getSharedChildDriveConnectionInfo({
    bool allowRemoteLookup = false,
  }) async {
    final local = _loadSharedChildDriveConnectionInfo();
    if (local != null && !local.isEmpty) {
      return local;
    }
    if (!allowRemoteLookup) {
      return local;
    }
    try {
      final remote = await _loadLatestRemoteSharedChildDriveConnectionInfo();
      if (remote == null || remote.isEmpty) {
        return local;
      }
      if (remote.email.trim().isNotEmpty) {
        await _optionBox.put(sharedChildDriveEmailKey, remote.email.trim());
        if (remote.label.trim().isNotEmpty) {
          await _optionBox.put(sharedChildDriveLabelKey, remote.label.trim());
        }
        if (remote.subjectId.trim().isNotEmpty) {
          await _optionBox.put(
            sharedChildDriveSubjectLocalKey,
            remote.subjectId.trim(),
          );
        }
      }
      return remote;
    } catch (e, st) {
      if (_isAuthError(e)) {
        return local;
      }
      debugPrint('Drive shared child info refresh failed: $e');
      debugPrintStack(stackTrace: st);
      return local;
    }
  }

  Future<bool> hasRemotePlayerBackup() async {
    try {
      return await _hasRemoteBackupFile();
    } catch (e, st) {
      if (_isAuthError(e)) {
        return false;
      }
      debugPrint('Drive remote backup check failed: $e');
      debugPrintStack(stackTrace: st);
      return false;
    }
  }

  PlayerDriveBindingState getPlayerDriveBindingState() {
    return _playerDriveBindingState();
  }

  PlayerDriveBindingState getCurrentRoleDriveBindingState() {
    return _currentRoleDriveBindingState();
  }

  bool hasChangedPlayerDriveConnection() {
    return _playerDriveBindingState() ==
        PlayerDriveBindingState.accountMismatch;
  }

  bool hasLegacyPlayerDriveConnection() {
    return _playerDriveBindingState() ==
        PlayerDriveBindingState.legacyEmailMatch;
  }

  bool hasActiveFamilyDriveLink() => _activeFamilyDriveLink() != null;

  FamilyDriveLinkRecord? getActiveFamilyDriveLink() => _activeFamilyDriveLink();

  String getActiveFamilyDriveLinkParentName() {
    return _activeFamilyDriveLink()?.parentDisplayName.trim() ?? '';
  }

  bool needsPlayerDriveImportBeforeBackup() {
    final state = _playerDriveBindingState();
    return state == PlayerDriveBindingState.unbound ||
        state == PlayerDriveBindingState.legacyEmailMatch ||
        state == PlayerDriveBindingState.accountMismatch;
  }

  bool needsDriveImportBeforeBackup() {
    final state = _currentRoleDriveBindingState();
    return state == PlayerDriveBindingState.unbound ||
        state == PlayerDriveBindingState.legacyEmailMatch ||
        state == PlayerDriveBindingState.accountMismatch;
  }

  Future<bool> importChangedPlayerDriveBackup() {
    return _runDriveMutation(_importChangedPlayerDriveBackup);
  }

  Future<bool> _importChangedPlayerDriveBackup() async {
    try {
      final driveApi = await _driveApi(requireInteractive: kIsWeb);
      return _importConnectedPlayerDriveBackupWithApi(driveApi);
    } catch (e, st) {
      if (!_isAuthError(e)) rethrow;
      debugPrint(
        'Drive sign-in/scope missing. Reauthenticating and retrying account backup import.',
      );
      debugPrintStack(stackTrace: st);
      await _reauthenticateForDriveScope();
      final retriedApi = await _driveApi(requireInteractive: false);
      return _importConnectedPlayerDriveBackupWithApi(retriedApi);
    }
  }

  Future<bool> _importConnectedPlayerDriveBackupWithApi(
    drive.DriveApi driveApi,
  ) async {
    await _syncConnectedDriveAccountCache();
    final bindingState = _playerDriveBindingState();
    if (bindingState == PlayerDriveBindingState.notApplicable ||
        bindingState == PlayerDriveBindingState.notConnected) {
      return false;
    }
    final remote = await _loadLatestRemoteBackupMapWithApi(driveApi);
    if (remote == null) {
      throw StateError(changedPlayerRemoteBackupMissingErrorCode);
    }
    if (bindingState == PlayerDriveBindingState.verified) {
      await _saveLocalPreRestore();
      _validateRestoreBinding(remote);
      await _restoreFromMap(remote, mode: RestoreMode.safeMerge);
      await _recordRemoteBackupReceipt(remote, modifiedAt: DateTime.now());
      await _rememberCurrentRoleDriveConnectionAfterRestore();
      return true;
    }
    return _adoptConnectedPlayerBackup(remoteBackup: remote);
  }

  Future<bool> startChangedPlayerDriveWithEmptyData() {
    return _runDriveMutation(_startChangedPlayerDriveWithEmptyData);
  }

  Future<bool> _startChangedPlayerDriveWithEmptyData() async {
    await _syncConnectedDriveAccountCache();
    final driveApi = await _driveApi(requireInteractive: kIsWeb);
    final remote = await _loadLatestRemoteBackupMapWithApi(driveApi);
    if (remote != null && _hasMeaningfulBackupData(remote)) {
      throw StateError(remoteBackupOverwriteBlockedErrorCode);
    }
    return _adoptConnectedPlayerBackup(remoteBackup: null);
  }

  String getSharedChildDriveEmail() {
    return (_optionBox.get(sharedChildDriveEmailKey) as String?)?.trim() ?? '';
  }

  String getSharedChildDriveLabel() {
    return (_optionBox.get(sharedChildDriveLabelKey) as String?)?.trim() ?? '';
  }

  String getSharedChildDriveSubjectId() {
    return (_optionBox.get(sharedChildDriveSubjectLocalKey) as String?)
            ?.trim() ??
        '';
  }

  String getSavedRecordDriveEmail() {
    return (_optionBox.get(recordDriveEmailLocalKey) as String?)?.trim() ?? '';
  }

  String getSavedRecordDriveLabel() {
    return (_optionBox.get(recordDriveLabelLocalKey) as String?)?.trim() ?? '';
  }

  String getSavedPlayerDriveEmail() {
    return getSavedRecordDriveEmail();
  }

  String getSavedPlayerDriveLabel() {
    return getSavedRecordDriveLabel();
  }

  String getSavedParentDriveEmail() {
    if (_activeFamilyDriveLink() != null) {
      return '';
    }
    return (_optionBox.get(parentDriveEmailLocalKey) as String?)?.trim() ?? '';
  }

  String getSavedParentDriveLabel() {
    final linkLabel = _activeFamilyDriveLink()?.parentDisplayName.trim() ?? '';
    if (linkLabel.isNotEmpty) {
      return linkLabel;
    }
    return (_optionBox.get(parentDriveLabelLocalKey) as String?)?.trim() ?? '';
  }

  @override
  Future<void> restoreLatest() {
    return _runDriveMutation(_restoreLatest);
  }

  Future<void> _restoreLatest() async {
    try {
      final driveApi = await _driveApi(requireInteractive: kIsWeb);
      await _ensureGenericRestoreAllowed();
      await _saveLocalPreRestore();
      await _restoreLatestWithApi(driveApi);
      await _rememberCurrentRoleDriveConnectionAfterRestore();
    } catch (e, st) {
      if (!_isAuthError(e)) rethrow;
      debugPrint(
        'Drive sign-in/scope missing. Reauthenticating and retrying restore.',
      );
      debugPrintStack(stackTrace: st);
      await _reauthenticateForDriveScope();
      final retriedApi = await _driveApi(requireInteractive: false);
      await _ensureGenericRestoreAllowed();
      await _saveLocalPreRestore();
      await _restoreLatestWithApi(retriedApi);
      await _rememberCurrentRoleDriveConnectionAfterRestore();
    }
  }

  Future<void> restorePreviousBackup() {
    return _runDriveMutation(_restorePreviousBackup);
  }

  Future<void> _restorePreviousBackup() async {
    try {
      final driveApi = await _driveApi(requireInteractive: kIsWeb);
      await _ensureGenericRestoreAllowed();
      await _saveLocalPreRestore();
      await _restorePreviousWithApi(driveApi);
      await _rememberCurrentRoleDriveConnectionAfterRestore();
    } catch (e, st) {
      if (!_isAuthError(e)) rethrow;
      debugPrint(
        'Drive sign-in/scope missing. Reauthenticating and retrying previous restore.',
      );
      debugPrintStack(stackTrace: st);
      await _reauthenticateForDriveScope();
      final retriedApi = await _driveApi(requireInteractive: false);
      await _ensureGenericRestoreAllowed();
      await _saveLocalPreRestore();
      await _restorePreviousWithApi(retriedApi);
      await _rememberCurrentRoleDriveConnectionAfterRestore();
    }
  }

  Future<void> _ensureGenericRestoreAllowed() async {
    await _syncConnectedDriveAccountCache();
  }

  Future<void> _saveLocalPreRestore() async {
    final data = _buildBackup(
      updatedByRole: _familyService.loadState().currentRole,
      familyLayerOnly: false,
    );
    final json = jsonEncode(data);
    final now = DateTime.now();
    final points = _loadLocalRecoverySnapshotMaps();
    points.insert(0, <String, dynamic>{
      'id': _createLocalIdValue('restore'),
      'createdAt': now.toIso8601String(),
      'data': json,
    });
    if (points.length > _localRecoverySnapshotRetentionCount) {
      points.removeRange(_localRecoverySnapshotRetentionCount, points.length);
    }
    await _optionBox.put(_localPreRestoreSnapshotsKey, points);
    await _optionBox.put(_localPreRestoreKey, json);
    await _optionBox.put(
      _localPreRestoreAtKey,
      now.toIso8601String(),
    );
  }

  Future<drive.DriveApi> _driveApi({required bool requireInteractive}) async {
    final driveApiLoader = _driveApiLoader;
    if (driveApiLoader != null) {
      return driveApiLoader(requireInteractive: requireInteractive);
    }
    if (kIsWeb) {
      final accessToken = await _ensureWebAccessToken(
        requireInteractive: requireInteractive,
      );
      final client = _GoogleAuthClient({
        'Authorization': 'Bearer $accessToken',
      });
      return drive.DriveApi(client);
    }
    final account = await _ensureSignedIn(
      requireInteractive: requireInteractive,
    );
    final authHeaders = await account.authHeaders;
    final client = _GoogleAuthClient(authHeaders);
    return drive.DriveApi(client);
  }

  Future<void> signIn() async {
    if (kIsWeb) {
      await _ensureWebAccessToken(requireInteractive: true);
      await _syncConnectedDriveAccountCache(
        attemptFamilyLinkRecovery: true,
      );
      await _prepareConnectedDriveDataForCurrentRole();
      return;
    }
    final account = await _ensureSignedIn(requireInteractive: true);
    _lastSilentSignInAccount = account;
    _lastSilentSignInAt = DateTime.now();
    _cacheRecentDriveConnection(
      DriveConnectionInfo(
        email: account.email.trim(),
        displayName: account.displayName?.trim() ?? '',
        subjectId: account.id,
      ),
    );
    await _syncConnectedDriveAccountCache(
      attemptFamilyLinkRecovery: true,
    );
    await _prepareConnectedDriveDataForCurrentRole();
  }

  Future<FamilyPairingOffer> createParentPairingOffer() async {
    if (!await isSignedIn()) {
      await signIn();
    }
    await _syncConnectedDriveAccountCache();
    return _familyDriveLinkService().createParentOffer();
  }

  Future<FamilyDriveLinkRecord> approveFamilyPairingOffer(
    String qrPayload,
  ) async {
    if (!await isSignedIn()) {
      await signIn();
    }
    await _syncConnectedDriveAccountCache();
    final state = _familyService.loadState();
    if (!state.isChildMode) {
      throw StateError(driveAccountBindingRequiredErrorCode);
    }
    _throwIfDriveAccountNeedsResolutionBeforeBackup();
    final familyId = await _ensureFamilyIdForPairing();
    final refreshedState = _familyService.loadState();
    final childBackup = _buildBackup(
      updatedByRole: FamilyRole.child,
      familyLayerOnly: false,
    );
    final record = await _familyDriveLinkService().approveOfferOnChild(
      qrPayload: qrPayload,
      familyId: familyId,
      datasetId: _loadOrCreateLocalDatasetId(),
      playerId: _activePlayerIdForMetadata,
      childBackupPayload: childBackup,
      parentContributionPayload:
          _emptyParentContributionForPairing(refreshedState),
    );
    if (record.parentDisplayName.trim().isNotEmpty &&
        (_optionBox.get(FamilyAccessService.parentNameKey) as String?)
                ?.trim()
                .isNotEmpty !=
            true) {
      await _optionBox.put(
        FamilyAccessService.parentNameKey,
        record.parentDisplayName.trim(),
      );
    }
    return record;
  }

  Future<FamilyDriveLinkRecord> completeParentPairing(String inviteId) async {
    if (!await isSignedIn()) {
      await signIn();
    }
    await _syncConnectedDriveAccountCache();
    final state = _familyService.loadState();
    if (!state.isParentRole) {
      throw StateError(driveAccountBindingRequiredErrorCode);
    }
    final record = await _familyDriveLinkService().completeParentPairing(
      inviteId: inviteId,
      restoreChildBackup: (record, childBackup) async {
        _validateLinkedCorePayload(link: record, remote: childBackup);
        await _saveLocalPreRestore();
        await _restoreFromMap(childBackup, mode: RestoreMode.safeMerge);
        await _recordRemoteBackupReceipt(
          childBackup,
          modifiedAt: DateTime.now(),
        );
      },
    );
    await _rememberFamilyDriveLinkIdentifiers(record);
    return record;
  }

  Future<FamilyDriveLinkRecord> completeParentPairingFromCompletionPayload(
    String inviteId,
    Map<dynamic, dynamic> completionPayload,
  ) async {
    if (!await isSignedIn()) {
      await signIn();
    }
    await _syncConnectedDriveAccountCache();
    final state = _familyService.loadState();
    if (!state.isParentRole) {
      throw StateError(driveAccountBindingRequiredErrorCode);
    }
    final record = await _familyDriveLinkService()
        .completeParentPairingFromCompletionPayload(
      inviteId: inviteId,
      completionPayload: completionPayload,
      restoreChildBackup: (record, childBackup) async {
        _validateLinkedCorePayload(link: record, remote: childBackup);
        await _saveLocalPreRestore();
        await _restoreFromMap(childBackup, mode: RestoreMode.safeMerge);
        await _recordRemoteBackupReceipt(
          childBackup,
          modifiedAt: DateTime.now(),
        );
      },
    );
    await _rememberFamilyDriveLinkIdentifiers(record);
    return record;
  }

  Future<void> unlinkActiveFamilyLink() async {
    final record = _activeFamilyDriveLink();
    if (record == null) return;
    if (!await isSignedIn()) {
      await signIn();
    }
    await _syncConnectedDriveAccountCache();
    final service = _familyDriveLinkService();
    final state = _familyService.loadState();
    if (state.isChildMode) {
      await service.childInitiatedUnlink(record: record);
    } else {
      await service.parentLocalUnlink(record: record);
    }
    await _setParentSharedDataDirty(false);
  }

  Future<bool> isSignedIn() async {
    if (kIsWeb) {
      var googleAccount = _googleSignIn?.currentUser;
      googleAccount ??= await _signInSilentlyThrottled();
      final firebaseSignedIn = _firebaseAuth?.currentUser != null;
      if (googleAccount != null) {
        _cacheRecentDriveConnection(
          DriveConnectionInfo(
            email: googleAccount.email.trim(),
            displayName: googleAccount.displayName?.trim() ?? '',
            subjectId: googleAccount.id,
          ),
        );
        await _syncConnectedDriveAccountCache();
      } else if (firebaseSignedIn) {
        await _syncConnectedDriveAccountCache();
      } else {
        await _clearConnectedDriveAccountCache();
      }
      return googleAccount != null || firebaseSignedIn;
    }
    final google = _googleSignIn;
    if (google == null) return false;
    var account = google.currentUser;
    account ??= await _signInSilentlyThrottled();
    if (account != null) {
      _cacheRecentDriveConnection(
        DriveConnectionInfo(
          email: account.email.trim(),
          displayName: account.displayName?.trim() ?? '',
          subjectId: account.id,
        ),
      );
      await _syncConnectedDriveAccountCache();
    } else {
      final recent = _loadRecentDriveConnection();
      if (recent == null || recent.isEmpty) {
        await _clearConnectedDriveAccountCache();
      }
    }
    return account != null || _loadRecentDriveConnection() != null;
  }

  Future<void> signOut() async {
    _webAccessToken = null;
    _clearRecentDriveConnection();
    _lastSilentSignInAccount = null;
    _lastSilentSignInAt = null;
    if (kIsWeb) {
      await _googleSignIn?.signOut();
      await _firebaseAuth?.signOut();
      await _clearConnectedDriveAccountCache();
      return;
    }
    final google = _googleSignIn;
    if (google == null) return;
    await google.signOut();
    await _clearConnectedDriveAccountCache();
  }

  Future<void> revokeGoogleAppAccess() async {
    _webAccessToken = null;
    _clearRecentDriveConnection();
    _lastSilentSignInAccount = null;
    _lastSilentSignInAt = null;
    if (kIsWeb) {
      try {
        await _googleSignIn?.disconnect();
      } catch (_) {
        await _googleSignIn?.signOut();
      }
      await _firebaseAuth?.signOut();
      await _clearConnectedDriveAccountCache();
      return;
    }
    final google = _googleSignIn;
    if (google == null) return;
    try {
      await google.disconnect();
    } finally {
      await _clearConnectedDriveAccountCache();
    }
  }

  Future<void> setCurrentFamilyRole(FamilyRole role) async {
    final previousRole = _familyService.loadState().currentRole;
    await _familyService.setCurrentRole(role);
    if (previousRole != role) {
      await _resetLocalBackupStatusForContextChange();
    }
  }

  Future<void> rememberRecordDriveConnection() {
    return _rememberDriveConnection(
      emailKey: recordDriveEmailLocalKey,
      labelKey: recordDriveLabelLocalKey,
      subjectKey: recordDriveSubjectLocalKey,
    );
  }

  Future<void> rememberPlayerDriveConnection() =>
      rememberRecordDriveConnection();

  Future<void> rememberParentDriveConnection() {
    return _rememberDriveConnection(
      emailKey: parentDriveEmailLocalKey,
      labelKey: parentDriveLabelLocalKey,
      subjectKey: parentDriveSubjectLocalKey,
    );
  }

  Future<void> rememberCurrentRoleDriveConnection() async {
    final role = _familyService.loadState().currentRole;
    if (role == FamilyRole.coach) {
      await _rememberCoachDriveConnection();
      return;
    }
    if (FamilyAccessService.isSupportRole(role)) {
      await rememberParentDriveConnection();
      return;
    }
    await rememberRecordDriveConnection();
  }

  Future<void> signInForSavedRecord() {
    return _signInForSavedDrive(
      expected: _loadSavedRecordDriveConnectionInfo(),
      rememberConnection: rememberRecordDriveConnection,
      mismatchErrorCode: recordDriveMismatchErrorCode,
    );
  }

  Future<void> signInForSavedPlayer() => signInForSavedRecord();

  Future<void> signInForSavedParent() {
    return _signInForSavedDrive(
      expected: _loadSavedParentDriveConnectionInfo(),
      rememberConnection: rememberParentDriveConnection,
      mismatchErrorCode: parentModeDriveMismatchErrorCode,
    );
  }

  Future<void> markParentSharedDataDirty() async {
    if (!_familyService.loadState().isSupportMode) {
      return;
    }
    await _setParentSharedDataDirty(true);
  }

  @visibleForTesting
  Future<void> markParentSharedDataDirtyForTesting() async {
    await _setParentSharedDataDirty(true);
  }

  @visibleForTesting
  Future<void> recordFamilySyncPushForTesting(DateTime value) async {
    await _recordFamilySyncPush(value);
  }

  @visibleForTesting
  Future<void> recordFamilySyncPullForTesting(
    DateTime value, {
    DateTime? remoteModifiedAt,
  }) async {
    await _recordFamilySyncPull(
      value,
      remoteModifiedAt: remoteModifiedAt ?? value,
    );
  }

  Future<bool> refreshParentSharedDataIfNeeded() {
    return _runDriveMutation(() async {
      final state = _familyService.loadState();
      if (!state.isSupportMode) {
        return false;
      }
      final result = await _refreshSupportFamilyDataIfNeeded(state);
      return result.refreshed;
    });
  }

  Future<FamilySharedSyncResult> refreshFamilySharedDataIfNeeded() {
    return _runDriveMutation(() {
      final state = _familyService.loadState();
      if (state.isSupportMode) {
        return _refreshSupportFamilyDataIfNeeded(state);
      }
      return _refreshChildSharedLayerIfNeeded(state);
    });
  }

  Future<FamilySharedSyncResult> _refreshSupportFamilyDataIfNeeded(
    FamilyAccessState state,
  ) async {
    try {
      await _syncConnectedDriveAccountCache(
        attemptFamilyLinkRecovery: true,
      );
      if (_driveAccountNeedsResolutionBeforeBackup()) {
        return FamilySharedSyncResult.none(role: state.currentRole);
      }
      final link = _activeFamilyDriveLink();
      if (link != null && state.isParentRole) {
        return _refreshLinkedParentFamilyDataIfNeeded(state, link);
      }
      final driveApi = await _driveApi(requireInteractive: false);
      final folderId = await _findFolderId(driveApi);
      if (folderId == null) {
        return FamilySharedSyncResult.none(role: state.currentRole);
      }
      final file = await _findFamilyContributionFile(driveApi, folderId) ??
          await _findBackupFile(driveApi, folderId);
      if (file == null) {
        return FamilySharedSyncResult.none(role: state.currentRole);
      }
      if (!_shouldRefreshParentSharedData(
        remoteModifiedAt: file.modifiedTime,
      )) {
        return FamilySharedSyncResult.none(role: state.currentRole);
      }
      final hadKnownRemoteSnapshot = _getLastFamilyRemoteSnapshot() != null;
      final beforeTrainingIds = _trainingEntryIds();
      final beforeRewardClaims = _loadRewardClaimFingerprints();
      await _saveLocalPreRestore();
      await _restoreBackupFileWithApi(
        driveApi,
        file,
        mode: RestoreMode.safeMerge,
      );
      await _recordFamilySyncPull(
        DateTime.now(),
        remoteModifiedAt: file.modifiedTime ?? DateTime.now(),
      );
      await _setParentSharedDataDirty(false);
      final newTrainingCount = hadKnownRemoteSnapshot
          ? _trainingEntryIds().difference(beforeTrainingIds).length
          : 0;
      final newRewardClaimCount = hadKnownRemoteSnapshot
          ? _countChangedStringMap(
              before: beforeRewardClaims,
              after: _loadRewardClaimFingerprints(),
            )
          : 0;
      return FamilySharedSyncResult(
        refreshed: true,
        role: state.currentRole,
        newTrainingEntryCount: newTrainingCount,
        newRewardClaimCount: newRewardClaimCount,
      );
    } catch (e, st) {
      if (_isAuthError(e)) {
        return FamilySharedSyncResult.none(role: state.currentRole);
      }
      debugPrint('Parent shared refresh skipped: $e');
      debugPrintStack(stackTrace: st);
      return FamilySharedSyncResult.none(role: state.currentRole);
    }
  }

  Future<FamilySharedSyncResult> _refreshLinkedParentFamilyDataIfNeeded(
    FamilyAccessState state,
    FamilyDriveLinkRecord link,
  ) async {
    try {
      _validateFamilyLinkForCurrentSession(link, state);
      final driveApi = await _driveApi(requireInteractive: false);
      final coreMetadata = await _linkedFileMetadata(
        driveApi,
        link.coreBackupFileId,
        FamilyDriveFileKind.coreBackup,
      );
      if (!_shouldRefreshParentSharedData(
        remoteModifiedAt: coreMetadata.modifiedAt,
      )) {
        return FamilySharedSyncResult.none(role: state.currentRole);
      }
      final hadKnownRemoteSnapshot = _getLastFamilyRemoteSnapshot() != null;
      final beforeTrainingIds = _trainingEntryIds();
      final beforeRewardClaims = _loadRewardClaimFingerprints();
      await _saveLocalPreRestore();
      final remote =
          await _downloadLinkedBackupMap(driveApi, link.coreBackupFile);
      _validateLinkedCorePayload(link: link, remote: remote);
      await _restoreFromMap(remote, mode: RestoreMode.safeMerge);
      DateTime? contributionModifiedAt;
      try {
        final contributionMetadata = await _linkedFileMetadata(
          driveApi,
          link.contributionFileId,
          FamilyDriveFileKind.parentContribution,
        );
        contributionModifiedAt = contributionMetadata.modifiedAt;
        final contributionData = await _downloadLinkedBackupMap(
          driveApi,
          link.contributionFile,
        );
        _validateLinkedContributionPayload(
          link: link,
          remote: contributionData,
        );
        await _restoreSharedOptionsFromMap(contributionData);
      } on StateError catch (error) {
        if (error.message != familyLinkPermissionRevokedErrorCode) {
          rethrow;
        }
      }
      final remoteModifiedAt =
          coreMetadata.modifiedAt ?? contributionModifiedAt ?? DateTime.now();
      await _familyLinkStore.saveRecord(
        link.copyWith(
          lastCoreModifiedAt: coreMetadata.modifiedAt,
          lastContributionModifiedAt: contributionModifiedAt,
          updatedAt: DateTime.now(),
        ),
      );
      await _recordFamilySyncPull(DateTime.now(),
          remoteModifiedAt: remoteModifiedAt);
      await _setParentSharedDataDirty(false);
      final newTrainingCount = hadKnownRemoteSnapshot
          ? _trainingEntryIds().difference(beforeTrainingIds).length
          : 0;
      final newRewardClaimCount = hadKnownRemoteSnapshot
          ? _countChangedStringMap(
              before: beforeRewardClaims,
              after: _loadRewardClaimFingerprints(),
            )
          : 0;
      return FamilySharedSyncResult(
        refreshed: true,
        role: state.currentRole,
        newTrainingEntryCount: newTrainingCount,
        newRewardClaimCount: newRewardClaimCount,
      );
    } catch (e, st) {
      if (_isAuthError(e)) {
        return FamilySharedSyncResult.none(role: state.currentRole);
      }
      debugPrint('Parent linked family refresh skipped: $e');
      debugPrintStack(stackTrace: st);
      return FamilySharedSyncResult.none(role: state.currentRole);
    }
  }

  Future<FamilySharedSyncResult> _refreshChildSharedLayerIfNeeded(
    FamilyAccessState state,
  ) async {
    try {
      await _syncConnectedDriveAccountCache(
        attemptFamilyLinkRecovery: true,
      );
      if (_driveAccountNeedsResolutionBeforeBackup()) {
        return FamilySharedSyncResult.none(role: state.currentRole);
      }
      final linkedResult = await _refreshLinkedChildSharedLayersIfNeeded(state);
      if (linkedResult != null) {
        return linkedResult;
      }
      final driveApi = await _driveApi(requireInteractive: false);
      final folderId = await _findFolderId(driveApi);
      if (folderId == null) {
        return FamilySharedSyncResult.none(role: state.currentRole);
      }
      final file = await _findBackupFile(driveApi, folderId);
      if (file == null) {
        return FamilySharedSyncResult.none(role: state.currentRole);
      }
      if (!_shouldRefreshChildSharedLayer(
        remoteModifiedAt: file.modifiedTime,
      )) {
        return FamilySharedSyncResult.none(role: state.currentRole);
      }
      final beforeFeedback = _loadParentFeedbackFingerprints();
      final beforeRewards = _loadRewardNames();
      final remote = await _downloadBackupMap(driveApi, file.id!);
      await _restoreSharedOptionsFromMap(remote);
      await _recordFamilySyncPull(
        DateTime.now(),
        remoteModifiedAt: file.modifiedTime ?? DateTime.now(),
      );
      final afterFeedback = _loadParentFeedbackFingerprints();
      final afterRewards = _loadRewardNames();
      return FamilySharedSyncResult(
        refreshed: true,
        role: state.currentRole,
        newParentFeedbackCount: _countChangedFeedback(
          before: beforeFeedback,
          after: afterFeedback,
        ),
        rewardNamesChanged: !_sameStringMap(beforeRewards, afterRewards),
      );
    } catch (e, st) {
      if (_isAuthError(e)) {
        return FamilySharedSyncResult.none(role: state.currentRole);
      }
      debugPrint('Child shared layer refresh skipped: $e');
      debugPrintStack(stackTrace: st);
      return FamilySharedSyncResult.none(role: state.currentRole);
    }
  }

  Future<FamilySharedSyncResult?> _refreshLinkedChildSharedLayersIfNeeded(
    FamilyAccessState state,
  ) async {
    final links = _familyLinkStore
        .loadRecords()
        .where((link) => !link.isRevoked && link.contributionFileId.isNotEmpty)
        .toList(growable: false);
    if (links.isEmpty) {
      return null;
    }
    final driveApi = await _driveApi(requireInteractive: false);
    var refreshed = false;
    DateTime? newestRemoteModifiedAt;
    final beforeFeedback = _loadParentFeedbackFingerprints();
    final beforeRewards = _loadRewardNames();
    for (final link in links) {
      _validateFamilyLinkForCurrentSession(link, state);
      final metadata = await _linkedFileMetadata(
        driveApi,
        link.contributionFileId,
        FamilyDriveFileKind.parentContribution,
      );
      if (!_shouldRefreshLinkedContribution(
        link: link,
        remoteModifiedAt: metadata.modifiedAt,
      )) {
        continue;
      }
      final remote =
          await _downloadLinkedBackupMap(driveApi, link.contributionFile);
      _validateLinkedContributionPayload(link: link, remote: remote);
      await _restoreSharedOptionsFromMap(remote);
      refreshed = true;
      newestRemoteModifiedAt = _maxDateTime(
        newestRemoteModifiedAt,
        metadata.modifiedAt,
      );
      await _familyLinkStore.saveRecord(
        link.copyWith(
          lastContributionModifiedAt: metadata.modifiedAt,
          updatedAt: DateTime.now(),
        ),
      );
    }
    if (!refreshed) {
      return FamilySharedSyncResult.none(role: state.currentRole);
    }
    await _recordFamilySyncPull(
      DateTime.now(),
      remoteModifiedAt: newestRemoteModifiedAt ?? DateTime.now(),
    );
    final afterFeedback = _loadParentFeedbackFingerprints();
    final afterRewards = _loadRewardNames();
    return FamilySharedSyncResult(
      refreshed: true,
      role: state.currentRole,
      newParentFeedbackCount: _countChangedFeedback(
        before: beforeFeedback,
        after: afterFeedback,
      ),
      rewardNamesChanged: !_sameStringMap(beforeRewards, afterRewards),
    );
  }

  Future<void> _reauthenticateForDriveScope() async {
    final reauthenticator = _driveScopeReauthenticator;
    if (reauthenticator != null) {
      await reauthenticator();
      return;
    }
    if (kIsWeb) {
      _webAccessToken = null;
      final google = _googleSignIn;
      if (google != null) {
        await google.signOut();
      } else {
        await _firebaseAuth?.signOut();
      }
      await _ensureWebAccessToken(requireInteractive: true);
      return;
    }
    final google = _googleSignIn;
    if (google == null) {
      throw StateError('Google sign-in required.');
    }
    await google.signOut();
    final account = await google.signIn();
    if (account == null) {
      throw StateError('Google sign-in cancelled.');
    }
    _lastSilentSignInAccount = account;
    _lastSilentSignInAt = DateTime.now();
    _cacheRecentDriveConnection(
      DriveConnectionInfo(
        email: account.email.trim(),
        displayName: account.displayName?.trim() ?? '',
        subjectId: account.id,
      ),
    );
    await _ensureDriveScopeGranted();
  }

  Future<String> _ensureWebAccessToken({
    required bool requireInteractive,
  }) async {
    if (!kIsWeb) {
      throw StateError('Web access token requested on non-web platform.');
    }
    final google = _googleSignIn;
    if (google != null) {
      return _ensureGoogleAccessToken(requireInteractive: requireInteractive);
    }
    final auth = _firebaseAuth;
    if (auth == null) {
      throw StateError('Firebase web auth unavailable.');
    }
    final cached = _webAccessToken;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    if (!requireInteractive) {
      throw StateError('Google sign-in required.');
    }
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope(_driveScope)
      ..setCustomParameters(const {'prompt': 'consent'});
    final credential = await auth.signInWithPopup(provider);
    final user = credential.user;
    if (user != null) {
      _cacheRecentDriveConnection(
        DriveConnectionInfo(
          email: user.email?.trim() ?? '',
          displayName: user.displayName?.trim() ?? '',
          subjectId: user.uid,
        ),
      );
    }
    final oauth = credential.credential;
    final token = oauth is OAuthCredential ? oauth.accessToken : null;
    if (token == null || token.isEmpty) {
      throw StateError('Drive access token is missing.');
    }
    _webAccessToken = token;
    return token;
  }

  Future<String> _ensureGoogleAccessToken({
    required bool requireInteractive,
  }) async {
    final google = _googleSignIn;
    if (google == null) {
      throw StateError('Google sign-in required.');
    }
    final cached = _webAccessToken;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    var account = google.currentUser;
    account ??= await _signInSilentlyThrottled();
    if (account == null && requireInteractive) {
      account = await google.signIn();
    }
    if (account == null) {
      throw StateError('Google sign-in required.');
    }
    if (requireInteractive) {
      await _ensureDriveScopeGranted();
    }
    _cacheRecentDriveConnection(
      DriveConnectionInfo(
        email: account.email.trim(),
        displayName: account.displayName?.trim() ?? '',
        subjectId: account.id,
      ),
    );
    final authentication = await account.authentication;
    var token = authentication.accessToken?.trim() ?? '';
    if (token.isEmpty) {
      final authHeaders = await account.authHeaders;
      final authorization = authHeaders['Authorization'] ?? '';
      const bearerPrefix = 'Bearer ';
      if (authorization.startsWith(bearerPrefix)) {
        token = authorization.substring(bearerPrefix.length).trim();
      }
    }
    if (token.isEmpty) {
      throw StateError('Drive access token is missing.');
    }
    _webAccessToken = token;
    return token;
  }

  Future<GoogleSignInAccount> _ensureSignedIn({
    required bool requireInteractive,
  }) async {
    final google = _googleSignIn;
    if (google == null) {
      throw StateError('Google sign-in required.');
    }
    var account = google.currentUser;
    account ??= await _signInSilentlyThrottled();
    if (account == null && requireInteractive) {
      account = await google.signIn();
    }
    if (account == null) {
      throw StateError('Google sign-in required.');
    }
    if (requireInteractive) {
      await _ensureDriveScopeGranted();
    }
    return account;
  }

  Future<GoogleSignInAccount?> _signInSilentlyThrottled() async {
    final google = _googleSignIn;
    if (google == null) return null;
    final current = google.currentUser;
    if (current != null) {
      _lastSilentSignInAccount = current;
      _lastSilentSignInAt = DateTime.now();
      return current;
    }
    final lastAttempt = _lastSilentSignInAt;
    if (lastAttempt != null &&
        DateTime.now().difference(lastAttempt) < _silentSignInTtl) {
      return _lastSilentSignInAccount;
    }
    final account = await google.signInSilently();
    _lastSilentSignInAccount = account;
    _lastSilentSignInAt = DateTime.now();
    return account;
  }

  Future<void> _ensureDriveScopeGranted() async {
    final google = _googleSignIn;
    if (google == null) return;
    try {
      final granted = await google.requestScopes(const [_driveScope]);
      if (!granted) {
        throw StateError('Drive permission denied.');
      }
    } on UnimplementedError {
      // Some platforms do not support explicit scope requests.
      // Continue with the scopes configured at sign-in.
    }
  }

  Future<void> _syncConnectedDriveAccountCache({
    bool attemptFamilyLinkRecovery = false,
  }) async {
    final info = await _loadDriveConnectionInfo();
    if (info == null || info.isEmpty) {
      final recent = _loadRecentDriveConnection();
      if (recent == null || recent.isEmpty) {
        await _clearConnectedDriveAccountCache();
        return;
      }
      await _storeConnectedDriveAccountCache(recent);
      if (attemptFamilyLinkRecovery) {
        await _recoverFamilyDriveLinksAfterReinstallIfNeeded();
      }
      return;
    }
    _cacheRecentDriveConnection(info);
    await _storeConnectedDriveAccountCache(info);
    if (attemptFamilyLinkRecovery) {
      await _recoverFamilyDriveLinksAfterReinstallIfNeeded();
    }
  }

  Future<void> _recoverFamilyDriveLinksAfterReinstallIfNeeded() async {
    if (_familyLinkRecoveryInFlight) return;
    if (_familyLinkStore.loadRecords().isNotEmpty) return;
    final state = _familyService.loadState();
    if (!state.isChildMode && !state.isParentRole) return;
    final current =
        _loadCachedDriveConnectionInfo() ?? _loadRecentDriveConnection();
    final subjectId = current?.subjectId.trim() ?? '';
    if (current == null || subjectId.isEmpty) return;
    if (!_canLoadDriveApiWithoutInteractiveSignIn()) return;
    final role = state.isChildMode
        ? FamilyDriveLinkOwnerRole.child
        : FamilyDriveLinkOwnerRole.parent;
    if (_isFamilyLinkNoManifestRecoveryCoolingDown(
      subjectId: subjectId,
      role: role,
    )) {
      return;
    }

    _familyLinkRecoveryInFlight = true;
    try {
      final service = _familyDriveLinkService();
      if (state.isChildMode) {
        final result = await service.recoverChildLinksAfterReinstall();
        if (result.hasRecords) {
          await _rememberRecoveredFamilyDriveLinkIdentifiers(result);
        } else if (result.noManifest) {
          _rememberFamilyLinkNoManifestRecoveryCheck(
            subjectId: subjectId,
            role: role,
          );
        }
      } else {
        final result = await service.recoverParentLinksAfterReinstall();
        final record = result.activeRecord;
        if (record != null) {
          await _rememberFamilyDriveLinkIdentifiers(record);
        } else if (result.noManifest) {
          _rememberFamilyLinkNoManifestRecoveryCheck(
            subjectId: subjectId,
            role: role,
          );
        }
      }
    } catch (e, st) {
      debugPrint('Family Drive link reinstall recovery skipped: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      _familyLinkRecoveryInFlight = false;
    }
  }

  bool _isFamilyLinkNoManifestRecoveryCoolingDown({
    required String subjectId,
    required FamilyDriveLinkOwnerRole role,
  }) {
    final key = _familyLinkRecoveryCooldownKey(
      subjectId: subjectId,
      role: role,
    );
    final checkedAt = _familyLinkNoManifestRecoveryCheckedAt[key];
    if (checkedAt == null) {
      return false;
    }
    if (DateTime.now().difference(checkedAt) <
        _familyLinkNoManifestRecoveryCooldown) {
      return true;
    }
    _familyLinkNoManifestRecoveryCheckedAt.remove(key);
    return false;
  }

  void _rememberFamilyLinkNoManifestRecoveryCheck({
    required String subjectId,
    required FamilyDriveLinkOwnerRole role,
  }) {
    _familyLinkNoManifestRecoveryCheckedAt[_familyLinkRecoveryCooldownKey(
      subjectId: subjectId,
      role: role,
    )] = DateTime.now();
  }

  String _familyLinkRecoveryCooldownKey({
    required String subjectId,
    required FamilyDriveLinkOwnerRole role,
  }) {
    return '${role.name}:${subjectId.trim().toLowerCase()}';
  }

  bool _canLoadDriveApiWithoutInteractiveSignIn() {
    if (_driveApiLoader != null) return true;
    if (_webAccessToken != null) return true;
    if (_googleSignIn?.currentUser != null) return true;
    if (_lastSilentSignInAccount != null) return true;
    if (kIsWeb && _firebaseAuth?.currentUser != null) return true;
    return false;
  }

  Future<void> _storeConnectedDriveAccountCache(
    DriveConnectionInfo info,
  ) async {
    final previous = _loadCachedDriveConnectionInfo() ??
        _loadSavedDriveConnectionInfoForCurrentRole();
    await _optionBox.put(connectedDriveEmailLocalKey, info.email.trim());
    await _optionBox.put(connectedDriveLabelLocalKey, info.displayName.trim());
    await _optionBox.put(connectedDriveSubjectLocalKey, info.subjectId.trim());
    if (!_sameDriveAccount(previous, info)) {
      await _resetLocalBackupStatusForContextChange();
    }
  }

  Future<void> _clearConnectedDriveAccountCache() async {
    final previous = _loadCachedDriveConnectionInfo();
    await _optionBox.delete(connectedDriveEmailLocalKey);
    await _optionBox.delete(connectedDriveLabelLocalKey);
    await _optionBox.delete(connectedDriveSubjectLocalKey);
    if (previous != null && !previous.isEmpty) {
      await _resetLocalBackupStatusForContextChange();
    }
  }

  bool _sameDriveAccount(
    DriveConnectionInfo? previous,
    DriveConnectionInfo? current,
  ) {
    final previousSubject = previous?.subjectId.trim().toLowerCase() ?? '';
    final currentSubject = current?.subjectId.trim().toLowerCase() ?? '';
    if (previousSubject.isNotEmpty && currentSubject.isNotEmpty) {
      return previousSubject == currentSubject;
    }
    final previousEmail = _normalizedEmail(previous?.email);
    final currentEmail = _normalizedEmail(current?.email);
    if (previousEmail.isNotEmpty && currentEmail.isNotEmpty) {
      return previousEmail == currentEmail;
    }
    return _driveAccountIdentity(previous) == _driveAccountIdentity(current);
  }

  PlayerDriveBindingState _playerDriveBindingState() {
    if (_familyService.loadState().currentRole != FamilyRole.child) {
      return PlayerDriveBindingState.notApplicable;
    }
    return _driveBindingStateForSaved(
      _loadSavedRecordDriveConnectionInfo(),
    );
  }

  PlayerDriveBindingState _currentRoleDriveBindingState() {
    final state = _familyService.loadState();
    if (state.currentRole == FamilyRole.child) {
      return _driveBindingStateForSaved(_loadSavedRecordDriveConnectionInfo());
    }
    if (state.currentRole == FamilyRole.coach) {
      return _driveBindingStateForSaved(
        CoachRosterService(
          HiveOptionRepository(_optionBox),
        ).activePlayerDriveConnection(),
      );
    }
    final link = _activeFamilyDriveLink();
    if (link != null) {
      return _familyLinkDriveBindingState(
        link: link,
        expectedRole: FamilyDriveLinkOwnerRole.parent,
      );
    }
    return _driveBindingStateForSaved(_loadSavedParentDriveConnectionInfo());
  }

  PlayerDriveBindingState _familyLinkDriveBindingState({
    required FamilyDriveLinkRecord link,
    required FamilyDriveLinkOwnerRole expectedRole,
  }) {
    final current =
        _loadCachedDriveConnectionInfo() ?? _loadRecentDriveConnection();
    if (current == null || current.isEmpty) {
      return PlayerDriveBindingState.notConnected;
    }
    final expectedSubject = expectedRole == FamilyDriveLinkOwnerRole.child
        ? link.childSubjectId.trim()
        : link.parentSubjectId.trim();
    final currentSubject = current.subjectId.trim();
    if (expectedSubject.isNotEmpty &&
        currentSubject.isNotEmpty &&
        currentSubject == expectedSubject) {
      return PlayerDriveBindingState.verified;
    }
    return PlayerDriveBindingState.accountMismatch;
  }

  PlayerDriveBindingState _driveBindingStateForSaved(
    DriveConnectionInfo? saved,
  ) {
    final current =
        _loadCachedDriveConnectionInfo() ?? _loadRecentDriveConnection();
    if (current == null || current.isEmpty) {
      return PlayerDriveBindingState.notConnected;
    }
    if (saved == null || saved.isEmpty) {
      return PlayerDriveBindingState.unbound;
    }
    final savedSubject = saved.subjectId.trim().toLowerCase();
    final currentSubject = current.subjectId.trim().toLowerCase();
    if (savedSubject.isNotEmpty && currentSubject.isNotEmpty) {
      return savedSubject == currentSubject
          ? PlayerDriveBindingState.verified
          : PlayerDriveBindingState.accountMismatch;
    }
    final savedEmail = _normalizedEmail(saved.email);
    final currentEmail = _normalizedEmail(current.email);
    if (savedEmail.isNotEmpty && savedEmail == currentEmail) {
      return PlayerDriveBindingState.legacyEmailMatch;
    }
    return PlayerDriveBindingState.accountMismatch;
  }

  String _driveAccountIdentity(DriveConnectionInfo? info) {
    if (info == null || info.isEmpty) return '';
    final subject = info.subjectId.trim();
    if (subject.isNotEmpty) return 'subject:${subject.toLowerCase()}';
    final email = _normalizedEmail(info.email);
    if (email.isNotEmpty) return 'email:$email';
    return '';
  }

  void _cacheRecentDriveConnection(DriveConnectionInfo info) {
    if (info.isEmpty) return;
    _recentDriveConnection = info;
    _recentDriveConnectionExpiresAt = DateTime.now().add(
      _recentDriveConnectionTtl,
    );
  }

  DriveConnectionInfo? _loadRecentDriveConnection() {
    final info = _recentDriveConnection;
    final expiresAt = _recentDriveConnectionExpiresAt;
    if (info == null || expiresAt == null) {
      return null;
    }
    if (DateTime.now().isAfter(expiresAt)) {
      _clearRecentDriveConnection();
      return null;
    }
    return info;
  }

  void _clearRecentDriveConnection() {
    _recentDriveConnection = null;
    _recentDriveConnectionExpiresAt = null;
  }

  DriveConnectionInfo? _loadSharedChildDriveConnectionInfo() {
    return _buildDriveConnectionInfoFromLabelEmail(
      label: getSharedChildDriveLabel(),
      email: getSharedChildDriveEmail(),
      subjectId: getSharedChildDriveSubjectId(),
    );
  }

  DriveConnectionInfo? _buildDriveConnectionInfoFromLabelEmail({
    required String label,
    required String email,
    String subjectId = '',
  }) {
    final trimmedLabel = label.trim();
    final trimmedEmail = email.trim();
    if (trimmedLabel.isEmpty &&
        trimmedEmail.isEmpty &&
        subjectId.trim().isEmpty) {
      return null;
    }
    var displayName = trimmedLabel;
    if (trimmedEmail.isNotEmpty) {
      final suffix = ' · $trimmedEmail';
      if (trimmedLabel.endsWith(suffix)) {
        displayName = trimmedLabel
            .substring(0, trimmedLabel.length - suffix.length)
            .trim();
      } else if (trimmedLabel.toLowerCase() == trimmedEmail.toLowerCase()) {
        displayName = '';
      }
    }
    return DriveConnectionInfo(
      email: trimmedEmail,
      displayName: displayName,
      subjectId: subjectId,
    );
  }

  Future<bool> _hasRemoteBackupFile() async {
    final driveApi = await _driveApi(requireInteractive: false);
    return _hasRemoteBackupFileWithApi(driveApi);
  }

  Future<bool> _hasRemoteBackupFileWithApi(drive.DriveApi driveApi) async {
    final folderId = await _findFolderId(driveApi);
    if (folderId == null) {
      return false;
    }
    final file = await _findBackupFile(driveApi, folderId);
    return file?.id != null;
  }

  Future<Map<String, dynamic>?> _loadLatestRemoteBackupMap() async {
    final driveApi = await _driveApi(requireInteractive: false);
    return _loadLatestRemoteBackupMapWithApi(driveApi);
  }

  Future<Map<String, dynamic>?> _loadLatestRemoteBackupMapWithApi(
    drive.DriveApi driveApi,
  ) async {
    final folderId = await _findFolderId(driveApi);
    if (folderId == null) {
      return null;
    }
    final file = await _findBackupFile(driveApi, folderId);
    if (file?.id == null) {
      return null;
    }
    return _downloadBackupMap(driveApi, file!.id!);
  }

  Future<DriveConnectionInfo?>
      _loadLatestRemoteSharedChildDriveConnectionInfo() async {
    final remote = await _loadLatestRemoteBackupMap();
    if (remote == null) {
      return null;
    }
    final sharedChildLabel = _extractSharedChildDriveLabel(remote);
    final sharedChildEmail = _extractSharedChildDriveEmail(remote);
    final sharedChildSubjectId = _extractSharedChildDriveSubjectId(remote);
    final fallbackLabel = sharedChildLabel.isNotEmpty
        ? sharedChildLabel
        : _extractChildName(remote);
    return _buildDriveConnectionInfoFromLabelEmail(
      label: fallbackLabel,
      email: sharedChildEmail,
      subjectId: sharedChildSubjectId,
    );
  }

  void _bindDriveAccountStateChanges() {
    unawaited(_googleAccountSubscription?.cancel());
    unawaited(_firebaseAuthSubscription?.cancel());
    final google = _googleSignIn;
    if (google != null) {
      _googleAccountSubscription = google.onCurrentUserChanged.listen(
        (_) => unawaited(_handleDriveAccountStateChanged()),
      );
    }
    if (kIsWeb) {
      final auth = _firebaseAuth;
      if (auth == null) {
        return;
      }
      _firebaseAuthSubscription = auth.authStateChanges().listen(
            (_) => unawaited(_handleDriveAccountStateChanged()),
          );
      return;
    }
  }

  Future<void> _handleDriveAccountStateChanged() async {
    try {
      if (kIsWeb) {
        if (_googleSignIn?.currentUser == null &&
            _firebaseAuth?.currentUser == null) {
          _clearRecentDriveConnection();
        }
      } else if (_googleSignIn?.currentUser == null) {
        _clearRecentDriveConnection();
        _lastSilentSignInAccount = null;
        _lastSilentSignInAt = null;
      }
      await _syncConnectedDriveAccountCache(
        attemptFamilyLinkRecovery: true,
      );
    } catch (e, st) {
      debugPrint('Drive account state sync failed: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      if (!_driveAccountStateController.isClosed) {
        _driveAccountStateController.add(null);
      }
    }
  }

  DriveConnectionInfo? _loadCachedDriveConnectionInfo() {
    final email =
        (_optionBox.get(connectedDriveEmailLocalKey) as String?)?.trim() ?? '';
    final displayName =
        (_optionBox.get(connectedDriveLabelLocalKey) as String?)?.trim() ?? '';
    final subjectId =
        (_optionBox.get(connectedDriveSubjectLocalKey) as String?)?.trim() ??
            '';
    if (email.isEmpty && displayName.isEmpty && subjectId.isEmpty) {
      return null;
    }
    return DriveConnectionInfo(
      email: email,
      displayName: displayName,
      subjectId: subjectId,
    );
  }

  DriveConnectionInfo? _loadSavedRecordDriveConnectionInfo() {
    final email =
        (_optionBox.get(recordDriveEmailLocalKey) as String?)?.trim() ?? '';
    final displayName =
        (_optionBox.get(recordDriveLabelLocalKey) as String?)?.trim() ?? '';
    final subjectId =
        (_optionBox.get(recordDriveSubjectLocalKey) as String?)?.trim() ?? '';
    if (email.isEmpty && displayName.isEmpty && subjectId.isEmpty) {
      return null;
    }
    return DriveConnectionInfo(
      email: email,
      displayName: displayName,
      subjectId: subjectId,
    );
  }

  DriveConnectionInfo? _loadSavedParentDriveConnectionInfo() {
    final email =
        (_optionBox.get(parentDriveEmailLocalKey) as String?)?.trim() ?? '';
    final displayName =
        (_optionBox.get(parentDriveLabelLocalKey) as String?)?.trim() ?? '';
    final subjectId =
        (_optionBox.get(parentDriveSubjectLocalKey) as String?)?.trim() ?? '';
    if (email.isEmpty && displayName.isEmpty && subjectId.isEmpty) {
      return null;
    }
    return DriveConnectionInfo(
      email: email,
      displayName: displayName,
      subjectId: subjectId,
    );
  }

  DriveConnectionInfo? _loadSavedDriveConnectionInfoForCurrentRole() {
    final state = _familyService.loadState();
    if (state.isCoachMode) {
      return CoachRosterService(
            HiveOptionRepository(_optionBox),
          ).activePlayerDriveConnection() ??
          _loadSavedParentDriveConnectionInfo();
    }
    final supportMode = state.isSupportMode;
    final emailKey =
        supportMode ? parentDriveEmailLocalKey : recordDriveEmailLocalKey;
    final labelKey =
        supportMode ? parentDriveLabelLocalKey : recordDriveLabelLocalKey;
    final subjectKey =
        supportMode ? parentDriveSubjectLocalKey : recordDriveSubjectLocalKey;
    final email = (_optionBox.get(emailKey) as String?)?.trim() ?? '';
    final displayName = (_optionBox.get(labelKey) as String?)?.trim() ?? '';
    final subjectId = (_optionBox.get(subjectKey) as String?)?.trim() ?? '';
    if (email.isEmpty && displayName.isEmpty && subjectId.isEmpty) {
      return null;
    }
    return DriveConnectionInfo(
      email: email,
      displayName: displayName,
      subjectId: subjectId,
    );
  }

  Future<DriveConnectionInfo?> _loadDriveConnectionInfo() async {
    if (_driveConnectionLoader != null) {
      final info = await _driveConnectionLoader();
      if (info != null && !info.isEmpty) {
        _cacheRecentDriveConnection(info);
      }
      return info;
    }
    if (kIsWeb) {
      var account = _googleSignIn?.currentUser;
      account ??= await _signInSilentlyThrottled();
      if (account != null) {
        final info = DriveConnectionInfo(
          email: account.email.trim(),
          displayName: account.displayName?.trim() ?? '',
          subjectId: account.id,
        );
        _cacheRecentDriveConnection(info);
        return info;
      }
      final user = _firebaseAuth?.currentUser;
      if (user == null) return _loadRecentDriveConnection();
      final info = DriveConnectionInfo(
        email: user.email?.trim() ?? '',
        displayName: user.displayName?.trim() ?? '',
        subjectId: user.uid,
      );
      _cacheRecentDriveConnection(info);
      return info;
    }
    final google = _googleSignIn;
    if (google == null) return null;
    var account = google.currentUser;
    account ??= await _signInSilentlyThrottled();
    if (account == null) return _loadRecentDriveConnection();
    final info = DriveConnectionInfo(
      email: account.email.trim(),
      displayName: account.displayName?.trim() ?? '',
      subjectId: account.id,
    );
    _cacheRecentDriveConnection(info);
    return info;
  }

  Future<void> _syncSharedChildDriveMetadataIfNeeded() async {
    final state = _familyService.loadState();
    if (state.currentRole != FamilyRole.child) {
      return;
    }
    final info = _loadCachedDriveConnectionInfo();
    if (info == null || info.email.trim().isEmpty) {
      return;
    }
    await _optionBox.put(sharedChildDriveEmailKey, info.email.trim());
    if (info.label.trim().isNotEmpty) {
      await _optionBox.put(sharedChildDriveLabelKey, info.label.trim());
    }
    if (info.subjectId.trim().isNotEmpty) {
      await _optionBox.put(
        sharedChildDriveSubjectLocalKey,
        info.subjectId.trim(),
      );
    }
  }

  Future<bool> _prepareConnectedDriveDataForCurrentRole({
    bool throwOnChangedPlayerDrive = false,
  }) async {
    final bindingState = _currentRoleDriveBindingState();
    if (bindingState == PlayerDriveBindingState.notConnected) {
      return false;
    }
    if (bindingState == PlayerDriveBindingState.verified) {
      return false;
    }
    if (throwOnChangedPlayerDrive) {
      throw StateError(driveAccountBindingRequiredErrorCode);
    }
    // An unbound, legacy, or changed account must restore/import before it can
    // become the active write target. Account caches never establish binding.
    return true;
  }

  bool _driveAccountNeedsResolutionBeforeBackup() {
    return needsDriveImportBeforeBackup();
  }

  void _throwIfDriveAccountNeedsResolutionBeforeBackup() {
    if (_driveAccountNeedsResolutionBeforeBackup()) {
      final errorCode =
          _familyService.loadState().currentRole == FamilyRole.child
              ? changedPlayerDriveConnectionErrorCode
              : driveAccountBindingRequiredErrorCode;
      throw StateError(errorCode);
    }
  }

  Future<String> _findOrCreateFolder(drive.DriveApi api) async {
    final existingId = await _findFolderIdByName(api, _folderName);
    if (existingId != null) {
      return existingId;
    }
    for (final legacyFolderName in _legacyBackupFolderNames) {
      final legacyId = await _findFolderIdByName(api, legacyFolderName);
      if (legacyId != null) {
        try {
          await api.files.update(
            drive.File(
              name: _folderName,
              appProperties: const <String, String>{
                _backupFolderMarkerKey: _backupFolderMarkerValue,
              },
            ),
            legacyId,
            $fields: 'id,name',
          );
        } catch (_) {
          // Keep using the existing folder if Drive refuses the rename.
        }
        return legacyId;
      }
    }
    final folder = await api.files.create(
      drive.File(
        name: _folderName,
        mimeType: 'application/vnd.google-apps.folder',
        appProperties: const <String, String>{
          _backupFolderMarkerKey: _backupFolderMarkerValue,
        },
      ),
    );
    return folder.id!;
  }

  Future<String?> _findFolderId(drive.DriveApi api) async {
    final currentId = await _findFolderIdByName(api, _folderName);
    if (currentId != null) return currentId;
    for (final legacyFolderName in _legacyBackupFolderNames) {
      final legacyId = await _findFolderIdByName(api, legacyFolderName);
      if (legacyId != null) return legacyId;
    }
    return null;
  }

  Future<String?> _findFolderIdByName(
    drive.DriveApi api,
    String folderName,
  ) async {
    final result = await api.files.list(
      q: "mimeType='application/vnd.google-apps.folder' and "
          "name='$folderName' and trashed=false",
      spaces: 'drive',
      $fields: 'files(id,name,appProperties,modifiedTime)',
    );
    final folders = result.files ?? const <drive.File>[];
    final marked = folders.where((folder) {
      return folder.appProperties?[_backupFolderMarkerKey] ==
          _backupFolderMarkerValue;
    }).toList(growable: false);
    if (marked.length == 1) return marked.single.id;
    if (folders.length == 1) return folders.single.id;

    final matchingBackups = <drive.File>[];
    for (final folder in folders) {
      final id = folder.id;
      if (id == null || id.isEmpty) continue;
      if (await _findBackupFileByName(api, id, _activeBackupFileName) != null) {
        matchingBackups.add(folder);
      }
    }
    return matchingBackups.length == 1 ? matchingBackups.single.id : null;
  }

  Future<drive.File?> _findBackupFile(
    drive.DriveApi api,
    String folderId,
  ) async {
    final active = await _findBackupFileByName(
      api,
      folderId,
      _activeBackupFileName,
    );
    if (active != null || _activeCoachPlayerId.isNotEmpty) return active;
    for (final legacyFileName in _legacyFileNames) {
      final legacy = await _findBackupFileByName(api, folderId, legacyFileName);
      if (legacy != null) return legacy;
    }
    return null;
  }

  Future<drive.File?> _findPreviousBackupFile(
    drive.DriveApi api,
    String folderId,
  ) async {
    final active = await _findBackupFileByName(
      api,
      folderId,
      _activePreviousBackupFileName,
    );
    if (active != null || _activeCoachPlayerId.isNotEmpty) return active;
    for (final legacyFileName in _legacyPreviousFileNames) {
      final legacy = await _findBackupFileByName(api, folderId, legacyFileName);
      if (legacy != null) return legacy;
    }
    return null;
  }

  Future<drive.File?> _findFamilyContributionFile(
    drive.DriveApi api,
    String folderId,
  ) {
    return _findBackupFileByName(
      api,
      folderId,
      _activeFamilyContributionFileName,
    );
  }

  Future<drive.File?> _findBackupFileByName(
    drive.DriveApi api,
    String folderId,
    String fileName,
  ) async {
    final result = await api.files.list(
      q: "'$folderId' in parents and name='$fileName' and trashed=false",
      spaces: 'drive',
      orderBy: 'modifiedTime desc',
      $fields: 'files(id,name,modifiedTime)',
    );
    return result.files?.firstOrNull;
  }

  Future<void> _cleanupDuplicateBackups(
    drive.DriveApi api,
    String folderId,
    String keepId,
  ) async {
    await _cleanupDuplicateBackupFiles(
      api,
      folderId,
      _activeBackupFileName,
      keepId,
    );
  }

  Future<void> _cleanupDuplicatePreviousBackups(
    drive.DriveApi api,
    String folderId,
    String keepId,
  ) async {
    await _cleanupDuplicateBackupFiles(
      api,
      folderId,
      _activePreviousBackupFileName,
      keepId,
    );
  }

  Future<void> _cleanupHistoryBackups(
    drive.DriveApi api,
    String folderId,
  ) async {
    final prefix = _activeHistoryBackupFileNamePrefix;
    final result = await api.files.list(
      q: "'$folderId' in parents and name contains '$prefix' and trashed=false",
      spaces: 'drive',
      orderBy: 'modifiedTime desc',
      $fields: 'files(id,name,modifiedTime)',
    );
    final files = (result.files ?? const <drive.File>[])
        .where((file) => (file.name ?? '').startsWith(prefix))
        .toList(growable: false);
    for (var i = _historyBackupRetentionCount; i < files.length; i++) {
      final id = files[i].id;
      if (id != null && id.isNotEmpty) {
        await api.files.update(drive.File(trashed: true), id);
      }
    }
  }

  Future<void> _cleanupDuplicateBackupFiles(
    drive.DriveApi api,
    String folderId,
    String fileName,
    String keepId,
  ) async {
    final result = await api.files.list(
      q: "'$folderId' in parents and name='$fileName' and trashed=false",
      spaces: 'drive',
      orderBy: 'modifiedTime desc',
      $fields: 'files(id,name,modifiedTime)',
    );
    final files = result.files ?? const <drive.File>[];
    for (final file in files) {
      if (file.id != null && file.id != keepId) {
        await api.files.update(drive.File(trashed: true), file.id!);
      }
    }
  }

  Future<void> _backupWithApi(drive.DriveApi driveApi) async {
    final familyState = _familyService.loadState();
    if (familyState.isSupportMode) {
      await _backupFamilyContributionWithApi(driveApi, familyState);
      return;
    }
    final folderId = await _findOrCreateFolder(driveApi);
    final activeBackupFileName = _activeBackupFileName;
    final existing = await _findBackupFile(driveApi, folderId);
    final existingContent = existing?.id == null
        ? null
        : await _downloadFileContent(driveApi, existing!.id!);
    final remote =
        existingContent == null ? null : _decodeBackupPayload(existingContent);
    _validateParentRemoteBinding(remote);
    _throwIfRemoteBackupChangedSinceLastRead(remote);
    final data = _buildUploadPayload(
      currentRole: familyState.currentRole,
      remote: remote,
    );
    _throwIfUnsafeRemoteOverwrite(local: data, remote: remote);
    final bytes = utf8.encode(jsonEncode(data));
    final media = drive.Media(Stream.value(bytes), bytes.length);
    late final DateTime syncedAt;
    if (existing != null) {
      if (_shouldCreateRemoteRecoverySnapshot()) {
        await _preservePreviousRemoteBackup(
          driveApi,
          folderId,
          existing,
          existingContent: existingContent,
        );
        await _setDateTimeOption(
          _lastRecoverySnapshotAtKeyForCurrentContext(),
          DateTime.now(),
        );
      }
      final updated = await driveApi.files.update(
        drive.File(name: activeBackupFileName),
        existing.id!,
        uploadMedia: media,
        $fields: 'id,modifiedTime',
      );
      syncedAt = updated.modifiedTime ?? DateTime.now();
      await _cleanupDuplicateBackups(driveApi, folderId, existing.id!);
      await _recordRemoteBackupReceipt(data, modifiedAt: syncedAt);
      await _recordRestoreBaselineFromBackup(data);
      await _recordSyncSuccess(
        role: familyState.currentRole,
        syncedAt: syncedAt,
      );
      return;
    }

    final created = await driveApi.files.create(
      drive.File(name: activeBackupFileName, parents: [folderId]),
      uploadMedia: media,
      $fields: 'id,modifiedTime',
    );
    syncedAt = created.modifiedTime ?? DateTime.now();
    await _recordRemoteBackupReceipt(data, modifiedAt: syncedAt);
    await _recordRestoreBaselineFromBackup(data);
    await _recordSyncSuccess(role: familyState.currentRole, syncedAt: syncedAt);
    if (created.id != null) {
      await _cleanupDuplicateBackups(driveApi, folderId, created.id!);
    }
  }

  Future<void> _backupFamilyContributionWithApi(
    drive.DriveApi driveApi,
    FamilyAccessState familyState,
  ) async {
    final link = _activeFamilyDriveLink();
    if (link != null && familyState.isParentRole) {
      await _backupLinkedFamilyContributionWithApi(
        driveApi,
        familyState,
        link,
      );
      return;
    }
    final folderId = await _findOrCreateFolder(driveApi);
    final local = _buildFamilyContributionBackup(familyState);
    final existing = await _findFamilyContributionFile(driveApi, folderId);
    final data = existing?.id == null
        ? local
        : _mergeFamilyContributionBackup(
            remote: await _downloadBackupMap(driveApi, existing!.id!),
            local: local,
            familyState: familyState,
          );
    final bytes = utf8.encode(jsonEncode(data));
    final media = drive.Media(Stream.value(bytes), bytes.length);
    final fileName = _activeFamilyContributionFileName;
    late final DateTime syncedAt;
    if (existing != null && existing.id != null) {
      final updated = await driveApi.files.update(
        drive.File(name: fileName),
        existing.id!,
        uploadMedia: media,
        $fields: 'id,modifiedTime',
      );
      syncedAt = updated.modifiedTime ?? DateTime.now();
    } else {
      final created = await driveApi.files.create(
        drive.File(name: fileName, parents: [folderId]),
        uploadMedia: media,
        $fields: 'id,modifiedTime',
      );
      syncedAt = created.modifiedTime ?? DateTime.now();
    }
    await _recordSyncSuccess(role: familyState.currentRole, syncedAt: syncedAt);
  }

  Future<void> _backupLinkedFamilyContributionWithApi(
    drive.DriveApi driveApi,
    FamilyAccessState familyState,
    FamilyDriveLinkRecord link,
  ) async {
    _validateFamilyLinkForCurrentSession(link, familyState);
    final remote =
        await _downloadLinkedBackupMap(driveApi, link.contributionFile);
    _validateLinkedContributionPayload(link: link, remote: remote);
    final local = _buildFamilyContributionBackup(familyState);
    final data = _mergeFamilyContributionBackup(
      remote: remote,
      local: local,
      familyState: familyState,
    );
    final bytes = utf8.encode(jsonEncode(data));
    final media = drive.Media(Stream.value(bytes), bytes.length);
    final updated = await _updateLinkedJsonFile(
      driveApi,
      fileId: link.contributionFileId,
      fileName: _activeFamilyContributionFileName,
      uploadMedia: media,
    );
    final syncedAt = updated.modifiedTime ?? DateTime.now();
    await _familyLinkStore.saveRecord(
      link.copyWith(
        lastContributionModifiedAt: syncedAt,
        updatedAt: syncedAt,
      ),
    );
    await _recordSyncSuccess(role: familyState.currentRole, syncedAt: syncedAt);
  }

  Future<void> _preservePreviousRemoteBackup(
    drive.DriveApi driveApi,
    String folderId,
    drive.File existing, {
    String? existingContent,
  }) async {
    final existingId = existing.id;
    if (existingId == null || existingId.isEmpty) return;
    final content =
        existingContent ?? await _downloadFileContent(driveApi, existingId);
    final previousCreatedAt =
        _createdAtFromBackupContent(content) ?? existing.modifiedTime;
    if (previousCreatedAt != null) {
      await _setDateTimeOption(_previousBackupCreatedAtKey, previousCreatedAt);
    }
    final bytes = utf8.encode(content);
    final media = drive.Media(Stream.value(bytes), bytes.length);
    final activePreviousBackupFileName = _activePreviousBackupFileName;
    final createdAt =
        previousCreatedAt ?? existing.modifiedTime ?? DateTime.now();
    try {
      await driveApi.files.copy(
        drive.File(
          name: _historyBackupFileName(createdAt),
          parents: <String>[folderId],
        ),
        existingId,
        $fields: 'id,modifiedTime',
      );
      await _cleanupHistoryBackups(driveApi, folderId);
    } catch (_) {
      // Preserve a recovery point even for Drive clients that do not allow a
      // server-side copy of the managed file.
      await _createHistoryRemoteBackup(
        driveApi,
        folderId,
        content,
        createdAt: createdAt,
      );
    }
    final previous = await _findPreviousBackupFile(driveApi, folderId);
    if (previous != null && previous.id != null) {
      final updated = await driveApi.files.update(
        drive.File(name: activePreviousBackupFileName),
        previous.id!,
        uploadMedia: media,
        $fields: 'id,modifiedTime',
      );
      if (updated.id != null) {
        await _cleanupDuplicatePreviousBackups(driveApi, folderId, updated.id!);
      }
      return;
    }
    final created = await driveApi.files.create(
      drive.File(name: activePreviousBackupFileName, parents: [folderId]),
      uploadMedia: media,
      $fields: 'id,modifiedTime',
    );
    if (created.id != null) {
      await _cleanupDuplicatePreviousBackups(driveApi, folderId, created.id!);
    }
  }

  Future<void> _createHistoryRemoteBackup(
    drive.DriveApi driveApi,
    String folderId,
    String content, {
    required DateTime createdAt,
  }) async {
    final bytes = utf8.encode(content);
    final media = drive.Media(Stream.value(bytes), bytes.length);
    await driveApi.files.create(
      drive.File(
        name: _historyBackupFileName(createdAt),
        parents: [folderId],
      ),
      uploadMedia: media,
      $fields: 'id,modifiedTime',
    );
    await _cleanupHistoryBackups(driveApi, folderId);
  }

  String _historyBackupFileName(DateTime createdAt) {
    final utc = createdAt.toUtc();
    final stamp = _compactUtcTimestamp(utc);
    return '$_activeHistoryBackupFileNamePrefix$stamp.json';
  }

  String _compactUtcTimestamp(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year.toString().padLeft(4, '0')}'
        '${two(value.month)}'
        '${two(value.day)}T'
        '${two(value.hour)}'
        '${two(value.minute)}'
        '${two(value.second)}Z';
  }

  DateTime? _createdAtFromBackupContent(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map) return null;
      return DateTime.tryParse(decoded['createdAt']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  String _remoteReceiptKeyForCurrentContext() {
    final context =
        '${_familyService.loadState().currentRole.name}|$_activeBackupFileName';
    return _remoteReceiptKeyPrefix + base64Url.encode(utf8.encode(context));
  }

  String _lastRecoverySnapshotAtKeyForCurrentContext() {
    final context =
        '${_familyService.loadState().currentRole.name}|$_activeBackupFileName';
    return _lastRecoverySnapshotAtKeyPrefix +
        base64Url.encode(utf8.encode(context));
  }

  bool _shouldCreateRemoteRecoverySnapshot() {
    final last =
        _getDateTimeOption(_lastRecoverySnapshotAtKeyForCurrentContext());
    return last == null || !_isSameDay(last, DateTime.now());
  }

  void _throwIfRemoteBackupChangedSinceLastRead(
    Map<String, dynamic>? remote,
  ) {
    if (remote == null) return;
    final raw = _optionBox.get(_remoteReceiptKeyForCurrentContext());
    if (raw is! Map) {
      if (_requiresRemoteReceipt(remote)) {
        throw StateError(remoteBackupConflictErrorCode);
      }
      return;
    }
    final expectedHash = raw['contentHash']?.toString() ?? '';
    final expectedAccount = raw['accountIdentity']?.toString() ?? '';
    final currentAccount = _driveAccountIdentity(
      _loadCachedDriveConnectionInfo(),
    );
    if (expectedAccount.isNotEmpty &&
        currentAccount.isNotEmpty &&
        expectedAccount != currentAccount) {
      throw StateError(remoteBackupConflictErrorCode);
    }
    if (expectedHash.isNotEmpty &&
        expectedHash != _stableBackupContentHash(remote)) {
      throw StateError(remoteBackupConflictErrorCode);
    }
  }

  bool _requiresRemoteReceipt(Map<String, dynamic> backup) {
    final manifest = backup[_backupSafetyManifestKey];
    if (manifest is! Map) return false;
    final schemaVersion = (manifest['schemaVersion'] as num?)?.toInt() ?? 1;
    return schemaVersion >= 2 &&
        manifest['hashAlgorithm'] == 'sha256' &&
        (manifest['contentHash']?.toString().length ?? 0) == 64;
  }

  Future<void> _recordRemoteBackupReceipt(
    Map<String, dynamic> backup, {
    required DateTime modifiedAt,
  }) async {
    await _optionBox
        .put(_remoteReceiptKeyForCurrentContext(), <String, dynamic>{
      'contentHash': _stableBackupContentHash(backup),
      'accountIdentity': _driveAccountIdentity(
        _loadCachedDriveConnectionInfo(),
      ),
      'modifiedAt': modifiedAt.toUtc().toIso8601String(),
    });
  }

  Future<void> _restoreLatestWithApi(drive.DriveApi driveApi) async {
    final state = _familyService.loadState();
    final link = _activeFamilyDriveLink();
    if (state.isParentRole && link != null) {
      _validateFamilyLinkForCurrentSession(link, state);
      final coreMetadata = await _linkedFileMetadata(
        driveApi,
        link.coreBackupFileId,
        FamilyDriveFileKind.coreBackup,
      );
      final remote =
          await _downloadLinkedBackupMap(driveApi, link.coreBackupFile);
      _validateLinkedCorePayload(link: link, remote: remote);
      await _restoreFromMap(remote, mode: RestoreMode.safeMerge);
      DateTime? contributionModifiedAt;
      try {
        final contributionMetadata = await _linkedFileMetadata(
          driveApi,
          link.contributionFileId,
          FamilyDriveFileKind.parentContribution,
        );
        contributionModifiedAt = contributionMetadata.modifiedAt;
        final contributionData = await _downloadLinkedBackupMap(
          driveApi,
          link.contributionFile,
        );
        _validateLinkedContributionPayload(
          link: link,
          remote: contributionData,
        );
        await _restoreSharedOptionsFromMap(contributionData);
      } on StateError catch (error) {
        if (error.message != familyLinkPermissionRevokedErrorCode) {
          rethrow;
        }
      }
      await _familyLinkStore.saveRecord(
        link.copyWith(
          lastCoreModifiedAt: coreMetadata.modifiedAt,
          lastContributionModifiedAt: contributionModifiedAt,
          updatedAt: DateTime.now(),
        ),
      );
      await _recordFamilySyncPull(
        DateTime.now(),
        remoteModifiedAt:
            coreMetadata.modifiedAt ?? contributionModifiedAt ?? DateTime.now(),
      );
      await _setParentSharedDataDirty(false);
      return;
    }
    final folderId = await _findFolderId(driveApi);
    if (folderId == null) {
      throw StateError('No backup file found.');
    }
    final file = await _findBackupFile(driveApi, folderId);
    if (file == null) {
      throw StateError('No backup file found.');
    }
    await _restoreBackupFileWithApi(
      driveApi,
      file,
      mode: RestoreMode.safeMerge,
    );
    if (_familyService.loadState().isSupportMode) {
      final contribution = await _findFamilyContributionFile(
        driveApi,
        folderId,
      );
      if (contribution?.id != null && contribution!.id != file.id) {
        final contributionData = await _downloadBackupMap(
          driveApi,
          contribution.id!,
        );
        await _restoreSharedOptionsFromMap(contributionData);
      }
      await _recordFamilySyncPull(
        DateTime.now(),
        remoteModifiedAt: file.modifiedTime ?? DateTime.now(),
      );
      await _setParentSharedDataDirty(false);
    }
  }

  Future<RestoreReceipt> _restoreLatestWithApiAndMode(
    drive.DriveApi driveApi,
    RestoreMode mode, {
    String? expectedPlanHash,
  }) async {
    final state = _familyService.loadState();
    final link = _activeFamilyDriveLink();
    if (state.isParentRole && link != null) {
      _validateFamilyLinkForCurrentSession(link, state);
      final coreMetadata = await _linkedFileMetadata(
        driveApi,
        link.coreBackupFileId,
        FamilyDriveFileKind.coreBackup,
      );
      final remote =
          await _downloadLinkedBackupMap(driveApi, link.coreBackupFile);
      _validateLinkedCorePayload(link: link, remote: remote);
      final plan = mode == RestoreMode.exactReplace
          ? null
          : _buildRestorePlan(remote: remote, mode: mode);
      if (expectedPlanHash != null && plan?.planHash != expectedPlanHash) {
        throw StateError(backupPreviewChangedErrorCode);
      }
      await _restoreFromMap(
        remote,
        mode: mode,
        expectedPlanHash: expectedPlanHash,
      );
      await _recordRemoteBackupReceipt(
        remote,
        modifiedAt: coreMetadata.modifiedAt ?? DateTime.now(),
      );
      await _familyLinkStore.saveRecord(
        link.copyWith(
          lastCoreModifiedAt: coreMetadata.modifiedAt,
          updatedAt: DateTime.now(),
        ),
      );
      await _recordFamilySyncPull(
        DateTime.now(),
        remoteModifiedAt: coreMetadata.modifiedAt ?? DateTime.now(),
      );
      await _setParentSharedDataDirty(false);
      if (plan == null) {
        final descriptor = const BackupRestorePlanner().describe(remote);
        return RestoreReceipt(
          planHash: descriptor.contentHash,
          applied:
              descriptor.counts.trainingEntries + descriptor.counts.options,
          updated: 0,
          skipped: 0,
          conflicts: 0,
          deleted: 0,
        );
      }
      return RestoreReceipt(
        planHash: plan.planHash,
        applied: plan.count(RestoreOperationType.add),
        updated: plan.count(RestoreOperationType.update),
        skipped: plan.count(RestoreOperationType.skip),
        conflicts: plan.count(RestoreOperationType.conflict),
        deleted: plan.count(RestoreOperationType.tombstone),
      );
    }
    final folderId = await _findFolderId(driveApi);
    if (folderId == null) {
      throw StateError('No backup file found.');
    }
    final file = await _findBackupFile(driveApi, folderId);
    if (file == null) {
      throw StateError('No backup file found.');
    }
    final remote = await _downloadBackupMap(driveApi, file.id!);
    await _syncConnectedDriveAccountCache();
    _validateRestoreBinding(remote);
    final plan = mode == RestoreMode.exactReplace
        ? null
        : _buildRestorePlan(remote: remote, mode: mode);
    if (expectedPlanHash != null && plan?.planHash != expectedPlanHash) {
      throw StateError(backupPreviewChangedErrorCode);
    }
    await _restoreFromMap(
      remote,
      mode: mode,
      expectedPlanHash: expectedPlanHash,
    );
    if (_familyService.loadState().isSupportMode) {
      final contribution = await _findFamilyContributionFile(
        driveApi,
        folderId,
      );
      if (contribution?.id != null && contribution!.id != file.id) {
        final contributionData = await _downloadBackupMap(
          driveApi,
          contribution.id!,
        );
        await _restoreSharedOptionsFromMap(contributionData);
      }
      await _recordFamilySyncPull(
        DateTime.now(),
        remoteModifiedAt: file.modifiedTime ?? DateTime.now(),
      );
      await _setParentSharedDataDirty(false);
    }
    await _recordRemoteBackupReceipt(
      remote,
      modifiedAt: file.modifiedTime ?? DateTime.now(),
    );
    await _rememberCurrentRoleDriveConnectionAfterRestore();
    if (plan == null) {
      final descriptor = const BackupRestorePlanner().describe(remote);
      return RestoreReceipt(
        planHash: descriptor.contentHash,
        applied: descriptor.counts.trainingEntries + descriptor.counts.options,
        updated: 0,
        skipped: 0,
        conflicts: 0,
        deleted: 0,
      );
    }
    return RestoreReceipt(
      planHash: plan.planHash,
      applied: plan.count(RestoreOperationType.add),
      updated: plan.count(RestoreOperationType.update),
      skipped: plan.count(RestoreOperationType.skip),
      conflicts: plan.count(RestoreOperationType.conflict),
      deleted: plan.count(RestoreOperationType.tombstone),
    );
  }

  Future<void> _restorePreviousWithApi(drive.DriveApi driveApi) async {
    final folderId = await _findFolderId(driveApi);
    if (folderId == null) {
      throw StateError('No previous backup file found.');
    }
    final file = await _findPreviousBackupFile(driveApi, folderId);
    if (file == null) {
      throw StateError('No previous backup file found.');
    }
    await _restoreBackupFileWithApi(
      driveApi,
      file,
      mode: RestoreMode.exactReplace,
    );
    if (_familyService.loadState().isSupportMode) {
      await _recordFamilySyncPull(
        DateTime.now(),
        remoteModifiedAt: file.modifiedTime ?? DateTime.now(),
      );
      await _setParentSharedDataDirty(false);
    }
  }

  Future<void> _restoreBackupFileWithApi(
    drive.DriveApi driveApi,
    drive.File file, {
    required RestoreMode mode,
  }) async {
    final media = await driveApi.files.get(
      file.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final content = await utf8.decoder.bind(media.stream).join();
    final data = _decodeBackupPayload(content);
    await _syncConnectedDriveAccountCache();
    _validateRestoreBinding(data);
    await _restoreFromMap(data, mode: mode);
    await _recordRemoteBackupReceipt(
      data,
      modifiedAt: file.modifiedTime ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _buildBackup({
    required FamilyRole updatedByRole,
    required bool familyLayerOnly,
  }) {
    final assetRecords = <String, dynamic>{};
    final assetIdBySourcePath = <String, String>{};
    final entries = _trainingBox.values
        .map(
          (entry) => _entryToMap(
            entry,
            assetRecords: assetRecords,
            assetIdBySourcePath: assetIdBySourcePath,
          ),
        )
        .toList();
    final options = <String, dynamic>{};
    final optionRecords = <Map<String, dynamic>>[];
    for (final key in _optionBox.keys) {
      if (!_shouldBackUpOptionKey(key)) {
        continue;
      }
      final encodedKey = _toBackupValue(key);
      final encodedValue = _encodeOptionValueForBackup(
        key: key as String,
        value: _optionBox.get(key),
        assetRecords: assetRecords,
        assetIdBySourcePath: assetIdBySourcePath,
      );
      if (encodedKey == _unsupportedValue ||
          encodedValue == _unsupportedValue) {
        throw StateError('$unsupportedBackupValueErrorCode:${key.toString()}');
      }
      optionRecords.add(<String, dynamic>{
        'key': encodedKey,
        'value': encodedValue,
      });
      options[key] = encodedValue;
    }
    final familyState = _familyService.loadState();
    final driveAccount = _driveAccountInfoForBackup();
    final driveAccountMetadata = driveAccount == null
        ? const <String, dynamic>{}
        : _driveConnectionMetadata(driveAccount);
    final backup = <String, dynamic>{
      _backupFormatKey: _backupFormatValue,
      'version': _backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'entries': entries,
      'options': options,
      _optionRecordsKey: optionRecords,
      _assetRecordsKey: assetRecords,
      _familyMetadataKey: FamilyAccessService.backupMetadataFromState(
        familyState,
        updatedByRole: updatedByRole,
        familyLayerOnly: familyLayerOnly,
      ),
      if (driveAccountMetadata.isNotEmpty)
        _driveAccountMetadataKey: driveAccountMetadata,
    };
    backup[_backupSafetyManifestKey] = _buildSafetyManifest(
      backup,
      driveAccount: driveAccount,
    );
    return backup;
  }

  Map<String, dynamic> _buildFamilyContributionBackup(
    FamilyAccessState familyState,
  ) {
    final sharedKeys = _sharedBackupOptionKeysForCurrentRole();
    final options = <String, dynamic>{};
    final optionRecords = <Map<String, dynamic>>[];
    for (final key in sharedKeys) {
      if (!_optionBox.containsKey(key)) {
        continue;
      }
      final encodedValue = _toBackupValue(_optionBox.get(key));
      if (encodedValue == _unsupportedValue) {
        throw StateError('$unsupportedBackupValueErrorCode:$key');
      }
      options[key] = encodedValue;
      optionRecords.add(<String, dynamic>{
        'key': key,
        'value': encodedValue,
      });
    }
    final driveAccount = _driveAccountInfoForBackup();
    final playerId = _activePlayerIdForMetadata;
    final metadata = <String, dynamic>{
      ...FamilyAccessService.backupMetadataFromState(
        familyState,
        updatedByRole: familyState.currentRole,
        familyLayerOnly: true,
      ),
      'playerId': playerId,
      'contributionLayerOnly': true,
      'ownedScopes': const <String>['feedback', 'rewardNames'],
    };
    final backup = <String, dynamic>{
      _backupFormatKey: BackupRestorePlanner.contributionFormatValue,
      'version': _backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'entries': const <Map<String, dynamic>>[],
      'options': options,
      _optionRecordsKey: optionRecords,
      _assetRecordsKey: const <String, dynamic>{},
      _familyMetadataKey: metadata,
      if (driveAccount != null && !driveAccount.isEmpty)
        _driveAccountMetadataKey: _driveConnectionMetadata(
          driveAccount,
          includeEmail: false,
        ),
    };
    backup[_backupSafetyManifestKey] = _buildSafetyManifest(
      backup,
      driveAccount: driveAccount,
      includeAccountEmail: false,
    )..addAll(<String, dynamic>{
        'playerId': playerId,
        'familyId': familyState.familyId,
        'contributionLayerOnly': true,
      });
    return backup;
  }

  Map<String, dynamic> _emptyParentContributionForPairing(
    FamilyAccessState familyState,
  ) {
    final metadata = <String, dynamic>{
      ...FamilyAccessService.backupMetadataFromState(
        familyState,
        updatedByRole: FamilyRole.parent,
        familyLayerOnly: true,
      ),
      'playerId': _activePlayerIdForMetadata,
      'contributionLayerOnly': true,
      'ownedScopes': const <String>['feedback', 'rewardNames'],
    };
    final backup = <String, dynamic>{
      _backupFormatKey: BackupRestorePlanner.contributionFormatValue,
      'version': _backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'entries': const <Map<String, dynamic>>[],
      'options': const <String, dynamic>{},
      _optionRecordsKey: const <Map<String, dynamic>>[],
      _assetRecordsKey: const <String, dynamic>{},
      _familyMetadataKey: metadata,
    };
    backup[_backupSafetyManifestKey] = _buildSafetyManifest(
      backup,
      driveAccount: _driveAccountInfoForBackup(),
      includeAccountEmail: false,
    )..addAll(<String, dynamic>{
        'playerId': _activePlayerIdForMetadata,
        'familyId': familyState.familyId,
        'contributionLayerOnly': true,
      });
    return backup;
  }

  Map<String, dynamic> _mergeFamilyContributionBackup({
    required Map<String, dynamic> remote,
    required Map<String, dynamic> local,
    required FamilyAccessState familyState,
  }) {
    if (remote[_backupFormatKey] !=
        BackupRestorePlanner.contributionFormatValue) {
      throw StateError(invalidBackupPayloadErrorCode);
    }
    final remoteFamilyId = _extractFamilyId(remote);
    final localFamilyId = familyState.familyId.trim();
    if (remoteFamilyId.isNotEmpty &&
        localFamilyId.isNotEmpty &&
        remoteFamilyId != localFamilyId) {
      throw StateError(parentFamilyMismatchErrorCode);
    }
    final remotePlayerId = _extractSafetyManifestPlayerId(remote) ?? '';
    final localPlayerId = _activePlayerIdForMetadata.trim();
    if (remotePlayerId.isNotEmpty &&
        localPlayerId.isNotEmpty &&
        remotePlayerId != localPlayerId) {
      throw StateError(backupPlayerMismatchErrorCode);
    }

    final allowedKeys = _sharedBackupOptionKeysForCurrentRole();
    final remoteOptions = _copyStringOptions(remote);
    final localOptions = _copyStringOptions(local);
    final mergedOptions = <String, dynamic>{};
    for (final key in allowedKeys) {
      final remoteValue = remoteOptions[key];
      final localValue = localOptions[key];
      if (remoteValue == null && localValue == null) continue;
      mergedOptions[key] = _mergeContributionValue(remoteValue, localValue);
    }
    final merged = <String, dynamic>{
      ...local,
      'createdAt': DateTime.now().toIso8601String(),
      'options': mergedOptions,
      _optionRecordsKey: mergedOptions.entries
          .map(
            (entry) => <String, dynamic>{
              'key': entry.key,
              'value': entry.value,
            },
          )
          .toList(growable: false),
    };
    merged[_backupSafetyManifestKey] = _buildSafetyManifest(
      merged,
      driveAccount: _driveAccountInfoForBackup(),
      includeAccountEmail: false,
      datasetIdOverride: _extractSafetyManifestDatasetId(remote),
    )..addAll(<String, dynamic>{
        'playerId': localPlayerId,
        'familyId': localFamilyId,
        'contributionLayerOnly': true,
      });
    return merged;
  }

  dynamic _mergeContributionValue(dynamic remote, dynamic local) {
    if (remote is Map && local is Map) {
      return <String, dynamic>{
        ...remote.map((key, value) => MapEntry(key.toString(), value)),
        ...local.map((key, value) => MapEntry(key.toString(), value)),
      };
    }
    return local ?? remote;
  }

  @visibleForTesting
  Map<String, dynamic> buildBackupForTesting({
    FamilyRole updatedByRole = FamilyRole.child,
    bool familyLayerOnly = false,
  }) =>
      _buildBackup(
        updatedByRole: updatedByRole,
        familyLayerOnly: familyLayerOnly,
      );

  @visibleForTesting
  Map<String, dynamic> buildFamilyContributionBackupForTesting() =>
      _buildFamilyContributionBackup(_familyService.loadState());

  @visibleForTesting
  Map<String, dynamic> mergeFamilyContributionBackupForTesting(
    Map<String, dynamic> remote,
  ) {
    final familyState = _familyService.loadState();
    return _mergeFamilyContributionBackup(
      remote: _validatedBackupData(remote),
      local: _buildFamilyContributionBackup(familyState),
      familyState: familyState,
    );
  }

  @visibleForTesting
  bool hasPendingRestoreTransactionForTesting() =>
      _optionBox.get(_restoreTransactionJournalKey) is Map;

  @visibleForTesting
  Future<void> restoreFromMapForTesting(
    Map<String, dynamic> data, {
    RestoreMode mode = RestoreMode.safeMerge,
    String? expectedPlanHash,
  }) =>
      _restoreFromMap(
        _validatedBackupData(data),
        mode: mode,
        expectedPlanHash: expectedPlanHash,
      );

  @visibleForTesting
  RestorePlan previewRestorePlanForTesting(
    Map<String, dynamic> data, {
    RestoreMode mode = RestoreMode.safeMerge,
  }) {
    return _buildRestorePlan(
      remote: _validatedBackupData(data),
      mode: mode,
    );
  }

  BackupSnapshotDescriptor describeLocalBackup() {
    return const BackupRestorePlanner().describe(
      _buildBackup(
        updatedByRole: _familyService.loadState().currentRole,
        familyLayerOnly: false,
      ),
    );
  }

  @visibleForTesting
  void validateRestoreBindingForTesting(Map<String, dynamic> data) {
    _validateRestoreBinding(_validatedBackupData(data));
  }

  @visibleForTesting
  Future<void> ensureGenericRestoreAllowedForTesting() {
    return _ensureGenericRestoreAllowed();
  }

  @visibleForTesting
  Future<void> saveLocalPreRestoreForTesting() => _saveLocalPreRestore();

  @visibleForTesting
  Future<void> writeRestoreTransactionJournalForTesting({
    required Map<String, dynamic> rollback,
    required String planHash,
    required RestoreMode mode,
  }) {
    return _writeRestoreTransactionJournal(
      rollback: rollback,
      planHash: planHash,
      mode: mode,
    );
  }

  @visibleForTesting
  Map<String, dynamic> mergeParentBackupForTesting({
    required Map<String, dynamic> remote,
  }) {
    return _buildUploadPayload(currentRole: FamilyRole.parent, remote: remote);
  }

  @visibleForTesting
  Future<bool> syncConnectedPlayerBackupForTesting({
    required DriveConnectionInfo connectedAccount,
    required Map<String, dynamic>? remoteBackup,
  }) async {
    _cacheRecentDriveConnection(connectedAccount);
    await _storeConnectedDriveAccountCache(connectedAccount);
    return _adoptConnectedPlayerBackup(remoteBackup: remoteBackup);
  }

  bool _shouldBackUpOptionKey(dynamic key) {
    if (key is! String) return false;
    if (_excludedOptionKeys.contains(key)) return false;
    if (_backedUpOptionKeys.contains(key)) return true;
    return _startsWithAny(key, _backedUpOptionKeyPrefixes);
  }

  bool _canRestoreOptionKey(dynamic key) => _shouldBackUpOptionKey(key);

  bool _shouldPreserveLocalOptionKey(dynamic key) {
    if (key is! String) return false;
    if (_excludedOptionKeys.contains(key) ||
        _localDeviceOptionKeys.contains(key)) {
      return true;
    }
    if (_backedUpOptionKeys.contains(key) ||
        _startsWithAny(key, _backedUpOptionKeyPrefixes)) {
      return false;
    }
    return _startsWithAny(key, _localDeviceOptionKeyPrefixes);
  }

  bool _startsWithAny(String key, List<String> prefixes) {
    for (final prefix in prefixes) {
      if (key.startsWith(prefix)) return true;
    }
    return false;
  }

  Map<String, dynamic> _localOptionSnapshotForRestore() {
    final snapshot = <String, dynamic>{};
    for (final key in _optionBox.keys) {
      if (key is String && _shouldPreserveLocalOptionKey(key)) {
        snapshot[key] = _optionBox.get(key);
      }
    }
    return snapshot;
  }

  Future<RestorePlan> previewLatestRestore({
    RestoreMode mode = RestoreMode.safeMerge,
  }) async {
    final driveApi = await _driveApi(requireInteractive: false);
    final state = _familyService.loadState();
    final link = _activeFamilyDriveLink();
    if (state.isParentRole && link != null) {
      _validateFamilyLinkForCurrentSession(link, state);
      final remote =
          await _downloadLinkedBackupMap(driveApi, link.coreBackupFile);
      _validateLinkedCorePayload(link: link, remote: remote);
      return _buildRestorePlan(remote: remote, mode: mode);
    }
    final folderId = await _findFolderId(driveApi);
    if (folderId == null) {
      throw StateError('No backup file found.');
    }
    final file = await _findBackupFile(driveApi, folderId);
    if (file?.id == null) {
      throw StateError('No backup file found.');
    }
    final remote = await _downloadBackupMap(driveApi, file!.id!);
    _validateRestoreBinding(remote);
    return _buildRestorePlan(remote: remote, mode: mode);
  }

  Future<RestoreReceipt> restoreLatestWithMode(
    RestoreMode mode, {
    String? expectedPlanHash,
  }) async {
    try {
      final driveApi = await _driveApi(requireInteractive: kIsWeb);
      await _ensureGenericRestoreAllowed();
      await _saveLocalPreRestore();
      return await _restoreLatestWithApiAndMode(
        driveApi,
        mode,
        expectedPlanHash: expectedPlanHash,
      );
    } catch (e, st) {
      if (!_isAuthError(e)) rethrow;
      debugPrint(
        'Drive sign-in/scope missing. Reauthenticating and retrying restore.',
      );
      debugPrintStack(stackTrace: st);
      await _reauthenticateForDriveScope();
      final retriedApi = await _driveApi(requireInteractive: false);
      await _ensureGenericRestoreAllowed();
      await _saveLocalPreRestore();
      return _restoreLatestWithApiAndMode(
        retriedApi,
        mode,
        expectedPlanHash: expectedPlanHash,
      );
    }
  }

  Future<void> _restoreFromMap(
    Map<String, dynamic> data, {
    RestoreMode mode = RestoreMode.safeMerge,
    String? expectedPlanHash,
  }) async {
    _validatePlayerSourceBackup(data);
    final rollback = _buildBackup(
      updatedByRole: _familyService.loadState().currentRole,
      familyLayerOnly: false,
    );
    final plan = mode == RestoreMode.exactReplace
        ? null
        : _buildRestorePlan(remote: data, mode: mode);
    if (expectedPlanHash != null && plan?.planHash != expectedPlanHash) {
      throw StateError(backupPreviewChangedErrorCode);
    }
    await _writeRestoreTransactionJournal(
      rollback: rollback,
      planHash: plan?.planHash ?? _stableBackupContentHash(data),
      mode: mode,
    );
    try {
      if (mode == RestoreMode.exactReplace) {
        await _restoreFromMapInternal(data);
        await _recordRestoreBaselineFromBackup(data);
      } else {
        await _restoreFromMapSafe(data, plan!);
      }
      await _clearRestoreTransactionJournal();
    } catch (_) {
      var rollbackSucceeded = false;
      try {
        await _restoreFromMapInternal(rollback);
        rollbackSucceeded = true;
      } catch (rollbackError, rollbackStackTrace) {
        debugPrint('Local restore rollback failed: $rollbackError');
        debugPrintStack(stackTrace: rollbackStackTrace);
      }
      if (rollbackSucceeded) {
        await _clearRestoreTransactionJournal();
      }
      rethrow;
    }
  }

  RestorePlan _buildRestorePlan({
    required Map<String, dynamic> remote,
    required RestoreMode mode,
  }) {
    final local = _buildBackup(
      updatedByRole: _familyService.loadState().currentRole,
      familyLayerOnly: false,
    );
    return const BackupRestorePlanner().buildPlan(
      local: local,
      remote: remote,
      mode: mode,
      baselineEntryHashes: _loadRestoreBaselineHashes('entries'),
      baselineOptionHashes: _loadRestoreBaselineHashes('options'),
    );
  }

  Future<RestoreReceipt> _restoreFromMapSafe(
    Map<String, dynamic> data,
    RestorePlan plan,
  ) async {
    final version = (data['version'] as num?)?.toInt() ?? 1;
    final entries = (data['entries'] as List?) ?? const [];
    final optionRecords = (data[_optionRecordsKey] as List?) ?? const [];
    final options = (data['options'] as Map?) ?? const {};
    final assetRecords = _extractAssetRecords(data);

    final stagedEntries = <String, TrainingEntry>{};
    for (final raw in entries) {
      if (raw is! Map) continue;
      final map = raw.map((key, value) => MapEntry(key.toString(), value));
      final entry = await _restoreEntryAssets(_entryFromMap(map), assetRecords);
      final id = BackupRestorePlanner.trainingRecordId(map);
      if (id.isNotEmpty) {
        stagedEntries[id] = entry;
      }
    }

    final stagedOptions = <String, dynamic>{};
    if (optionRecords.isNotEmpty) {
      for (final raw in optionRecords) {
        if (raw is! Map) continue;
        final key = _fromBackupValue(raw['key'], version: version);
        if (!_canRestoreOptionKey(key)) {
          continue;
        }
        var value = _fromBackupValue(raw['value'], version: version);
        value =
            await _restoreOptionAssetValue(key as String, value, assetRecords);
        stagedOptions[key] = value;
      }
    } else {
      for (final entry in options.entries) {
        if (!_canRestoreOptionKey(entry.key)) {
          continue;
        }
        var value = _fromBackupValue(entry.value, version: version);
        value = await _restoreOptionAssetValue(
          entry.key as String,
          value,
          assetRecords,
        );
        stagedOptions[entry.key as String] = value;
      }
    }

    final localTrainingKeys = <String, dynamic>{};
    _trainingBox.toMap().forEach((key, value) {
      localTrainingKeys[value.effectiveRecordId] = key;
    });
    var added = 0;
    var updated = 0;
    var deleted = 0;
    var skipped = 0;
    var conflicts = 0;

    for (final operation in plan.operations) {
      switch (operation.type) {
        case RestoreOperationType.add:
          if (operation.category == RestoreOperationCategory.training) {
            final entry = stagedEntries[operation.recordId];
            if (entry != null &&
                !localTrainingKeys.containsKey(operation.recordId)) {
              final key = await _trainingBox.add(entry);
              localTrainingKeys[operation.recordId] = key;
              added += 1;
            } else {
              skipped += 1;
            }
          } else if (operation.category == RestoreOperationCategory.option) {
            if (!_optionBox.containsKey(operation.recordId) &&
                stagedOptions.containsKey(operation.recordId)) {
              await _optionBox.put(
                operation.recordId,
                stagedOptions[operation.recordId],
              );
              added += 1;
            } else {
              skipped += 1;
            }
          }
          break;
        case RestoreOperationType.update:
          if (operation.category == RestoreOperationCategory.training) {
            final key = localTrainingKeys[operation.recordId];
            final entry = stagedEntries[operation.recordId];
            if (key != null && entry != null) {
              await _trainingBox.put(key, entry);
              updated += 1;
            } else {
              skipped += 1;
            }
          } else if (operation.category == RestoreOperationCategory.option) {
            if (stagedOptions.containsKey(operation.recordId)) {
              await _optionBox.put(
                operation.recordId,
                stagedOptions[operation.recordId],
              );
              updated += 1;
            } else {
              skipped += 1;
            }
          }
          break;
        case RestoreOperationType.tombstone:
          if (operation.category == RestoreOperationCategory.training) {
            final key = localTrainingKeys.remove(operation.recordId);
            final tombstone = stagedEntries[operation.recordId];
            if (key != null && tombstone != null) {
              await _trainingBox.put(key, tombstone);
              deleted += 1;
            } else if (tombstone != null) {
              final tombstoneKey = await _trainingBox.add(tombstone);
              localTrainingKeys[operation.recordId] = tombstoneKey;
              skipped += 1;
            } else {
              skipped += 1;
            }
          } else if (operation.category == RestoreOperationCategory.option) {
            await _optionBox.delete(operation.recordId);
            deleted += 1;
          }
          break;
        case RestoreOperationType.conflict:
          conflicts += 1;
          break;
        case RestoreOperationType.skip:
          skipped += 1;
          break;
      }
    }
    await _adoptDatasetIdFromSafetyManifest(data);
    if (!plan.hasConflicts) {
      await _recordRestoreBaselineFromBackup(data);
    }
    _notifyDataChanged();
    return RestoreReceipt(
      planHash: plan.planHash,
      applied: added,
      updated: updated,
      skipped: skipped,
      conflicts: conflicts,
      deleted: deleted,
    );
  }

  Map<String, String> _loadRestoreBaselineHashes(String key) {
    final raw = _optionBox.get(_restoreBaselineHashesKey);
    if (raw is! Map) return <String, String>{};
    final section = raw[key];
    if (section is! Map) return <String, String>{};
    return section.map(
      (entryKey, value) => MapEntry(entryKey.toString(), value.toString()),
    );
  }

  Future<void> _recordRestoreBaselineFromBackup(
    Map<String, dynamic> backup,
  ) async {
    final version = (backup['version'] as num?)?.toInt() ?? 1;
    final entries = <String, String>{};
    final rawEntries = backup['entries'];
    if (rawEntries is List) {
      for (final raw in rawEntries) {
        if (raw is! Map) continue;
        final map = raw.map((key, value) => MapEntry(key.toString(), value));
        final id = BackupRestorePlanner.trainingRecordId(map);
        if (id.isEmpty) continue;
        entries[id] = BackupRestorePlanner.entryPayloadHash(map);
      }
    }
    final options = <String, String>{};
    for (final record in _extractOptionRecords(backup)) {
      final key = _fromBackupValue(record['key'], version: version);
      if (key is! String || key.trim().isEmpty) {
        continue;
      }
      options[key] = BackupRestorePlanner.optionPayloadHash(record['value']);
    }
    await _optionBox.put(_restoreBaselineHashesKey, <String, dynamic>{
      'contentHash': _stableBackupContentHash(backup),
      'recordedAt': DateTime.now().toIso8601String(),
      'entries': entries,
      'options': options,
    });
  }

  Future<void> _writeRestoreTransactionJournal({
    required Map<String, dynamic> rollback,
    required String planHash,
    required RestoreMode mode,
  }) async {
    await _optionBox.put(_restoreTransactionJournalKey, <String, dynamic>{
      'id': _createLocalIdValue('restore_tx'),
      'status': 'applying',
      'mode': mode.name,
      'planHash': planHash,
      'createdAt': DateTime.now().toIso8601String(),
      'rollback': jsonEncode(rollback),
    });
  }

  Future<void> _clearRestoreTransactionJournal() async {
    await _optionBox.delete(_restoreTransactionJournalKey);
  }

  Future<void> _restoreFromMapInternal(Map<String, dynamic> data) async {
    final version = (data['version'] as num?)?.toInt() ?? 1;
    final entries = (data['entries'] as List?) ?? const [];
    final optionRecords = (data[_optionRecordsKey] as List?) ?? const [];
    final options = (data['options'] as Map?) ?? const {};
    final assetRecords = _extractAssetRecords(data);
    final preservedLocalOnly = _localOptionSnapshotForRestore();
    final fallbackCurrentSportId = _localCurrentSportIdForRestore();

    final stagedEntries = <TrainingEntry>[];
    for (final raw in entries) {
      if (raw is Map) {
        stagedEntries.add(
          await _restoreEntryAssets(
            _entryFromMap(raw.cast<String, dynamic>()),
            assetRecords,
          ),
        );
      }
    }

    final stagedOptions = <dynamic, dynamic>{};
    if (optionRecords.isNotEmpty) {
      for (final raw in optionRecords) {
        if (raw is! Map) continue;
        final key = _fromBackupValue(raw['key'], version: version);
        if (!_canRestoreOptionKey(key)) {
          continue;
        }
        var value = _fromBackupValue(raw['value'], version: version);
        value =
            await _restoreOptionAssetValue(key as String, value, assetRecords);
        stagedOptions[key] = value;
      }
    } else {
      for (final entry in options.entries) {
        if (!_canRestoreOptionKey(entry.key)) {
          continue;
        }
        var value = _fromBackupValue(entry.value, version: version);
        value = await _restoreOptionAssetValue(
          entry.key as String,
          value,
          assetRecords,
        );
        stagedOptions[entry.key] = value;
      }
    }

    await _trainingBox.clear();
    for (final entry in stagedEntries) {
      await _trainingBox.add(entry);
    }

    await _optionBox.clear();
    for (final entry in stagedOptions.entries) {
      await _optionBox.put(entry.key, entry.value);
    }
    for (final entry in preservedLocalOnly.entries) {
      if (entry.value != null) {
        await _optionBox.put(entry.key, entry.value);
      }
    }
    if (!stagedOptions.containsKey(SportCatalog.currentSportOptionKey) &&
        fallbackCurrentSportId != null) {
      await _optionBox.put(
        SportCatalog.currentSportOptionKey,
        fallbackCurrentSportId,
      );
    }
    await _adoptDatasetIdFromSafetyManifest(data);
    _notifyDataChanged();
  }

  String? _localCurrentSportIdForRestore() {
    final raw = _optionBox.get(SportCatalog.currentSportOptionKey);
    if (raw is! String || raw.trim().isEmpty) {
      return null;
    }
    return SportCatalog.normalizeSportId(raw);
  }

  dynamic _encodeOptionValueForBackup({
    required String key,
    required dynamic value,
    required Map<String, dynamic> assetRecords,
    required Map<String, String> assetIdBySourcePath,
  }) {
    if (PlayerProfileService.isPhotoUrlKey(key) && value is String) {
      return _toBackupValue(
        _replacePathWithAssetReferenceIfNeeded(
          assetId: 'option:$key',
          sourcePath: value,
          assetRecords: assetRecords,
          assetIdBySourcePath: assetIdBySourcePath,
          preferredFileName: 'profile_photo${_fileExtension(value)}',
        ),
      );
    }
    return _toBackupValue(value);
  }

  String _replacePathWithAssetReferenceIfNeeded({
    required String assetId,
    required String sourcePath,
    required Map<String, dynamic> assetRecords,
    required Map<String, String> assetIdBySourcePath,
    String? preferredFileName,
  }) {
    final trimmed = sourcePath.trim();
    if (trimmed.isEmpty || trimmed.startsWith('data:')) {
      return sourcePath;
    }
    final existingAssetId = assetIdBySourcePath[trimmed];
    if (existingAssetId != null) {
      return '$_assetRefPrefix$existingAssetId';
    }
    final record = _backupAssetFileStore.readFileSync(
      assetId: assetId,
      sourcePath: trimmed,
      preferredFileName: preferredFileName,
    );
    if (record == null) {
      return sourcePath;
    }
    assetIdBySourcePath[trimmed] = record.assetId;
    assetRecords[record.assetId] = record.toMap();
    return '$_assetRefPrefix${record.assetId}';
  }

  Map<String, BackupAssetRecord> _extractAssetRecords(
    Map<String, dynamic> data,
  ) {
    final raw = data[_assetRecordsKey];
    if (raw is! Map) {
      return const <String, BackupAssetRecord>{};
    }
    final records = <String, BackupAssetRecord>{};
    raw.forEach((key, value) {
      final record = BackupAssetRecord.tryParse(key.toString(), value);
      if (record != null) {
        records[record.assetId] = record;
      }
    });
    return records;
  }

  Future<dynamic> _restoreOptionAssetValue(
    String key,
    dynamic value,
    Map<String, BackupAssetRecord> assetRecords,
  ) async {
    if (!PlayerProfileService.isPhotoUrlKey(key) || value is! String) {
      return value;
    }
    return await _restoreAssetReference(value, assetRecords) ?? value;
  }

  Future<TrainingEntry> _restoreEntryAssets(
    TrainingEntry entry,
    Map<String, BackupAssetRecord> assetRecords,
  ) async {
    final restoredPaths = <String>[];
    for (final path in entry.imagePaths) {
      restoredPaths.add(
        await _restoreAssetReference(path, assetRecords) ?? path,
      );
    }
    final restoredPrimary =
        await _restoreAssetReference(entry.imagePath, assetRecords) ??
            (restoredPaths.isNotEmpty ? restoredPaths.first : entry.imagePath);
    return TrainingEntry(
      date: entry.date,
      sportId: entry.sportId,
      durationMinutes: entry.durationMinutes,
      intensity: entry.intensity,
      type: entry.type,
      mood: entry.mood,
      injury: entry.injury,
      notes: entry.notes,
      location: entry.location,
      program: entry.program,
      drills: entry.drills,
      club: entry.club,
      injuryPart: entry.injuryPart,
      painLevel: entry.painLevel,
      rehab: entry.rehab,
      goal: entry.goal,
      feedback: entry.feedback,
      heightCm: entry.heightCm,
      weightKg: entry.weightKg,
      imagePath: restoredPrimary,
      imagePaths: restoredPaths,
      status: entry.status,
      liftingByPart: entry.liftingByPart,
      liftingMinutes: entry.liftingMinutes,
      coachComment: entry.coachComment,
      fortuneComment: entry.fortuneComment,
      fortuneRecommendation: entry.fortuneRecommendation,
      fortuneRecommendedProgram: entry.fortuneRecommendedProgram,
      goalFocuses: entry.goalFocuses,
      goodPoints: entry.goodPoints,
      improvements: entry.improvements,
      nextGoal: entry.nextGoal,
      createdAt: entry.createdAt,
      jumpRopeCount: entry.jumpRopeCount,
      jumpRopeMinutes: entry.jumpRopeMinutes,
      jumpRopeEnabled: entry.jumpRopeEnabled,
      jumpRopeNote: entry.jumpRopeNote,
      opponentTeam: entry.opponentTeam,
      scoredGoals: entry.scoredGoals,
      concededGoals: entry.concededGoals,
      playerGoals: entry.playerGoals,
      playerAssists: entry.playerAssists,
      minutesPlayed: entry.minutesPlayed,
      matchLocation: entry.matchLocation,
      breakfastDone: entry.breakfastDone,
      breakfastRiceBowls: entry.breakfastRiceBowls,
      lunchDone: entry.lunchDone,
      lunchRiceBowls: entry.lunchRiceBowls,
      dinnerDone: entry.dinnerDone,
      dinnerRiceBowls: entry.dinnerRiceBowls,
      shotsOnTarget: entry.shotsOnTarget,
      ballsWon: entry.ballsWon,
      yellowCards: entry.yellowCards,
      redCards: entry.redCards,
      penaltyShootoutGoalsFor: entry.penaltyShootoutGoalsFor,
      penaltyShootoutGoalsAgainst: entry.penaltyShootoutGoalsAgainst,
      matchKind: entry.matchKind,
      leagueTeamNames: entry.leagueTeamNames,
      leagueResultMode: entry.leagueResultMode,
      leaguePoints: entry.leaguePoints,
      tournamentWins: entry.tournamentWins,
      trainingProgramMinutes: entry.trainingProgramMinutes,
      matchCompetitionName: entry.matchCompetitionName,
      matchCompetitionId: entry.matchCompetitionId,
      matchFixtureId: entry.matchFixtureId,
      matchStage: entry.matchStage,
      tournamentOutcome: entry.tournamentOutcome,
      isLesson: entry.isLesson,
      lessonDetail: entry.lessonDetail,
      recordId: entry.recordId,
      updatedAt: entry.updatedAt,
      revision: entry.revision,
      originDeviceId: entry.originDeviceId,
      payloadHash: entry.payloadHash,
      deletedAt: entry.deletedAt,
    );
  }

  Future<String?> _restoreAssetReference(
    String raw,
    Map<String, BackupAssetRecord> assetRecords,
  ) async {
    if (!_isAssetReference(raw)) {
      return null;
    }
    final assetId = raw.substring(_assetRefPrefix.length);
    final record = assetRecords[assetId];
    if (record == null) {
      return null;
    }
    return _backupAssetFileStore.restoreFile(record);
  }

  bool _isAssetReference(String raw) {
    return raw.trim().startsWith(_assetRefPrefix);
  }

  String _fileExtension(String path) {
    final trimmed = path.trim();
    final dotIndex = trimmed.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == trimmed.length - 1) {
      return '.bin';
    }
    final extension = trimmed.substring(dotIndex);
    if (!RegExp(r'^\.[A-Za-z0-9]+$').hasMatch(extension)) {
      return '.bin';
    }
    return extension;
  }

  void _validateParentRemoteBinding(Map<String, dynamic>? remote) {
    final state = _familyService.loadState();
    if (!state.isSupportMode || remote == null) {
      return;
    }
    final link = _activeFamilyDriveLink();
    if (link != null && state.isParentRole) {
      _validateFamilyLinkForCurrentSession(link, state);
      _validateLinkedCorePayload(link: link, remote: remote);
      return;
    }
    final localFamilyId = state.familyId.trim();
    final remoteFamilyId = _extractFamilyId(remote);
    if (localFamilyId.isNotEmpty &&
        remoteFamilyId.isNotEmpty &&
        localFamilyId != remoteFamilyId) {
      throw StateError(parentFamilyMismatchErrorCode);
    }
    final connected = _loadCachedDriveConnectionInfo();
    final expected = _expectedSharedChildDriveConnection(remote);
    if (connected != null &&
        expected != null &&
        !connected.isEmpty &&
        !expected.isEmpty &&
        !_sameDriveAccount(expected, connected)) {
      throw StateError(parentDriveMismatchErrorCode);
    }
  }

  void _validateRestoreBinding(
    Map<String, dynamic> remote, {
    bool allowIdentityAdoption = false,
  }) {
    _validatePlayerSourceBackup(remote);
    final state = _familyService.loadState();
    final activeLink = _activeFamilyDriveLink();
    if (state.isSupportMode && activeLink != null && state.isParentRole) {
      _validateFamilyLinkForCurrentSession(activeLink, state);
      _validateLinkedCorePayload(link: activeLink, remote: remote);
      return;
    }
    final canAdoptIdentity = !state.isSupportMode &&
        (allowIdentityAdoption || _canAdoptRemoteIdentityForRestore());
    final localFamilyId = state.familyId.trim();
    final remoteFamilyId = _extractFamilyId(remote);
    if (!canAdoptIdentity &&
        localFamilyId.isNotEmpty &&
        remoteFamilyId.isNotEmpty &&
        localFamilyId != remoteFamilyId) {
      throw StateError(parentFamilyMismatchErrorCode);
    }
    final localDatasetId =
        (_optionBox.get(_localDatasetIdKey) as String?)?.trim() ?? '';
    final remoteDatasetId = _extractSafetyManifestDatasetId(remote) ?? '';
    if (!canAdoptIdentity &&
        localDatasetId.isNotEmpty &&
        remoteDatasetId.isNotEmpty &&
        localDatasetId != remoteDatasetId) {
      throw StateError(backupDatasetMismatchErrorCode);
    }
    final localPlayerId = _localPlayerIdForComparison();
    final remotePlayerId = _extractSafetyManifestPlayerId(remote) ?? '';
    if (!canAdoptIdentity &&
        localPlayerId.isNotEmpty &&
        remotePlayerId.isNotEmpty &&
        localPlayerId != remotePlayerId) {
      throw StateError(backupPlayerMismatchErrorCode);
    }
    if (_backupOwnerConflictsWithConnectedAccount(remote)) {
      throw StateError(backupOwnerMismatchErrorCode);
    }
    if (!state.isSupportMode) {
      return;
    }
    final connected = _loadCachedDriveConnectionInfo();
    final expected = _expectedSharedChildDriveConnection(remote);
    if (connected != null &&
        expected != null &&
        !connected.isEmpty &&
        !expected.isEmpty &&
        !_sameDriveAccount(expected, connected)) {
      throw StateError(parentDriveMismatchErrorCode);
    }
  }

  bool _canAdoptRemoteIdentityForRestore() {
    final state = _familyService.loadState();
    if (state.isSupportMode || _activeCoachPlayerId.isNotEmpty) {
      return false;
    }
    final saved = _loadSavedDriveConnectionInfoForCurrentRole();
    if (saved != null && !saved.isEmpty) {
      return false;
    }
    if (_trainingBox.values.any((entry) => entry.deletedAt == null)) {
      return false;
    }
    final local = _buildBackup(
      updatedByRole: state.currentRole,
      familyLayerOnly: false,
    );
    return !_hasCoreBackupData(local);
  }

  DriveConnectionInfo? _expectedSharedChildDriveConnection(
    Map<String, dynamic>? remote,
  ) {
    if (remote != null) {
      final remoteConnection = _extractSharedChildDriveConnection(remote);
      if (remoteConnection != null && !remoteConnection.isEmpty) {
        return remoteConnection;
      }
    }
    return _loadSharedChildDriveConnectionInfo();
  }

  void _validateFamilyLinkForCurrentSession(
    FamilyDriveLinkRecord link,
    FamilyAccessState state,
  ) {
    if (link.isRevoked ||
        link.coreBackupFileId.trim().isEmpty ||
        link.contributionFileId.trim().isEmpty) {
      throw StateError(familyLinkPermissionRevokedErrorCode);
    }
    final localFamilyId = state.familyId.trim();
    if (localFamilyId.isNotEmpty &&
        link.familyId.trim().isNotEmpty &&
        localFamilyId != link.familyId.trim()) {
      throw StateError(parentFamilyMismatchErrorCode);
    }
    final localDatasetId =
        (_optionBox.get(_localDatasetIdKey) as String?)?.trim() ?? '';
    if (localDatasetId.isNotEmpty &&
        link.datasetId.trim().isNotEmpty &&
        localDatasetId != link.datasetId.trim()) {
      throw StateError(backupDatasetMismatchErrorCode);
    }
    final localPlayerId = _localPlayerIdForComparison();
    if (localPlayerId.isNotEmpty &&
        link.playerId.trim().isNotEmpty &&
        localPlayerId != link.playerId.trim()) {
      throw StateError(backupPlayerMismatchErrorCode);
    }
    final connected =
        _loadCachedDriveConnectionInfo() ?? _loadRecentDriveConnection();
    if (connected == null || connected.isEmpty) {
      throw StateError(driveAccountBindingRequiredErrorCode);
    }
    final expectedSubject = state.isChildMode
        ? link.childSubjectId.trim()
        : link.parentSubjectId.trim();
    if (expectedSubject.isNotEmpty &&
        connected.subjectId.trim() != expectedSubject) {
      throw StateError(familyLinkAccountMismatchErrorCode);
    }
  }

  void _validateLinkedCorePayload({
    required FamilyDriveLinkRecord link,
    required Map<String, dynamic> remote,
  }) {
    _validateLinkedFamilyDatasetPlayer(link: link, remote: remote);
    if (remote[_backupFormatKey] ==
        BackupRestorePlanner.contributionFormatValue) {
      throw StateError(invalidBackupPayloadErrorCode);
    }
  }

  void _validateLinkedContributionPayload({
    required FamilyDriveLinkRecord link,
    required Map<String, dynamic> remote,
  }) {
    _validateLinkedFamilyDatasetPlayer(link: link, remote: remote);
    if (remote[_backupFormatKey] !=
        BackupRestorePlanner.contributionFormatValue) {
      throw StateError(invalidBackupPayloadErrorCode);
    }
  }

  void _validateLinkedFamilyDatasetPlayer({
    required FamilyDriveLinkRecord link,
    required Map<String, dynamic> remote,
  }) {
    final remoteFamilyId = _extractFamilyId(remote);
    if (remoteFamilyId.isNotEmpty &&
        link.familyId.trim().isNotEmpty &&
        remoteFamilyId != link.familyId.trim()) {
      throw StateError(parentFamilyMismatchErrorCode);
    }
    final remoteDatasetId = _extractSafetyManifestDatasetId(remote) ?? '';
    if (remoteDatasetId.isNotEmpty &&
        link.datasetId.trim().isNotEmpty &&
        remoteDatasetId != link.datasetId.trim()) {
      throw StateError(backupDatasetMismatchErrorCode);
    }
    final remotePlayerId = _extractSafetyManifestPlayerId(remote) ?? '';
    if (remotePlayerId.isNotEmpty &&
        link.playerId.trim().isNotEmpty &&
        remotePlayerId != link.playerId.trim()) {
      throw StateError(backupPlayerMismatchErrorCode);
    }
  }

  String _extractFamilyId(Map<String, dynamic> backup) {
    final familyRaw = backup[_familyMetadataKey];
    if (familyRaw is Map) {
      final value = familyRaw['familyId']?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    final options = _copyStringOptions(backup);
    return options[FamilyAccessService.familyIdKey]?.toString().trim() ?? '';
  }

  String _localPlayerIdForComparison() {
    final coachPlayerId = _activeCoachPlayerId;
    if (coachPlayerId.isNotEmpty) return coachPlayerId;
    return (_optionBox.get(_localPlayerIdKey) as String?)?.trim() ?? '';
  }

  String _extractSharedChildDriveEmail(Map<String, dynamic> backup) {
    final options = _copyStringOptions(backup);
    return options[sharedChildDriveEmailKey]?.toString().trim() ?? '';
  }

  String _extractSharedChildDriveLabel(Map<String, dynamic> backup) {
    final options = _copyStringOptions(backup);
    return options[sharedChildDriveLabelKey]?.toString().trim() ?? '';
  }

  String _extractSharedChildDriveSubjectId(Map<String, dynamic> backup) {
    final options = _copyStringOptions(backup);
    return options[sharedChildDriveSubjectLocalKey]?.toString().trim() ?? '';
  }

  DriveConnectionInfo? _extractSharedChildDriveConnection(
    Map<String, dynamic> backup,
  ) {
    return _buildDriveConnectionInfoFromLabelEmail(
      label: _extractSharedChildDriveLabel(backup),
      email: _extractSharedChildDriveEmail(backup),
      subjectId: _extractSharedChildDriveSubjectId(backup),
    );
  }

  String _extractChildName(Map<String, dynamic> backup) {
    final familyRaw = backup[_familyMetadataKey];
    if (familyRaw is Map) {
      return familyRaw['childName']?.toString().trim() ?? '';
    }
    return '';
  }

  String _normalizedEmail(String? raw) {
    return raw?.trim().toLowerCase() ?? '';
  }

  DateTime? _getLastFamilyRemoteSnapshot() =>
      _getDateTimeOption(_lastFamilyRemoteSnapshotAtKey) ??
      _getDateTimeOption(_lastFamilySyncPullAtKey);

  Future<void> _recordSyncSuccess({
    required FamilyRole role,
    required DateTime syncedAt,
  }) async {
    await _familyService.recordSharedBackupSync(role: role, syncedAt: syncedAt);
    if (FamilyAccessService.isSupportRole(role)) {
      await _recordFamilySyncPush(syncedAt);
      await _setParentSharedDataDirty(false);
      return;
    }
    await _setLastRecordBackup(syncedAt);
  }

  bool _shouldRefreshParentSharedData({required DateTime? remoteModifiedAt}) {
    if (!_familyService.loadState().isSupportMode) {
      return false;
    }
    if (hasPendingParentSharedChanges()) {
      return false;
    }
    if (remoteModifiedAt == null) {
      return _getLastFamilyRemoteSnapshot() == null;
    }
    final lastPushAt = getLastFamilySyncPush();
    final lastPullAt = _getLastFamilyRemoteSnapshot();
    final knownRemoteAt = switch ((lastPushAt, lastPullAt)) {
      (final DateTime push, final DateTime pull) =>
        push.isAfter(pull) ? push : pull,
      (final DateTime push, null) => push,
      (null, final DateTime pull) => pull,
      _ => null,
    };
    if (knownRemoteAt == null) {
      return true;
    }
    return remoteModifiedAt.isAfter(knownRemoteAt);
  }

  bool _shouldRefreshChildSharedLayer({required DateTime? remoteModifiedAt}) {
    if (_familyService.loadState().isSupportMode) {
      return false;
    }
    if (remoteModifiedAt == null) {
      return _getLastFamilyRemoteSnapshot() == null;
    }
    final knownRemoteAt = _getLastFamilyRemoteSnapshot();
    if (knownRemoteAt == null) {
      return true;
    }
    return remoteModifiedAt.isAfter(knownRemoteAt);
  }

  bool _shouldRefreshLinkedContribution({
    required FamilyDriveLinkRecord link,
    required DateTime? remoteModifiedAt,
  }) {
    if (_familyService.loadState().isSupportMode) {
      return false;
    }
    if (remoteModifiedAt == null) {
      return link.lastContributionModifiedAt == null;
    }
    final known = link.lastContributionModifiedAt;
    return known == null || remoteModifiedAt.isAfter(known);
  }

  DateTime? _maxDateTime(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  Future<FamilyDriveFileRef> _linkedFileMetadata(
    drive.DriveApi driveApi,
    String fileId,
    FamilyDriveFileKind kind,
  ) async {
    try {
      final file = await driveApi.files.get(
        fileId,
        $fields: 'id,name,resourceKey,modifiedTime,capabilities,trashed',
      ) as drive.File;
      if (file.trashed == true) {
        throw StateError(familyLinkPermissionRevokedErrorCode);
      }
      return FamilyDriveFileRef(
        id: file.id ?? fileId,
        name: file.name ?? '',
        resourceKey: file.resourceKey ?? '',
        kind: kind,
        modifiedAt: file.modifiedTime,
        canRead: true,
        canWrite: file.capabilities?.canEdit == true,
      );
    } catch (error) {
      if (error is StateError &&
          error.message == familyLinkPermissionRevokedErrorCode) {
        rethrow;
      }
      if (_isAuthError(error) || _isNotFoundOrPermissionError(error)) {
        throw StateError(familyLinkPermissionRevokedErrorCode);
      }
      rethrow;
    }
  }

  @visibleForTesting
  bool shouldRefreshParentSharedDataForTesting({
    required DateTime? remoteModifiedAt,
  }) {
    return _shouldRefreshParentSharedData(remoteModifiedAt: remoteModifiedAt);
  }

  @visibleForTesting
  Future<FamilySharedSyncResult> restoreSharedOptionsFromMapForTesting(
    Map<String, dynamic> data, {
    DateTime? remoteModifiedAt,
  }) async {
    final beforeFeedback = _loadParentFeedbackFingerprints();
    final beforeRewards = _loadRewardNames();
    await _restoreSharedOptionsFromMap(_validatedBackupData(data));
    await _recordFamilySyncPull(
      DateTime.now(),
      remoteModifiedAt: remoteModifiedAt ?? DateTime.now(),
    );
    final afterFeedback = _loadParentFeedbackFingerprints();
    final afterRewards = _loadRewardNames();
    return FamilySharedSyncResult(
      refreshed: true,
      role: _familyService.loadState().currentRole,
      newParentFeedbackCount: _countChangedFeedback(
        before: beforeFeedback,
        after: afterFeedback,
      ),
      rewardNamesChanged: !_sameStringMap(beforeRewards, afterRewards),
    );
  }

  Future<void> _rememberDriveConnection({
    required String emailKey,
    required String labelKey,
    required String subjectKey,
    bool allowReplace = false,
  }) async {
    final info = await getDriveConnectionInfo();
    if (info == null || info.isEmpty) {
      return;
    }
    final saved = _connectionInfoFromKeys(
      emailKey: emailKey,
      labelKey: labelKey,
      subjectKey: subjectKey,
    );
    if (!allowReplace) {
      if (saved == null || saved.isEmpty) {
        return;
      }
      if (!_sameDriveAccount(saved, info)) {
        return;
      }
    }
    await _optionBox.put(emailKey, info.email.trim());
    await _optionBox.put(labelKey, info.label.trim());
    await _optionBox.put(subjectKey, info.subjectId.trim());
  }

  DriveConnectionInfo? _connectionInfoFromKeys({
    required String emailKey,
    required String labelKey,
    required String subjectKey,
  }) {
    final email = (_optionBox.get(emailKey) as String?)?.trim() ?? '';
    final label = (_optionBox.get(labelKey) as String?)?.trim() ?? '';
    final subjectId = (_optionBox.get(subjectKey) as String?)?.trim() ?? '';
    if (email.isEmpty && label.isEmpty && subjectId.isEmpty) {
      return null;
    }
    return DriveConnectionInfo(
      email: email,
      displayName: label,
      subjectId: subjectId,
    );
  }

  Future<void> _rememberCoachDriveConnection({
    bool allowReplace = false,
  }) async {
    final info = await getDriveConnectionInfo();
    if (info == null || info.isEmpty) {
      return;
    }
    final roster = CoachRosterService(HiveOptionRepository(_optionBox));
    final saved = roster.activePlayerDriveConnection();
    if (!allowReplace) {
      if (saved == null || saved.isEmpty) {
        return;
      }
      if (!_sameDriveAccount(saved, info)) {
        return;
      }
    }
    await roster.updateActivePlayerDriveConnection(info);
  }

  Future<void> _signInForSavedDrive({
    required DriveConnectionInfo? expected,
    required Future<void> Function() rememberConnection,
    required String mismatchErrorCode,
  }) async {
    final current = await getDriveConnectionInfo();
    if (_matchesExpectedDriveAccount(expected: expected, current: current)) {
      await rememberConnection();
      return;
    }
    if (current != null && !current.isEmpty) {
      await signOut();
    }
    await signIn();
    final refreshed = await getDriveConnectionInfo();
    if (!_matchesExpectedDriveAccount(
      expected: expected,
      current: refreshed,
    )) {
      await signOut();
      throw StateError(mismatchErrorCode);
    }
    await rememberConnection();
  }

  bool _matchesExpectedDriveAccount({
    required DriveConnectionInfo? expected,
    required DriveConnectionInfo? current,
  }) {
    if (expected == null || expected.isEmpty) {
      return true;
    }
    if (current == null || current.isEmpty) {
      return false;
    }
    return _sameDriveAccount(expected, current);
  }

  Future<void> _rememberCurrentRoleDriveConnectionAfterRestore() async {
    await _syncConnectedDriveAccountCache();
    final role = _familyService.loadState().currentRole;
    if (role == FamilyRole.coach) {
      await _rememberCoachDriveConnection(allowReplace: true);
    } else if (FamilyAccessService.isSupportRole(role)) {
      await _rememberDriveConnection(
        emailKey: parentDriveEmailLocalKey,
        labelKey: parentDriveLabelLocalKey,
        subjectKey: parentDriveSubjectLocalKey,
        allowReplace: true,
      );
    } else {
      await _rememberDriveConnection(
        emailKey: recordDriveEmailLocalKey,
        labelKey: recordDriveLabelLocalKey,
        subjectKey: recordDriveSubjectLocalKey,
        allowReplace: true,
      );
    }
    await _syncSharedChildDriveMetadataIfNeeded();
  }

  Future<bool> _adoptConnectedPlayerBackup({
    required Map<String, dynamic>? remoteBackup,
  }) async {
    final current = _loadCachedDriveConnectionInfo();
    if (current == null || current.email.trim().isEmpty) {
      return false;
    }
    final bindingState = _playerDriveBindingState();
    if (bindingState == PlayerDriveBindingState.verified) {
      await rememberRecordDriveConnection();
      await _syncSharedChildDriveMetadataIfNeeded();
      return false;
    }
    if (bindingState == PlayerDriveBindingState.notApplicable ||
        bindingState == PlayerDriveBindingState.notConnected) {
      return false;
    }
    await _saveLocalPreRestore();
    if (remoteBackup == null) {
      await _restoreFromMap(
        _emptyConnectedPlayerBackup(current),
        mode: RestoreMode.exactReplace,
      );
      await _optionBox.delete(_remoteReceiptKeyForCurrentContext());
      await _rememberCurrentRoleDriveConnectionAfterRestore();
      return true;
    }
    _validateRestoreBinding(
      remoteBackup,
      allowIdentityAdoption: true,
    );
    await _restoreFromMap(remoteBackup, mode: RestoreMode.exactReplace);
    await _recordRemoteBackupReceipt(remoteBackup, modifiedAt: DateTime.now());
    await _rememberCurrentRoleDriveConnectionAfterRestore();
    return true;
  }

  Map<String, dynamic> _emptyConnectedPlayerBackup(
    DriveConnectionInfo current,
  ) {
    final email = current.email.trim();
    final label = current.label.trim();
    final subjectId = current.subjectId.trim();
    final datasetId = _createLocalIdValue('dataset');
    final options = <String, dynamic>{
      if (email.isNotEmpty) sharedChildDriveEmailKey: email,
      if (label.isNotEmpty) sharedChildDriveLabelKey: label,
      if (subjectId.isNotEmpty) sharedChildDriveSubjectLocalKey: subjectId,
    };
    final backup = <String, dynamic>{
      _backupFormatKey: _backupFormatValue,
      'version': _backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'entries': const <Map<String, dynamic>>[],
      'options': options,
      _optionRecordsKey: options.entries
          .map(
            (entry) => <String, dynamic>{
              'key': entry.key,
              'value': entry.value,
            },
          )
          .toList(growable: false),
      _assetRecordsKey: const <String, dynamic>{},
      _familyMetadataKey: FamilyAccessService.backupMetadataFromState(
        _familyService.loadState(),
        updatedByRole: FamilyRole.child,
        familyLayerOnly: false,
      ),
      _driveAccountMetadataKey: _driveConnectionMetadata(current),
    };
    backup[_backupSafetyManifestKey] = _buildSafetyManifest(
      backup,
      driveAccount: current,
      datasetIdOverride: datasetId,
    );
    return backup;
  }

  bool hasLocalPreRestoreBackup() {
    return _loadLocalRecoverySnapshotMaps().isNotEmpty ||
        _optionBox.get(_localPreRestoreKey) != null;
  }

  DateTime? getLocalPreRestoreTime() {
    final points = _loadLocalRecoverySnapshotMaps();
    if (points.isNotEmpty) {
      final value = points.first['createdAt'];
      if (value is String) {
        return DateTime.tryParse(value);
      }
    }
    final value = _optionBox.get(_localPreRestoreAtKey);
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  List<LocalBackupRecoveryPoint> getLocalRecoveryPoints() {
    return _loadLocalRecoverySnapshotMaps()
        .map((point) {
          final id = point['id']?.toString() ?? '';
          final createdAt = DateTime.tryParse(
            point['createdAt']?.toString() ?? '',
          );
          if (id.isEmpty || createdAt == null) return null;
          return LocalBackupRecoveryPoint(id: id, createdAt: createdAt);
        })
        .whereType<LocalBackupRecoveryPoint>()
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _loadLocalRecoverySnapshotMaps() {
    final raw = _optionBox.get(_localPreRestoreSnapshotsKey);
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map(
          (value) => value.map(
            (key, item) => MapEntry(key.toString(), item),
          ),
        )
        .where((value) => value['data'] is String)
        .toList(growable: true);
  }

  Future<void> restoreLocalPreBackup() async {
    final points = _loadLocalRecoverySnapshotMaps();
    final raw = points.isNotEmpty
        ? points.first['data']
        : _optionBox.get(_localPreRestoreKey);
    if (raw is! String) {
      throw StateError('No local backup available.');
    }
    await _saveLocalPreRestore();
    final data = _decodeBackupPayload(raw);
    await _restoreFromMap(data, mode: RestoreMode.exactReplace);
    if (_familyService.loadState().isSupportMode) {
      await _setParentSharedDataDirty(true);
    }
  }

  Future<void> restoreLocalRecoveryPoint(String id) async {
    final point = _loadLocalRecoverySnapshotMaps().firstWhere(
      (value) => value['id']?.toString() == id,
      orElse: () => <String, dynamic>{},
    );
    final raw = point['data'];
    if (raw is! String) {
      throw StateError('No local backup available.');
    }
    await _saveLocalPreRestore();
    await _restoreFromMap(
      _decodeBackupPayload(raw),
      mode: RestoreMode.exactReplace,
    );
    if (_familyService.loadState().isSupportMode) {
      await _setParentSharedDataDirty(true);
    }
  }

  DateTime? _getDateTimeOption(String key) {
    final value = _optionBox.get(key);
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Future<void> _setDateTimeOption(String key, DateTime value) async {
    await _optionBox.put(key, value.toIso8601String());
  }

  Future<void> _setLastRecordBackup(DateTime value) async {
    await _setDateTimeOption(_lastRecordBackupKey, value);
    await _setDateTimeOption(_lastBackupKey, value);
  }

  Future<void> _resetLocalBackupStatusForContextChange() async {
    await _optionBox.delete(_lastBackupKey);
    await _optionBox.delete(_lastRecordBackupKey);
    await _optionBox.delete(_previousBackupCreatedAtKey);
    await _optionBox.delete(_lastFamilySyncPushAtKey);
    await _optionBox.delete(_lastFamilySyncPullAtKey);
    await _optionBox.delete(_lastFamilyRemoteSnapshotAtKey);
    await _optionBox.delete(FamilyAccessService.lastSharedSyncAtKey);
    await _optionBox.delete(FamilyAccessService.lastSharedSyncRoleKey);
    await _setParentSharedDataDirty(false);
  }

  Future<void> _recordFamilySyncPush(DateTime value) async {
    await _setDateTimeOption(_lastFamilySyncPushAtKey, value);
    await _setDateTimeOption(_lastFamilyRemoteSnapshotAtKey, value);
  }

  Future<void> _recordFamilySyncPull(
    DateTime refreshedAt, {
    required DateTime remoteModifiedAt,
  }) async {
    await _setDateTimeOption(_lastFamilySyncPullAtKey, refreshedAt);
    await _setDateTimeOption(_lastFamilyRemoteSnapshotAtKey, remoteModifiedAt);
  }

  Future<void> _setParentSharedDataDirty(bool value) async {
    await _optionBox.put(_parentSharedDataDirtyKey, value);
  }

  Set<String> _trainingEntryIds() {
    return _trainingBox.values
        .where((entry) => entry.deletedAt == null)
        .map(ParentSharedFeedbackService.entryIdFor)
        .toSet();
  }

  Map<String, String> _loadParentFeedbackFingerprints() {
    final feedback = ParentSharedFeedbackService(
      HiveOptionRepository(_optionBox),
    ).loadAll();
    return feedback.map(
      (key, value) => MapEntry(
        key,
        '${value.message.trim()}\n${value.reaction.trim()}\n${value.updatedAt?.toIso8601String() ?? ''}',
      ),
    );
  }

  Map<String, String> _loadRewardNames() {
    final result = <String, String>{};
    for (final optionKey in PlayerLevelService.customRewardNamesOptionKeys) {
      final raw = _optionBox.get(_playerScopedLevelOptionKey(optionKey));
      if (raw is! Map) continue;
      raw.forEach((key, value) {
        final normalizedKey = key.toString().trim();
        final normalizedValue = value?.toString().trim() ?? '';
        if (normalizedKey.isNotEmpty && normalizedValue.isNotEmpty) {
          result['$optionKey:$normalizedKey'] = normalizedValue;
        }
      });
    }
    return result;
  }

  Map<String, String> _loadRewardClaimFingerprints() {
    final raw = _optionBox.get(
      _playerScopedLevelOptionKey(PlayerLevelService.rewardClaimMessagesKey),
    );
    if (raw is! List) {
      return <String, String>{};
    }
    final result = <String, String>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final id = item['id']?.toString().trim() ?? '';
      if (id.isEmpty) continue;
      result[id] =
          '${item['level'] ?? ''}\n${item['rewardName'] ?? ''}\n${item['claimedAt'] ?? ''}';
    }
    return result;
  }

  String _playerScopedLevelOptionKey(String key) {
    final playerId = _activeCoachPlayerId;
    return playerId.isEmpty
        ? key
        : CoachRosterService.scopedOptionKey(key, playerId);
  }

  int _countChangedFeedback({
    required Map<String, String> before,
    required Map<String, String> after,
  }) {
    return _countChangedStringMap(before: before, after: after);
  }

  int _countChangedStringMap({
    required Map<String, String> before,
    required Map<String, String> after,
  }) {
    var count = 0;
    after.forEach((key, value) {
      if (value.trim().isNotEmpty && before[key] != value) {
        count += 1;
      }
    });
    return count;
  }

  bool _sameStringMap(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  Future<void> _restoreSharedOptionsFromMap(Map<String, dynamic> data) async {
    final sharedOptions = _extractSharedOptions(data);
    for (final entry in sharedOptions.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value == null) {
        await _optionBox.delete(key);
      } else {
        await _optionBox.put(key, value);
      }
    }
    _notifyDataChanged();
  }

  void _notifyDataChanged() {
    if (!_dataChangeController.isClosed) {
      _dataChangeController.add(null);
    }
  }

  Map<String, dynamic> _extractSharedOptions(Map<String, dynamic> backup) {
    final version = (backup['version'] as num?)?.toInt() ?? 1;
    final shared = <String, dynamic>{};
    final options = _copyStringOptions(backup);
    final sharedKeys = _sharedBackupOptionKeysForCurrentRole();
    for (final key in sharedKeys) {
      if (options.containsKey(key)) {
        shared[key] = _fromBackupValue(options[key], version: version);
      }
    }
    for (final record in _extractOptionRecords(backup)) {
      final key = _fromBackupValue(record['key'], version: version);
      if (key is! String || !sharedKeys.contains(key)) {
        continue;
      }
      shared[key] = _fromBackupValue(record['value'], version: version);
    }
    return shared;
  }

  Set<String> _sharedBackupOptionKeysForCurrentRole() {
    final keys = FamilyAccessService.sharedBackupOptionKeys.toSet();
    final playerId = _activeCoachPlayerId;
    if (playerId.isEmpty) return keys;
    keys
      ..remove(FamilyAccessService.parentTrainingFeedbackKey)
      ..removeAll(PlayerLevelService.customRewardNamesOptionKeys)
      ..add(
        CoachRosterService.scopedOptionKey(
          FamilyAccessService.parentTrainingFeedbackKey,
          playerId,
        ),
      );
    for (final optionKey in PlayerLevelService.customRewardNamesOptionKeys) {
      keys.add(CoachRosterService.scopedOptionKey(optionKey, playerId));
    }
    return keys;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static const _unsupportedValue = Object();

  dynamic _toBackupValue(dynamic value) {
    if (value == null || value is String || value is bool || value is num) {
      return value;
    }
    if (value is DateTime) {
      return {
        _typedValueKey: 'datetime',
        _typedDataKey: value.toIso8601String(),
      };
    }
    if (value is Uint8List) {
      return {_typedValueKey: 'bytes', _typedDataKey: base64Encode(value)};
    }
    if (value is Set) {
      final result = <dynamic>[];
      for (final item in value) {
        final converted = _toBackupValue(item);
        if (converted == _unsupportedValue) {
          return _unsupportedValue;
        }
        result.add(converted);
      }
      return {_typedValueKey: 'set', _typedDataKey: result};
    }
    if (value is List) {
      final result = <dynamic>[];
      for (final item in value) {
        final converted = _toBackupValue(item);
        if (converted == _unsupportedValue) {
          return _unsupportedValue;
        }
        result.add(converted);
      }
      return result;
    }
    if (value is Map) {
      final canUsePlainMap = value.keys.every((key) => key is String) &&
          !(value[_typedValueKey] is String &&
              value.containsKey(_typedDataKey));
      final result = <String, dynamic>{};
      if (canUsePlainMap) {
        for (final entry in value.entries) {
          final key = entry.key as String;
          final converted = _toBackupValue(entry.value);
          if (converted == _unsupportedValue) {
            return _unsupportedValue;
          }
          result[key] = converted;
        }
        return result;
      }
      final typedEntries = <Map<String, dynamic>>[];
      for (final entry in value.entries) {
        final convertedKey = _toBackupValue(entry.key);
        final convertedValue = _toBackupValue(entry.value);
        if (convertedKey == _unsupportedValue ||
            convertedValue == _unsupportedValue) {
          return _unsupportedValue;
        }
        typedEntries.add(<String, dynamic>{
          'key': convertedKey,
          'value': convertedValue,
        });
      }
      return {_typedValueKey: 'map', _typedDataKey: typedEntries};
    }
    return _unsupportedValue;
  }

  dynamic _fromBackupValue(dynamic value, {required int version}) {
    if (value is Map) {
      if (version >= 2 &&
          value[_typedValueKey] is String &&
          value.containsKey(_typedDataKey)) {
        final type = value[_typedValueKey] as String;
        final data = value[_typedDataKey];
        switch (type) {
          case 'datetime':
            if (data is String) {
              return DateTime.tryParse(data) ?? data;
            }
            return data;
          case 'bytes':
            if (data is String) {
              try {
                return base64Decode(data);
              } catch (_) {
                return data;
              }
            }
            return data;
          case 'set':
            if (data is List) {
              return data
                  .map((item) => _fromBackupValue(item, version: version))
                  .toSet();
            }
            return <dynamic>{};
          case 'map':
            if (data is List) {
              final result = <dynamic, dynamic>{};
              for (final raw in data) {
                if (raw is! Map) continue;
                final key = _fromBackupValue(raw['key'], version: version);
                final restoredValue = _fromBackupValue(
                  raw['value'],
                  version: version,
                );
                result[key] = restoredValue;
              }
              return result;
            }
            return <dynamic, dynamic>{};
          default:
            return data;
        }
      }
      final mapped = <String, dynamic>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) continue;
        mapped[key] = _fromBackupValue(entry.value, version: version);
      }
      return mapped;
    }
    if (value is List) {
      return value
          .map((item) => _fromBackupValue(item, version: version))
          .toList(growable: true);
    }
    return value;
  }

  bool _isInsufficientScopeError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('insufficient authentication scopes') ||
        msg.contains('insufficientpermissions') ||
        msg.contains('insufficient permissions');
  }

  bool _isSignInRequiredError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('sign-in required') ||
        msg.contains('sign in required') ||
        msg.contains('firebase web auth unavailable');
  }

  bool _isAuthError(Object error) {
    final msg = error.toString().toLowerCase();
    return _isInsufficientScopeError(error) ||
        _isSignInRequiredError(error) ||
        msg.contains('invalid credentials') ||
        msg.contains('unauthenticated') ||
        msg.contains('request is missing required authentication credential');
  }

  bool _isNotFoundOrPermissionError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('404') ||
        msg.contains('not found') ||
        msg.contains('403') ||
        msg.contains('forbidden') ||
        msg.contains('permission') ||
        msg.contains('insufficient file permissions');
  }

  FamilyAccessService get _familyService {
    return FamilyAccessService(HiveOptionRepository(_optionBox));
  }

  FamilyDriveLinkStore get _familyLinkStore {
    return FamilyDriveLinkStore(HiveOptionRepository(_optionBox));
  }

  FamilyDriveLinkRecord? _activeFamilyDriveLink() {
    return _familyLinkStore.loadActiveRecord();
  }

  FamilyDriveLinkService _familyDriveLinkService() {
    return FamilyDriveLinkService(
      store: _familyLinkStore,
      gateway: GoogleDriveFamilyLinkGateway(
        driveApiLoader: _driveApi,
        accountLoader: _loadCurrentDriveConnectionForFamilyLink,
      ),
    );
  }

  Future<DriveConnectionInfo?>
      _loadCurrentDriveConnectionForFamilyLink() async {
    final cached =
        _loadCachedDriveConnectionInfo() ?? _loadRecentDriveConnection();
    if (cached != null && !cached.isEmpty) {
      return cached;
    }
    return _loadDriveConnectionInfo();
  }

  Future<String> _ensureFamilyIdForPairing() async {
    final existing =
        (_optionBox.get(FamilyAccessService.familyIdKey) as String?)?.trim() ??
            '';
    if (existing.isNotEmpty) return existing;
    final generated = _createLocalIdValue('family');
    await _optionBox.put(FamilyAccessService.familyIdKey, generated);
    return generated;
  }

  Future<void> _rememberFamilyDriveLinkIdentifiers(
    FamilyDriveLinkRecord record,
  ) async {
    if (record.familyId.trim().isNotEmpty) {
      await _optionBox.put(FamilyAccessService.familyIdKey, record.familyId);
    }
    if (record.datasetId.trim().isNotEmpty) {
      await _optionBox.put(_localDatasetIdKey, record.datasetId);
    }
    if (record.playerId.trim().isNotEmpty && _activeCoachPlayerId.isEmpty) {
      await _optionBox.put(_localPlayerIdKey, record.playerId);
    }
    if (record.parentDisplayName.trim().isNotEmpty) {
      await _optionBox.put(
        FamilyAccessService.parentNameKey,
        record.parentDisplayName.trim(),
      );
    }
  }

  Future<void> _rememberRecoveredFamilyDriveLinkIdentifiers(
    FamilyDriveLinkRecoveryResult result,
  ) async {
    final identityRecord = result.activeRecord ?? result.records.firstOrNull;
    if (identityRecord == null) return;
    if (identityRecord.familyId.trim().isNotEmpty) {
      await _optionBox.put(
        FamilyAccessService.familyIdKey,
        identityRecord.familyId.trim(),
      );
    }
    if (identityRecord.datasetId.trim().isNotEmpty) {
      await _optionBox.put(_localDatasetIdKey, identityRecord.datasetId.trim());
    }
    if (identityRecord.playerId.trim().isNotEmpty &&
        _activeCoachPlayerId.isEmpty) {
      await _optionBox.put(_localPlayerIdKey, identityRecord.playerId.trim());
    }
    final active = result.activeRecord;
    if (active != null && active.parentDisplayName.trim().isNotEmpty) {
      await _optionBox.put(
        FamilyAccessService.parentNameKey,
        active.parentDisplayName.trim(),
      );
    }
    await _syncSharedChildDriveMetadataIfNeeded();
  }

  Future<Map<String, dynamic>> _downloadBackupMap(
    drive.DriveApi driveApi,
    String fileId,
  ) async {
    final content = await _downloadFileContent(driveApi, fileId);
    return _decodeBackupPayload(content);
  }

  Future<Map<String, dynamic>> _downloadLinkedBackupMap(
    drive.DriveApi driveApi,
    FamilyDriveFileRef file,
  ) async {
    try {
      return await _downloadBackupMap(driveApi, file.id);
    } catch (error) {
      if (_isAuthError(error) || _isNotFoundOrPermissionError(error)) {
        throw StateError(familyLinkPermissionRevokedErrorCode);
      }
      rethrow;
    }
  }

  Future<drive.File> _updateLinkedJsonFile(
    drive.DriveApi driveApi, {
    required String fileId,
    required String fileName,
    required drive.Media uploadMedia,
  }) async {
    try {
      return await driveApi.files.update(
        drive.File(name: fileName),
        fileId,
        uploadMedia: uploadMedia,
        $fields: 'id,modifiedTime',
      );
    } catch (error) {
      if (_isAuthError(error) || _isNotFoundOrPermissionError(error)) {
        throw StateError(familyLinkPermissionRevokedErrorCode);
      }
      rethrow;
    }
  }

  Future<String> _downloadFileContent(
    drive.DriveApi driveApi,
    String fileId,
  ) async {
    final media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    return utf8.decoder.bind(media.stream).join();
  }

  Map<String, dynamic> _decodeBackupPayload(String content) {
    final dynamic data;
    try {
      data = jsonDecode(content);
    } on FormatException {
      throw StateError(invalidBackupPayloadErrorCode);
    }
    if (data is Map<String, dynamic>) {
      return _validatedBackupData(data);
    }
    if (data is Map) {
      return _validatedBackupData(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    throw StateError(invalidBackupPayloadErrorCode);
  }

  Map<String, dynamic> _validatedBackupData(Map<String, dynamic> data) {
    final rawFormat = data[_backupFormatKey];
    if (rawFormat != null && !_acceptedBackupFormatValues.contains(rawFormat)) {
      throw StateError(invalidBackupPayloadErrorCode);
    }
    final rawVersion = data['version'];
    final version = switch (rawVersion) {
      null => 1,
      num value => value.toInt(),
      _ => -1,
    };
    if (version < 1) {
      throw StateError(invalidBackupPayloadErrorCode);
    }
    if (version > _backupVersion) {
      throw StateError(unsupportedBackupVersionErrorCode);
    }
    if (data['entries'] case final entries? when entries is! List) {
      throw StateError(invalidBackupPayloadErrorCode);
    }
    if (data['options'] case final options? when options is! Map) {
      throw StateError(invalidBackupPayloadErrorCode);
    }
    if (data[_optionRecordsKey] case final records? when records is! List) {
      throw StateError(invalidBackupPayloadErrorCode);
    }
    if (data[_assetRecordsKey] case final assets? when assets is! Map) {
      throw StateError(invalidBackupPayloadErrorCode);
    }
    if (data[_familyMetadataKey] case final family? when family is! Map) {
      throw StateError(invalidBackupPayloadErrorCode);
    }
    if (data[_backupSafetyManifestKey] case final manifest?
        when manifest is! Map) {
      throw StateError(invalidBackupPayloadErrorCode);
    }
    final manifest = data[_backupSafetyManifestKey];
    if (manifest is Map) {
      final schemaVersion = (manifest['schemaVersion'] as num?)?.toInt() ?? 1;
      final hashAlgorithm = manifest['hashAlgorithm']?.toString() ?? '';
      if (schemaVersion >= 2 || hashAlgorithm == 'sha256') {
        final expected = manifest['contentHash']?.toString() ?? '';
        if (expected.length != 64 ||
            expected != _stableBackupContentHash(data)) {
          throw StateError(invalidBackupPayloadErrorCode);
        }
      }
    }
    return data;
  }

  void _validatePlayerSourceBackup(Map<String, dynamic> data) {
    if (data[_backupFormatKey] ==
        BackupRestorePlanner.contributionFormatValue) {
      throw StateError(invalidBackupPayloadErrorCode);
    }
  }

  Map<String, dynamic> _buildUploadPayload({
    required FamilyRole currentRole,
    required Map<String, dynamic>? remote,
  }) {
    if (FamilyAccessService.isSupportRole(currentRole)) {
      _validateParentRemoteBinding(remote);
    }
    final local = _buildBackup(
      updatedByRole: currentRole,
      familyLayerOnly: false,
    );
    if (!FamilyAccessService.isSupportRole(currentRole)) {
      return local;
    }
    if (remote == null) {
      throw StateError(
        'Parent mode needs an existing player backup before syncing family data.',
      );
    }
    return _mergeParentFamilyBackup(remote: remote, local: local);
  }

  void _throwIfUnsafeRemoteOverwrite({
    required Map<String, dynamic> local,
    required Map<String, dynamic>? remote,
  }) {
    if (remote == null) {
      return;
    }
    if (_backupOwnerConflictsWithConnectedAccount(remote)) {
      throw StateError(backupOwnerMismatchErrorCode);
    }
    final localDatasetId = _extractSafetyManifestDatasetId(local) ?? '';
    final remoteDatasetId = _extractSafetyManifestDatasetId(remote) ?? '';
    if (localDatasetId.isNotEmpty &&
        remoteDatasetId.isNotEmpty &&
        localDatasetId != remoteDatasetId) {
      throw StateError(backupDatasetMismatchErrorCode);
    }
    final localPlayerId = _extractSafetyManifestPlayerId(local) ?? '';
    final remotePlayerId = _extractSafetyManifestPlayerId(remote) ?? '';
    if (localPlayerId.isNotEmpty &&
        remotePlayerId.isNotEmpty &&
        localPlayerId != remotePlayerId) {
      throw StateError(backupPlayerMismatchErrorCode);
    }
    if (_wouldDropTooManyCoreRecords(local: local, remote: remote)) {
      throw StateError(remoteBackupOverwriteBlockedErrorCode);
    }
    if (!_hasCoreBackupData(local) && _hasCoreBackupData(remote)) {
      throw StateError(remoteBackupOverwriteBlockedErrorCode);
    }
    if (_hasMeaningfulBackupData(local)) {
      return;
    }
    if (!_hasMeaningfulBackupData(remote)) {
      return;
    }
    throw StateError(remoteBackupOverwriteBlockedErrorCode);
  }

  bool _wouldDropTooManyCoreRecords({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) {
    final localCoreRecords = _backupSafetyCounts(local).coreRecords;
    final remoteCoreRecords = _backupSafetyCounts(remote).coreRecords;
    if (remoteCoreRecords < 5) {
      return false;
    }
    return localCoreRecords * 3 < remoteCoreRecords;
  }

  bool _hasMeaningfulBackupData(Map<String, dynamic> backup) {
    final entries = backup['entries'];
    if (entries is List && entries.isNotEmpty) {
      return true;
    }
    final version = (backup['version'] as num?)?.toInt() ?? 1;
    for (final record in _extractOptionRecords(backup)) {
      final key = _fromBackupValue(record['key'], version: version);
      if (key is! String || !_isMeaningfulBackupOptionKey(key)) {
        continue;
      }
      final value = _fromBackupValue(record['value'], version: version);
      if (_hasMeaningfulBackupValue(value)) {
        return true;
      }
    }
    return false;
  }

  bool _hasCoreBackupData(Map<String, dynamic> backup) {
    final entries = backup['entries'];
    if (entries is List && entries.isNotEmpty) {
      return true;
    }
    final version = (backup['version'] as num?)?.toInt() ?? 1;
    for (final record in _extractOptionRecords(backup)) {
      final key = _fromBackupValue(record['key'], version: version);
      if (key is! String || !_isCoreRecordBackupOptionKey(key)) {
        continue;
      }
      final value = _fromBackupValue(record['value'], version: version);
      if (_hasMeaningfulBackupValue(value)) {
        return true;
      }
    }
    return false;
  }

  bool _isCoreRecordBackupOptionKey(String key) {
    if (_coreRecordBackupOptionKeys.contains(key)) {
      return true;
    }
    return _startsWithAny(key, _coreRecordBackupOptionKeyPrefixes);
  }

  bool _isMeaningfulBackupOptionKey(String key) {
    if (_nonMeaningfulBackupOptionKeys.contains(key)) {
      return false;
    }
    return !_startsWithAny(key, _nonMeaningfulBackupOptionKeyPrefixes);
  }

  bool _hasMeaningfulBackupValue(dynamic value) {
    if (value == null) {
      return false;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == '[]' || trimmed == '{}') {
        return false;
      }
      try {
        final decoded = jsonDecode(trimmed);
        return _hasMeaningfulBackupValue(decoded);
      } on FormatException {
        return true;
      }
    }
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is List || value is Set) {
      return (value as Iterable).any(_hasMeaningfulBackupValue);
    }
    if (value is Map) {
      return value.values.any(_hasMeaningfulBackupValue);
    }
    return true;
  }

  DriveConnectionInfo? _driveAccountInfoForBackup() {
    final info = _loadCachedDriveConnectionInfo() ??
        _loadSavedDriveConnectionInfoForCurrentRole();
    if (info == null || info.isEmpty) {
      return null;
    }
    return info;
  }

  Map<String, dynamic> _driveConnectionMetadata(
    DriveConnectionInfo info, {
    bool includeEmail = true,
  }) {
    return <String, dynamic>{
      if (includeEmail && info.email.trim().isNotEmpty)
        'email': info.email.trim(),
      if (info.label.trim().isNotEmpty) 'label': info.label.trim(),
      if (info.subjectId.trim().isNotEmpty) 'subjectId': info.subjectId.trim(),
    };
  }

  bool _backupOwnerConflictsWithConnectedAccount(
    Map<String, dynamic> backup,
  ) {
    final owner = _extractBackupDriveConnectionInfo(backup);
    final connected = _loadCachedDriveConnectionInfo();
    if (owner == null ||
        connected == null ||
        owner.isEmpty ||
        connected.isEmpty) {
      return false;
    }
    final ownerSubject = owner.subjectId.trim().toLowerCase();
    final connectedSubject = connected.subjectId.trim().toLowerCase();
    if (ownerSubject.isNotEmpty && connectedSubject.isNotEmpty) {
      return ownerSubject != connectedSubject;
    }
    final ownerEmail = _normalizedEmail(owner.email);
    final connectedEmail = _normalizedEmail(connected.email);
    if (ownerEmail.isNotEmpty &&
        connectedEmail.isNotEmpty &&
        ownerEmail == connectedEmail) {
      return false;
    }
    if (ownerSubject.isNotEmpty && connectedSubject.isNotEmpty) {
      return true;
    }
    return ownerEmail.isNotEmpty && connectedEmail.isNotEmpty;
  }

  DriveConnectionInfo? _extractBackupDriveConnectionInfo(
    Map<String, dynamic> backup,
  ) {
    final raw = backup[_driveAccountMetadataKey];
    if (raw is Map) {
      return _buildDriveConnectionInfoFromLabelEmail(
        label: raw['label']?.toString().trim() ?? '',
        email: raw['email']?.toString().trim() ?? '',
        subjectId: raw['subjectId']?.toString().trim() ?? '',
      );
    }
    final manifest = backup[_backupSafetyManifestKey];
    if (manifest is! Map) {
      return null;
    }
    return _buildDriveConnectionInfoFromLabelEmail(
      label: '',
      email: manifest['accountEmail']?.toString().trim() ?? '',
      subjectId: manifest['accountSubjectId']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> _buildSafetyManifest(
    Map<String, dynamic> backup, {
    required DriveConnectionInfo? driveAccount,
    String? datasetIdOverride,
    bool includeAccountEmail = true,
  }) {
    final counts = _backupSafetyCounts(backup);
    final datasetId = datasetIdOverride ?? _loadOrCreateLocalDatasetId();
    final deviceId = _loadOrCreateLocalDeviceId();
    final familyState = _familyService.loadState();
    final playerId = _activePlayerIdForMetadata;
    return <String, dynamic>{
      'schemaVersion': 2,
      'hashAlgorithm': 'sha256',
      'datasetId': datasetId,
      'deviceId': deviceId,
      if (playerId.trim().isNotEmpty) 'playerId': playerId.trim(),
      if (familyState.familyId.trim().isNotEmpty)
        'familyId': familyState.familyId.trim(),
      'createdAt': DateTime.now().toIso8601String(),
      if (includeAccountEmail &&
          driveAccount != null &&
          driveAccount.email.trim().isNotEmpty)
        'accountEmail': driveAccount.email.trim(),
      if (driveAccount != null && driveAccount.subjectId.trim().isNotEmpty)
        'accountSubjectId': driveAccount.subjectId.trim(),
      'recordCounts': counts.toMap(),
      'contentHash': _stableBackupContentHash(backup),
    };
  }

  _BackupSafetyCounts _backupSafetyCounts(Map<String, dynamic> backup) {
    final entries = backup['entries'];
    final trainingEntryCount = entries is List
        ? entries.where((entry) {
            if (entry is! Map) return false;
            return entry[BackupRestorePlanner.entryDeletedAtKey] == null;
          }).length
        : 0;
    var meaningfulOptionCount = 0;
    var coreRecordOptionCount = 0;
    final version = (backup['version'] as num?)?.toInt() ?? 1;
    for (final record in _extractOptionRecords(backup)) {
      final key = _fromBackupValue(record['key'], version: version);
      if (key is! String) {
        continue;
      }
      final value = _fromBackupValue(record['value'], version: version);
      if (_isMeaningfulBackupOptionKey(key) &&
          _hasMeaningfulBackupValue(value)) {
        meaningfulOptionCount += _meaningfulBackupValueCount(value);
      }
      if (_isCoreRecordBackupOptionKey(key) &&
          _hasMeaningfulBackupValue(value)) {
        coreRecordOptionCount += _meaningfulBackupValueCount(value);
      }
    }
    return _BackupSafetyCounts(
      trainingEntries: trainingEntryCount,
      meaningfulOptions: meaningfulOptionCount,
      coreRecordOptions: coreRecordOptionCount,
    );
  }

  int _meaningfulBackupValueCount(dynamic value) {
    if (!_hasMeaningfulBackupValue(value)) {
      return 0;
    }
    if (value is String) {
      try {
        return _meaningfulBackupValueCount(jsonDecode(value.trim()));
      } on FormatException {
        return 1;
      }
    }
    if (value is List || value is Set) {
      return (value as Iterable)
          .map(_meaningfulBackupValueCount)
          .fold<int>(0, (sum, count) => sum + count);
    }
    if (value is Map) {
      return value.values
          .map(_meaningfulBackupValueCount)
          .fold<int>(0, (sum, count) => sum + count);
    }
    return 1;
  }

  String _stableBackupContentHash(Map<String, dynamic> backup) {
    final canonical = jsonEncode(
      _canonicalJson(<String, dynamic>{
        'entries': backup['entries'] ?? const <dynamic>[],
        'optionRecords': _extractOptionRecords(backup),
        _familyMetadataKey: backup[_familyMetadataKey],
        _assetRecordsKey: backup[_assetRecordsKey],
      }),
    );
    return sha256.convert(utf8.encode(canonical)).toString();
  }

  dynamic _canonicalJson(dynamic value) {
    if (value is Map) {
      final result = <String, dynamic>{};
      final entries = value.entries
          .map(
            (entry) => MapEntry(entry.key.toString(), entry.value),
          )
          .toList(growable: false)
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in entries) {
        result[entry.key] = _canonicalJson(entry.value);
      }
      return result;
    }
    if (value is List) {
      return value.map(_canonicalJson).toList(growable: false);
    }
    return value;
  }

  String _loadOrCreateLocalDatasetId() {
    final existing = (_optionBox.get(_localDatasetIdKey) as String?)?.trim();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final generated = _createLocalIdValue('dataset');
    unawaited(_optionBox.put(_localDatasetIdKey, generated));
    return generated;
  }

  String _loadOrCreateLocalDeviceId() {
    final existing = (_optionBox.get(_localDeviceIdKey) as String?)?.trim();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final generated = _createLocalIdValue('device');
    unawaited(_optionBox.put(_localDeviceIdKey, generated));
    return generated;
  }

  String _loadOrCreateLocalPlayerId() {
    final existing = (_optionBox.get(_localPlayerIdKey) as String?)?.trim();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final generated = _createLocalIdValue('player');
    unawaited(_optionBox.put(_localPlayerIdKey, generated));
    return generated;
  }

  String _createLocalIdValue(String prefix) {
    final random = _randomHex(12);
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return '$prefix-$time-$random';
  }

  String _randomHex(int byteCount) {
    try {
      final secure = math.Random.secure();
      return List<int>.generate(byteCount, (_) => secure.nextInt(256))
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
    } catch (_) {
      final fallback = math.Random();
      return List<int>.generate(byteCount, (_) => fallback.nextInt(256))
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
    }
  }

  Future<void> _adoptDatasetIdFromSafetyManifest(
    Map<String, dynamic> backup,
  ) async {
    final raw = backup[_backupSafetyManifestKey];
    if (raw is! Map) {
      return;
    }
    final datasetId = raw['datasetId']?.toString().trim() ?? '';
    if (datasetId.isEmpty) {
      return;
    }
    await _optionBox.put(_localDatasetIdKey, datasetId);
    final playerId = _extractSafetyManifestPlayerId(backup) ?? '';
    if (playerId.isNotEmpty && _activeCoachPlayerId.isEmpty) {
      await _optionBox.put(_localPlayerIdKey, playerId);
    }
    final familyId = raw['familyId']?.toString().trim().isNotEmpty == true
        ? raw['familyId'].toString().trim()
        : _extractFamilyId(backup);
    if (familyId.isNotEmpty &&
        !_familyService.loadState().isSupportMode &&
        _activeCoachPlayerId.isEmpty) {
      await _optionBox.put(FamilyAccessService.familyIdKey, familyId);
    }
  }

  String? _extractSafetyManifestDatasetId(Map<String, dynamic> backup) {
    final raw = backup[_backupSafetyManifestKey];
    if (raw is! Map) {
      return null;
    }
    final datasetId = raw['datasetId']?.toString().trim() ?? '';
    return datasetId.isEmpty ? null : datasetId;
  }

  String? _extractSafetyManifestPlayerId(Map<String, dynamic> backup) {
    final raw = backup[_backupSafetyManifestKey];
    if (raw is Map) {
      final playerId = raw['playerId']?.toString().trim() ?? '';
      if (playerId.isNotEmpty) return playerId;
    }
    final familyRaw = backup[_familyMetadataKey];
    if (familyRaw is Map) {
      final playerId = familyRaw['playerId']?.toString().trim() ?? '';
      if (playerId.isNotEmpty) return playerId;
    }
    return null;
  }

  Map<String, dynamic> _mergeParentFamilyBackup({
    required Map<String, dynamic> remote,
    required Map<String, dynamic> local,
  }) {
    final remoteVersion = (remote['version'] as num?)?.toInt() ?? 1;
    final localVersion = (local['version'] as num?)?.toInt() ?? _backupVersion;
    final localOptions = _copyStringOptions(local);
    final sharedKeys = _sharedBackupOptionKeysForCurrentRole();
    final mergedOptions = _copyStringOptions(remote)
      ..removeWhere(
        (key, value) =>
            !_canRestoreOptionKey(key) ||
            _isFamilySharedLayerOptionKey(key, sharedKeys),
      );
    for (final key in sharedKeys) {
      if (localOptions.containsKey(key)) {
        mergedOptions[key] = localOptions[key];
      } else {
        mergedOptions.remove(key);
      }
    }
    final familyState = _familyService.loadState();
    final merged = <String, dynamic>{
      ...remote,
      'version': _backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'entries':
          (remote['entries'] as List?)?.toList(growable: true) ?? const [],
      'options': mergedOptions,
      _optionRecordsKey: _mergeOptionRecords(
        remote: remote,
        remoteVersion: remoteVersion,
        local: local,
        localVersion: localVersion,
        sharedKeys: sharedKeys,
      ),
      _familyMetadataKey: FamilyAccessService.backupMetadataFromState(
        familyState,
        updatedByRole: familyState.currentRole,
        familyLayerOnly: true,
      ),
    };
    merged[_backupSafetyManifestKey] = _buildSafetyManifest(
      merged,
      driveAccount: _driveAccountInfoForBackup(),
      datasetIdOverride: _extractSafetyManifestDatasetId(remote),
    );
    return merged;
  }

  Map<String, dynamic> _copyStringOptions(Map<String, dynamic> backup) {
    final raw = backup['options'];
    if (raw is! Map) return <String, dynamic>{};
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  List<Map<String, dynamic>> _mergeOptionRecords({
    required Map<String, dynamic> remote,
    required int remoteVersion,
    required Map<String, dynamic> local,
    required int localVersion,
    required Set<String> sharedKeys,
  }) {
    final keptRemote = _extractOptionRecords(remote).where((record) {
      final key = _fromBackupValue(record['key'], version: remoteVersion);
      return key is String &&
          _canRestoreOptionKey(key) &&
          !_isFamilySharedLayerOptionKey(key, sharedKeys);
    });
    final localShared = _extractOptionRecords(local).where((record) {
      final key = _fromBackupValue(record['key'], version: localVersion);
      return key is String &&
          _canRestoreOptionKey(key) &&
          sharedKeys.contains(key);
    });
    return <Map<String, dynamic>>[...keptRemote, ...localShared];
  }

  bool _isFamilySharedLayerOptionKey(String key, Set<String> activeSharedKeys) {
    return activeSharedKeys.contains(key) ||
        FamilyAccessService.sharedBackupOptionKeys.contains(key) ||
        CoachRosterService.isScopedOptionKeyForBase(
          key,
          FamilyAccessService.parentTrainingFeedbackKey,
        ) ||
        PlayerLevelService.customRewardNamesOptionKeys.any(
          (optionKey) =>
              CoachRosterService.isScopedOptionKeyForBase(key, optionKey),
        );
  }

  List<Map<String, dynamic>> _extractOptionRecords(
    Map<String, dynamic> backup,
  ) {
    final raw = backup[_optionRecordsKey];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: true);
    }
    final options = backup['options'];
    if (options is! Map) {
      return <Map<String, dynamic>>[];
    }
    return options.entries
        .map(
          (entry) => <String, dynamic>{
            'key': _toBackupValue(entry.key.toString()),
            'value': entry.value,
          },
        )
        .toList(growable: true);
  }

  Map<String, dynamic> _entryToMap(
    TrainingEntry entry, {
    required Map<String, dynamic> assetRecords,
    required Map<String, String> assetIdBySourcePath,
  }) {
    final assetBaseId = 'training:${entry.createdAt.microsecondsSinceEpoch}';
    final encodedImagePaths = <String>[
      for (var i = 0; i < entry.imagePaths.length; i++)
        _replacePathWithAssetReferenceIfNeeded(
          assetId: '$assetBaseId:$i',
          sourcePath: entry.imagePaths[i],
          assetRecords: assetRecords,
          assetIdBySourcePath: assetIdBySourcePath,
        ),
    ];
    final encodedPrimaryImage = entry.imagePath.trim().isNotEmpty
        ? _replacePathWithAssetReferenceIfNeeded(
            assetId: '$assetBaseId:primary',
            sourcePath: entry.imagePath,
            assetRecords: assetRecords,
            assetIdBySourcePath: assetIdBySourcePath,
          )
        : (encodedImagePaths.isNotEmpty ? encodedImagePaths.first : '');
    final map = <String, dynamic>{
      'date': entry.date.toIso8601String(),
      'createdAt': entry.createdAt.toIso8601String(),
      BackupRestorePlanner.entryRecordIdKey: entry.effectiveRecordId,
      BackupRestorePlanner.entryUpdatedAtKey:
          entry.effectiveUpdatedAt.toIso8601String(),
      BackupRestorePlanner.entryRevisionKey: entry.revision,
      BackupRestorePlanner.entryOriginDeviceIdKey:
          entry.originDeviceId.trim().isNotEmpty
              ? entry.originDeviceId.trim()
              : _loadOrCreateLocalDeviceId(),
      if (entry.deletedAt != null)
        BackupRestorePlanner.entryDeletedAtKey:
            entry.deletedAt!.toIso8601String(),
      'sportId': entry.sportId,
      'durationMinutes': entry.durationMinutes,
      'intensity': entry.intensity,
      'type': entry.type,
      'mood': entry.mood,
      'injury': entry.injury,
      'notes': entry.notes,
      'location': entry.location,
      'program': entry.program,
      'drills': entry.drills,
      'club': entry.club,
      'injuryPart': entry.injuryPart,
      'painLevel': entry.painLevel,
      'rehab': entry.rehab,
      'goal': entry.goal,
      'feedback': entry.feedback,
      'heightCm': entry.heightCm,
      'weightKg': entry.weightKg,
      'imagePath': encodedPrimaryImage,
      'imagePaths': encodedImagePaths,
      'status': entry.status,
      'liftingByPart': entry.liftingByPart,
      'liftingMinutes': entry.liftingMinutes,
      'coachComment': entry.coachComment,
      'fortuneComment': entry.fortuneComment,
      'fortuneRecommendation': entry.fortuneRecommendation,
      'fortuneRecommendedProgram': entry.fortuneRecommendedProgram,
      'goalFocuses': entry.goalFocuses,
      'goodPoints': entry.goodPoints,
      'improvements': entry.improvements,
      'nextGoal': entry.nextGoal,
      'jumpRopeCount': entry.jumpRopeCount,
      'jumpRopeMinutes': entry.jumpRopeMinutes,
      'jumpRopeEnabled': entry.jumpRopeEnabled,
      'jumpRopeNote': entry.jumpRopeNote,
      'opponentTeam': entry.opponentTeam,
      'scoredGoals': entry.scoredGoals,
      'concededGoals': entry.concededGoals,
      'playerGoals': entry.playerGoals,
      'playerAssists': entry.playerAssists,
      'minutesPlayed': entry.minutesPlayed,
      'matchLocation': entry.matchLocation,
      'breakfastDone': entry.breakfastDone,
      'breakfastRiceBowls': entry.breakfastRiceBowls,
      'lunchDone': entry.lunchDone,
      'lunchRiceBowls': entry.lunchRiceBowls,
      'dinnerDone': entry.dinnerDone,
      'dinnerRiceBowls': entry.dinnerRiceBowls,
      'shotsOnTarget': entry.shotsOnTarget,
      'ballsWon': entry.ballsWon,
      'yellowCards': entry.yellowCards,
      'redCards': entry.redCards,
      'penaltyShootoutGoalsFor': entry.penaltyShootoutGoalsFor,
      'penaltyShootoutGoalsAgainst': entry.penaltyShootoutGoalsAgainst,
      'matchKind': entry.matchKind,
      'leagueTeamNames': entry.leagueTeamNames,
      'leagueResultMode': entry.leagueResultMode,
      'leaguePoints': entry.leaguePoints,
      'tournamentWins': entry.tournamentWins,
      'matchCompetitionName': entry.matchCompetitionName,
      'matchCompetitionId': entry.matchCompetitionId,
      'matchFixtureId': entry.matchFixtureId,
      'matchStage': entry.matchStage,
      'tournamentOutcome': entry.tournamentOutcome,
      'isLesson': entry.isLesson,
      'lessonDetail': entry.lessonDetail,
      'trainingProgramMinutes': entry.trainingProgramMinutes,
    };
    map[BackupRestorePlanner.entryPayloadHashKey] =
        BackupRestorePlanner.entryPayloadHash(map);
    return map;
  }

  TrainingEntry _entryFromMap(Map<String, dynamic> map) {
    DateTime parseDate() {
      final value = map['date'];
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime parseCreatedAt(DateTime fallback) {
      final value = map['createdAt'];
      if (value is String) {
        return DateTime.tryParse(value) ?? fallback;
      }
      return fallback;
    }

    DateTime? parseOptionalDate(String key) {
      final value = map[key];
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final date = parseDate();

    return TrainingEntry(
      date: date,
      sportId: map['sportId'] as String? ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      intensity: (map['intensity'] as num?)?.toInt() ?? 3,
      type: map['type'] as String? ?? '',
      mood: (map['mood'] as num?)?.toInt() ?? 3,
      injury: map['injury'] as bool? ?? false,
      notes: map['notes'] as String? ?? '',
      location: map['location'] as String? ?? '',
      program: map['program'] as String? ?? '',
      drills: map['drills'] as String? ?? '',
      club: map['club'] as String? ?? '',
      injuryPart: map['injuryPart'] as String? ?? '',
      painLevel: (map['painLevel'] as num?)?.toInt(),
      rehab: map['rehab'] as bool? ?? false,
      goal: map['goal'] as String? ?? '',
      feedback: map['feedback'] as String? ?? '',
      heightCm: (map['heightCm'] as num?)?.toDouble(),
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      imagePath: map['imagePath'] as String? ?? '',
      imagePaths:
          (map['imagePaths'] as List?)?.cast<String>() ?? const <String>[],
      status: map['status'] as String? ?? 'normal',
      liftingByPart: (map['liftingByPart'] as Map?)?.map(
            (key, value) =>
                MapEntry(key.toString(), (value is num) ? value.toInt() : 0),
          ) ??
          const {},
      liftingMinutes: (map['liftingMinutes'] as num?)?.toInt() ?? 0,
      coachComment: map['coachComment'] as String? ?? '',
      fortuneComment: map['fortuneComment'] as String? ?? '',
      fortuneRecommendation: map['fortuneRecommendation'] as String? ?? '',
      fortuneRecommendedProgram:
          map['fortuneRecommendedProgram'] as String? ?? '',
      goalFocuses:
          (map['goalFocuses'] as List?)?.map((e) => e.toString()).toList() ??
              const <String>[],
      goodPoints:
          (map['goodPoints'] as String?) ?? (map['feedback'] as String? ?? ''),
      improvements:
          (map['improvements'] as String?) ?? (map['notes'] as String? ?? ''),
      nextGoal: (map['nextGoal'] as String?) ?? (map['goal'] as String? ?? ''),
      createdAt: parseCreatedAt(date),
      jumpRopeCount: (map['jumpRopeCount'] as num?)?.toInt() ?? 0,
      jumpRopeMinutes: (map['jumpRopeMinutes'] as num?)?.toInt() ?? 0,
      jumpRopeEnabled: map['jumpRopeEnabled'] as bool? ?? false,
      jumpRopeNote: map['jumpRopeNote'] as String? ?? '',
      opponentTeam:
          map['opponentTeam'] as String? ?? (map['club'] as String? ?? ''),
      scoredGoals: (map['scoredGoals'] as num?)?.toInt(),
      concededGoals: (map['concededGoals'] as num?)?.toInt(),
      playerGoals: (map['playerGoals'] as num?)?.toInt(),
      playerAssists: (map['playerAssists'] as num?)?.toInt(),
      minutesPlayed: (map['minutesPlayed'] as num?)?.toInt(),
      matchLocation: map['matchLocation'] as String? ?? '',
      breakfastDone: map['breakfastDone'] as bool? ?? false,
      breakfastRiceBowls: (map['breakfastRiceBowls'] as num?)?.toInt() ?? 0,
      lunchDone: map['lunchDone'] as bool? ?? false,
      lunchRiceBowls: (map['lunchRiceBowls'] as num?)?.toInt() ?? 0,
      dinnerDone: map['dinnerDone'] as bool? ?? false,
      dinnerRiceBowls: (map['dinnerRiceBowls'] as num?)?.toInt() ?? 0,
      shotsOnTarget: (map['shotsOnTarget'] as num?)?.toInt(),
      ballsWon: (map['ballsWon'] as num?)?.toInt(),
      yellowCards: (map['yellowCards'] as num?)?.toInt(),
      redCards: (map['redCards'] as num?)?.toInt(),
      penaltyShootoutGoalsFor:
          (map['penaltyShootoutGoalsFor'] as num?)?.toInt(),
      penaltyShootoutGoalsAgainst:
          (map['penaltyShootoutGoalsAgainst'] as num?)?.toInt(),
      matchKind: map['matchKind'] as String? ?? 'friendly',
      leagueTeamNames: (map['leagueTeamNames'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      leagueResultMode: map['leagueResultMode'] as String? ?? 'points',
      leaguePoints: (map['leaguePoints'] as num?)?.toInt(),
      tournamentWins: (map['tournamentWins'] as num?)?.toInt(),
      matchCompetitionName: map['matchCompetitionName'] as String? ?? '',
      matchCompetitionId: map['matchCompetitionId'] as String? ?? '',
      matchFixtureId: map['matchFixtureId'] as String? ?? '',
      matchStage: map['matchStage'] as String? ?? '',
      tournamentOutcome: map['tournamentOutcome'] as String? ?? '',
      isLesson: map['isLesson'] as bool? ?? false,
      lessonDetail: map['lessonDetail'] as String? ?? '',
      recordId: map[BackupRestorePlanner.entryRecordIdKey] as String? ?? '',
      updatedAt: parseOptionalDate(BackupRestorePlanner.entryUpdatedAtKey),
      revision:
          (map[BackupRestorePlanner.entryRevisionKey] as num?)?.toInt() ?? 1,
      originDeviceId:
          map[BackupRestorePlanner.entryOriginDeviceIdKey] as String? ?? '',
      payloadHash:
          map[BackupRestorePlanner.entryPayloadHashKey] as String? ?? '',
      deletedAt: parseOptionalDate(BackupRestorePlanner.entryDeletedAtKey),
      trainingProgramMinutes: (map['trainingProgramMinutes'] as Map?)?.map(
            (key, value) =>
                MapEntry(key.toString(), (value is num) ? value.toInt() : 0),
          ) ??
          const <String, int>{},
    );
  }
}

class _BackupSafetyCounts {
  const _BackupSafetyCounts({
    required this.trainingEntries,
    required this.meaningfulOptions,
    required this.coreRecordOptions,
  });

  final int trainingEntries;
  final int meaningfulOptions;
  final int coreRecordOptions;

  int get coreRecords => trainingEntries + coreRecordOptions;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'trainingEntries': trainingEntries,
      'meaningfulOptions': meaningfulOptions,
      'coreRecordOptions': coreRecordOptions,
      'coreRecords': coreRecords,
    };
  }
}

class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(this._headers);

  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}

extension on List<drive.File>? {
  drive.File? get firstOrNull {
    final files = this;
    if (files == null || files.isEmpty) return null;
    return files.first;
  }
}
