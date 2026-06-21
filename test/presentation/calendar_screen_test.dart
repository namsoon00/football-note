import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/match_competition_service.dart';
import 'package:football_note/application/meal_log_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/training_service.dart';
import 'package:football_note/domain/entities/meal_entry.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/repositories/training_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/calendar_screen.dart';
import 'package:table_calendar/table_calendar.dart';

import '../helpers/test_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MemoryTrainingRepository trainingRepository;
  late TrainingService trainingService;
  late MealLogService mealLogService;
  late _MemoryOptionRepository optionRepository;
  late LocaleService localeService;
  late SettingsService settingsService;

  Future<void> pumpCalendar(
    WidgetTester tester, {
    void Function(TrainingEntry entry)? onEdit,
  }) async {
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
          supportedLocales: const [Locale('en'), Locale('ko', 'KR')],
          home: CalendarScreen(
            trainingService: trainingService,
            mealLogService: mealLogService,
            localeService: localeService,
            optionRepository: optionRepository,
            settingsService: settingsService,
            onEdit: onEdit ?? (_) {},
            onCreate: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  Future<void> saveTrainingEntry(
    WidgetTester _,
    TrainingEntry entry,
  ) async {
    await trainingService.add(entry);
  }

  Future<void> saveMealEntry(WidgetTester _, MealEntry entry) async {
    await mealLogService.save(entry);
  }

  Future<void> setOptionValue(
    WidgetTester _,
    String key,
    Object? value,
  ) async {
    await optionRepository.setValue(key, value);
  }

  setUp(() async {
    trainingRepository = _MemoryTrainingRepository();
    trainingService = TrainingService(trainingRepository);
    optionRepository = _MemoryOptionRepository();
    mealLogService = MealLogService(optionRepository);
    localeService = LocaleService(optionRepository)..load();
    settingsService = SettingsService(optionRepository)..load();
  });

  tearDown(() async {
    await mealLogService.dispose();
    await trainingRepository.dispose();
  });

  testWidgets('기록이 있으면 캘린더를 접고 펼칠 수 있다', (tester) async {
    final today = DateTime.now();
    await saveTrainingEntry(
      tester,
      TrainingEntry(
        date: DateTime(today.year, today.month, today.day, 7),
        durationMinutes: 45,
        intensity: 3,
        type: '슛',
        mood: 3,
        injury: false,
        notes: '',
        location: '',
      ),
    );

    await pumpCalendar(tester);

    expect(find.byType(TableCalendar<TrainingEntry>), findsOneWidget);
    expect(find.text('캘린더 접기'), findsOneWidget);

    await tester.tap(find.text('캘린더 접기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TableCalendar<TrainingEntry>), findsNothing);
    expect(find.text('캘린더 펼치기'), findsOneWidget);
  });

  testWidgets('기록이 없으면 저장된 상태와 무관하게 캘린더를 펼쳐둔다', (tester) async {
    await setOptionValue(tester, 'calendar_expanded_v1', false);

    await pumpCalendar(tester);

    expect(find.byType(TableCalendar<TrainingEntry>), findsOneWidget);
    expect(find.text('캘린더 접기'), findsOneWidget);

    await tester.tap(find.text('캘린더 접기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TableCalendar<TrainingEntry>), findsOneWidget);
    expect(find.text('캘린더 접기'), findsOneWidget);
    expect(find.text('캘린더 펼치기'), findsNothing);
  });

  testWidgets('경기 기록은 승패와 상대 팀 결과를 캘린더 목록에 보여준다', (tester) async {
    final today = DateTime.now();
    await saveTrainingEntry(
      tester,
      TrainingEntry(
        date: DateTime(today.year, today.month, today.day, 9),
        durationMinutes: 90,
        intensity: 4,
        type: '경기',
        mood: 4,
        injury: false,
        notes: '',
        location: '메인 구장',
        program: '경기',
        club: '라이벌 FC',
        opponentTeam: '라이벌 FC',
        scoredGoals: 3,
        concededGoals: 2,
        playerGoals: 1,
        playerAssists: 2,
        shotsOnTarget: 4,
        ballsWon: 7,
        minutesPlayed: 70,
        matchLocation: '메인 구장',
      ),
    );

    await pumpCalendar(tester);

    expect(find.textContaining('승 · vs 라이벌 FC'), findsOneWidget);
    expect(find.textContaining('vs 라이벌 FC'), findsOneWidget);
    expect(find.textContaining('메인 구장'), findsOneWidget);
    expect(find.textContaining('결과 3:2'), findsOneWidget);
    expect(find.textContaining('골 1'), findsOneWidget);
    expect(find.textContaining('어시스트 2'), findsOneWidget);
    expect(find.textContaining('유효 슈팅 4'), findsOneWidget);
    expect(find.textContaining('공을 뺏은 횟수 7'), findsOneWidget);
    expect(find.textContaining('출전 70분'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
  });

  testWidgets('부모 모드에서도 캘린더 훈련 리스트 탭이 기록 화면으로 이어진다', (tester) async {
    final today = DateTime.now();
    TrainingEntry? editedEntry;
    await setOptionValue(
      tester,
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );
    await saveTrainingEntry(
      tester,
      TrainingEntry(
        date: DateTime(today.year, today.month, today.day, 7),
        durationMinutes: 45,
        intensity: 3,
        type: '드리블',
        mood: 3,
        injury: false,
        notes: '퍼스트 터치\n[날씨] 흐림 18°C',
        location: '학교 운동장',
        program: '드리블',
        trainingProgramMinutes: const {'드리블': 30, '패스': 15},
      ),
    );

    await pumpCalendar(tester, onEdit: (entry) => editedEntry = entry);

    expect(find.text('드리블, 패스 · 45분'), findsOneWidget);
    expect(find.textContaining('줄넘기/리프팅 기록 없음 · 흐림 18°C'), findsOneWidget);
    expect(find.textContaining('학교 운동장'), findsNothing);

    await tester.tap(find.text('드리블, 패스 · 45분'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(editedEntry, isNotNull);
    expect(editedEntry!.type, '드리블');
  });

  testWidgets('부모 모드에서도 캘린더 시합 리스트 탭이 읽기 전용 화면을 연다', (tester) async {
    final today = DateTime.now();
    await setOptionValue(
      tester,
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );
    await saveTrainingEntry(
      tester,
      TrainingEntry(
        date: DateTime(today.year, today.month, today.day, 9),
        durationMinutes: 90,
        intensity: 4,
        type: '경기',
        mood: 4,
        injury: false,
        notes: '시합 메모',
        location: '메인 구장',
        program: '경기',
        club: '라이벌 FC',
        opponentTeam: '라이벌 FC',
        scoredGoals: 3,
        concededGoals: 2,
        playerGoals: 1,
        playerAssists: 2,
        shotsOnTarget: 4,
        ballsWon: 7,
        minutesPlayed: 70,
        matchLocation: '메인 구장',
      ),
    );

    await pumpCalendar(tester);

    await tester.tap(find.textContaining('vs 라이벌 FC').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('시합 보기'), findsOneWidget);
    expect(find.text('유효 슈팅'), findsWidgets);
    expect(find.text('공을 뺏은 횟수'), findsWidgets);
    expect(find.widgetWithText(FilledButton, '저장'), findsNothing);
  });

  testWidgets('캘린더 기록 추가 버튼은 아이콘만 표시하고 훈련 노트 메뉴를 연다', (tester) async {
    await pumpCalendar(tester);

    expect(find.text('기록 추가'), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('훈련 노트'), findsOneWidget);
    expect(find.text('식사 기록'), findsOneWidget);
    expect(find.text('훈련 계획'), findsOneWidget);
    expect(find.text('시합'), findsOneWidget);
  });

  testWidgets('친선 경기 결과는 버튼 클릭으로 점수를 저장한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    Future<void> tapTooltip(String tooltip) async {
      final button = find.byTooltip(tooltip);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
    }

    await pumpCalendar(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('시합'));
    await tester.pumpAndSettle();

    expect(find.text('경기 결과'), findsOneWidget);

    await tester.enterText(
      find
          .ancestor(of: find.text('상대 팀'), matching: find.byType(TextField))
          .first,
      '그린 FC',
    );
    await tester.tap(find.widgetWithText(ChoiceChip, '승'));
    await tester.pump();
    await tapTooltip('골 늘리기');
    await tapTooltip('골 늘리기');
    await tapTooltip('골 줄이기');
    await tapTooltip('어시스트 늘리기');
    await tapTooltip('유효 슈팅 늘리기');
    await tapTooltip('유효 슈팅 늘리기');
    await tapTooltip('공을 뺏은 횟수 늘리기');

    final saveButton = find.widgetWithText(FilledButton, '저장');
    await tester.ensureVisible(saveButton);
    await tester.pump();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final entries = await trainingService.allEntries();
    expect(entries, hasLength(1));
    expect(entries.single.matchKind, 'friendly');
    expect(entries.single.scoredGoals, 1);
    expect(entries.single.concededGoals, 0);
    expect(entries.single.playerGoals, 1);
    expect(entries.single.playerAssists, 1);
    expect(entries.single.shotsOnTarget, 2);
    expect(entries.single.ballsWon, 1);
    expect(find.textContaining('승 · vs 그린 FC'), findsOneWidget);
    expect(find.textContaining('결과 1:0'), findsOneWidget);
    expect(find.textContaining('골 1'), findsOneWidget);
    expect(find.textContaining('어시스트 1'), findsOneWidget);
    expect(find.textContaining('유효 슈팅 2'), findsOneWidget);
    expect(find.textContaining('공을 뺏은 횟수 1'), findsOneWidget);
  });

  testWidgets('토너먼트 시합 기록은 별도 유형과 승수를 저장한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await pumpCalendar(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('시합'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('토너먼트'));
    await tester.pump();

    await tester.enterText(
      find
          .ancestor(
              of: find.text('대회 이름'), matching: find.byType(TextFormField))
          .first,
      '봄 컵',
    );
    await tester.tap(find.text('예선').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('8강').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('진행 중').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음 라운드 진출').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find
          .ancestor(of: find.text('상대 팀'), matching: find.byType(TextField))
          .first,
      '레드 FC',
    );
    await tester.enterText(
      find
          .ancestor(
            of: find.text('토너먼트 팀'),
            matching: find.byType(TextFormField),
          )
          .first,
      '레드 FC, 블루 FC',
    );
    await tester.enterText(
      find
          .ancestor(
            of: find.text('토너먼트 승리'),
            matching: find.byType(TextFormField),
          )
          .first,
      '2',
    );
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, '승'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, '승'));
    await tester.pump();

    final saveButton = find.widgetWithText(FilledButton, '저장');
    await tester.ensureVisible(saveButton);
    await tester.pump();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final entries = await trainingService.allEntries();
    expect(entries, hasLength(1));
    expect(entries.single.matchKind, 'tournament');
    expect(entries.single.isTournamentMatch, isTrue);
    expect(entries.single.leagueTeamNames, <String>['레드 FC', '블루 FC']);
    expect(entries.single.matchCompetitionName, '봄 컵');
    expect(entries.single.matchStage, 'quarterfinal');
    expect(entries.single.tournamentOutcome, 'advanced');
    expect(entries.single.tournamentWins, 2);
    expect(entries.single.scoredGoals, 1);
    expect(entries.single.concededGoals, 0);
    expect(find.textContaining('토너먼트'), findsWidgets);
    expect(find.textContaining('봄 컵'), findsOneWidget);
    expect(find.textContaining('8강'), findsOneWidget);
    expect(find.textContaining('다음 라운드 진출'), findsOneWidget);
    expect(find.textContaining('결과 1:0'), findsOneWidget);
    expect(find.textContaining('2승'), findsOneWidget);
  });

  testWidgets('리그 시합 기록은 라운드와 승점 중심으로 저장한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await pumpCalendar(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('시합'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('리그 경기'));
    await tester.pump();

    await tester.enterText(
      find
          .ancestor(
              of: find.text('대회 이름'), matching: find.byType(TextFormField))
          .first,
      '주말 리그',
    );
    await tester.enterText(
      find
          .ancestor(
              of: find.text('라운드/주차'), matching: find.byType(TextFormField))
          .first,
      '3라운드',
    );
    await tester.enterText(
      find
          .ancestor(of: find.text('상대 팀'), matching: find.byType(TextField))
          .first,
      '블루 FC',
    );
    await tester.enterText(
      find
          .ancestor(of: find.text('리그 팀'), matching: find.byType(TextFormField))
          .first,
      '레드 FC, 블루 FC, 그린 FC',
    );
    await tester.enterText(
      find
          .ancestor(of: find.text('승점'), matching: find.byType(TextFormField))
          .first,
      '3',
    );
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, '무'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, '무'));
    await tester.pump();

    final saveButton = find.widgetWithText(FilledButton, '저장');
    await tester.ensureVisible(saveButton);
    await tester.pump();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final entries = await trainingService.allEntries();
    expect(entries, hasLength(1));
    expect(entries.single.matchKind, 'league');
    expect(entries.single.isLeagueMatch, isTrue);
    expect(entries.single.matchCompetitionName, '주말 리그');
    expect(entries.single.matchStage, '3라운드');
    expect(entries.single.leagueTeamNames, <String>[
      '레드 FC',
      '블루 FC',
      '그린 FC',
    ]);
    expect(entries.single.leaguePoints, 3);
    expect(entries.single.scoredGoals, 1);
    expect(entries.single.concededGoals, 1);
    expect(find.textContaining('리그 경기'), findsWidgets);
    expect(find.textContaining('주말 리그'), findsOneWidget);
    expect(find.textContaining('3라운드'), findsOneWidget);
    expect(find.textContaining('결과 1:1'), findsOneWidget);
    expect(find.textContaining('승점 3'), findsOneWidget);
  });

  testWidgets('리그 대회 관리 시트는 등록 팀 순위를 보여준다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    final today = DateTime.now();
    await saveTrainingEntry(
      tester,
      TrainingEntry(
        date: DateTime(today.year, today.month, today.day, 9),
        durationMinutes: 90,
        intensity: 4,
        type: '경기',
        mood: 4,
        injury: false,
        notes: '',
        location: '',
        matchKind: MatchCompetitionRecord.kindLeague,
        matchCompetitionName: '주말 리그',
        opponentTeam: '블루 FC',
        leagueTeamNames: const <String>['레드 FC', '블루 FC', '그린 FC'],
        scoredGoals: 2,
        concededGoals: 1,
        leaguePoints: 3,
      ),
    );

    await pumpCalendar(tester);

    await tester.tap(find.textContaining('주말 리그').first);
    await tester.pumpAndSettle();

    final manageButton = find.text('팀 등록/결과 보기');
    await tester.ensureVisible(manageButton);
    await tester.tap(manageButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('결과 보기'));
    await tester.pumpAndSettle();

    expect(find.text('리그 순위'), findsOneWidget);
    expect(find.text('레드 FC'), findsWidgets);
    expect(find.text('블루 FC'), findsWidgets);
    expect(find.text('그린 FC'), findsWidgets);
    expect(find.text('승점'), findsWidgets);
  });

  testWidgets('대회 관리 시트는 저장하지 않고 뒤로 돌아갈 수 있다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    final today = DateTime.now();
    await saveTrainingEntry(
      tester,
      TrainingEntry(
        date: DateTime(today.year, today.month, today.day, 9),
        durationMinutes: 90,
        intensity: 4,
        type: '경기',
        mood: 4,
        injury: false,
        notes: '',
        location: '',
        matchKind: MatchCompetitionRecord.kindLeague,
        matchCompetitionName: '주말 리그',
        opponentTeam: '블루 FC',
        leagueTeamNames: const <String>['레드 FC', '블루 FC'],
      ),
    );

    await pumpCalendar(tester);

    await tester.tap(find.textContaining('주말 리그').first);
    await tester.pumpAndSettle();

    final manageButton = find.text('팀 등록/결과 보기');
    await tester.ensureVisible(manageButton);
    await tester.tap(manageButton);
    await tester.pumpAndSettle();

    expect(find.text('팀 미리보기'), findsOneWidget);
    expect(find.text('뒤로'), findsOneWidget);

    await tester.tap(find.text('뒤로'));
    await tester.pumpAndSettle();

    expect(find.text('팀 미리보기'), findsNothing);
    expect(find.text('시합 수정'), findsOneWidget);
  });

  testWidgets('대회 관리 시트는 팀을 하나씩 추가하고 삭제해 저장한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    final today = DateTime.now();
    await saveTrainingEntry(
      tester,
      TrainingEntry(
        date: DateTime(today.year, today.month, today.day, 9),
        durationMinutes: 90,
        intensity: 4,
        type: '경기',
        mood: 4,
        injury: false,
        notes: '',
        location: '',
        matchKind: MatchCompetitionRecord.kindLeague,
        matchCompetitionName: '주말 리그',
        opponentTeam: '블루 FC',
      ),
    );

    await pumpCalendar(tester);

    await tester.tap(find.textContaining('주말 리그').first);
    await tester.pumpAndSettle();

    final manageButton = find.text('팀 등록/결과 보기');
    await tester.ensureVisible(manageButton);
    await tester.tap(manageButton);
    await tester.pumpAndSettle();

    final teamField = find
        .ancestor(of: find.text('팀 이름'), matching: find.byType(TextFormField))
        .first;
    await tester.enterText(teamField, '레드 FC');
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();
    await tester.enterText(teamField, '블루 FC');
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();

    expect(find.text('레드 FC'), findsWidgets);
    expect(find.text('블루 FC'), findsWidgets);
    expect(find.text('2개 팀 등록됨'), findsOneWidget);

    await tester.tap(find.byTooltip('레드 FC 삭제'));
    await tester.pumpAndSettle();
    expect(find.text('레드 FC'), findsNothing);
    expect(find.text('블루 FC'), findsWidgets);
    expect(find.text('1개 팀 등록됨'), findsOneWidget);

    await tester.tap(find.text('팀 저장'));
    await tester.pumpAndSettle();

    final savedCompetition = MatchCompetitionService(
      optionRepository,
    ).findCompetition(
      kind: MatchCompetitionRecord.kindLeague,
      name: '주말 리그',
    );
    expect(savedCompetition?.teams, <String>['블루 FC']);
  });

  testWidgets('토너먼트 대회 관리 시트는 등록 팀 대진표를 보여준다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await MatchCompetitionService(optionRepository).upsertCompetition(
      MatchCompetitionRecord.create(
        kind: MatchCompetitionRecord.kindTournament,
        name: '봄 컵',
        teams: const <String>['레드 FC', '블루 FC', '그린 FC'],
      ),
    );
    final today = DateTime.now();
    await saveTrainingEntry(
      tester,
      TrainingEntry(
        date: DateTime(today.year, today.month, today.day, 9),
        durationMinutes: 90,
        intensity: 4,
        type: '경기',
        mood: 4,
        injury: false,
        notes: '',
        location: '',
        matchKind: MatchCompetitionRecord.kindTournament,
        matchCompetitionName: '봄 컵',
        matchStage: 'quarterfinal',
        tournamentOutcome: 'advanced',
        opponentTeam: '블루 FC',
      ),
    );

    await pumpCalendar(tester);

    await tester.tap(find.textContaining('봄 컵').first);
    await tester.pumpAndSettle();

    final manageButton = find.text('팀 등록/결과 보기');
    await tester.ensureVisible(manageButton);
    await tester.tap(manageButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('결과 보기'));
    await tester.pumpAndSettle();

    expect(find.text('토너먼트 대진표'), findsOneWidget);
    expect(find.text('1경기'), findsOneWidget);
    expect(find.text('레드 FC vs 블루 FC'), findsOneWidget);
    expect(find.text('2경기'), findsOneWidget);
    expect(find.text('그린 FC vs 부전승'), findsOneWidget);
    expect(find.text('기록된 진행'), findsOneWidget);
    expect(find.text('8강 · 블루 FC전 · 다음 라운드 진출'), findsOneWidget);
  });

  testWidgets('독립 식사 기록은 선택한 날짜 타임라인에 표시된다', (tester) async {
    final today = DateTime.now();
    await saveMealEntry(
      tester,
      MealEntry(
        date: DateTime(today.year, today.month, today.day),
        breakfastRiceBowls: 1,
        lunchRiceBowls: 0.5,
        dinnerRiceBowls: 1,
      ),
    );

    await pumpCalendar(tester);

    expect(find.text('식사 기록'), findsWidgets);
    expect(find.textContaining('아침 1공기'), findsOneWidget);
  });

  testWidgets('캘린더 상단바는 홈과 동일하게 다이어리 버튼을 숨긴다', (tester) async {
    await pumpCalendar(tester);

    expect(find.byTooltip('다이어리'), findsNothing);
  });

  testWidgets('캘린더 상단 컨트롤이 기간 전환과 오늘 이동을 보여준다', (tester) async {
    await pumpCalendar(tester);

    expect(find.text('2주'), findsOneWidget);
    expect(find.text('1개월'), findsOneWidget);
    expect(find.text('오늘'), findsOneWidget);
  });

  testWidgets('계획 마커는 유지하고 파란 마커는 시합이 있는 날에만 표시한다', (tester) async {
    final today = DateTime.now();
    await saveTrainingEntry(
      tester,
      TrainingEntry(
        date: DateTime(today.year, today.month, today.day, 7),
        durationMinutes: 45,
        intensity: 3,
        type: '패스',
        mood: 3,
        injury: false,
        notes: '',
        location: '',
      ),
    );
    await saveTrainingEntry(
      tester,
      TrainingEntry(
        date: DateTime(today.year, today.month, today.day, 18),
        durationMinutes: 90,
        intensity: 4,
        type: '시합',
        mood: 4,
        injury: false,
        notes: '',
        location: '주 경기장',
        opponentTeam: '블루 FC',
        scoredGoals: 2,
        concededGoals: 1,
        matchLocation: '주 경기장',
      ),
    );
    await setOptionValue(
      tester,
      'training_plans_v1',
      jsonEncode([
        {
          'id': 'series_1',
          'scheduledAt': DateTime(
            today.year,
            today.month,
            today.day,
            18,
          ).toIso8601String(),
          'category': '슛',
          'durationMinutes': 60,
          'reminderMinutesBefore': 30,
          'repeatWeekdays': [today.weekday],
          'alarmLoopEnabled': false,
          'note': '',
          'seriesId': 'series',
          'seriesStartDate': DateTime(
            today.year,
            today.month,
            today.day,
          ).toIso8601String(),
          'seriesEndDate': DateTime(
            today.year,
            today.month,
            today.day,
          ).toIso8601String(),
        },
      ]),
    );

    await pumpCalendar(tester);

    expect(
      find.byKey(ValueKey('calendar_day_match_marker_${today.day}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('calendar_day_plan_marker_${today.day}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('calendar_day_training_marker_${today.day}')),
      findsOneWidget,
    );
  });

  testWidgets('훈련 기록만 있는 날에는 파란 마커를 표시하지 않는다', (tester) async {
    final today = DateTime.now();
    await saveTrainingEntry(
      tester,
      TrainingEntry(
        date: DateTime(today.year, today.month, today.day, 7),
        durationMinutes: 45,
        intensity: 3,
        type: '패스',
        mood: 3,
        injury: false,
        notes: '',
        location: '',
      ),
    );

    await pumpCalendar(tester);

    expect(
      find.byKey(ValueKey('calendar_day_match_marker_${today.day}')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('calendar_day_training_marker_${today.day}')),
      findsOneWidget,
    );
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    return value is List<String>
        ? List<String>.of(value)
        : List<String>.of(defaults);
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    return value is List<int> ? List<int>.of(value) : List<int>.of(defaults);
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

class _MemoryTrainingRepository implements TrainingRepository {
  final List<TrainingEntry> _entries = <TrainingEntry>[];
  final StreamController<List<TrainingEntry>> _controller =
      StreamController<List<TrainingEntry>>.broadcast();

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
      List<TrainingEntry>.of(_entries);

  @override
  Future<List<TrainingEntry>> getRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) async =>
      _rangeEntries(startInclusive, endExclusive);

  @override
  Future<List<TrainingEntry>> getRecent({
    required int limit,
    bool includeMatches = true,
    String? sportId,
  }) async =>
      _recentEntries(
        limit: limit,
        includeMatches: includeMatches,
        sportId: sportId,
      );

  @override
  Future<void> update(int key, TrainingEntry entry) async {
    if (key < 0 || key >= _entries.length) return;
    _entries[key] = entry;
    _emit();
  }

  @override
  Stream<List<TrainingEntry>> watchAll() async* {
    yield List<TrainingEntry>.of(_entries);
    yield* _controller.stream.map((_) => List<TrainingEntry>.of(_entries));
  }

  @override
  Stream<List<TrainingEntry>> watchRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) async* {
    yield _rangeEntries(startInclusive, endExclusive);
    yield* _controller.stream.map(
      (_) => _rangeEntries(startInclusive, endExclusive),
    );
  }

  @override
  Stream<List<TrainingEntry>> watchRecent({
    required int limit,
    bool includeMatches = true,
    String? sportId,
  }) async* {
    yield _recentEntries(
      limit: limit,
      includeMatches: includeMatches,
      sportId: sportId,
    );
    yield* _controller.stream.map(
      (_) => _recentEntries(
        limit: limit,
        includeMatches: includeMatches,
        sportId: sportId,
      ),
    );
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
