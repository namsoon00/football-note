import 'running_video_analysis_result.dart';

enum RunningCoachSessionSource { uploadVideo }

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
  final String? videoPath;
  final String? videoName;
  final List<RunningCoachSessionMetric> metricSnapshots;
  final RunningVideoAnalysisResult? analysisResult;

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
    this.videoPath,
    this.videoName,
    this.metricSnapshots = const <RunningCoachSessionMetric>[],
    this.analysisResult,
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

  List<RunningCoachingInsight> get insights {
    if (metricSnapshots.isEmpty) {
      return <RunningCoachingInsight>[primaryInsight];
    }
    return List<RunningCoachingInsight>.unmodifiable(
      metricSnapshots.map((snapshot) => snapshot.toInsight()),
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
      if (videoPath != null) 'videoPath': videoPath,
      if (videoName != null) 'videoName': videoName,
      if (metricSnapshots.isNotEmpty)
        'insights': metricSnapshots
            .map((snapshot) => snapshot.toMap())
            .toList(growable: false),
      if (analysisResult != null)
        'analysisResult': analysisResult!.historySnapshot().toMap(),
    };
  }

  factory RunningCoachSessionAnalysis.fromMap(Map<String, dynamic> map) {
    return RunningCoachSessionAnalysis(
      id: map['id']?.toString() ?? '',
      analyzedAt: DateTime.tryParse(map['analyzedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      source: RunningCoachSessionSource.uploadVideo,
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
      videoPath: _optionalString(map['videoPath']),
      videoName: _optionalString(map['videoName']),
      metricSnapshots: _metricSnapshotsFromMap(map['insights']),
      analysisResult: _analysisResultFromMap(map['analysisResult']),
    );
  }
}

RunningVideoAnalysisResult? _analysisResultFromMap(Object? raw) {
  if (raw is! Map) return null;
  return RunningVideoAnalysisResult.fromMap(
    raw.map<Object?, Object?>((key, value) => MapEntry(key, value)),
  );
}

class RunningCoachSessionMetric {
  final RunningCoachMetric metric;
  final RunningCoachFinding finding;
  final RunningCoachStatus status;
  final int score;
  final double value;
  final double confidence;
  final int sampleCount;

  const RunningCoachSessionMetric({
    required this.metric,
    required this.finding,
    required this.status,
    required this.score,
    required this.value,
    required this.confidence,
    required this.sampleCount,
  });

  factory RunningCoachSessionMetric.fromInsight(
    RunningCoachingInsight insight,
  ) {
    return RunningCoachSessionMetric(
      metric: insight.metric,
      finding: insight.finding,
      status: insight.status,
      score: insight.score,
      value: insight.value,
      confidence: insight.quality.confidence,
      sampleCount: insight.quality.sampleCount,
    );
  }

  RunningCoachingInsight toInsight() {
    return RunningCoachingInsight(
      metric: metric,
      finding: finding,
      status: status,
      score: score,
      value: value,
      quality: RunningMetricQuality(
        confidence: confidence,
        sampleCount: sampleCount,
      ),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'metric': metric.name,
      'finding': finding.name,
      'status': status.name,
      'score': score,
      'value': value,
      'confidence': confidence,
      'sampleCount': sampleCount,
    };
  }

  factory RunningCoachSessionMetric.fromMap(Map<String, dynamic> map) {
    return RunningCoachSessionMetric(
      metric: _enumByName(
        RunningCoachMetric.values,
        map['metric']?.toString(),
        RunningCoachMetric.posture,
      ),
      finding: _enumByName(
        RunningCoachFinding.values,
        map['finding']?.toString(),
        RunningCoachFinding.postureAligned,
      ),
      status: _enumByName(
        RunningCoachStatus.values,
        map['status']?.toString(),
        RunningCoachStatus.good,
      ),
      score: _intValue(map['score']),
      value: _doubleValue(map['value']),
      confidence: _doubleValue(map['confidence']).clamp(0.0, 1.0),
      sampleCount: _intValue(map['sampleCount']),
    );
  }
}

List<RunningCoachSessionMetric> _metricSnapshotsFromMap(Object? value) {
  if (value is! List) return const <RunningCoachSessionMetric>[];
  return List<RunningCoachSessionMetric>.unmodifiable(
    value
        .whereType<Map>()
        .map(
          (item) => RunningCoachSessionMetric.fromMap(
            item.cast<String, dynamic>(),
          ),
        )
        .toList(growable: false),
  );
}

String? _optionalString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _intValue(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _doubleValue(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
