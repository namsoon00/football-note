import 'dart:async';

import 'package:football_note/application/backup_service.dart';
import 'package:football_note/application/drive_connection_info.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/domain/repositories/backup_repository.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('backup health details stay hidden until expanded', (
    WidgetTester tester,
  ) async {
    final optionRepository = _MemoryOptionRepository();
    final localeService = LocaleService(optionRepository)..load();
    final settingsService = SettingsService(optionRepository)..load();
    final backupService = BackupService(
      _FakeBackupRepository(
        lastBackupAt: DateTime(2026, 3, 22, 10),
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

    expect(find.text('백업 상태'), findsOneWidget);
    expect(find.textContaining('마지막 클라우드 백업:'), findsNothing);

    await tester.tap(find.text('자세한 상태 보기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('마지막 클라우드 백업:'), findsOneWidget);
  });

  testWidgets(
    'parent mode keeps player Drive connection and family restore in family sharing section',
    (WidgetTester tester) async {
      final optionRepository = _MemoryOptionRepository();
      await optionRepository.setValue(
        FamilyAccessService.currentRoleLocalKey,
        FamilyRole.parent.name,
      );
      await optionRepository.setValue(
        FamilyAccessService.childNameKey,
        '민수',
      );
      await optionRepository.setValue(
        FamilyAccessService.parentNameKey,
        '아빠',
      );
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
        find.text('선수 Google Drive 연결'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('부모 모드 활성화'), findsOneWidget);
      expect(find.text('선수 Google Drive 연결'), findsOneWidget);
      expect(find.text('공유 대상 선수 Drive'), findsOneWidget);
      expect(find.text('현재 연결된 Drive 계정'), findsOneWidget);
      expect(find.text('선수 Drive 연결 해제'), findsOneWidget);
      expect(find.text('가족 공유 복원'), findsOneWidget);
      expect(find.text('최근 가족 공유 반영'), findsOneWidget);
      expect(find.text('최근 가족 공유 새로고침'), findsOneWidget);
      expect(find.text('가족 공간 열기'), findsNothing);
      expect(find.text('Google Drive 백업'), findsNothing);
      expect(find.text('로그아웃'), findsNothing);
    },
  );

  testWidgets(
    'enabling parent mode signs out current record Drive and prepares child connection',
    (WidgetTester tester) async {
      final optionRepository = _MemoryOptionRepository();
      await optionRepository.setValue(
        FamilyAccessService.childNameKey,
        '민수',
      );
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
        find.text('부모 모드 활성화'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('부모 모드 활성화'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('선수 Google Drive 연결'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(backupService.signOutCalled, isTrue);
      expect(backupService.refreshParentSharedDataIfNeededCalled, isTrue);
      expect(backupService.getSavedRecordDriveEmail(), 'player@example.com');
      expect(find.text('선수 Google Drive 연결'), findsOneWidget);
      expect(find.text('선수 Drive 연결 해제'), findsNothing);
      expect(find.text('아직 Google Drive 계정이 연결되지 않았어요.'), findsOneWidget);
    },
  );

  testWidgets('record mode shows saved record drive reconnect action', (
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

    expect(find.text('저장된 기록 모드 Drive'), findsOneWidget);
    expect(find.text('저장된 기록 Drive 연결'), findsOneWidget);
  });

  testWidgets(
    'record mode hides saved record drive when current account matches it',
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
      expect(find.text('저장된 기록 모드 Drive'), findsNothing);
      expect(find.text('저장된 기록 Drive 연결'), findsNothing);
    },
  );

  testWidgets(
    'parent mode shows saved parent drive separately from shared player drive',
    (WidgetTester tester) async {
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
      await tester.scrollUntilVisible(
        find.text('선수 Google Drive 연결'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('저장된 부모 모드 Drive'), findsOneWidget);
      expect(find.text('아빠 · parent@example.com'), findsOneWidget);
      expect(find.text('저장된 부모 Drive 연결'), findsOneWidget);
      expect(find.text('공유 대상 선수 Drive'), findsOneWidget);
      expect(find.text('민수 · child@example.com'), findsOneWidget);
      expect(find.text('최근 가족 공유 반영'), findsOneWidget);
      expect(find.text('최근 가족 공유 새로고침'), findsOneWidget);
      expect(
        find.text('아직 원격에 반영하지 못한 부모 모드 로컬 변경이 있어 자동 새로고침을 잠시 보류하고 있어요.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'disabling parent mode stores parent mode drive separately before returning to record mode',
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
        find.text('부모 모드 활성화'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('부모 모드 활성화'));
      await tester.pumpAndSettle();

      expect(backupService.signOutCalled, isTrue);
      expect(
        backupService.getSavedParentDriveEmail(),
        'parent-mode@example.com',
      );
      expect(find.text('저장된 기록 모드 Drive'), findsOneWidget);
      expect(find.text('저장된 기록 Drive 연결'), findsOneWidget);
    },
  );

  testWidgets(
      'settings reflects signed-in Drive account immediately after sign in', (
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

    await tester.tap(find.text('Google로 로그인'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('민수 · player@example.com'), findsWidgets);
    expect(find.text('Google 로그인이 필요해요.'), findsNothing);
  });

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

    expect(find.text('Google로 로그인'), findsOneWidget);

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

    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('러너 · runner@example.com'), findsWidgets);

    backupService.updateAccountState(
      signedIn: false,
      connectionInfo: null,
    );
    backupService.emitDriveAccountStateChanged();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Google로 로그인'), findsOneWidget);
    expect(find.text('아직 Google Drive 계정이 연결되지 않았어요.'), findsOneWidget);
  });
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
  bool _pendingParentSharedChanges;
  final DriveConnectionInfo? signInConnectionInfo;
  bool throwNextIsSignedIn;
  final bool throwIsSignedInAfterSignInOnce;
  bool signOutCalled;
  bool refreshParentSharedDataIfNeededCalled;
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
    bool pendingParentSharedChanges = false,
    this.signInConnectionInfo,
    this.throwIsSignedInAfterSignInOnce = false,
    DateTime? lastBackupAt,
  })  : _signedIn = signedIn,
        signOutCalled = false,
        refreshParentSharedDataIfNeededCalled = false,
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
  Future<bool> refreshParentSharedDataIfNeeded() async {
    refreshParentSharedDataIfNeededCalled = true;
    return false;
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

  const _FakeBackupRepository({
    this.lastBackupAt,
  });

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
