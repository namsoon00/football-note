import 'dart:async';

import 'package:football_note/application/backup_restore_plan.dart';
import 'package:football_note/application/backup_service.dart';
import 'package:football_note/application/coach_roster_service.dart';
import 'package:football_note/application/drive_connection_info.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/tutorial_guide_service.dart';
import 'package:football_note/domain/repositories/backup_repository.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BackupSnapshotDescriptor _backupDescriptor({
  FamilyRole role = FamilyRole.child,
  int trainingEntries = 0,
  int options = 0,
  DateTime? createdAt,
  String accountEmail = 'player@example.com',
}) {
  return BackupSnapshotDescriptor(
    format: BackupRestorePlanner.backupFormatValue,
    version: 7,
    createdAt: createdAt ?? DateTime(2026, 3, 22, 10),
    role: role,
    familyId: 'family-1',
    playerId: 'player-1',
    datasetId: 'dataset-1',
    accountEmail: accountEmail,
    accountLabel: accountEmail,
    accountSubjectId: 'subject-1',
    contentHash: 'hash-1',
    integrityVerified: true,
    counts: BackupCategoryCounts(
      trainingEntries: trainingEntries,
      options: options,
    ),
  );
}

RestorePlan _restorePlan({
  FamilyRole sourceRole = FamilyRole.child,
  int addCount = 0,
  int updateCount = 0,
  int conflictCount = 0,
  int tombstoneCount = 0,
  int skipCount = 0,
}) {
  List<RestoreOperation> operations(
    RestoreOperationType type,
    int count,
  ) {
    return List<RestoreOperation>.generate(
      count,
      (index) => RestoreOperation(
        type: type,
        category: RestoreOperationCategory.training,
        recordId: '${type.name}-$index',
        label: '${type.name}-$index',
        reason: type.name,
      ),
    );
  }

  final operationList = <RestoreOperation>[
    ...operations(RestoreOperationType.add, addCount),
    ...operations(RestoreOperationType.update, updateCount),
    ...operations(RestoreOperationType.conflict, conflictCount),
    ...operations(RestoreOperationType.tombstone, tombstoneCount),
    ...operations(RestoreOperationType.skip, skipCount),
  ];
  return RestorePlan(
    source: _backupDescriptor(
      role: sourceRole,
      trainingEntries: addCount + updateCount + skipCount,
      options: 2,
      createdAt: DateTime(2026, 3, 23, 8),
    ),
    target: _backupDescriptor(trainingEntries: 1, options: 1),
    mode: RestoreMode.safeMerge,
    planHash: 'plan-hash',
    beforeSummary: const <String, int>{'trainingEntries': 1, 'options': 1},
    afterSummary: const <String, int>{'trainingEntries': 2, 'options': 2},
    warnings: const <String>[],
    operations: operationList,
  );
}

void main() {
  testWidgets('general settings can disable sound effects', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          localeService: localeService,
          settingsService: settingsService,
          optionRepository: optionRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('일반 설정'));
    await tester.pumpAndSettle();

    final soundEffectsTile = find.widgetWithText(SwitchListTile, '효과음');
    expect(soundEffectsTile, findsOneWidget);
    expect(tester.widget<SwitchListTile>(soundEffectsTile).value, isTrue);

    await tester.tap(
      find.descendant(of: soundEffectsTile, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();

    expect(settingsService.soundEffectsEnabled, isFalse);
    expect(
      optionRepository.getValue<bool>('sound_effects_enabled'),
      isFalse,
    );
  });

  testWidgets('tutorial replay clears every guide completion flag', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.setValue(
      TutorialGuideService.parentSeenKey,
      true,
    );
    for (final tabIndex in TutorialGuideService.guidedTabIndexes) {
      await optionRepository.setValue(
        TutorialGuideService.childSeenKey(tabIndex),
        true,
      );
    }
    final replayRequestBefore = TutorialGuideService.replayRequests.value;
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          localeService: localeService,
          settingsService: settingsService,
          optionRepository: optionRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('일반 설정'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('settings-replay-tutorial')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-replay-tutorial')),
    );
    await tester.pumpAndSettle();

    expect(
      optionRepository.getValue<bool>(TutorialGuideService.parentSeenKey),
      isFalse,
    );
    for (final tabIndex in TutorialGuideService.guidedTabIndexes) {
      expect(
        optionRepository.getValue<bool>(
          TutorialGuideService.childSeenKey(tabIndex),
        ),
        isFalse,
      );
    }
    expect(
      TutorialGuideService.replayRequests.value,
      replayRequestBefore + 1,
    );
    expect(find.text('튜토리얼을 다시 시작할 준비가 됐어요.'), findsOneWidget);
  });

  testWidgets('backup health details stay hidden until expanded', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final backupService = _FakeDriveBackupService(
      signedIn: true,
      connectionInfo: const DriveConnectionInfo(
        email: 'player@example.com',
        displayName: '민수',
        subjectId: 'subject-player',
      ),
      sharedChildDriveLabel: '',
      sharedChildDriveEmail: '',
      savedRecordDriveLabel: '민수 · player@example.com',
      savedRecordDriveEmail: 'player@example.com',
      lastBackupAt: DateTime(2026, 3, 22, 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          localeService: localeService,
          settingsService: settingsService,
          optionRepository: optionRepository,
          driveBackupService: backupService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('데이터 동기화 상태'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('데이터 동기화 상태'), findsOneWidget);
    expect(find.textContaining('백업된 데이터:'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('상세 보기'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('상세 보기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('백업된 데이터:'), findsOneWidget);
    expect(find.textContaining('파일 경로:'), findsNothing);
  });

  testWidgets('role and sync section can collapse together', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final backupService = _FakeDriveBackupService(
      signedIn: true,
      connectionInfo: const DriveConnectionInfo(
        email: 'player@example.com',
        displayName: '민수',
        subjectId: 'subject-player',
      ),
      sharedChildDriveLabel: '',
      sharedChildDriveEmail: '',
      savedRecordDriveLabel: '민수 · player@example.com',
      savedRecordDriveEmail: 'player@example.com',
      lastBackupAt: DateTime(2026, 3, 22, 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          localeService: localeService,
          settingsService: settingsService,
          optionRepository: optionRepository,
          driveBackupService: backupService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('사용 방식 및 동기화'), findsOneWidget);
    expect(find.text('데이터 동기화'), findsOneWidget);

    await tester.tap(find.text('사용 방식 및 동기화'));
    await tester.pumpAndSettle();

    expect(find.text('데이터 동기화'), findsNothing);
  });

  testWidgets('role and sync section stays compact without long helper copy', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final backupService = _FakeDriveBackupService(
      signedIn: true,
      connectionInfo: const DriveConnectionInfo(
        email: 'player@example.com',
        displayName: '민수',
        subjectId: 'subject-player',
      ),
      sharedChildDriveLabel: '',
      sharedChildDriveEmail: '',
      savedRecordDriveLabel: '민수 · player@example.com',
      savedRecordDriveEmail: 'player@example.com',
      lastBackupAt: DateTime(2026, 3, 22, 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          localeService: localeService,
          settingsService: settingsService,
          optionRepository: optionRepository,
          driveBackupService: backupService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ChoiceChip, '선수'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '데이터 백업하기'), findsOneWidget);
    expect(find.text('데이터 백업하기'), findsOneWidget);
    expect(find.text('최근 데이터 가져오기'), findsOneWidget);
    expect(
      find.text('이 기기가 직접 기록하는 선수용인지, 보호자가 확인하는 기기인지 먼저 고르세요.'),
      findsNothing,
    );
    expect(
      find.text('현재 기기 기록을 Google Drive 최신본으로 저장합니다. 새 기록을 보호할 때 먼저 사용하세요.'),
      findsNothing,
    );
    expect(find.text('백업, 자동 백업, 복원을 한 곳에서 관리합니다.'), findsNothing);
  });

  testWidgets('coach mode shows roster management controls', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.coach.name,
    );
    await optionRepository.setValue(
        CoachRosterService.activePlayerIdKey, 'minjun');
    await optionRepository.setValue(CoachRosterService.rosterPlayersKey, [
      <String, Object>{
        'id': 'minjun',
        'displayName': '민준',
        'driveEmail': 'minjun@example.com',
        'driveLabel': '민준 · minjun@example.com',
        'driveSubjectId': 'subject-minjun',
        'createdAt': '2026-06-20T09:00:00.000',
        'updatedAt': '2026-06-20T09:00:00.000',
      },
      <String, Object>{
        'id': 'jisoo',
        'displayName': '지수',
        'createdAt': '2026-06-20T09:00:00.000',
        'updatedAt': '2026-06-20T09:00:00.000',
      },
    ]);
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final backupService = _FakeDriveBackupService(
      signedIn: false,
      connectionInfo: null,
      sharedChildDriveLabel: '',
      sharedChildDriveEmail: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          localeService: localeService,
          settingsService: settingsService,
          optionRepository: optionRepository,
          driveBackupService: backupService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ChoiceChip, '코치'), findsOneWidget);
    expect(find.text('코치 선수 목록'), findsOneWidget);
    expect(find.text('민준'), findsOneWidget);
    expect(find.text('Drive: minjun@example.com'), findsOneWidget);
    expect(find.text('지수'), findsOneWidget);
    expect(find.byTooltip('선수 수정'), findsNWidgets(2));
    expect(find.byTooltip('선수 삭제'), findsNWidgets(2));
  });

  testWidgets('general settings hide the sport selector', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          localeService: localeService,
          settingsService: settingsService,
          optionRepository: optionRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('일반 설정'));
    await tester.pumpAndSettle();

    expect(find.text('종목'), findsNothing);
  });

  testWidgets(
    'Drive action buttons are hidden while account check is loading',
    (WidgetTester tester) async {
      final optionRepository = _MemoryOptionRepository();
      final localeService = LocaleService(optionRepository)..load();
      final settingsService = SettingsService(optionRepository)..load();
      final backupService = _FakeDriveBackupService(
        signedIn: false,
        connectionInfo: null,
        sharedChildDriveLabel: '',
        sharedChildDriveEmail: '',
        lastBackupAt: DateTime(2026, 3, 22, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(
            localeService: localeService,
            settingsService: settingsService,
            optionRepository: optionRepository,
            driveBackupService: backupService,
          ),
        ),
      );

      expect(find.text('확인 중'), findsWidgets);
      expect(
        find.widgetWithText(OutlinedButton, 'Google Drive 연결'),
        findsNothing,
      );
      expect(find.widgetWithText(OutlinedButton, '최근 데이터 가져오기'), findsNothing);

      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(OutlinedButton, 'Google Drive 연결'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'parent mode keeps player Drive connection and player restore in parent/player sharing section',
    (WidgetTester tester) async {
      final optionRepository = _MemoryOptionRepository();
      await optionRepository.setValue(
        FamilyAccessService.currentRoleLocalKey,
        FamilyRole.parent.name,
      );
      await optionRepository.setValue(FamilyAccessService.childNameKey, '민수');
      await optionRepository.setValue(FamilyAccessService.parentNameKey, '아빠');
      final localeService = LocaleService(optionRepository)..load();
      final settingsService = SettingsService(optionRepository)..load();
      final backupService = _FakeDriveBackupService(
        signedIn: true,
        connectionInfo: const DriveConnectionInfo(
          email: 'child@example.com',
          displayName: '민수',
          subjectId: 'subject-1',
        ),
        sharedChildDriveLabel: '민수 · child@example.com',
        sharedChildDriveEmail: 'child@example.com',
        lastFamilySyncPushAt: DateTime(2026, 3, 21, 9),
        lastFamilySyncPullAt: DateTime(2026, 3, 22, 8),
        localPreRestoreAt: DateTime(2026, 3, 22, 7),
        lastBackupAt: DateTime(2026, 3, 22, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(
            localeService: localeService,
            settingsService: settingsService,
            optionRepository: optionRepository,
            driveBackupService: backupService,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('백업 데이터'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('데이터 동기화'), findsOneWidget);
      expect(find.text('백업 데이터'), findsOneWidget);
      expect(find.text('현재 연결된 Drive 계정'), findsOneWidget);
      expect(find.text('Google Drive 연결 해제'), findsOneWidget);
      expect(backupService.refreshParentSharedDataIfNeededCalled, isTrue);
      expect(
        find.widgetWithText(OutlinedButton, '최근 데이터 가져오기'),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, '데이터 백업하기'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, '최근 가져오기 취소'), findsNothing);
      expect(find.text('최근 반영'), findsOneWidget);
      expect(find.text('최근 가져오기 확인'), findsOneWidget);
      expect(find.textContaining('파일 경로:'), findsNothing);
      expect(find.text('가족 공간 열기'), findsNothing);
      expect(find.text('Google Drive 백업'), findsNothing);
      expect(find.text('로그아웃'), findsNothing);
    },
  );

  testWidgets(
    'parent restore refreshes remote Drive status after latest import',
    (WidgetTester tester) async {
      final optionRepository = _MemoryOptionRepository();
      await optionRepository.setValue(
        FamilyAccessService.currentRoleLocalKey,
        FamilyRole.parent.name,
      );
      final localeService = LocaleService(optionRepository)..load();
      final settingsService = SettingsService(optionRepository)..load();
      final backupService = _FakeDriveBackupService(
        signedIn: true,
        connectionInfo: const DriveConnectionInfo(
          email: 'parent@example.com',
          displayName: '부모',
          subjectId: 'parent-1',
        ),
        sharedChildDriveLabel: '',
        sharedChildDriveEmail: '',
        hasRemotePlayerBackup: true,
        lastBackupAt: DateTime(2026, 3, 22, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(
            localeService: localeService,
            settingsService: settingsService,
            optionRepository: optionRepository,
            driveBackupService: backupService,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(OutlinedButton, '최근 데이터 가져오기'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      backupService.resetStatusCounters();
      await tester.tap(find.widgetWithText(OutlinedButton, '최근 데이터 가져오기'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Google Drive의 최신 선수 데이터를'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TextButton, '확인'));
      await tester.pumpAndSettle();
      expect(find.text('복원 재확인'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, '확인'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(backupService.restoreLatestCalled, isTrue);
      expect(backupService.hasRemotePlayerBackupChecks, greaterThan(0));
    },
  );

  testWidgets('enabling parent mode does not persist the current Drive account',
      (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.setValue(FamilyAccessService.childNameKey, '민수');
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final backupService = _FakeDriveBackupService(
      signedIn: true,
      connectionInfo: const DriveConnectionInfo(
        email: 'player@example.com',
        displayName: '민수',
        subjectId: 'subject-player',
      ),
      sharedChildDriveLabel: '',
      sharedChildDriveEmail: '',
      lastBackupAt: DateTime(2026, 3, 22, 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          localeService: localeService,
          settingsService: settingsService,
          optionRepository: optionRepository,
          driveBackupService: backupService,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('사용 방식'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '보호자'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('데이터 동기화'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(backupService.signOutCalled, isFalse);
    expect(backupService.refreshParentSharedDataIfNeededCalled, isTrue);
    expect(backupService.getSavedRecordDriveEmail(), isEmpty);
    expect(find.text('데이터 동기화'), findsOneWidget);
    expect(find.text('Google Drive 연결 해제'), findsOneWidget);
    expect(find.text('민수 · player@example.com'), findsWidgets);
    expect(find.text('아직 Google Drive 계정이 연결되지 않았어요.'), findsNothing);
  });

  testWidgets('player mode shows only current Drive account in sync card', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final backupService = _FakeDriveBackupService(
      signedIn: false,
      connectionInfo: null,
      sharedChildDriveLabel: '',
      sharedChildDriveEmail: '',
      savedRecordDriveLabel: '민수 · player@example.com',
      savedRecordDriveEmail: 'player@example.com',
      lastBackupAt: DateTime(2026, 3, 22, 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          localeService: localeService,
          settingsService: settingsService,
          optionRepository: optionRepository,
          driveBackupService: backupService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('현재 연결된 Drive 계정'), findsOneWidget);
    expect(find.text('아직 Google Drive 계정이 연결되지 않았어요.'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Google Drive 연결'),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, '최근 데이터 가져오기'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '데이터 백업하기'), findsNothing);
    expect(find.text('데이터 동기화 상태'), findsNothing);
    expect(find.text('선수 모드 백업 Drive'), findsNothing);
    expect(find.text('선수 모드 Drive 다시 연결'), findsNothing);
  });

  testWidgets('player mode shows latest import when Drive account is available',
      (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final backupService = _FakeDriveBackupService(
      signedIn: true,
      connectionInfo: const DriveConnectionInfo(
        email: 'player@example.com',
        displayName: '민수',
        subjectId: 'subject-player',
      ),
      sharedChildDriveLabel: '',
      sharedChildDriveEmail: '',
      savedRecordDriveLabel: '민수 · player@example.com',
      savedRecordDriveEmail: 'player@example.com',
      localPreRestoreAt: DateTime(2026, 3, 22, 7),
      lastBackupAt: DateTime(2026, 3, 22, 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          localeService: localeService,
          settingsService: settingsService,
          optionRepository: optionRepository,
          driveBackupService: backupService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, '최근 데이터 가져오기'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final latestRestoreButton = find.widgetWithText(
      OutlinedButton,
      '최근 데이터 가져오기',
    );
    final backupButton = find.widgetWithText(OutlinedButton, '데이터 백업하기');
    final remoteRestoreButton = find.widgetWithText(
      OutlinedButton,
      '이 계정 백업 가져오기',
    );
    final localRestoreButton = find.widgetWithText(
      OutlinedButton,
      '최근 가져오기 취소',
    );

    expect(latestRestoreButton, findsOneWidget);
    expect(backupButton, findsOneWidget);
    expect(remoteRestoreButton, findsNothing);
    expect(localRestoreButton, findsNothing);

    await tester.tap(latestRestoreButton);
    await tester.pumpAndSettle();
    expect(find.textContaining('Google Drive의 최신 데이터를'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '확인'));
    await tester.pumpAndSettle();
    expect(find.text('복원 재확인'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '확인'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(backupService.restoreLatestCalled, isTrue);
  });

  testWidgets('backup details dialog previews safe merge before restore',
      (WidgetTester tester) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final backupService = _FakeDriveBackupService(
      signedIn: true,
      connectionInfo: const DriveConnectionInfo(
        email: 'player@example.com',
        displayName: '민수',
        subjectId: 'subject-player',
      ),
      sharedChildDriveLabel: '',
      sharedChildDriveEmail: '',
      savedRecordDriveLabel: '민수 · player@example.com',
      savedRecordDriveEmail: 'player@example.com',
      lastBackupAt: DateTime(2026, 3, 22, 10),
      localDescriptor: _backupDescriptor(trainingEntries: 1, options: 1),
      previewPlan: _restorePlan(
        addCount: 2,
        updateCount: 1,
        conflictCount: 1,
        tombstoneCount: 1,
        skipCount: 3,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          localeService: localeService,
          settingsService: settingsService,
          optionRepository: optionRepository,
          driveBackupService: backupService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, '백업 상세 확인'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '백업 상세 확인'));
    await tester.pumpAndSettle();

    expect(find.text('백업 및 가져오기 상세'), findsOneWidget);
    expect(
      find.text('추가 2개, 업데이트 1개, 충돌 1개, 삭제 후보 1개, 건너뜀 3개'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, '없는 항목만 추가'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '안전 병합'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '안전 병합'));
    await tester.pumpAndSettle();

    expect(backupService.restoreLatestWithModeCalled, isTrue);
    expect(backupService.lastRestoreMode, RestoreMode.safeMerge);
  });

  testWidgets('parent backup details show contribution scope', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final backupService = _FakeDriveBackupService(
      signedIn: true,
      connectionInfo: const DriveConnectionInfo(
        email: 'parent@example.com',
        displayName: '부모',
        subjectId: 'subject-parent',
      ),
      sharedChildDriveLabel: '민수 · child@example.com',
      sharedChildDriveEmail: 'child@example.com',
      lastBackupAt: DateTime(2026, 3, 22, 10),
      localDescriptor: _backupDescriptor(
        role: FamilyRole.parent,
        trainingEntries: 4,
        options: 2,
        accountEmail: 'parent@example.com',
      ),
      previewPlan: _restorePlan(sourceRole: FamilyRole.parent, skipCount: 2),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          localeService: localeService,
          settingsService: settingsService,
          optionRepository: optionRepository,
          driveBackupService: backupService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, '백업 상세 확인'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, '기여 파일 백업'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '데이터 백업하기'), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, '백업 상세 확인'));
    await tester.pumpAndSettle();

    expect(find.text('보호자 기여 파일'), findsOneWidget);
    expect(
      find.text('보호자/코치 업로드는 선수 핵심 기록을 0개만 씁니다. 피드백과 선물 이름만 포함됩니다.'),
      findsOneWidget,
    );
    expect(
      find.text('추가 0개, 업데이트 0개, 충돌 0개, 삭제 후보 0개, 건너뜀 2개'),
      findsOneWidget,
    );
  });

  testWidgets(
    'legacy player account shows a verify-and-import action before backup',
    (WidgetTester tester) async {
      final optionRepository = _MemoryOptionRepository();
      final localeService = LocaleService(optionRepository)..load();
      final settingsService = SettingsService(optionRepository)..load();
      final backupService = _FakeDriveBackupService(
        signedIn: true,
        connectionInfo: const DriveConnectionInfo(
          email: 'player@example.com',
          displayName: '민수',
          subjectId: 'subject-player',
        ),
        sharedChildDriveLabel: '',
        sharedChildDriveEmail: '',
        savedRecordDriveLabel: '민수 · player@example.com',
        savedRecordDriveEmail: 'player@example.com',
        legacyPlayerDriveConnection: true,
        lastBackupAt: DateTime(2026, 3, 22, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(
            localeService: localeService,
            settingsService: settingsService,
            optionRepository: optionRepository,
            driveBackupService: backupService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final legacyImportButton = find.widgetWithText(
        OutlinedButton,
        '이 계정 확인 및 백업 가져오기',
      );
      expect(legacyImportButton, findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, '이 계정 백업 가져오기'),
        findsNothing,
      );
      expect(
        find.widgetWithText(OutlinedButton, '데이터 백업하기'),
        findsNothing,
      );

      await tester.ensureVisible(legacyImportButton);
      await tester.pumpAndSettle();
      await tester.tap(legacyImportButton);
      await tester.pumpAndSettle();
      expect(find.text('기존 계정 연결을 확인할까요?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, '확인'));
      await tester.pumpAndSettle();
      expect(find.text('복원 재확인'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, '확인'));
      await tester.pumpAndSettle();

      expect(backupService.restoreLatestCalled, isTrue);
    },
  );

  testWidgets(
    'player mode hides backup until remote backup is imported for unsaved Drive',
    (WidgetTester tester) async {
      final optionRepository = _MemoryOptionRepository();
      final localeService = LocaleService(optionRepository)..load();
      final settingsService = SettingsService(optionRepository)..load();
      final backupService = _FakeDriveBackupService(
        signedIn: true,
        connectionInfo: const DriveConnectionInfo(
          email: 'new-player@example.com',
          displayName: '민수',
          subjectId: 'subject-new',
        ),
        sharedChildDriveLabel: '',
        sharedChildDriveEmail: '',
        hasRemotePlayerBackup: true,
        lastBackupAt: DateTime(2026, 3, 22, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(
            localeService: localeService,
            settingsService: settingsService,
            optionRepository: optionRepository,
            driveBackupService: backupService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final accountImportButton = find.widgetWithText(
        OutlinedButton,
        '이 계정 백업 가져오기',
      );
      expect(accountImportButton, findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, '이 계정으로 새로 시작'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, '최근 데이터 가져오기'),
        findsNothing,
      );
      expect(
        find.widgetWithText(OutlinedButton, '데이터 백업하기'),
        findsNothing,
      );
      expect(find.text('매일 자동 백업'), findsNothing);
      expect(find.text('저장 시 자동 백업'), findsNothing);
      expect(
        find.textContaining('Google 계정이 바뀌었어요'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        accountImportButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(accountImportButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '이 계정 백업 가져오기'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(backupService.importChangedPlayerDriveBackupCalled, isTrue);
    },
  );

  testWidgets(
    'player mode blocks backup for unsaved Drive even without remote backup',
    (WidgetTester tester) async {
      final optionRepository = _MemoryOptionRepository();
      final localeService = LocaleService(optionRepository)..load();
      final settingsService = SettingsService(optionRepository)..load();
      final backupService = _FakeDriveBackupService(
        signedIn: true,
        connectionInfo: const DriveConnectionInfo(
          email: 'new-player@example.com',
          displayName: '민수',
          subjectId: 'subject-new',
        ),
        sharedChildDriveLabel: '',
        sharedChildDriveEmail: '',
        hasRemotePlayerBackup: false,
        lastBackupAt: DateTime(2026, 3, 22, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(
            localeService: localeService,
            settingsService: settingsService,
            optionRepository: optionRepository,
            driveBackupService: backupService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(OutlinedButton, '이 계정 백업 가져오기'),
        findsOneWidget,
      );
      final startEmptyButton = find.widgetWithText(
        OutlinedButton,
        '이 계정으로 새로 시작',
      );
      expect(startEmptyButton, findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, '최근 데이터 가져오기'),
        findsNothing,
      );
      expect(
        find.widgetWithText(OutlinedButton, '데이터 백업하기'),
        findsNothing,
      );
      expect(find.text('매일 자동 백업'), findsNothing);
      expect(find.text('저장 시 자동 백업'), findsNothing);
      expect(
        find.textContaining('Google 계정이 바뀌었어요'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        startEmptyButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(startEmptyButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '이 계정으로 새로 시작'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
          backupService.getSavedRecordDriveEmail(), 'new-player@example.com');
    },
  );

  testWidgets('player backup is hidden when Google account changes', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final backupService = _FakeDriveBackupService(
      signedIn: true,
      connectionInfo: const DriveConnectionInfo(
        email: 'new-player@example.com',
        displayName: '민수',
        subjectId: 'subject-new',
      ),
      sharedChildDriveLabel: '',
      sharedChildDriveEmail: '',
      savedRecordDriveLabel: '민수 · player@example.com',
      savedRecordDriveEmail: 'player@example.com',
      lastBackupAt: DateTime(2026, 3, 22, 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          localeService: localeService,
          settingsService: settingsService,
          optionRepository: optionRepository,
          driveBackupService: backupService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final remoteRestoreButton = find.widgetWithText(
      OutlinedButton,
      '이 계정 백업 가져오기',
    );
    await tester.scrollUntilVisible(
      remoteRestoreButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final previousButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.history_rounded),
    );
    expect(previousButton.onPressed, isNull);
    expect(remoteRestoreButton, findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, '데이터 백업하기'),
      findsNothing,
    );
    expect(find.text('매일 자동 백업'), findsNothing);
    expect(find.text('저장 시 자동 백업'), findsNothing);
    expect(
      find.text(
          'Google 계정이 바뀌었어요. 이 계정으로 백업하기 전에 이 기기에서 어떤 데이터로 시작할지 선택해야 해요.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'player mode hides saved player drive when current account matches it',
    (WidgetTester tester) async {
      final optionRepository = _MemoryOptionRepository();
      final localeService = LocaleService(optionRepository)..load();
      final settingsService = SettingsService(optionRepository)..load();
      final backupService = _FakeDriveBackupService(
        signedIn: true,
        connectionInfo: const DriveConnectionInfo(
          email: 'player@example.com',
          displayName: '민수',
          subjectId: 'subject-player',
        ),
        sharedChildDriveLabel: '',
        sharedChildDriveEmail: '',
        savedRecordDriveLabel: '민수 · player@example.com',
        savedRecordDriveEmail: 'player@example.com',
        lastBackupAt: DateTime(2026, 3, 22, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(
            localeService: localeService,
            settingsService: settingsService,
            optionRepository: optionRepository,
            driveBackupService: backupService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('현재 연결된 Drive 계정'), findsOneWidget);
      expect(find.text('민수 · player@example.com'), findsWidgets);
      expect(find.text('선수 모드 백업 Drive'), findsNothing);
      expect(find.text('선수 모드 Drive 다시 연결'), findsNothing);
    },
  );

  testWidgets('parent mode hides sync details while Drive is disconnected', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final backupService = _FakeDriveBackupService(
      signedIn: false,
      connectionInfo: null,
      sharedChildDriveLabel: '민수 · child@example.com',
      sharedChildDriveEmail: 'child@example.com',
      savedParentDriveLabel: '아빠 · parent@example.com',
      savedParentDriveEmail: 'parent@example.com',
      lastFamilySyncPushAt: DateTime(2026, 3, 21, 9),
      lastFamilySyncPullAt: DateTime(2026, 3, 22, 8),
      pendingParentSharedChanges: true,
      lastBackupAt: DateTime(2026, 3, 22, 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          localeService: localeService,
          settingsService: settingsService,
          optionRepository: optionRepository,
          driveBackupService: backupService,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('저장된 공유 역할 Drive'), findsNothing);
    expect(find.text('아빠 · parent@example.com'), findsNothing);
    expect(find.text('저장된 공유 역할 Drive 연결'), findsNothing);
    expect(find.text('현재 연결된 Drive 계정'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Google Drive 연결'),
      findsOneWidget,
    );
    expect(find.text('백업 데이터'), findsNothing);
    expect(find.text('민수 · child@example.com'), findsNothing);
    expect(find.text('최근 반영'), findsNothing);
    expect(find.text('최근 가져오기 확인'), findsNothing);
    expect(
      find.text('아직 Drive에 반영하지 못한 로컬 변경이 있어 자동 가져오기를 잠시 보류하고 있어요.'),
      findsNothing,
    );
  });

  testWidgets(
    'disabling parent mode does not persist the connected parent Drive before returning to player mode',
    (WidgetTester tester) async {
      final optionRepository = _MemoryOptionRepository();
      await optionRepository.setValue(
        FamilyAccessService.currentRoleLocalKey,
        FamilyRole.parent.name,
      );
      final localeService = LocaleService(optionRepository)..load();
      final settingsService = SettingsService(optionRepository)..load();
      final backupService = _FakeDriveBackupService(
        signedIn: true,
        connectionInfo: const DriveConnectionInfo(
          email: 'parent-mode@example.com',
          displayName: '부모',
          subjectId: 'subject-parent',
        ),
        sharedChildDriveLabel: '민수 · child@example.com',
        sharedChildDriveEmail: 'child@example.com',
        savedRecordDriveLabel: '민수 · record@example.com',
        savedRecordDriveEmail: 'record@example.com',
        lastBackupAt: DateTime(2026, 3, 22, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(
            localeService: localeService,
            settingsService: settingsService,
            optionRepository: optionRepository,
            driveBackupService: backupService,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('사용 방식'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, '선수'));
      await tester.pumpAndSettle();

      expect(backupService.signOutCalled, isTrue);
      expect(backupService.getSavedParentDriveEmail(), isEmpty);
      expect(find.text('선수 모드 백업 Drive'), findsNothing);
      expect(find.text('선수 모드 Drive 다시 연결'), findsNothing);
      expect(find.text('현재 연결된 Drive 계정'), findsOneWidget);
    },
  );

  testWidgets(
    'settings reflects signed-in Drive account immediately after sign in',
    (WidgetTester tester) async {
      final optionRepository = _MemoryOptionRepository();
      final localeService = LocaleService(optionRepository)..load();
      final settingsService = SettingsService(optionRepository)..load();
      final backupService = _FakeDriveBackupService(
        signedIn: false,
        connectionInfo: null,
        sharedChildDriveLabel: '',
        sharedChildDriveEmail: '',
        signInConnectionInfo: const DriveConnectionInfo(
          email: 'player@example.com',
          displayName: '민수',
          subjectId: 'subject-2',
        ),
        throwIsSignedInAfterSignInOnce: true,
        lastBackupAt: DateTime(2026, 3, 22, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(
            localeService: localeService,
            settingsService: settingsService,
            optionRepository: optionRepository,
            driveBackupService: backupService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.widgetWithText(OutlinedButton, 'Google Drive 연결'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Google Drive 연결'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Google Drive 연결 해제'), findsOneWidget);
      expect(find.text('민수 · player@example.com'), findsWidgets);
      expect(find.text('Google 로그인이 필요해요.'), findsNothing);
    },
  );

  testWidgets(
    'player sign in does not remember unsaved Drive before remote import',
    (WidgetTester tester) async {
      final optionRepository = _MemoryOptionRepository();
      final localeService = LocaleService(optionRepository)..load();
      final settingsService = SettingsService(optionRepository)..load();
      final backupService = _FakeDriveBackupService(
        signedIn: false,
        connectionInfo: null,
        sharedChildDriveLabel: '',
        sharedChildDriveEmail: '',
        hasRemotePlayerBackup: true,
        signInConnectionInfo: const DriveConnectionInfo(
          email: 'new-player@example.com',
          displayName: '민수',
          subjectId: 'subject-new',
        ),
        lastBackupAt: DateTime(2026, 3, 22, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(
            localeService: localeService,
            settingsService: settingsService,
            optionRepository: optionRepository,
            driveBackupService: backupService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Google Drive 연결'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(backupService.getSavedRecordDriveEmail(), isEmpty);
      expect(
        find.widgetWithText(OutlinedButton, '이 계정 백업 가져오기'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, '이 계정으로 새로 시작'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, '최근 데이터 가져오기'),
        findsNothing,
      );
      expect(
        find.widgetWithText(OutlinedButton, '데이터 백업하기'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'player sign in with changed Google account keeps latest import available',
    (WidgetTester tester) async {
      final optionRepository = _MemoryOptionRepository();
      final localeService = LocaleService(optionRepository)..load();
      final settingsService = SettingsService(optionRepository)..load();
      final backupService = _FakeDriveBackupService(
        signedIn: false,
        connectionInfo: null,
        sharedChildDriveLabel: '',
        sharedChildDriveEmail: '',
        savedRecordDriveLabel: '민수 · player@example.com',
        savedRecordDriveEmail: 'player@example.com',
        signInConnectionInfo: const DriveConnectionInfo(
          email: 'new-player@example.com',
          displayName: '민수',
          subjectId: 'subject-new',
        ),
        lastBackupAt: DateTime(2026, 3, 22, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(
            localeService: localeService,
            settingsService: settingsService,
            optionRepository: optionRepository,
            driveBackupService: backupService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.widgetWithText(OutlinedButton, 'Google Drive 연결'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Google Drive 연결'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(backupService.getSavedRecordDriveEmail(), 'player@example.com');
      expect(find.text('민수 · new-player@example.com'), findsWidgets);
      expect(
        find.widgetWithText(OutlinedButton, '이 계정 백업 가져오기'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, '데이터 백업하기'),
        findsNothing,
      );
      expect(find.text('매일 자동 백업'), findsNothing);
      expect(find.text('저장 시 자동 백업'), findsNothing);
      expect(
        find.textContaining('Google 계정이 바뀌었어요'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(OutlinedButton, '이 계정 백업 가져오기'));
      await tester.pumpAndSettle();
      expect(find.text('연결된 계정의 데이터를 사용할까요?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '이 계정 백업 가져오기'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(backupService.importChangedPlayerDriveBackupCalled, isTrue);
      expect(
          backupService.getSavedRecordDriveEmail(), 'new-player@example.com');
    },
  );

  testWidgets('settings reacts immediately to external Drive account changes', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final backupService = _FakeDriveBackupService(
      signedIn: false,
      connectionInfo: null,
      sharedChildDriveLabel: '',
      sharedChildDriveEmail: '',
      lastBackupAt: DateTime(2026, 3, 22, 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          localeService: localeService,
          settingsService: settingsService,
          optionRepository: optionRepository,
          driveBackupService: backupService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(OutlinedButton, 'Google Drive 연결'),
      findsOneWidget,
    );

    backupService.updateAccountState(
      signedIn: true,
      connectionInfo: const DriveConnectionInfo(
        email: 'runner@example.com',
        displayName: '러너',
        subjectId: 'runner-1',
      ),
    );
    backupService.emitDriveAccountStateChanged();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Google Drive 연결 해제'), findsOneWidget);
    expect(find.text('러너 · runner@example.com'), findsWidgets);

    backupService.updateAccountState(signedIn: false, connectionInfo: null);
    backupService.emitDriveAccountStateChanged();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(OutlinedButton, 'Google Drive 연결'),
      findsOneWidget,
    );
    expect(find.text('아직 Google Drive 계정이 연결되지 않았어요.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '최근 데이터 가져오기'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '데이터 백업하기'), findsNothing);
    expect(find.text('데이터 동기화 상태'), findsNothing);
  });

  testWidgets(
    'parent mode uses remote backup fallback when shared player drive metadata is missing',
    (WidgetTester tester) async {
      final optionRepository = _MemoryOptionRepository();
      await optionRepository.setValue(
        FamilyAccessService.currentRoleLocalKey,
        FamilyRole.parent.name,
      );
      final localeService = LocaleService(optionRepository)..load();
      final settingsService = SettingsService(optionRepository)..load();
      final backupService = _FakeDriveBackupService(
        signedIn: true,
        connectionInfo: const DriveConnectionInfo(
          email: 'parent@example.com',
          displayName: '부모',
          subjectId: 'parent-1',
        ),
        sharedChildDriveLabel: '',
        sharedChildDriveEmail: '',
        hasRemotePlayerBackup: true,
        lastBackupAt: DateTime(2026, 3, 22, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(
            localeService: localeService,
            settingsService: settingsService,
            optionRepository: optionRepository,
            driveBackupService: backupService,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('백업 데이터'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('백업 데이터'), findsOneWidget);
      expect(
        find.text('원격 백업은 확인됐어요. 같은 Google Drive 계정으로 연결해 주세요.'),
        findsOneWidget,
      );
      expect(find.text('아직 백업 원본 정보가 없어요. 먼저 한 번 백업해 주세요.'), findsNothing);
    },
  );
}

class _FakeDriveBackupService extends BackupService {
  bool _signedIn;
  DriveConnectionInfo? _connectionInfo;
  String _sharedChildDriveLabel;
  String _sharedChildDriveEmail;
  String _savedRecordDriveLabel;
  String _savedRecordDriveEmail;
  String _savedParentDriveLabel;
  String _savedParentDriveEmail;
  bool _legacyPlayerDriveConnection;
  final DateTime? _lastFamilySyncPushAt;
  final DateTime? _lastFamilySyncPullAt;
  final DateTime? _localPreRestoreAt;
  final DriveConnectionInfo? _remoteSharedChildConnectionInfo;
  final bool _hasRemotePlayerBackup;
  final BackupSnapshotDescriptor? _localDescriptor;
  final RestorePlan? _previewPlan;
  bool _pendingParentSharedChanges;
  final DriveConnectionInfo? signInConnectionInfo;
  bool throwNextIsSignedIn;
  final bool throwIsSignedInAfterSignInOnce;
  bool signOutCalled;
  bool restoreLatestCalled;
  bool restoreLatestWithModeCalled;
  RestoreMode? lastRestoreMode;
  bool importChangedPlayerDriveBackupCalled;
  bool restorePreviousBackupCalled;
  bool refreshParentSharedDataIfNeededCalled;
  int hasRemotePlayerBackupChecks;
  final StreamController<void> _driveAccountStateController =
      StreamController<void>.broadcast();

  _FakeDriveBackupService({
    required bool signedIn,
    required DriveConnectionInfo? connectionInfo,
    required String sharedChildDriveLabel,
    required String sharedChildDriveEmail,
    String savedRecordDriveLabel = '',
    String savedRecordDriveEmail = '',
    String savedParentDriveLabel = '',
    String savedParentDriveEmail = '',
    DateTime? lastFamilySyncPushAt,
    DateTime? lastFamilySyncPullAt,
    DateTime? localPreRestoreAt,
    DriveConnectionInfo? remoteSharedChildConnectionInfo,
    bool hasRemotePlayerBackup = false,
    BackupSnapshotDescriptor? localDescriptor,
    RestorePlan? previewPlan,
    bool pendingParentSharedChanges = false,
    bool legacyPlayerDriveConnection = false,
    this.signInConnectionInfo,
    this.throwIsSignedInAfterSignInOnce = false,
    DateTime? lastBackupAt,
  })  : _signedIn = signedIn,
        signOutCalled = false,
        restoreLatestCalled = false,
        restoreLatestWithModeCalled = false,
        lastRestoreMode = null,
        importChangedPlayerDriveBackupCalled = false,
        restorePreviousBackupCalled = false,
        refreshParentSharedDataIfNeededCalled = false,
        hasRemotePlayerBackupChecks = 0,
        throwNextIsSignedIn = false,
        _connectionInfo = connectionInfo,
        _sharedChildDriveLabel = sharedChildDriveLabel,
        _sharedChildDriveEmail = sharedChildDriveEmail,
        _savedRecordDriveLabel = savedRecordDriveLabel,
        _savedRecordDriveEmail = savedRecordDriveEmail,
        _savedParentDriveLabel = savedParentDriveLabel,
        _savedParentDriveEmail = savedParentDriveEmail,
        _lastFamilySyncPushAt = lastFamilySyncPushAt,
        _lastFamilySyncPullAt = lastFamilySyncPullAt,
        _localPreRestoreAt = localPreRestoreAt,
        _remoteSharedChildConnectionInfo = remoteSharedChildConnectionInfo,
        _hasRemotePlayerBackup = hasRemotePlayerBackup,
        _localDescriptor = localDescriptor,
        _previewPlan = previewPlan,
        _pendingParentSharedChanges = pendingParentSharedChanges,
        _legacyPlayerDriveConnection = legacyPlayerDriveConnection,
        super(_FakeBackupRepository(lastBackupAt: lastBackupAt));

  bool get signedIn => _signedIn;
  DriveConnectionInfo? get connectionInfo => _connectionInfo;

  void updateAccountState({
    required bool signedIn,
    required DriveConnectionInfo? connectionInfo,
  }) {
    _signedIn = signedIn;
    _connectionInfo = connectionInfo;
  }

  void emitDriveAccountStateChanged() {
    _driveAccountStateController.add(null);
  }

  void resetStatusCounters() {
    hasRemotePlayerBackupChecks = 0;
  }

  @override
  Future<DriveConnectionInfo?> getDriveConnectionInfo() async =>
      _connectionInfo;

  @override
  Stream<void> driveAccountStateChanges() =>
      _driveAccountStateController.stream;

  @override
  String getSharedChildDriveEmail() => _sharedChildDriveEmail;

  @override
  String getSharedChildDriveLabel() => _sharedChildDriveLabel;

  @override
  Future<DriveConnectionInfo?> getSharedChildDriveConnectionInfo({
    bool allowRemoteLookup = false,
  }) async {
    final localLabel = _sharedChildDriveLabel.trim();
    final localEmail = _sharedChildDriveEmail.trim();
    if (localLabel.isNotEmpty || localEmail.isNotEmpty) {
      var displayName = localLabel;
      if (localEmail.isNotEmpty) {
        final suffix = ' · $localEmail';
        if (localLabel.endsWith(suffix)) {
          displayName =
              localLabel.substring(0, localLabel.length - suffix.length).trim();
        } else if (localLabel.toLowerCase() == localEmail.toLowerCase()) {
          displayName = '';
        }
      }
      return DriveConnectionInfo(
        email: localEmail,
        displayName: displayName,
        subjectId: 'shared-child',
      );
    }
    if (allowRemoteLookup) {
      return _remoteSharedChildConnectionInfo;
    }
    return null;
  }

  @override
  Future<bool> hasRemotePlayerBackup() async {
    hasRemotePlayerBackupChecks += 1;
    return _hasRemotePlayerBackup;
  }

  @override
  bool hasChangedPlayerDriveConnection() {
    final savedEmail = _savedRecordDriveEmail.trim().toLowerCase();
    final currentEmail = _connectionInfo?.email.trim().toLowerCase() ?? '';
    return _signedIn &&
        savedEmail.isNotEmpty &&
        currentEmail.isNotEmpty &&
        savedEmail != currentEmail;
  }

  @override
  bool hasLegacyPlayerDriveConnection() {
    return _signedIn && _legacyPlayerDriveConnection;
  }

  @override
  bool needsPlayerDriveImportBeforeBackup() {
    if (!_signedIn || _connectionInfo == null) return false;
    return _legacyPlayerDriveConnection ||
        _savedRecordDriveLabel.trim().isEmpty ||
        hasChangedPlayerDriveConnection();
  }

  @override
  Future<bool> startChangedPlayerDriveWithEmptyData() async {
    _legacyPlayerDriveConnection = false;
    await rememberRecordDriveConnection();
    return true;
  }

  @override
  String getSavedRecordDriveEmail() => _savedRecordDriveEmail;

  @override
  String getSavedRecordDriveLabel() => _savedRecordDriveLabel;

  @override
  String getSavedPlayerDriveEmail() => _savedRecordDriveEmail;

  @override
  String getSavedPlayerDriveLabel() => _savedRecordDriveLabel;

  @override
  String getSavedParentDriveEmail() => _savedParentDriveEmail;

  @override
  String getSavedParentDriveLabel() => _savedParentDriveLabel;

  @override
  DateTime? getLastFamilySyncPush() => _lastFamilySyncPushAt;

  @override
  DateTime? getLastFamilySyncPull() => _lastFamilySyncPullAt;

  @override
  DateTime? getLastFamilyRefresh() => _lastFamilySyncPullAt;

  @override
  bool hasLocalPreRestoreBackup() => _localPreRestoreAt != null;

  @override
  DateTime? getLocalPreRestoreTime() => _localPreRestoreAt;

  @override
  bool hasPendingParentSharedChanges() => _pendingParentSharedChanges;

  @override
  Future<bool> isSignedIn() async {
    if (throwNextIsSignedIn) {
      throwNextIsSignedIn = false;
      throw StateError('temporary sign-in refresh failure');
    }
    return _signedIn;
  }

  @override
  Future<void> signIn() async {
    _signedIn = true;
    _connectionInfo ??= signInConnectionInfo;
    if (throwIsSignedInAfterSignInOnce) {
      throwNextIsSignedIn = true;
    }
  }

  @override
  Future<void> signInForSavedRecord() async {
    _signedIn = true;
    if (_savedRecordDriveEmail.isNotEmpty) {
      _connectionInfo = DriveConnectionInfo(
        email: _savedRecordDriveEmail,
        displayName: _savedRecordDriveLabel.split(' · ').first,
        subjectId: 'saved-record',
      );
    }
  }

  @override
  Future<void> rememberRecordDriveConnection() async {
    final info = _connectionInfo;
    if (info == null) return;
    _savedRecordDriveEmail = info.email;
    _savedRecordDriveLabel = info.label;
  }

  @override
  Future<void> signInForSavedPlayer() => signInForSavedRecord();

  @override
  Future<void> rememberPlayerDriveConnection() =>
      rememberRecordDriveConnection();

  @override
  Future<void> rememberParentDriveConnection() async {
    final info = _connectionInfo;
    if (info == null) return;
    _savedParentDriveEmail = info.email;
    _savedParentDriveLabel = info.label;
  }

  @override
  Future<void> rememberCurrentRoleDriveConnection() async {
    await rememberRecordDriveConnection();
    await rememberParentDriveConnection();
  }

  @override
  Future<void> markParentSharedDataDirty() async {
    _pendingParentSharedChanges = true;
  }

  @override
  Future<bool> backupIfSignedIn({bool requireAutoOnSave = false}) async {
    _pendingParentSharedChanges = false;
    return true;
  }

  @override
  Future<bool> refreshParentSharedDataIfNeeded() async {
    refreshParentSharedDataIfNeededCalled = true;
    return false;
  }

  @override
  Future<FamilySharedSyncResult> refreshFamilySharedDataIfNeeded() async {
    refreshParentSharedDataIfNeededCalled = true;
    return const FamilySharedSyncResult.none(role: FamilyRole.parent);
  }

  @override
  Future<void> restoreLatest() async {
    _legacyPlayerDriveConnection = false;
    restoreLatestCalled = true;
  }

  @override
  BackupSnapshotDescriptor? describeLocalBackup() => _localDescriptor;

  @override
  Future<RestorePlan?> previewLatestRestore({
    RestoreMode mode = RestoreMode.safeMerge,
  }) async {
    return _previewPlan;
  }

  @override
  Future<RestoreReceipt> restoreLatestWithMode(RestoreMode mode) async {
    _legacyPlayerDriveConnection = false;
    restoreLatestCalled = true;
    restoreLatestWithModeCalled = true;
    lastRestoreMode = mode;
    return const RestoreReceipt(
      planHash: 'plan-hash',
      applied: 1,
      updated: 0,
      skipped: 0,
      conflicts: 0,
      deleted: 0,
    );
  }

  @override
  Future<bool> importChangedPlayerDriveBackup() async {
    _legacyPlayerDriveConnection = false;
    importChangedPlayerDriveBackupCalled = true;
    await rememberRecordDriveConnection();
    return true;
  }

  @override
  Future<void> restorePreviousBackup() async {
    restorePreviousBackupCalled = true;
  }

  @override
  Future<void> signInForSavedParent() async {
    _signedIn = true;
    if (_savedParentDriveEmail.isNotEmpty) {
      _connectionInfo = DriveConnectionInfo(
        email: _savedParentDriveEmail,
        displayName: _savedParentDriveLabel.split(' · ').first,
        subjectId: 'saved-parent',
      );
    }
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    _signedIn = false;
    _connectionInfo = null;
    _sharedChildDriveLabel = '';
    _sharedChildDriveEmail = '';
  }
}

class _FakeBackupRepository implements BackupRepository {
  final DateTime? lastBackupAt;

  const _FakeBackupRepository({this.lastBackupAt});

  @override
  Future<void> autoBackupDaily() async {}

  @override
  Future<void> backup() async {}

  @override
  Future<bool> backupIfSignedIn({bool requireAutoOnSave = false}) async => true;

  @override
  DateTime? getLastBackup() => lastBackupAt;

  @override
  bool isAutoDailyEnabled() => true;

  @override
  bool isAutoOnSaveEnabled() => true;

  @override
  Future<void> restoreLatest() async {}

  @override
  Future<void> setAutoDailyEnabled(bool value) async {}

  @override
  Future<void> setAutoOnSaveEnabled(bool value) async {}
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List<String>) {
      return value;
    }
    return defaults;
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List<int>) {
      return value;
    }
    return defaults;
  }

  @override
  T? getValue<T>(String key) => _values[key] as T?;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }
}
