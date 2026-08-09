import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_coaching_service.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';

void main() {
  const service = RunningCoachingService();

  test('balanced running form produces strong coaching scores', () {
    const result = RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 6),
      sampledFrames: 14,
      validFrames: 14,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 9.2,
      verticalBounceRatio: 0.058,
      footStrikeDistanceRatio: 0.09,
      stanceKneeAngleDegrees: 154,
      elbowAngleDegrees: 92,
    );

    final report = service.buildReport(result);

    expect(report.overallScore, greaterThanOrEqualTo(85));
    expect(report.insights.length, 5);
    expect(
      report.insights.every((item) => item.status == RunningCoachStatus.good),
      isTrue,
    );
  });

  test(
    'upright posture, high bounce, and overstride lower coaching scores',
    () {
      const result = RunningVideoAnalysisResult(
        videoDuration: Duration(seconds: 6),
        sampledFrames: 14,
        validFrames: 10,
        direction: RunningDirection.leftToRight,
        forwardLeanDegrees: 3.8,
        verticalBounceRatio: 0.108,
        footStrikeDistanceRatio: 0.23,
        stanceKneeAngleDegrees: 174,
        elbowAngleDegrees: 132,
      );

      final report = service.buildReport(result);

      expect(report.overallScore, lessThan(70));
      expect(report.insights[0].finding, RunningCoachFinding.postureTooUpright);
      expect(report.insights[1].finding, RunningCoachFinding.bounceTooHigh);
      expect(
        report.insights[2].finding,
        RunningCoachFinding.footStrikeOverstride,
      );
      expect(report.insights[3].finding, RunningCoachFinding.kneeTooStraight);
      expect(report.insights[4].finding, RunningCoachFinding.armTooOpen);
    },
  );

  test('focus priorities rank the lowest non-good scores first', () {
    const result = RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 6),
      sampledFrames: 14,
      validFrames: 10,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 3.8,
      verticalBounceRatio: 0.108,
      footStrikeDistanceRatio: 0.23,
      stanceKneeAngleDegrees: 174,
      elbowAngleDegrees: 132,
    );

    final report = service.buildReport(result);

    expect(
      report.focusInsights.map((item) => item.metric),
      orderedEquals([
        RunningCoachMetric.armCarriage,
        RunningCoachMetric.bounce,
        RunningCoachMetric.posture,
        RunningCoachMetric.footStrike,
        RunningCoachMetric.kneeFlexion,
      ]),
    );
    expect(report.focusPriorityByMetric[RunningCoachMetric.armCarriage], 1);
    expect(report.focusPriorityByMetric[RunningCoachMetric.kneeFlexion], 5);
    expect(
      report.focusPriorityByMetric.containsKey(RunningCoachMetric.posture),
      isTrue,
    );
  });

  test('withholds a primary coaching goal when every metric is low quality',
      () {
    const result = RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 4),
      sampledFrames: 14,
      validFrames: 5,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 11,
      verticalBounceRatio: 0.11,
      footStrikeDistanceRatio: 0.12,
      stanceKneeAngleDegrees: 156,
      elbowAngleDegrees: 90,
    );

    final report = service.buildReport(result);
    expect(report.primaryFocus, isNull);
    expect(report.overallScore, 0);
    expect(report.focusPriorityByMetric, isEmpty);
    expect(
      report.insights.every((insight) => insight.quality.sampleCount == 5),
      isTrue,
    );
  });

  test('withholds all coaching when fresh metric qualities lack video frames',
      () {
    const result = RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 6),
      sampledFrames: 14,
      validFrames: 14,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 3.8,
      verticalBounceRatio: 0.058,
      footStrikeDistanceRatio: 0.28,
      stanceKneeAngleDegrees: 174,
      elbowAngleDegrees: 92,
      metricQualities: <RunningCoachMetric, RunningMetricQuality>{
        RunningCoachMetric.posture: RunningMetricQuality(
          confidence: 0.88,
          sampleCount: 14,
        ),
        RunningCoachMetric.bounce: RunningMetricQuality(
          confidence: 0.88,
          sampleCount: 14,
        ),
        RunningCoachMetric.footStrike: RunningMetricQuality(
          confidence: 0.42,
          sampleCount: 2,
          reason: 'contact_phase_proxy',
        ),
        RunningCoachMetric.kneeFlexion: RunningMetricQuality(
          confidence: 0.42,
          sampleCount: 2,
          reason: 'contact_phase_proxy',
        ),
        RunningCoachMetric.armCarriage: RunningMetricQuality(
          confidence: 0.88,
          sampleCount: 14,
        ),
      },
    );

    final report = service.buildReport(result);

    expect(report.primaryFocus, isNull);
    expect(report.overallScore, 0);
    expect(
      report.insights.every(
        (insight) => !insight.quality.isReliableForCoaching,
      ),
      isTrue,
    );
  });

  test('perspective gates preserve exact lower-body limitation reasons', () {
    const result = RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 60),
      sampledFrames: 481,
      validFrames: 430,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 10,
      verticalBounceRatio: 0.06,
      footStrikeDistanceRatio: 0.20,
      stanceKneeAngleDegrees: 170,
      elbowAngleDegrees: 92,
      perspectiveQuality: RunningVideoPerspectiveQuality(
        evaluatedFrameCount: 430,
        medianBodyScaleRatio: 0.22,
        minBodyScaleRatio: 0.20,
        visibilityCoverage: 0.9,
        sideViewScore: 0.42,
        scaleDriftRatio: 1.05,
        cutOffFrameRatio: 0.02,
        issues: <RunningVideoQualityIssue>[
          RunningVideoQualityIssue.notSideOn,
        ],
      ),
      metricQualities: <RunningCoachMetric, RunningMetricQuality>{
        RunningCoachMetric.posture: RunningMetricQuality(
          confidence: 0.9,
          sampleCount: 10,
        ),
        RunningCoachMetric.bounce: RunningMetricQuality(
          confidence: 0.9,
          sampleCount: 10,
        ),
        RunningCoachMetric.footStrike: RunningMetricQuality(
          confidence: 0.9,
          sampleCount: 6,
        ),
        RunningCoachMetric.kneeFlexion: RunningMetricQuality(
          confidence: 0.9,
          sampleCount: 6,
        ),
        RunningCoachMetric.armCarriage: RunningMetricQuality(
          confidence: 0.9,
          sampleCount: 10,
        ),
      },
    );

    final report = service.buildReport(result);
    final footStrike = report.insights.firstWhere(
      (insight) => insight.metric == RunningCoachMetric.footStrike,
    );
    final knee = report.insights.firstWhere(
      (insight) => insight.metric == RunningCoachMetric.kneeFlexion,
    );

    expect(report.overallScore, 0);
    expect(footStrike.quality.confidence, closeTo(0.55, 0.0001));
    expect(footStrike.quality.reason, 'not_side_on');
    expect(knee.quality.confidence, closeTo(0.55, 0.0001));
    expect(knee.quality.reason, 'not_side_on');
  });

  test('excludes low-confidence contact proxies from score and next goal', () {
    const result = RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 6),
      sampledFrames: 14,
      validFrames: 14,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 10,
      verticalBounceRatio: 0.06,
      footStrikeDistanceRatio: 0.5,
      stanceKneeAngleDegrees: 180,
      elbowAngleDegrees: 90,
      metricQualities: <RunningCoachMetric, RunningMetricQuality>{
        RunningCoachMetric.posture: RunningMetricQuality(
          confidence: 0.88,
          sampleCount: 14,
        ),
        RunningCoachMetric.bounce: RunningMetricQuality(
          confidence: 0.88,
          sampleCount: 14,
        ),
        RunningCoachMetric.footStrike: RunningMetricQuality(
          confidence: 0.42,
          sampleCount: 2,
          reason: 'contact_phase_proxy',
        ),
        RunningCoachMetric.kneeFlexion: RunningMetricQuality(
          confidence: 0.42,
          sampleCount: 2,
          reason: 'contact_phase_proxy',
        ),
        RunningCoachMetric.armCarriage: RunningMetricQuality(
          confidence: 0.88,
          sampleCount: 14,
        ),
      },
    );

    final report = service.buildReport(result);

    expect(report.overallScore, 0);
    expect(report.primaryFocus, isNull);
    expect(report.focusPriorityByMetric[RunningCoachMetric.footStrike], isNull);
    expect(
        report.focusPriorityByMetric[RunningCoachMetric.kneeFlexion], isNull);
  });

  test('requires paired contact evidence before lower-body coaching', () {
    final result = RunningVideoAnalysisResult(
      videoDuration: const Duration(seconds: 4),
      sampledFrames: 14,
      validFrames: 12,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 10,
      verticalBounceRatio: 0.06,
      footStrikeDistanceRatio: 0.36,
      stanceKneeAngleDegrees: 175,
      elbowAngleDegrees: 92,
      metricQualities: const <RunningCoachMetric, RunningMetricQuality>{
        RunningCoachMetric.footStrike: RunningMetricQuality(
          confidence: 0.92,
          sampleCount: 3,
        ),
        RunningCoachMetric.kneeFlexion: RunningMetricQuality(
          confidence: 0.92,
          sampleCount: 3,
        ),
      },
      poseFrames: <RunningPoseFrame>[_frameForEvidenceGate()],
    );

    final report = service.buildReport(result);
    final footStrike = report.insights.firstWhere(
      (insight) => insight.metric == RunningCoachMetric.footStrike,
    );
    final knee = report.insights.firstWhere(
      (insight) => insight.metric == RunningCoachMetric.kneeFlexion,
    );

    expect(footStrike.quality.reason, 'missing_contact_evidence');
    expect(knee.quality.reason, 'missing_contact_evidence');
    expect(footStrike.quality.isReliableForCoaching, isFalse);
    expect(knee.quality.isReliableForCoaching, isFalse);
    expect(report.overallScore, 0);
  });

  test('custom thresholds can tune the coaching report', () {
    const tunedService = RunningCoachingService(
      thresholds: RunningCoachingThresholds(maximumFootStrikeRatio: 0.12),
    );
    const result = RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 6),
      sampledFrames: 14,
      validFrames: 14,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 9.2,
      verticalBounceRatio: 0.058,
      footStrikeDistanceRatio: 0.13,
      stanceKneeAngleDegrees: 154,
      elbowAngleDegrees: 92,
    );

    final report = tunedService.buildReport(result);

    expect(
      report.insights[2].finding,
      RunningCoachFinding.footStrikeOverstride,
    );
  });

  test('keeps an in-range value on watch when it is far from target center',
      () {
    const result = RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 6),
      sampledFrames: 14,
      validFrames: 14,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 6.1,
      verticalBounceRatio: 0.058,
      footStrikeDistanceRatio: 0.09,
      stanceKneeAngleDegrees: 154,
      elbowAngleDegrees: 92,
    );

    final report = service.buildReport(result);

    expect(report.insights.first.finding, RunningCoachFinding.postureAligned);
    expect(report.insights.first.status, RunningCoachStatus.watch);
  });
}

RunningPoseFrame _frameForEvidenceGate() {
  return RunningPoseFrame(
    timestamp: Duration.zero,
    imageWidth: 720,
    imageHeight: 1280,
    landmarks: List<RunningVideoPoseLandmark>.unmodifiable(
      List<RunningVideoPoseLandmark>.generate(
        mediaPipePoseLandmarkCount,
        (index) => RunningVideoPoseLandmark(
          index: index,
          x: 0.5,
          y: 0.5,
          z: 0,
          visibility: 0.95,
          presence: 0.95,
          confidence: 0.95,
        ),
      ),
    ),
  );
}
