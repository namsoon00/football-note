import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_coaching_service.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';

void main() {
  const service = RunningCoachingService();

  test('balanced running form produces strong coaching scores', () {
    const result = RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 6),
      sampledFrames: 12,
      validFrames: 12,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 8.2,
      verticalBounceRatio: 0.064,
      strideReachRatio: 0.29,
    );

    final report = service.buildReport(result);

    expect(report.overallScore, greaterThanOrEqualTo(85));
    expect(
      report.insights.every((item) => item.status == RunningCoachStatus.good),
      isTrue,
    );
  });

  test('upright posture, high bounce, and overstride lower coaching scores',
      () {
    const result = RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 6),
      sampledFrames: 12,
      validFrames: 10,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 2.8,
      verticalBounceRatio: 0.108,
      strideReachRatio: 0.47,
    );

    final report = service.buildReport(result);

    expect(report.overallScore, lessThan(70));
    expect(report.insights[0].finding, RunningCoachFinding.postureTooUpright);
    expect(report.insights[1].finding, RunningCoachFinding.bounceTooHigh);
    expect(report.insights[2].finding, RunningCoachFinding.strideOverstride);
  });
}
