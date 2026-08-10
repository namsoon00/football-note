import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_coaching_service.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';

void main() {
  test('multiple-person payload can never become a confirmed score', () {
    final result = _result(
      perspectiveQuality: const RunningVideoPerspectiveQuality(
        evaluatedFrameCount: 12,
        medianBodyScaleRatio: 0.6,
        minBodyScaleRatio: 0.55,
        visibilityCoverage: 0.9,
        sideViewScore: 0.9,
        scaleDriftRatio: 0.03,
        cutOffFrameRatio: 0,
        issues: <RunningVideoQualityIssue>[
          RunningVideoQualityIssue.multiplePerson,
        ],
      ),
    );

    final report = const RunningCoachingService().buildReport(result);

    expect(result.targetIdentityIssueReason, 'multiple_person');
    expect(report.scoreStatus, RunningCoachScoreStatus.unavailable);
    expect(report.overallScore, 0);
    expect(
      report.insights.every(
        (insight) => insight.quality.reason == 'multiple_person',
      ),
      isTrue,
    );
  });

  test('an extreme pose identity jump defensively withholds scoring', () {
    final result = _result(
      poseFrames: <RunningPoseFrame>[
        _poseFrame(const Duration(milliseconds: 100), centerX: 0.04),
        _poseFrame(const Duration(milliseconds: 250), centerX: 0.96),
      ],
    );

    final report = const RunningCoachingService().buildReport(result);

    expect(result.targetIdentityIssueReason, 'target_identity_unstable');
    expect(report.scoreStatus, RunningCoachScoreStatus.unavailable);
    expect(report.overallScore, 0);
  });
}

RunningVideoAnalysisResult _result({
  RunningVideoPerspectiveQuality perspectiveQuality =
      RunningVideoPerspectiveQuality.unevaluated,
  List<RunningPoseFrame> poseFrames = const <RunningPoseFrame>[],
}) {
  return RunningVideoAnalysisResult(
    videoDuration: const Duration(seconds: 5),
    sampledFrames: 16,
    validFrames: 15,
    direction: RunningDirection.leftToRight,
    forwardLeanDegrees: 9,
    verticalBounceRatio: 0.06,
    footStrikeDistanceRatio: 0.12,
    stanceKneeAngleDegrees: 150,
    elbowAngleDegrees: 90,
    metricQualities: const <RunningCoachMetric, RunningMetricQuality>{
      RunningCoachMetric.posture:
          RunningMetricQuality(confidence: 0.9, sampleCount: 10),
      RunningCoachMetric.bounce:
          RunningMetricQuality(confidence: 0.9, sampleCount: 10),
      RunningCoachMetric.footStrike:
          RunningMetricQuality(confidence: 0.9, sampleCount: 10),
      RunningCoachMetric.kneeFlexion:
          RunningMetricQuality(confidence: 0.9, sampleCount: 10),
      RunningCoachMetric.armCarriage:
          RunningMetricQuality(confidence: 0.9, sampleCount: 10),
    },
    poseFrames: poseFrames,
    perspectiveQuality: perspectiveQuality,
  );
}

RunningPoseFrame _poseFrame(Duration timestamp, {required double centerX}) {
  const indices = <int>[0, 11, 12, 23, 24, 25, 26, 27, 28];
  return RunningPoseFrame(
    timestamp: timestamp,
    imageWidth: 720,
    imageHeight: 1280,
    landmarks: <RunningVideoPoseLandmark>[
      for (var position = 0; position < indices.length; position += 1)
        RunningVideoPoseLandmark(
          index: indices[position],
          x: centerX + (position.isEven ? -0.025 : 0.025),
          y: 0.15 + position * 0.075,
          z: 0,
          visibility: 0.95,
          presence: 0.95,
          confidence: 0.95,
        ),
    ],
  );
}
