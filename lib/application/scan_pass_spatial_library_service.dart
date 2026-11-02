import 'dart:async';
import 'dart:convert';

import '../domain/repositories/option_repository.dart';
import '../domain/repositories/scan_pass_spatial_library_repository.dart';
import '../domain/scan_pass/real_match_replay.dart';
import '../domain/scan_pass/scan_pass_spatial_library.dart';
import '../domain/scan_pass/scan_pass_spatial_personalization.dart';

class ScanPassSpatialLibraryService {
  static const storageKey = 'scan_pass_spatial_library_personalization_v1';

  final ScanPassSpatialLibraryRepository repository;
  final OptionRepository? optionRepository;

  SpatialLibraryPreferences _preferences;
  Future<void> _writeQueue = Future<void>.value();
  Object? _persistenceError;

  ScanPassSpatialLibraryService(
    this.repository, {
    this.optionRepository,
  }) : _preferences = _loadPreferences(optionRepository);

  SpatialLibraryPreferences get preferences => _preferences;
  Object? get persistenceError => _persistenceError;
  bool get hasPersistenceError => _persistenceError != null;

  Future<SpatialLibraryCatalog> loadCatalog() => repository.loadCatalog();

  Future<RealMatchReplayData> loadScene(SpatialLibraryScene scene) async {
    final data = await repository.loadScene(scene);
    scene.validateReplay(data);
    return data;
  }

  Future<void> prepareCatalog(SpatialLibraryCatalog catalog) async {
    final before = jsonEncode(_preferences.toJson());
    _preferences = _preferences.sanitized(catalog);
    if (jsonEncode(_preferences.toJson()) != before) await persist();
  }

  SpatialLibraryScene initialScene(
    SpatialLibraryCatalog catalog, {
    SpatialLibraryQueryMatcher matchesQuery = _defaultSpatialQueryMatcher,
  }) {
    final lastIdentity = _preferences.lastSceneIdentity;
    SpatialLibraryScene? lastScene;
    if (lastIdentity != null) {
      for (final scene in catalog.scenes) {
        if (scene.spatialHistoryIdentity == lastIdentity) {
          lastScene = scene;
          break;
        }
      }
    }
    if (lastScene != null && !isWatched(lastScene)) return lastScene;
    final filtered = filteredScenes(
      catalog: catalog,
      matchesQuery: matchesQuery,
    );
    if (lastScene != null) {
      final next = nextUnfinished(
        filteredScenes: filtered,
        currentSceneId: lastScene.id,
      );
      return next ?? lastScene;
    }
    for (final scene in filtered) {
      if (!isWatched(scene)) return scene;
    }
    return catalog.scenes.first;
  }

  double initialResumeTime(SpatialLibraryScene scene) =>
      isWatched(scene) ? scene.duration : resumeTime(scene);

  SpatialLibrarySceneRecord recordFor(SpatialLibraryScene scene) =>
      _preferences.records[scene.spatialHistoryIdentity] ??
      const SpatialLibrarySceneRecord();

  SpatialLibraryWatchState watchState(SpatialLibraryScene scene) =>
      recordFor(scene).coverage.watchState(scene.duration);

  bool isWatched(SpatialLibraryScene scene) =>
      recordFor(scene).coverage.watched(scene.duration);

  double coveredSeconds(SpatialLibraryScene scene) =>
      recordFor(scene).coverage.coveredSeconds(scene.duration);

  bool isBookmarked(SpatialLibraryScene scene) => recordFor(scene).bookmarked;

  double resumeTime(SpatialLibraryScene scene) {
    final record = recordFor(scene);
    if (record.coverage.watched(scene.duration)) return 0;
    final value = record.resumeTime;
    if (!value.isFinite || value >= scene.duration - .001) return 0;
    return value.clamp(0.0, scene.duration).toDouble();
  }

  void recordPlaying({
    required SpatialLibraryScene scene,
    required double from,
    required double to,
  }) {
    final previous = recordFor(scene);
    final coverage = previous.coverage.recordPlaying(
      duration: scene.duration,
      from: from,
      to: to,
    );
    final record = previous.copyWith(
      resumeTime: to.clamp(0.0, scene.duration).toDouble(),
      coverage: coverage,
    );
    _replaceRecord(scene, record, markRecent: true);
  }

  void updateResumeTime(SpatialLibraryScene scene, double sourceTime) {
    if (!sourceTime.isFinite) return;
    _replaceRecord(
      scene,
      recordFor(scene).copyWith(
        resumeTime: sourceTime.clamp(0.0, scene.duration).toDouble(),
      ),
      markRecent: true,
    );
  }

  Future<void> selectScene(
    SpatialLibraryScene scene, {
    required double sourceTime,
  }) async {
    updateResumeTime(scene, sourceTime);
    if (!isWatched(scene)) {
      _preferences = _preferences.copyWith(
        lastSceneIdentity: scene.spatialHistoryIdentity,
      );
    }
    await persist();
  }

  Future<void> checkpoint(
    SpatialLibraryScene scene, {
    required double sourceTime,
  }) async {
    updateResumeTime(scene, sourceTime);
    await persist();
  }

  Future<void> toggleBookmark(SpatialLibraryScene scene) async {
    final previous = recordFor(scene);
    _replaceRecord(
      scene,
      previous.copyWith(bookmarked: !previous.bookmarked),
    );
    await persist();
  }

  Future<void> setFilters(SpatialLibraryFilters filters) async {
    _preferences = _preferences.copyWith(filters: filters);
    await persist();
  }

  Future<void> setPlaybackMode(SpatialLibraryPlaybackMode mode) async {
    _preferences = _preferences.copyWith(playbackMode: mode);
    await persist();
  }

  Future<void> setAutoNext(bool enabled) async {
    _preferences = _preferences.copyWith(autoNext: enabled);
    await persist();
  }

  List<SpatialLibraryScene> filteredScenes({
    required SpatialLibraryCatalog catalog,
    required SpatialLibraryQueryMatcher matchesQuery,
  }) =>
      SpatialLibraryPersonalization.filteredScenes(
        catalog: catalog,
        preferences: _preferences,
        matchesQuery: matchesQuery,
      );

  SpatialLibraryScene? nextUnfinished({
    required List<SpatialLibraryScene> filteredScenes,
    required String currentSceneId,
  }) =>
      SpatialLibraryPersonalization.nextUnfinished(
        filteredScenes: filteredScenes,
        preferences: _preferences,
        currentSceneId: currentSceneId,
      );

  SpatialLibraryScene? relativeScene({
    required List<SpatialLibraryScene> filteredScenes,
    required String currentSceneId,
    required int delta,
  }) =>
      SpatialLibraryPersonalization.relativeScene(
        filteredScenes: filteredScenes,
        currentSceneId: currentSceneId,
        delta: delta,
      );

  Future<void> persist() {
    final options = optionRepository;
    if (options == null) {
      _persistenceError = null;
      return Future<void>.value();
    }
    final encoded = jsonEncode(_preferences.toJson());
    _writeQueue = _writeQueue.catchError((_) {}).then((_) async {
      try {
        await options.setValue(storageKey, encoded);
        _persistenceError = null;
      } catch (error) {
        _persistenceError = error;
      }
    });
    return _writeQueue;
  }

  Future<void> retryPersistence() => persist();

  Future<void> flush() => persist();

  void _replaceRecord(
    SpatialLibraryScene scene,
    SpatialLibrarySceneRecord record, {
    bool markRecent = false,
  }) {
    final records = Map<String, SpatialLibrarySceneRecord>.from(
      _preferences.records,
    );
    if (markRecent) records.remove(scene.spatialHistoryIdentity);
    records[scene.spatialHistoryIdentity] = record;
    _preferences = _preferences.copyWith(records: Map.unmodifiable(records));
  }

  static SpatialLibraryPreferences _loadPreferences(
    OptionRepository? repository,
  ) {
    if (repository == null) return const SpatialLibraryPreferences();
    try {
      final source = repository.getValue<String>(storageKey);
      if (source == null || source.trim().isEmpty) {
        return const SpatialLibraryPreferences();
      }
      return SpatialLibraryPreferences.fromJson(jsonDecode(source));
    } catch (_) {
      return const SpatialLibraryPreferences();
    }
  }
}

bool _defaultSpatialQueryMatcher(SpatialLibraryScene scene, String query) =>
    scene.matchesSearch(query);
