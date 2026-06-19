import '../domain/repositories/option_repository.dart';

class CoachPlayerProfile {
  final String id;
  final String displayName;
  final String familyId;
  final String driveEmail;
  final String driveLabel;
  final String driveSubjectId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CoachPlayerProfile({
    required this.id,
    required this.displayName,
    this.familyId = '',
    this.driveEmail = '',
    this.driveLabel = '',
    this.driveSubjectId = '',
    required this.createdAt,
    required this.updatedAt,
  });

  CoachPlayerProfile copyWith({
    String? id,
    String? displayName,
    String? familyId,
    String? driveEmail,
    String? driveLabel,
    String? driveSubjectId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CoachPlayerProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      familyId: familyId ?? this.familyId,
      driveEmail: driveEmail ?? this.driveEmail,
      driveLabel: driveLabel ?? this.driveLabel,
      driveSubjectId: driveSubjectId ?? this.driveSubjectId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'displayName': displayName,
      if (familyId.trim().isNotEmpty) 'familyId': familyId.trim(),
      if (driveEmail.trim().isNotEmpty) 'driveEmail': driveEmail.trim(),
      if (driveLabel.trim().isNotEmpty) 'driveLabel': driveLabel.trim(),
      if (driveSubjectId.trim().isNotEmpty)
        'driveSubjectId': driveSubjectId.trim(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static CoachPlayerProfile? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final id = CoachRosterService.normalizePlayerId(raw['id']?.toString());
    if (id.isEmpty) return null;
    final now = DateTime.now();
    final createdAt =
        DateTime.tryParse(raw['createdAt']?.toString() ?? '') ?? now;
    final updatedAt =
        DateTime.tryParse(raw['updatedAt']?.toString() ?? '') ?? createdAt;
    final displayName = raw['displayName']?.toString().trim() ?? '';
    return CoachPlayerProfile(
      id: id,
      displayName: displayName.isEmpty ? 'Player' : displayName,
      familyId: raw['familyId']?.toString().trim() ?? '',
      driveEmail: raw['driveEmail']?.toString().trim() ?? '',
      driveLabel: raw['driveLabel']?.toString().trim() ?? '',
      driveSubjectId: raw['driveSubjectId']?.toString().trim() ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class CoachRosterState {
  final List<CoachPlayerProfile> players;
  final String activePlayerId;

  const CoachRosterState({
    required this.players,
    required this.activePlayerId,
  });

  CoachPlayerProfile? get activePlayer {
    for (final player in players) {
      if (player.id == activePlayerId) return player;
    }
    return players.isEmpty ? null : players.first;
  }

  bool get hasMultiplePlayers => players.length > 1;
}

class CoachRosterService {
  static const String rosterPlayersKey = 'coach_roster_players_v1';
  static const String activePlayerIdKey = 'coach_active_player_id_v1';
  static const String scopedOptionKeyPrefix = 'coach_player_';
  static const String defaultPlayerId = 'default_player';
  static const String _familyCurrentRoleLocalKey =
      'family_current_role_local_v1';
  static const String _familyChildNameKey = 'family_child_name_v1';
  static const String _familyIdKey = 'family_shared_id_v1';
  static const String _profileNameKey = 'profile_name';
  static const String _coachRoleStorageValue = 'coach';

  final OptionRepository _options;

  CoachRosterService(this._options);

  CoachRosterState loadState() {
    final players = _loadPlayers();
    final storedActive = normalizePlayerId(
      _options.getValue<String>(activePlayerIdKey),
    );
    final activePlayerId = storedActive.isNotEmpty
        ? storedActive
        : (players.isNotEmpty ? players.first.id : '');
    return CoachRosterState(
      players: List<CoachPlayerProfile>.unmodifiable(players),
      activePlayerId: activePlayerId,
    );
  }

  Future<CoachPlayerProfile> ensureActivePlayer() async {
    final state = loadState();
    final active = state.activePlayer;
    if (active != null && state.activePlayerId.isNotEmpty) {
      return active;
    }
    final now = DateTime.now();
    final player = CoachPlayerProfile(
      id: defaultPlayerId,
      displayName: _fallbackPlayerName(),
      familyId: _options.getValue<String>(_familyIdKey)?.trim() ?? '',
      createdAt: now,
      updatedAt: now,
    );
    await _savePlayers(<CoachPlayerProfile>[player], player.id);
    return player;
  }

  Future<CoachPlayerProfile> addPlayer({required String displayName}) async {
    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(displayName, 'displayName');
    }
    final state = loadState();
    final now = DateTime.now();
    final existingIds = state.players.map((player) => player.id).toSet();
    var id = fileSafePlayerId(trimmedName);
    if (id == defaultPlayerId || existingIds.contains(id)) {
      id = 'player_${now.microsecondsSinceEpoch}';
    }
    while (existingIds.contains(id)) {
      id = 'player_${DateTime.now().microsecondsSinceEpoch}';
    }
    final player = CoachPlayerProfile(
      id: id,
      displayName: trimmedName,
      createdAt: now,
      updatedAt: now,
    );
    await _savePlayers(<CoachPlayerProfile>[...state.players, player], id);
    return player;
  }

  Future<void> setActivePlayer(String playerId) async {
    final normalizedId = normalizePlayerId(playerId);
    if (normalizedId.isEmpty) return;
    final state = loadState();
    if (!state.players.any((player) => player.id == normalizedId)) return;
    await _options.setValue(activePlayerIdKey, normalizedId);
  }

  Future<void> upsertPlayer(CoachPlayerProfile player) async {
    final normalizedId = normalizePlayerId(player.id);
    if (normalizedId.isEmpty) return;
    final state = loadState();
    final now = DateTime.now();
    final next = <CoachPlayerProfile>[];
    var replaced = false;
    for (final existing in state.players) {
      if (existing.id == normalizedId) {
        next.add(
          player.copyWith(
            id: normalizedId,
            updatedAt: now,
            createdAt: player.createdAt,
          ),
        );
        replaced = true;
      } else {
        next.add(existing);
      }
    }
    if (!replaced) {
      next.add(player.copyWith(id: normalizedId, updatedAt: now));
    }
    await _savePlayers(next,
        state.activePlayerId.isEmpty ? normalizedId : state.activePlayerId);
  }

  Future<void> removePlayer(String playerId) async {
    final normalizedId = normalizePlayerId(playerId);
    if (normalizedId.isEmpty) return;
    final state = loadState();
    final next = state.players
        .where((player) => player.id != normalizedId)
        .toList(growable: false);
    final nextActive = state.activePlayerId == normalizedId
        ? (next.isEmpty ? '' : next.first.id)
        : state.activePlayerId;
    await _savePlayers(next, nextActive);
  }

  static String resolveScopedPlayerIdForOptions(
    OptionRepository options, {
    String? explicitPlayerId,
  }) {
    final explicit = normalizePlayerId(explicitPlayerId);
    if (explicit.isNotEmpty) return explicit;
    final role = options.getValue<String>(_familyCurrentRoleLocalKey)?.trim();
    if (role != _coachRoleStorageValue) return '';
    return activePlayerIdForOptions(options);
  }

  static String activePlayerIdForOptions(OptionRepository options) {
    final storedActive = normalizePlayerId(
      options.getValue<String>(activePlayerIdKey),
    );
    if (storedActive.isNotEmpty) return storedActive;
    final rawPlayers = options.getValue<List>(rosterPlayersKey);
    if (rawPlayers != null) {
      for (final raw in rawPlayers) {
        final player = CoachPlayerProfile.tryParse(raw);
        if (player != null) return player.id;
      }
    }
    return defaultPlayerId;
  }

  static String scopedOptionKey(String baseKey, String playerId) {
    final safePlayerId = fileSafePlayerId(playerId);
    return '$scopedOptionKeyPrefix${safePlayerId}_$baseKey';
  }

  static bool isScopedOptionKeyForBase(String key, String baseKey) {
    return key.startsWith(scopedOptionKeyPrefix) && key.endsWith('_$baseKey');
  }

  static String normalizePlayerId(String? raw) {
    return raw?.trim() ?? '';
  }

  static String fileSafePlayerId(String? raw) {
    final normalized = normalizePlayerId(raw)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? defaultPlayerId : normalized;
  }

  List<CoachPlayerProfile> _loadPlayers() {
    final raw = _options.getValue<List>(rosterPlayersKey) ?? const [];
    final players = <CoachPlayerProfile>[];
    final seen = <String>{};
    for (final item in raw) {
      final player = CoachPlayerProfile.tryParse(item);
      if (player == null || !seen.add(player.id)) continue;
      players.add(player);
    }
    return players;
  }

  Future<void> _savePlayers(
    List<CoachPlayerProfile> players,
    String activePlayerId,
  ) async {
    final normalizedActive = normalizePlayerId(activePlayerId);
    await _options.setValue(
      rosterPlayersKey,
      players.map((player) => player.toMap()).toList(growable: false),
    );
    if (normalizedActive.isEmpty) {
      await _options.setValue(activePlayerIdKey, '');
    } else {
      await _options.setValue(activePlayerIdKey, normalizedActive);
    }
  }

  String _fallbackPlayerName() {
    final childName = _options.getValue<String>(_familyChildNameKey)?.trim();
    if (childName != null && childName.isNotEmpty) return childName;
    final profileName = _options.getValue<String>(_profileNameKey)?.trim();
    if (profileName != null && profileName.isNotEmpty) return profileName;
    return 'Player';
  }
}
