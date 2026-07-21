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
import 'package:football_note/domain/entities/sprint_realtime_coaching_state.dart';
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

  testWidgets('mission exposes one unified live sprint coach action', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
        home: RunningCoachScreen(optionRepository: _MemoryOptionRepository()),
      ),
    );

    expect(find.text('Start live sprint coach'), findsOneWidget);
    expect(find.text('Before live capture'), findsOneWidget);
    expect(
      find.textContaining('whole body including both feet'),
      findsOneWidget,
    );
    expect(find.text('Check form live'), findsNothing);
    expect(
      find.widgetWithText(FilledButton, 'Start live sprint coach'),
      findsOneWidget,
    );
  });

  testWidgets('coach home explains when live trend needs more stable sessions',
      (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final optionRepository = _MemoryOptionRepository();
    final session = RunningCoachSessionAnalysis(
      id: 'live-trend-start',
      analyzedAt: DateTime(2026, 7, 21, 10),
      source: RunningCoachSessionSource.sprintLive,
      overallScore: 76,
      duration: const Duration(seconds: 14),
      sampledFrames: 180,
      validFrames: 160,
      primaryMetric: RunningCoachMetric.footStrike,
      primaryFinding: RunningCoachFinding.footStrikeOverstride,
      primaryStatus: RunningCoachStatus.watch,
      primaryScore: 72,
      primaryValue: 0.2,
      primaryConfidence: 0.84,
      liveSprintReport: const LiveSprintSessionReport(
        runningTrackedFrames: 160,
        runningAnalyzedFrames: 180,
        sprintTrackedFrames: 60,
        sprintAnalyzedFrames: 60,
        touchdownEvents: 8,
        toeOffEvents: 8,
        detectedSteps: 8,
        landingEvents: 6,
        feedbackChanges: 2,
        timingConfidence: 0.86,
        sideViewConfidence: 0.84,
        sprintTrackingConfidence: 0.82,
        bodyNotVisibleRatio: 0.08,
        status: SprintCoachingStatus.coaching,
        trackingReadiness: SprintTrackingReadiness.readyForAnalysis,
        feedbackCode: null,
        feedbackSeverity: null,
        feedbackConfidence: 0,
        metrics: <LiveSprintMetricSummary>[
          LiveSprintMetricSummary(
            kind: LiveSprintMetricKind.trunkAngle,
            value: 12,
            confidence: 0.86,
            sampleCount: 10,
          ),
        ],
      ),
    );
    await optionRepository.setValue(
      RunningCoachHistoryService.storageKey,
      jsonEncode(<Map<String, Object?>>[session.toMap()]),
    );
    expect(RunningCoachHistoryService(optionRepository).allSessions(),
        hasLength(1));

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

    expect(
      find.byKey(const ValueKey('running-coach-live-trend-card')),
      findsOneWidget,
    );
    expect(find.text('Sprint progress'), findsOneWidget);
    expect(
      find.text('Record 2 more stable sessions to establish a trend.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
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
      find.byKey(const ValueKey('running-coach-sample-real-pose-overlay')),
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
    expect(find.text('Example A'), findsOneWidget);
    expect(find.text('Example B'), findsOneWidget);
    expect(find.text('Reference sample'), findsNothing);
    expect(find.text('Wrong form sample'), findsNothing);
    expect(
      find.textContaining('not a controlled correct-vs-wrong comparison'),
      findsOneWidget,
    );
    expect(find.text('What the overlay shows'), findsOneWidget);
    expect(find.text('Example A readouts'), findsOneWidget);
    expect(find.text('Analysis process on the real clip'), findsOneWidget);
    expect(find.text('Dense contact evidence'), findsOneWidget);
    expect(find.text('Validate contact frame'), findsOneWidget);
    expect(find.text('Contact 0.00s'), findsOneWidget);
    expect(find.text('0.00s, 0.50s'), findsOneWidget);
    expect(find.text('Contact frames'), findsOneWidget);
    expect(find.textContaining('Find body points'), findsOneWidget);
    expect(find.textContaining('Mark body load'), findsOneWidget);
    expect(find.textContaining('Connect body lines'), findsOneWidget);
    expect(find.textContaining('Measure angles'), findsOneWidget);
    expect(find.textContaining('Check contact evidence'), findsOneWidget);
    expect(find.text('Decision evidence'), findsOneWidget);
    expect(find.text('Forward lean'), findsWidgets);
    expect(find.text('Bounce'), findsOneWidget);
    expect(find.text('Landing 0.08'), findsNothing);
    expect(find.text('Lean 10°'), findsNothing);
    expect(find.text('Arms 90°'), findsNothing);
    expect(find.text('Bounce 6%'), findsNothing);
    expect(find.text('12.4° body lean'), findsWidgets);
    expect(find.text('0.11x foot reach'), findsWidgets);
    expect(find.text('7.0% up-down motion'), findsWidgets);
    expect(find.text('Good'), findsWidgets);
    expect(
      find.text('Foot lands under the hip with toes forward'),
      findsOneWidget,
    );
    expect(find.textContaining('landing distance is 0.08'), findsNothing);

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
    expect(find.text('12.4° body lean'), findsWidgets);
    expect(find.textContaining("this clip's measured value"), findsWidgets);
    expect(find.textContaining('vertical hip line'), findsWidgets);

    Navigator.of(
      tester.element(
        find.byKey(const ValueKey('running-coach-sample-metric-detail')),
      ),
    ).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Example B'));
    await tester.pump();
    await tester.tap(find.text('Example B'));
    await tester.pump();

    expect(find.text('Example B readouts'), findsOneWidget);
    expect(find.text('0.22x foot reach'), findsWidgets);
    expect(find.text('Bounce'), findsOneWidget);
    expect(find.text('10.0% up-down motion'), findsWidgets);
    expect(find.text('Needs work'), findsWidgets);
    expect(
      find.textContaining('landing is 0.20 ahead of the hip'),
      findsNothing,
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
    expect(find.text('10.0% up-down motion'), findsWidgets);
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

  testWidgets('sample sheet does not draw a fake skeleton without poseFrames', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final analysisService = _FakeRunningVideoAnalysisService(
      omitPoseFrames: true,
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
    await tester.runAsync(() => analysisService.waitForCallCount(2));
    await tester.pump();
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('running-coach-sample-video-frame')),
    );
    await tester.binding.setSurfaceSize(const Size(360, 780));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('running-coach-sample-real-pose-overlay')),
      findsNothing,
    );
    expect(find.text('No pose frames'), findsOneWidget);
    expect(find.text('12.4° body lean'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sample sheet shows localized error and retries native analysis',
      (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final analysisService = _FakeRunningVideoAnalysisService(
      failFirstCall: true,
      failureCode: 'video_too_blurry',
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
        'This video is too blurry for a precise result. Keep the phone still and record a clearer side view with your whole body and both feet visible.',
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
    expect(find.text('Example A'), findsOneWidget);
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

    expect(find.text('Coaching analysis history'), findsOneWidget);
    expect(find.text('All 1'), findsOneWidget);
    expect(find.text('Video saved'), findsOneWidget);

    await tester.tap(find.text('All 1'));
    await tester.pumpAndSettle();

    expect(find.text('Coaching analysis history'), findsWidgets);
    expect(
        find.text(
            'Review each uploaded video and live sprint session with its key coaching focus and correction guide.'),
        findsWidgets);
    expect(find.text('Posture'), findsWidgets);
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.tap(find.text('Posture').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Analysis review'), findsOneWidget);
    expect(find.text('Analyzed video'), findsOneWidget);
    expect(find.text('side-view-test.mp4'), findsOneWidget);
    expect(find.text('Correction point in pictures'), findsOneWidget);
    expect(
      find.text('Goal: slight forward lean, without bending at the waist'),
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
      coarseSamples: RunningAnalysisSampleSummary(
        attemptedFrames: 14,
        validFrames: 12,
        poseFrameCount: 12,
      ),
      denseSamples: RunningAnalysisSampleSummary(
        attemptedFrames: 18,
        validFrames: 16,
        poseFrameCount: 16,
        maxFrameBudget: 48,
        targetFps: 30,
      ),
      contactWindows: <RunningContactWindow>[
        RunningContactWindow(
          start: Duration(milliseconds: 900),
          center: Duration(milliseconds: 1030),
          end: Duration(milliseconds: 1190),
          side: RunningContactSide.right,
          denseSampleCount: 9,
          validatedContactTimestamps: <Duration>[
            Duration(milliseconds: 1033),
          ],
          confidence: 0.88,
        ),
        RunningContactWindow(
          start: Duration(milliseconds: 1400),
          center: Duration(milliseconds: 1560),
          end: Duration(milliseconds: 1740),
          side: RunningContactSide.left,
          denseSampleCount: 9,
          validatedContactTimestamps: <Duration>[
            Duration(milliseconds: 1560),
          ],
          confidence: 0.86,
        ),
      ],
      validatedContactFrameTimestamps: <Duration>[
        Duration(milliseconds: 1033),
        Duration(milliseconds: 1560),
      ],
      contactConfidence: 0.88,
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
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('running-coach-dense-contact-evidence')),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey('running-coach-dense-contact-evidence')),
      findsOneWidget,
    );

    for (var scrollStep = 0; scrollStep < 8; scrollStep += 1) {
      await tester.drag(
        find.byType(Scrollable).first,
        const Offset(0, -520),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('analysis guide uses beginner copy at 320px portrait', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const result = RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 5),
      sampledFrames: 18,
      validFrames: 16,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 12,
      verticalBounceRatio: 0.07,
      footStrikeDistanceRatio: 0.25,
      stanceKneeAngleDegrees: 152,
      elbowAngleDegrees: 92,
      metricQualities: <RunningCoachMetric, RunningMetricQuality>{
        RunningCoachMetric.posture: RunningMetricQuality(
          confidence: 1,
          sampleCount: 16,
        ),
        RunningCoachMetric.bounce: RunningMetricQuality(
          confidence: 1,
          sampleCount: 16,
        ),
        RunningCoachMetric.footStrike: RunningMetricQuality(
          confidence: 1,
          sampleCount: 16,
        ),
        RunningCoachMetric.kneeFlexion: RunningMetricQuality(
          confidence: 1,
          sampleCount: 16,
        ),
        RunningCoachMetric.armCarriage: RunningMetricQuality(
          confidence: 1,
          sampleCount: 16,
        ),
      },
    );
    final report = const RunningCoachingService().buildReport(result);
    final primary = report.primaryFocus!;
    final session = RunningCoachSessionAnalysis(
      id: 'beginner-copy-320',
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
        home: runningAnalysisResultScreenForTesting(
          result: result,
          report: report,
          session: session,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('running-coach-beginner-action-card')),
      findsOneWidget,
    );
    expect(find.text('Change one thing first'), findsOneWidget);
    expect(find.text('On your next run'), findsOneWidget);

    final guideVisual = find.byKey(
      const ValueKey('running-coach-insight-guide-visual-footStrike'),
    );
    for (var step = 0; step < 12 && guideVisual.evaluate().isEmpty; step++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -360));
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(
      guideVisual,
      findsOneWidget,
    );
    expect(find.text('Put the foot down closer under the hips.'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('analysis result localizes dense contact timestamp units', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const result = RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 4),
      sampledFrames: 14,
      validFrames: 12,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 10,
      verticalBounceRatio: 0.07,
      footStrikeDistanceRatio: 0.12,
      stanceKneeAngleDegrees: 150,
      elbowAngleDegrees: 96,
      metricQualities: <RunningCoachMetric, RunningMetricQuality>{
        RunningCoachMetric.footStrike: RunningMetricQuality(
          confidence: 0.84,
          sampleCount: 2,
        ),
        RunningCoachMetric.kneeFlexion: RunningMetricQuality(
          confidence: 0.84,
          sampleCount: 2,
        ),
      },
      coarseSamples: RunningAnalysisSampleSummary(
        attemptedFrames: 14,
        validFrames: 12,
        poseFrameCount: 6,
      ),
      denseSamples: RunningAnalysisSampleSummary(
        attemptedFrames: 8,
        validFrames: 6,
        poseFrameCount: 6,
        maxFrameBudget: 48,
        targetFps: 30,
      ),
      contactWindows: <RunningContactWindow>[
        RunningContactWindow(
          start: Duration.zero,
          center: Duration.zero,
          end: Duration(milliseconds: 180),
          side: RunningContactSide.right,
          denseSampleCount: 4,
          validatedContactTimestamps: <Duration>[Duration.zero],
          confidence: 0.82,
        ),
        RunningContactWindow(
          start: Duration(milliseconds: 320),
          center: Duration(milliseconds: 500),
          end: Duration(milliseconds: 680),
          side: RunningContactSide.left,
          denseSampleCount: 4,
          validatedContactTimestamps: <Duration>[Duration(milliseconds: 500)],
          confidence: 0.86,
        ),
      ],
      validatedContactFrameTimestamps: <Duration>[
        Duration.zero,
        Duration(milliseconds: 500),
      ],
      contactConfidence: 0.84,
    );
    final report = const RunningCoachingService().buildReport(result);
    final primary = report.primaryFocus!;
    final session = RunningCoachSessionAnalysis(
      id: 'localized-contact-times',
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
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
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

    await tester.scrollUntilVisible(
      find.text('0.00초, 0.50초'),
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('0.00초, 0.50초'), findsOneWidget);
  });

  testWidgets('analysis result shows navigable evidence at 320px portrait', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final result = RunningVideoAnalysisResult(
      videoDuration: const Duration(seconds: 4),
      sampledFrames: 14,
      validFrames: 13,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 10,
      verticalBounceRatio: 0.06,
      footStrikeDistanceRatio: 0.24,
      stanceKneeAngleDegrees: 155,
      elbowAngleDegrees: 92,
      metricQualities: _testDenseMetricQualities(),
      coarseSamples: const RunningAnalysisSampleSummary(
        attemptedFrames: 14,
        validFrames: 13,
        poseFrameCount: 6,
      ),
      denseSamples: const RunningAnalysisSampleSummary(
        attemptedFrames: 8,
        validFrames: 6,
        poseFrameCount: 6,
        maxFrameBudget: 48,
        targetFps: 30,
      ),
      contactWindows: _testContactWindows(),
      validatedContactFrameTimestamps: _testContactTimestamps(),
      contactConfidence: 0.84,
      poseFrames: _testPoseFrames(
        startX: 0.34,
        dxPerFrame: -0.018,
        confidence: 0.93,
        imageWidth: 720,
        imageHeight: 1280,
      ),
    );
    final report = const RunningCoachingService().buildReport(result);

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
          session: _sessionForReport(
            id: 'portrait-evidence',
            result: result,
            report: report,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('running-coach-analysis-evidence-card')),
      findsOneWidget,
    );
    expect(find.text('Evidence from your video'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('running-coach-analysis-evidence-overlay')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey('running-coach-analysis-evidence-preview'),
            ),
          )
          .height,
      lessThanOrEqualTo(320),
    );
    expect(find.text('Evidence 1/2'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final nextEvidence = find.byKey(
      const ValueKey('running-coach-evidence-next'),
    );
    await tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, -260),
    );
    await tester.pump();
    expect(tester.widget<IconButton>(nextEvidence).onPressed, isNotNull);
    await tester.tap(nextEvidence);
    await tester.pump();

    expect(find.text('Evidence 2/2'), findsOneWidget);
    expect(find.text('What I saw'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('analysis result recommends retake and hides low-evidence score',
      (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final result = RunningVideoAnalysisResult(
      videoDuration: const Duration(seconds: 4),
      sampledFrames: 14,
      validFrames: 12,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 10,
      verticalBounceRatio: 0.06,
      footStrikeDistanceRatio: 0.35,
      stanceKneeAngleDegrees: 155,
      elbowAngleDegrees: 92,
      metricQualities: const <RunningCoachMetric, RunningMetricQuality>{
        RunningCoachMetric.footStrike: RunningMetricQuality(
          confidence: 0.42,
          sampleCount: 1,
          reason: 'limited_samples',
        ),
        RunningCoachMetric.kneeFlexion: RunningMetricQuality(
          confidence: 0.84,
          sampleCount: 2,
        ),
      },
      coarseSamples: const RunningAnalysisSampleSummary(
        attemptedFrames: 14,
        validFrames: 12,
        poseFrameCount: 6,
      ),
      denseSamples: RunningAnalysisSampleSummary.empty,
      contactConfidence: 0,
      poseFrames: _testPoseFrames(
        startX: 0.32,
        dxPerFrame: -0.012,
        confidence: 0.5,
      ),
    );
    final report = const RunningCoachingService().buildReport(result);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: runningAnalysisResultScreenForTesting(
          result: result,
          report: report,
          session: _sessionForReport(
            id: 'limited-evidence',
            result: result,
            report: report,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('running-coach-analysis-evidence-retake')),
      findsOneWidget,
    );
    expect(find.text('Retake this clip'), findsOneWidget);
    expect(find.text('Evidence limited'), findsWidgets);
    expect(find.textContaining('Metric score 14'), findsNothing);
    expect(
      find.byKey(const ValueKey('running-coach-analysis-evidence-overlay')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
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

RunningCoachSessionAnalysis _sessionForReport({
  required String id,
  required RunningVideoAnalysisResult result,
  required RunningCoachingReport report,
}) {
  final primary = report.primaryFocus!;
  return RunningCoachSessionAnalysis(
    id: id,
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
  );
}

class _FakeRunningVideoAnalysisService extends RunningVideoAnalysisService {
  final bool failFirstCall;
  final bool omitPoseFrames;
  final String failureCode;
  final List<String> calls = <String>[];
  final List<bool> fileExistsAtCall = <bool>[];
  final List<int> fileLengthAtCall = <int>[];

  _FakeRunningVideoAnalysisService({
    this.failFirstCall = false,
    this.omitPoseFrames = false,
    this.failureCode = 'no_pose_detected',
  });

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
      throw RunningVideoAnalysisException(
        failureCode,
        'No pose detected in fixture.',
      );
    }
    if (path.endsWith('running_coach_mistake_sample.mp4')) {
      return RunningVideoAnalysisResult(
        videoDuration: const Duration(seconds: 4),
        sampledFrames: 14,
        validFrames: 12,
        direction: RunningDirection.leftToRight,
        forwardLeanDegrees: 4,
        verticalBounceRatio: 0.10,
        footStrikeDistanceRatio: 0.22,
        stanceKneeAngleDegrees: 172,
        elbowAngleDegrees: 126,
        metricQualities: _testDenseMetricQualities(),
        coarseSamples: const RunningAnalysisSampleSummary(
          attemptedFrames: 14,
          validFrames: 12,
          poseFrameCount: 6,
        ),
        denseSamples: omitPoseFrames
            ? RunningAnalysisSampleSummary.empty
            : const RunningAnalysisSampleSummary(
                attemptedFrames: 8,
                validFrames: 6,
                poseFrameCount: 6,
                maxFrameBudget: 48,
                targetFps: 30,
              ),
        contactWindows: omitPoseFrames
            ? const <RunningContactWindow>[]
            : _testContactWindows(),
        validatedContactFrameTimestamps:
            omitPoseFrames ? const <Duration>[] : _testContactTimestamps(),
        contactConfidence: omitPoseFrames ? 0 : 0.82,
        poseFrames: omitPoseFrames
            ? const <RunningPoseFrame>[]
            : _testPoseFrames(
                startX: 0.22,
                dxPerFrame: 0.055,
                confidence: 0.88,
              ),
      );
    }
    return RunningVideoAnalysisResult(
      videoDuration: const Duration(seconds: 4),
      sampledFrames: 14,
      validFrames: 13,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 12.4,
      verticalBounceRatio: 0.07,
      footStrikeDistanceRatio: 0.11,
      stanceKneeAngleDegrees: 150,
      elbowAngleDegrees: 96,
      metricQualities: _testDenseMetricQualities(),
      coarseSamples: const RunningAnalysisSampleSummary(
        attemptedFrames: 14,
        validFrames: 13,
        poseFrameCount: 6,
      ),
      denseSamples: omitPoseFrames
          ? RunningAnalysisSampleSummary.empty
          : const RunningAnalysisSampleSummary(
              attemptedFrames: 8,
              validFrames: 6,
              poseFrameCount: 6,
              maxFrameBudget: 48,
              targetFps: 30,
            ),
      contactWindows: omitPoseFrames
          ? const <RunningContactWindow>[]
          : _testContactWindows(),
      validatedContactFrameTimestamps:
          omitPoseFrames ? const <Duration>[] : _testContactTimestamps(),
      contactConfidence: omitPoseFrames ? 0 : 0.84,
      poseFrames: omitPoseFrames
          ? const <RunningPoseFrame>[]
          : _testPoseFrames(
              startX: 0.34,
              dxPerFrame: -0.018,
              confidence: 0.93,
            ),
    );
  }
}

Map<RunningCoachMetric, RunningMetricQuality> _testDenseMetricQualities() {
  return const <RunningCoachMetric, RunningMetricQuality>{
    RunningCoachMetric.footStrike: RunningMetricQuality(
      confidence: 0.84,
      sampleCount: 2,
    ),
    RunningCoachMetric.kneeFlexion: RunningMetricQuality(
      confidence: 0.84,
      sampleCount: 2,
    ),
  };
}

List<Duration> _testContactTimestamps() {
  return const <Duration>[
    Duration.zero,
    Duration(milliseconds: 500),
  ];
}

List<RunningContactWindow> _testContactWindows() {
  return const <RunningContactWindow>[
    RunningContactWindow(
      start: Duration.zero,
      center: Duration.zero,
      end: Duration(milliseconds: 180),
      side: RunningContactSide.right,
      denseSampleCount: 4,
      validatedContactTimestamps: <Duration>[Duration.zero],
      confidence: 0.82,
    ),
    RunningContactWindow(
      start: Duration(milliseconds: 320),
      center: Duration(milliseconds: 500),
      end: Duration(milliseconds: 680),
      side: RunningContactSide.left,
      denseSampleCount: 4,
      validatedContactTimestamps: <Duration>[Duration(milliseconds: 500)],
      confidence: 0.86,
    ),
  ];
}

List<RunningPoseFrame> _testPoseFrames({
  required double startX,
  required double dxPerFrame,
  required double confidence,
  int imageWidth = 1280,
  int imageHeight = 720,
}) {
  return List<RunningPoseFrame>.unmodifiable([
    for (var frameIndex = 0; frameIndex < 6; frameIndex += 1)
      RunningPoseFrame(
        timestamp: Duration(milliseconds: frameIndex * 500),
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        landmarks: List<RunningVideoPoseLandmark>.unmodifiable([
          for (var index = 0; index < mediaPipePoseLandmarkCount; index += 1)
            _testPoseLandmark(
              index,
              baseX: startX + (frameIndex * dxPerFrame),
              confidence: confidence,
            ),
        ]),
      ),
  ]);
}

RunningVideoPoseLandmark _testPoseLandmark(
  int index, {
  required double baseX,
  required double confidence,
}) {
  final bodyY = switch (index) {
    0 => 0.22,
    >= 1 && <= 10 => 0.24,
    11 || 12 => 0.38,
    13 || 14 => 0.48,
    15 || 16 => 0.58,
    >= 17 && <= 22 => 0.61,
    23 || 24 => 0.58,
    25 || 26 => 0.72,
    27 || 28 => 0.86,
    29 || 30 => 0.89,
    _ => 0.91,
  };
  final sideOffset = switch (index) {
    11 || 13 || 15 || 17 || 19 || 21 || 23 || 25 || 27 || 29 || 31 => -0.04,
    12 || 14 || 16 || 18 || 20 || 22 || 24 || 26 || 28 || 30 || 32 => 0.04,
    _ => 0.0,
  };
  return RunningVideoPoseLandmark(
    index: index,
    x: (baseX + sideOffset).clamp(0.05, 0.95).toDouble(),
    y: bodyY,
    z: -0.01 * index,
    visibility: confidence,
    presence: confidence,
    confidence: confidence,
  );
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
