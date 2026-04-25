import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/backup_service.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/player_level_service.dart';
import 'package:football_note/domain/repositories/backup_repository.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/player_xp_guide_screen.dart';
import 'package:football_note/presentation/screens/player_level_guide_screen.dart';

void main() {
  testWidgets('reward dialog keeps action buttons in one row in dark mode', (
    tester,
  ) async {
    final repository = _MemoryOptionRepository()
      ..seed(FamilyAccessService.currentRoleLocalKey, 'parent');

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlayerLevelGuideScreen(
          currentLevel: 2,
          optionRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('입력').first);
    await tester.pumpAndSettle();

    final cancelY = tester.getTopLeft(find.text('취소')).dy;
    final clearY = tester.getTopLeft(find.text('삭제')).dy;
    final saveY = tester.getTopLeft(find.text('저장')).dy;

    expect((cancelY - clearY).abs(), lessThan(1));
    expect((clearY - saveY).abs(), lessThan(1));
  });

  testWidgets('xp history screen opens from level guide', (tester) async {
    final repository = _MemoryOptionRepository()
      ..seed(PlayerLevelService.xpHistoryKey, <Map<String, dynamic>>[
        <String, dynamic>{
          'awardedAt': '2026-03-18T09:30:00.000',
          'deltaXp': 30,
          'totalXp': 130,
          'beforeLevel': 2,
          'afterLevel': 3,
          'category': 'training',
          'label': '원터치 패스',
          'reasons': <String>['log', 'first_daily_log'],
        },
      ]);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlayerLevelGuideScreen(
          currentLevel: 3,
          optionRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('경험치 히스토리'));
    await tester.pumpAndSettle();

    expect(find.text('경험치 히스토리'), findsWidgets);
    expect(find.textContaining('훈련 기록 · 원터치 패스'), findsWidgets);
    expect(find.text('+30 XP'), findsOneWidget);
    expect(find.textContaining('누적 130 XP'), findsOneWidget);
  });

  testWidgets('xp guide lists lifting jump rope and plan series bonus', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlayerXpGuideScreen(optionRepository: _MemoryOptionRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('리프팅 기록 추가'), findsOneWidget);
    expect(find.text('줄넘기 기록 추가'), findsOneWidget);
    expect(find.text('리프팅/줄넘기 없이 저장하면 감점'), findsOneWidget);
    expect(find.text('묶음 계획 생성 보너스', skipOffstage: false), findsOneWidget);
  });

  testWidgets('parent mode hides reward claim action and keeps reward edit', (
    tester,
  ) async {
    final repository = _MemoryOptionRepository()
      ..seed(FamilyAccessService.currentRoleLocalKey, 'parent')
      ..seed(PlayerLevelService.customRewardNamesKey, <String, String>{
        '2': '새 축구공',
      })
      ..seed(PlayerLevelService.totalXpKey, 120);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlayerLevelGuideScreen(
          currentLevel: 2,
          optionRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('공유 역할 모드'), findsOneWidget);
    expect(find.byTooltip('모드 설명 보기'), findsOneWidget);
    expect(find.textContaining('선물 이름만 저장할 수 있고'), findsNothing);
    expect(find.text('선물 받기'), findsNothing);
    expect(find.text('입력').first, findsOneWidget);
    expect(find.text('선수 모드에서 수령'), findsOneWidget);

    await tester.tap(find.byTooltip('모드 설명 보기'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        '공유 역할에서는 레벨 선물 이름만 저장할 수 있고, 저장한 선물 이름은 선수 Drive 공유에도 반영됩니다. 선물 수령은 선수 모드에서 진행합니다.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('parent mode shows syncing state after saving reward name', (
    tester,
  ) async {
    final completer = Completer<bool>();
    final repository = _MemoryOptionRepository()
      ..seed(FamilyAccessService.currentRoleLocalKey, 'parent')
      ..seed(PlayerLevelService.totalXpKey, 120);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlayerLevelGuideScreen(
          currentLevel: 2,
          optionRepository: repository,
          driveBackupService: BackupService(
            _DelayedBackupRepository(
              onBackupIfSignedIn: () => completer.future,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('입력').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '새 축구공');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pump();

    expect(find.text('동기화 중...'), findsOneWidget);
    expect(find.text('선수 Drive로 동기화 중이에요...'), findsWidgets);

    completer.complete(true);
    await tester.pumpAndSettle();

    expect(find.text('동기화 중...'), findsNothing);
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  void seed(String key, dynamic value) {
    _values[key] = value;
  }

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List<String>) return value;
    return defaults;
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List<int>) return value;
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

class _DelayedBackupRepository implements BackupRepository {
  final Future<bool> Function() onBackupIfSignedIn;

  _DelayedBackupRepository({required this.onBackupIfSignedIn});

  @override
  Future<void> autoBackupDaily() async {}

  @override
  Future<void> backup() async {}

  @override
  Future<bool> backupIfSignedIn({bool requireAutoOnSave = false}) =>
      onBackupIfSignedIn();

  @override
  DateTime? getLastBackup() => null;

  @override
  bool isAutoDailyEnabled() => false;

  @override
  bool isAutoOnSaveEnabled() => false;

  @override
  Future<void> restoreLatest() async {}

  @override
  Future<void> setAutoDailyEnabled(bool value) async {}

  @override
  Future<void> setAutoOnSaveEnabled(bool value) async {}
}
