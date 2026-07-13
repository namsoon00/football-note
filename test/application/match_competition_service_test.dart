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

  test('토너먼트 대진표는 등록 순서대로 짝을 만들고 홀수 팀은 부전승 처리한다', () {
    final pairs = MatchCompetitionService.buildTournamentBracketPairs(
      const <String>['레드 FC', '블루 FC', '그린 FC'],
    );

    expect(pairs, hasLength(2));
    expect(pairs.first.teamA, '레드 FC');
    expect(pairs.first.teamB, '블루 FC');
    expect(pairs.last.teamA, '그린 FC');
    expect(pairs.last.hasBye, isTrue);
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
