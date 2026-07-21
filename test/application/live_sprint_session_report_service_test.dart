import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/live_sprint_session_report_service.dart';
import 'package:football_note/application/running_coach_history_service.dart';
import 'package:football_note/application/running_live_session_metrics.dart';
import 'package:football_note/application/sprint_live_session_metrics.dart';
import 'package:football_note/domain/entities/running_coach_session.dart';
import 'package:football_note/domain/entities/running_live_coaching_state.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/domain/entities/sprint_capture_calibration_profile.dart';
import 'package:football_note/domain/entities/sprint_realtime_coaching_state.dart';
import 'package:football_note/domain/repositories/option_repository.dart';

void main() {
  const fixture = _LiveSessionFixture();

  test('builds one detailed report from unified live session signals', () {
    final session = const LiveSprintSessionReportService().buildSession(
      sessionId: fixture.sessionId,
      completedAt: fixture.completedAt,
      runningSnapshot: fixture.runningSnapshot,
      sprintSnapshot: fixture.sprintSnapshot,
      runningState: fixture.runningState,
      sprintState: fixture.sprintState,
      calibrationProfile: SprintCaptureCalibrationProfile.responsive,
      poseEvidence: fixture.poseEvidence,
      poseEvidenceDiagnostic: fixture.poseEvidenceDiagnostic,
    );

    expect(session.id, fixture.sessionId);
    expect(session.source, RunningCoachSessionSource.sprintLive);
    expect(session.overallScore, 74);
    expect(session.duration, const Duration(seconds: 12));
    expect(session.insights, hasLength(2));
    expect(session.primaryMetric, RunningCoachMetric.footStrike);

    final report = session.liveSprintReport!;
    expect(
        report.calibrationProfile, SprintCaptureCalibrationProfile.responsive);
    expect(report.runningAnalyzedFrames, 180);
    expect(report.sprintAnalyzedFrames, 72);
    expect(report.detectedSteps, 8);
    expect(report.feedbackCode, SprintFeedbackCode.landUnderHips);
    expect(
        report.poseEvidence.single.phase, LiveSprintPoseEvidencePhase.flight);
    expect(
      report.poseEvidenceDiagnostic.dominantBlocker,
      LiveSprintPoseEvidenceBlocker.stableSideView,
    );
    expect(report.analysisConfidence, closeTo(0.8, 0.0001));
    expect(
      report.metricFor(LiveSprintMetricKind.cadence)!.value,
      closeTo(218, 0.0001),
    );
    expect(
      report.metricFor(LiveSprintMetricKind.landing)!.secondaryValue,
      closeTo(69, 0.0001),
    );

    final restored = RunningCoachSessionAnalysis.fromMap(session.toMap());
    expect(restored.insights, hasLength(2));
    expect(restored.liveSprintReport!.detectedSteps, 8);
    expect(
      restored.liveSprintReport!.calibrationProfile,
      SprintCaptureCalibrationProfile.responsive,
    );
    expect(
      restored.liveSprintReport!.poseEvidence.single.quality,
      closeTo(0.84, 0.0001),
    );
    expect(
      restored.liveSprintReport!.poseEvidenceDiagnostic.sideViewBlockedFrames,
      12,
    );
    expect(
      restored.liveSprintReport!.metricFor(LiveSprintMetricKind.rhythm)!.value,
      closeTo(13, 0.0001),
    );
  });

  test('persists a live sprint report in the shared coaching history',
      () async {
    final repository = _MemoryOptionRepository();
    final history = RunningCoachHistoryService(repository);

    final saved = await history.saveLiveSprintSession(
      sessionId: fixture.sessionId,
      completedAt: fixture.completedAt,
      runningSnapshot: fixture.runningSnapshot,
      sprintSnapshot: fixture.sprintSnapshot,
      runningState: fixture.runningState,
      sprintState: fixture.sprintState,
      calibrationProfile: SprintCaptureCalibrationProfile.conservative,
      poseEvidence: fixture.poseEvidence,
      poseEvidenceDiagnostic: fixture.poseEvidenceDiagnostic,
    );

    expect(saved, hasLength(1));
    expect(saved.single.liveSprintReport, isNotNull);
    expect(saved.single.metricSnapshots, hasLength(2));

    final restored = history.allSessions();
    expect(restored, hasLength(1));
    expect(restored.single.source, RunningCoachSessionSource.sprintLive);
    expect(restored.single.liveSprintReport!.feedbackChanges, 4);
    expect(
      restored.single.liveSprintReport!.calibrationProfile,
      SprintCaptureCalibrationProfile.conservative,
    );
    expect(
      restored.single.liveSprintReport!.poseEvidence.single.phase,
      LiveSprintPoseEvidencePhase.flight,
    );
    expect(
      restored.single.liveSprintReport!.poseEvidenceDiagnostic.currentBlocker,
      LiveSprintPoseEvidenceBlocker.stableSideView,
    );
    expect(
      restored.single.liveSprintReport!
          .metricFor(LiveSprintMetricKind.kneeDrive)!
          .value,
      closeTo(0.42, 0.0001),
    );
  });

  test('loads legacy live sprint sessions without calibration metadata', () {
    final session = const LiveSprintSessionReportService()
        .buildSession(
          sessionId: fixture.sessionId,
          completedAt: fixture.completedAt,
          runningSnapshot: fixture.runningSnapshot,
          sprintSnapshot: fixture.sprintSnapshot,
          runningState: fixture.runningState,
          sprintState: fixture.sprintState,
        )
        .toMap();
    final report = session['liveSprintReport']! as Map<String, Object?>;
    report.remove('calibrationProfile');
    report.remove('poseEvidenceDiagnostic');

    final restored = RunningCoachSessionAnalysis.fromMap(session);

    expect(
      restored.liveSprintReport!.calibrationProfile,
      SprintCaptureCalibrationProfile.balanced,
    );
    expect(
      restored.liveSprintReport!.poseEvidenceDiagnostic.readinessSummary,
      isA<LiveSprintCaptureReadinessSummary>(),
    );
  });
}

class _LiveSessionFixture {
  static final DateTime _completedAt = DateTime(2026, 7, 21, 10, 30);

  const _LiveSessionFixture();

  String get sessionId => 'live-sprint-1784597400000000';

  DateTime get completedAt => _completedAt;

  List<LiveSprintPoseEvidenceFrame> get poseEvidence =>
      const <LiveSprintPoseEvidenceFrame>[
        LiveSprintPoseEvidenceFrame(
          phase: LiveSprintPoseEvidencePhase.flight,
          capturedOffsetMs: 1800,
          quality: 0.84,
          sideViewConfidence: 0.8,
          imageAspectRatio: 0.5625,
          leadFoot: null,
          joints: <LiveSprintPoseEvidenceJoint>[
            LiveSprintPoseEvidenceJoint(
              type: RunningPoseLandmarkType.leftHip,
              x: 0.42,
              y: 0.5,
              z: 0.1,
              confidence: 0.9,
              observed: true,
            ),
          ],
        ),
      ];

  LiveSprintPoseEvidenceDiagnostic get poseEvidenceDiagnostic =>
      const LiveSprintPoseEvidenceDiagnostic(
        evaluatedFrames: 30,
        eligibleFrames: 18,
        capturedPhaseCount: 1,
        fullBodyBlockedFrames: 3,
        sideViewBlockedFrames: 12,
        coreJointsBlockedFrames: 1,
        gaitPhaseBlockedFrames: 2,
        currentBlocker: LiveSprintPoseEvidenceBlocker.stableSideView,
      );

  RunningLiveSessionMetricsSnapshot get runningSnapshot =>
      const RunningLiveSessionMetricsSnapshot(
        elapsed: Duration(seconds: 12),
        cameraInputFrames: 240,
        analyzedFrames: 180,
        skippedFrames: 60,
        busySkippedFrames: 8,
        throttledSkippedFrames: 50,
        invalidInputFrames: 1,
        analysisErrorFrames: 1,
        cameraInputFps: 20,
        analyzedFps: 15,
        analyzedFrameIntervalSampleCount: 120,
        analyzedFrameIntervalP50Ms: 66,
        analyzedFrameIntervalP95Ms: 88,
        processingLatencySampleCount: 180,
        averageProcessingLatencyMs: 28,
        processingLatencyP50Ms: 26,
        processingLatencyP95Ms: 44,
        averageTimingConfidence: 0.84,
        averageSideViewConfidence: 0.79,
        cadenceAvailableFrames: 100,
        cadenceUnavailableFrames: 80,
        leftContactAvailableFrames: 92,
        leftContactUnavailableFrames: 88,
        rightContactAvailableFrames: 90,
        rightContactUnavailableFrames: 90,
        touchdownEvents: 8,
        toeOffEvents: 8,
        eventTimeline: <RunningLiveGaitEventLogEntry>[],
      );

  SprintLiveSessionMetricsSnapshot get sprintSnapshot =>
      const SprintLiveSessionMetricsSnapshot(
        elapsed: Duration(seconds: 12),
        cameraInputFrames: 240,
        analyzedFrames: 72,
        skippedFrames: 168,
        busySkippedFrames: 8,
        throttledSkippedFrames: 158,
        invalidInputFrames: 1,
        analysisErrorFrames: 1,
        bodyNotVisibleCount: 6,
        feedbackChangeCount: 4,
        feedbackSuppressedByCooldownCount: 5,
        cameraInputFps: 20,
        analyzedFps: 6,
        averageProcessingTimeMs: 28,
        bodyNotVisibleRatio: 0.0833,
        feedbackChangesPerMinute: 20,
        confidenceBucketCounts: <int>[0, 1, 3, 10, 40],
      );

  RunningLiveCoachingState get runningState => const RunningLiveCoachingState(
        primaryCue: RunningLivePrimaryCue.footStrikeOverstride,
        coachingReport: RunningCoachingReport(
          overallScore: 74,
          insights: <RunningCoachingInsight>[
            RunningCoachingInsight(
              metric: RunningCoachMetric.footStrike,
              finding: RunningCoachFinding.footStrikeOverstride,
              status: RunningCoachStatus.needsWork,
              score: 58,
              value: 0.24,
              quality: RunningMetricQuality(confidence: 0.82, sampleCount: 18),
            ),
            RunningCoachingInsight(
              metric: RunningCoachMetric.posture,
              finding: RunningCoachFinding.postureAligned,
              status: RunningCoachStatus.good,
              score: 88,
              value: 12.0,
              quality: RunningMetricQuality(confidence: 0.87, sampleCount: 20),
            ),
          ],
        ),
        highlightedInsight: RunningCoachingInsight(
          metric: RunningCoachMetric.footStrike,
          finding: RunningCoachFinding.footStrikeOverstride,
          status: RunningCoachStatus.needsWork,
          score: 58,
          value: 0.24,
          quality: RunningMetricQuality(confidence: 0.82, sampleCount: 18),
        ),
        gaitAnalysis: RunningGaitAnalysis(
          currentPhase: RunningGaitPhase.flight,
          phaseConfidence: 0.9,
          cadence: RunningGaitMetric.available(
            value: 172,
            confidence: 0.82,
            sampleCount: 8,
          ),
          leftContactDuration: RunningGaitMetric.available(
            value: 220,
            confidence: 0.8,
            sampleCount: 4,
          ),
          rightContactDuration: RunningGaitMetric.available(
            value: 218,
            confidence: 0.8,
            sampleCount: 4,
          ),
          recentEvents: <RunningGaitEvent>[],
          touchdownCount: 8,
          toeOffCount: 8,
          validFrameCount: 180,
          timingConfidence: 0.84,
          sideViewConfidence: 0.79,
        ),
        trackedFrames: 160,
      );

  SprintRealtimeCoachingState get sprintState =>
      const SprintRealtimeCoachingState(
        status: SprintCoachingStatus.coaching,
        features: SprintFeatureSnapshot(
          trunkAngle: SprintMeasuredValue.available(
            value: 12.4,
            confidence: 0.88,
            sampleCount: 18,
          ),
          kneeDrive: SprintMeasuredValue.available(
            value: 0.42,
            confidence: 0.84,
            sampleCount: 18,
          ),
          cadence: SprintMeasuredValue.available(
            value: 218,
            confidence: 0.86,
            sampleCount: 8,
          ),
          rhythm: SprintMeasuredValue.available(
            value: 13,
            confidence: 0.8,
            sampleCount: 8,
          ),
          armBalance: SprintMeasuredValue.available(
            value: 0.08,
            confidence: 0.78,
            sampleCount: 18,
          ),
          overstride: SprintMeasuredValue.available(
            value: 0.21,
            confidence: 0.82,
            sampleCount: 6,
          ),
          shinAngle: SprintMeasuredValue.available(
            value: 69,
            confidence: 0.8,
            sampleCount: 6,
          ),
          flightRatio: SprintMeasuredValue.available(
            value: 0.28,
            confidence: 0.74,
            sampleCount: 12,
          ),
          lateFormDrop: SprintMeasuredValue.available(
            value: 0.04,
            confidence: 0.7,
            sampleCount: 10,
          ),
          detectedStepEvents: 8,
          landingEventCount: 6,
        ),
        stateEstimate: SprintStateEstimate(
          runningDetected: true,
          accelerationPhaseDetected: true,
          feedbackCooldownActive: false,
          lowConfidence: false,
          bodyFullyVisible: true,
          bodyVisibilityStatus: SprintBodyVisibilityStatus.full,
          trackingReadiness: SprintTrackingReadiness.readyForAnalysis,
          trackingConfidence: 0.77,
          stableFrameCount: 18,
          visibleLandmarkCount: 33,
          visibleCoreLandmarkCount: 11,
          missingCoreLandmarkCount: 0,
          bodyVisibilityRatio: 1,
          hipTravelRatio: 0.12,
          personHeightRatio: 0.65,
          personAreaRatio: 0.25,
          averageLandmarkConfidence: 0.86,
          sideViewConfidence: 0.8,
          personBounds: Rect.fromLTRB(240, 90, 760, 910),
          suggestedCropRect: Rect.fromLTRB(200, 60, 800, 940),
        ),
        feedback: SprintFeedbackMessage(
          code: SprintFeedbackCode.landUnderHips,
          priority: 90,
          cueKey: 'runningCoachSprintCueLandUnderHips',
          diagnosisKey: 'runningCoachSprintDiagnosisLandUnderHips',
          actionTipKey: 'runningCoachSprintActionLandUnderHips',
          severity: SprintFeedbackSeverity.warning,
          confidence: 0.83,
          sourceFeatures: <String>['overstride'],
          cooldownKey: 'land_under_hips',
          debugLabel: 'Land under hips',
        ),
        processedFrames: 72,
        trackedFrames: 60,
      );
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> values = <String, dynamic>{};

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    return List<int>.from(defaults);
  }

  @override
  List<String> getOptions(String key, List<String> defaults) {
    return List<String>.from(defaults);
  }

  @override
  T? getValue<T>(String key) => values[key] as T?;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    values[key] = value;
  }
}
