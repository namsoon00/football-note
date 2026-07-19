import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/match_competition_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/team_management_service.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/repositories/training_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/competition_management_screen.dart';
import 'package:football_note/presentation/screens/match_record_screen.dart';
import 'package:football_note/presentation/screens/team_management_screen.dart';
import 'package:football_note/presentation/theme/app_theme.dart';

import '../helpers/test_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MemoryTrainingRepository trainingRepository;
  late TrainingService trainingService;
  late _MemoryOptionRepository optionRepository;
  late LocaleService localeService;
  late SettingsService settingsService;

  setUp(() {
    trainingRepository = _MemoryTrainingRepository();
    trainingService = TrainingService(trainingRepository);
    optionRepository = _MemoryOptionRepository();
    localeService = LocaleService(optionRepository)..load();
    settingsService = SettingsService(optionRepository)..load();
  });

  tearDown(() async {
    await trainingRepository.dispose();
  });

  Future<void> pumpCompetitionManagement(
    WidgetTester tester, {
    required ThemeMode themeMode,
  }) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp(
          locale: const Locale('ko', 'KR'),
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ko', 'KR'),
            Locale('ja'),
          ],
          home: CompetitionManagementScreen(
            trainingService: trainingService,
            optionRepository: optionRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> seedMatchHubRecords() async {
    final competitionService = MatchCompetitionService(optionRepository);
    await competitionService.upsertCompetition(
      MatchCompetitionRecord.create(
        kind: MatchCompetitionRecord.kindLeague,
        name: '주말 리그',
        teams: const ['우리 팀', '서울 U15', '부산 U15'],
        season: '2026 여름',
        venue: '메인 구장',
        organizer: '감독 김코치',
      ),
    );
    await competitionService.upsertCompetition(
      MatchCompetitionRecord.create(
        kind: MatchCompetitionRecord.kindTournament,
        name: '컵 대회',
        teams: const ['우리 팀', '인천 U15', '대전 U15', '광주 U15'],
        status: MatchCompetitionRecord.statusFinished,
      ),
    );
    await TeamManagementService(optionRepository).upsertTeam(
      ManagedTeam.create(
        name: '우리 팀 U15',
        formation: '4-3-3',
        strategy: '전방 압박 후 빠른 측면 전환',
        players: [
          ManagedTeamPlayer.create(name: '김민준', number: '10'),
        ],
        lineup: const <String, String>{},
      ),
    );
    await trainingService.add(
      TrainingEntry(
        date: DateTime(2026, 6, 20),
        durationMinutes: 70,
        intensity: 4,
        type: '시합',
        mood: 4,
        injury: false,
        notes: '',
        location: '메인 구장',
        opponentTeam: '서울 U15',
        scoredGoals: 3,
        concededGoals: 1,
        matchKind: MatchCompetitionRecord.kindLeague,
        matchCompetitionName: '주말 리그',
        leagueTeamNames: const ['우리 팀', '서울 U15', '부산 U15'],
        leaguePoints: 3,
      ),
    );
    await trainingService.add(
      TrainingEntry(
        date: DateTime(2026, 6, 18),
        durationMinutes: 60,
        intensity: 3,
        type: '시합',
        mood: 3,
        injury: false,
        notes: '',
        location: '보조 구장',
        opponentTeam: '인천 U15',
        scoredGoals: 1,
        concededGoals: 2,
        matchKind: MatchCompetitionRecord.kindTournament,
        matchCompetitionName: '컵 대회',
        leagueTeamNames: const ['우리 팀', '인천 U15'],
        tournamentOutcome: 'eliminated',
      ),
    );
  }

  testWidgets('Competition management actions keep contrast in both themes', (
    tester,
  ) async {
    await seedMatchHubRecords();

    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      await pumpCompetitionManagement(tester, themeMode: themeMode);

      _expectTextButtonContrast(tester, '새 대회');
      expect(find.text('전체 2'), findsOneWidget);
      expect(find.text('진행 1'), findsOneWidget);
      expect(find.text('종료 1'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('competition-create-action')),
      );
      await tester.pumpAndSettle();

      expect(find.text('리그 경기'), findsWidgets);
      expect(find.text('토너먼트'), findsWidgets);
      _expectTextButtonContrast(tester, '대회 저장');
      _expectFilledButtonContrast(tester, '추가');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Competition editor auto saves after name is entered', (
    tester,
  ) async {
    await pumpCompetitionManagement(tester, themeMode: ThemeMode.light);

    await tester.tap(
      find.byKey(const ValueKey('competition-create-action')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '자동 저장 리그');
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    var competitions = MatchCompetitionService(
      optionRepository,
    ).allCompetitions();
    expect(competitions, hasLength(1));
    expect(competitions.single.name, '자동 저장 리그');

    await tester.enterText(find.byType(TextField).at(1), '2026 가을');
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    competitions = MatchCompetitionService(optionRepository).allCompetitions();
    expect(competitions.single.season, '2026 가을');
    expect(find.text('대회 저장'), findsOneWidget);
  });

  testWidgets('Competition center opens a focused mobile detail view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await seedMatchHubRecords();
    await pumpCompetitionManagement(tester, themeMode: ThemeMode.light);

    expect(find.text('운영 요약'), findsNothing);
    expect(find.text('주말 리그'), findsOneWidget);
    expect(find.text('컵 대회'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('주말 리그'));
    await tester.pumpAndSettle();

    expect(find.text('리그 순위'), findsOneWidget);
    expect(find.text('등록 팀'), findsWidgets);
    expect(find.text('서울 U15'), findsWidgets);
    expect(find.textContaining('1승 0무 0패'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('competition-detail-edit')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Competition deletion requires confirmation', (tester) async {
    await seedMatchHubRecords();
    await pumpCompetitionManagement(tester, themeMode: ThemeMode.light);

    await tester.tap(find.text('컵 대회'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('competition-detail-delete')),
    );
    await tester.pumpAndSettle();

    expect(find.text('대회 삭제'), findsOneWidget);
    expect(find.textContaining('시합 기록은 삭제되지 않습니다'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await tester.pumpAndSettle();
    expect(
      MatchCompetitionService(optionRepository).allCompetitions(),
      hasLength(2),
    );

    await tester.tap(find.text('컵 대회'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('competition-detail-delete')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pumpAndSettle();

    final records = MatchCompetitionService(
      optionRepository,
    ).allCompetitions();
    expect(records, hasLength(1));
    expect(records.single.name, '주말 리그');
  });

  testWidgets('Team management match tab shows records inline', (
    tester,
  ) async {
    await seedMatchHubRecords();

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp(
          locale: const Locale('ko', 'KR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ko', 'KR'),
            Locale('ja'),
          ],
          home: TeamManagementScreen(
            optionRepository: optionRepository,
            trainingService: trainingService,
            localeService: localeService,
            settingsService: settingsService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('team-header-competition')),
    );
    await tester.pumpAndSettle();
    expect(find.text('대회 운영 센터'), findsOneWidget);
    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('시합관리'));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('team-match-record-action')), findsOneWidget);
    expect(find.byKey(const ValueKey('team-match-records-content')),
        findsOneWidget);
    expect(find.text('시합 기록 보기'), findsNothing);
    expect(find.text('시합 통계'), findsNothing);
    expect(find.text('클럽 일정'), findsNothing);
    expect(find.text('전체 시합 기록'), findsOneWidget);
    expect(find.text('기록 요약'), findsNothing);
    expect(find.textContaining('서울 U15'), findsWidgets);
    expect(find.text('3 : 1'), findsOneWidget);
  });

  testWidgets('Team management filters match records by kind and competition', (
    tester,
  ) async {
    await seedMatchHubRecords();

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp(
          locale: const Locale('ko', 'KR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ko', 'KR'),
            Locale('ja'),
          ],
          home: TeamManagementScreen(
            optionRepository: optionRepository,
            trainingService: trainingService,
            localeService: localeService,
            settingsService: settingsService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('시합관리'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('match-record-kind-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('리그 경기').last);
    await tester.pumpAndSettle();

    expect(find.text('서울 U15'), findsOneWidget);
    expect(find.text('인천 U15'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('match-record-kind-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('토너먼트').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('match-record-competition-filter')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('컵 대회').last);
    await tester.pumpAndSettle();

    expect(find.text('서울 U15'), findsNothing);
    expect(find.text('인천 U15'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parent mode team management does not auto save edits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp(
          locale: const Locale('ko', 'KR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ko', 'KR'),
            Locale('ja'),
          ],
          home: TeamManagementScreen(
            optionRepository: optionRepository,
            trainingService: trainingService,
            localeService: localeService,
            settingsService: settingsService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final addPlayerButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '선수 등록').first,
    );
    expect(addPlayerButton.onPressed, isNull);
    expect(find.widgetWithText(FilledButton, '새 팀'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '팀 삭제'), findsNothing);
    expect(find.text('팀 선택'), findsNothing);
    await tester.tap(find.text('시합관리'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('team-match-record-action')));
    await tester.pumpAndSettle();

    expect(find.byType(MatchRecordScreen), findsNothing);
    expect(
      find.text('보호자 모드에서는 선수의 핵심 데이터를 수정할 수 없어요. 선수 모드에서 변경해 주세요.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(TeamManagementService(optionRepository).allTeams(), isEmpty);
  });

  testWidgets('team management mobile home shows roster content immediately', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp(
          locale: const Locale('en'),
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ko', 'KR'),
            Locale('ja'),
          ],
          home: TeamManagementScreen(
            optionRepository: optionRepository,
            trainingService: trainingService,
            localeService: localeService,
            settingsService: settingsService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Team Management'), findsOneWidget);
    expect(find.text('Player management'), findsOneWidget);
    expect(find.text('Match management'), findsOneWidget);
    expect(find.text('Board'), findsOneWidget);
    expect(find.text('Cups'), findsOneWidget);
    expect(find.text('Roster'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Register player'),
      findsOneWidget,
    );
    expect(find.text('No players registered.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('team management searches and filters a compact mobile roster', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await TeamManagementService(optionRepository).upsertTeam(
      ManagedTeam.create(
        name: '우리 팀 U15',
        players: [
          ManagedTeamPlayer.create(
            name: '김민준',
            number: '10',
            role: ManagedTeamPlayer.roleMidfielder,
            condition: ManagedTeamPlayer.conditionReady,
          ),
          ManagedTeamPlayer.create(
            name: '이서준',
            number: '4',
            role: ManagedTeamPlayer.roleDefender,
            condition: ManagedTeamPlayer.conditionRest,
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp(
          locale: const Locale('ko', 'KR'),
          theme: AppTheme.light(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ko', 'KR'),
            Locale('ja'),
          ],
          home: TeamManagementScreen(optionRepository: optionRepository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('전체 2'), findsOneWidget);
    expect(find.text('출전 1'), findsOneWidget);
    expect(find.text('휴식 1'), findsOneWidget);
    expect(find.text('김민준'), findsOneWidget);
    expect(find.text('이서준'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('team-player-search-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('team-player-search-field')),
      '김',
    );
    await tester.pumpAndSettle();

    expect(find.text('김민준'), findsOneWidget);
    expect(find.text('이서준'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('team-player-search-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('team-player-condition-filter')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('휴식 권장').last);
    await tester.pumpAndSettle();

    expect(find.text('김민준'), findsNothing);
    expect(find.text('이서준'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parent mode competition management keeps create flow disabled', (
    tester,
  ) async {
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );

    await pumpCompetitionManagement(tester, themeMode: ThemeMode.light);

    final createButton = tester.widget<TextButton>(
      find.descendant(
        of: find.byKey(const ValueKey('competition-create-action')),
        matching: find.byType(TextButton),
      ),
    );
    expect(createButton.onPressed, isNull);

    await tester.tap(
      find.byKey(const ValueKey('competition-create-action')),
    );
    await tester.pumpAndSettle();

    expect(find.text('대회 저장'), findsNothing);
    final competitions = MatchCompetitionService(
      optionRepository,
    ).allCompetitions();
    expect(competitions, isEmpty);
  });

  testWidgets('Match record screen saves a friendly result from touch controls',
      (
    tester,
  ) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp(
          locale: const Locale('ko', 'KR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ko', 'KR'),
            Locale('ja'),
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MatchRecordScreen(
                          trainingService: trainingService,
                          localeService: localeService,
                          optionRepository: optionRepository,
                          settingsService: settingsService,
                          initialDate: DateTime(2026, 6, 26),
                        ),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('match-opponent-field')),
      '서울 U15',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('match-board-our-score-increase')),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('match-board-primary-stat-increase')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('match-board-primary-stat-increase')),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('match-board-yellow-cards-increase')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('match-board-yellow-cards-increase')),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('match-board-red-cards-increase')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('match-board-red-cards-increase')),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('match-board-minutes-increase')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('match-board-minutes-increase')),
    );
    await tester.ensureVisible(find.text('승'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('저장'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pump(const Duration(seconds: 1));

    expect(trainingRepository.entries, hasLength(1));
    expect(trainingRepository.entries.single.opponentTeam, '서울 U15');
    expect(trainingRepository.entries.single.scoredGoals, 1);
    expect(trainingRepository.entries.single.concededGoals, 0);
    expect(trainingRepository.entries.single.playerGoals, 1);
    expect(trainingRepository.entries.single.yellowCards, 1);
    expect(trainingRepository.entries.single.redCards, 1);
    expect(trainingRepository.entries.single.minutesPlayed, 5);
    expect(trainingRepository.entries.single.matchKind, 'friendly');
  });

  testWidgets('Match record screen requires a managed league competition', (
    tester,
  ) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp(
          locale: const Locale('ko', 'KR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ko', 'KR'),
            Locale('ja'),
          ],
          home: MatchRecordScreen(
            trainingService: trainingService,
            localeService: localeService,
            optionRepository: optionRepository,
            settingsService: settingsService,
            initialDate: DateTime(2026, 7, 13),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('리그 경기'));
    await tester.pumpAndSettle();

    expect(find.text('대회관리에서 만든 대회를 선택하세요.'), findsOneWidget);
    expect(find.text('대회 이름'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey<String>('match-opponent-field')),
      '서울 U15',
    );
    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pump(const Duration(seconds: 1));

    expect(trainingRepository.entries, isEmpty);
    expect(
        MatchCompetitionService(optionRepository).allCompetitions(), isEmpty);
  });

  testWidgets('Match record screen loads a saved league competition', (
    tester,
  ) async {
    await MatchCompetitionService(optionRepository).upsertCompetition(
      MatchCompetitionRecord.create(
        kind: MatchCompetitionRecord.kindLeague,
        name: '주말 리그',
        teams: const ['서울 U15', '수원 U15'],
        venue: '메인 구장',
      ),
    );

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp(
          locale: const Locale('ko', 'KR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ko', 'KR'),
            Locale('ja'),
          ],
          home: MatchRecordScreen(
            trainingService: trainingService,
            localeService: localeService,
            optionRepository: optionRepository,
            settingsService: settingsService,
            initialDate: DateTime(2026, 7, 13),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('리그 경기'));
    await tester.pumpAndSettle();
    expect(find.text('저장된 대회 불러오기'), findsOneWidget);
    expect(find.text('대회 이름'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('match-saved-competition-loader')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('주말 리그 · 진행 중').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('수원 U15').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('match-board-our-score-increase')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pump(const Duration(seconds: 1));

    expect(trainingRepository.entries, hasLength(1));
    final entry = trainingRepository.entries.single;
    expect(entry.matchKind, MatchCompetitionRecord.kindLeague);
    expect(entry.matchCompetitionName, '주말 리그');
    expect(entry.leagueTeamNames, containsAll(['서울 U15', '수원 U15']));
    expect(entry.opponentTeam, '수원 U15');
    expect(entry.matchLocation, '메인 구장');
    expect(entry.scoredGoals, 1);
    expect(entry.concededGoals, 0);
    expect(entry.leaguePoints, 3);
  });

  testWidgets('Match record screen calculates tournament wins from result', (
    tester,
  ) async {
    await MatchCompetitionService(optionRepository).upsertCompetition(
      MatchCompetitionRecord.create(
        kind: MatchCompetitionRecord.kindTournament,
        name: '여름 컵',
        teams: const ['서울 U15', '수원 U15'],
        venue: '컵 구장',
      ),
    );

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp(
          locale: const Locale('ko', 'KR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ko', 'KR'),
            Locale('ja'),
          ],
          home: MatchRecordScreen(
            trainingService: trainingService,
            localeService: localeService,
            optionRepository: optionRepository,
            settingsService: settingsService,
            initialDate: DateTime(2026, 7, 14),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('토너먼트'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('match-saved-competition-loader')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('여름 컵 · 진행 중').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('수원 U15').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('match-board-our-score-increase')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pump(const Duration(seconds: 1));

    expect(trainingRepository.entries, hasLength(1));
    final entry = trainingRepository.entries.single;
    expect(entry.matchKind, MatchCompetitionRecord.kindTournament);
    expect(entry.matchCompetitionName, '여름 컵');
    expect(entry.opponentTeam, '수원 U15');
    expect(entry.matchLocation, '컵 구장');
    expect(entry.scoredGoals, 1);
    expect(entry.concededGoals, 0);
    expect(entry.tournamentWins, 1);
  });

  testWidgets('Team management screen saves a roster and pitch assignment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp(
          locale: const Locale('ko', 'KR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ko', 'KR'),
            Locale('ja'),
          ],
          home: TeamManagementScreen(optionRepository: optionRepository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('작업 선택'), findsNothing);
    expect(find.text('선수관리'), findsOneWidget);
    expect(find.text('시합관리'), findsOneWidget);
    expect(find.text('팀 프로필'), findsNothing);
    expect(find.text('팀 프로필과 전술 원칙'), findsNothing);
    expect(find.text('전술 설명'), findsNothing);
    expect(find.byKey(const ValueKey('team-header-board')), findsOneWidget);
    expect(find.byKey(const ValueKey('team-player-board')), findsNothing);
    expect(
        find.byKey(const ValueKey('team-tactics-board-pitch')), findsNothing);
    expect(find.widgetWithText(FilledButton, '새 팀'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '팀 삭제'), findsNothing);
    expect(find.text('팀 선택'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('team-name-open')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('team-name-field')),
      '우리 팀 U15',
    );
    await tester.tap(find.byKey(const ValueKey('team-name-save')));
    await tester.pumpAndSettle();

    expect(find.text('저장됨'), findsNothing);
    expect(
      TeamManagementService(optionRepository).allTeams().single.name,
      '우리 팀 U15',
    );

    final addPlayerButton = find.widgetWithText(FilledButton, '선수 등록');
    await tester.ensureVisible(addPlayerButton);
    await tester.pumpAndSettle();
    await tester.tap(addPlayerButton.first);
    await tester.pumpAndSettle();
    expect(find.text('선수 등록'), findsWidgets);
    await tester.tap(find.text('미드필더').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('team-player-name-field')),
      '김민준',
    );
    await _selectDropdownValue(
      tester,
      const ValueKey('team-player-number-field'),
      '번호 10',
    );
    await _selectDropdownValue(
      tester,
      const ValueKey('team-player-grade-field'),
      '초등 5학년',
    );
    await _selectDropdownValue(
      tester,
      const ValueKey('team-player-height-field'),
      '152cm',
    );
    await _selectDropdownValue(
      tester,
      const ValueKey('team-player-weight-field'),
      '43kg',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('team-player-note-field')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('team-player-note-field')),
      '왼발 킥 좋음',
    );
    final savePlayerButton = find.byKey(
      const ValueKey('team-player-save-button'),
    );
    await tester.ensureVisible(savePlayerButton);
    await tester.pumpAndSettle();
    await tester.tap(savePlayerButton);
    await tester.pumpAndSettle();

    expect(find.text('스쿼드 보드'), findsNothing);
    expect(find.text('미드필더 · 1명'), findsOneWidget);
    expect(find.text('출전 가능'), findsOneWidget);

    final boardButton = find.byKey(const ValueKey('team-header-board'));
    await tester.ensureVisible(boardButton);
    await tester.tap(boardButton);
    await tester.pumpAndSettle();
    expect(find.text('포메이션'), findsNothing);
    expect(find.byKey(const ValueKey('team-board-landscape-toggle')),
        findsOneWidget);
    expect(find.text('전술 리스트'), findsOneWidget);
    expect(find.text('전술 1'), findsOneWidget);

    final playerChip = find.text('10 김민준').last;
    final pitchFinder = find.byKey(const ValueKey('team-tactics-board-pitch'));
    await tester.ensureVisible(playerChip);
    await tester.ensureVisible(pitchFinder);
    await tester.pumpAndSettle();
    final pitchRect = tester.getRect(pitchFinder);
    expect(pitchRect.height, greaterThan(420));
    await tester.drag(
      playerChip,
      pitchRect.center - tester.getCenter(playerChip),
    );
    await tester.pumpAndSettle();

    final markerMode = find.text('이동선').last;
    await tester.ensureVisible(markerMode);
    await tester.tap(markerMode);
    await tester.pumpAndSettle();
    await tester.dragFrom(
      pitchRect.centerLeft + Offset(80, pitchRect.height * 0.28),
      const Offset(180, -120),
    );
    await tester.pumpAndSettle();

    final pressMode = find.text('압박선').last;
    await tester.tap(pressMode);
    await tester.pumpAndSettle();
    await tester.dragFrom(
      pitchRect.centerRight - Offset(80, pitchRect.height * 0.22),
      const Offset(-170, 110),
    );
    await tester.pumpAndSettle();

    final zoneMode = find.text('공간 영역').last;
    await tester.tap(zoneMode);
    await tester.pumpAndSettle();
    await tester.dragFrom(
      pitchRect.center - const Offset(80, 80),
      const Offset(160, 130),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('team-tactic-board-list-open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('team-tactic-board-add')));
    await tester.pumpAndSettle();
    expect(find.text('전술 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('team-tactic-board-list-open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('team-tactic-board-delete')));
    await tester.pumpAndSettle();
    expect(find.text('전술 삭제'), findsOneWidget);
    expect(find.textContaining('전술 2'), findsWidgets);
    await tester.tap(find.text('취소').last);
    await tester.pumpAndSettle();
    expect(find.text('전술 2'), findsOneWidget);
    final secondBoardPlayerChip = find.text('10 김민준').last;
    await tester.ensureVisible(secondBoardPlayerChip);
    await tester.drag(
      secondBoardPlayerChip,
      pitchRect.topCenter.translate(0, pitchRect.height * 0.32) -
          tester.getCenter(secondBoardPlayerChip),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('team-tactic-board-list-open')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('전술 1').last);
    await tester.pumpAndSettle();

    expect(find.text('팀 저장'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    final teams = TeamManagementService(optionRepository).allTeams();
    expect(teams, hasLength(1));
    expect(teams.single.name, '우리 팀 U15');
    expect(teams.single.strategy, isEmpty);
    expect(teams.single.players.single.name, '김민준');
    expect(teams.single.players.single.role, ManagedTeamPlayer.roleMidfielder);
    expect(teams.single.players.single.grade, '초등 5학년');
    expect(teams.single.players.single.heightCm, 152);
    expect(teams.single.players.single.weightKg, 43);
    expect(teams.single.players.single.note, '왼발 킥 좋음');
    final placement =
        teams.single.playerPlacements[teams.single.players.single.id];
    expect(placement, isNotNull);
    expect(placement!.x, inInclusiveRange(0.35, 0.65));
    expect(placement.y, inInclusiveRange(0.35, 0.65));
    expect(teams.single.tacticLines, hasLength(3));
    expect(teams.single.tacticBoards, hasLength(2));
    expect(teams.single.tacticBoards.first.tacticLines, hasLength(3));
    expect(teams.single.tacticBoards.last.title, '전술 2');
    expect(teams.single.tacticBoards.last.playerPlacements, hasLength(1));
    expect(
      teams.single.tacticLines.map((line) => line.type),
      containsAll(<String>[
        ManagedTacticLine.typeMovement,
        ManagedTacticLine.typePress,
        ManagedTacticLine.typeZone,
      ]),
    );
  });
}

void _expectFilledButtonContrast(WidgetTester tester, String text) {
  final button = tester.widget<FilledButton>(
    find
        .ancestor(
          of: find.text(text),
          matching: find.byType(FilledButton),
        )
        .first,
  );
  _expectButtonStyleContrast(button.style, text);
}

void _expectTextButtonContrast(WidgetTester tester, String text) {
  final button = tester.widget<TextButton>(
    find
        .ancestor(
          of: find.text(text),
          matching: find.byType(TextButton),
        )
        .first,
  );
  _expectButtonStyleContrast(button.style, text);
}

Future<void> _selectDropdownValue(
  WidgetTester tester,
  Key dropdownKey,
  String optionText,
) async {
  final dropdown = find.byKey(dropdownKey);
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(optionText).last);
  await tester.pumpAndSettle();
}

void _expectButtonStyleContrast(ButtonStyle? style, String text) {
  final states = <WidgetState>{};
  final foreground = style?.foregroundColor?.resolve(states);
  final background = style?.backgroundColor?.resolve(states);

  expect(foreground, isNotNull, reason: '$text foreground must be explicit');
  expect(background, isNotNull, reason: '$text background must be explicit');
  expect(
    _contrastRatio(foreground!, background!),
    greaterThanOrEqualTo(4.5),
    reason: '$text button text contrast should remain readable',
  );
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

class _MemoryTrainingRepository implements TrainingRepository {
  final List<TrainingEntry> _entries = <TrainingEntry>[];
  final StreamController<List<TrainingEntry>> _controller =
      StreamController<List<TrainingEntry>>.broadcast();

  List<TrainingEntry> get entries => List<TrainingEntry>.unmodifiable(_entries);

  Future<void> dispose() => _controller.close();

  @override
  Future<void> add(TrainingEntry entry) async {
    _entries.add(entry);
    _emit();
  }

  @override
  Future<void> delete(TrainingEntry entry) async {
    _entries.remove(entry);
    _emit();
  }

  @override
  Future<List<TrainingEntry>> getAll() async =>
      List<TrainingEntry>.unmodifiable(_entries);

  @override
  Future<List<TrainingEntry>> getRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) async {
    return _rangeEntries(startInclusive, endExclusive);
  }

  @override
  Future<List<TrainingEntry>> getRecent({
    required int limit,
    bool includeMatches = true,
    String? sportId,
  }) async {
    return _recentEntries(
      limit: limit,
      includeMatches: includeMatches,
      sportId: sportId,
    );
  }

  @override
  Future<void> update(int key, TrainingEntry entry) async {
    if (key < 0 || key >= _entries.length) return;
    _entries[key] = entry;
    _emit();
  }

  @override
  Stream<List<TrainingEntry>> watchAll() {
    return Stream<List<TrainingEntry>>.multi((controller) {
      void emit() {
        if (!controller.isClosed) {
          controller.add(List<TrainingEntry>.unmodifiable(_entries));
        }
      }

      emit();
      final sub = _controller.stream.listen((_) => emit());
      controller.onCancel = sub.cancel;
    }, isBroadcast: true);
  }

  @override
  Stream<List<TrainingEntry>> watchRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    return Stream<List<TrainingEntry>>.multi((controller) {
      void emit() {
        if (!controller.isClosed) {
          controller.add(_rangeEntries(startInclusive, endExclusive));
        }
      }

      emit();
      final sub = _controller.stream.listen((_) => emit());
      controller.onCancel = sub.cancel;
    }, isBroadcast: true);
  }

  @override
  Stream<List<TrainingEntry>> watchRecent({
    required int limit,
    bool includeMatches = true,
    String? sportId,
  }) {
    return Stream<List<TrainingEntry>>.multi((controller) {
      void emit() {
        if (!controller.isClosed) {
          controller.add(
            _recentEntries(
              limit: limit,
              includeMatches: includeMatches,
              sportId: sportId,
            ),
          );
        }
      }

      emit();
      final sub = _controller.stream.listen((_) => emit());
      controller.onCancel = sub.cancel;
    }, isBroadcast: true);
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List<TrainingEntry>.unmodifiable(_entries));
    }
  }

  List<TrainingEntry> _rangeEntries(
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    return _entries
        .where(
          (entry) =>
              !entry.date.isBefore(startInclusive) &&
              entry.date.isBefore(endExclusive),
        )
        .toList(growable: false)
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<TrainingEntry> _recentEntries({
    required int limit,
    required bool includeMatches,
    String? sportId,
  }) {
    if (limit <= 0) return const <TrainingEntry>[];
    final entries = _entries
        .where(
          (entry) =>
              (sportId == null || entry.sportId == sportId) &&
              (includeMatches || !entry.isMatch),
        )
        .toList(growable: false)
      ..sort(TrainingEntry.compareByRecentCreated);
    if (entries.length <= limit) return entries;
    return entries.take(limit).toList(growable: false);
  }
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  T? getValue<T>(String key) => _values[key] as T?;

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List<int>) return List<int>.from(value);
    if (value is List) return value.whereType<int>().toList(growable: false);
    return List<int>.from(defaults);
  }

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List<String>) return List<String>.from(value);
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return List<String>.from(defaults);
  }

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = List<dynamic>.from(options);
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }
}
