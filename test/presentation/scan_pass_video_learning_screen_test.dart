import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/video_learning_player.dart';
import 'package:football_note/application/video_learning_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/scan_pass/scan_pass_video_learning.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/gen/app_localizations_en.dart';
import 'package:football_note/gen/app_localizations_ja.dart';
import 'package:football_note/gen/app_localizations_ko.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';
import 'package:football_note/presentation/theme/app_theme.dart';

import '../domain/scan_pass_video_learning_test.dart'
    show testVideoLearningCatalogJson;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoLearningCatalog catalog;
  late _MemoryOptionRepository options;
  late _FakePlayer player;
  late List<Uri> opened;

  setUp(() {
    catalog = _twoSceneCatalog();
    options = _MemoryOptionRepository();
    player = _FakePlayer();
    opened = <Uri>[];
  });

  Widget app({
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) =>
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: theme ?? ThemeData.light(useMaterial3: true),
        home: ScanPassVideoLearningScreen(
          optionRepository: options,
          catalogLoader: () async => catalog,
          player: player,
          sourceLauncher: (uri) async {
            opened.add(uri);
            return true;
          },
        ),
      );

  testWidgets('phone narrow landscape and desktop layouts do not overflow',
      (tester) async {
    for (final size in <Size>[
      const Size(390, 844),
      const Size(320, 640),
      const Size(667, 320),
      const Size(1280, 900),
    ]) {
      player = _FakePlayer();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.byKey(const ValueKey<String>('video-learning-play')),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('video-learning-scenes')),
          findsOneWidget);
      for (final key in <String>[
        'video-learning-play',
        'video-learning-scenes',
      ]) {
        final rect = tester.getRect(find.byKey(ValueKey<String>(key)));
        expect(rect.top, greaterThanOrEqualTo(0), reason: '$key at $size');
        expect(rect.bottom, lessThanOrEqualTo(size.height),
            reason: '$key at $size');
      }
      expect(find.byKey(const ValueKey<String>('video-diagram-prepare')),
          findsOneWidget);
      if (size == const Size(667, 320)) {
        final surface = tester.getSize(
          find.byKey(const ValueKey<String>('video-learning-surface')),
        );
        expect(surface.width, greaterThanOrEqualTo(200));
        expect(surface.height, greaterThanOrEqualTo(200));
      }
      expect(tester.takeException(), isNull, reason: 'layout $size');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('source fallback is explicit and does not mark watched',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    player.emit(const VideoLearningPlayerEvent(
      state: VideoLearningPlayerState.error,
      mediaTime: 110,
      errorCode: '101',
    ));
    await tester.pump();

    expect(
        find.text(
            'The official video cannot play here. Retry or open the source.'),
        findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('video-learning-open-source')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('video-learning-open-source')),
    );
    await tester.pump();

    expect(opened.single.queryParameters['v'], 'abcdefghijk');
    expect(opened.single.queryParameters['t'], '110s');
    final stored = options.getValue<String>(VideoLearningService.storageKey);
    expect(stored, isNull);
  });

  testWidgets('unsupported player keeps its source fallback after load returns',
      (tester) async {
    final pending = _DeferredLoadPlayer();
    player = pending;
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(pending.loadStarted, isTrue);
    pending.emit(VideoLearningPlayerEvent(
      state: VideoLearningPlayerState.error,
      mediaTime: catalog.scenes.first.clip.start,
      sceneId: catalog.scenes.first.id,
      errorCode: 'native_unavailable',
    ));
    await tester.pump();
    pending.completeLoad();
    await tester.pump();
    await tester.pump(const Duration(seconds: 13));

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ScanPassVideoLearningScreen)),
    )!;
    expect(find.text(l10n.videoLearningNativeUnavailable), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('video-learning-retry-player')),
        findsNothing);
    expect(find.byKey(const ValueKey<String>('video-learning-open-source')),
        findsOneWidget);
  });

  testWidgets('scene sheet shows clip duration teams filters and state',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('video-learning-scenes')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('video-learning-scenes')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Clip 0:20'), findsNWidgets(2));
    expect(find.textContaining('Home v Away'), findsWidgets);
    expect(find.text('New'), findsNWidgets(2));
    expect(find.byKey(const ValueKey<String>('video-team-filter')),
        findsOneWidget);
    expect(find.text('2 of 2 scenes'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('video-team-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Second Home').last);
    await tester.pumpAndSettle();
    expect(find.text('1 of 2 scenes'), findsOneWidget);
  });

  testWidgets('parts rate and seek controls preserve paused playback',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await tester.tap(
      find.byKey(const ValueKey<String>('video-learning-settings')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('video-rate-0.75')));
    await tester.pump();
    expect(player.rates.last, .75);
    expect(player.playCalls, 0);

    await tester.tap(find.text('Parts'));
    await tester.pump();

    expect(player.playCalls, 0);
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('video-phase-1')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('video-phase-1')));
    await tester.pump();
    expect(player.seekTimes.last, 106);
    expect(player.playCalls, 0);
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    final slider = find.byKey(const ValueKey<String>('video-learning-slider'));
    await tester.drag(slider, const Offset(120, 0));
    await tester.pump();
    expect(player.seekTimes.last, inInclusiveRange(106, 112));
    expect(player.playCalls, 0);
  });

  testWidgets(
      'whole completion advances once to next unseen scene and restores',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    player.emit(const VideoLearningPlayerEvent(
      state: VideoLearningPlayerState.playing,
      mediaTime: 100,
    ));
    for (var time = 101.0; time < 120; time += 1) {
      player.emit(VideoLearningPlayerEvent(
        state: VideoLearningPlayerState.playing,
        mediaTime: time,
      ));
    }
    player.emit(const VideoLearningPlayerEvent(
      state: VideoLearningPlayerState.ended,
      mediaTime: 120,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(player.loadedScenes.last.id, 'scene-two');
    expect(
      player.loadedScenes.where((scene) => scene.id == 'scene-two'),
      hasLength(1),
    );

    final replacement = _FakePlayer();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ScanPassVideoLearningScreen(
        optionRepository: options,
        catalogLoader: () async => catalog,
        player: replacement,
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();
    expect(replacement.loadedScenes.single.id, 'scene-two');
  });

  testWidgets('real dark theme keeps headline and bottom controls legible',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(theme: AppTheme.dark()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));

    final title = tester.widget<Text>(
      find.byKey(const ValueKey<String>('video-learning-title')),
    );
    expect(title.style?.color?.computeLuminance(), greaterThan(.7));
    final decoration = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byKey(const ValueKey<String>('video-learning-controls')),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final color = (decoration.decoration as BoxDecoration).color!;
    expect(color.computeLuminance(), lessThan(.2));
    expect(
        find.byKey(const ValueKey<String>('video-learning-play')).hitTestable(),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'real catalogue rows retain duration and status at large phone text',
      (tester) async {
    catalog = VideoLearningCatalog.fromJsonString(
      File('assets/video_learning/catalog.json').readAsStringSync(),
    );
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    await tester.tap(
      find.byKey(const ValueKey<String>('video-learning-scenes')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'real catalogue sheet');

    final first = catalog.scenes.first;
    expect(
      find.byKey(ValueKey<String>('video-scene-duration-${first.id}')),
      findsOneWidget,
    );
    expect(find.text('Clip 0:28'), findsOneWidget);
    expect(
      find.byKey(ValueKey<String>('video-scene-status-${first.id}')),
      findsOneWidget,
    );
    expect(find.text('New'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('shipped catalogue resolves every copy key in EN KO and JA', () {
    final shipped = VideoLearningCatalog.fromJsonString(
      File('assets/video_learning/catalog.json').readAsStringSync(),
    );
    final localizations = <AppLocalizations>[
      AppLocalizationsEn(),
      AppLocalizationsKo(),
      AppLocalizationsJa(),
    ];

    for (final l10n in localizations) {
      for (final scene in shipped.scenes) {
        final keys = <String>[
          scene.titleKey,
          scene.focusKey,
          for (final phase in scene.phases) ...[
            phase.titleKey,
            phase.watchKey,
          ],
        ];
        for (final key in keys) {
          final copy = videoLearningLocalizedCopy(l10n, key);
          expect(copy, isNotEmpty, reason: '${l10n.localeName}: $key');
          expect(copy, isNot(l10n.videoLearningTitle),
              reason: '${l10n.localeName}: $key');
        }
      }
    }
  });

  testWidgets('rapid scene choices keep only the latest delayed selection',
      (tester) async {
    catalog = _threeSceneCatalog();
    final delayed = _DelayedOptionRepository();
    options = delayed;
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));

    final next = find.byKey(const ValueKey<String>('video-learning-next'));
    await tester.tap(next);
    await tester.pump();
    await tester.tap(next);
    await tester.pump();
    for (var attempt = 0; attempt < 8; attempt++) {
      delayed.releaseNextIfPending();
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 50));

    expect(player.loadedScenes.last.id, 'scene-three');
    final stored = jsonDecode(
      delayed.getValue<String>(VideoLearningService.storageKey)!,
    ) as Map<String, dynamic>;
    expect(stored['lastSceneId'], 'scene-three');

    player.emit(const VideoLearningPlayerEvent(
      state: VideoLearningPlayerState.error,
      mediaTime: 110,
      sceneId: 'scene-two',
      errorCode: 'stale',
    ));
    await tester.pump();
    expect(
        find.text(
          'The official video cannot play here. Retry or open the source.',
        ),
        findsNothing);
  });

  testWidgets('disposing during a pending player load ignores late completion',
      (tester) async {
    final deferred = _DeferredLoadPlayer();
    player = deferred;
    await tester.pumpWidget(app());
    await tester.pump();
    expect(deferred.loadStarted, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    deferred.completeLoad();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('default root is video-first and opens retained 2D library',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ScanPassGameScreen(optionRepository: options),
    ));
    for (var attempt = 0; attempt < 50; attempt++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (find.byType(ScanPassVideoLearningScreen).evaluate().isNotEmpty &&
          find
              .byKey(const ValueKey<String>('video-learning-settings'))
              .evaluate()
              .isNotEmpty) {
        break;
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
    expect(find.byType(ScanPassVideoLearningScreen), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('video-learning-settings')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('video-open-spatial-library')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('video-open-spatial-library')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ScanPassSpatialLibraryScreen), findsOneWidget);
  });
}

VideoLearningCatalog _twoSceneCatalog() {
  final first = testVideoLearningCatalogJson();
  final firstScene = (first['scenes'] as List).single as Map<String, dynamic>;
  final second = jsonDecode(jsonEncode(firstScene)) as Map<String, dynamic>;
  second['id'] = 'scene-two';
  second['videoId'] = '12345678901';
  final secondHome = second['homeTeam'] as Map<String, dynamic>;
  secondHome['id'] = 'second-home';
  secondHome['name'] = 'Second Home';
  final secondAway = second['awayTeam'] as Map<String, dynamic>;
  secondAway['id'] = 'second-away';
  secondAway['name'] = 'Second Away';
  return VideoLearningCatalog.fromJson(<String, dynamic>{
    'version': 1,
    'scenes': <Object>[firstScene, second],
  });
}

VideoLearningCatalog _threeSceneCatalog() {
  final two = _twoSceneCatalog();
  final source = testVideoLearningCatalogJson();
  final third = jsonDecode(
    jsonEncode((source['scenes'] as List).single),
  ) as Map<String, dynamic>;
  third['id'] = 'scene-three';
  third['videoId'] = 'ZYXWVUTSRQP';
  final home = third['homeTeam'] as Map<String, dynamic>;
  home['id'] = 'third-home';
  home['name'] = 'Third Home';
  final away = third['awayTeam'] as Map<String, dynamic>;
  away['id'] = 'third-away';
  away['name'] = 'Third Away';
  return VideoLearningCatalog(
    version: 1,
    scenes: <VideoLearningScene>[
      ...two.scenes,
      VideoLearningCatalog.fromJson(
        <String, dynamic>{
          'version': 1,
          'scenes': <Object>[third]
        },
      ).scenes.single
    ],
  );
}

class _FakePlayer implements VideoLearningPlayerPort {
  final StreamController<VideoLearningPlayerEvent> _events =
      StreamController<VideoLearningPlayerEvent>.broadcast();
  final List<VideoLearningScene> loadedScenes = <VideoLearningScene>[];
  final List<double> seekTimes = <double>[];
  final List<double> rates = <double>[];
  int playCalls = 0;
  int pauseCalls = 0;

  @override
  Stream<VideoLearningPlayerEvent> get events => _events.stream;

  void emit(VideoLearningPlayerEvent event) => _events.add(event);

  @override
  Future<void> load(
    VideoLearningScene scene, {
    required double initialTime,
    required bool autoplay,
  }) async {
    loadedScenes.add(scene);
    emit(VideoLearningPlayerEvent(
      state: VideoLearningPlayerState.ready,
      mediaTime: initialTime,
      sceneId: scene.id,
      supportedRates: const <double>[.5, .75, 1],
    ));
  }

  @override
  Future<void> pause() async {
    pauseCalls += 1;
  }

  @override
  Future<void> play() async {
    playCalls += 1;
  }

  @override
  Future<void> seek(double mediaTime) async {
    seekTimes.add(mediaTime);
  }

  @override
  Future<void> setPlaybackRate(double rate) async {
    rates.add(rate);
  }

  @override
  Future<void> dispose() async {
    await _events.close();
  }
}

class _DeferredLoadPlayer extends _FakePlayer {
  final Completer<void> _loadCompleter = Completer<void>();
  bool loadStarted = false;

  @override
  Future<void> load(
    VideoLearningScene scene, {
    required double initialTime,
    required bool autoplay,
  }) async {
    loadStarted = true;
    loadedScenes.add(scene);
    await _loadCompleter.future;
  }

  void completeLoad() {
    if (!_loadCompleter.isCompleted) _loadCompleter.complete();
  }
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<int> getIntOptions(String key, List<int> defaults) => defaults;

  @override
  List<String> getOptions(String key, List<String> defaults) => defaults;

  @override
  T? getValue<T>(String key) => _values[key] is T ? _values[key] as T : null;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }
}

class _DelayedOptionRepository extends _MemoryOptionRepository {
  final List<_PendingWrite> _pending = <_PendingWrite>[];

  @override
  Future<void> setValue(String key, dynamic value) {
    final write = _PendingWrite();
    _pending.add(write);
    return write.completer.future.then((_) {
      _values[key] = value;
    });
  }

  void releaseNextIfPending() {
    for (final write in _pending) {
      if (!write.completer.isCompleted) {
        write.completer.complete();
        return;
      }
    }
  }
}

class _PendingWrite {
  final Completer<void> completer = Completer<void>();

  _PendingWrite();
}
