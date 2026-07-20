import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_coach_history_service.dart';
import 'package:football_note/application/running_coaching_service.dart';
import 'package:football_note/application/running_video_analysis_service.dart';
import 'package:football_note/domain/entities/running_coach_session.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/running_coach_screen.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

const _sampleReferenceVideoAssetForTest =
    'assets/videos/running_coach_reference_sample.mp4';
const _sampleMistakeVideoAssetForTest =
    'assets/videos/running_coach_mistake_sample.mp4';

void main() {
  late VideoPlayerPlatform previousVideoPlayerPlatform;

  setUp(() {
    previousVideoPlayerPlatform = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = _FakeVideoPlayerPlatform();
  });

  tearDown(() {
    VideoPlayerPlatform.instance = previousVideoPlayerPlatform;
  });

  testWidgets('coach screen omits the personal record chase area', (
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
    expect(
      find.byKey(const ValueKey('running-coach-growth-record-card')),
      findsNothing,
    );
    expect(find.text('Beat your own runner'), findsNothing);
    expect(find.text('Open sample video guide'), findsOneWidget);
  });

  testWidgets('sample sheet shows framed runner posture cues', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final analysisService = _FakeRunningVideoAnalysisService();
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
        home: RunningCoachScreen(
          analysisService: analysisService,
          sampleVideoPreparer: _prepareSampleVideoForTest,
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Open sample video guide'),
      -220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Open sample video guide'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('running-coach-sample-analysis-loading')),
      findsOneWidget,
    );
    await tester.runAsync(() => analysisService.waitForCallCount(2));
    await tester.pump();
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('running-coach-sample-video-frame')),
    );

    expect(analysisService.calls, hasLength(2));
    expect(
      analysisService.calls,
      everyElement(contains('football_note_running_sample_')),
    );
    expect(
      analysisService.calls,
      isNot(contains(_sampleReferenceVideoAssetForTest)),
    );
    expect(analysisService.fileExistsAtCall, everyElement(isTrue));
    expect(analysisService.fileLengthAtCall, everyElement(greaterThan(0)));

    expect(
      find.byKey(const ValueKey('running-coach-sample-video-frame')),
      findsOneWidget,
    );
    final referenceVideo = await rootBundle.load(
      _sampleReferenceVideoAssetForTest,
    );
    final mistakeVideo = await rootBundle.load(
      _sampleMistakeVideoAssetForTest,
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

    await tester.ensureVisible(
      find.byKey(const ValueKey('running-coach-sample-decision-posture')),
    );
    await tester.pump();
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

    await tester.ensureVisible(find.text('Wrong form sample'));
    await tester.pump();
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

    await tester.ensureVisible(
      find.byKey(const ValueKey('running-coach-sample-decision-bounce')),
    );
    await tester.pump();
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

    await tester.ensureVisible(
      find.byKey(const ValueKey('running-coach-sample-back-button')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('running-coach-sample-back-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('running-coach-sample-video-frame')),
      findsNothing,
    );
    expect(find.text('Running Coach'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open sample video guide'),
      -220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Open sample video guide'));
    await tester.pump();
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('running-coach-sample-video-frame')),
    );
    expect(analysisService.calls, hasLength(2));
  });

  testWidgets('sample sheet shows localized error and retries native analysis',
      (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final analysisService =
        _FakeRunningVideoAnalysisService(failFirstCall: true);
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
        home: RunningCoachScreen(
          analysisService: analysisService,
          sampleVideoPreparer: _prepareSampleVideoForTest,
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Open sample video guide'),
      -220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Open sample video guide'));
    await tester.pump();
    await tester.runAsync(() => analysisService.waitForCallCount(1));
    await tester.pump();
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('running-coach-sample-analysis-error')),
    );

    expect(find.text('Sample analysis unavailable'), findsOneWidget);
    expect(
      find.text(
        'The runner could not be tracked well enough. Try a clearer side-view clip with elbows, knees, and feet visible.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry sample analysis'), findsOneWidget);

    final retryButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('running-coach-sample-analysis-retry')),
    );
    retryButton.onPressed!();
    await tester.pump();
    await tester.runAsync(() => analysisService.waitForCallCount(3));
    await tester.pump();
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('running-coach-sample-video-frame')),
    );

    expect(analysisService.calls, hasLength(3));
    expect(find.text('Reference sample'), findsOneWidget);
  });

  testWidgets('analysis history opens a visual correction guide', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final optionRepository = _MemoryOptionRepository();
    final session = RunningCoachSessionAnalysis(
      id: 'upload-test',
      analyzedAt: DateTime(2026, 6, 28, 9, 30),
      source: RunningCoachSessionSource.uploadVideo,
      overallScore: 72,
      duration: const Duration(seconds: 4),
      sampledFrames: 24,
      validFrames: 21,
      primaryMetric: RunningCoachMetric.posture,
      primaryFinding: RunningCoachFinding.postureTooUpright,
      primaryStatus: RunningCoachStatus.watch,
      primaryScore: 70,
      primaryValue: 4,
      primaryConfidence: 0.86,
      videoPath: '/missing/running-coach-test.mp4',
      videoName: 'side-view-test.mp4',
    );
    await optionRepository.setValue(
      RunningCoachHistoryService.storageKey,
      jsonEncode([session.toMap()]),
    );

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
    await tester.pumpAndSettle();

    expect(find.text('Video analysis history'), findsOneWidget);
    expect(find.text('All 1'), findsOneWidget);
    expect(find.text('Video saved'), findsOneWidget);

    await tester.tap(find.text('All 1'));
    await tester.pumpAndSettle();

    expect(find.text('Video analysis history'), findsWidgets);
    expect(
        find.text(
            'Review each analyzed video with its key decision and correction guide.'),
        findsWidgets);
    expect(find.text('Posture'), findsWidgets);
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.tap(find.text('Posture').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Analysis guide'), findsOneWidget);
    expect(find.text('Analyzed video'), findsOneWidget);
    expect(find.text('side-view-test.mp4'), findsOneWidget);
    expect(find.text('Correction point in pictures'), findsOneWidget);
    expect(
      find.text('Target: 8-15° whole-body forward lean from the ankles'),
      findsWidgets,
    );
    expect(find.text('Action cue'), findsOneWidget);
    expect(find.text('Recommended drill'), findsOneWidget);
  });

  testWidgets('analysis result layout stays readable on narrow phones', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const longVideoName =
        '2026-07-14-side-view-sprint-overstride-right-camera-angle-final-review.mp4';
    const result = RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 8),
      sampledFrames: 30,
      validFrames: 28,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 4,
      verticalBounceRatio: 0.10,
      footStrikeDistanceRatio: 0.25,
      stanceKneeAngleDegrees: 172,
      elbowAngleDegrees: 126,
      metricQualities: <RunningCoachMetric, RunningMetricQuality>{
        RunningCoachMetric.posture: RunningMetricQuality(
          confidence: 1,
          sampleCount: 28,
        ),
        RunningCoachMetric.bounce: RunningMetricQuality(
          confidence: 1,
          sampleCount: 28,
        ),
        RunningCoachMetric.footStrike: RunningMetricQuality(
          confidence: 1,
          sampleCount: 28,
        ),
        RunningCoachMetric.kneeFlexion: RunningMetricQuality(
          confidence: 1,
          sampleCount: 28,
        ),
        RunningCoachMetric.armCarriage: RunningMetricQuality(
          confidence: 1,
          sampleCount: 28,
        ),
      },
    );
    final report = const RunningCoachingService().buildReport(result);
    final primary = report.primaryFocus!;
    final session = RunningCoachSessionAnalysis(
      id: 'layout-stress',
      analyzedAt: DateTime(2026, 7, 14, 9),
      source: RunningCoachSessionSource.uploadVideo,
      overallScore: report.overallScore,
      duration: result.videoDuration,
      sampledFrames: result.sampledFrames,
      validFrames: result.validFrames,
      primaryMetric: primary.metric,
      primaryFinding: primary.finding,
      primaryStatus: primary.status,
      primaryScore: primary.score,
      primaryValue: primary.value,
      primaryConfidence: primary.quality.confidence,
      videoName: longVideoName,
    );

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
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: runningArchivedAnalysisVideoCardForTesting(
              session: session,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('running-coach-archived-video-card')),
      findsOneWidget,
    );
    final analyzedVideoTitle = find.text('Analyzed video');
    expect(analyzedVideoTitle, findsOneWidget);
    final titleSize = tester.getSize(analyzedVideoTitle);
    expect(titleSize.width, greaterThan(90));
    expect(titleSize.height, lessThan(40));

    final videoName = find.text(longVideoName);
    expect(videoName, findsOneWidget);
    final videoNameSize = tester.getSize(videoName);
    expect(videoNameSize.width, greaterThan(180));
    expect(videoNameSize.height, lessThan(28));

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
        home: runningAnalysisResultScreenForTesting(
          result: result,
          report: report,
          session: session,
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    for (var scrollStep = 0; scrollStep < 8; scrollStep += 1) {
      await tester.drag(
        find.byType(Scrollable).first,
        const Offset(0, -520),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);
    }
  });
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int attempts = 40,
}) async {
  for (var attempt = 0; attempt < attempts; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for $finder');
}

Future<RunningCoachPreparedSampleVideo> _prepareSampleVideoForTest(
  String assetPath,
) async {
  final tempDirectory = Directory.systemTemp.createTempSync(
    'football_note_running_sample_test_',
  );
  final file = File('${tempDirectory.path}/${assetPath.split('/').last}');
  file.writeAsBytesSync(assetPath.codeUnits, flush: true);
  return RunningCoachPreparedSampleVideo(
    file: file,
    dispose: () async {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    },
  );
}

class _FakeRunningVideoAnalysisService extends RunningVideoAnalysisService {
  final bool failFirstCall;
  final List<String> calls = <String>[];
  final List<bool> fileExistsAtCall = <bool>[];
  final List<int> fileLengthAtCall = <int>[];

  _FakeRunningVideoAnalysisService({this.failFirstCall = false});

  Future<void> waitForCallCount(int count) async {
    for (var attempt = 0; attempt < 500; attempt += 1) {
      if (calls.length >= count) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw StateError('Timed out waiting for $count analysis calls.');
  }

  @override
  Future<RunningVideoAnalysisResult> analyzeVideo(String path) async {
    calls.add(path);
    final file = File(path);
    fileExistsAtCall.add(file.existsSync());
    fileLengthAtCall.add(file.existsSync() ? file.lengthSync() : 0);
    if (failFirstCall && calls.length == 1) {
      throw const RunningVideoAnalysisException(
        'no_pose_detected',
        'No pose detected in fixture.',
      );
    }
    if (path.endsWith('running_coach_mistake_sample.mp4')) {
      return const RunningVideoAnalysisResult(
        videoDuration: Duration(seconds: 4),
        sampledFrames: 14,
        validFrames: 12,
        direction: RunningDirection.leftToRight,
        forwardLeanDegrees: 4,
        verticalBounceRatio: 0.10,
        footStrikeDistanceRatio: 0.20,
        stanceKneeAngleDegrees: 172,
        elbowAngleDegrees: 118,
      );
    }
    return const RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 4),
      sampledFrames: 14,
      validFrames: 13,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 10,
      verticalBounceRatio: 0.06,
      footStrikeDistanceRatio: 0.08,
      stanceKneeAngleDegrees: 155,
      elbowAngleDegrees: 90,
    );
  }
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
