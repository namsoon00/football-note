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
}
