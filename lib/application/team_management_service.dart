import 'dart:convert';

import '../domain/repositories/option_repository.dart';
import 'sport_scoped_storage.dart';

class ManagedTeamPlayer {
  static const String roleGoalkeeper = 'goalkeeper';
  static const String roleDefender = 'defender';
  static const String roleMidfielder = 'midfielder';
  static const String roleForward = 'forward';
  static const String footRight = 'right';
  static const String footLeft = 'left';
  static const String footBoth = 'both';
  static const String conditionReady = 'ready';
  static const String conditionWatch = 'watch';
  static const String conditionRest = 'rest';

  final String id;
  final String name;
  final String number;
  final String role;
  final String foot;
  final String condition;
  final String note;

  const ManagedTeamPlayer({
    required this.id,
    required this.name,
    this.number = '',
    this.role = roleForward,
    this.foot = footRight,
    this.condition = conditionReady,
    this.note = '',
  });

  factory ManagedTeamPlayer.create({
    required String name,
    String number = '',
    String role = roleForward,
    String foot = footRight,
    String condition = conditionReady,
    String note = '',
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return ManagedTeamPlayer(
      id: TeamManagementService.playerId(name: name, now: timestamp),
      name: name.trim(),
      number: number.trim(),
      role: TeamManagementService.normalizePlayerRole(role),
      foot: TeamManagementService.normalizePlayerFoot(foot),
      condition: TeamManagementService.normalizePlayerCondition(condition),
      note: note.trim(),
    );
  }

  factory ManagedTeamPlayer.fromMap(Map<String, dynamic> map) {
    return ManagedTeamPlayer(
      id: map['id']?.toString().trim() ?? '',
      name: map['name']?.toString().trim() ?? '',
      number: map['number']?.toString().trim() ?? '',
      role: TeamManagementService.normalizePlayerRole(
        map['role']?.toString() ?? '',
      ),
      foot: TeamManagementService.normalizePlayerFoot(
        map['foot']?.toString() ?? '',
      ),
      condition: TeamManagementService.normalizePlayerCondition(
        map['condition']?.toString() ?? '',
      ),
      note: map['note']?.toString().trim() ?? '',
    );
  }

  ManagedTeamPlayer copyWith({
    String? id,
    String? name,
    String? number,
    String? role,
    String? foot,
    String? condition,
    String? note,
  }) {
    return ManagedTeamPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      role: TeamManagementService.normalizePlayerRole(role ?? this.role),
      foot: TeamManagementService.normalizePlayerFoot(foot ?? this.foot),
      condition: TeamManagementService.normalizePlayerCondition(
        condition ?? this.condition,
      ),
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'number': number,
      'role': role,
      'foot': foot,
      'condition': condition,
      'note': note,
    };
  }
}

class ManagedTacticLine {
  static const String typeMovement = 'movement';
  static const String typePress = 'press';
  static const String typeZone = 'zone';

  final String id;
  final String type;
  final double startX;
  final double startY;
  final double endX;
  final double endY;

  const ManagedTacticLine({
    required this.id,
    this.type = typeMovement,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
  });

  factory ManagedTacticLine.create({
    String type = typeMovement,
    required double startX,
    required double startY,
    required double endX,
    required double endY,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return ManagedTacticLine(
      id: TeamManagementService.tacticLineId(now: timestamp),
      type: TeamManagementService.normalizeTacticMarkerType(type),
      startX: TeamManagementService.normalizeBoardCoordinate(startX),
      startY: TeamManagementService.normalizeBoardCoordinate(startY),
      endX: TeamManagementService.normalizeBoardCoordinate(endX),
      endY: TeamManagementService.normalizeBoardCoordinate(endY),
    );
  }

  factory ManagedTacticLine.fromMap(Map<String, dynamic> map) {
    return ManagedTacticLine(
      id: map['id']?.toString().trim() ?? '',
      type: TeamManagementService.normalizeTacticMarkerType(
        map['type']?.toString() ?? '',
      ),
      startX: TeamManagementService.normalizeBoardCoordinate(map['startX']),
      startY: TeamManagementService.normalizeBoardCoordinate(map['startY']),
      endX: TeamManagementService.normalizeBoardCoordinate(map['endX']),
      endY: TeamManagementService.normalizeBoardCoordinate(map['endY']),
    );
  }

  ManagedTacticLine copyWith({
    String? id,
    String? type,
    double? startX,
    double? startY,
    double? endX,
    double? endY,
  }) {
    return ManagedTacticLine(
      id: id ?? this.id,
      type: TeamManagementService.normalizeTacticMarkerType(type ?? this.type),
      startX: TeamManagementService.normalizeBoardCoordinate(
        startX ?? this.startX,
      ),
      startY: TeamManagementService.normalizeBoardCoordinate(
        startY ?? this.startY,
      ),
      endX: TeamManagementService.normalizeBoardCoordinate(endX ?? this.endX),
      endY: TeamManagementService.normalizeBoardCoordinate(endY ?? this.endY),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'startX': startX,
      'startY': startY,
      'endX': endX,
      'endY': endY,
    };
  }
}

class ManagedPlayerPlacement {
  final String playerId;
  final double x;
  final double y;

  const ManagedPlayerPlacement({
    required this.playerId,
    required this.x,
    required this.y,
  });

  factory ManagedPlayerPlacement.create({
    required String playerId,
    required double x,
    required double y,
  }) {
    return ManagedPlayerPlacement(
      playerId: playerId.trim(),
      x: TeamManagementService.normalizeBoardCoordinate(x),
      y: TeamManagementService.normalizeBoardCoordinate(y),
    );
  }

  factory ManagedPlayerPlacement.fromMap(Map<String, dynamic> map) {
    return ManagedPlayerPlacement.create(
      playerId: map['playerId']?.toString() ?? '',
      x: map['x'],
      y: map['y'],
    );
  }

  ManagedPlayerPlacement copyWith({
    String? playerId,
    double? x,
    double? y,
  }) {
    return ManagedPlayerPlacement.create(
      playerId: playerId ?? this.playerId,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'playerId': playerId,
      'x': x,
      'y': y,
    };
  }
}

class ManagedTeam {
  static const String defaultFormation = '4-3-3';

  final String id;
  final String name;
  final String formation;
  final String strategy;
  final List<ManagedTeamPlayer> players;
  final Map<String, String> lineup;
  final Map<String, ManagedPlayerPlacement> playerPlacements;
  final List<ManagedTacticLine> tacticLines;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ManagedTeam({
    required this.id,
    required this.name,
    this.formation = defaultFormation,
    this.strategy = '',
    this.players = const <ManagedTeamPlayer>[],
    this.lineup = const <String, String>{},
    this.playerPlacements = const <String, ManagedPlayerPlacement>{},
    this.tacticLines = const <ManagedTacticLine>[],
    required this.createdAt,
    required this.updatedAt,
  });

  int get filledLineupCount {
    if (playerPlacements.isNotEmpty) return playerPlacements.length;
    return lineup.values.where((id) => id.isNotEmpty).length;
  }

  factory ManagedTeam.create({
    required String name,
    String formation = defaultFormation,
    String strategy = '',
    List<ManagedTeamPlayer> players = const <ManagedTeamPlayer>[],
    Map<String, String> lineup = const <String, String>{},
    Map<String, ManagedPlayerPlacement> playerPlacements =
        const <String, ManagedPlayerPlacement>{},
    List<ManagedTacticLine> tacticLines = const <ManagedTacticLine>[],
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final normalizedPlayers = TeamManagementService.normalizePlayers(players);
    final normalizedFormation =
        TeamManagementService.normalizeFormation(formation);
    final normalizedLineup = TeamManagementService.normalizeLineup(
      lineup: lineup,
      players: normalizedPlayers,
      formation: normalizedFormation,
    );
    final normalizedPlacements =
        TeamManagementService.normalizePlayerPlacements(
      placements: playerPlacements,
      players: normalizedPlayers,
    );
    return ManagedTeam(
      id: TeamManagementService.teamId(name: name, now: timestamp),
      name: name.trim(),
      formation: normalizedFormation,
      strategy: strategy.trim(),
      players: normalizedPlayers,
      lineup: normalizedLineup,
      playerPlacements: normalizedPlacements.isNotEmpty
          ? normalizedPlacements
          : TeamManagementService.placementsFromLineup(
              lineup: normalizedLineup,
              players: normalizedPlayers,
              formation: normalizedFormation,
            ),
      tacticLines: TeamManagementService.normalizeTacticLines(tacticLines),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  factory ManagedTeam.fromMap(Map<String, dynamic> map) {
    final createdAt = DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final updatedAt =
        DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? createdAt;
    final players = map['players'] is List
        ? (map['players'] as List)
            .whereType<Map>()
            .map((item) => ManagedTeamPlayer.fromMap(
                  item.cast<String, dynamic>(),
                ))
            .where((player) =>
                player.id.trim().isNotEmpty && player.name.trim().isNotEmpty)
            .toList(growable: false)
        : const <ManagedTeamPlayer>[];
    final formation = TeamManagementService.normalizeFormation(
      map['formation']?.toString() ?? '',
    );
    final lineup = map['lineup'] is Map
        ? (map['lineup'] as Map).map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          )
        : const <String, String>{};
    final playerPlacements = map['playerPlacements'] is Map
        ? (map['playerPlacements'] as Map).map(
            (key, value) {
              final raw = value is Map
                  ? value.cast<String, dynamic>()
                  : <String, dynamic>{};
              return MapEntry(
                key.toString(),
                ManagedPlayerPlacement.fromMap({
                  ...raw,
                  'playerId': raw['playerId'] ?? key.toString(),
                }),
              );
            },
          )
        : const <String, ManagedPlayerPlacement>{};
    final tacticLines = map['tacticLines'] is List
        ? (map['tacticLines'] as List)
            .whereType<Map>()
            .map((item) => ManagedTacticLine.fromMap(
                  item.cast<String, dynamic>(),
                ))
            .toList(growable: false)
        : const <ManagedTacticLine>[];
    final normalizedPlayers = TeamManagementService.normalizePlayers(players);
    final normalizedLineup = TeamManagementService.normalizeLineup(
      lineup: lineup,
      players: normalizedPlayers,
      formation: formation,
    );
    final normalizedPlacements =
        TeamManagementService.normalizePlayerPlacements(
      placements: playerPlacements,
      players: normalizedPlayers,
    );
    return ManagedTeam(
      id: map['id']?.toString().trim().isNotEmpty == true
          ? map['id'].toString()
          : TeamManagementService.teamId(
              name: map['name']?.toString() ?? '',
              now: createdAt,
            ),
      name: map['name']?.toString().trim() ?? '',
      formation: formation,
      strategy: map['strategy']?.toString().trim() ?? '',
      players: normalizedPlayers,
      lineup: normalizedLineup,
      playerPlacements: normalizedPlacements.isNotEmpty
          ? normalizedPlacements
          : TeamManagementService.placementsFromLineup(
              lineup: normalizedLineup,
              players: normalizedPlayers,
              formation: formation,
            ),
      tacticLines: TeamManagementService.normalizeTacticLines(tacticLines),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  ManagedTeam copyWith({
    String? id,
    String? name,
    String? formation,
    String? strategy,
    List<ManagedTeamPlayer>? players,
    Map<String, String>? lineup,
    Map<String, ManagedPlayerPlacement>? playerPlacements,
    List<ManagedTacticLine>? tacticLines,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final nextFormation =
        TeamManagementService.normalizeFormation(formation ?? this.formation);
    final nextPlayers =
        TeamManagementService.normalizePlayers(players ?? this.players);
    final nextLineup = TeamManagementService.normalizeLineup(
      lineup: lineup ?? this.lineup,
      players: nextPlayers,
      formation: nextFormation,
    );
    return ManagedTeam(
      id: id ?? this.id,
      name: name ?? this.name,
      formation: nextFormation,
      strategy: strategy ?? this.strategy,
      players: nextPlayers,
      lineup: nextLineup,
      playerPlacements: TeamManagementService.normalizePlayerPlacements(
        placements: playerPlacements ?? this.playerPlacements,
        players: nextPlayers,
      ),
      tacticLines: TeamManagementService.normalizeTacticLines(
        tacticLines ?? this.tacticLines,
      ),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'formation': formation,
      'strategy': strategy,
      'players': players.map((player) => player.toMap()).toList(),
      'lineup': lineup,
      'playerPlacements': playerPlacements.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'tacticLines': tacticLines.map((line) => line.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class TeamFormationSpot {
  final String id;
  final String label;
  final String role;
  final double x;
  final double y;

  const TeamFormationSpot({
    required this.id,
    required this.label,
    required this.role,
    required this.x,
    required this.y,
  });
}

class TeamManagementService {
  static const String storageKey = 'match_managed_teams_v1';
  static const List<String> supportedFormations = <String>[
    '4-3-3',
    '4-4-2',
    '4-2-3-1',
    '3-5-2',
  ];

  final OptionRepository _optionRepository;
  final String? _sportId;

  const TeamManagementService(this._optionRepository, {String? sportId})
      : _sportId = sportId;

  String get _storageKey => sportScopedOptionKey(
        _optionRepository,
        storageKey,
        sportId: _sportId,
      );

  List<ManagedTeam> allTeams() {
    final raw = _optionRepository.getValue<String>(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <ManagedTeam>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <ManagedTeam>[];
      return decoded
          .whereType<Map>()
          .map((item) => ManagedTeam.fromMap(item.cast<String, dynamic>()))
          .where((team) => team.id.isNotEmpty && team.name.isNotEmpty)
          .toList(growable: false)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return const <ManagedTeam>[];
    }
  }

  ManagedTeam? findTeamById(String id) {
    final key = id.trim();
    if (key.isEmpty) return null;
    for (final team in allTeams()) {
      if (team.id == key) return team;
    }
    return null;
  }

  Future<void> upsertTeam(ManagedTeam team) async {
    final now = DateTime.now();
    final normalized = team.copyWith(
      name: team.name.trim(),
      updatedAt: now,
    );
    if (normalized.name.isEmpty) return;

    final next = <ManagedTeam>[];
    var createdAt = normalized.createdAt;
    for (final current in allTeams()) {
      if (current.id == normalized.id) {
        createdAt = current.createdAt;
        continue;
      }
      next.add(current);
    }
    next.add(normalized.copyWith(createdAt: createdAt));
    await _saveAll(next);
  }

  Future<void> deleteTeam(String id) async {
    final key = id.trim();
    if (key.isEmpty) return;
    final next =
        allTeams().where((team) => team.id != key).toList(growable: false);
    await _saveAll(next);
  }

  Future<void> _saveAll(List<ManagedTeam> teams) {
    final normalized = [...teams]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return _optionRepository.setValue(
      _storageKey,
      jsonEncode(normalized.map((team) => team.toMap()).toList()),
    );
  }

  static String teamId({required String name, required DateTime now}) {
    return 'team:${_normalizeKey(name)}:${now.microsecondsSinceEpoch}';
  }

  static String playerId({required String name, required DateTime now}) {
    return 'player:${_normalizeKey(name)}:${now.microsecondsSinceEpoch}';
  }

  static String tacticLineId({required DateTime now}) {
    return 'tactic-line:${now.microsecondsSinceEpoch}';
  }

  static String normalizeFormation(String formation) {
    return supportedFormations.contains(formation)
        ? formation
        : ManagedTeam.defaultFormation;
  }

  static String normalizePlayerRole(String role) {
    return switch (role) {
      ManagedTeamPlayer.roleGoalkeeper => ManagedTeamPlayer.roleGoalkeeper,
      ManagedTeamPlayer.roleDefender => ManagedTeamPlayer.roleDefender,
      ManagedTeamPlayer.roleMidfielder => ManagedTeamPlayer.roleMidfielder,
      _ => ManagedTeamPlayer.roleForward,
    };
  }

  static String normalizePlayerFoot(String foot) {
    return switch (foot) {
      ManagedTeamPlayer.footLeft => ManagedTeamPlayer.footLeft,
      ManagedTeamPlayer.footBoth => ManagedTeamPlayer.footBoth,
      _ => ManagedTeamPlayer.footRight,
    };
  }

  static String normalizePlayerCondition(String condition) {
    return switch (condition) {
      ManagedTeamPlayer.conditionWatch => ManagedTeamPlayer.conditionWatch,
      ManagedTeamPlayer.conditionRest => ManagedTeamPlayer.conditionRest,
      _ => ManagedTeamPlayer.conditionReady,
    };
  }

  static String normalizeTacticMarkerType(String type) {
    return switch (type) {
      ManagedTacticLine.typePress => ManagedTacticLine.typePress,
      ManagedTacticLine.typeZone => ManagedTacticLine.typeZone,
      _ => ManagedTacticLine.typeMovement,
    };
  }

  static double normalizeBoardCoordinate(Object? value) {
    final number = switch (value) {
      num() => value.toDouble(),
      String() => double.tryParse(value) ?? 0.0,
      _ => 0.0,
    };
    return number.clamp(0.0, 1.0).toDouble();
  }

  static List<ManagedTeamPlayer> normalizePlayers(
    Iterable<ManagedTeamPlayer> values,
  ) {
    final seen = <String>{};
    final players = <ManagedTeamPlayer>[];
    for (final player in values) {
      final id = player.id.trim();
      final name = player.name.trim();
      if (id.isEmpty || name.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      players.add(player.copyWith(name: name));
    }
    return players;
  }

  static Map<String, String> normalizeLineup({
    required Map<String, String> lineup,
    required Iterable<ManagedTeamPlayer> players,
    required String formation,
  }) {
    final playerIds = players.map((player) => player.id).toSet();
    final spotIds = formationSpots(formation).map((spot) => spot.id).toSet();
    final normalized = <String, String>{};
    for (final entry in lineup.entries) {
      final spotId = entry.key.trim();
      final playerId = entry.value.trim();
      if (!spotIds.contains(spotId)) continue;
      if (playerId.isEmpty || !playerIds.contains(playerId)) continue;
      normalized[spotId] = playerId;
    }
    return normalized;
  }

  static Map<String, ManagedPlayerPlacement> normalizePlayerPlacements({
    required Map<String, ManagedPlayerPlacement> placements,
    required Iterable<ManagedTeamPlayer> players,
  }) {
    final playerIds = players.map((player) => player.id).toSet();
    final normalized = <String, ManagedPlayerPlacement>{};
    for (final entry in placements.entries) {
      final playerId = entry.value.playerId.trim().isNotEmpty
          ? entry.value.playerId.trim()
          : entry.key.trim();
      if (playerId.isEmpty || !playerIds.contains(playerId)) continue;
      normalized[playerId] = entry.value.copyWith(playerId: playerId);
    }
    return normalized;
  }

  static Map<String, ManagedPlayerPlacement> placementsFromLineup({
    required Map<String, String> lineup,
    required Iterable<ManagedTeamPlayer> players,
    required String formation,
  }) {
    final playerIds = players.map((player) => player.id).toSet();
    final spots = {
      for (final spot in formationSpots(formation)) spot.id: spot,
    };
    final placements = <String, ManagedPlayerPlacement>{};
    for (final entry in lineup.entries) {
      final spot = spots[entry.key.trim()];
      final playerId = entry.value.trim();
      if (spot == null || playerId.isEmpty || !playerIds.contains(playerId)) {
        continue;
      }
      placements[playerId] = ManagedPlayerPlacement.create(
        playerId: playerId,
        x: spot.x,
        y: spot.y,
      );
    }
    return placements;
  }

  static List<ManagedTacticLine> normalizeTacticLines(
    Iterable<ManagedTacticLine> values,
  ) {
    final seen = <String>{};
    final lines = <ManagedTacticLine>[];
    for (final line in values) {
      final id = line.id.trim();
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      lines.add(line.copyWith(id: id));
    }
    return lines;
  }

  static List<TeamFormationSpot> formationSpots(String formation) {
    final normalized = normalizeFormation(formation);
    final shape = normalized
        .split('-')
        .map((part) => int.tryParse(part) ?? 0)
        .where((count) => count > 0)
        .toList(growable: false);
    final spots = <TeamFormationSpot>[
      const TeamFormationSpot(
        id: 'gk',
        label: 'GK',
        role: ManagedTeamPlayer.roleGoalkeeper,
        x: 0.5,
        y: 0.88,
      ),
    ];
    if (shape.isEmpty) return spots;

    final lineYs = _lineYs(shape.length);
    for (var lineIndex = 0; lineIndex < shape.length; lineIndex += 1) {
      final count = shape[lineIndex];
      final role = _roleForLine(lineIndex, shape.length);
      final prefix = _prefixForRole(role);
      final y = lineYs[lineIndex];
      for (var index = 0; index < count; index += 1) {
        final x = (index + 1) / (count + 1);
        spots.add(
          TeamFormationSpot(
            id: '$prefix${index + 1}',
            label: '$prefix${index + 1}',
            role: role,
            x: x,
            y: y,
          ),
        );
      }
    }
    return spots;
  }

  static String _roleForLine(int lineIndex, int lineCount) {
    if (lineIndex == 0) return ManagedTeamPlayer.roleDefender;
    if (lineIndex == lineCount - 1) return ManagedTeamPlayer.roleForward;
    return ManagedTeamPlayer.roleMidfielder;
  }

  static String _prefixForRole(String role) {
    return switch (role) {
      ManagedTeamPlayer.roleDefender => 'DF',
      ManagedTeamPlayer.roleMidfielder => 'MF',
      ManagedTeamPlayer.roleForward => 'FW',
      _ => 'ST',
    };
  }

  static List<double> _lineYs(int lineCount) {
    if (lineCount <= 1) return const <double>[0.46];
    const top = 0.20;
    const bottom = 0.70;
    return List<double>.generate(
      lineCount,
      (index) => bottom - ((bottom - top) * index / (lineCount - 1)),
    );
  }

  static String _normalizeKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
  }
}
