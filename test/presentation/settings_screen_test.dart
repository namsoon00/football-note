import 'dart:async';

import 'package:football_note/application/backup_service.dart';
import 'package:football_note/application/drive_connection_info.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/sport_state_controller.dart';
import 'package:football_note/domain/repositories/backup_repository.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/entities/sport_definition.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/settings_screen.dart';
import 'package:football_note/presentation/widgets/sport_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    expect(find.text('최근 데이터 가져오기'), findsNothing);
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

  testWidgets('player mode sport selector updates shared sport state', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final sportController = SportStateController(optionRepository);

    await tester.pumpWidget(
      SportScope(
        controller: sportController,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(
            localeService: localeService,
            settingsService: settingsService,
            optionRepository: optionRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('일반 설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownMenu<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('농구').last);
    await tester.pumpAndSettle();

    expect(sportController.currentSportId, SportCatalog.basketballId);
    expect(
      optionRepository.getValue<String>(SportCatalog.currentSportOptionKey),
      SportCatalog.basketballId,
    );
  });

  testWidgets('parent mode disables sport selector', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final sportController = SportStateController(optionRepository);

    await tester.pumpWidget(
      SportScope(
        controller: sportController,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(
            localeService: localeService,
            settingsService: settingsService,
            optionRepository: optionRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('일반 설정'));
    await tester.pumpAndSettle();

    final sportMenu = tester
        .widgetList<DropdownMenu<String>>(find.byType(DropdownMenu<String>))
        .firstWhere((menu) {
      final label = menu.label;
      return label is Text && label.data == '종목';
    });
    expect(sportMenu.enabled, isFalse);
    expect(
      find.text('보호자 모드에서는 종목, 기본값, 뉴스 필터를 수정할 수 없어요. 선수 모드에서 변경해 주세요.'),
      findsWidgets,
    );
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

  testWidgets('enabling parent mode keeps current player Drive connected', (
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
    expect(backupService.getSavedRecordDriveEmail(), 'player@example.com');
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

  testWidgets('player mode hides import action when Drive account is unchanged',
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
      find.widgetWithText(OutlinedButton, '데이터 백업하기'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final backupButton = find.widgetWithText(OutlinedButton, '데이터 백업하기');
    final remoteRestoreButton = find.widgetWithText(
      OutlinedButton,
      '이 계정 백업 가져오기',
    );
    final localRestoreButton = find.widgetWithText(
      OutlinedButton,
      '최근 가져오기 취소',
    );

    expect(backupButton, findsOneWidget);
    expect(remoteRestoreButton, findsNothing);
    expect(localRestoreButton, findsNothing);
  });

  testWidgets('player backup is disabled when Google account changes', (
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

    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, '데이터 백업하기'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final backupButtonFinder = find.widgetWithText(OutlinedButton, '데이터 백업하기');
    final remoteRestoreButton = find.widgetWithText(
      OutlinedButton,
      '이 계정 백업 가져오기',
    );
    final backupButton = tester.widget<OutlinedButton>(backupButtonFinder);
    final previousButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.history_rounded),
    );
    expect(backupButton.onPressed, isNull);
    expect(previousButton.onPressed, isNull);
    expect(remoteRestoreButton, findsOneWidget);
    expect(
      tester.getTopLeft(remoteRestoreButton).dy,
      lessThan(tester.getTopLeft(backupButtonFinder).dy),
    );
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
    'disabling parent mode stores parent mode drive separately before returning to player mode',
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
      expect(
        backupService.getSavedParentDriveEmail(),
        'parent-mode@example.com',
      );
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

      final backupButtonFinder = find.widgetWithText(
        OutlinedButton,
        '데이터 백업하기',
      );
      final backupButton = tester.widget<OutlinedButton>(backupButtonFinder);
      expect(backupButton.onPressed, isNull);

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
  final DateTime? _lastFamilySyncPushAt;
  final DateTime? _lastFamilySyncPullAt;
  final DateTime? _localPreRestoreAt;
  final DriveConnectionInfo? _remoteSharedChildConnectionInfo;
  final bool _hasRemotePlayerBackup;
  bool _pendingParentSharedChanges;
  final DriveConnectionInfo? signInConnectionInfo;
  bool throwNextIsSignedIn;
  final bool throwIsSignedInAfterSignInOnce;
  bool signOutCalled;
  bool restoreLatestCalled;
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
    bool pendingParentSharedChanges = false,
    this.signInConnectionInfo,
    this.throwIsSignedInAfterSignInOnce = false,
    DateTime? lastBackupAt,
  })  : _signedIn = signedIn,
        signOutCalled = false,
        restoreLatestCalled = false,
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
        _pendingParentSharedChanges = pendingParentSharedChanges,
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
  Future<bool> startChangedPlayerDriveWithEmptyData() async {
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
    restoreLatestCalled = true;
  }

  @override
  Future<bool> importChangedPlayerDriveBackup() async {
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
