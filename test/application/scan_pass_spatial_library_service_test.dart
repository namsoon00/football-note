import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/scan_pass_spatial_library_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/repositories/scan_pass_spatial_library_repository.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_library.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_personalization.dart';
import 'package:football_note/infrastructure/scan_pass_spatial_asset_repository.dart';

void main() {
  late ScanPassSpatialAssetRepository assets;
  late SpatialLibraryCatalog catalog;

  setUpAll(() async {
    assets = ScanPassSpatialAssetRepository(
      loadAsset: (asset) => File(asset).readAsString(),
    );
    catalog = await assets.loadCatalog();
  });

  test(
    'asset repository hashes, parses, and service-validates a scene',
    () async {
      final service = ScanPassSpatialLibraryService(assets);
      final loadedCatalog = await service.loadCatalog();
      final scene = loadedCatalog.scenes.first;
      final data = await service.loadScene(scene);

      expect(loadedCatalog.scenes, isNotEmpty);
      expect(data.scene.id, scene.id);
      expect(data.match.id, scene.matchId);
    },
    tags: 'prelaunch-smoke',
  );

  test('asset repository rejects corrupt scene bytes before parsing', () async {
    final scene = catalog.scenes.first;
    final corrupt = ScanPassSpatialAssetRepository(
      loadAsset: (asset) async {
        final source = await File(asset).readAsString();
        return asset == scene.asset ? '$source\ncorrupt' : source;
      },
    );

    expect(corrupt.loadScene(scene), throwsFormatException);
  });

  test('application service rejects a valid payload from another scene',
      () async {
    final first = catalog.scenes.first;
    final second = catalog.scenes[1];
    final wrongData = RealMatchReplayData.fromJsonString(
      File(second.asset).readAsStringSync(),
    );
    final service = ScanPassSpatialLibraryService(
      _FakeRepository(catalog, wrongData),
    );

    expect(service.loadScene(first), throwsFormatException);
  });

  test(
    'restores exact source time, mode, filters, and bookmark paused state',
    () async {
      final options = _MemoryOptionRepository();
      final scene = catalog.scenes.first;
      final service = ScanPassSpatialLibraryService(
        assets,
        optionRepository: options,
      );
      await service.prepareCatalog(catalog);
      await service.selectScene(scene, sourceTime: 12.25);
      await service.setPlaybackMode(SpatialLibraryPlaybackMode.source);
      await service.setFilters(SpatialLibraryFilters(
        query: scene.focusPlayerName,
        attackingTeam: scene.attackingTeam,
        player: scene.focusPlayerName,
        watchFilter: SpatialLibraryWatchFilter.inProgress,
        unfinishedFirst: false,
      ));
      await service.toggleBookmark(scene);

      final restored = ScanPassSpatialLibraryService(
        assets,
        optionRepository: options,
      );
      await restored.prepareCatalog(catalog);

      expect(restored.initialScene(catalog).id, scene.id);
      expect(restored.resumeTime(scene), 12.25);
      expect(
        restored.preferences.playbackMode,
        SpatialLibraryPlaybackMode.source,
      );
      expect(restored.preferences.filters.query, scene.focusPlayerName);
      expect(restored.preferences.filters.attackingTeam, scene.attackingTeam);
      expect(restored.preferences.filters.player, scene.focusPlayerName);
      expect(
        restored.preferences.filters.watchFilter,
        SpatialLibraryWatchFilter.inProgress,
      );
      expect(restored.preferences.filters.unfinishedFirst, isFalse);
      expect(restored.isBookmarked(scene), isTrue);
      expect(restored.isWatched(scene), isFalse);
    },
    tags: 'prelaunch-smoke',
  );

  test('seek, repeat, and jumps cannot manufacture spatial completion',
      () async {
    final service = ScanPassSpatialLibraryService(assets);
    final scene = catalog.scenes.first;
    await service.prepareCatalog(catalog);
    service.updateResumeTime(scene, scene.duration);
    service.recordPlaying(scene: scene, from: 0, to: 1);
    service.recordPlaying(scene: scene, from: 0, to: 1);
    service.recordPlaying(scene: scene, from: 1, to: scene.duration);

    expect(service.coveredSeconds(scene), 1);
    expect(service.isWatched(scene), isFalse);
    expect(service.resumeTime(scene), 0);
  });

  test('completing the latest scene keeps the prior unfinished resume target',
      () async {
    final service = ScanPassSpatialLibraryService(assets);
    final first = catalog.scenes[0];
    final second = catalog.scenes[1];
    await service.prepareCatalog(catalog);
    await service.selectScene(first, sourceTime: 0);
    service.recordPlaying(scene: first, from: 0, to: 1);
    await service.selectScene(second, sourceTime: 0);
    for (var from = 0.0; from < second.duration; from += 1) {
      service.recordPlaying(
        scene: second,
        from: from,
        to: (from + 1).clamp(0.0, second.duration),
      );
    }

    expect(service.isWatched(second), isTrue);
    expect(service.initialScene(catalog).id, first.id);
    expect(service.resumeTime(first), 1);
  });

  test('completed last scene reopens next unfinished within saved filters',
      () async {
    final grouped = <(String, String), List<SpatialLibraryScene>>{};
    for (final scene in catalog.scenes) {
      for (final player in scene.participantNames) {
        grouped.putIfAbsent(
          (scene.attackingTeam, player),
          () => <SpatialLibraryScene>[],
        ).add(scene);
      }
    }
    final group =
        grouped.entries.firstWhere((entry) => entry.value.length >= 2);
    final eligible = group.value;
    final first = eligible[0];
    final second = eligible[1];
    final service = ScanPassSpatialLibraryService(assets);
    await service.prepareCatalog(catalog);
    await service.setFilters(SpatialLibraryFilters(
      query: first.attackingTeam,
      attackingTeam: first.attackingTeam,
      player: group.key.$2,
    ));
    await service.selectScene(first, sourceTime: 0);
    for (var from = 0.0; from < first.duration; from += 1) {
      service.recordPlaying(
        scene: first,
        from: from,
        to: (from + 1).clamp(0.0, first.duration),
      );
    }

    expect(service.isWatched(first), isTrue);
    expect(service.initialScene(catalog).id, second.id);
    expect(service.isWatched(service.initialScene(catalog)), isFalse);
  });

  test('all watched keeps the last completed scene at replay position',
      () async {
    final scenes = catalog.scenes.take(2).toList(growable: false);
    final smallCatalog = SpatialLibraryCatalog(
      version: catalog.version,
      provider: catalog.provider,
      license: catalog.license,
      sourceCommit: catalog.sourceCommit,
      sourceUrl: catalog.sourceUrl,
      matchCount: catalog.matchCount,
      scenes: scenes,
      proofVersion: catalog.proofVersion,
      actionProofVersion: catalog.actionProofVersion,
      sourcePins: catalog.sourcePins,
    );
    final service = ScanPassSpatialLibraryService(assets);
    await service.prepareCatalog(smallCatalog);
    for (final scene in scenes) {
      await service.selectScene(scene, sourceTime: 0);
      for (var from = 0.0; from < scene.duration; from += 1) {
        service.recordPlaying(
          scene: scene,
          from: from,
          to: (from + 1).clamp(0.0, scene.duration),
        );
      }
      await service.checkpoint(scene, sourceTime: scene.duration);
    }

    final initial = service.initialScene(smallCatalog);
    expect(initial.id, scenes.last.id);
    expect(service.initialResumeTime(initial), initial.duration);
  });

  test('rapid persistence writes are serialized in preference order', () async {
    final options = _DelayedOptionRepository();
    final service = ScanPassSpatialLibraryService(
      assets,
      optionRepository: options,
    );

    final first = service.setAutoNext(false);
    final second = service.setPlaybackMode(SpatialLibraryPlaybackMode.source);
    await Future<void>.delayed(Duration.zero);
    expect(options.activeWrites, 1);
    options.releaseNext();
    await Future<void>.delayed(Duration.zero);
    expect(options.activeWrites, 1);
    options.releaseNext();
    await Future.wait(<Future<void>>[first, second]);

    final restored = ScanPassSpatialLibraryService(
      assets,
      optionRepository: options,
    );
    expect(restored.preferences.autoNext, isFalse);
    expect(
      restored.preferences.playbackMode,
      SpatialLibraryPlaybackMode.source,
    );
  });

  test(
    'corrupt and stale source-bound history is discarded safely',
    () async {
      final scene = catalog.scenes.first;
      final options = _MemoryOptionRepository()
        ..values[ScanPassSpatialLibraryService.storageKey] = jsonEncode(
          <String, dynamic>{
            'version': 1,
            'lastSceneIdentity': '${scene.id}:old-source-hash',
            'records': <String, dynamic>{
              '${scene.id}:old-source-hash': <String, dynamic>{
                'resumeTime': 999,
                'coverage': <String, dynamic>{
                  'intervals': <Object>[
                    <double>[0, 999],
                  ],
                  'playedFinalInterval': true,
                },
                'bookmarked': true,
              },
            },
            'filters': <String, dynamic>{
              'attackingTeam': 'Deleted team',
              'player': 'Deleted player',
              'watchFilter': 'invalid',
            },
            'playbackMode': 'invalid',
            'autoNext': 'invalid',
          },
        );
      final service = ScanPassSpatialLibraryService(
        assets,
        optionRepository: options,
      );
      await service.prepareCatalog(catalog);

      expect(service.preferences.records, isEmpty);
      expect(service.preferences.lastSceneIdentity, isNull);
      expect(service.preferences.filters.attackingTeam, isNull);
      expect(service.preferences.filters.player, isNull);
      expect(
        service.preferences.filters.watchFilter,
        SpatialLibraryWatchFilter.all,
      );
      expect(service.resumeTime(scene), 0);
    },
    tags: 'prelaunch-smoke',
  );

  test('save failure keeps playback state in memory and retry recovers',
      () async {
    final options = _FailOnceOptionRepository();
    final service = ScanPassSpatialLibraryService(
      assets,
      optionRepository: options,
    );
    final scene = catalog.scenes.first;

    await service.selectScene(scene, sourceTime: 4.5);
    expect(service.hasPersistenceError, isTrue);
    expect(service.resumeTime(scene), 4.5);
    await service.retryPersistence();

    expect(service.hasPersistenceError, isFalse);
    final restored = ScanPassSpatialLibraryService(
      assets,
      optionRepository: options,
    );
    expect(restored.resumeTime(scene), 4.5);
  });
}

class _FakeRepository implements ScanPassSpatialLibraryRepository {
  final SpatialLibraryCatalog catalog;
  final RealMatchReplayData scene;

  const _FakeRepository(this.catalog, this.scene);

  @override
  Future<SpatialLibraryCatalog> loadCatalog() async => catalog;

  @override
  Future<RealMatchReplayData> loadScene(SpatialLibraryScene scene) async =>
      this.scene;
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> values = <String, dynamic>{};

  @override
  List<int> getIntOptions(String key, List<int> defaults) => defaults;

  @override
  List<String> getOptions(String key, List<String> defaults) => defaults;

  @override
  T? getValue<T>(String key) => values[key] is T ? values[key] as T : null;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    values[key] = value;
  }
}

class _DelayedOptionRepository extends _MemoryOptionRepository {
  final List<Completer<void>> _pending = <Completer<void>>[];
  int activeWrites = 0;

  @override
  Future<void> setValue(String key, dynamic value) async {
    activeWrites += 1;
    final completer = Completer<void>();
    _pending.add(completer);
    await completer.future;
    values[key] = value;
    activeWrites -= 1;
  }

  void releaseNext() {
    _pending.firstWhere((value) => !value.isCompleted).complete();
  }
}

class _FailOnceOptionRepository extends _MemoryOptionRepository {
  bool failNext = true;

  @override
  Future<void> setValue(String key, dynamic value) async {
    if (failNext) {
      failNext = false;
      throw StateError('disk unavailable');
    }
    await super.setValue(key, value);
  }
}
