import 'scan_pass_spatial_library.dart';

enum SpatialLibraryWatchFilter {
  all,
  unwatched,
  inProgress,
  watched,
  bookmarked,
}

enum SpatialLibraryPlaybackMode { guided, source }

enum SpatialLibraryWatchState { unwatched, inProgress, watched }

class SpatialLibraryViewedInterval {
  final double start;
  final double end;

  const SpatialLibraryViewedInterval(this.start, this.end);

  double get duration => end - start;
}

class SpatialLibraryCoverage {
  static const double completionFraction = .9;
  static const double maximumTelemetryDelta = 1.5;
  static const double finalIntervalTolerance = .25;

  final List<SpatialLibraryViewedInterval> intervals;
  final bool playedFinalInterval;

  const SpatialLibraryCoverage({
    this.intervals = const <SpatialLibraryViewedInterval>[],
    this.playedFinalInterval = false,
  });

  double coveredSeconds(double duration) => normalizedIntervals(duration)
      .fold<double>(0, (total, interval) => total + interval.duration);

  double fraction(double duration) {
    if (!duration.isFinite || duration <= 0) return 0;
    return (coveredSeconds(duration) / duration).clamp(0, 1).toDouble();
  }

  bool watched(double duration) =>
      playedFinalInterval && fraction(duration) >= completionFraction;

  SpatialLibraryWatchState watchState(double duration) {
    if (watched(duration)) return SpatialLibraryWatchState.watched;
    if (coveredSeconds(duration) > 0) {
      return SpatialLibraryWatchState.inProgress;
    }
    return SpatialLibraryWatchState.unwatched;
  }

  SpatialLibraryCoverage recordPlaying({
    required double duration,
    required double from,
    required double to,
  }) {
    final delta = to - from;
    if (!duration.isFinite ||
        duration <= 0 ||
        !from.isFinite ||
        !to.isFinite ||
        delta <= 0 ||
        delta > maximumTelemetryDelta) {
      return this;
    }
    final start = from.clamp(0.0, duration).toDouble();
    final end = to.clamp(0.0, duration).toDouble();
    if (end <= start) return this;
    final merged = _normalize(
      <SpatialLibraryViewedInterval>[
        ...normalizedIntervals(duration),
        SpatialLibraryViewedInterval(start, end),
      ],
      duration,
    );
    return SpatialLibraryCoverage(
      intervals: merged,
      playedFinalInterval: playedFinalInterval ||
          (start < duration && end >= duration - finalIntervalTolerance),
    );
  }

  SpatialLibraryCoverage sanitized(double duration) => SpatialLibraryCoverage(
        intervals: normalizedIntervals(duration),
        playedFinalInterval: playedFinalInterval &&
            normalizedIntervals(duration).any(
              (interval) => interval.end >= duration - finalIntervalTolerance,
            ),
      );

  List<SpatialLibraryViewedInterval> normalizedIntervals(double duration) =>
      _normalize(intervals, duration);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'intervals': <List<double>>[
          for (final interval in intervals)
            <double>[interval.start, interval.end],
        ],
        'playedFinalInterval': playedFinalInterval,
      };

  factory SpatialLibraryCoverage.fromJson(Object? value) {
    if (value is! Map) return const SpatialLibraryCoverage();
    final intervals = <SpatialLibraryViewedInterval>[];
    final rawIntervals = value['intervals'];
    if (rawIntervals is List) {
      for (final raw in rawIntervals) {
        if (raw is! List || raw.length != 2) continue;
        final start = raw[0];
        final end = raw[1];
        if (start is num &&
            end is num &&
            start.isFinite &&
            end.isFinite &&
            start >= 0 &&
            end > start) {
          intervals.add(
            SpatialLibraryViewedInterval(start.toDouble(), end.toDouble()),
          );
        }
      }
    }
    return SpatialLibraryCoverage(
      intervals: List.unmodifiable(intervals),
      playedFinalInterval: value['playedFinalInterval'] == true,
    );
  }

  static List<SpatialLibraryViewedInterval> _normalize(
    Iterable<SpatialLibraryViewedInterval> source,
    double duration,
  ) {
    if (!duration.isFinite || duration <= 0) {
      return const <SpatialLibraryViewedInterval>[];
    }
    final clamped = <SpatialLibraryViewedInterval>[];
    for (final interval in source) {
      if (!interval.start.isFinite ||
          !interval.end.isFinite ||
          interval.start < 0 ||
          interval.end > duration + finalIntervalTolerance) {
        continue;
      }
      final start = interval.start.clamp(0.0, duration).toDouble();
      final end = interval.end.clamp(0.0, duration).toDouble();
      if (end > start) {
        clamped.add(SpatialLibraryViewedInterval(start, end));
      }
    }
    clamped.sort((a, b) => a.start.compareTo(b.start));
    final merged = <SpatialLibraryViewedInterval>[];
    for (final interval in clamped) {
      if (merged.isEmpty || interval.start > merged.last.end + .05) {
        merged.add(interval);
      } else {
        final previous = merged.removeLast();
        merged.add(SpatialLibraryViewedInterval(
          previous.start,
          interval.end > previous.end ? interval.end : previous.end,
        ));
      }
    }
    return List.unmodifiable(merged);
  }
}

class SpatialLibrarySceneRecord {
  final double resumeTime;
  final SpatialLibraryCoverage coverage;
  final bool bookmarked;

  const SpatialLibrarySceneRecord({
    this.resumeTime = 0,
    this.coverage = const SpatialLibraryCoverage(),
    this.bookmarked = false,
  });

  SpatialLibrarySceneRecord copyWith({
    double? resumeTime,
    SpatialLibraryCoverage? coverage,
    bool? bookmarked,
  }) =>
      SpatialLibrarySceneRecord(
        resumeTime: resumeTime ?? this.resumeTime,
        coverage: coverage ?? this.coverage,
        bookmarked: bookmarked ?? this.bookmarked,
      );

  SpatialLibrarySceneRecord sanitized(double duration) {
    final safeResume =
        resumeTime.isFinite ? resumeTime.clamp(0.0, duration).toDouble() : 0.0;
    return SpatialLibrarySceneRecord(
      resumeTime: safeResume,
      coverage: coverage.sanitized(duration),
      bookmarked: bookmarked,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'resumeTime': resumeTime,
        'coverage': coverage.toJson(),
        'bookmarked': bookmarked,
      };

  factory SpatialLibrarySceneRecord.fromJson(Object? value) {
    if (value is! Map) return const SpatialLibrarySceneRecord();
    final resume = value['resumeTime'];
    return SpatialLibrarySceneRecord(
      resumeTime: resume is num && resume.isFinite && resume >= 0
          ? resume.toDouble()
          : 0,
      coverage: SpatialLibraryCoverage.fromJson(value['coverage']),
      bookmarked: value['bookmarked'] == true,
    );
  }
}

class SpatialLibraryFilters {
  final String query;
  final SpatialLearningTheme? theme;
  final SpatialLearningObjective? objective;
  final String? attackingTeam;
  final String? player;
  final SpatialLibraryWatchFilter watchFilter;
  final bool unfinishedFirst;

  const SpatialLibraryFilters({
    this.query = '',
    this.theme,
    this.objective,
    this.attackingTeam,
    this.player,
    this.watchFilter = SpatialLibraryWatchFilter.all,
    this.unfinishedFirst = true,
  });

  SpatialLibraryFilters copyWith({
    String? query,
    Object? theme = _notProvided,
    Object? objective = _notProvided,
    Object? attackingTeam = _notProvided,
    Object? player = _notProvided,
    SpatialLibraryWatchFilter? watchFilter,
    bool? unfinishedFirst,
  }) =>
      SpatialLibraryFilters(
        query: query ?? this.query,
        theme: identical(theme, _notProvided)
            ? this.theme
            : theme as SpatialLearningTheme?,
        objective: identical(objective, _notProvided)
            ? this.objective
            : objective as SpatialLearningObjective?,
        attackingTeam: identical(attackingTeam, _notProvided)
            ? this.attackingTeam
            : attackingTeam as String?,
        player:
            identical(player, _notProvided) ? this.player : player as String?,
        watchFilter: watchFilter ?? this.watchFilter,
        unfinishedFirst: unfinishedFirst ?? this.unfinishedFirst,
      );

  SpatialLibraryFilters sanitized(SpatialLibraryCatalog catalog) {
    final teams = catalog.attackingTeams;
    final safeTeam = teams.contains(attackingTeam) ? attackingTeam : null;
    final players = catalog.participants(attackingTeam: safeTeam);
    final safePlayer = players.contains(player) ? player : null;
    final themes = catalog.themes;
    final objectives = catalog.scenes
        .map((scene) => scene.education?.objective)
        .whereType<SpatialLearningObjective>()
        .toSet();
    return SpatialLibraryFilters(
      query: query.length <= 200 ? query : query.substring(0, 200),
      theme: themes.contains(theme) ? theme : null,
      objective: objectives.contains(objective) ? objective : null,
      attackingTeam: safeTeam,
      player: safePlayer,
      watchFilter: watchFilter,
      unfinishedFirst: unfinishedFirst,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'query': query,
        if (theme != null) 'theme': theme!.name,
        if (objective != null) 'objective': objective!.name,
        if (attackingTeam != null) 'attackingTeam': attackingTeam,
        if (player != null) 'player': player,
        'watchFilter': watchFilter.name,
        'unfinishedFirst': unfinishedFirst,
      };

  factory SpatialLibraryFilters.fromJson(Object? value) {
    if (value is! Map) return const SpatialLibraryFilters();
    return SpatialLibraryFilters(
      query: value['query'] is String ? value['query'] as String : '',
      theme: _enumByName(SpatialLearningTheme.values, value['theme']),
      objective: _enumByName(
        SpatialLearningObjective.values,
        value['objective'],
      ),
      attackingTeam: value['attackingTeam'] is String
          ? value['attackingTeam'] as String
          : null,
      player: value['player'] is String ? value['player'] as String : null,
      watchFilter: _enumByName(
            SpatialLibraryWatchFilter.values,
            value['watchFilter'],
          ) ??
          SpatialLibraryWatchFilter.all,
      unfinishedFirst: value['unfinishedFirst'] is bool
          ? value['unfinishedFirst'] as bool
          : true,
    );
  }
}

class SpatialLibraryPreferences {
  final String? lastSceneIdentity;
  final Map<String, SpatialLibrarySceneRecord> records;
  final SpatialLibraryFilters filters;
  final SpatialLibraryPlaybackMode playbackMode;
  final bool autoNext;

  const SpatialLibraryPreferences({
    this.lastSceneIdentity,
    this.records = const <String, SpatialLibrarySceneRecord>{},
    this.filters = const SpatialLibraryFilters(),
    this.playbackMode = SpatialLibraryPlaybackMode.guided,
    this.autoNext = true,
  });

  SpatialLibraryPreferences copyWith({
    Object? lastSceneIdentity = _notProvided,
    Map<String, SpatialLibrarySceneRecord>? records,
    SpatialLibraryFilters? filters,
    SpatialLibraryPlaybackMode? playbackMode,
    bool? autoNext,
  }) =>
      SpatialLibraryPreferences(
        lastSceneIdentity: identical(lastSceneIdentity, _notProvided)
            ? this.lastSceneIdentity
            : lastSceneIdentity as String?,
        records: records ?? this.records,
        filters: filters ?? this.filters,
        playbackMode: playbackMode ?? this.playbackMode,
        autoNext: autoNext ?? this.autoNext,
      );

  SpatialLibraryPreferences sanitized(SpatialLibraryCatalog catalog) {
    final scenesByIdentity = <String, SpatialLibraryScene>{
      for (final scene in catalog.scenes) scene.spatialHistoryIdentity: scene,
    };
    final sanitizedRecords = <String, SpatialLibrarySceneRecord>{};
    for (final entry in records.entries) {
      final scene = scenesByIdentity[entry.key];
      if (scene != null) {
        sanitizedRecords[entry.key] = entry.value.sanitized(scene.duration);
      }
    }
    final lastScene = scenesByIdentity[lastSceneIdentity];
    var safeLastIdentity = lastScene == null ? null : lastSceneIdentity;
    if (safeLastIdentity == null) {
      final entries = sanitizedRecords.entries.toList(growable: false);
      for (final entry in entries.reversed) {
        final scene = scenesByIdentity[entry.key]!;
        final record = entry.value;
        if (!record.coverage.watched(scene.duration) &&
            (record.resumeTime > 0 ||
                record.coverage.coveredSeconds(scene.duration) > 0)) {
          safeLastIdentity = entry.key;
          break;
        }
      }
    }
    return SpatialLibraryPreferences(
      lastSceneIdentity: safeLastIdentity,
      records: Map.unmodifiable(sanitizedRecords),
      filters: filters.sanitized(catalog),
      playbackMode: playbackMode,
      autoNext: autoNext,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': 1,
        if (lastSceneIdentity != null) 'lastSceneIdentity': lastSceneIdentity,
        'records': <String, dynamic>{
          for (final entry in records.entries) entry.key: entry.value.toJson(),
        },
        'filters': filters.toJson(),
        'playbackMode': playbackMode.name,
        'autoNext': autoNext,
      };

  factory SpatialLibraryPreferences.fromJson(Object? value) {
    if (value is! Map || value['version'] != 1) {
      return const SpatialLibraryPreferences();
    }
    final records = <String, SpatialLibrarySceneRecord>{};
    final rawRecords = value['records'];
    if (rawRecords is Map) {
      for (final entry in rawRecords.entries) {
        if (entry.key is String) {
          records[entry.key as String] =
              SpatialLibrarySceneRecord.fromJson(entry.value);
        }
      }
    }
    return SpatialLibraryPreferences(
      lastSceneIdentity: value['lastSceneIdentity'] is String
          ? value['lastSceneIdentity'] as String
          : null,
      records: Map.unmodifiable(records),
      filters: SpatialLibraryFilters.fromJson(value['filters']),
      playbackMode: _enumByName(
            SpatialLibraryPlaybackMode.values,
            value['playbackMode'],
          ) ??
          SpatialLibraryPlaybackMode.guided,
      autoNext: value['autoNext'] is bool ? value['autoNext'] as bool : true,
    );
  }
}

typedef SpatialLibraryQueryMatcher = bool Function(
  SpatialLibraryScene scene,
  String query,
);

class SpatialLibraryPersonalization {
  const SpatialLibraryPersonalization._();

  static List<SpatialLibraryScene> filteredScenes({
    required SpatialLibraryCatalog catalog,
    required SpatialLibraryPreferences preferences,
    required SpatialLibraryQueryMatcher matchesQuery,
  }) {
    final filters = preferences.filters;
    final scenes = catalog.scenes.where((scene) {
      if (filters.objective != null &&
          scene.education?.objective != filters.objective) {
        return false;
      }
      if (filters.theme != null && scene.theme != filters.theme) return false;
      if (filters.attackingTeam != null &&
          scene.attackingTeam != filters.attackingTeam) {
        return false;
      }
      if (filters.player != null && !scene.involvesPlayer(filters.player!)) {
        return false;
      }
      if (!matchesQuery(scene, filters.query)) return false;
      final record = preferences.records[scene.spatialHistoryIdentity] ??
          const SpatialLibrarySceneRecord();
      final state = record.coverage.watchState(scene.duration);
      return switch (filters.watchFilter) {
        SpatialLibraryWatchFilter.all => true,
        SpatialLibraryWatchFilter.unwatched =>
          state == SpatialLibraryWatchState.unwatched,
        SpatialLibraryWatchFilter.inProgress =>
          state == SpatialLibraryWatchState.inProgress,
        SpatialLibraryWatchFilter.watched =>
          state == SpatialLibraryWatchState.watched,
        SpatialLibraryWatchFilter.bookmarked => record.bookmarked,
      };
    }).toList(growable: false);
    if (!filters.unfinishedFirst ||
        filters.watchFilter == SpatialLibraryWatchFilter.watched) {
      return scenes;
    }
    final indexed = scenes.indexed.toList(growable: false)
      ..sort((a, b) {
        final aWatched = _isWatched(preferences, a.$2);
        final bWatched = _isWatched(preferences, b.$2);
        if (aWatched != bWatched) return aWatched ? 1 : -1;
        return a.$1.compareTo(b.$1);
      });
    return List.unmodifiable(indexed.map((entry) => entry.$2));
  }

  static SpatialLibraryScene? nextUnfinished({
    required List<SpatialLibraryScene> filteredScenes,
    required SpatialLibraryPreferences preferences,
    required String currentSceneId,
  }) {
    if (filteredScenes.isEmpty) return null;
    final current = filteredScenes.indexWhere(
      (scene) => scene.id == currentSceneId,
    );
    for (var offset = 1; offset <= filteredScenes.length; offset++) {
      final index = (current + offset) % filteredScenes.length;
      final candidate = filteredScenes[index];
      if (candidate.id != currentSceneId &&
          !_isWatched(preferences, candidate)) {
        return candidate;
      }
    }
    return null;
  }

  static SpatialLibraryScene? relativeScene({
    required List<SpatialLibraryScene> filteredScenes,
    required String currentSceneId,
    required int delta,
  }) {
    if (filteredScenes.isEmpty) return null;
    final current = filteredScenes.indexWhere(
      (scene) => scene.id == currentSceneId,
    );
    final base = current < 0 ? (delta > 0 ? -1 : 0) : current;
    final index = (base + delta) % filteredScenes.length;
    return filteredScenes[index];
  }

  static bool _isWatched(
    SpatialLibraryPreferences preferences,
    SpatialLibraryScene scene,
  ) =>
      (preferences.records[scene.spatialHistoryIdentity] ??
              const SpatialLibrarySceneRecord())
          .coverage
          .watched(scene.duration);
}

extension SpatialLibraryScenePersonalization on SpatialLibraryScene {
  String get spatialHistoryIdentity => '$id:$assetSha256';
}

T? _enumByName<T extends Enum>(Iterable<T> values, Object? name) {
  if (name is! String) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

const Object _notProvided = Object();
