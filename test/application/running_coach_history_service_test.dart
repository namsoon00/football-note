import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_coach_history_service.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/domain/repositories/option_repository.dart';

void main() {
  test('saves recent upload analyses with primary focus', () async {
    final repository = _MemoryOptionRepository();
    final service = RunningCoachHistoryService(repository);
    const report = RunningCoachingReport(
      overallScore: 62,
      insights: [
        RunningCoachingInsight(
          metric: RunningCoachMetric.footStrike,
          finding: RunningCoachFinding.footStrikeOverstride,
          status: RunningCoachStatus.needsWork,
          score: 58,
          value: 0.22,
          quality: RunningMetricQuality(confidence: 0.72, sampleCount: 3),
        ),
      ],
    );
    const result = RunningVideoAnalysisResult(
      videoDuration: Duration(seconds: 5),
      sampledFrames: 14,
      validFrames: 10,
      direction: RunningDirection.leftToRight,
      forwardLeanDegrees: 9,
      verticalBounceRatio: 0.07,
      footStrikeDistanceRatio: 0.22,
      stanceKneeAngleDegrees: 160,
      elbowAngleDegrees: 88,
    );

    await service.saveUploadAnalysis(
      result: result,
      report: report,
      analyzedAt: DateTime(2026, 5, 5, 12),
    );

    final sessions = service.allSessions();
    expect(sessions, hasLength(1));
    expect(sessions.first.overallScore, 62);
    expect(sessions.first.primaryMetric, RunningCoachMetric.footStrike);
    expect(sessions.first.primaryConfidence, 0.72);
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> values = <String, dynamic>{};

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = values[key];
    if (value is List) {
      return value.map((item) => int.tryParse('$item') ?? 0).toList();
    }
    return List<int>.from(defaults);
  }

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = values[key];
    if (value is List) {
      return value.map((item) => '$item').toList();
    }
    return List<String>.from(defaults);
  }

  @override
  T? getValue<T>(String key) {
    final value = values[key];
    return value is T ? value : null;
  }

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    values[key] = value;
  }
}
