import '../realtime_analysis/running_coaching/running_live_timing_config.dart';
import 'running_gait_calibration_evaluator.dart';

/// Checks whether a completed live-running session is suitable for expert
/// gait-event labeling. It verifies capture quality only; it does not claim
/// touchdown or toe-off accuracy without ground-truth labels.
class RunningLiveCaptureReadinessGate {
  final int minElapsedMs;
  final int minAnalyzedFrames;
  final int minAnalyzedFrameIntervalSamples;
  final int maxTargetFrameIntervalMs;
  final double maxAnalyzedFrameIntervalP95Ms;
  final double minTimingConfidence;
  final double minSideViewConfidence;
  final int minGaitEvents;
  final int maxAnalysisErrorFrames;

  RunningLiveCaptureReadinessGate({
    this.minElapsedMs = 5000,
    this.minAnalyzedFrames = 80,
    this.minAnalyzedFrameIntervalSamples = 80,
    int? maxTargetFrameIntervalMs,
    double? maxAnalyzedFrameIntervalP95Ms,
    this.minTimingConfidence = 0.70,
    this.minSideViewConfidence = 0.70,
    this.minGaitEvents = 12,
    this.maxAnalysisErrorFrames = 0,
  })  : maxTargetFrameIntervalMs = maxTargetFrameIntervalMs ??
            runningLiveGaitTargetFrameInterval.inMilliseconds,
        maxAnalyzedFrameIntervalP95Ms = maxAnalyzedFrameIntervalP95Ms ??
            runningLiveGaitMaximumFrameGap.inMilliseconds.toDouble(),
        assert(minElapsedMs > 0),
        assert(minAnalyzedFrames > 0),
        assert(minAnalyzedFrameIntervalSamples > 0),
        assert(
            maxTargetFrameIntervalMs == null || maxTargetFrameIntervalMs > 0),
        assert(maxAnalyzedFrameIntervalP95Ms == null ||
            maxAnalyzedFrameIntervalP95Ms > 0),
        assert(minTimingConfidence >= 0 && minTimingConfidence <= 1),
        assert(minSideViewConfidence >= 0 && minSideViewConfidence <= 1),
        assert(minGaitEvents > 0),
        assert(maxAnalysisErrorFrames >= 0) {
    _validateThresholds();
  }

  void _validateThresholds() {
    if (minElapsedMs <= 0) {
      throw ArgumentError.value(minElapsedMs, 'minElapsedMs', 'must be > 0');
    }
    if (minAnalyzedFrames <= 0) {
      throw ArgumentError.value(
        minAnalyzedFrames,
        'minAnalyzedFrames',
        'must be > 0',
      );
    }
    if (minAnalyzedFrameIntervalSamples <= 0) {
      throw ArgumentError.value(
        minAnalyzedFrameIntervalSamples,
        'minAnalyzedFrameIntervalSamples',
        'must be > 0',
      );
    }
    if (maxTargetFrameIntervalMs <= 0) {
      throw ArgumentError.value(
        maxTargetFrameIntervalMs,
        'maxTargetFrameIntervalMs',
        'must be > 0',
      );
    }
    if (!maxAnalyzedFrameIntervalP95Ms.isFinite ||
        maxAnalyzedFrameIntervalP95Ms <= 0) {
      throw ArgumentError.value(
        maxAnalyzedFrameIntervalP95Ms,
        'maxAnalyzedFrameIntervalP95Ms',
        'must be finite and > 0',
      );
    }
    _validateUnitInterval(minTimingConfidence, 'minTimingConfidence');
    _validateUnitInterval(minSideViewConfidence, 'minSideViewConfidence');
    if (minGaitEvents <= 0) {
      throw ArgumentError.value(minGaitEvents, 'minGaitEvents', 'must be > 0');
    }
    if (maxAnalysisErrorFrames < 0) {
      throw ArgumentError.value(
        maxAnalysisErrorFrames,
        'maxAnalysisErrorFrames',
        'must be >= 0',
      );
    }
  }

  void _validateUnitInterval(double value, String name) {
    if (!value.isFinite || value < 0 || value > 1) {
      throw ArgumentError.value(value, name, 'must be finite and 0 to 1');
    }
  }

  RunningLiveCaptureReadinessGateReport evaluate(
    GaitCalibrationFixture fixture,
  ) {
    final violations = <RunningLiveCaptureReadinessViolation>[];
    final diagnostics = fixture.liveSessionDiagnostics;
    final isLiveInput =
        fixture.format == GaitCalibrationInputFormat.runningLiveSessionLog ||
            fixture.format ==
                GaitCalibrationInputFormat.runningLiveCalibrationCapture;
    if (!isLiveInput) {
      violations.add(
        RunningLiveCaptureReadinessViolation(
          metric: 'input.format',
          actual: fixture.format.name,
          comparison: 'supported',
          threshold: 'runningLiveSessionLog or runningLiveCalibrationCapture',
          message: 'A live-running session log is required.',
        ),
      );
      return RunningLiveCaptureReadinessGateReport(
        thresholds: this,
        violations: List.unmodifiable(violations),
      );
    }
    if (diagnostics == null) {
      violations.add(
        const RunningLiveCaptureReadinessViolation(
          metric: 'capture.diagnostics',
          actual: null,
          comparison: 'available',
          threshold: true,
          message: 'The selected session does not include capture diagnostics.',
        ),
      );
      return RunningLiveCaptureReadinessGateReport(
        thresholds: this,
        violations: List.unmodifiable(violations),
      );
    }

    _checkRequiredEndEvent(violations, diagnostics.hasEndEvent);
    _checkMinimumInt(
      violations,
      metric: 'session.elapsedMs',
      actual: diagnostics.elapsedMs,
      threshold: minElapsedMs,
    );
    _checkMaximumInt(
      violations,
      metric: 'session.targetFrameIntervalMs',
      actual: diagnostics.targetFrameIntervalMs,
      threshold: maxTargetFrameIntervalMs,
    );
    _checkMinimumInt(
      violations,
      metric: 'metrics.analyzedFrames',
      actual: diagnostics.analyzedFrames,
      threshold: minAnalyzedFrames,
    );
    _checkMinimumInt(
      violations,
      metric: 'metrics.analyzedFrameIntervalMs.sampleCount',
      actual: diagnostics.analyzedFrameIntervalSampleCount,
      threshold: minAnalyzedFrameIntervalSamples,
    );
    _checkMaximumDouble(
      violations,
      metric: 'metrics.analyzedFrameIntervalMs.p95',
      actual: diagnostics.analyzedFrameIntervalP95Ms,
      threshold: maxAnalyzedFrameIntervalP95Ms,
    );
    _checkUnitIntervalMinimum(
      violations,
      metric: 'metrics.averageConfidence.timing',
      actual: diagnostics.averageTimingConfidence,
      threshold: minTimingConfidence,
    );
    _checkUnitIntervalMinimum(
      violations,
      metric: 'metrics.averageConfidence.sideView',
      actual: diagnostics.averageSideViewConfidence,
      threshold: minSideViewConfidence,
    );
    _checkMaximumInt(
      violations,
      metric: 'metrics.skippedFrames.analysisError',
      actual: diagnostics.analysisErrorFrames,
      threshold: maxAnalysisErrorFrames,
    );
    _checkMinimumInt(
      violations,
      metric: 'events.total',
      actual: diagnostics.reportedEventCount,
      threshold: minGaitEvents,
    );
    _checkTimelineCompleteness(violations, diagnostics);

    return RunningLiveCaptureReadinessGateReport(
      thresholds: this,
      violations: List.unmodifiable(violations),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'minElapsedMs': minElapsedMs,
      'minAnalyzedFrames': minAnalyzedFrames,
      'minAnalyzedFrameIntervalSamples': minAnalyzedFrameIntervalSamples,
      'maxTargetFrameIntervalMs': maxTargetFrameIntervalMs,
      'maxAnalyzedFrameIntervalP95Ms': _round(maxAnalyzedFrameIntervalP95Ms),
      'minTimingConfidence': _round(minTimingConfidence),
      'minSideViewConfidence': _round(minSideViewConfidence),
      'minGaitEvents': minGaitEvents,
      'maxAnalysisErrorFrames': maxAnalysisErrorFrames,
    };
  }

  void _checkRequiredEndEvent(
    List<RunningLiveCaptureReadinessViolation> violations,
    bool hasEndEvent,
  ) {
    if (hasEndEvent) {
      return;
    }
    violations.add(
      const RunningLiveCaptureReadinessViolation(
        metric: 'session.endEvent',
        actual: false,
        comparison: '==',
        threshold: true,
        message: 'The selected session must include its final end log.',
      ),
    );
  }

  void _checkMinimumInt(
    List<RunningLiveCaptureReadinessViolation> violations, {
    required String metric,
    required int? actual,
    required int threshold,
  }) {
    if (actual != null && actual >= threshold) {
      return;
    }
    violations.add(
      RunningLiveCaptureReadinessViolation(
        metric: metric,
        actual: actual,
        comparison: '>=',
        threshold: threshold,
        message: actual == null
            ? '$metric is unavailable; it must be >= $threshold.'
            : '$metric must be >= $threshold but was $actual.',
      ),
    );
  }

  void _checkMaximumInt(
    List<RunningLiveCaptureReadinessViolation> violations, {
    required String metric,
    required int? actual,
    required int threshold,
  }) {
    if (actual != null && actual >= 0 && actual <= threshold) {
      return;
    }
    violations.add(
      RunningLiveCaptureReadinessViolation(
        metric: metric,
        actual: actual,
        comparison: '<=',
        threshold: threshold,
        message: actual == null
            ? '$metric is unavailable; it must be <= $threshold.'
            : '$metric must be between 0 and $threshold but was $actual.',
      ),
    );
  }

  void _checkMaximumDouble(
    List<RunningLiveCaptureReadinessViolation> violations, {
    required String metric,
    required double? actual,
    required double threshold,
  }) {
    if (actual != null && actual >= 0 && actual <= threshold) {
      return;
    }
    violations.add(
      RunningLiveCaptureReadinessViolation(
        metric: metric,
        actual: actual == null ? null : _round(actual),
        comparison: '<=',
        threshold: _round(threshold),
        message: actual == null
            ? '$metric is unavailable; it must be <= ${_round(threshold)}.'
            : '$metric must be between 0 and ${_round(threshold)} but was '
                '${_round(actual)}.',
      ),
    );
  }

  void _checkUnitIntervalMinimum(
    List<RunningLiveCaptureReadinessViolation> violations, {
    required String metric,
    required double? actual,
    required double threshold,
  }) {
    if (actual != null && actual >= 0 && actual <= 1 && actual >= threshold) {
      return;
    }
    violations.add(
      RunningLiveCaptureReadinessViolation(
        metric: metric,
        actual: actual == null ? null : _round(actual),
        comparison: '>=',
        threshold: _round(threshold),
        message: actual == null
            ? '$metric is unavailable; it must be >= ${_round(threshold)}.'
            : '$metric must be between ${_round(threshold)} and 1 but was '
                '${_round(actual)}.',
      ),
    );
  }

  void _checkTimelineCompleteness(
    List<RunningLiveCaptureReadinessViolation> violations,
    RunningLiveCaptureDiagnostics diagnostics,
  ) {
    final reportedEventCount = diagnostics.reportedEventCount;
    if (reportedEventCount != null &&
        reportedEventCount == diagnostics.loggedTimelineEventCount) {
      return;
    }
    violations.add(
      RunningLiveCaptureReadinessViolation(
        metric: 'events.timelineCount',
        actual: diagnostics.loggedTimelineEventCount,
        comparison: '==',
        threshold: reportedEventCount ?? 'reported events.total',
        message: reportedEventCount == null
            ? 'The logged event timeline cannot be checked against events.total.'
            : 'The logged event timeline has '
                '${diagnostics.loggedTimelineEventCount} events but '
                'events.total reports $reportedEventCount.',
      ),
    );
  }
}

class RunningLiveCaptureReadinessGateReport {
  final RunningLiveCaptureReadinessGate thresholds;
  final List<RunningLiveCaptureReadinessViolation> violations;

  const RunningLiveCaptureReadinessGateReport({
    required this.thresholds,
    required this.violations,
  });

  bool get passed => violations.isEmpty;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'passed': passed,
      'thresholds': thresholds.toJson(),
      'violations': [
        for (final violation in violations) violation.toJson(),
      ],
    };
  }
}

class RunningLiveCaptureReadinessViolation {
  final String metric;
  final Object? actual;
  final String comparison;
  final Object threshold;
  final String message;

  const RunningLiveCaptureReadinessViolation({
    required this.metric,
    required this.actual,
    required this.comparison,
    required this.threshold,
    required this.message,
  });

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'metric': metric,
      'actual': actual,
      'comparison': comparison,
      'threshold': threshold,
      'message': message,
    };
  }
}

class RunningLiveCaptureReadinessEvaluator {
  final RunningLiveCaptureReadinessGate readinessGate;

  RunningLiveCaptureReadinessEvaluator({
    RunningLiveCaptureReadinessGate? readinessGate,
  }) : readinessGate = readinessGate ?? RunningLiveCaptureReadinessGate();

  RunningLiveCaptureReadinessReport evaluate(
    GaitCalibrationFixture fixture,
  ) {
    return RunningLiveCaptureReadinessReport(
      input: fixture.sourceMetadataToJson(),
      capture: fixture.liveSessionDiagnostics,
      readinessGate: readinessGate.evaluate(fixture),
    );
  }
}

class RunningLiveCaptureReadinessReport {
  final Map<String, Object?> input;
  final RunningLiveCaptureDiagnostics? capture;
  final RunningLiveCaptureReadinessGateReport readinessGate;

  const RunningLiveCaptureReadinessReport({
    required this.input,
    required this.capture,
    required this.readinessGate,
  });

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'input': input,
      'capture': capture?.toJson(),
      'readinessGate': readinessGate.toJson(),
    };
  }
}

double _round(double value) => double.parse(value.toStringAsFixed(3));
