enum RunningMeasurementState { confirmed, estimated, unavailable }

enum RunningAnalysisMetric {
  cadence,
  stepTime,
  leftRightTiming,
  posture,
  bounce,
  footStrike,
  kneeAtContact,
  maximumKneeFlexion,
  elbowAngle,
  armSwingRange,
  armAsymmetry,
  footRolling,
}

enum RunningScaleTrend { stable, approaching, receding }

const int runningAnalysisVersionV2 = 2;

class RunningExpectedRange {
  final double lower;
  final double upper;

  const RunningExpectedRange({required this.lower, required this.upper});

  Map<String, Object?> toMap() => <String, Object?>{
        'lower': lower,
        'upper': upper,
      };

  static RunningExpectedRange? fromObject(Object? raw) {
    if (raw is! Map) return null;
    final lower = _measurementDouble(raw['lower']);
    final upper = _measurementDouble(raw['upper']);
    if (lower == null || upper == null) return null;
    return RunningExpectedRange(
      lower: lower <= upper ? lower : upper,
      upper: upper >= lower ? upper : lower,
    );
  }
}

class RunningMetricMeasurement {
  final RunningAnalysisMetric metric;
  final RunningMeasurementState state;
  final double? value;
  final RunningExpectedRange? expectedRange;
  final double confidence;
  final int sampleCount;
  final String method;
  final String? reason;
  final List<Duration> evidenceTimestamps;

  const RunningMetricMeasurement({
    required this.metric,
    required this.state,
    required this.value,
    required this.expectedRange,
    required this.confidence,
    required this.sampleCount,
    required this.method,
    required this.evidenceTimestamps,
    this.reason,
  });

  const RunningMetricMeasurement.unavailable({
    required this.metric,
    required this.method,
    required this.reason,
  })  : state = RunningMeasurementState.unavailable,
        value = null,
        expectedRange = null,
        confidence = 0,
        sampleCount = 0,
        evidenceTimestamps = const <Duration>[];

  bool get hasCoordinates => state != RunningMeasurementState.unavailable;
  bool get isConfirmed => state == RunningMeasurementState.confirmed;
  bool get isEstimated => state == RunningMeasurementState.estimated;

  Map<String, Object?> toMap() => <String, Object?>{
        'metric': metric.name,
        'state': state.name,
        if (value != null && value!.isFinite) 'value': value,
        if (expectedRange != null) 'expectedRange': expectedRange!.toMap(),
        'confidence': confidence,
        'sampleCount': sampleCount,
        'method': method,
        if (reason != null) 'reason': reason,
        'evidenceTimestampsMs': evidenceTimestamps
            .map((timestamp) => timestamp.inMilliseconds)
            .toList(growable: false),
      };

  static RunningMetricMeasurement? fromObject(Object? raw) {
    if (raw is! Map) return null;
    final metric = _enumByName(
      RunningAnalysisMetric.values,
      raw['metric']?.toString(),
    );
    final state = _enumByName(
      RunningMeasurementState.values,
      raw['state']?.toString(),
    );
    final confidence = _measurementDouble(raw['confidence']);
    final sampleCount = _measurementInt(raw['sampleCount']);
    final method = raw['method']?.toString().trim();
    if (metric == null ||
        state == null ||
        confidence == null ||
        sampleCount == null ||
        sampleCount < 0 ||
        method == null ||
        method.isEmpty) {
      return null;
    }
    final value = _measurementDouble(raw['value']);
    if (state != RunningMeasurementState.unavailable && value == null) {
      return null;
    }
    final timestamps = <Duration>[];
    final rawTimestamps = raw['evidenceTimestampsMs'];
    if (rawTimestamps is Iterable) {
      for (final item in rawTimestamps) {
        final milliseconds = _measurementInt(item);
        if (milliseconds != null && milliseconds >= 0) {
          timestamps.add(Duration(milliseconds: milliseconds));
        }
      }
    }
    timestamps.sort();
    return RunningMetricMeasurement(
      metric: metric,
      state: state,
      value: state == RunningMeasurementState.unavailable ? null : value,
      expectedRange: RunningExpectedRange.fromObject(raw['expectedRange']),
      confidence: confidence.clamp(0.0, 1.0).toDouble(),
      sampleCount: sampleCount,
      method: method,
      reason: _optionalMeasurementString(raw['reason']),
      evidenceTimestamps: List<Duration>.unmodifiable(timestamps),
    );
  }
}

class RunningScaleSegment {
  final Duration start;
  final Duration end;
  final RunningScaleTrend trend;
  final double medianScale;
  final double confidence;
  final int sampleCount;

  const RunningScaleSegment({
    required this.start,
    required this.end,
    required this.trend,
    required this.medianScale,
    required this.confidence,
    required this.sampleCount,
  });

  Map<String, Object?> toMap() => <String, Object?>{
        'startTimestampMs': start.inMilliseconds,
        'endTimestampMs': end.inMilliseconds,
        'trend': trend.name,
        'medianScale': medianScale,
        'confidence': confidence,
        'sampleCount': sampleCount,
      };

  static RunningScaleSegment? fromObject(Object? raw) {
    if (raw is! Map) return null;
    final startMs = _measurementInt(raw['startTimestampMs']);
    final endMs = _measurementInt(raw['endTimestampMs']);
    final trend = _enumByName(
      RunningScaleTrend.values,
      raw['trend']?.toString(),
    );
    final medianScale = _measurementDouble(raw['medianScale']);
    final confidence = _measurementDouble(raw['confidence']);
    final sampleCount = _measurementInt(raw['sampleCount']);
    if (startMs == null ||
        endMs == null ||
        startMs < 0 ||
        endMs < startMs ||
        trend == null ||
        medianScale == null ||
        medianScale <= 0 ||
        confidence == null ||
        sampleCount == null ||
        sampleCount <= 0) {
      return null;
    }
    return RunningScaleSegment(
      start: Duration(milliseconds: startMs),
      end: Duration(milliseconds: endMs),
      trend: trend,
      medianScale: medianScale,
      confidence: confidence.clamp(0.0, 1.0).toDouble(),
      sampleCount: sampleCount,
    );
  }
}

T? _enumByName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

double? _measurementDouble(Object? value) {
  if (value is! num || !value.isFinite) return null;
  return value.toDouble();
}

int? _measurementInt(Object? value) {
  if (value is! num || !value.isFinite) return null;
  return value.toInt();
}

String? _optionalMeasurementString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
