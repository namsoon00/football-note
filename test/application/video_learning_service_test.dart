import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/video_learning_player.dart';
import 'package:football_note/application/video_learning_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/repositories/video_learning_repository.dart';
import 'package:football_note/domain/scan_pass/scan_pass_video_learning.dart';

import '../domain/scan_pass_video_learning_test.dart'
    show testVideoLearningCatalogJson;

void main() {
  late VideoLearningCatalog catalog;
  late VideoLearningScene scene;

  setUp(() {
    catalog = VideoLearningCatalog.fromJson(testVideoLearningCatalogJson());
    scene = catalog.scenes.single;
  });

  test('coverage counts real bounded playing telemetry but never a seek', () {
    var coverage = const VideoLearningCoverage();
    coverage = coverage.recordPlaying(scene: scene, from: 100, to: 101);
    coverage = coverage.recordPlaying(scene: scene, from: 101, to: 116);

    expect(coverage.coveredSeconds, 1);
    expect(coverage.reachedGoal, isFalse);
    expect(coverage.watched(scene), isFalse);
  });

  test('watched needs 80 percent unique coverage and the goal segment', () {
    var coverage = const VideoLearningCoverage();
    for (var time = 100.0; time < 115; time += 1) {
      coverage = coverage.recordPlaying(
        scene: scene,
        from: time,
        to: time + 1,
      );
    }
    expect(coverage.fraction(scene), .75);
    expect(coverage.watched(scene), isFalse);

    coverage = coverage.recordPlaying(scene: scene, from: 115, to: 116);
    expect(coverage.fraction(scene), .8);
    expect(coverage.watched(scene), isFalse);
    coverage = coverage.recordPlaying(scene: scene, from: 116, to: 117);
    expect(coverage.reachedGoal, isTrue);
    expect(coverage.watched(scene), isTrue);

    final replayed = coverage.recordPlaying(scene: scene, from: 116, to: 117);
    expect(replayed.coveredSeconds, coverage.coveredSeconds);
  });

  test('service restores resume and serializes rapid persistence writes',
      () async {
    final options = _DelayedOptionRepository();
    final service = VideoLearningService(
      catalogRepository: _Repository(catalog),
      optionRepository: options,
    );

    final first = service.setPlaybackRate(.75);
    final second = service.setAutoNext(false);
    await Future<void>.delayed(Duration.zero);
    expect(options.activeWrites, 1);
    options.releaseNext();
    await Future<void>.delayed(Duration.zero);
    expect(options.activeWrites, 1);
    options.releaseNext();
    await Future.wait(<Future<void>>[first, second]);

    final select = service.selectScene(scene, resumeTime: 109);
    await Future<void>.delayed(Duration.zero);
    options.releaseNext();
    await select;
    final flush = service.flush();
    await Future<void>.delayed(Duration.zero);
    options.releaseNext();
    await flush;
    final restored = VideoLearningService(
      catalogRepository: _Repository(catalog),
      optionRepository: options,
    );
    expect(restored.preferences.playbackRate, .75);
    expect(restored.preferences.autoNext, isFalse);
    expect(restored.preferences.lastSceneId, scene.id);
    expect(restored.resumeTime(scene), 109);
  });

  test('event accumulation flushes pause and ignores loading and jumps',
      () async {
    final options = _MemoryOptionRepository();
    final service = VideoLearningService(
      catalogRepository: _Repository(catalog),
      optionRepository: options,
    );
    await service.recordPlayerEvent(
      scene,
      const VideoLearningPlayerEvent(
        state: VideoLearningPlayerState.loading,
        mediaTime: 100,
      ),
      foreground: true,
    );
    await service.recordPlayerEvent(
      scene,
      const VideoLearningPlayerEvent(
        state: VideoLearningPlayerState.playing,
        mediaTime: 100,
      ),
      foreground: true,
    );
    await service.recordPlayerEvent(
      scene,
      const VideoLearningPlayerEvent(
        state: VideoLearningPlayerState.playing,
        mediaTime: 101,
      ),
      foreground: true,
    );
    await service.recordPlayerEvent(
      scene,
      const VideoLearningPlayerEvent(
        state: VideoLearningPlayerState.playing,
        mediaTime: 115,
      ),
      foreground: true,
    );
    await service.recordPlayerEvent(
      scene,
      const VideoLearningPlayerEvent(
        state: VideoLearningPlayerState.paused,
        mediaTime: 116,
      ),
      foreground: true,
    );

    expect(service.coverageFraction(scene), closeTo(.1, .001));
    expect(options.values[VideoLearningService.storageKey], isA<String>());
  });

  test('malformed saved history falls back without claiming watched', () {
    final options = _MemoryOptionRepository()
      ..values[VideoLearningService.storageKey] = '{not-json';
    final service = VideoLearningService(
      catalogRepository: _Repository(catalog),
      optionRepository: options,
    );

    expect(service.resumeTime(scene), scene.clip.start);
    expect(service.isWatched(scene), isFalse);
  });

  test('loaded overlap and out-of-clip ranges cannot manufacture completion',
      () {
    final coverage = VideoLearningCoverage.fromJson(<String, dynamic>{
      'intervals': <Object>[
        <double>[100, 115],
        <double>[100, 115],
        <double>[-100, 500],
      ],
      'reachedGoal': true,
    });

    expect(coverage.fraction(scene), .75);
    expect(coverage.watched(scene), isFalse);
  });

  test('source timing uncertainty never grants early watched completion', () {
    final source = testVideoLearningCatalogJson();
    final sceneJson = (source['scenes'] as List).single as Map<String, dynamic>;
    sceneJson['timestampTolerance'] = 10;
    final uncertainScene = VideoLearningCatalog.fromJson(source).scenes.single;
    var coverage = const VideoLearningCoverage();
    for (var time = 100.0; time < 116; time += 1) {
      coverage = coverage.recordPlaying(
        scene: uncertainScene,
        from: time,
        to: time + 1,
      );
    }

    expect(coverage.fraction(uncertainScene), .8);
    expect(coverage.watched(uncertainScene), isFalse);
  });

  test('large source tolerance does not discard a valid partial resume', () {
    final source = testVideoLearningCatalogJson();
    final sceneJson = (source['scenes'] as List).single as Map<String, dynamic>;
    sceneJson['timestampTolerance'] = 10;
    final uncertainCatalog = VideoLearningCatalog.fromJson(source);
    final uncertainScene = uncertainCatalog.scenes.single;
    final options = _MemoryOptionRepository()
      ..values[VideoLearningService.storageKey] = jsonEncode(<String, dynamic>{
        'version': 1,
        'lastSceneId': uncertainScene.id,
        'resumeTimes': <String, double>{uncertainScene.id: 109},
        'coverage': <String, dynamic>{},
        'watchFilter': 'all',
        'playbackRate': 1,
        'autoNext': true,
      });
    final service = VideoLearningService(
      catalogRepository: _Repository(uncertainCatalog),
      optionRepository: options,
    );

    expect(service.resumeTime(uncertainScene), 109);
  });

  test('expanded catalogue preserves existing scene resume and history', () {
    final shipped = VideoLearningCatalog.fromJsonString(
      File('assets/video_learning/catalog.json').readAsStringSync(),
    );
    final existing = shipped.scenes.firstWhere(
      (candidate) => candidate.id == 'clasico-messi-winner-20170423',
    );
    final options = _MemoryOptionRepository()
      ..values[VideoLearningService.storageKey] = jsonEncode(<String, dynamic>{
        'version': 1,
        'lastSceneId': existing.id,
        'resumeTimes': <String, double>{existing.id: 6060},
        'coverage': <String, dynamic>{
          existing.id: <String, dynamic>{
            'intervals': <Object>[
              <double>[existing.clip.start, existing.goalTime + .25],
            ],
            'reachedGoal': true,
          },
        },
        'teamFilter': existing.awayTeam.id,
        'watchFilter': 'watched',
        'playbackRate': .75,
        'autoNext': false,
      });
    final service = VideoLearningService(
      catalogRepository: _Repository(shipped),
      optionRepository: options,
    );

    expect(service.preferences.lastSceneId, existing.id);
    expect(service.resumeTime(existing), 6060);
    expect(service.isWatched(existing), isTrue);
    expect(service.preferences.teamFilter, existing.awayTeam.id);
    expect(service.preferences.watchFilter, VideoLearningWatchFilter.watched);
  });

  test('wrong saved repository type cannot crash preference recovery', () {
    final service = VideoLearningService(
      catalogRepository: _Repository(catalog),
      optionRepository: _ThrowingGetOptionRepository(),
    );

    expect(service.preferences, isA<VideoLearningPreferences>());
    expect(service.resumeTime(scene), scene.clip.start);
  });
}

class _Repository implements VideoLearningRepository {
  final VideoLearningCatalog catalog;

  const _Repository(this.catalog);

  @override
  Future<VideoLearningCatalog> loadCatalog() async => catalog;
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
    final pending = _pending.firstWhere((value) => !value.isCompleted);
    pending.complete();
  }
}

class _ThrowingGetOptionRepository extends _MemoryOptionRepository {
  @override
  T? getValue<T>(String key) {
    throw StateError('saved value has the wrong runtime type');
  }
}
