import 'dart:math' as math;

import '../domain/entities/running_coach_session.dart';
import '../realtime_analysis/sprint_coaching/sprint_pipeline_config.dart';

enum LiveSprintTrendStatus {
  noSessions,
  needsMoreSessions,
  captureQualityLow,
  ready,
}

enum LiveSprintTrendSignal { improved, steady, needsAttention }

class LiveSprintMetricTrend {
  final LiveSprintMetricKind kind;
  final double currentValue;
  final double baselineValue;
  final int baselineSessionCount;
  final double confidence;
  final double currentTargetGap;
  final double baselineTargetGap;
  final LiveSprintTrendSignal signal;

  const LiveSprintMetricTrend({
    required this.kind,
    required this.currentValue,
    required this.baselineValue,
    required this.baselineSessionCount,
    required this.confidence,
    required this.currentTargetGap,
    required this.baselineTargetGap,
    required this.signal,
  });

  double get targetGapChange => currentTargetGap - baselineTargetGap;
}

class LiveSprintTrendSummary {
  final LiveSprintTrendStatus status;
  final RunningCoachSessionAnalysis? currentSession;
  final int liveSessionCount;
  final int comparableSessionCount;
  final int baselineSessionCount;
  final int requiredComparableSessions;
  final List<LiveSprintMetricTrend> metricTrends;

  const LiveSprintTrendSummary({
    required this.status,
    required this.currentSession,
    required this.liveSessionCount,
    required this.comparableSessionCount,
    required this.baselineSessionCount,
    required this.requiredComparableSessions,
    required this.metricTrends,
  });

  bool get hasLiveSessions => liveSessionCount > 0;

  bool get isReady => status == LiveSprintTrendStatus.ready;

  int get additionalStableSessionsNeeded => math.max(
        0,
        requiredComparableSessions - comparableSessionCount,
      );

  List<LiveSprintMetricTrend> get highlightedMetricTrends {
    final trends = List<LiveSprintMetricTrend>.from(metricTrends);
    trends.sort((left, right) {
      final signalCompare = _signalPriority(right.signal).compareTo(
        _signalPriority(left.signal),
      );
      if (signalCompare != 0) {
        return signalCompare;
      }
      final gapCompare = right.currentTargetGap.compareTo(
        left.currentTargetGap,
      );
      if (gapCompare != 0) {
        return gapCompare;
      }
      return right.targetGapChange.abs().compareTo(
            left.targetGapChange.abs(),
          );
    });
    return List<LiveSprintMetricTrend>.unmodifiable(trends);
  }
}

class LiveSprintTrendService {
  static const int minimumComparableSessions = 3;
  static const int _minimumBaselineSessions = minimumComparableSessions - 1;
  static const int _maximumBaselineSessions = 4;
  static const double _minimumSessionAnalysisConfidence = 0.7;
  static const double _minimumMetricConfidence = 0.7;
  static const int _minimumSprintAnalyzedFrames = 18;
  static const int _minimumDetectedSteps = 4;
  static const int _minimumMetricSamples = 4;
  static const double _maximumBodyNotVisibleRatio = 0.25;

  final SprintPipelineConfig _config;

  const LiveSprintTrendService({
    SprintPipelineConfig config = const SprintPipelineConfig(),
  }) : _config = config;

  LiveSprintTrendSummary build(
    List<RunningCoachSessionAnalysis> sessions, {
    String? currentSessionId,
  }) {
    final liveSessions = sessions
        .where(
          (session) =>
              session.source == RunningCoachSessionSource.sprintLive &&
              session.liveSprintReport != null,
        )
        .toList(growable: false)
      ..sort((left, right) => right.analyzedAt.compareTo(left.analyzedAt));
    if (liveSessions.isEmpty) {
      return _summary(
        status: LiveSprintTrendStatus.noSessions,
        liveSessionCount: 0,
      );
    }

    final current = _currentSessionFor(liveSessions, currentSessionId);
    if (current == null) {
      return _summary(
        status: LiveSprintTrendStatus.noSessions,
        liveSessionCount: liveSessions.length,
      );
    }

    final sessionsAtOrBeforeCurrent = liveSessions
        .where(
          (session) =>
              session.id == current.id ||
              !session.analyzedAt.isAfter(current.analyzedAt),
        )
        .toList(growable: false);
    final comparable = sessionsAtOrBeforeCurrent
        .where(isSessionQualitySufficient)
        .toList(growable: false);
    if (!isSessionQualitySufficient(current)) {
      return _summary(
        status: LiveSprintTrendStatus.captureQualityLow,
        currentSession: current,
        liveSessionCount: liveSessions.length,
        comparableSessionCount: comparable.length,
      );
    }

    final baselineSessions = comparable
        .where((session) => session.id != current.id)
        .take(_maximumBaselineSessions)
        .toList(growable: false);
    final comparableSessionCount = baselineSessions.length + 1;
    if (baselineSessions.length < _minimumBaselineSessions) {
      return _summary(
        status: LiveSprintTrendStatus.needsMoreSessions,
        currentSession: current,
        liveSessionCount: liveSessions.length,
        comparableSessionCount: comparableSessionCount,
        baselineSessionCount: baselineSessions.length,
      );
    }

    final trends = _buildMetricTrends(
      current: current,
      baselineSessions: baselineSessions,
    );
    return _summary(
      status: trends.isEmpty
          ? LiveSprintTrendStatus.captureQualityLow
          : LiveSprintTrendStatus.ready,
      currentSession: current,
      liveSessionCount: liveSessions.length,
      comparableSessionCount: comparableSessionCount,
      baselineSessionCount: baselineSessions.length,
      metricTrends: trends,
    );
  }

  bool isSessionQualitySufficient(RunningCoachSessionAnalysis session) {
    final report = session.liveSprintReport;
    return session.source == RunningCoachSessionSource.sprintLive &&
        report != null &&
        report.analysisConfidence >= _minimumSessionAnalysisConfidence &&
        report.sprintAnalyzedFrames >= _minimumSprintAnalyzedFrames &&
        report.detectedSteps >= _minimumDetectedSteps &&
        report.bodyNotVisibleRatio <= _maximumBodyNotVisibleRatio;
  }

  bool isMetricQualitySufficient(LiveSprintMetricSummary? metric) {
    return metric != null &&
        metric.available &&
        metric.confidence >= _minimumMetricConfidence &&
        metric.sampleCount >= _minimumMetricSamples;
  }

  RunningCoachSessionAnalysis? _currentSessionFor(
    List<RunningCoachSessionAnalysis> sessions,
    String? sessionId,
  ) {
    if (sessionId == null) {
      return sessions.first;
    }
    for (final session in sessions) {
      if (session.id == sessionId) {
        return session;
      }
    }
    return null;
  }

  List<LiveSprintMetricTrend> _buildMetricTrends({
    required RunningCoachSessionAnalysis current,
    required List<RunningCoachSessionAnalysis> baselineSessions,
  }) {
    final report = current.liveSprintReport!;
    final trends = <LiveSprintMetricTrend>[];
    for (final kind in _trendMetricKinds) {
      final currentMetric = report.metricFor(kind);
      if (!isMetricQualitySufficient(currentMetric)) {
        continue;
      }
      final baselineMetrics = baselineSessions
          .map((session) => session.liveSprintReport!.metricFor(kind))
          .whereType<LiveSprintMetricSummary>()
          .where(isMetricQualitySufficient)
          .toList(growable: false);
      if (baselineMetrics.length < _minimumBaselineSessions) {
        continue;
      }
      final currentValue = currentMetric!.value!;
      final baselineValue = _average(
        baselineMetrics.map((metric) => metric.value!).toList(growable: false),
      );
      final currentGap = _targetGap(kind, currentValue);
      final baselineGap = _targetGap(kind, baselineValue);
      trends.add(
        LiveSprintMetricTrend(
          kind: kind,
          currentValue: currentValue,
          baselineValue: baselineValue,
          baselineSessionCount: baselineMetrics.length,
          confidence: math.min(
            currentMetric.confidence,
            _average(
              baselineMetrics
                  .map((metric) => metric.confidence)
                  .toList(growable: false),
            ),
          ),
          currentTargetGap: currentGap,
          baselineTargetGap: baselineGap,
          signal: _signalFor(
            kind: kind,
            currentGap: currentGap,
            baselineGap: baselineGap,
          ),
        ),
      );
    }
    return List<LiveSprintMetricTrend>.unmodifiable(trends);
  }

  double _targetGap(LiveSprintMetricKind kind, double value) {
    return switch (kind) {
      LiveSprintMetricKind.trunkAngle => _distanceFromRange(
          value,
          _config.minimumTrunkAngleDegrees,
          _config.maximumAccelerationTrunkAngleDegrees,
        ),
      LiveSprintMetricKind.kneeDrive =>
        math.max(0, _config.minimumKneeDriveHeight - value),
      LiveSprintMetricKind.rhythm =>
        math.max(0, value - _config.maximumStepIntervalStdMs),
      LiveSprintMetricKind.armBalance =>
        math.max(0, value - _config.maximumArmAsymmetryRatio),
      LiveSprintMetricKind.landing =>
        math.max(0, value - _config.maximumOverstrideRatio),
      LiveSprintMetricKind.flightRatio =>
        math.max(0, _config.minimumFlightRatio - value),
      LiveSprintMetricKind.lateForm =>
        math.max(0, value - _config.maximumLateFormDropScore),
      LiveSprintMetricKind.cadence => 0,
    };
  }

  LiveSprintTrendSignal _signalFor({
    required LiveSprintMetricKind kind,
    required double currentGap,
    required double baselineGap,
  }) {
    final change = currentGap - baselineGap;
    final threshold = _meaningfulGapChange(kind);
    if (change <= -threshold) {
      return LiveSprintTrendSignal.improved;
    }
    if (change >= threshold) {
      return LiveSprintTrendSignal.needsAttention;
    }
    return LiveSprintTrendSignal.steady;
  }

  double _meaningfulGapChange(LiveSprintMetricKind kind) {
    return switch (kind) {
      LiveSprintMetricKind.trunkAngle => 0.8,
      LiveSprintMetricKind.kneeDrive => 0.015,
      LiveSprintMetricKind.rhythm => 8,
      LiveSprintMetricKind.armBalance => 0.015,
      LiveSprintMetricKind.landing => 0.02,
      LiveSprintMetricKind.flightRatio => 0.015,
      LiveSprintMetricKind.lateForm => 0.02,
      LiveSprintMetricKind.cadence => double.infinity,
    };
  }

  LiveSprintTrendSummary _summary({
    required LiveSprintTrendStatus status,
    int liveSessionCount = 0,
    RunningCoachSessionAnalysis? currentSession,
    int comparableSessionCount = 0,
    int baselineSessionCount = 0,
    List<LiveSprintMetricTrend> metricTrends = const <LiveSprintMetricTrend>[],
  }) {
    return LiveSprintTrendSummary(
      status: status,
      currentSession: currentSession,
      liveSessionCount: liveSessionCount,
      comparableSessionCount: comparableSessionCount,
      baselineSessionCount: baselineSessionCount,
      requiredComparableSessions: minimumComparableSessions,
      metricTrends: metricTrends,
    );
  }
}

const List<LiveSprintMetricKind> _trendMetricKinds = <LiveSprintMetricKind>[
  LiveSprintMetricKind.trunkAngle,
  LiveSprintMetricKind.kneeDrive,
  LiveSprintMetricKind.rhythm,
  LiveSprintMetricKind.armBalance,
  LiveSprintMetricKind.landing,
  LiveSprintMetricKind.flightRatio,
  LiveSprintMetricKind.lateForm,
];

int _signalPriority(LiveSprintTrendSignal signal) {
  return switch (signal) {
    LiveSprintTrendSignal.needsAttention => 3,
    LiveSprintTrendSignal.improved => 2,
    LiveSprintTrendSignal.steady => 1,
  };
}

double _distanceFromRange(double value, double minimum, double maximum) {
  if (value < minimum) {
    return minimum - value;
  }
  if (value > maximum) {
    return value - maximum;
  }
  return 0;
}

double _average(List<double> values) {
  if (values.isEmpty) {
    return 0;
  }
  return values.reduce((sum, value) => sum + value) / values.length;
}
