import 'dart:async';
import 'dart:convert';

import '../domain/repositories/option_repository.dart';
import '../domain/repositories/video_learning_repository.dart';
import '../domain/scan_pass/scan_pass_video_learning.dart';
import 'video_learning_player.dart';

class VideoLearningInterval {
  final double start;
  final double end;

  const VideoLearningInterval(this.start, this.end);

  double get duration => end - start;
}

class VideoLearningCoverage {
  static const double maximumTelemetryDelta = 1.5;

  final List<VideoLearningInterval> intervals;
  final bool reachedGoal;

  const VideoLearningCoverage({
    this.intervals = const <VideoLearningInterval>[],
    this.reachedGoal = false,
  });

  double get coveredSeconds => intervals.fold<double>(
        0,
        (total, interval) => total + interval.duration,
      );

  List<VideoLearningInterval> normalizedIntervals(VideoLearningScene scene) {
    final clamped = <VideoLearningInterval>[];
    for (final interval in intervals) {
      if (interval.start < scene.clip.start - .25 ||
          interval.end > scene.clip.end + .25) {
        continue;
      }
      final start = scene.clip.clamp(interval.start);
      final end = scene.clip.clamp(interval.end);
      if (end > start) clamped.add(VideoLearningInterval(start, end));
    }
    clamped.sort((a, b) => a.start.compareTo(b.start));
    final merged = <VideoLearningInterval>[];
    for (final interval in clamped) {
      if (merged.isEmpty || interval.start > merged.last.end + .05) {
        merged.add(interval);
      } else {
        final previous = merged.removeLast();
        merged.add(VideoLearningInterval(
          previous.start,
          interval.end > previous.end ? interval.end : previous.end,
        ));
      }
    }
    return List.unmodifiable(merged);
  }

  double fraction(VideoLearningScene scene) {
    final seconds = normalizedIntervals(scene).fold<double>(
      0,
      (total, interval) => total + interval.duration,
    );
    return (seconds / scene.clip.duration).clamp(0, 1).toDouble();
  }

  bool watched(VideoLearningScene scene) =>
      fraction(scene) >= .8 &&
      normalizedIntervals(scene).any(
        (interval) => interval.end >= scene.goalTime - .25,
      );

  VideoLearningCoverage recordPlaying({
    required VideoLearningScene scene,
    required double from,
    required double to,
  }) {
    final delta = to - from;
    if (!delta.isFinite || delta <= 0 || delta > maximumTelemetryDelta) {
      return this;
    }
    final start = scene.clip.clamp(from);
    final end = scene.clip.clamp(to);
    if (end <= start) return this;
    final merged = <VideoLearningInterval>[
      ...intervals,
      VideoLearningInterval(start, end),
    ]..sort((a, b) => a.start.compareTo(b.start));
    final result = <VideoLearningInterval>[];
    for (final interval in merged) {
      if (result.isEmpty || interval.start > result.last.end + .05) {
        result.add(interval);
      } else {
        final previous = result.removeLast();
        result.add(VideoLearningInterval(
          previous.start,
          interval.end > previous.end ? interval.end : previous.end,
        ));
      }
    }
    final goalReached = reachedGoal || end >= scene.goalTime - .25;
    return VideoLearningCoverage(
      intervals: List.unmodifiable(result),
      reachedGoal: goalReached,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'intervals': <List<double>>[
          for (final interval in intervals)
            <double>[
              interval.start,
              interval.end,
            ],
        ],
        'reachedGoal': reachedGoal,
      };

  factory VideoLearningCoverage.fromJson(Object? value) {
    if (value is! Map) return const VideoLearningCoverage();
    final rawIntervals = value['intervals'];
    final intervals = <VideoLearningInterval>[];
    if (rawIntervals is List) {
      for (final raw in rawIntervals) {
        if (raw is! List || raw.length != 2) continue;
        final start = raw[0];
        final end = raw[1];
        if (start is num && end is num && start.isFinite && end.isFinite) {
          final a = start.toDouble();
          final b = end.toDouble();
          if (a >= 0 && b > a) intervals.add(VideoLearningInterval(a, b));
        }
      }
    }
    intervals.sort((a, b) => a.start.compareTo(b.start));
    return VideoLearningCoverage(
      intervals: List.unmodifiable(intervals),
      reachedGoal: value['reachedGoal'] == true,
    );
  }
}

class VideoLearningPreferences {
  final String? lastSceneId;
  final Map<String, double> resumeTimes;
  final Map<String, VideoLearningCoverage> coverage;
  final String? teamFilter;
  final VideoLearningWatchFilter watchFilter;
  final double playbackRate;
  final bool autoNext;

  const VideoLearningPreferences({
    this.lastSceneId,
    this.resumeTimes = const <String, double>{},
    this.coverage = const <String, VideoLearningCoverage>{},
    this.teamFilter,
    this.watchFilter = VideoLearningWatchFilter.all,
    this.playbackRate = 1,
    this.autoNext = true,
  });

  VideoLearningPreferences copyWith({
    String? lastSceneId,
    Map<String, double>? resumeTimes,
    Map<String, VideoLearningCoverage>? coverage,
    Object? teamFilter = _notProvided,
    VideoLearningWatchFilter? watchFilter,
    double? playbackRate,
    bool? autoNext,
  }) =>
      VideoLearningPreferences(
        lastSceneId: lastSceneId ?? this.lastSceneId,
        resumeTimes: resumeTimes ?? this.resumeTimes,
        coverage: coverage ?? this.coverage,
        teamFilter: identical(teamFilter, _notProvided)
            ? this.teamFilter
            : teamFilter as String?,
        watchFilter: watchFilter ?? this.watchFilter,
        playbackRate: playbackRate ?? this.playbackRate,
        autoNext: autoNext ?? this.autoNext,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': 1,
        if (lastSceneId != null) 'lastSceneId': lastSceneId,
        'resumeTimes': resumeTimes,
        'coverage': <String, dynamic>{
          for (final entry in coverage.entries) entry.key: entry.value.toJson(),
        },
        if (teamFilter != null) 'teamFilter': teamFilter,
        'watchFilter': watchFilter.name,
        'playbackRate': playbackRate,
        'autoNext': autoNext,
      };

  factory VideoLearningPreferences.fromJson(Object? value) {
    if (value is! Map || value['version'] != 1) {
      return const VideoLearningPreferences();
    }
    final resume = <String, double>{};
    final rawResume = value['resumeTimes'];
    if (rawResume is Map) {
      for (final entry in rawResume.entries) {
        final time = entry.value;
        if (entry.key is String && time is num && time.isFinite && time >= 0) {
          resume[entry.key as String] = time.toDouble();
        }
      }
    }
    final coverage = <String, VideoLearningCoverage>{};
    final rawCoverage = value['coverage'];
    if (rawCoverage is Map) {
      for (final entry in rawCoverage.entries) {
        if (entry.key is String) {
          coverage[entry.key as String] =
              VideoLearningCoverage.fromJson(entry.value);
        }
      }
    }
    final rate = value['playbackRate'];
    final parsedRate =
        rate is num && rate.isFinite && rate > 0 ? rate.toDouble() : 1.0;
    return VideoLearningPreferences(
      lastSceneId: value['lastSceneId'] is String
          ? value['lastSceneId'] as String
          : null,
      resumeTimes: Map.unmodifiable(resume),
      coverage: Map.unmodifiable(coverage),
      teamFilter:
          value['teamFilter'] is String ? value['teamFilter'] as String : null,
      watchFilter: VideoLearningWatchFilter.values.firstWhere(
        (filter) => filter.name == value['watchFilter'],
        orElse: () => VideoLearningWatchFilter.all,
      ),
      playbackRate: parsedRate,
      autoNext: value['autoNext'] is bool ? value['autoNext'] as bool : true,
    );
  }
}

const Object _notProvided = Object();

class VideoLearningService {
  static const storageKey = 'scan_pass_video_learning_v1';

  final VideoLearningRepository catalogRepository;
  final OptionRepository optionRepository;

  VideoLearningPreferences _preferences;
  Future<void> _writeQueue = Future<void>.value();
  double? _lastTelemetryTime;
  VideoLearningPlayerState _lastPlayerState = VideoLearningPlayerState.idle;
  Object? _persistenceError;

  VideoLearningService({
    required this.catalogRepository,
    required this.optionRepository,
  }) : _preferences = _loadPreferences(optionRepository);

  VideoLearningPreferences get preferences => _preferences;
  Object? get persistenceError => _persistenceError;
  bool get hasPersistenceError => _persistenceError != null;

  Future<VideoLearningCatalog> loadCatalog() => catalogRepository.loadCatalog();

  bool isWatched(VideoLearningScene scene) =>
      (_preferences.coverage[scene.id] ?? const VideoLearningCoverage())
          .watched(scene);

  double coverageFraction(VideoLearningScene scene) =>
      (_preferences.coverage[scene.id] ?? const VideoLearningCoverage())
          .fraction(scene);

  double resumeTime(VideoLearningScene scene) {
    final stored = _preferences.resumeTimes[scene.id];
    if (stored == null || !stored.isFinite) return scene.clip.start;
    if (stored >= scene.clip.end - .25) {
      return scene.clip.start;
    }
    return scene.clip.clamp(stored);
  }

  void resetTelemetry() {
    _lastTelemetryTime = null;
    _lastPlayerState = VideoLearningPlayerState.idle;
  }

  Future<void> recordPlayerEvent(
    VideoLearningScene scene,
    VideoLearningPlayerEvent event, {
    required bool foreground,
  }) async {
    final time = scene.clip.clamp(event.mediaTime);
    var coverage =
        _preferences.coverage[scene.id] ?? const VideoLearningCoverage();
    final previousTime = _lastTelemetryTime;
    final terminalEvent = event.state == VideoLearningPlayerState.paused ||
        event.state == VideoLearningPlayerState.ended;
    if (foreground &&
        previousTime != null &&
        _lastPlayerState == VideoLearningPlayerState.playing &&
        (event.state == VideoLearningPlayerState.playing || terminalEvent)) {
      coverage = coverage.recordPlaying(
        scene: scene,
        from: previousTime,
        to: time,
      );
    }
    final resume = Map<String, double>.from(_preferences.resumeTimes)
      ..[scene.id] = time;
    final allCoverage =
        Map<String, VideoLearningCoverage>.from(_preferences.coverage)
          ..[scene.id] = coverage;
    _preferences = _preferences.copyWith(
      resumeTimes: Map.unmodifiable(resume),
      coverage: Map.unmodifiable(allCoverage),
    );
    _lastTelemetryTime =
        foreground && event.state == VideoLearningPlayerState.playing
            ? time
            : null;
    _lastPlayerState = foreground ? event.state : VideoLearningPlayerState.idle;
    if (terminalEvent) await persist();
  }

  Future<void> selectScene(
    VideoLearningScene scene, {
    double? resumeTime,
  }) async {
    final resume = Map<String, double>.from(_preferences.resumeTimes);
    if (resumeTime != null && resumeTime.isFinite) {
      resume[scene.id] = scene.clip.clamp(resumeTime);
    }
    _preferences = _preferences.copyWith(
      lastSceneId: scene.id,
      resumeTimes: Map.unmodifiable(resume),
    );
    resetTelemetry();
    await persist();
  }

  Future<void> setFilters({
    required String? teamId,
    required VideoLearningWatchFilter watchFilter,
  }) async {
    _preferences = _preferences.copyWith(
      teamFilter: teamId,
      watchFilter: watchFilter,
    );
    await persist();
  }

  Future<void> setPlaybackRate(double rate) async {
    if (!rate.isFinite || rate <= 0) return;
    _preferences = _preferences.copyWith(playbackRate: rate);
    await persist();
  }

  Future<void> setAutoNext(bool enabled) async {
    _preferences = _preferences.copyWith(autoNext: enabled);
    await persist();
  }

  Future<void> persist() {
    final encoded = jsonEncode(_preferences.toJson());
    _writeQueue = _writeQueue.catchError((_) {}).then((_) async {
      try {
        await optionRepository.setValue(storageKey, encoded);
        _persistenceError = null;
      } catch (error) {
        _persistenceError = error;
      }
    });
    return _writeQueue;
  }

  Future<void> flush() => persist();

  static VideoLearningPreferences _loadPreferences(
    OptionRepository repository,
  ) {
    try {
      final source = repository.getValue<String>(storageKey);
      if (source == null || source.trim().isEmpty) {
        return const VideoLearningPreferences();
      }
      return VideoLearningPreferences.fromJson(jsonDecode(source));
    } catch (_) {
      return const VideoLearningPreferences();
    }
  }
}
