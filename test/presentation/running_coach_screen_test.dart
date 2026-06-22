import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/running_coach_screen.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  late VideoPlayerPlatform previousVideoPlayerPlatform;

  setUp(() {
    previousVideoPlayerPlatform = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = _FakeVideoPlayerPlatform();
  });

  tearDown(() {
    VideoPlayerPlatform.instance = previousVideoPlayerPlatform;
  });

  testWidgets('growth loop records a sprint time and shows badges', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final optionRepository = _MemoryOptionRepository();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: RunningCoachScreen(optionRepository: optionRepository),
      ),
    );

    expect(
      find.byKey(const ValueKey('running-coach-today-mission-card')),
      findsOneWidget,
    );
    expect(find.text("Today's speed mission"), findsOneWidget);
    expect(find.text('Session plan'), findsNothing);
    expect(find.text('Coach checkpoint'), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('running-coach-growth-record-card')),
      -220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Beat your own runner'), findsOneWidget);
    expect(find.text('No time yet'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('running-coach-record-seconds-field')),
      '4.32',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('running-coach-record-save-button')),
      -220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('running-coach-record-save-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('4.32s'), findsOneWidget);
    expect(find.text('First sprint'), findsOneWidget);
    expect(find.text('Sprint time saved.'), findsOneWidget);
  });

  testWidgets('sample sheet shows framed runner posture cues', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: RunningCoachScreen(),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Open sample video guide'),
      -220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Open sample video guide'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('running-coach-sample-video-frame')),
      findsOneWidget,
    );
    final referenceVideo = await rootBundle.load(
      'assets/videos/running_coach_reference_sample.mp4',
    );
    final mistakeVideo = await rootBundle.load(
      'assets/videos/running_coach_mistake_sample.mp4',
    );
    expect(referenceVideo.lengthInBytes, greaterThan(1500000));
    expect(mistakeVideo.lengthInBytes, greaterThan(1000000));
    expect(
      listEquals(
        referenceVideo.buffer.asUint8List(
          referenceVideo.offsetInBytes,
          referenceVideo.lengthInBytes,
        ),
        mistakeVideo.buffer.asUint8List(
          mistakeVideo.offsetInBytes,
          mistakeVideo.lengthInBytes,
        ),
      ),
      isFalse,
    );
    expect(
      find.byKey(const ValueKey('running-coach-sample-frame-guide')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-sample-recording-guide')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-sample-joint-readouts')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-sample-analysis-method')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-sample-analysis-process')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-sample-analysis-phase')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-sample-fake-video-view')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.byKey(const ValueKey('running-coach-sample-back-button')),
      findsOneWidget,
    );
    expect(find.text('Reference sample'), findsOneWidget);
    expect(find.text('Wrong form sample'), findsOneWidget);
    expect(find.text('What to compare in the video'), findsOneWidget);
    expect(find.text('Reference readouts'), findsOneWidget);
    expect(find.text('Analysis process on the real clip'), findsOneWidget);
    expect(find.text('Sample frame'), findsWidgets);
    expect(find.textContaining('Track joints'), findsOneWidget);
    expect(find.textContaining('Map muscle load'), findsOneWidget);
    expect(find.textContaining('Connect pose lines'), findsOneWidget);
    expect(find.textContaining('Measure angles'), findsOneWidget);
    expect(find.textContaining('Score contact confidence'), findsOneWidget);
    expect(find.text('Decision evidence'), findsOneWidget);
    expect(find.text('Forward lean'), findsWidgets);
    expect(find.text('Bounce'), findsOneWidget);
    expect(find.textContaining('Frame '), findsWidgets);
    expect(find.text('Landing 0.08'), findsOneWidget);
    expect(find.text('Bounce 6%'), findsOneWidget);
    expect(find.text('Pass'), findsWidgets);
    expect(
      find.text('Foot lands under the hip with toes forward'),
      findsOneWidget,
    );
    expect(find.textContaining('landing distance is 0.08'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('running-coach-sample-decision-posture')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('running-coach-sample-metric-detail')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-sample-metric-detail-visual')),
      findsOneWidget,
    );
    expect(find.text('Evidence detail'), findsOneWidget);
    expect(find.text('Measured value'), findsOneWidget);
    expect(find.text('Good range'), findsOneWidget);
    expect(find.text('Lean 10°'), findsWidgets);
    expect(find.textContaining('8-24°'), findsWidgets);
    expect(find.textContaining('vertical hip line'), findsWidgets);

    Navigator.of(
      tester.element(
        find.byKey(const ValueKey('running-coach-sample-metric-detail')),
      ),
    ).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wrong form sample'));
    await tester.pump();

    expect(find.text('Wrong-form readouts'), findsOneWidget);
    expect(find.text('Ahead 0.20'), findsOneWidget);
    expect(find.text('Bounce'), findsOneWidget);
    expect(find.text('Bounce 10%'), findsWidgets);
    expect(find.text('Review'), findsWidgets);
    expect(
      find.textContaining('landing is 0.20 ahead of the hip'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('running-coach-sample-decision-bounce')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('running-coach-sample-metric-detail')),
      findsOneWidget,
    );
    expect(find.text('Bounce 10%'), findsWidgets);
    expect(find.textContaining('head and hip height band'), findsOneWidget);

    Navigator.of(
      tester.element(
        find.byKey(const ValueKey('running-coach-sample-metric-detail')),
      ),
    ).pop();
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('running-coach-sample-back-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('running-coach-sample-video-frame')),
      findsNothing,
    );
    expect(find.text('Running Coach'), findsOneWidget);
  });
}

class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> _streams =
      <int, StreamController<VideoEvent>>{};
  int _nextPlayerId = 0;

  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) => _createPlayer();

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) =>
      _createPlayer();

  Future<int?> _createPlayer() async {
    final playerId = _nextPlayerId++;
    final stream = StreamController<VideoEvent>();
    _streams[playerId] = stream;
    scheduleMicrotask(() {
      if (stream.isClosed) return;
      stream.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 4),
          size: const Size(1280, 720),
        ),
      );
      stream.add(
        VideoEvent(
          eventType: VideoEventType.isPlayingStateUpdate,
          isPlaying: true,
        ),
      );
    });
    return playerId;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _streams[playerId]!.stream;

  @override
  Future<void> dispose(int playerId) async {
    await _streams.remove(playerId)?.close();
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<Duration> getPosition(int playerId) async =>
      const Duration(milliseconds: 500);

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Widget buildView(int playerId) {
    return const SizedBox.expand(
      key: ValueKey('running-coach-sample-fake-video-view'),
    );
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      buildView(options.playerId);
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = {};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    _values[key] = defaults;
    return List<String>.from(defaults);
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List) {
      return value.map((item) => int.tryParse(item.toString()) ?? 0).toList();
    }
    _values[key] = defaults;
    return List<int>.from(defaults);
  }

  @override
  T? getValue<T>(String key) => _values[key] as T?;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }
}
