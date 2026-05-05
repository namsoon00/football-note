import 'running_video_analysis_result.dart';

enum RunningCoachSessionSource { uploadVideo, liveRun, sprintLive }

class RunningCoachSessionAnalysis {
  final String id;
  final DateTime analyzedAt;
  final RunningCoachSessionSource source;
  final int overallScore;
  final Duration duration;
  final int sampledFrames;
  final int validFrames;
  final RunningCoachMetric primaryMetric;
  final RunningCoachFinding primaryFinding;
  final RunningCoachStatus primaryStatus;
  final int primaryScore;
  final double primaryValue;
  final double primaryConfidence;

  const RunningCoachSessionAnalysis({
    required this.id,
    required this.analyzedAt,
    required this.source,
    required this.overallScore,
    required this.duration,
    required this.sampledFrames,
    required this.validFrames,
    required this.primaryMetric,
    required this.primaryFinding,
    required this.primaryStatus,
    required this.primaryScore,
    required this.primaryValue,
    required this.primaryConfidence,
  });

  double get coverage =>
      sampledFrames == 0 ? 0.0 : (validFrames / sampledFrames).clamp(0.0, 1.0);

  RunningCoachingInsight get primaryInsight {
    return RunningCoachingInsight(
      metric: primaryMetric,
      finding: primaryFinding,
      status: primaryStatus,
      score: primaryScore,
      value: primaryValue,
      quality: RunningMetricQuality(
        confidence: primaryConfidence,
        sampleCount: validFrames,
      ),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'analyzedAt': analyzedAt.toIso8601String(),
      'source': source.name,
      'overallScore': overallScore,
      'durationMs': duration.inMilliseconds,
      'sampledFrames': sampledFrames,
      'validFrames': validFrames,
      'primaryMetric': primaryMetric.name,
      'primaryFinding': primaryFinding.name,
      'primaryStatus': primaryStatus.name,
      'primaryScore': primaryScore,
      'primaryValue': primaryValue,
      'primaryConfidence': primaryConfidence,
    };
  }

  factory RunningCoachSessionAnalysis.fromMap(Map<String, dynamic> map) {
    return RunningCoachSessionAnalysis(
      id: map['id']?.toString() ?? '',
      analyzedAt: DateTime.tryParse(map['analyzedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      source: _enumByName(
        RunningCoachSessionSource.values,
        map['source']?.toString(),
        RunningCoachSessionSource.uploadVideo,
      ),
      overallScore: _intValue(map['overallScore']),
      duration: Duration(milliseconds: _intValue(map['durationMs'])),
      sampledFrames: _intValue(map['sampledFrames']),
      validFrames: _intValue(map['validFrames']),
      primaryMetric: _enumByName(
        RunningCoachMetric.values,
        map['primaryMetric']?.toString(),
        RunningCoachMetric.posture,
      ),
      primaryFinding: _enumByName(
        RunningCoachFinding.values,
        map['primaryFinding']?.toString(),
        RunningCoachFinding.postureAligned,
      ),
      primaryStatus: _enumByName(
        RunningCoachStatus.values,
        map['primaryStatus']?.toString(),
        RunningCoachStatus.good,
      ),
      primaryScore: _intValue(map['primaryScore']),
      primaryValue: _doubleValue(map['primaryValue']),
      primaryConfidence: _doubleValue(map['primaryConfidence']).clamp(0.0, 1.0),
    );
  }
}

int _intValue(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _doubleValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
}
