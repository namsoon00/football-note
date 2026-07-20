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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
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
    final normalized = record.copyWith(
      id: competitionId(kind: record.kind, name: record.name),
      name: record.name.trim(),
      teams: normalizeTeams(record.teams),
      status: normalizeStatus(record.status),
      updatedAt: now,
    );
    if (!_supportedKind(normalized.kind) || normalized.name.isEmpty) {
      return;
    }

    final next = <MatchCompetitionRecord>[];
    var createdAt = normalized.createdAt;
    for (final current in allCompetitions()) {
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
    required Iterable<TrainingEntry> entries,
  }) {
    final targetName = _normalizeKey(competitionName);
    return entries.where((entry) {
      final kindMatches = kind == MatchCompetitionRecord.kindTournament
          ? entry.isTournamentMatch
          : entry.isLeagueMatch;
      if (!kindMatches) return false;
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
