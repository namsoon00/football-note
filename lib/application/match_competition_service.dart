import 'dart:convert';

import '../domain/entities/training_entry.dart';
import '../domain/repositories/option_repository.dart';
import 'sport_scoped_storage.dart';

class MatchCompetitionRecord {
  static const String kindLeague = 'league';
  static const String kindTournament = 'tournament';
  static const String statusActive = 'active';
  static const String statusFinished = 'finished';
  static const String tieBreakerGoalDifference = 'goal_difference';
  static const String tieBreakerWins = 'wins';
  static const String tieBreakerGoalsFor = 'goals_for';

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
  final String leagueTieBreaker;
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
    this.leagueTieBreaker = tieBreakerGoalDifference,
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
    String leagueTieBreaker = tieBreakerGoalDifference,
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
      leagueTieBreaker: MatchCompetitionService.normalizeLeagueTieBreaker(
        leagueTieBreaker,
      ),
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
      leagueTieBreaker: MatchCompetitionService.normalizeLeagueTieBreaker(
        map['leagueTieBreaker']?.toString() ?? '',
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
    String? leagueTieBreaker,
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
      leagueTieBreaker: MatchCompetitionService.normalizeLeagueTieBreaker(
        leagueTieBreaker ?? this.leagueTieBreaker,
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
      'leagueTieBreaker': leagueTieBreaker,
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
  static const String statusCompleted = 'completed';
  static const String statusPostponed = 'postponed';
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
  final int? homeScore;
  final int? awayScore;
  final int? homePenaltyScore;
  final int? awayPenaltyScore;

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
    this.homeScore,
    this.awayScore,
    this.homePenaltyScore,
    this.awayPenaltyScore,
  });

  bool get isCancelled => status == statusCancelled;

  bool get isPostponed => status == statusPostponed;

  bool get isCompleted => status == statusCompleted || hasResult;

  bool get hasResult => homeScore != null && awayScore != null;

  bool get hasPenaltyResult =>
      homePenaltyScore != null && awayPenaltyScore != null;

  bool get isDrawnResult => hasResult && homeScore == awayScore;

  bool get hasSourceSlots =>
      sourceHomeFixtureId != null || sourceAwayFixtureId != null;

  factory CompetitionFixture.fromMap(Map<String, dynamic> map) {
    final homeScore = _scoreFromMap(map['homeScore']);
    final awayScore = _scoreFromMap(map['awayScore']);
    final rawStatus = map['status']?.toString().trim() ?? '';
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
      status: normalizeStatus(
        rawStatus,
        hasResult: homeScore != null && awayScore != null,
      ),
      homeScore: homeScore,
      awayScore: awayScore,
      homePenaltyScore: _scoreFromMap(map['homePenaltyScore']),
      awayPenaltyScore: _scoreFromMap(map['awayPenaltyScore']),
    );
  }

  static String normalizeStatus(String value, {bool hasResult = false}) {
    switch (value.trim()) {
      case statusCompleted:
      case statusPostponed:
      case statusCancelled:
      case statusScheduled:
        return value.trim();
      default:
        return hasResult ? statusCompleted : statusScheduled;
    }
  }

  static int? _scoreFromMap(Object? value) {
    final score = value is num ? value.toInt() : int.tryParse('$value');
    return score == null || score < 0 ? null : score;
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
    int? homeScore,
    int? awayScore,
    int? homePenaltyScore,
    int? awayPenaltyScore,
    bool clearResult = false,
    bool clearPenaltyResult = false,
  }) {
    final nextHomeScore = clearResult ? null : homeScore ?? this.homeScore;
    final nextAwayScore = clearResult ? null : awayScore ?? this.awayScore;
    final nextStatus =
        clearResult && status == null && this.status == statusCompleted
            ? statusScheduled
            : status == null || status.trim().isEmpty
                ? this.status
                : status.trim();
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
      status: normalizeStatus(
        nextStatus,
        hasResult: nextHomeScore != null && nextAwayScore != null,
      ),
      homeScore: nextHomeScore,
      awayScore: nextAwayScore,
      homePenaltyScore:
          clearPenaltyResult ? null : homePenaltyScore ?? this.homePenaltyScore,
      awayPenaltyScore:
          clearPenaltyResult ? null : awayPenaltyScore ?? this.awayPenaltyScore,
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
      'homeScore': homeScore,
      'awayScore': awayScore,
      'homePenaltyScore': homePenaltyScore,
      'awayPenaltyScore': awayPenaltyScore,
    };
  }
}

class CompetitionFixtureState {
  final MatchCompetitionRecord competition;
  final CompetitionFixture fixture;
  final String homeTeam;
  final String awayTeam;
  final TrainingEntry? resultEntry;
  final int? homeScore;
  final int? awayScore;
  final int? homePenaltyScore;
  final int? awayPenaltyScore;
  final String winner;

  const CompetitionFixtureState({
    required this.competition,
    required this.fixture,
    required this.homeTeam,
    required this.awayTeam,
    this.resultEntry,
    this.homeScore,
    this.awayScore,
    this.homePenaltyScore,
    this.awayPenaltyScore,
    this.winner = '',
  });

  bool get isCancelled => fixture.isCancelled;

  bool get hasParticipants => homeTeam.isNotEmpty && awayTeam.isNotEmpty;

  bool get isBye =>
      (homeTeam.isNotEmpty && awayTeam.isEmpty) ||
      (homeTeam.isEmpty && awayTeam.isNotEmpty);

  bool get isReady => hasParticipants && !isCancelled;

  bool get isRecorded => !isCancelled && homeScore != null && awayScore != null;

  bool get hasPenaltyResult =>
      homePenaltyScore != null && awayPenaltyScore != null;

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
    final key = MatchCompetitionService.normalizeTeamKey(team);
    if (key.isEmpty || !isRecorded) return null;
    if (key == MatchCompetitionService.normalizeTeamKey(homeTeam)) {
      return homeScore;
    }
    if (key == MatchCompetitionService.normalizeTeamKey(awayTeam)) {
      return awayScore;
    }
    return null;
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

class CompetitionFixtureRebuildImpact {
  final bool requiresRebuild;
  final int currentFixtureCount;
  final int nextFixtureCount;
  final int changedFixtureCount;
  final int clearedResultCount;

  const CompetitionFixtureRebuildImpact({
    required this.requiresRebuild,
    required this.currentFixtureCount,
    required this.nextFixtureCount,
    required this.changedFixtureCount,
    required this.clearedResultCount,
  });

  bool get hasSavedResultsAtRisk => clearedResultCount > 0;
}

class CompetitionScheduleIssue {
  static const String typeVenueOverlap = 'venue_overlap';
  static const String typeTeamOverlap = 'team_overlap';
  static const String typeShortRest = 'short_rest';

  final String type;
  final List<String> fixtureIds;

  const CompetitionScheduleIssue({
    required this.type,
    required this.fixtureIds,
  });
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
      if (current.id == record.id) {
        existing = current;
        break;
      }
    }
    existing ??= _competitionWithSameName(currentRecords, record);
    final recordId = record.id.trim();
    final normalizedBase = record.copyWith(
      id: existing?.id ??
          (recordId.isEmpty
              ? competitionId(kind: record.kind, name: record.name)
              : recordId),
      name: record.name.trim(),
      teams: normalizeTeams(record.teams),
      status: normalizeStatus(record.status),
      updatedAt: now,
    );
    if (!_supportedKind(normalizedBase.kind) || normalizedBase.name.isEmpty) {
      return;
    }

    final suppliedFixtures = normalizeFixtures(normalizedBase.fixtures);
    final fixtureStructureChanged =
        existing != null && _fixtureStructureChanged(existing, normalizedBase);
    final fixtureScheduleChanged =
        existing != null && _fixtureScheduleChanged(existing, normalizedBase);
    final fixtures = suppliedFixtures.isNotEmpty
        ? suppliedFixtures
        : existing?.fixtures.isNotEmpty == true
            ? fixtureStructureChanged || fixtureScheduleChanged
                ? _rebuildFixtures(
                    existing: existing,
                    updated: normalizedBase,
                    fixtureStructureChanged: fixtureStructureChanged,
                    fixtureScheduleChanged: fixtureScheduleChanged,
                  )
                : _synchronizeFixtureVenue(
                    existing: existing!,
                    updated: normalizedBase,
                  )
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
    var fixtures = _fixturesWithEntryResult(
      competition: existing,
      entry: entry,
    );
    if (existing.kind == MatchCompetitionRecord.kindTournament) {
      for (final fixture in fixtures) {
        final previous = existing.fixtures.where(
          (item) => item.id == fixture.id,
        );
        if (previous.isEmpty ||
            _fixtureResultSignature(previous.first) ==
                _fixtureResultSignature(fixture)) {
          continue;
        }
        fixtures = _clearDependentFixtureResults(
          fixtures: fixtures,
          sourceFixtureId: fixture.id,
        );
      }
    }
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
        leagueTieBreaker: existing.leagueTieBreaker,
        fixtureStartDate: existing.fixtureStartDate,
        fixtureIntervalDays: existing.fixtureIntervalDays,
        fixtures: fixtures,
      ),
    );
  }

  /// Saves an independently managed fixture. This is intentionally separate
  /// from [TrainingEntry] so a manager can enter every tournament or league
  /// result, including matches that do not involve the managed team.
  Future<MatchCompetitionRecord?> updateFixture({
    required MatchCompetitionRecord competition,
    required CompetitionFixture fixture,
  }) async {
    final current = findCompetitionById(competition.id);
    if (current == null) return null;
    final existingFixture = current.fixtures.where(
      (item) => item.id == fixture.id,
    );
    if (existingFixture.isEmpty) return current;
    final previous = existingFixture.first;
    final resultChanged =
        _fixtureResultSignature(previous) != _fixtureResultSignature(fixture);
    var nextFixtures = current.fixtures
        .map((item) => item.id == fixture.id ? fixture : item)
        .toList(growable: false);
    if (current.kind == MatchCompetitionRecord.kindTournament &&
        resultChanged) {
      nextFixtures = _clearDependentFixtureResults(
        fixtures: nextFixtures,
        sourceFixtureId: fixture.id,
      );
    }
    await upsertCompetition(current.copyWith(fixtures: nextFixtures));
    return findCompetitionById(current.id);
  }

  /// Applies a single matchday rhythm to every fixture. Individual fixture
  /// edits remain intact until this action is deliberately applied again.
  Future<MatchCompetitionRecord?> scheduleFixtures({
    required MatchCompetitionRecord competition,
    required DateTime startAt,
    required int intervalDays,
    String? venue,
  }) async {
    final current = findCompetitionById(competition.id);
    if (current == null) return null;
    final normalizedInterval = normalizeFixtureInterval(intervalDays);
    final firstRound = current.fixtures.isEmpty
        ? 1
        : current.fixtures
            .map((fixture) => fixture.roundNumber)
            .reduce((value, element) => value < element ? value : element);
    final fixtures = current.fixtures.map((fixture) {
      final roundOffset = fixture.roundNumber - firstRound;
      final scheduledAt = startAt.add(
        Duration(days: normalizedInterval * roundOffset),
      );
      return fixture.copyWith(
        scheduledAt: scheduledAt,
        venue: venue?.trim() ?? fixture.venue,
        status: fixture.isCancelled || fixture.isCompleted
            ? fixture.status
            : CompetitionFixture.statusScheduled,
      );
    }).toList(growable: false);
    await upsertCompetition(
      current.copyWith(
        fixtureStartDate: startAt,
        fixtureIntervalDays: normalizedInterval,
        fixtures: fixtures,
      ),
    );
    return findCompetitionById(current.id);
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

  static List<CompetitionFixture> _fixturesWithEntryResult({
    required MatchCompetitionRecord competition,
    required TrainingEntry entry,
  }) {
    final fixtureId = entry.matchFixtureId.trim();
    if (fixtureId.isEmpty ||
        entry.scoredGoals == null ||
        entry.concededGoals == null) {
      return competition.fixtures;
    }
    return competition.fixtures.map((fixture) {
      if (fixture.id != fixtureId) return fixture;
      final result = _scoresForEntry(
        entry: entry,
        homeTeam: fixture.homeTeam,
        awayTeam: fixture.awayTeam,
      );
      if (result == null) return fixture;
      return fixture.copyWith(
        homeScore: result.$1,
        awayScore: result.$2,
        homePenaltyScore: result.$3,
        awayPenaltyScore: result.$4,
        clearPenaltyResult: result.$3 == null || result.$4 == null,
        status: CompetitionFixture.statusCompleted,
      );
    }).toList(growable: false);
  }

  static String _fixtureResultSignature(CompetitionFixture fixture) {
    return '${fixture.isCancelled}:${fixture.homeScore}:${fixture.awayScore}:'
        '${fixture.homePenaltyScore}:${fixture.awayPenaltyScore}';
  }

  static List<CompetitionFixture> _clearDependentFixtureResults({
    required List<CompetitionFixture> fixtures,
    required String sourceFixtureId,
  }) {
    final affectedIds = <String>{sourceFixtureId};
    var added = true;
    while (added) {
      added = false;
      for (final fixture in fixtures) {
        if (affectedIds.contains(fixture.id)) continue;
        if (affectedIds.contains(fixture.sourceHomeFixtureId) ||
            affectedIds.contains(fixture.sourceAwayFixtureId)) {
          affectedIds.add(fixture.id);
          added = true;
        }
      }
    }
    return fixtures.map((fixture) {
      if (fixture.id == sourceFixtureId || !affectedIds.contains(fixture.id)) {
        return fixture;
      }
      return fixture.copyWith(
        clearResult: true,
        clearPenaltyResult: true,
        status: fixture.status == CompetitionFixture.statusCompleted
            ? CompetitionFixture.statusScheduled
            : fixture.status,
      );
    }).toList(growable: false);
  }

  static String competitionId({
    required String kind,
    required String name,
  }) {
    return '$kind:${_normalizeKey(name)}';
  }

  static int normalizeLeagueLegs(int value) => value == 2 ? 2 : 1;

  static String normalizeLeagueTieBreaker(String value) {
    switch (value.trim()) {
      case MatchCompetitionRecord.tieBreakerWins:
        return MatchCompetitionRecord.tieBreakerWins;
      case MatchCompetitionRecord.tieBreakerGoalsFor:
        return MatchCompetitionRecord.tieBreakerGoalsFor;
      case MatchCompetitionRecord.tieBreakerGoalDifference:
      default:
        return MatchCompetitionRecord.tieBreakerGoalDifference;
    }
  }

  static int normalizeFixtureInterval(int value) => value.clamp(1, 30);

  static String normalizeTeamKey(String value) => _normalizeKey(value);

  static CompetitionFixtureRebuildImpact fixtureRebuildImpact({
    required MatchCompetitionRecord existing,
    required MatchCompetitionRecord updated,
  }) {
    final normalizedUpdated = updated.copyWith(
      teams: normalizeTeams(updated.teams),
      leagueLegs: normalizeLeagueLegs(updated.leagueLegs),
    );
    final structureChanged = _fixtureStructureChanged(
      existing,
      normalizedUpdated,
    );
    if (!structureChanged) {
      return CompetitionFixtureRebuildImpact(
        requiresRebuild: false,
        currentFixtureCount: existing.fixtures.length,
        nextFixtureCount: existing.fixtures.length,
        changedFixtureCount: 0,
        clearedResultCount: 0,
      );
    }

    final rebuilt = _rebuildFixtures(
      existing: existing,
      updated: normalizedUpdated,
      fixtureStructureChanged: true,
      fixtureScheduleChanged:
          _fixtureScheduleChanged(existing, normalizedUpdated),
    );
    final nextByDefinition = <String, CompetitionFixture>{
      for (final fixture in rebuilt) _fixtureDefinitionKey(fixture): fixture,
    };
    var changedFixtureCount = 0;
    var clearedResultCount = 0;
    for (final fixture in existing.fixtures) {
      final next = nextByDefinition[_fixtureDefinitionKey(fixture)];
      if (next == null ||
          _fixtureResultSignature(next) != _fixtureResultSignature(fixture)) {
        changedFixtureCount += 1;
      }
      if (fixture.hasResult &&
          (next == null ||
              _fixtureResultSignature(next) !=
                  _fixtureResultSignature(fixture))) {
        clearedResultCount += 1;
      }
    }
    changedFixtureCount += (rebuilt.length - existing.fixtures.length)
        .clamp(0, rebuilt.length)
        .toInt();
    return CompetitionFixtureRebuildImpact(
      requiresRebuild: true,
      currentFixtureCount: existing.fixtures.length,
      nextFixtureCount: rebuilt.length,
      changedFixtureCount: changedFixtureCount,
      clearedResultCount: clearedResultCount,
    );
  }

  static List<CompetitionScheduleIssue> scheduleIssues({
    required MatchCompetitionRecord competition,
    int minimumRestDays = 2,
  }) {
    final fixtures = competition.fixtures
        .where(
          (fixture) => fixture.scheduledAt != null && !fixture.isCancelled,
        )
        .toList(growable: false);
    if (fixtures.length < 2) return const <CompetitionScheduleIssue>[];

    final issues = <CompetitionScheduleIssue>[];
    final issueKeys = <String>{};
    void addIssue(String type, Iterable<String> fixtureIds) {
      final ids = fixtureIds.toSet().toList()..sort();
      if (ids.length < 2) return;
      final key = '$type:${ids.join(',')}';
      if (!issueKeys.add(key)) return;
      issues.add(CompetitionScheduleIssue(type: type, fixtureIds: ids));
    }

    String dateKey(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final venueByTime = <String, List<CompetitionFixture>>{};
    final teamByDate = <String, List<CompetitionFixture>>{};
    final fixturesByTeam = <String, List<CompetitionFixture>>{};
    for (final fixture in fixtures) {
      final scheduledAt = fixture.scheduledAt!;
      final day = dateKey(scheduledAt);
      final venue = fixture.venue.trim();
      if (venue.isNotEmpty) {
        final time =
            '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
        venueByTime
            .putIfAbsent('$day:$time:${_normalizeKey(venue)}', () => [])
            .add(fixture);
      }
      for (final team in [fixture.homeTeam, fixture.awayTeam]) {
        final teamKey = _normalizeKey(team);
        if (teamKey.isEmpty) continue;
        teamByDate.putIfAbsent('$day:$teamKey', () => []).add(fixture);
        fixturesByTeam.putIfAbsent(teamKey, () => []).add(fixture);
      }
    }

    for (final sameVenue in venueByTime.values) {
      addIssue(
        CompetitionScheduleIssue.typeVenueOverlap,
        sameVenue.map((fixture) => fixture.id),
      );
    }
    for (final sameTeam in teamByDate.values) {
      addIssue(
        CompetitionScheduleIssue.typeTeamOverlap,
        sameTeam.map((fixture) => fixture.id),
      );
    }
    final normalizedRestDays = minimumRestDays.clamp(1, 14).toInt();
    for (final teamFixtures in fixturesByTeam.values) {
      final ordered = [...teamFixtures]..sort(
          (first, second) => first.scheduledAt!.compareTo(second.scheduledAt!),
        );
      for (var index = 1; index < ordered.length; index += 1) {
        final previous = ordered[index - 1].scheduledAt!;
        final current = ordered[index].scheduledAt!;
        final gap = DateTime(
          current.year,
          current.month,
          current.day,
        )
            .difference(DateTime(previous.year, previous.month, previous.day))
            .inDays;
        if (gap < normalizedRestDays) {
          addIssue(
            CompetitionScheduleIssue.typeShortRest,
            [ordered[index - 1].id, ordered[index].id],
          );
        }
      }
    }
    return List<CompetitionScheduleIssue>.unmodifiable(issues);
  }

  static Map<String, List<String>> scheduleIssueTypesByFixture({
    required MatchCompetitionRecord competition,
    int minimumRestDays = 2,
  }) {
    final typesByFixture = <String, List<String>>{};
    for (final issue in scheduleIssues(
      competition: competition,
      minimumRestDays: minimumRestDays,
    )) {
      for (final fixtureId in issue.fixtureIds) {
        final fixtureTypes = typesByFixture.putIfAbsent(
          fixtureId,
          () => <String>[],
        );
        if (!fixtureTypes.contains(issue.type)) {
          fixtureTypes.add(issue.type);
        }
      }
    }
    return Map<String, List<String>>.unmodifiable({
      for (final entry in typesByFixture.entries)
        entry.key: List<String>.unmodifiable(entry.value),
    });
  }

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

  static MatchCompetitionRecord? _competitionWithSameName(
    Iterable<MatchCompetitionRecord> records,
    MatchCompetitionRecord record,
  ) {
    final nameKey = _normalizeKey(record.name);
    if (nameKey.isEmpty) return null;
    for (final current in records) {
      if (current.kind == record.kind &&
          _normalizeKey(current.name) == nameKey) {
        return current;
      }
    }
    return null;
  }

  static bool _fixtureStructureChanged(
    MatchCompetitionRecord existing,
    MatchCompetitionRecord updated,
  ) {
    if (existing.kind != updated.kind ||
        existing.leagueLegs != updated.leagueLegs) {
      return true;
    }
    final previousTeams = normalizeTeams(existing.teams);
    final nextTeams = normalizeTeams(updated.teams);
    if (previousTeams.length != nextTeams.length) return true;
    for (var index = 0; index < previousTeams.length; index += 1) {
      if (normalizeTeamKey(previousTeams[index]) !=
          normalizeTeamKey(nextTeams[index])) {
        return true;
      }
    }
    return false;
  }

  static bool _fixtureScheduleChanged(
    MatchCompetitionRecord existing,
    MatchCompetitionRecord updated,
  ) {
    return !_sameScheduleDate(
          existing.fixtureStartDate,
          updated.fixtureStartDate,
        ) ||
        existing.fixtureIntervalDays != updated.fixtureIntervalDays;
  }

  static bool _sameScheduleDate(DateTime? first, DateTime? second) {
    if (first == null || second == null) return first == second;
    return first.isAtSameMomentAs(second);
  }

  static List<CompetitionFixture> _rebuildFixtures({
    required MatchCompetitionRecord existing,
    required MatchCompetitionRecord updated,
    required bool fixtureStructureChanged,
    required bool fixtureScheduleChanged,
  }) {
    final previousByDefinition = <String, CompetitionFixture>{
      for (final fixture in existing.fixtures)
        _fixtureDefinitionKey(fixture): fixture,
    };
    return buildFixtures(updated).map((fixture) {
      final previous = previousByDefinition[_fixtureDefinitionKey(fixture)];
      if (previous == null) return fixture;
      return _carryFixtureDetails(
        generated: fixture,
        previous: previous,
        existing: existing,
        fixtureStructureChanged: fixtureStructureChanged,
        fixtureScheduleChanged: fixtureScheduleChanged,
      );
    }).toList(growable: false);
  }

  static List<CompetitionFixture> _synchronizeFixtureVenue({
    required MatchCompetitionRecord existing,
    required MatchCompetitionRecord updated,
  }) {
    if (existing.venue.trim() == updated.venue.trim()) {
      return existing.fixtures;
    }
    return existing.fixtures.map((fixture) {
      if (fixture.venue.trim() != existing.venue.trim()) return fixture;
      return fixture.copyWith(venue: updated.venue);
    }).toList(growable: false);
  }

  static CompetitionFixture _carryFixtureDetails({
    required CompetitionFixture generated,
    required CompetitionFixture previous,
    required MatchCompetitionRecord existing,
    required bool fixtureStructureChanged,
    required bool fixtureScheduleChanged,
  }) {
    var carried = generated;
    if (!fixtureScheduleChanged && previous.scheduledAt != null) {
      carried = carried.copyWith(scheduledAt: previous.scheduledAt);
    }
    if (previous.venue.trim() != existing.venue.trim()) {
      carried = carried.copyWith(venue: previous.venue);
    }

    final canKeepResult = !fixtureStructureChanged ||
        generated.stage.isEmpty ||
        generated.sourceHomeFixtureId == null &&
            generated.sourceAwayFixtureId == null;
    if (!canKeepResult) return carried;

    return carried.copyWith(
      status: previous.status,
      homeScore: previous.homeScore,
      awayScore: previous.awayScore,
      homePenaltyScore: previous.homePenaltyScore,
      awayPenaltyScore: previous.awayPenaltyScore,
    );
  }

  static String _fixtureDefinitionKey(CompetitionFixture fixture) {
    return [
      fixture.roundNumber,
      fixture.stage.trim(),
      normalizeTeamKey(fixture.homeTeam),
      normalizeTeamKey(fixture.awayTeam),
      fixture.sourceHomeFixtureId?.trim() ?? '',
      fixture.sourceAwayFixtureId?.trim() ?? '',
    ].join('|');
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
      final entryScores = fixture.hasResult
          ? null
          : _scoresForEntry(
              entry: resultEntry,
              homeTeam: homeTeam,
              awayTeam: awayTeam,
            );
      final homeScore = fixture.homeScore ?? entryScores?.$1;
      final awayScore = fixture.awayScore ?? entryScores?.$2;
      final homePenaltyScore = fixture.homePenaltyScore ?? entryScores?.$3;
      final awayPenaltyScore = fixture.awayPenaltyScore ?? entryScores?.$4;
      final winner = _winnerForFixture(
        competition: competition,
        fixture: fixture,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        homeScore: homeScore,
        awayScore: awayScore,
        homePenaltyScore: homePenaltyScore,
        awayPenaltyScore: awayPenaltyScore,
      );
      final resolved = CompetitionFixtureState(
        competition: competition,
        fixture: fixture,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        resultEntry: resultEntry,
        homeScore: homeScore,
        awayScore: awayScore,
        homePenaltyScore: homePenaltyScore,
        awayPenaltyScore: awayPenaltyScore,
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
    String leagueTieBreaker = MatchCompetitionRecord.tieBreakerGoalDifference,
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

    return _sortLeagueStandings(
      rows.values.where((row) => row.team.trim().isNotEmpty),
      leagueTieBreaker: leagueTieBreaker,
    );
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

    return _sortLeagueStandings(
      rows.values,
      leagueTieBreaker: competition.leagueTieBreaker,
    );
  }

  static List<LeagueStandingRow> _sortLeagueStandings(
    Iterable<LeagueStandingRow> rows, {
    required String leagueTieBreaker,
  }) {
    final tieBreaker = normalizeLeagueTieBreaker(leagueTieBreaker);
    final sorted = rows.toList(growable: false)
      ..sort((first, second) {
        final pointsCompare = second.points.compareTo(first.points);
        if (pointsCompare != 0) return pointsCompare;

        int compareBy(int Function(LeagueStandingRow row) selector) =>
            selector(second).compareTo(selector(first));

        final firstTieCompare = switch (tieBreaker) {
          MatchCompetitionRecord.tieBreakerWins => compareBy((row) => row.wins),
          MatchCompetitionRecord.tieBreakerGoalsFor =>
            compareBy((row) => row.goalsFor),
          _ => compareBy((row) => row.goalDifference),
        };
        if (firstTieCompare != 0) return firstTieCompare;

        final secondTieCompare = switch (tieBreaker) {
          MatchCompetitionRecord.tieBreakerWins =>
            compareBy((row) => row.goalDifference),
          MatchCompetitionRecord.tieBreakerGoalsFor =>
            compareBy((row) => row.goalDifference),
          _ => compareBy((row) => row.goalsFor),
        };
        if (secondTieCompare != 0) return secondTieCompare;

        final finalTieCompare = switch (tieBreaker) {
          MatchCompetitionRecord.tieBreakerWins =>
            compareBy((row) => row.goalsFor),
          MatchCompetitionRecord.tieBreakerGoalsFor =>
            compareBy((row) => row.wins),
          _ => compareBy((row) => row.wins),
        };
        if (finalTieCompare != 0) return finalTieCompare;
        return first.team.compareTo(second.team);
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
    return startDate.add(
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

  static (int, int, int?, int?)? _scoresForEntry({
    required TrainingEntry? entry,
    required String homeTeam,
    required String awayTeam,
  }) {
    if (entry == null ||
        entry.scoredGoals == null ||
        entry.concededGoals == null ||
        homeTeam.isEmpty ||
        awayTeam.isEmpty) {
      return null;
    }
    final opponentKey = _normalizeKey(entry.opponentTeam);
    final homeKey = _normalizeKey(homeTeam);
    final awayKey = _normalizeKey(awayTeam);
    if (opponentKey == awayKey) {
      return (
        entry.scoredGoals!,
        entry.concededGoals!,
        entry.penaltyShootoutGoalsFor,
        entry.penaltyShootoutGoalsAgainst,
      );
    }
    if (opponentKey == homeKey) {
      return (
        entry.concededGoals!,
        entry.scoredGoals!,
        entry.penaltyShootoutGoalsAgainst,
        entry.penaltyShootoutGoalsFor,
      );
    }
    return null;
  }

  static String _winnerForFixture({
    required MatchCompetitionRecord competition,
    required CompetitionFixture fixture,
    required String homeTeam,
    required String awayTeam,
    required int? homeScore,
    required int? awayScore,
    required int? homePenaltyScore,
    required int? awayPenaltyScore,
  }) {
    if (fixture.isCancelled) return '';
    if (homeTeam.isEmpty || awayTeam.isEmpty) {
      return homeTeam.isNotEmpty ? homeTeam : awayTeam;
    }
    if (competition.kind != MatchCompetitionRecord.kindTournament ||
        homeScore == null ||
        awayScore == null) {
      return '';
    }
    if (homeScore > awayScore) return homeTeam;
    if (awayScore > homeScore) return awayTeam;
    if (homePenaltyScore == null || awayPenaltyScore == null) return '';
    if (homePenaltyScore > awayPenaltyScore) return homeTeam;
    if (awayPenaltyScore > homePenaltyScore) return awayTeam;
    return '';
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
