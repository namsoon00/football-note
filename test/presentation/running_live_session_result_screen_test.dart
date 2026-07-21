import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/live_sprint_calibration_readiness_service.dart';
import 'package:football_note/application/live_sprint_calibration_candidate_service.dart';
import 'package:football_note/application/live_sprint_field_validation_matrix_service.dart';
import 'package:football_note/application/live_sprint_trend_service.dart';
import 'package:football_note/domain/entities/running_coach_session.dart';
import 'package:football_note/domain/entities/running_live_coaching_state.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/domain/entities/sprint_capture_calibration_profile.dart';
import 'package:football_note/domain/entities/sprint_realtime_coaching_state.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/running_live_session_result_screen.dart';

void main() {
  testWidgets('shows one readable report for running and sprint outcomes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _LocalizedHarness(
        child: RunningLiveSessionResultScreen(session: _session()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Live sprint report'), findsOneWidget);
    expect(find.text('Saved to coaching history'), findsOneWidget);
    expect(
      find.byKey(
          const ValueKey('running-live-session-report-field-validation')),
      findsOneWidget,
    );
    expect(find.text('Field validation'), findsOneWidget);
    expect(find.text('Ready for calibration'), findsOneWidget);
    expect(find.text('Profile: Balanced'), findsOneWidget);
    await _scrollReportUntilVisible(
      tester,
      find.byKey(
        const ValueKey(
          'running-live-session-report-calibration-readiness',
        ),
      ),
    );
    expect(
      find.byKey(
        const ValueKey(
          'running-live-session-report-calibration-readiness',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Calibration repeatability'), findsOneWidget);
    expect(find.text('Need more same-profile sessions'), findsOneWidget);
    expect(find.text('Ready 1/3'), findsOneWidget);
    await _scrollReportUntilVisible(
      tester,
      find.byKey(const ValueKey('running-live-session-report-focus')),
    );
    expect(
      find.byKey(const ValueKey('running-live-session-report-focus')),
      findsOneWidget,
    );
    expect(find.text('Next focus'), findsOneWidget);
    await _scrollReportUntilVisible(
      tester,
      find.text('Joint-tracking evidence'),
    );
    expect(
      find.byKey(const ValueKey('running-live-session-report-pose-evidence')),
      findsOneWidget,
    );
    expect(find.text('Joint-tracking evidence'), findsOneWidget);
    expect(find.text('Touchdown'), findsWidgets);
    await _scrollReportUntilVisible(tester, find.text('Sprint mechanics'));
    expect(find.text('Sprint mechanics'), findsWidgets);

    await _scrollReportUntilVisible(tester, find.text('Analysis quality'));
    expect(find.text('Analysis quality'), findsOneWidget);
    await _scrollReportUntilVisible(tester, find.text('Gait events'));
    expect(find.text('Gait events'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('explains when the session did not stabilize enough to score', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final session = RunningCoachSessionAnalysis(
      id: 'live-short',
      analyzedAt: DateTime(2026, 7, 21, 10),
      source: RunningCoachSessionSource.sprintLive,
      overallScore: 0,
      duration: const Duration(seconds: 2),
      sampledFrames: 10,
      validFrames: 3,
      primaryMetric: RunningCoachMetric.posture,
      primaryFinding: RunningCoachFinding.postureAligned,
      primaryStatus: RunningCoachStatus.watch,
      primaryScore: 0,
      primaryValue: 0,
      primaryConfidence: 0,
      liveSprintReport: const LiveSprintSessionReport(
        runningTrackedFrames: 3,
        runningAnalyzedFrames: 10,
        sprintTrackedFrames: 0,
        sprintAnalyzedFrames: 0,
        touchdownEvents: 0,
        toeOffEvents: 0,
        detectedSteps: 0,
        landingEvents: 0,
        feedbackChanges: 0,
        timingConfidence: 0.2,
        sideViewConfidence: 0.2,
        sprintTrackingConfidence: 0.2,
        bodyNotVisibleRatio: 0.7,
        status: SprintCoachingStatus.lowConfidence,
        trackingReadiness: SprintTrackingReadiness.bodyTooSmall,
        feedbackCode: null,
        feedbackSeverity: null,
        feedbackConfidence: 0,
        metrics: <LiveSprintMetricSummary>[],
        poseEvidenceDiagnostic: LiveSprintPoseEvidenceDiagnostic(
          evaluatedFrames: 18,
          eligibleFrames: 0,
          capturedPhaseCount: 0,
          fullBodyBlockedFrames: 12,
          sideViewBlockedFrames: 2,
          coreJointsBlockedFrames: 2,
          gaitPhaseBlockedFrames: 2,
          currentBlocker: LiveSprintPoseEvidenceBlocker.fullBodyVisibility,
        ),
      ),
    );

    await tester.pumpWidget(
      _LocalizedHarness(
        child: RunningLiveSessionResultScreen(
          session: session,
          isPersisted: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Form score unavailable'), findsOneWidget);
    await _scrollReportUntilVisible(
      tester,
      find.text(
        'Main capture limit: Step back until your head and both feet stay in frame.',
      ),
    );
    expect(find.text('Touchdown: not captured'), findsOneWidget);
    await _scrollReportUntilVisible(
      tester,
      find.text(
        'There was not enough stable signal to summarize sprint mechanics. Keep the same framing for a few more steps, then finish again.',
      ),
    );
    expect(
      find.text(
        'There was not enough stable signal to summarize sprint mechanics. Keep the same framing for a few more steps, then finish again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Saved to coaching history'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows calibration repeatability ready state at narrow width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final current = _session(
      id: 'current',
      analyzedAt: DateTime(2026, 7, 21, 10, 30),
    );
    final summary = const LiveSprintCalibrationReadinessService().build(
      <RunningCoachSessionAnalysis>[
        current,
        _session(
          id: 'baseline-2',
          analyzedAt: DateTime(2026, 7, 20, 10, 30),
        ),
        _session(
          id: 'baseline-1',
          analyzedAt: DateTime(2026, 7, 19, 10, 30),
        ),
      ],
      currentSessionId: 'current',
    );

    await tester.pumpWidget(
      _LocalizedHarness(
        child: RunningLiveSessionResultScreen(
          session: current,
          calibrationReadinessSummary: summary,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollReportUntilVisible(
      tester,
      find.text('Ready for threshold calibration'),
    );
    expect(
      find.byKey(
        const ValueKey(
          'running-live-session-report-calibration-readiness',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Calibration repeatability'), findsOneWidget);
    expect(find.text('Ready for threshold calibration'), findsOneWidget);
    expect(find.text('Ready 3/3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows calibration matrix and candidate cards at 320px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final current = _session(
      id: 'current',
      analyzedAt: DateTime(2026, 7, 21, 10, 30),
      captureContext: _context(
        distanceBand: LiveSprintCaptureDistanceBand.close,
      ),
    );
    final sessions = <RunningCoachSessionAnalysis>[
      current,
      _session(
        id: 'baseline',
        analyzedAt: DateTime(2026, 7, 20, 10, 30),
        captureContext: _context(),
      ),
      _session(
        id: 'far',
        analyzedAt: DateTime(2026, 7, 19, 10, 30),
        captureContext: _context(
          distanceBand: LiveSprintCaptureDistanceBand.far,
        ),
      ),
    ];

    await tester.pumpWidget(
      _LocalizedHarness(
        child: RunningLiveSessionResultScreen(
          session: current,
          calibrationReadinessSummary:
              const LiveSprintCalibrationReadinessService().build(
            sessions,
            currentSessionId: 'current',
          ),
          fieldValidationMatrixSummary:
              const LiveSprintFieldValidationMatrixService().build(
            sessions,
            currentSessionId: 'current',
          ),
          calibrationCandidateSummary:
              const LiveSprintCalibrationCandidateService().build(
            sessions,
            currentSessionId: 'current',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollReportUntilVisible(
      tester,
      find.text('Field coverage matrix'),
    );
    expect(find.text('Field coverage matrix'), findsOneWidget);
    expect(find.text('Ready for recommendation coverage'), findsOneWidget);
    await _scrollReportUntilVisible(
      tester,
      find.text('Calibration recommendation'),
    );
    expect(find.text('Calibration recommendation'), findsOneWidget);
    expect(find.text('Safe recommendation only'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows confidence-gated progress in the live report', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _LocalizedHarness(
        child: RunningLiveSessionResultScreen(
          session: _session(),
          trendSummary: const LiveSprintTrendSummary(
            status: LiveSprintTrendStatus.ready,
            currentSession: null,
            liveSessionCount: 3,
            comparableSessionCount: 3,
            baselineSessionCount: 2,
            requiredComparableSessions: 3,
            metricTrends: <LiveSprintMetricTrend>[
              LiveSprintMetricTrend(
                kind: LiveSprintMetricKind.trunkAngle,
                currentValue: 10,
                baselineValue: 6,
                baselineSessionCount: 2,
                confidence: 0.85,
                currentTargetGap: 0,
                baselineTargetGap: 2,
                signal: LiveSprintTrendSignal.improved,
              ),
              LiveSprintMetricTrend(
                kind: LiveSprintMetricKind.landing,
                currentValue: 0.44,
                baselineValue: 0.38,
                baselineSessionCount: 2,
                confidence: 0.84,
                currentTargetGap: 0.08,
                baselineTargetGap: 0.02,
                signal: LiveSprintTrendSignal.needsAttention,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollReportUntilVisible(tester, find.text('Sprint progress'));
    expect(
      find.byKey(const ValueKey('running-live-session-report-trend')),
      findsOneWidget,
    );
    expect(find.text('Sprint progress'), findsOneWidget);
    expect(find.text('Improving'), findsOneWidget);
    expect(find.text('Needs attention'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

RunningCoachSessionAnalysis _session({
  String id = 'live-report',
  DateTime? analyzedAt,
  SprintCaptureCalibrationProfile profile =
      SprintCaptureCalibrationProfile.balanced,
  LiveSprintCaptureContext captureContext =
      const LiveSprintCaptureContext.unknown(),
}) {
  return RunningCoachSessionAnalysis(
    id: id,
    analyzedAt: analyzedAt ?? DateTime(2026, 7, 21, 10, 30),
    source: RunningCoachSessionSource.sprintLive,
    overallScore: 76,
    duration: const Duration(seconds: 18),
    sampledFrames: 200,
    validFrames: 176,
    primaryMetric: RunningCoachMetric.footStrike,
    primaryFinding: RunningCoachFinding.footStrikeOverstride,
    primaryStatus: RunningCoachStatus.needsWork,
    primaryScore: 58,
    primaryValue: 0.23,
    primaryConfidence: 0.82,
    metricSnapshots: const <RunningCoachSessionMetric>[
      RunningCoachSessionMetric(
        metric: RunningCoachMetric.footStrike,
        finding: RunningCoachFinding.footStrikeOverstride,
        status: RunningCoachStatus.needsWork,
        score: 58,
        value: 0.23,
        confidence: 0.82,
        sampleCount: 20,
      ),
      RunningCoachSessionMetric(
        metric: RunningCoachMetric.posture,
        finding: RunningCoachFinding.postureAligned,
        status: RunningCoachStatus.good,
        score: 87,
        value: 12,
        confidence: 0.88,
        sampleCount: 20,
      ),
    ],
    liveSprintReport: LiveSprintSessionReport(
      calibrationProfile: profile,
      runningTrackedFrames: 176,
      runningAnalyzedFrames: 200,
      sprintTrackedFrames: 72,
      sprintAnalyzedFrames: 72,
      touchdownEvents: 8,
      toeOffEvents: 8,
      detectedSteps: 8,
      landingEvents: 6,
      feedbackChanges: 3,
      timingConfidence: 0.85,
      sideViewConfidence: 0.8,
      sprintTrackingConfidence: 0.82,
      bodyNotVisibleRatio: 0.05,
      status: SprintCoachingStatus.coaching,
      trackingReadiness: SprintTrackingReadiness.readyForAnalysis,
      feedbackCode: SprintFeedbackCode.landUnderHips,
      feedbackSeverity: SprintFeedbackSeverity.warning,
      feedbackConfidence: 0.84,
      metrics: <LiveSprintMetricSummary>[
        const LiveSprintMetricSummary(
          kind: LiveSprintMetricKind.cadence,
          value: 218,
          confidence: 0.84,
          sampleCount: 8,
        ),
        const LiveSprintMetricSummary(
          kind: LiveSprintMetricKind.landing,
          value: 0.22,
          secondaryValue: 68,
          confidence: 0.82,
          sampleCount: 6,
        ),
        const LiveSprintMetricSummary(
          kind: LiveSprintMetricKind.trunkAngle,
          value: 12.4,
          confidence: 0.8,
          sampleCount: 12,
        ),
      ],
      poseEvidence: _poseEvidence(),
      poseEvidenceDiagnostic: const LiveSprintPoseEvidenceDiagnostic(
        evaluatedFrames: 36,
        eligibleFrames: 18,
        capturedPhaseCount: 3,
        fullBodyBlockedFrames: 0,
        sideViewBlockedFrames: 0,
        coreJointsBlockedFrames: 0,
        gaitPhaseBlockedFrames: 0,
        currentBlocker: null,
        readinessSummary: LiveSprintCaptureReadinessSummary(
          framing: LiveSprintCaptureReadinessCheck(
            ready: true,
            value: 1,
            threshold: 1,
          ),
          sideView: LiveSprintCaptureReadinessCheck(
            ready: true,
            value: 0.82,
            threshold: 0.65,
          ),
          coreJointConfidence: LiveSprintCaptureReadinessCheck(
            ready: true,
            value: 0.84,
            threshold: 0.70,
            observedCount: 15,
            requiredCount: 15,
          ),
          gaitPhase: LiveSprintCaptureReadinessCheck(
            ready: true,
            value: 0.82,
            threshold: 0.62,
          ),
        ),
      ),
      captureContext: captureContext,
    ),
  );
}

LiveSprintCaptureContext _context({
  LiveSprintCaptureDistanceBand distanceBand =
      LiveSprintCaptureDistanceBand.normal,
  LiveSprintViewBand viewBand = LiveSprintViewBand.clearSide,
}) {
  return LiveSprintCaptureContext(
    deviceClass: LiveSprintDeviceClass.phone,
    cameraLensDirection: LiveSprintCameraLensDirection.rear,
    distanceBand: distanceBand,
    viewBand: viewBand,
  );
}

List<LiveSprintPoseEvidenceFrame> _poseEvidence() {
  return <LiveSprintPoseEvidenceFrame>[
    for (final phase in LiveSprintPoseEvidencePhase.values)
      LiveSprintPoseEvidenceFrame(
        phase: phase,
        capturedOffsetMs: 2400 + (phase.index * 220),
        quality: 0.88,
        sideViewConfidence: 0.84,
        imageAspectRatio: 0.5625,
        leadFoot: phase == LiveSprintPoseEvidencePhase.touchdown
            ? RunningFootSide.left
            : null,
        joints: <LiveSprintPoseEvidenceJoint>[
          for (final type in RunningPoseLandmarkType.values)
            LiveSprintPoseEvidenceJoint(
              type: type,
              x: 0.2 + ((type.index % 5) * 0.12),
              y: 0.1 + ((type.index ~/ 5) * 0.16),
              z: type.index / 100,
              confidence: 0.9,
              observed: true,
            ),
        ],
      ),
  ];
}

class _LocalizedHarness extends StatelessWidget {
  final Widget child;

  const _LocalizedHarness({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}

Future<void> _scrollReportUntilVisible(
  WidgetTester tester,
  Finder target,
) async {
  await tester.scrollUntilVisible(
    target,
    320,
    scrollable: find.descendant(
      of: find.byKey(const ValueKey('running-live-session-report-list')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
