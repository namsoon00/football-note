import 'dart:convert';

import '../domain/entities/running_coach_runner_profile.dart';
import '../domain/repositories/option_repository.dart';
import 'sport_scoped_storage.dart';

class RunningCoachRunnerProfileService {
  static const profilesStorageKey = 'running_coach_runner_profiles_v1';
  static const selectedRunnerStorageKey = 'running_coach_selected_runner_v1';

  final OptionRepository _options;
  final String? _sportId;

  const RunningCoachRunnerProfileService(
    this._options, {
    String? sportId,
  }) : _sportId = sportId;

  String get _profilesKey => sportScopedOptionKey(
        _options,
        profilesStorageKey,
        sportId: _sportId,
      );

  String get _selectedKey => sportScopedOptionKey(
        _options,
        selectedRunnerStorageKey,
        sportId: _sportId,
      );

  List<RunningCoachRunnerProfile> profiles({
    required String defaultDisplayName,
    bool includeArchived = false,
  }) {
    final stored = _readStoredProfiles();
    final defaultIndex = stored.indexWhere((profile) => profile.isDefault);
    final defaultProfile = RunningCoachRunnerProfile(
      id: runningCoachDefaultRunnerId,
      displayName: defaultDisplayName,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
    final normalized = <RunningCoachRunnerProfile>[
      if (defaultIndex < 0)
        defaultProfile
      else
        stored[defaultIndex].copyWith(
          displayName: stored[defaultIndex].displayName.trim().isEmpty
              ? defaultDisplayName
              : stored[defaultIndex].displayName,
          archived: false,
        ),
      ...stored.where((profile) => !profile.isDefault),
    ];
    final visible = includeArchived
        ? normalized
        : normalized.where((profile) => !profile.archived).toList();
    return List<RunningCoachRunnerProfile>.unmodifiable(visible);
  }

  RunningCoachRunnerProfile selectedProfile({
    required String defaultDisplayName,
  }) {
    final active = profiles(defaultDisplayName: defaultDisplayName);
    final selectedId = _options.getValue<String>(_selectedKey);
    return active.firstWhere(
      (profile) => profile.id == selectedId,
      orElse: () => active.first,
    );
  }

  Future<RunningCoachRunnerProfile> ensureDefaultRunner({
    required String defaultDisplayName,
  }) async {
    final all = profiles(
      defaultDisplayName: defaultDisplayName,
      includeArchived: true,
    );
    await _persist(all);
    final selected = selectedProfile(defaultDisplayName: defaultDisplayName);
    await _options.setValue(_selectedKey, selected.id);
    return selected;
  }

  Future<RunningCoachRunnerProfile> addRunner({
    required String displayName,
    String? imageReference,
    DateTime? createdAt,
    required String defaultDisplayName,
  }) async {
    final normalizedName = displayName.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(displayName, 'displayName');
    }
    final timestamp = createdAt ?? DateTime.now();
    final profile = RunningCoachRunnerProfile(
      id: 'runner-${timestamp.microsecondsSinceEpoch}',
      displayName: normalizedName,
      imageReference: imageReference,
      createdAt: timestamp,
    );
    final all = profiles(
      defaultDisplayName: defaultDisplayName,
      includeArchived: true,
    );
    await _persist(<RunningCoachRunnerProfile>[...all, profile]);
    await selectRunner(profile.id, defaultDisplayName: defaultDisplayName);
    return profile;
  }

  Future<RunningCoachRunnerProfile> renameRunner({
    required String runnerId,
    required String displayName,
    required String defaultDisplayName,
  }) async {
    final normalizedName = displayName.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(displayName, 'displayName');
    }
    final all = profiles(
      defaultDisplayName: defaultDisplayName,
      includeArchived: true,
    );
    late RunningCoachRunnerProfile renamed;
    final next = all.map((profile) {
      if (profile.id != runnerId) return profile;
      renamed = profile.copyWith(displayName: normalizedName);
      return renamed;
    }).toList(growable: false);
    if (!next.any((profile) => profile.id == runnerId)) {
      throw StateError('runner_not_found');
    }
    await _persist(next);
    return renamed;
  }

  Future<void> archiveRunner({
    required String runnerId,
    required String defaultDisplayName,
  }) async {
    if (runnerId == runningCoachDefaultRunnerId) {
      await ensureDefaultRunner(defaultDisplayName: defaultDisplayName);
      return;
    }
    final all = profiles(
      defaultDisplayName: defaultDisplayName,
      includeArchived: true,
    );
    final next = all
        .map(
          (profile) => profile.id == runnerId
              ? profile.copyWith(archived: true)
              : profile,
        )
        .toList(growable: false);
    await _persist(next);
    if (_options.getValue<String>(_selectedKey) == runnerId) {
      await _options.setValue(_selectedKey, runningCoachDefaultRunnerId);
    }
  }

  Future<RunningCoachRunnerProfile> selectRunner(
    String runnerId, {
    required String defaultDisplayName,
  }) async {
    final active = profiles(defaultDisplayName: defaultDisplayName);
    final selected = active.firstWhere(
      (profile) => profile.id == runnerId,
      orElse: () => active.first,
    );
    await _options.setValue(_selectedKey, selected.id);
    return selected;
  }

  List<RunningCoachRunnerProfile> _readStoredProfiles() {
    final raw = _options.getValue<String>(_profilesKey);
    if (raw == null) return const <RunningCoachRunnerProfile>[];
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const <RunningCoachRunnerProfile>[];
    }
    if (decoded is! List) return const <RunningCoachRunnerProfile>[];
    return decoded
        .whereType<Map>()
        .map(
          (item) => RunningCoachRunnerProfile.fromMap(
            item.cast<String, dynamic>(),
          ),
        )
        .where((profile) => profile.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _persist(List<RunningCoachRunnerProfile> profiles) {
    return _options.setValue(
      _profilesKey,
      jsonEncode(
        profiles.map((profile) => profile.toMap()).toList(growable: false),
      ),
    );
  }
}
