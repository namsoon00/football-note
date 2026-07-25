import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/match_competition_service.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/option_repository.dart';

void main() {
  test('대회 팀 등록 정보를 옵션 저장소에 갱신한다', () async {
    final repository = _MemoryOptionRepository();
    final service = MatchCompetitionService(repository);

    await service.upsertCompetition(
      MatchCompetitionRecord.create(
        kind: MatchCompetitionRecord.kindLeague,
        name: '주말 리그',
        teams: const <String>['레드 FC', '블루 FC'],
      ),
    );
    await service.upsertCompetition(
      MatchCompetitionRecord.create(
        kind: MatchCompetitionRecord.kindLeague,
        name: '주말 리그',
        teams: const <String>['레드 FC', '그린 FC'],
      ),
    );

    final competitions = service.allCompetitions();
    expect(competitions, hasLength(1));
    expect(competitions.single.name, '주말 리그');
    expect(competitions.single.teams, <String>['레드 FC', '그린 FC']);
    expect(competitions.single.status, MatchCompetitionRecord.statusActive);
    expect(
      service
          .findCompetition(
            kind: MatchCompetitionRecord.kindLeague,
            name: '주말 리그',
          )
          ?.teams,
      <String>['레드 FC', '그린 FC'],
    );
  });

  test('대회 상태는 저장하고 진행 중 대회를 먼저 정렬한다', () async {
    final repository = _MemoryOptionRepository();
    final service = MatchCompetitionService(repository);

    await service.upsertCompetition(
      MatchCompetitionRecord.create(
        kind: MatchCompetitionRecord.kindLeague,
        name: '종료 리그',
        teams: const <String>['레드 FC'],
        status: MatchCompetitionRecord.statusFinished,
      ),
    );
    await service.upsertCompetition(
      MatchCompetitionRecord.create(
        kind: MatchCompetitionRecord.kindLeague,
        name: '진행 리그',
        teams: const <String>['블루 FC'],
      ),
    );

    final leagues = service.competitionsForKind(
      MatchCompetitionRecord.kindLeague,
    );

    expect(leagues.map((record) => record.name), <String>[
      '진행 리그',
      '종료 리그',
    ]);
    expect(leagues.first.status, MatchCompetitionRecord.statusActive);
    expect(leagues.last.status, MatchCompetitionRecord.statusFinished);
  });

  test('종료된 대회는 경기 기록으로 갱신해도 종료 상태를 유지한다', () async {
    final repository = _MemoryOptionRepository();
    final service = MatchCompetitionService(repository);

    await service.upsertCompetition(
      MatchCompetitionRecord.create(
        kind: MatchCompetitionRecord.kindTournament,
        name: '봄 컵',
        teams: const <String>['레드 FC'],
        status: MatchCompetitionRecord.statusFinished,
      ),
    );
    await service.upsertFromEntry(
      TrainingEntry(
        date: DateTime(2026, 6, 1),
        durationMinutes: 90,
        intensity: 4,
        type: '경기',
        mood: 4,
        injury: false,
        notes: '',
        location: '',
        matchKind: MatchCompetitionRecord.kindTournament,
        matchCompetitionName: '봄 컵',
        opponentTeam: '블루 FC',
        leagueTeamNames: const <String>['블루 FC'],
      ),
    );

    final competition = service.findCompetition(
      kind: MatchCompetitionRecord.kindTournament,
      name: '봄 컵',
    );

    expect(competition?.status, MatchCompetitionRecord.statusFinished);
    expect(competition?.teams, <String>['레드 FC', '블루 FC']);
  });

  test('등록되지 않은 토너먼트 기록은 저장 대회를 새로 만들지 않는다', () async {
    final repository = _MemoryOptionRepository();
    final service = MatchCompetitionService(repository);

    await service.upsertFromEntry(
      TrainingEntry(
        date: DateTime(2026, 6, 1),
        durationMinutes: 90,
        intensity: 4,
        type: '경기',
        mood: 4,
        injury: false,
        notes: '',
        location: '',
        matchKind: MatchCompetitionRecord.kindTournament,
        matchCompetitionName: '여름 컵',
        opponentTeam: '블루 FC',
      ),
    );

    final tournaments = service.competitionsForKind(
      MatchCompetitionRecord.kindTournament,
    );

    expect(tournaments, isEmpty);
  });

  test('리그 순위는 등록 팀과 기록 결과를 합쳐 승점 순으로 계산한다', () {
    final entries = <TrainingEntry>[
      TrainingEntry(
        date: DateTime(2026, 6, 1),
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
      TrainingEntry(
        date: DateTime(2026, 6, 8),
        durationMinutes: 90,
        intensity: 4,
        type: '경기',
        mood: 4,
        injury: false,
        notes: '',
        location: '',
        matchKind: MatchCompetitionRecord.kindLeague,
        matchCompetitionName: '주말 리그',
        opponentTeam: '그린 FC',
        scoredGoals: 1,
        concededGoals: 1,
      ),
    ];

    final standings = MatchCompetitionService.buildLeagueStandings(
      competitionName: '주말 리그',
      registeredTeams: const <String>['레드 FC', '블루 FC', '그린 FC'],
      entries: entries,
      ownTeamName: '우리 팀',
    );

    expect(standings.map((row) => row.team), <String>[
      '레드 FC',
      '그린 FC',
      '블루 FC',
    ]);
    expect(standings.first.points, 4);
    expect(standings.first.played, 2);
    expect(standings.first.wins, 1);
    expect(standings.first.draws, 1);
    expect(standings[1].points, 1);
    expect(standings[2].points, 0);
  });

  test('토너먼트 대진표는 시드 순서에 따라 상위 시드에 부전승을 배정한다', () {
    final pairs = MatchCompetitionService.buildTournamentBracketPairs(
      const <String>['레드 FC', '블루 FC', '그린 FC'],
    );

    expect(pairs, hasLength(2));
    expect(pairs.first.teamA, '레드 FC');
    expect(pairs.first.seedA, 1);
    expect(pairs.first.hasBye, isTrue);
    expect(pairs.last.teamA, '블루 FC');
    expect(pairs.last.teamB, '그린 FC');
  });

  test('전체 토너먼트 대진표는 모든 라운드와 이전 경기 출처를 만든다', () {
    final bracket = MatchCompetitionService.buildTournamentBracket(
      const <String>['A', 'B', 'C', 'D', 'E', 'F'],
    );

    expect(bracket.slotCount, 8);
    expect(bracket.rounds.map((round) => round.teamCapacity), [8, 4, 2]);
    expect(bracket.rounds.map((round) => round.matches.length), [4, 2, 1]);
    expect(bracket.rounds.first.matches.first.teamA, 'A');
    expect(bracket.rounds.first.matches.first.hasBye, isTrue);
    expect(bracket.rounds[1].matches.first.sourceMatchA, 1);
    expect(bracket.rounds[1].matches.first.sourceMatchB, 2);
    expect(bracket.rounds.last.matches.single.slotNumber, 7);
  });

  test('팀관리의 팀명을 리그 기준 팀으로 사용하고 이전 기본 이름을 합친다', () {
    final entries = <TrainingEntry>[
      TrainingEntry(
        date: DateTime(2026, 7, 1),
        durationMinutes: 90,
        intensity: 4,
        type: '경기',
        mood: 4,
        injury: false,
        notes: '',
        location: '',
        matchKind: MatchCompetitionRecord.kindLeague,
        matchCompetitionName: '여름 리그',
        opponentTeam: '블루 FC',
        leagueTeamNames: const <String>['우리 팀', '블루 FC'],
        scoredGoals: 2,
        concededGoals: 0,
        leaguePoints: 3,
      ),
    ];

    final standings = MatchCompetitionService.buildLeagueStandings(
      competitionName: '여름 리그',
      registeredTeams: const <String>['우리 팀', '블루 FC'],
      entries: entries,
      ownTeamName: '남순 FC',
      preferOwnTeamName: true,
      ownTeamAliases: const <String>['우리 팀'],
    );

    expect(standings.map((row) => row.team), <String>['남순 FC', '블루 FC']);
    expect(standings.first.points, 3);
    expect(standings.first.wins, 1);
  });

  test('대회 유형에 맞춰 팀관리 팀명을 참가 팀과 시드에 반영한다', () {
    final leagueTeams = MatchCompetitionService.teamsWithManagedTeam(
      kind: MatchCompetitionRecord.kindLeague,
      teams: const <String>['우리 팀', '블루 FC'],
      managedTeamName: '남순 FC',
      fallbackTeamName: '우리 팀',
      replaceLeagueFirstTeam: true,
    );
    final tournamentTeams = MatchCompetitionService.teamsWithManagedTeam(
      kind: MatchCompetitionRecord.kindTournament,
      teams: const <String>['레드 FC', '우리 팀', '블루 FC'],
      managedTeamName: '남순 FC',
      fallbackTeamName: '우리 팀',
    );

    expect(leagueTeams, <String>['남순 FC', '블루 FC']);
    expect(tournamentTeams, <String>['레드 FC', '남순 FC', '블루 FC']);
  });

  test('리그를 저장하면 모든 팀 조합의 경기 일정이 자동으로 편성된다', () async {
    final repository = _MemoryOptionRepository();
    final service = MatchCompetitionService(repository);
    final record = MatchCompetitionRecord.create(
      kind: MatchCompetitionRecord.kindLeague,
      name: '여름 리그',
      teams: const <String>['우리 팀', '블루 FC', '그린 FC', '레드 FC'],
      fixtureStartDate: DateTime(2026, 8, 1),
    );

    await service.upsertCompetition(record);

    final saved = service.findCompetitionById(record.id)!;
    expect(saved.fixtures, hasLength(6));
    expect(saved.fixtures.map((fixture) => fixture.roundNumber).toSet(),
        <int>{1, 2, 3});
    expect(
      saved.fixtures
          .map(
            (fixture) =>
                ([fixture.homeTeam, fixture.awayTeam]..sort()).join('|'),
          )
          .toSet(),
      hasLength(6),
    );
    expect(saved.fixtures.first.scheduledAt, DateTime(2026, 8, 1));
  });

  test('토너먼트 결과를 기록하면 다음 경기 참가 팀이 대진표에 진출한다', () {
    final record = MatchCompetitionRecord.create(
      kind: MatchCompetitionRecord.kindTournament,
      name: '여름 컵',
      teams: const <String>['우리 팀', '블루 FC', '그린 FC'],
    ).copyWith();
    final scheduled = record.copyWith(
      fixtures: MatchCompetitionService.buildFixtures(record),
    );
    final preliminary = scheduled.fixtures.firstWhere(
      (fixture) =>
          fixture.stage != 'final' &&
          fixture.homeTeam.isNotEmpty &&
          fixture.awayTeam.isNotEmpty,
    );
    final finalFixture = scheduled.fixtures.firstWhere(
      (fixture) => fixture.stage == 'final',
    );
    final entries = <TrainingEntry>[
      _matchEntry(
        kind: MatchCompetitionRecord.kindTournament,
        competitionName: scheduled.name,
        competitionId: scheduled.id,
        fixtureId: preliminary.id,
        stage: preliminary.stage,
        opponent: preliminary.awayTeam,
        scored: 2,
        conceded: 0,
      ),
    ];

    final states = MatchCompetitionService.resolveFixtureStates(
      competition: scheduled,
      entries: entries,
    );
    final resolvedFinal = states.firstWhere(
      (state) => state.fixture.id == finalFixture.id,
    );

    expect(resolvedFinal.homeTeam, '우리 팀');
    expect(resolvedFinal.awayTeam, preliminary.homeTeam);
    expect(resolvedFinal.isReady, isTrue);
  });

  test('경기 일정 ID의 결과만 리그 순위에 반영한다', () {
    final base = MatchCompetitionRecord.create(
      kind: MatchCompetitionRecord.kindLeague,
      name: '가을 리그',
      teams: const <String>['우리 팀', '블루 FC'],
    );
    final record = base.copyWith(
      fixtures: MatchCompetitionService.buildFixtures(base),
    );
    final fixture = record.fixtures.single;
    final standings =
        MatchCompetitionService.buildLeagueStandingsForCompetition(
      competition: record,
      entries: [
        _matchEntry(
          kind: MatchCompetitionRecord.kindLeague,
          competitionName: record.name,
          competitionId: record.id,
          fixtureId: fixture.id,
          stage: fixture.stage,
          opponent: fixture.awayTeam,
          scored: 3,
          conceded: 1,
        ),
      ],
    );

    expect(standings.first.team, fixture.homeTeam);
    expect(standings.first.points, 3);
    expect(standings.last.team, fixture.awayTeam);
    expect(standings.last.points, 0);
  });

  test('기존 기본 팀명도 현재 팀명의 예정 경기 목록에서 조회한다', () {
    final base = MatchCompetitionRecord.create(
      kind: MatchCompetitionRecord.kindLeague,
      name: '호환 리그',
      teams: const <String>['우리 팀', '블루 FC'],
    );
    final record = base.copyWith(
      fixtures: MatchCompetitionService.buildFixtures(base),
    );

    final fixtures = MatchCompetitionService.fixturesForTeam(
      competitions: [record],
      entries: const <TrainingEntry>[],
      teamName: '남순 FC',
      teamAliases: const <String>['우리 팀'],
    );

    expect(fixtures, hasLength(1));
    expect(fixtures.single.opponentFor('우리 팀'), '블루 FC');
  });
}

TrainingEntry _matchEntry({
  required String kind,
  required String competitionName,
  required String competitionId,
  required String fixtureId,
  required String stage,
  required String opponent,
  required int scored,
  required int conceded,
}) {
  return TrainingEntry(
    date: DateTime(2026, 8, 1),
    durationMinutes: 90,
    intensity: 4,
    type: '경기',
    mood: 4,
    injury: false,
    notes: '',
    location: '',
    matchKind: kind,
    matchCompetitionName: competitionName,
    matchCompetitionId: competitionId,
    matchFixtureId: fixtureId,
    matchStage: stage,
    opponentTeam: opponent,
    scoredGoals: scored,
    concededGoals: conceded,
  );
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
