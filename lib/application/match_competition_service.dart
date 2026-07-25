import 'dart:convert';

import '../domain/entities/training_entry.dart';
import '../domain/repositories/option_repository.dart';
import 'sport_scoped_storage.dart';

class MatchCompetitionRecord {
  static const String kindLeague = 'league';
  static const String kindTournament = 'tournament';
  static const String statusActive = 'active';
  static const String statusFinished = 'finished';

  final String id;
  final String kind;
  final String name;
  final List<String> teams;
  final String status;
  final String season;
  final String venue;
  final String organizer;
  final String note;
  final int leagueLegs;
  final DateTime? fixtureStartDate;
  final int fixtureIntervalDays;
  final List<CompetitionFixture> fixtures;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MatchCompetitionRecord({
    required this.id,
    required this.kind,
    required this.name,
    required this.teams,
    this.status = statusActive,
    this.season = '',
    this.venue = '',
    this.organizer = '',
    this.note = '',
    this.leagueLegs = 1,
    this.fixtureStartDate,
    this.fixtureIntervalDays = 7,
    this.fixtures = const <CompetitionFixture>[],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isFinished => status == statusFinished;

  factory MatchCompetitionRecord.create({
    required String kind,
    required String name,
    required List<String> teams,
    String status = statusActive,
    String season = '',
    String venue = '',
    String organizer = '',
    String note = '',
    int leagueLegs = 1,
    DateTime? fixtureStartDate,
    int fixtureIntervalDays = 7,
    List<CompetitionFixture> fixtures = const <CompetitionFixture>[],
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return MatchCompetitionRecord(
      id: MatchCompetitionService.competitionId(kind: kind, name: name),
      kind: kind,
      name: name.trim(),
      teams: MatchCompetitionService.normalizeTeams(teams),
      status: MatchCompetitionService.normalizeStatus(status),
      season: season.trim(),
      venue: venue.trim(),
      organizer: organizer.trim(),
      note: note.trim(),
      leagueLegs: MatchCompetitionService.normalizeLeagueLegs(leagueLegs),
      fixtureStartDate: fixtureStartDate,
      fixtureIntervalDays:
          MatchCompetitionService.normalizeFixtureInterval(fixtureIntervalDays),
      fixtures: MatchCompetitionService.normalizeFixtures(fixtures),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  factory MatchCompetitionRecord.fromMap(Map<String, dynamic> map) {
    final kind = map['kind']?.toString() ?? '';
    final name = map['name']?.toString() ?? '';
    final createdAt = DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final updatedAt =
        DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? createdAt;
    final teams = map['teams'] is List
        ? (map['teams'] as List).map((item) => item.toString()).toList()
        : const <String>[];
    final status = MatchCompetitionService.normalizeStatus(
      map['status']?.toString() ?? '',
    );
    final fixtures = map['fixtures'] is List
        ? (map['fixtures'] as List)
            .whereType<Map>()
            .map(
              (item) => CompetitionFixture.fromMap(
                item.cast<String, dynamic>(),
              ),
            )
            .toList(growable: false)
        : const <CompetitionFixture>[];
    return MatchCompetitionRecord(
      id: map['id']?.toString().trim().isNotEmpty == true
          ? map['id'].toString()
          : MatchCompetitionService.competitionId(kind: kind, name: name),
      kind: kind,
      name: name,
      teams: MatchCompetitionService.normalizeTeams(teams),
      status: status,
      season: map['season']?.toString().trim() ?? '',
      venue: map['venue']?.toString().trim() ?? '',
      organizer: map['organizer']?.toString().trim() ?? '',
      note: map['note']?.toString().trim() ?? '',
      leagueLegs: MatchCompetitionService.normalizeLeagueLegs(
        (map['leagueLegs'] as num?)?.toInt() ?? 1,
      ),
      fixtureStartDate: DateTime.tryParse(
        map['fixtureStartDate']?.toString() ?? '',
      ),
      fixtureIntervalDays: MatchCompetitionService.normalizeFixtureInterval(
        (map['fixtureIntervalDays'] as num?)?.toInt() ?? 7,
      ),
      fixtures: MatchCompetitionService.normalizeFixtures(fixtures),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  MatchCompetitionRecord copyWith({
    String? id,
    String? kind,
    String? name,
    List<String>? teams,
    String? status,
    String? season,
    String? venue,
    String? organizer,
    String? note,
    int? leagueLegs,
    DateTime? fixtureStartDate,
    bool clearFixtureStartDate = false,
    int? fixtureIntervalDays,
    List<CompetitionFixture>? fixtures,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MatchCompetitionRecord(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      teams: teams == null
          ? this.teams
          : MatchCompetitionService.normalizeTeams(teams),
      status: MatchCompetitionService.normalizeStatus(status ?? this.status),
      season: season?.trim() ?? this.season,
      venue: venue?.trim() ?? this.venue,
      organizer: organizer?.trim() ?? this.organizer,
      note: note?.trim() ?? this.note,
      leagueLegs: MatchCompetitionService.normalizeLeagueLegs(
        leagueLegs ?? this.leagueLegs,
      ),
      fixtureStartDate: clearFixtureStartDate
          ? null
          : fixtureStartDate ?? this.fixtureStartDate,
      fixtureIntervalDays: MatchCompetitionService.normalizeFixtureInterval(
        fixtureIntervalDays ?? this.fixtureIntervalDays,
      ),
      fixtures: fixtures == null
          ? this.fixtures
          : MatchCompetitionService.normalizeFixtures(fixtures),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'kind': kind,
      'name': name,
      'teams': teams,
      'status': status,
      'season': season,
      'venue': venue,
      'organizer': organizer,
      'note': note,
      'leagueLegs': leagueLegs,
      'fixtureStartDate': fixtureStartDate?.toIso8601String(),
      'fixtureIntervalDays': fixtureIntervalDays,
      'fixtures': fixtures.map((fixture) => fixture.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class CompetitionFixture {
  static const String statusScheduled = 'scheduled';
  static const String statusCancelled = 'cancelled';

  final String id;
  final int roundNumber;
  final int slotNumber;
  final String stage;
  final String homeTeam;
  final String awayTeam;
  final String? sourceHomeFixtureId;
  final String? sourceAwayFixtureId;
  final DateTime? scheduledAt;
  final String venue;
  final String status;

  const CompetitionFixture({
    required this.id,
    required this.roundNumber,
    required this.slotNumber,
    this.stage = '',
    this.homeTeam = '',
    this.awayTeam = '',
    this.sourceHomeFixtureId,
    this.sourceAwayFixtureId,
    this.scheduledAt,
    this.venue = '',
    this.status = statusScheduled,
  });

  bool get isCancelled => status == statusCancelled;

  bool get hasSourceSlots =>
      sourceHomeFixtureId != null || sourceAwayFixtureId != null;

  factory CompetitionFixture.fromMap(Map<String, dynamic> map) {
    return CompetitionFixture(
      id: map['id']?.toString().trim() ?? '',
      roundNumber: (map['roundNumber'] as num?)?.toInt() ?? 1,
      slotNumber: (map['slotNumber'] as num?)?.toInt() ?? 1,
      stage: map['stage']?.toString().trim() ?? '',
      homeTeam: map['homeTeam']?.toString().trim() ?? '',
      awayTeam: map['awayTeam']?.toString().trim() ?? '',
      sourceHomeFixtureId: map['sourceHomeFixtureId']?.toString().trim(),
      sourceAwayFixtureId: map['sourceAwayFixtureId']?.toString().trim(),
      scheduledAt: DateTime.tryParse(map['scheduledAt']?.toString() ?? ''),
      venue: map['venue']?.toString().trim() ?? '',
      status: map['status']?.toString().trim() ?? statusScheduled,
    );
  }

  CompetitionFixture copyWith({
    String? id,
    int? roundNumber,
    int? slotNumber,
    String? stage,
    String? homeTeam,
    String? awayTeam,
    String? sourceHomeFixtureId,
    String? sourceAwayFixtureId,
    bool clearSourceHomeFixtureId = false,
    bool clearSourceAwayFixtureId = false,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
    String? venue,
    String? status,
  }) {
    return CompetitionFixture(
      id: id ?? this.id,
      roundNumber: roundNumber ?? this.roundNumber,
      slotNumber: slotNumber ?? this.slotNumber,
      stage: stage?.trim() ?? this.stage,
      homeTeam: homeTeam?.trim() ?? this.homeTeam,
      awayTeam: awayTeam?.trim() ?? this.awayTeam,
      sourceHomeFixtureId: clearSourceHomeFixtureId
          ? null
          : sourceHomeFixtureId ?? this.sourceHomeFixtureId,
      sourceAwayFixtureId: clearSourceAwayFixtureId
          ? null
          : sourceAwayFixtureId ?? this.sourceAwayFixtureId,
      scheduledAt: clearScheduledAt ? null : scheduledAt ?? this.scheduledAt,
      venue: venue?.trim() ?? this.venue,
      status:
          status == null || status.trim().isEmpty ? this.status : status.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'roundNumber': roundNumber,
      'slotNumber': slotNumber,
      'stage': stage,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'sourceHomeFixtureId': sourceHomeFixtureId,
      'sourceAwayFixtureId': sourceAwayFixtureId,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'venue': venue,
      'status': status,
    };
  }
}

class CompetitionFixtureState {
  final MatchCompetitionRecord competition;
  final CompetitionFixture fixture;
  final String homeTeam;
  final String awayTeam;
  final TrainingEntry? resultEntry;
  final String winner;

  const CompetitionFixtureState({
    required this.competition,
    required this.fixture,
    required this.homeTeam,
    required this.awayTeam,
    this.resultEntry,
    this.winner = '',
  });

  bool get isCancelled => fixture.isCancelled;

  bool get hasParticipants => homeTeam.isNotEmpty && awayTeam.isNotEmpty;

  bool get isBye =>
      (homeTeam.isNotEmpty && awayTeam.isEmpty) ||
      (homeTeam.isEmpty && awayTeam.isNotEmpty);

  bool get isReady => hasParticipants && !isCancelled;

  bool get isRecorded =>
      resultEntry?.scoredGoals != null && resultEntry?.concededGoals != null;

  bool involvesTeam(String team) {
    final key = MatchCompetitionService.normalizeTeamKey(team);
    return key.isNotEmpty &&
        (MatchCompetitionService.normalizeTeamKey(homeTeam) == key ||
            MatchCompetitionService.normalizeTeamKey(awayTeam) == key);
  }

  String opponentFor(String team) {
    final key = MatchCompetitionService.normalizeTeamKey(team);
    if (key.isEmpty) return '';
    if (MatchCompetitionService.normalizeTeamKey(homeTeam) == key) {
      return awayTeam;
    }
    if (MatchCompetitionService.normalizeTeamKey(awayTeam) == key) {
      return homeTeam;
    }
    return '';
  }

  int? scoreFor(String team) {
    final entry = resultEntry;
    if (entry == null || !isRecorded) return null;
    final key = MatchCompetitionService.normalizeTeamKey(team);
    final opponentKey = MatchCompetitionService.normalizeTeamKey(
      entry.opponentTeam,
    );
    if (key.isEmpty || opponentKey.isEmpty) return null;
    if (key == opponentKey) return entry.concededGoals;
    return entry.scoredGoals;
  }
}

class LeagueStandingRow {
  final String team;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int points;

  const LeagueStandingRow({
    required this.team,
    this.played = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.points = 0,
  });

  int get goalDifference => goalsFor - goalsAgainst;

  LeagueStandingRow addResult({
    required int resultPoints,
    int goalsFor = 0,
    int goalsAgainst = 0,
  }) {
    return LeagueStandingRow(
      team: team,
      played: played + 1,
      wins: wins + (resultPoints >= 3 ? 1 : 0),
      draws: draws + (resultPoints == 1 ? 1 : 0),
      losses: losses + (resultPoints == 0 ? 1 : 0),
      goalsFor: this.goalsFor + goalsFor,
      goalsAgainst: this.goalsAgainst + goalsAgainst,
      points: points + resultPoints,
    );
  }
}

class TournamentBracketPair {
  final int slotNumber;
  final String teamA;
  final String teamB;
  final int? seedA;
  final int? seedB;
  final int? sourceMatchA;
  final int? sourceMatchB;

  const TournamentBracketPair({
    required this.slotNumber,
    required this.teamA,
    required this.teamB,
    this.seedA,
    this.seedB,
    this.sourceMatchA,
    this.sourceMatchB,
  });

  bool get hasBye => teamB.trim().isEmpty;

  String get automaticWinner {
    if (sourceMatchA != null || sourceMatchB != null) return '';
    final first = teamA.trim();
    final second = teamB.trim();
    if (first.isNotEmpty == second.isNotEmpty) return '';
    return first.isNotEmpty ? first : second;
  }
}

class TournamentBracketRound {
  final int teamCapacity;
  final List<TournamentBracketPair> matches;

  const TournamentBracketRound({
    required this.teamCapacity,
    required this.matches,
  });
}

class TournamentBracket {
  final int slotCount;
  final List<TournamentBracketRound> rounds;

  const TournamentBracket({
    required this.slotCount,
    required this.rounds,
  });

  static const empty = TournamentBracket(
    slotCount: 0,
    rounds: <TournamentBracketRound>[],
  );
}

class MatchCompetitionService {
  static const String storageKey = 'match_competitions_v1';

  final OptionRepository _optionRepository;
  final String? _sportId;

  const MatchCompetitionService(this._optionRepository, {String? sportId})
      : _sportId = sportId;

  String get _storageKey => sportScopedOptionKey(
        _optionRepository,
        storageKey,
        sportId: _sportId,
      );

  List<MatchCompetitionRecord> allCompetitions() {
    final raw = _optionRepository.getValue<String>(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <MatchCompetitionRecord>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <MatchCompetitionRecord>[];
      final records = decoded
          .whereType<Map>()
          .map((item) => MatchCompetitionRecord.fromMap(
                item.cast<String, dynamic>(),
              ))
          .where((record) =>
              _supportedKind(record.kind) && record.name.trim().isNotEmpty)
          .toList(growable: false)
        ..sort(_compareCompetitionRecords);
      return records;
    } catch (_) {
      return const <MatchCompetitionRecord>[];
    }
  }

  MatchCompetitionRecord? findCompetition({
    required String kind,
    required String name,
  }) {
    final key = _normalizeKey(name);
    if (key.isEmpty) return null;
    for (final record in allCompetitions()) {
      if (record.kind == kind && _normalizeKey(record.name) == key) {
        return record;
      }
    }
    return null;
  }

  MatchCompetitionRecord? findCompetitionById(String id) {
    final key = id.trim();
    if (key.isEmpty) return null;
    for (final record in allCompetitions()) {
      if (record.id == key) return record;
    }
    return null;
  }

  List<MatchCompetitionRecord> competitionsForKind(String kind) {
    return allCompetitions()
        .where((record) => record.kind == kind)
        .toList(growable: false)
      ..sort(_compareCompetitionRecords);
  }

  Future<void> upsertCompetition(MatchCompetitionRecord record) async {
    final now = DateTime.now();
    final currentRecords = allCompetitions();
    MatchCompetitionRecord? existing;
    for (final current in currentRecords) {
      final sameRecord = current.id == record.id ||
          (current.kind == record.kind &&
              _normalizeKey(current.name) == _normalizeKey(record.name));
      if (sameRecord) {
        existing = current;
        break;
      }
    }
    final normalizedBase = record.copyWith(
      id: competitionId(kind: record.kind, name: record.name),
      name: record.name.trim(),
      teams: normalizeTeams(record.teams),
      status: normalizeStatus(record.status),
      updatedAt: now,
    );
    if (!_supportedKind(normalizedBase.kind) || normalizedBase.name.isEmpty) {
      return;
    }

    final fixtures = normalizedBase.fixtures.isNotEmpty
        ? normalizedBase.fixtures
        : existing?.fixtures.isNotEmpty == true
            ? existing!.fixtures
            : buildFixtures(normalizedBase);
    final normalized = normalizedBase.copyWith(fixtures: fixtures);

    final next = <MatchCompetitionRecord>[];
    var createdAt = normalized.createdAt;
    for (final current in currentRecords) {
      final sameRecord = current.id == normalized.id ||
          (current.kind == normalized.kind &&
              _normalizeKey(current.name) == _normalizeKey(normalized.name));
      if (sameRecord) {
        createdAt = current.createdAt;
        continue;
      }
      next.add(current);
    }
    next.add(normalized.copyWith(createdAt: createdAt));
    await _saveAll(next);
  }

  Future<void> upsertFromEntry(TrainingEntry entry) async {
    if (!entry.isLeagueMatch && !entry.isTournamentMatch) return;
    final name = entry.matchCompetitionName.trim();
    if (name.isEmpty) return;
    final kind = entry.isTournamentMatch
        ? MatchCompetitionRecord.kindTournament
        : MatchCompetitionRecord.kindLeague;
    final existing = findCompetition(kind: kind, name: name);
    if (existing == null) return;
    final teams = normalizeTeams([
      ...existing.teams,
      ...entry.leagueTeamNames,
      entry.opponentTeam,
    ]);
    await upsertCompetition(
      MatchCompetitionRecord.create(
        kind: kind,
        name: name,
        teams: teams,
        status: existing.status,
        season: existing.season,
        venue: existing.venue,
        organizer: existing.organizer,
        note: existing.note,
        leagueLegs: existing.leagueLegs,
        fixtureStartDate: existing.fixtureStartDate,
        fixtureIntervalDays: existing.fixtureIntervalDays,
        fixtures: existing.fixtures,
      ),
    );
  }

  Future<void> deleteCompetition(String id) async {
    final key = id.trim();
    if (key.isEmpty) return;
    final next = allCompetitions()
        .where((record) => record.id != key)
        .toList(growable: false);
    await _saveAll(next);
  }

  Future<void> _saveAll(List<MatchCompetitionRecord> records) {
    final normalized = [...records]..sort(_compareCompetitionRecords);
    return _optionRepository.setValue(
      _storageKey,
      jsonEncode(normalized.map((record) => record.toMap()).toList()),
    );
  }

  static String competitionId({
    required String kind,
    required String name,
  }) {
    return '$kind:${_normalizeKey(name)}';
  }

  static int normalizeLeagueLegs(int value) => value == 2 ? 2 : 1;

  static int normalizeFixtureInterval(int value) => value.clamp(1, 30);

  static String normalizeTeamKey(String value) => _normalizeKey(value);

  static List<CompetitionFixture> normalizeFixtures(
    Iterable<CompetitionFixture> fixtures,
  ) {
    final seen = <String>{};
    final result = <CompetitionFixture>[];
    for (final fixture in fixtures) {
      final id = fixture.id.trim();
      if (id.isEmpty || !seen.add(id)) continue;
      result.add(
        fixture.copyWith(
          id: id,
          roundNumber: fixture.roundNumber < 1 ? 1 : fixture.roundNumber,
          slotNumber: fixture.slotNumber < 1 ? 1 : fixture.slotNumber,
        ),
      );
    }
    result.sort((a, b) {
      final roundCompare = a.roundNumber.compareTo(b.roundNumber);
      if (roundCompare != 0) return roundCompare;
      return a.slotNumber.compareTo(b.slotNumber);
    });
    return List<CompetitionFixture>.unmodifiable(result);
  }

  static List<CompetitionFixture> buildFixtures(
    MatchCompetitionRecord record,
  ) {
    return record.kind == MatchCompetitionRecord.kindTournament
        ? _buildTournamentFixtures(record)
        : _buildLeagueFixtures(record);
  }

  static List<CompetitionFixtureState> resolveFixtureStates({
    required MatchCompetitionRecord competition,
    required Iterable<TrainingEntry> entries,
  }) {
    final fixtures = normalizeFixtures(competition.fixtures);
    if (fixtures.isEmpty) return const <CompetitionFixtureState>[];
    final fixtureById = <String, CompetitionFixture>{
      for (final fixture in fixtures) fixture.id: fixture,
    };
    final stateById = <String, CompetitionFixtureState>{};
    final resolving = <String>{};
    final scopedEntries = competitionEntries(
      kind: competition.kind,
      competitionName: competition.name,
      competitionId: competition.id,
      entries: entries,
    );

    CompetitionFixtureState resolve(CompetitionFixture fixture) {
      final cached = stateById[fixture.id];
      if (cached != null) return cached;
      if (!resolving.add(fixture.id)) {
        return CompetitionFixtureState(
          competition: competition,
          fixture: fixture,
          homeTeam: fixture.homeTeam,
          awayTeam: fixture.awayTeam,
        );
      }
      final sourceHome = fixture.sourceHomeFixtureId == null
          ? null
          : fixtureById[fixture.sourceHomeFixtureId];
      final sourceAway = fixture.sourceAwayFixtureId == null
          ? null
          : fixtureById[fixture.sourceAwayFixtureId];
      final homeTeam = fixture.homeTeam.trim().isNotEmpty
          ? fixture.homeTeam.trim()
          : sourceHome == null
              ? ''
              : resolve(sourceHome).winner;
      final awayTeam = fixture.awayTeam.trim().isNotEmpty
          ? fixture.awayTeam.trim()
          : sourceAway == null
              ? ''
              : resolve(sourceAway).winner;
      final resultEntry = _entryForFixture(
        competition: competition,
        fixture: fixture,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        entries: scopedEntries,
      );
      final winner = _winnerForFixture(
        competition: competition,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        entry: resultEntry,
      );
      final resolved = CompetitionFixtureState(
        competition: competition,
        fixture: fixture,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        resultEntry: resultEntry,
        winner: winner,
      );
      resolving.remove(fixture.id);
      stateById[fixture.id] = resolved;
      return resolved;
    }

    return List<CompetitionFixtureState>.unmodifiable([
      for (final fixture in fixtures) resolve(fixture),
    ]);
  }

  static List<CompetitionFixtureState> fixturesForTeam({
    required Iterable<MatchCompetitionRecord> competitions,
    required Iterable<TrainingEntry> entries,
    required String teamName,
    Iterable<String> teamAliases = const <String>[],
    bool includeRecorded = true,
  }) {
    final teamNames = normalizeTeams([teamName, ...teamAliases]);
    final states = <CompetitionFixtureState>[];
    for (final competition in competitions) {
      for (final state in resolveFixtureStates(
        competition: competition,
        entries: entries,
      )) {
        if (!teamNames.any(state.involvesTeam)) continue;
        if (!includeRecorded && state.isRecorded) continue;
        states.add(state);
      }
    }
    states.sort((a, b) {
      final aDate = a.fixture.scheduledAt;
      final bDate = b.fixture.scheduledAt;
      if (aDate == null && bDate != null) return 1;
      if (aDate != null && bDate == null) return -1;
      if (aDate != null && bDate != null) {
        final dateCompare = aDate.compareTo(bDate);
        if (dateCompare != 0) return dateCompare;
      }
      final competitionCompare =
          a.competition.name.compareTo(b.competition.name);
      if (competitionCompare != 0) return competitionCompare;
      return a.fixture.slotNumber.compareTo(b.fixture.slotNumber);
    });
    return List<CompetitionFixtureState>.unmodifiable(states);
  }

  static TournamentBracket resolveTournamentBracket({
    required MatchCompetitionRecord competition,
    required Iterable<TrainingEntry> entries,
  }) {
    final base = buildTournamentBracket(competition.teams);
    if (base.rounds.isEmpty || competition.fixtures.isEmpty) return base;
    final states = <int, CompetitionFixtureState>{
      for (final state in resolveFixtureStates(
        competition: competition,
        entries: entries,
      ))
        state.fixture.slotNumber: state,
    };
    return TournamentBracket(
      slotCount: base.slotCount,
      rounds: [
        for (final round in base.rounds)
          TournamentBracketRound(
            teamCapacity: round.teamCapacity,
            matches: [
              for (final match in round.matches)
                TournamentBracketPair(
                  slotNumber: match.slotNumber,
                  teamA: states[match.slotNumber]?.homeTeam ?? match.teamA,
                  teamB: states[match.slotNumber]?.awayTeam ?? match.teamB,
                  seedA: match.seedA,
                  seedB: match.seedB,
                  sourceMatchA: match.sourceMatchA,
                  sourceMatchB: match.sourceMatchB,
                ),
            ],
          ),
      ],
    );
  }

  static List<String> parseTeams(String text) {
    return normalizeTeams(text.split(RegExp(r'[,/\n]')));
  }

  static List<String> normalizeTeams(Iterable<String> values) {
    final seen = <String>{};
    final teams = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      final key = _normalizeKey(trimmed);
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      teams.add(trimmed);
    }
    return teams;
  }

  static List<String> teamsWithManagedTeam({
    required String kind,
    required Iterable<String> teams,
    required String managedTeamName,
    required String fallbackTeamName,
    bool replaceLeagueFirstTeam = false,
  }) {
    final explicitManagedTeam = managedTeamName.trim();
    final ownTeam = explicitManagedTeam.isEmpty
        ? fallbackTeamName.trim()
        : explicitManagedTeam;
    final normalized = normalizeTeams(teams);
    if (explicitManagedTeam.isEmpty && normalized.isNotEmpty) {
      return normalized;
    }
    if (ownTeam.isEmpty) return normalized;
    final ownKey = _normalizeKey(ownTeam);
    final fallbackKey = _normalizeKey(fallbackTeamName);

    if (kind == MatchCompetitionRecord.kindLeague) {
      return normalizeTeams([
        ownTeam,
        for (final item in normalized.indexed)
          if (!(replaceLeagueFirstTeam && item.$1 == 0) &&
              _normalizeKey(item.$2) != ownKey &&
              _normalizeKey(item.$2) != fallbackKey)
            item.$2,
      ]);
    }

    var foundOwnTeam = false;
    final tournamentTeams = <String>[];
    for (final team in normalized) {
      final key = _normalizeKey(team);
      if (key == ownKey || (fallbackKey.isNotEmpty && key == fallbackKey)) {
        tournamentTeams.add(ownTeam);
        foundOwnTeam = true;
      } else {
        tournamentTeams.add(team);
      }
    }
    if (!foundOwnTeam) tournamentTeams.insert(0, ownTeam);
    return normalizeTeams(tournamentTeams);
  }

  static String normalizeStatus(String status) {
    return status == MatchCompetitionRecord.statusFinished
        ? MatchCompetitionRecord.statusFinished
        : MatchCompetitionRecord.statusActive;
  }

  static List<TrainingEntry> competitionEntries({
    required String kind,
    required String competitionName,
    String competitionId = '',
    required Iterable<TrainingEntry> entries,
  }) {
    final targetName = _normalizeKey(competitionName);
    final targetId = competitionId.trim();
    return entries.where((entry) {
      final kindMatches = kind == MatchCompetitionRecord.kindTournament
          ? entry.isTournamentMatch
          : entry.isLeagueMatch;
      if (!kindMatches) return false;
      if (targetId.isNotEmpty && entry.matchCompetitionId == targetId) {
        return true;
      }
      if (targetName.isEmpty) return true;
      return _normalizeKey(entry.matchCompetitionName) == targetName;
    }).toList(growable: false);
  }

  static List<LeagueStandingRow> buildLeagueStandings({
    required String competitionName,
    required List<String> registeredTeams,
    required Iterable<TrainingEntry> entries,
    required String ownTeamName,
    bool preferOwnTeamName = false,
    Iterable<String> ownTeamAliases = const <String>[],
  }) {
    final matchingEntries = competitionEntries(
      kind: MatchCompetitionRecord.kindLeague,
      competitionName: competitionName,
      entries: entries,
    );
    final requestedOwnTeam = ownTeamName.trim();
    final ownTeamKeys = <String>{
      if (requestedOwnTeam.isNotEmpty) _normalizeKey(requestedOwnTeam),
      for (final alias in ownTeamAliases)
        if (alias.trim().isNotEmpty) _normalizeKey(alias),
    };
    String canonicalTeam(String raw) {
      final team = raw.trim();
      if (preferOwnTeamName &&
          requestedOwnTeam.isNotEmpty &&
          ownTeamKeys.contains(_normalizeKey(team))) {
        return requestedOwnTeam;
      }
      return team;
    }

    final teams = normalizeTeams([
      if (preferOwnTeamName) requestedOwnTeam,
      for (final team in registeredTeams) canonicalTeam(team),
      for (final entry in matchingEntries)
        for (final team in entry.leagueTeamNames) canonicalTeam(team),
      for (final entry in matchingEntries) canonicalTeam(entry.opponentTeam),
    ]);
    final ownTeam = preferOwnTeamName && requestedOwnTeam.isNotEmpty
        ? requestedOwnTeam
        : teams.isNotEmpty
            ? teams.first
            : requestedOwnTeam;
    if (ownTeam.isNotEmpty && !teams.any((team) => team == ownTeam)) {
      teams.insert(0, ownTeam);
    }

    final rows = <String, LeagueStandingRow>{
      for (final team in teams) team: LeagueStandingRow(team: team),
    };

    LeagueStandingRow ensureRow(String team) {
      final trimmed = canonicalTeam(team);
      return rows.putIfAbsent(trimmed, () => LeagueStandingRow(team: trimmed));
    }

    void applyResult({
      required String team,
      required int points,
      int goalsFor = 0,
      int goalsAgainst = 0,
    }) {
      if (team.trim().isEmpty) return;
      final current = ensureRow(team);
      rows[current.team] = current.addResult(
        resultPoints: points,
        goalsFor: goalsFor,
        goalsAgainst: goalsAgainst,
      );
    }

    for (final entry in matchingEntries) {
      final opponent = canonicalTeam(entry.opponentTeam);
      final scored = entry.scoredGoals;
      final conceded = entry.concededGoals;
      final inferredSelfPoints = _pointsFromScore(scored, conceded);
      final selfPoints = entry.leaguePoints ?? inferredSelfPoints;
      if (selfPoints == null) continue;

      final selfGoalsFor = scored ?? 0;
      final selfGoalsAgainst = conceded ?? 0;
      applyResult(
        team: ownTeam,
        points: selfPoints,
        goalsFor: selfGoalsFor,
        goalsAgainst: selfGoalsAgainst,
      );

      if (opponent.isNotEmpty && opponent != ownTeam) {
        final opponentPoints = _opponentPoints(
          selfPoints: selfPoints,
          scored: scored,
          conceded: conceded,
        );
        applyResult(
          team: opponent,
          points: opponentPoints,
          goalsFor: selfGoalsAgainst,
          goalsAgainst: selfGoalsFor,
        );
      }
    }

    final sorted = rows.values
        .where((row) => row.team.trim().isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) {
        final pointsCompare = b.points.compareTo(a.points);
        if (pointsCompare != 0) return pointsCompare;
        final goalDiffCompare = b.goalDifference.compareTo(a.goalDifference);
        if (goalDiffCompare != 0) return goalDiffCompare;
        final goalsForCompare = b.goalsFor.compareTo(a.goalsFor);
        if (goalsForCompare != 0) return goalsForCompare;
        return a.team.compareTo(b.team);
      });
    return sorted;
  }

  static List<LeagueStandingRow> buildLeagueStandingsForCompetition({
    required MatchCompetitionRecord competition,
    required Iterable<TrainingEntry> entries,
  }) {
    final rows = <String, LeagueStandingRow>{
      for (final team in normalizeTeams(competition.teams))
        team: LeagueStandingRow(team: team),
    };

    void apply(
      String team,
      int points,
      int goalsFor,
      int goalsAgainst,
    ) {
      final current =
          rows.putIfAbsent(team, () => LeagueStandingRow(team: team));
      rows[team] = current.addResult(
        resultPoints: points,
        goalsFor: goalsFor,
        goalsAgainst: goalsAgainst,
      );
    }

    final scopedEntries = competitionEntries(
      kind: MatchCompetitionRecord.kindLeague,
      competitionName: competition.name,
      competitionId: competition.id,
      entries: entries,
    );
    final resolvedFixtures = resolveFixtureStates(
      competition: competition,
      entries: scopedEntries,
    );
    final handledEntries = <TrainingEntry>{};
    for (final fixture in resolvedFixtures) {
      final resultEntry = fixture.resultEntry;
      if (resultEntry != null) handledEntries.add(resultEntry);
      if (!fixture.isRecorded ||
          fixture.homeTeam.isEmpty ||
          fixture.awayTeam.isEmpty) {
        continue;
      }
      final homeScore = fixture.scoreFor(fixture.homeTeam);
      final awayScore = fixture.scoreFor(fixture.awayTeam);
      if (homeScore == null || awayScore == null) continue;
      final homePoints = _pointsFromScore(homeScore, awayScore);
      final awayPoints = _pointsFromScore(awayScore, homeScore);
      if (homePoints == null || awayPoints == null) continue;
      apply(fixture.homeTeam, homePoints, homeScore, awayScore);
      apply(fixture.awayTeam, awayPoints, awayScore, homeScore);
    }

    // Older records predate fixture IDs. Keep them visible until the user
    // records a result through the generated schedule.
    final ownTeam = competition.teams.isEmpty ? '' : competition.teams.first;
    for (final entry in scopedEntries) {
      if (handledEntries.contains(entry) || entry.matchFixtureId.isNotEmpty) {
        continue;
      }
      final opponent = entry.opponentTeam.trim();
      final scored = entry.scoredGoals;
      final conceded = entry.concededGoals;
      final selfPoints =
          entry.leaguePoints ?? _pointsFromScore(scored, conceded);
      if (ownTeam.isEmpty || opponent.isEmpty || selfPoints == null) continue;
      apply(ownTeam, selfPoints, scored ?? 0, conceded ?? 0);
      apply(
        opponent,
        _opponentPoints(
          selfPoints: selfPoints,
          scored: scored,
          conceded: conceded,
        ),
        conceded ?? 0,
        scored ?? 0,
      );
    }

    final sorted = rows.values.toList(growable: false)
      ..sort((a, b) {
        final pointsCompare = b.points.compareTo(a.points);
        if (pointsCompare != 0) return pointsCompare;
        final goalDiffCompare = b.goalDifference.compareTo(a.goalDifference);
        if (goalDiffCompare != 0) return goalDiffCompare;
        final goalsForCompare = b.goalsFor.compareTo(a.goalsFor);
        if (goalsForCompare != 0) return goalsForCompare;
        return a.team.compareTo(b.team);
      });
    return sorted;
  }

  static List<TournamentBracketPair> buildTournamentBracketPairs(
    List<String> registeredTeams,
  ) {
    final bracket = buildTournamentBracket(registeredTeams);
    return bracket.rounds.isEmpty
        ? const <TournamentBracketPair>[]
        : bracket.rounds.first.matches;
  }

  static TournamentBracket buildTournamentBracket(
    List<String> registeredTeams,
  ) {
    final teams = normalizeTeams(registeredTeams);
    if (teams.isEmpty) return TournamentBracket.empty;

    var slotCount = 2;
    while (slotCount < teams.length) {
      slotCount *= 2;
    }

    final seedOrder = _tournamentSeedOrder(slotCount);
    final firstRound = <TournamentBracketPair>[];
    var nextMatchNumber = 1;
    for (var index = 0; index < seedOrder.length; index += 2) {
      final seedA = seedOrder[index];
      final seedB = seedOrder[index + 1];
      firstRound.add(
        TournamentBracketPair(
          slotNumber: nextMatchNumber++,
          teamA: seedA <= teams.length ? teams[seedA - 1] : '',
          teamB: seedB <= teams.length ? teams[seedB - 1] : '',
          seedA: seedA <= teams.length ? seedA : null,
          seedB: seedB <= teams.length ? seedB : null,
        ),
      );
    }

    final rounds = <TournamentBracketRound>[
      TournamentBracketRound(
        teamCapacity: slotCount,
        matches: firstRound,
      ),
    ];
    var previousRound = firstRound;
    var teamCapacity = slotCount ~/ 2;
    while (previousRound.length > 1) {
      final nextRound = <TournamentBracketPair>[];
      for (var index = 0; index < previousRound.length; index += 2) {
        final sourceA = previousRound[index];
        final sourceB = previousRound[index + 1];
        nextRound.add(
          TournamentBracketPair(
            slotNumber: nextMatchNumber++,
            teamA: sourceA.automaticWinner,
            teamB: sourceB.automaticWinner,
            sourceMatchA: sourceA.slotNumber,
            sourceMatchB: sourceB.slotNumber,
          ),
        );
      }
      rounds.add(
        TournamentBracketRound(
          teamCapacity: teamCapacity,
          matches: nextRound,
        ),
      );
      previousRound = nextRound;
      teamCapacity ~/= 2;
    }
    return TournamentBracket(slotCount: slotCount, rounds: rounds);
  }

  static List<CompetitionFixture> _buildLeagueFixtures(
    MatchCompetitionRecord record,
  ) {
    final teams = normalizeTeams(record.teams);
    if (teams.length < 2) return const <CompetitionFixture>[];
    final rotation = List<String>.from(teams);
    if (rotation.length.isOdd) rotation.add('');
    final roundsPerLeg = rotation.length - 1;
    final fixtures = <CompetitionFixture>[];
    var slotNumber = 1;
    for (var roundIndex = 0; roundIndex < roundsPerLeg; roundIndex += 1) {
      for (var pairIndex = 0;
          pairIndex < rotation.length ~/ 2;
          pairIndex += 1) {
        final first = rotation[pairIndex];
        final second = rotation[rotation.length - 1 - pairIndex];
        if (first.isEmpty || second.isEmpty) continue;
        final swap = (roundIndex + pairIndex).isOdd;
        fixtures.add(
          CompetitionFixture(
            id: 'league-r${roundIndex + 1}-m${pairIndex + 1}',
            roundNumber: roundIndex + 1,
            slotNumber: slotNumber++,
            stage: 'round-${roundIndex + 1}',
            homeTeam: swap ? second : first,
            awayTeam: swap ? first : second,
            scheduledAt: _fixtureDate(
              record.fixtureStartDate,
              record.fixtureIntervalDays,
              roundIndex,
            ),
            venue: record.venue,
          ),
        );
      }
      final anchor = rotation.first;
      final tail = rotation.sublist(1);
      final last = tail.removeLast();
      tail.insert(0, last);
      rotation
        ..clear()
        ..add(anchor)
        ..addAll(tail);
    }
    if (record.leagueLegs == 2) {
      final firstLeg = List<CompetitionFixture>.from(fixtures);
      for (final fixture in firstLeg) {
        final secondRound = fixture.roundNumber + roundsPerLeg;
        fixtures.add(
          CompetitionFixture(
            id: 'league-r$secondRound-m${fixture.slotNumber}',
            roundNumber: secondRound,
            slotNumber: slotNumber++,
            stage: 'round-$secondRound',
            homeTeam: fixture.awayTeam,
            awayTeam: fixture.homeTeam,
            scheduledAt: _fixtureDate(
              record.fixtureStartDate,
              record.fixtureIntervalDays,
              secondRound - 1,
            ),
            venue: fixture.venue,
          ),
        );
      }
    }
    return normalizeFixtures(fixtures);
  }

  static List<CompetitionFixture> _buildTournamentFixtures(
    MatchCompetitionRecord record,
  ) {
    final bracket = buildTournamentBracket(record.teams);
    if (bracket.rounds.isEmpty) return const <CompetitionFixture>[];
    final fixtures = <CompetitionFixture>[];
    for (var roundIndex = 0;
        roundIndex < bracket.rounds.length;
        roundIndex += 1) {
      final round = bracket.rounds[roundIndex];
      for (final pair in round.matches) {
        fixtures.add(
          CompetitionFixture(
            id: 'tournament-m${pair.slotNumber}',
            roundNumber: roundIndex + 1,
            slotNumber: pair.slotNumber,
            stage: _tournamentStageForCapacity(round.teamCapacity),
            homeTeam: pair.teamA,
            awayTeam: pair.teamB,
            sourceHomeFixtureId: pair.sourceMatchA == null
                ? null
                : 'tournament-m${pair.sourceMatchA}',
            sourceAwayFixtureId: pair.sourceMatchB == null
                ? null
                : 'tournament-m${pair.sourceMatchB}',
            scheduledAt: _fixtureDate(
              record.fixtureStartDate,
              record.fixtureIntervalDays,
              roundIndex,
            ),
            venue: record.venue,
          ),
        );
      }
    }
    return normalizeFixtures(fixtures);
  }

  static DateTime? _fixtureDate(
    DateTime? startDate,
    int intervalDays,
    int roundIndex,
  ) {
    if (startDate == null) return null;
    final normalized = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    return normalized.add(
      Duration(days: normalizeFixtureInterval(intervalDays) * roundIndex),
    );
  }

  static TrainingEntry? _entryForFixture({
    required MatchCompetitionRecord competition,
    required CompetitionFixture fixture,
    required String homeTeam,
    required String awayTeam,
    required Iterable<TrainingEntry> entries,
  }) {
    final explicit = entries.where(
      (entry) =>
          entry.matchCompetitionId == competition.id &&
          entry.matchFixtureId == fixture.id,
    );
    if (explicit.isNotEmpty) {
      return explicit.reduce(
        (current, next) =>
            current.createdAt.isAfter(next.createdAt) ? current : next,
      );
    }
    final legacyStage = fixture.stage.trim();
    if (legacyStage.isEmpty || homeTeam.isEmpty || awayTeam.isEmpty) {
      return null;
    }
    final legacy = entries.where((entry) {
      if (_normalizeKey(entry.matchStage) != _normalizeKey(legacyStage)) {
        return false;
      }
      final opponent = _normalizeKey(entry.opponentTeam);
      return opponent == _normalizeKey(homeTeam) ||
          opponent == _normalizeKey(awayTeam);
    });
    if (legacy.isEmpty) return null;
    return legacy.reduce(
      (current, next) =>
          current.createdAt.isAfter(next.createdAt) ? current : next,
    );
  }

  static String _winnerForFixture({
    required MatchCompetitionRecord competition,
    required String homeTeam,
    required String awayTeam,
    required TrainingEntry? entry,
  }) {
    if (homeTeam.isEmpty || awayTeam.isEmpty) {
      return homeTeam.isNotEmpty ? homeTeam : awayTeam;
    }
    if (entry == null ||
        entry.scoredGoals == null ||
        entry.concededGoals == null ||
        competition.kind != MatchCompetitionRecord.kindTournament) {
      return '';
    }
    final opponentKey = _normalizeKey(entry.opponentTeam);
    final teamForScore = opponentKey == _normalizeKey(homeTeam)
        ? awayTeam
        : opponentKey == _normalizeKey(awayTeam)
            ? homeTeam
            : '';
    if (teamForScore.isEmpty) return '';
    final result = entry.resolvedMatchOutcome;
    if (result == null || result == 0) return '';
    return result > 0
        ? teamForScore
        : _normalizeKey(teamForScore) == _normalizeKey(homeTeam)
            ? awayTeam
            : homeTeam;
  }

  static String _tournamentStageForCapacity(int capacity) {
    return switch (capacity) {
      2 => 'final',
      4 => 'semifinal',
      8 => 'quarterfinal',
      16 => 'round16',
      _ => 'preliminary',
    };
  }

  static List<int> _tournamentSeedOrder(int slotCount) {
    var seeds = <int>[1, 2];
    var currentSize = 2;
    while (currentSize < slotCount) {
      final nextSize = currentSize * 2;
      seeds = <int>[
        for (final seed in seeds) ...[seed, nextSize + 1 - seed],
      ];
      currentSize = nextSize;
    }
    return seeds;
  }

  static bool _supportedKind(String kind) {
    return kind == MatchCompetitionRecord.kindLeague ||
        kind == MatchCompetitionRecord.kindTournament;
  }

  static int _compareCompetitionRecords(
    MatchCompetitionRecord a,
    MatchCompetitionRecord b,
  ) {
    final kindCompare = a.kind.compareTo(b.kind);
    if (kindCompare != 0) return kindCompare;
    final statusCompare = a.status.compareTo(b.status);
    if (statusCompare != 0) return statusCompare;
    return b.updatedAt.compareTo(a.updatedAt);
  }

  static String _normalizeKey(String value) => value.trim().toLowerCase();

  static int? _pointsFromScore(int? scored, int? conceded) {
    if (scored == null || conceded == null) return null;
    if (scored > conceded) return 3;
    if (scored == conceded) return 1;
    return 0;
  }

  static int _opponentPoints({
    required int selfPoints,
    required int? scored,
    required int? conceded,
  }) {
    final fromScore = _pointsFromScore(conceded, scored);
    if (fromScore != null) return fromScore;
    if (selfPoints >= 3) return 0;
    if (selfPoints == 1) return 1;
    return 3;
  }
}
