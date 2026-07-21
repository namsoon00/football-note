import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/live_sprint_trend_service.dart';
import 'package:football_note/domain/entities/running_coach_session.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/domain/entities/sprint_realtime_coaching_state.dart';

void main() {
  const service = LiveSprintTrendService();

  test('compares stable sessions by movement toward coaching targets', () {
    final summary = service.build(<RunningCoachSessionAnalysis>[
      _session(
        id: 'current',
        at: DateTime(2026, 7, 3),
        values: const <LiveSprintMetricKind, double>{
          LiveSprintMetricKind.trunkAngle: 10,
          LiveSprintMetricKind.kneeDrive: 0.35,
          LiveSprintMetricKind.landing: 0.44,
          LiveSprintMetricKind.rhythm: 125,
          LiveSprintMetricKind.cadence: 220,
        },
      ),
      _session(
        id: 'baseline-newer',
        at: DateTime(2026, 7, 2),
        values: const <LiveSprintMetricKind, double>{
          LiveSprintMetricKind.trunkAngle: 6,
          LiveSprintMetricKind.kneeDrive: 0.31,
          LiveSprintMetricKind.landing: 0.39,
          LiveSprintMetricKind.rhythm: 102,
          LiveSprintMetricKind.cadence: 205,
        },
      ),
      _session(
        id: 'baseline-older',
        at: DateTime(2026, 7, 1),
        values: const <LiveSprintMetricKind, double>{
          LiveSprintMetricKind.trunkAngle: 5,
          LiveSprintMetricKind.kneeDrive: 0.30,
          LiveSprintMetricKind.landing: 0.38,
          LiveSprintMetricKind.rhythm: 100,
          LiveSprintMetricKind.cadence: 198,
        },
      ),
    ]);

    expect(summary.status, LiveSprintTrendStatus.ready);
    expect(summary.baselineSessionCount, 2);
    expect(
      _trendFor(summary, LiveSprintMetricKind.trunkAngle).signal,
      LiveSprintTrendSignal.improved,
    );
    expect(
      _trendFor(summary, LiveSprintMetricKind.kneeDrive).signal,
      LiveSprintTrendSignal.steady,
    );
    expect(
      _trendFor(summary, LiveSprintMetricKind.landing).signal,
      LiveSprintTrendSignal.needsAttention,
    );
    expect(
      _trendFor(summary, LiveSprintMetricKind.rhythm).signal,
      LiveSprintTrendSignal.needsAttention,
    );
    expect(
      summary.metricTrends
          .where((trend) => trend.kind == LiveSprintMetricKind.cadence),
      isEmpty,
    );
  });

  test('does not compare a low-quality current capture to good history', () {
    final summary = service.build(<RunningCoachSessionAnalysis>[
      _session(
        id: 'current-low-quality',
        at: DateTime(2026, 7, 3),
        qualitySufficient: false,
      ),
      _session(id: 'baseline-newer', at: DateTime(2026, 7, 2)),
      _session(id: 'baseline-older', at: DateTime(2026, 7, 1)),
    ]);

    expect(summary.status, LiveSprintTrendStatus.captureQualityLow);
    expect(summary.metricTrends, isEmpty);
  });

  test('asks for one additional stable session before forming a trend', () {
    final summary = service.build(<RunningCoachSessionAnalysis>[
      _session(id: 'current', at: DateTime(2026, 7, 2)),
      _session(id: 'baseline', at: DateTime(2026, 7, 1)),
    ]);

    expect(summary.status, LiveSprintTrendStatus.needsMoreSessions);
    expect(summary.additionalStableSessionsNeeded, 1);
  });

  test('uses only history at or before the selected session', () {
    final summary = service.build(
      <RunningCoachSessionAnalysis>[
        _session(id: 'newer', at: DateTime(2026, 7, 4)),
        _session(id: 'selected', at: DateTime(2026, 7, 3)),
        _session(id: 'baseline-newer', at: DateTime(2026, 7, 2)),
        _session(id: 'baseline-older', at: DateTime(2026, 7, 1)),
      ],
      currentSessionId: 'selected',
    );

    expect(summary.status, LiveSprintTrendStatus.ready);
    expect(summary.currentSession!.id, 'selected');
    expect(summary.baselineSessionCount, 2);
  });
}

LiveSprintMetricTrend _trendFor(
  LiveSprintTrendSummary summary,
  LiveSprintMetricKind kind,
) {
  return summary.metricTrends.singleWhere((trend) => trend.kind == kind);
}

RunningCoachSessionAnalysis _session({
  required String id,
  required DateTime at,
  Map<LiveSprintMetricKind, double> values =
      const <LiveSprintMetricKind, double>{
    LiveSprintMetricKind.trunkAngle: 12,
    LiveSprintMetricKind.kneeDrive: 0.32,
    LiveSprintMetricKind.landing: 0.30,
    LiveSprintMetricKind.rhythm: 80,
  },
  bool qualitySufficient = true,
}) {
  return RunningCoachSessionAnalysis(
    id: id,
    analyzedAt: at,
    source: RunningCoachSessionSource.sprintLive,
    overallScore: 78,
    duration: const Duration(seconds: 14),
    sampledFrames: 180,
    validFrames: 160,
    primaryMetric: RunningCoachMetric.footStrike,
    primaryFinding: RunningCoachFinding.footStrikeOverstride,
    primaryStatus: RunningCoachStatus.watch,
    primaryScore: 74,
    primaryValue: 0.2,
    primaryConfidence: 0.85,
    liveSprintReport: LiveSprintSessionReport(
      runningTrackedFrames: 160,
      runningAnalyzedFrames: 180,
      sprintTrackedFrames: qualitySufficient ? 60 : 5,
      sprintAnalyzedFrames: qualitySufficient ? 60 : 5,
      touchdownEvents: qualitySufficient ? 8 : 1,
      toeOffEvents: qualitySufficient ? 8 : 1,
      detectedSteps: qualitySufficient ? 8 : 1,
      landingEvents: qualitySufficient ? 6 : 1,
      feedbackChanges: 2,
      timingConfidence: qualitySufficient ? 0.86 : 0.3,
      sideViewConfidence: qualitySufficient ? 0.84 : 0.3,
      sprintTrackingConfidence: qualitySufficient ? 0.82 : 0.3,
      bodyNotVisibleRatio: qualitySufficient ? 0.08 : 0.6,
      status: qualitySufficient
          ? SprintCoachingStatus.coaching
          : SprintCoachingStatus.lowConfidence,
      trackingReadiness: qualitySufficient
          ? SprintTrackingReadiness.readyForAnalysis
          : SprintTrackingReadiness.lowConfidence,
      feedbackCode: null,
      feedbackSeverity: null,
      feedbackConfidence: 0,
      metrics: values.entries
          .map(
            (entry) => LiveSprintMetricSummary(
              kind: entry.key,
              value: entry.value,
              confidence: qualitySufficient ? 0.86 : 0.3,
              sampleCount: qualitySufficient ? 10 : 1,
            ),
          )
          .toList(growable: false),
    ),
  );
}
