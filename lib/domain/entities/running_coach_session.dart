import 'running_video_analysis_result.dart';
import 'running_live_coaching_state.dart';
import 'sprint_realtime_coaching_state.dart';

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
  final String? videoPath;
  final String? videoName;
  final List<RunningCoachSessionMetric> metricSnapshots;
  final LiveSprintSessionReport? liveSprintReport;

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
    this.liveSprintReport,
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
      if (liveSprintReport != null)
        'liveSprintReport': liveSprintReport!.toMap(),
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
      videoPath: _optionalString(map['videoPath']),
      videoName: _optionalString(map['videoName']),
      metricSnapshots: _metricSnapshotsFromMap(map['insights']),
      liveSprintReport: _liveSprintReportFromMap(map['liveSprintReport']),
    );
  }
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
      RunningCoachingInsight insight) {
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

enum LiveSprintMetricKind {
  trunkAngle,
  kneeDrive,
  cadence,
  rhythm,
  armBalance,
  landing,
  flightRatio,
  lateForm,
}

class LiveSprintMetricSummary {
  final LiveSprintMetricKind kind;
  final double? value;
  final double? secondaryValue;
  final double confidence;
  final int sampleCount;

  const LiveSprintMetricSummary({
    required this.kind,
    required this.value,
    this.secondaryValue,
    required this.confidence,
    required this.sampleCount,
  });

  bool get available => value != null;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'kind': kind.name,
      'value': value,
      if (secondaryValue != null) 'secondaryValue': secondaryValue,
      'confidence': confidence,
      'sampleCount': sampleCount,
    };
  }

  factory LiveSprintMetricSummary.fromMap(Map<String, dynamic> map) {
    return LiveSprintMetricSummary(
      kind: _enumByName(
        LiveSprintMetricKind.values,
        map['kind']?.toString(),
        LiveSprintMetricKind.trunkAngle,
      ),
      value: _nullableDoubleValue(map['value']),
      secondaryValue: _nullableDoubleValue(map['secondaryValue']),
      confidence: _doubleValue(map['confidence']).clamp(0.0, 1.0),
      sampleCount: _intValue(map['sampleCount']),
    );
  }
}

enum LiveSprintPoseEvidencePhase { touchdown, support, flight }

class LiveSprintPoseEvidenceJoint {
  final RunningPoseLandmarkType type;
  final double x;
  final double y;
  final double z;
  final double confidence;
  final bool observed;

  const LiveSprintPoseEvidenceJoint({
    required this.type,
    required this.x,
    required this.y,
    required this.z,
    required this.confidence,
    required this.observed,
  });

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'type': type.name,
      'x': x,
      'y': y,
      'z': z,
      'confidence': confidence,
      'observed': observed,
    };
  }

  factory LiveSprintPoseEvidenceJoint.fromMap(Map<String, dynamic> map) {
    return LiveSprintPoseEvidenceJoint(
      type: _enumByName(
        RunningPoseLandmarkType.values,
        map['type']?.toString(),
        RunningPoseLandmarkType.nose,
      ),
      x: _doubleValue(map['x']).clamp(0.0, 1.0),
      y: _doubleValue(map['y']).clamp(0.0, 1.0),
      z: _doubleValue(map['z']),
      confidence: _doubleValue(map['confidence']).clamp(0.0, 1.0),
      observed: map['observed'] == true,
    );
  }
}

class LiveSprintPoseEvidenceFrame {
  final LiveSprintPoseEvidencePhase phase;
  final int capturedOffsetMs;
  final double quality;
  final double sideViewConfidence;
  final double imageAspectRatio;
  final RunningFootSide? leadFoot;
  final List<LiveSprintPoseEvidenceJoint> joints;

  const LiveSprintPoseEvidenceFrame({
    required this.phase,
    required this.capturedOffsetMs,
    required this.quality,
    required this.sideViewConfidence,
    required this.imageAspectRatio,
    required this.leadFoot,
    required this.joints,
  });

  LiveSprintPoseEvidenceJoint? joint(RunningPoseLandmarkType type) {
    for (final candidate in joints) {
      if (candidate.type == type) {
        return candidate;
      }
    }
    return null;
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'phase': phase.name,
      'capturedOffsetMs': capturedOffsetMs,
      'quality': quality,
      'sideViewConfidence': sideViewConfidence,
      'imageAspectRatio': imageAspectRatio,
      if (leadFoot != null) 'leadFoot': leadFoot!.name,
      'joints': joints.map((joint) => joint.toMap()).toList(growable: false),
    };
  }

  factory LiveSprintPoseEvidenceFrame.fromMap(Map<String, dynamic> map) {
    return LiveSprintPoseEvidenceFrame(
      phase: _enumByName(
        LiveSprintPoseEvidencePhase.values,
        map['phase']?.toString(),
        LiveSprintPoseEvidencePhase.support,
      ),
      capturedOffsetMs: _intValue(map['capturedOffsetMs']).clamp(0, 1 << 31),
      quality: _doubleValue(map['quality']).clamp(0.0, 1.0),
      sideViewConfidence:
          _doubleValue(map['sideViewConfidence']).clamp(0.0, 1.0),
      imageAspectRatio: _doubleValue(map['imageAspectRatio']).clamp(0.2, 4.0),
      leadFoot: _nullableEnumByName(
        RunningFootSide.values,
        map['leadFoot']?.toString(),
      ),
      joints: _liveSprintPoseEvidenceJointsFromMap(map['joints']),
    );
  }
}

class LiveSprintSessionReport {
  final int runningTrackedFrames;
  final int runningAnalyzedFrames;
  final int sprintTrackedFrames;
  final int sprintAnalyzedFrames;
  final int touchdownEvents;
  final int toeOffEvents;
  final int detectedSteps;
  final int landingEvents;
  final int feedbackChanges;
  final double timingConfidence;
  final double sideViewConfidence;
  final double sprintTrackingConfidence;
  final double bodyNotVisibleRatio;
  final SprintCoachingStatus status;
  final SprintTrackingReadiness trackingReadiness;
  final SprintFeedbackCode? feedbackCode;
  final SprintFeedbackSeverity? feedbackSeverity;
  final double feedbackConfidence;
  final List<LiveSprintMetricSummary> metrics;
  final List<LiveSprintPoseEvidenceFrame> poseEvidence;

  const LiveSprintSessionReport({
    required this.runningTrackedFrames,
    required this.runningAnalyzedFrames,
    required this.sprintTrackedFrames,
    required this.sprintAnalyzedFrames,
    required this.touchdownEvents,
    required this.toeOffEvents,
    required this.detectedSteps,
    required this.landingEvents,
    required this.feedbackChanges,
    required this.timingConfidence,
    required this.sideViewConfidence,
    required this.sprintTrackingConfidence,
    required this.bodyNotVisibleRatio,
    required this.status,
    required this.trackingReadiness,
    required this.feedbackCode,
    required this.feedbackSeverity,
    required this.feedbackConfidence,
    required this.metrics,
    this.poseEvidence = const <LiveSprintPoseEvidenceFrame>[],
  });

  double get analysisConfidence =>
      ((timingConfidence + sideViewConfidence + sprintTrackingConfidence) / 3)
          .clamp(0.0, 1.0);

  LiveSprintMetricSummary? metricFor(LiveSprintMetricKind kind) {
    for (final metric in metrics) {
      if (metric.kind == kind) {
        return metric;
      }
    }
    return null;
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'runningTrackedFrames': runningTrackedFrames,
      'runningAnalyzedFrames': runningAnalyzedFrames,
      'sprintTrackedFrames': sprintTrackedFrames,
      'sprintAnalyzedFrames': sprintAnalyzedFrames,
      'touchdownEvents': touchdownEvents,
      'toeOffEvents': toeOffEvents,
      'detectedSteps': detectedSteps,
      'landingEvents': landingEvents,
      'feedbackChanges': feedbackChanges,
      'timingConfidence': timingConfidence,
      'sideViewConfidence': sideViewConfidence,
      'sprintTrackingConfidence': sprintTrackingConfidence,
      'bodyNotVisibleRatio': bodyNotVisibleRatio,
      'status': status.name,
      'trackingReadiness': trackingReadiness.name,
      if (feedbackCode != null) 'feedbackCode': feedbackCode!.name,
      if (feedbackSeverity != null) 'feedbackSeverity': feedbackSeverity!.name,
      'feedbackConfidence': feedbackConfidence,
      'metrics':
          metrics.map((metric) => metric.toMap()).toList(growable: false),
      if (poseEvidence.isNotEmpty)
        'poseEvidence': poseEvidence
            .map((evidence) => evidence.toMap())
            .toList(growable: false),
    };
  }

  factory LiveSprintSessionReport.fromMap(Map<String, dynamic> map) {
    return LiveSprintSessionReport(
      runningTrackedFrames: _intValue(map['runningTrackedFrames']),
      runningAnalyzedFrames: _intValue(map['runningAnalyzedFrames']),
      sprintTrackedFrames: _intValue(map['sprintTrackedFrames']),
      sprintAnalyzedFrames: _intValue(map['sprintAnalyzedFrames']),
      touchdownEvents: _intValue(map['touchdownEvents']),
      toeOffEvents: _intValue(map['toeOffEvents']),
      detectedSteps: _intValue(map['detectedSteps']),
      landingEvents: _intValue(map['landingEvents']),
      feedbackChanges: _intValue(map['feedbackChanges']),
      timingConfidence: _doubleValue(map['timingConfidence']).clamp(0.0, 1.0),
      sideViewConfidence:
          _doubleValue(map['sideViewConfidence']).clamp(0.0, 1.0),
      sprintTrackingConfidence:
          _doubleValue(map['sprintTrackingConfidence']).clamp(0.0, 1.0),
      bodyNotVisibleRatio:
          _doubleValue(map['bodyNotVisibleRatio']).clamp(0.0, 1.0),
      status: _enumByName(
        SprintCoachingStatus.values,
        map['status']?.toString(),
        SprintCoachingStatus.collecting,
      ),
      trackingReadiness: _enumByName(
        SprintTrackingReadiness.values,
        map['trackingReadiness']?.toString(),
        SprintTrackingReadiness.lowConfidence,
      ),
      feedbackCode: _nullableEnumByName(
        SprintFeedbackCode.values,
        map['feedbackCode']?.toString(),
      ),
      feedbackSeverity: _nullableEnumByName(
        SprintFeedbackSeverity.values,
        map['feedbackSeverity']?.toString(),
      ),
      feedbackConfidence:
          _doubleValue(map['feedbackConfidence']).clamp(0.0, 1.0),
      metrics: _liveSprintMetricsFromMap(map['metrics']),
      poseEvidence: _liveSprintPoseEvidenceFromMap(map['poseEvidence']),
    );
  }
}

List<RunningCoachSessionMetric> _metricSnapshotsFromMap(Object? value) {
  if (value is! List) {
    return const <RunningCoachSessionMetric>[];
  }
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

LiveSprintSessionReport? _liveSprintReportFromMap(Object? value) {
  if (value is! Map) {
    return null;
  }
  return LiveSprintSessionReport.fromMap(value.cast<String, dynamic>());
}

List<LiveSprintMetricSummary> _liveSprintMetricsFromMap(Object? value) {
  if (value is! List) {
    return const <LiveSprintMetricSummary>[];
  }
  return List<LiveSprintMetricSummary>.unmodifiable(
    value
        .whereType<Map>()
        .map(
          (item) => LiveSprintMetricSummary.fromMap(
            item.cast<String, dynamic>(),
          ),
        )
        .toList(growable: false),
  );
}

List<LiveSprintPoseEvidenceFrame> _liveSprintPoseEvidenceFromMap(
  Object? value,
) {
  if (value is! List) {
    return const <LiveSprintPoseEvidenceFrame>[];
  }
  return List<LiveSprintPoseEvidenceFrame>.unmodifiable(
    value
        .whereType<Map>()
        .map(
          (item) => LiveSprintPoseEvidenceFrame.fromMap(
            item.cast<String, dynamic>(),
          ),
        )
        .toList(growable: false),
  );
}

List<LiveSprintPoseEvidenceJoint> _liveSprintPoseEvidenceJointsFromMap(
  Object? value,
) {
  if (value is! List) {
    return const <LiveSprintPoseEvidenceJoint>[];
  }
  return List<LiveSprintPoseEvidenceJoint>.unmodifiable(
    value
        .whereType<Map>()
        .map(
          (item) => LiveSprintPoseEvidenceJoint.fromMap(
            item.cast<String, dynamic>(),
          ),
        )
        .toList(growable: false),
  );
}

String? _optionalString(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
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

double? _nullableDoubleValue(Object? value) {
  if (value == null) {
    return null;
  }
  return _doubleValue(value);
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
}

T? _nullableEnumByName<T extends Enum>(List<T> values, String? name) {
  if (name == null || name.isEmpty) {
    return null;
  }
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return null;
}
