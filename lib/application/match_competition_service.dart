import 'dart:convert';

import '../domain/entities/training_entry.dart';
import '../domain/repositories/option_repository.dart';

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
  final DateTime createdAt;
  final DateTime updatedAt;

  const MatchCompetitionRecord({
    required this.id,
    required this.kind,
    required this.name,
    required this.teams,
    this.status = statusActive,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isFinished => status == statusFinished;

  factory MatchCompetitionRecord.create({
    required String kind,
    required String name,
    required List<String> teams,
    String status = statusActive,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return MatchCompetitionRecord(
      id: MatchCompetitionService.competitionId(kind: kind, name: name),
      kind: kind,
      name: name.trim(),
      teams: MatchCompetitionService.normalizeTeams(teams),
      status: MatchCompetitionService.normalizeStatus(status),
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

  const TournamentBracketPair({
    required this.slotNumber,
    required this.teamA,
    required this.teamB,
  });

  bool get hasBye => teamB.trim().isEmpty;
}

class MatchCompetitionService {
  static const String storageKey = 'match_competitions_v1';

  final OptionRepository _optionRepository;

  const MatchCompetitionService(this._optionRepository);

  List<MatchCompetitionRecord> allCompetitions() {
    final raw = _optionRepository.getValue<String>(storageKey);
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
    if (name.isEmpty || entry.leagueTeamNames.isEmpty) return;
    final kind = entry.isTournamentMatch
        ? MatchCompetitionRecord.kindTournament
        : MatchCompetitionRecord.kindLeague;
    final existing = findCompetition(kind: kind, name: name);
    final teams = normalizeTeams([
      ...?existing?.teams,
      ...entry.leagueTeamNames,
    ]);
    await upsertCompetition(
      MatchCompetitionRecord.create(
        kind: kind,
        name: name,
        teams: teams,
        status: existing?.status ?? MatchCompetitionRecord.statusActive,
      ),
    );
  }

  Future<void> _saveAll(List<MatchCompetitionRecord> records) {
    final normalized = [...records]..sort(_compareCompetitionRecords);
    return _optionRepository.setValue(
      storageKey,
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
  }) {
    final matchingEntries = competitionEntries(
      kind: MatchCompetitionRecord.kindLeague,
      competitionName: competitionName,
      entries: entries,
    );
    final teams = normalizeTeams([
      ...registeredTeams,
      for (final entry in matchingEntries) ...entry.leagueTeamNames,
      for (final entry in matchingEntries) entry.opponentTeam,
    ]);
    final ownTeam = teams.isNotEmpty ? teams.first : ownTeamName.trim();
    if (ownTeam.isNotEmpty && !teams.any((team) => team == ownTeam)) {
      teams.insert(0, ownTeam);
    }

    final rows = <String, LeagueStandingRow>{
      for (final team in teams) team: LeagueStandingRow(team: team),
    };

    LeagueStandingRow ensureRow(String team) {
      final trimmed = team.trim();
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
      final opponent = entry.opponentTeam.trim();
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
    final teams = normalizeTeams(registeredTeams);
    final pairs = <TournamentBracketPair>[];
    for (var index = 0; index < teams.length; index += 2) {
      pairs.add(
        TournamentBracketPair(
          slotNumber: pairs.length + 1,
          teamA: teams[index],
          teamB: index + 1 < teams.length ? teams[index + 1] : '',
        ),
      );
    }
    return pairs;
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
