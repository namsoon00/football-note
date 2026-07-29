import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:football_note/application/running_coach_history_service.dart';
import 'package:football_note/application/running_coaching_service.dart';
import 'package:football_note/application/running_video_analysis_service.dart';
import 'package:football_note/domain/entities/running_coach_session.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/running_coach/running_foot_strike_target_motion_proof.dart';
import 'package:football_note/presentation/screens/running_coach_screen.dart';
import 'package:football_note/presentation/screens/running_coach_sample_video.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

const _samplePortraitVideoAssetForTest =
    'assets/videos/running_coach_portrait_side_view_sample.mp4';

void main() {
  late VideoPlayerPlatform previousVideoPlayerPlatform;

  test('target guide illustration assets are bundled', () async {
    const guideAssets = <String>[
      'assets/images/running_guides/capture_treadmill_side_reference.jpg',
      'assets/images/running_guides/capture_outdoor_side_reference.jpg',
      'assets/images/running_guides/target_posture.png',
      'assets/images/running_guides/target_landing.png',
      'assets/images/running_guides/professional_runner/'
          'professional_runner_pose_atlas_v2.png',
    ];

    for (final asset in guideAssets) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.lengthInBytes, greaterThan(100000));
    }
  });

  setUp(() {
    previousVideoPlayerPlatform = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = _FakeVideoPlayerPlatform();
  });

  tearDown(() {
    VideoPlayerPlatform.instance = previousVideoPlayerPlatform;
  });

  testWidgets('coach screen presents one recording and analysis flow', (
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
      find.byKey(const ValueKey('running-coach-primary-action-card')),
      findsOneWidget,
    );
    expect(find.text('Analyze a running video'), findsOneWidget);
    expect(find.text('Record now'), findsOneWidget);
    expect(find.text('Pick video'), findsOneWidget);
    expect(find.text('Live'), findsNothing);
    expect(find.text('Start live coaching'), findsNothing);
    expect(
      find.byKey(const ValueKey('running-coach-today-mission-card')),
      findsNothing,
    );
    expect(find.text("Today's speed mission"), findsNothing);
    expect(find.text('Open sample video guide'), findsOneWidget);
  });

  testWidgets('coach uses an in-app capture result in the video analysis flow',
      (
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
        home: RunningCoachScreen(
          optionRepository: _MemoryOptionRepository(),
          captureLauncher: (_) async => XFile(
            '/tmp/captured-running-video.mp4',
            name: 'captured-running-video.mp4',
          ),
        ),
      ),
    );

    expect(find.text('Record now'), findsOneWidget);
    await tester.tap(find.text('Record now'));
    await tester.pump();

    expect(find.text('captured-running-video.mp4'), findsOneWidget);
    expect(
      find.text('Analyze run'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-capture-primary-action')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('running-coach-capture-guide-action')),
      findsOneWidget,
    );
  });

  testWidgets(
      'foot strike rig refuses to fabricate a runner without coordinate data',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 760));
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
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: RunningFootStrikeEvidenceReferencePreview(
              evidence: ColoredBox(color: Colors.black),
              insight: RunningCoachingInsight(
                metric: RunningCoachMetric.footStrike,
                finding: RunningCoachFinding.footStrikeOverstride,
                status: RunningCoachStatus.needsWork,
                score: 34,
                value: 0.32,
              ),
              direction: RunningDirection.leftToRight,
              currentPose: null,
            ),
          ),
        ),
      ),
    );

    expect(
      find.text(
        'The 3D runner cannot be built from this frame. Try a clearer side-view clip with full-body landmarks.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-foot-strike-3d-runner')),
      findsNothing,
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
    expect(
      find.byKey(const ValueKey('running-coach-sample-video-frame')),
      findsOneWidget,
    );
    await tester.runAsync(() => analysisService.waitForCallCount(1));
    await tester.pump();
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('running-coach-sample-video-frame')),
    );

    expect(analysisService.calls, hasLength(1));
    expect(
      analysisService.calls,
      everyElement(contains('running_coach_sample_')),
    );
    expect(
      analysisService.calls,
      isNot(contains(_samplePortraitVideoAssetForTest)),
    );
    expect(analysisService.fileExistsAtCall, everyElement(isTrue));
    expect(analysisService.fileLengthAtCall, everyElement(greaterThan(0)));

    expect(
      find.byKey(const ValueKey('running-coach-sample-video-frame')),
      findsOneWidget,
    );
    final referenceVideo = await rootBundle.load(
      _samplePortraitVideoAssetForTest,
    );
    expect(referenceVideo.lengthInBytes, greaterThan(1000000));
    final sampleFrame = tester.getSize(
      find.byKey(const ValueKey('running-coach-sample-video-frame')),
    );
    expect(sampleFrame.height / sampleFrame.width, closeTo(16 / 9, 0.01));
    expect(
      find.byKey(const ValueKey('running-coach-sample-recording-guide')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-sample-real-pose-overlay')),
      findsNothing,
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
    expect(find.text('Portrait full-body side-view example'), findsWidgets);
    expect(find.text('Treadmill'), findsOneWidget);
    expect(find.text('Outdoor pass'), findsOneWidget);
    expect(find.text('Best setup for a treadmill'), findsOneWidget);
    await tester.ensureVisible(find.text('Outdoor pass'));
    await tester.pump();
    await tester.tap(find.text('Outdoor pass'));
    await tester.pump();
    expect(find.text('Fixed side-pass setup'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('running-coach-capture-reference-outdoor'),
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('How the analysis works'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('How the analysis works'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('running-coach-sample-frame-guide')),
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
    expect(analysisService.calls, hasLength(1));
  });

  testWidgets('sample video stays usable while native analysis is pending', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final analysisService = _PendingRunningVideoAnalysisService();
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

    await tester.ensureVisible(find.text('Open sample video guide'));
    await tester.pump();
    await tester.tap(find.text('Open sample video guide'));
    await tester.pump();
    await tester.runAsync(analysisService.waitUntilCalled);
    await tester.pump();

    expect(analysisService.callCount, 1);
    expect(
      find.byKey(const ValueKey('running-coach-sample-video-frame')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-sample-fake-video-view')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-sample-analysis-loading')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-sample-recording-guide')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    analysisService.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.byKey(const ValueKey('running-coach-sample-analysis-loading')),
      findsNothing,
    );
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
    await tester.runAsync(() => analysisService.waitForCallCount(1));
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

    final retryFinder =
        find.byKey(const ValueKey('running-coach-sample-analysis-retry'));
    await tester.ensureVisible(retryFinder);
    await tester.pumpAndSettle();
    await tester.tap(retryFinder);
    await tester.pump();
    await tester.runAsync(() => analysisService.waitForCallCount(2));
    await tester.pump();
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('running-coach-sample-video-frame')),
    );

    expect(analysisService.calls, hasLength(2));
    expect(find.text('Portrait full-body side-view example'), findsWidgets);
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
      metricSnapshots: const <RunningCoachSessionMetric>[
        RunningCoachSessionMetric(
          metric: RunningCoachMetric.posture,
          finding: RunningCoachFinding.postureTooUpright,
          status: RunningCoachStatus.watch,
          score: 70,
          value: 4,
          confidence: 0.86,
          sampleCount: 21,
        ),
        RunningCoachSessionMetric(
          metric: RunningCoachMetric.footStrike,
          finding: RunningCoachFinding.footStrikeOverstride,
          status: RunningCoachStatus.needsWork,
          score: 58,
          value: 0.24,
          confidence: 0.82,
          sampleCount: 8,
        ),
        RunningCoachSessionMetric(
          metric: RunningCoachMetric.armCarriage,
          finding: RunningCoachFinding.armTooOpen,
          status: RunningCoachStatus.watch,
          score: 68,
          value: 118,
          confidence: 0.79,
          sampleCount: 18,
        ),
      ],
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
    expect(find.text('Posture'), findsWidgets);

    await tester.tap(find.text('Posture').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Running analysis result'), findsOneWidget);
    expect(find.text('Next goal'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('running-coach-beginner-action-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-history-evidence-unavailable')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-report-details')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('running-coach-report-details')),
      -320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester
        .tap(find.byKey(const ValueKey('running-coach-report-details')));
    await tester.pump();
    expect(find.text('Foot strike'), findsWidgets);
    expect(find.text('Arm carriage'), findsWidgets);
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
    expect(
      find.byKey(const ValueKey('running-coach-beginner-action-card')),
      findsOneWidget,
    );
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
    expect(find.text('Next goal'), findsOneWidget);
    expect(
      find.text('For your next three runs, focus only on this.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-beginner-action-drill')),
      findsOneWidget,
    );
    final qualityDetails = find.byKey(
      const ValueKey('running-coach-analysis-quality-details'),
    );
    expect(find.text('Frames'), findsNothing);
    await _scrollAnalysisResultUntilFound(tester, qualityDetails);
    await tester.tap(qualityDetails);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Frames'), findsOneWidget);
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
      find.byKey(const ValueKey('running-coach-report-details')),
      -320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester
        .tap(find.byKey(const ValueKey('running-coach-report-details')));
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
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('running-coach-analysis-evidence-measurement'),
      ),
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
    expect(
      find.byKey(const ValueKey('running-coach-analysis-evidence-caption')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 100));
    final unavailablePlay = find.byKey(
      const ValueKey('running-coach-evidence-play-pause'),
    );
    expect(tester.widget<IconButton>(unavailablePlay).onPressed, isNull);
    expect(
      find.byKey(const ValueKey('running-coach-evidence-video-unavailable')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-evidence-details')),
      findsOneWidget,
    );
    expect(
      find.text(
        'The red guide marks only the body area used for this coaching call.',
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('running-coach-evidence-pose-transition')),
      findsOneWidget,
    );
    expect(find.text('Your frame and target movement'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('running-coach-goal-motion')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-goal-motion-toggle')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<IconButton>(
            find.descendant(
              of: find.byKey(
                const ValueKey('running-coach-goal-motion-toggle'),
              ),
              matching: find.byType(IconButton),
            ),
          )
          .tooltip,
      'Play goal movement',
    );
    final goalMotionToggle = find.byKey(
      const ValueKey('running-coach-goal-motion-toggle'),
    );
    await tester.ensureVisible(goalMotionToggle);
    await tester.pump();
    await tester.tap(goalMotionToggle);
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(
            find.descendant(
              of: find.byKey(
                const ValueKey('running-coach-goal-motion-toggle'),
              ),
              matching: find.byType(IconButton),
            ),
          )
          .tooltip,
      'Pause goal movement',
    );
    await tester.tap(goalMotionToggle);
    await tester.pump();
    expect(find.text('Current point'), findsOneWidget);
    expect(find.text('Target range'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('running-coach-goal-motion-coordinate-comparison'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('running-coach-coordinate-comparison-current-label'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('running-coach-coordinate-comparison-next-label'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('running-coach-goal-motion-professional-runner'),
      ),
      findsNothing,
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('running-coach-goal-motion')),
          )
          .height,
      272,
    );
    expect(find.text('Evidence 1/2'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final nextEvidence = find.byKey(
      const ValueKey('running-coach-evidence-next'),
    );
    await tester.ensureVisible(nextEvidence);
    await tester.pump();
    expect(tester.widget<IconButton>(nextEvidence).onPressed, isNotNull);
    await tester.tap(nextEvidence);
    await tester.pump();

    expect(find.text('Evidence 2/2'), findsOneWidget);
    final evidenceDetails = find.byKey(
      const ValueKey('running-coach-evidence-details'),
    );
    await tester.ensureVisible(evidenceDetails);
    await tester.tap(evidenceDetails);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('What I saw'), findsOneWidget);
    expect(
      find.text(
        'The red guide marks only the body area used for this coaching call.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('analysis result renders movement maps for every tracked metric',
      (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final metric in RunningCoachMetric.values) {
      final values = switch (metric) {
        RunningCoachMetric.posture => (
            forwardLean: 0.0,
            bounce: 0.06,
            footStrike: 0.08,
            knee: 155.0,
            elbow: 90.0,
          ),
        RunningCoachMetric.bounce => (
            forwardLean: 10.0,
            bounce: 0.16,
            footStrike: 0.08,
            knee: 155.0,
            elbow: 90.0,
          ),
        RunningCoachMetric.footStrike => (
            forwardLean: 10.0,
            bounce: 0.06,
            footStrike: 0.40,
            knee: 155.0,
            elbow: 90.0,
          ),
        RunningCoachMetric.kneeFlexion => (
            forwardLean: 10.0,
            bounce: 0.06,
            footStrike: 0.08,
            knee: 180.0,
            elbow: 90.0,
          ),
        RunningCoachMetric.armCarriage => (
            forwardLean: 10.0,
            bounce: 0.06,
            footStrike: 0.08,
            knee: 155.0,
            elbow: 170.0,
          ),
      };
      final result = RunningVideoAnalysisResult(
        videoDuration: const Duration(seconds: 4),
        sampledFrames: 14,
        validFrames: 13,
        direction: RunningDirection.leftToRight,
        forwardLeanDegrees: values.forwardLean,
        verticalBounceRatio: values.bounce,
        footStrikeDistanceRatio: values.footStrike,
        stanceKneeAngleDegrees: values.knee,
        elbowAngleDegrees: values.elbow,
        metricQualities: const <RunningCoachMetric, RunningMetricQuality>{
          RunningCoachMetric.posture: RunningMetricQuality(
            confidence: 0.90,
            sampleCount: 8,
          ),
          RunningCoachMetric.bounce: RunningMetricQuality(
            confidence: 0.90,
            sampleCount: 8,
          ),
          RunningCoachMetric.footStrike: RunningMetricQuality(
            confidence: 0.90,
            sampleCount: 8,
          ),
          RunningCoachMetric.kneeFlexion: RunningMetricQuality(
            confidence: 0.90,
            sampleCount: 8,
          ),
          RunningCoachMetric.armCarriage: RunningMetricQuality(
            confidence: 0.90,
            sampleCount: 8,
          ),
        },
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
        contactConfidence: 0.88,
        poseFrames: _testPoseFrames(
          startX: 0.22,
          dxPerFrame: 0.04,
          confidence: 0.94,
        ),
      );
      final report = const RunningCoachingService().buildReport(result);
      expect(report.primaryFocus!.metric, metric);
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey('movement-map-preview-${metric.name}'),
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
              id: '${metric.name}-movement-map',
              result: result,
              report: report,
            ),
          ),
        ),
      );
      await tester.pump();
      final goalMotion = find.byKey(
        const ValueKey('running-coach-goal-motion'),
      );
      expect(goalMotion, findsOneWidget);
      expect(tester.getSize(goalMotion).height, 272);
      if (metric == RunningCoachMetric.posture) {
        final reportDetails = find.byKey(
          const ValueKey('running-coach-report-details'),
        );
        await _scrollAnalysisResultUntilFound(tester, reportDetails);
        await tester.tap(reportDetails);
        await tester.pump();
        final detailComparison = find.byKey(
          const ValueKey('running-coach-insight-evidence-diagram-posture'),
        );
        await _scrollAnalysisResultUntilFound(tester, detailComparison);
        expect(detailComparison, findsOneWidget);
        expect(
          find.byKey(
            const ValueKey(
              'running-coach-insight-coordinate-comparison-posture',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'running-coach-insight-goal-motion-toggle-posture',
            ),
          ),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    }
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
    final qualityDetails = find.byKey(
      const ValueKey('running-coach-analysis-quality-details'),
    );
    await _scrollAnalysisResultUntilFound(tester, qualityDetails);
    await tester.tap(qualityDetails);
    await tester.pump(const Duration(milliseconds: 250));
    final limitedEvidenceNotice = find.byKey(
      const ValueKey('running-coach-lower-body-evidence-limited'),
    );
    await _scrollAnalysisResultUntilFound(tester, limitedEvidenceNotice);
    expect(limitedEvidenceNotice, findsOneWidget);
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

Future<void> _scrollAnalysisResultUntilFound(
  WidgetTester tester,
  Finder finder,
) async {
  final resultList = find.byKey(
    const ValueKey('running-coach-analysis-result-list'),
  );
  for (var attempt = 0; attempt < 12; attempt += 1) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.drag(resultList, const Offset(0, -420));
    await tester.pump(const Duration(milliseconds: 80));
  }
  expect(finder, findsOneWidget);
}

Future<RunningCoachPreparedSampleVideo> _prepareSampleVideoForTest(
  String assetPath,
) async {
  final tempDirectory = Directory.systemTemp.createTempSync(
    'running_coach_sample_test_',
  );
  final file = File('${tempDirectory.path}/${assetPath.split('/').last}');
  file.writeAsBytesSync(assetPath.codeUnits, flush: true);
  return RunningCoachPreparedSampleVideo(
    file: XFile(file.path, name: file.uri.pathSegments.last),
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
  Future<RunningVideoAnalysisResult> analyzeVideo(XFile video) async {
    final path = video.path;
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

class _PendingRunningVideoAnalysisService extends RunningVideoAnalysisService {
  final Completer<RunningVideoAnalysisResult> _result =
      Completer<RunningVideoAnalysisResult>();
  int callCount = 0;

  @override
  Future<RunningVideoAnalysisResult> analyzeVideo(XFile video) {
    callCount += 1;
    return _result.future;
  }

  Future<void> waitUntilCalled() async {
    for (var attempt = 0; attempt < 100; attempt += 1) {
      if (callCount > 0) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw StateError('Timed out waiting for sample analysis.');
  }

  void complete() {
    _result.complete(
      const RunningVideoAnalysisResult(
        videoDuration: Duration(seconds: 4),
        sampledFrames: 14,
        validFrames: 13,
        direction: RunningDirection.leftToRight,
        forwardLeanDegrees: 12.4,
        verticalBounceRatio: 0.07,
        footStrikeDistanceRatio: 0.11,
        stanceKneeAngleDegrees: 150,
        elbowAngleDegrees: 96,
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
