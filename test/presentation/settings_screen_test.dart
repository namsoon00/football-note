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
        find.text('아이 Google Drive 연결'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('부모 모드 활성화'), findsOneWidget);
      expect(find.text('아이 Google Drive 연결'), findsOneWidget);
      expect(find.text('공유 대상 아이 Drive'), findsOneWidget);
      expect(find.text('현재 연결된 Drive 계정'), findsOneWidget);
      expect(find.text('아이 Drive 연결 해제'), findsOneWidget);
      expect(find.text('가족 공유 복원'), findsOneWidget);
      expect(find.text('가족 공간 열기'), findsNothing);
      expect(find.text('Google Drive 백업'), findsNothing);
      expect(find.text('로그아웃'), findsNothing);
    },
  );

  testWidgets(
    'enabling parent mode signs out current player Drive and prepares child connection',
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
        find.text('아이 Google Drive 연결'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(backupService.signOutCalled, isTrue);
      expect(backupService.getSavedPlayerDriveEmail(), 'player@example.com');
      expect(find.text('아이 Google Drive 연결'), findsOneWidget);
      expect(find.text('아이 Drive 연결 해제'), findsNothing);
      expect(find.text('아직 Google Drive 계정이 연결되지 않았어요.'), findsOneWidget);
    },
  );

  testWidgets('player mode shows saved player drive reconnect action', (
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
      savedPlayerDriveLabel: '민수 · player@example.com',
      savedPlayerDriveEmail: 'player@example.com',
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

    expect(find.text('저장된 선수 Drive'), findsOneWidget);
    expect(find.text('저장된 선수 Drive 연결'), findsOneWidget);
  });

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
}

class _FakeDriveBackupService extends BackupService {
  bool _signedIn;
  DriveConnectionInfo? _connectionInfo;
  String _sharedChildDriveLabel;
  String _sharedChildDriveEmail;
  String _savedPlayerDriveLabel;
  String _savedPlayerDriveEmail;
  final DriveConnectionInfo? signInConnectionInfo;
  bool throwNextIsSignedIn;
  final bool throwIsSignedInAfterSignInOnce;
  bool signOutCalled;

  _FakeDriveBackupService({
    required bool signedIn,
    required DriveConnectionInfo? connectionInfo,
    required String sharedChildDriveLabel,
    required String sharedChildDriveEmail,
    String savedPlayerDriveLabel = '',
    String savedPlayerDriveEmail = '',
    this.signInConnectionInfo,
    this.throwIsSignedInAfterSignInOnce = false,
    DateTime? lastBackupAt,
  })  : _signedIn = signedIn,
        signOutCalled = false,
        throwNextIsSignedIn = false,
        _connectionInfo = connectionInfo,
        _sharedChildDriveLabel = sharedChildDriveLabel,
        _sharedChildDriveEmail = sharedChildDriveEmail,
        _savedPlayerDriveLabel = savedPlayerDriveLabel,
        _savedPlayerDriveEmail = savedPlayerDriveEmail,
        super(_FakeBackupRepository(lastBackupAt: lastBackupAt));

  bool get signedIn => _signedIn;
  DriveConnectionInfo? get connectionInfo => _connectionInfo;

  @override
  Future<DriveConnectionInfo?> getDriveConnectionInfo() async =>
      _connectionInfo;

  @override
  String getSharedChildDriveEmail() => _sharedChildDriveEmail;

  @override
  String getSharedChildDriveLabel() => _sharedChildDriveLabel;

  @override
  String getSavedPlayerDriveEmail() => _savedPlayerDriveEmail;

  @override
  String getSavedPlayerDriveLabel() => _savedPlayerDriveLabel;

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
  Future<void> signInForSavedPlayer() async {}

  @override
  Future<void> rememberPlayerDriveConnection() async {
    final info = _connectionInfo;
    if (info == null) return;
    _savedPlayerDriveEmail = info.email;
    _savedPlayerDriveLabel = info.label;
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
