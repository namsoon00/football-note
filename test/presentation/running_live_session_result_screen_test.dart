import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/running_coach_session.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/domain/entities/sprint_realtime_coaching_state.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/running_live_session_result_screen.dart';

void main() {
  testWidgets('shows one readable report for running and sprint outcomes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _LocalizedHarness(
        child: RunningLiveSessionResultScreen(session: _session()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Live sprint report'), findsOneWidget);
    expect(find.text('Saved to coaching history'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('running-live-session-report-focus')),
      findsOneWidget,
    );
    expect(find.text('Next focus'), findsOneWidget);
    await _scrollReport(tester);
    expect(find.text('Sprint mechanics'), findsWidgets);

    await _scrollReport(tester);
    expect(find.text('Analysis quality'), findsOneWidget);
    await _scrollReport(tester);
    expect(find.text('Gait events'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('explains when the session did not stabilize enough to score', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final session = RunningCoachSessionAnalysis(
      id: 'live-short',
      analyzedAt: DateTime(2026, 7, 21, 10),
      source: RunningCoachSessionSource.sprintLive,
      overallScore: 0,
      duration: const Duration(seconds: 2),
      sampledFrames: 10,
      validFrames: 3,
      primaryMetric: RunningCoachMetric.posture,
      primaryFinding: RunningCoachFinding.postureAligned,
      primaryStatus: RunningCoachStatus.watch,
      primaryScore: 0,
      primaryValue: 0,
      primaryConfidence: 0,
      liveSprintReport: const LiveSprintSessionReport(
        runningTrackedFrames: 3,
        runningAnalyzedFrames: 10,
        sprintTrackedFrames: 0,
        sprintAnalyzedFrames: 0,
        touchdownEvents: 0,
        toeOffEvents: 0,
        detectedSteps: 0,
        landingEvents: 0,
        feedbackChanges: 0,
        timingConfidence: 0.2,
        sideViewConfidence: 0.2,
        sprintTrackingConfidence: 0.2,
        bodyNotVisibleRatio: 0.7,
        status: SprintCoachingStatus.lowConfidence,
        trackingReadiness: SprintTrackingReadiness.bodyTooSmall,
        feedbackCode: null,
        feedbackSeverity: null,
        feedbackConfidence: 0,
        metrics: <LiveSprintMetricSummary>[],
      ),
    );

    await tester.pumpWidget(
      _LocalizedHarness(
        child: RunningLiveSessionResultScreen(
          session: session,
          isPersisted: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Form score unavailable'), findsOneWidget);
    await _scrollReport(tester);
    expect(
      find.text(
        'There was not enough stable signal to summarize sprint mechanics. Keep the same framing for a few more steps, then finish again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Saved to coaching history'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

RunningCoachSessionAnalysis _session() {
  return RunningCoachSessionAnalysis(
    id: 'live-report',
    analyzedAt: DateTime(2026, 7, 21, 10, 30),
    source: RunningCoachSessionSource.sprintLive,
    overallScore: 76,
    duration: const Duration(seconds: 18),
    sampledFrames: 200,
    validFrames: 176,
    primaryMetric: RunningCoachMetric.footStrike,
    primaryFinding: RunningCoachFinding.footStrikeOverstride,
    primaryStatus: RunningCoachStatus.needsWork,
    primaryScore: 58,
    primaryValue: 0.23,
    primaryConfidence: 0.82,
    metricSnapshots: const <RunningCoachSessionMetric>[
      RunningCoachSessionMetric(
        metric: RunningCoachMetric.footStrike,
        finding: RunningCoachFinding.footStrikeOverstride,
        status: RunningCoachStatus.needsWork,
        score: 58,
        value: 0.23,
        confidence: 0.82,
        sampleCount: 20,
      ),
      RunningCoachSessionMetric(
        metric: RunningCoachMetric.posture,
        finding: RunningCoachFinding.postureAligned,
        status: RunningCoachStatus.good,
        score: 87,
        value: 12,
        confidence: 0.88,
        sampleCount: 20,
      ),
    ],
    liveSprintReport: const LiveSprintSessionReport(
      runningTrackedFrames: 176,
      runningAnalyzedFrames: 200,
      sprintTrackedFrames: 72,
      sprintAnalyzedFrames: 72,
      touchdownEvents: 8,
      toeOffEvents: 8,
      detectedSteps: 8,
      landingEvents: 6,
      feedbackChanges: 3,
      timingConfidence: 0.85,
      sideViewConfidence: 0.8,
      sprintTrackingConfidence: 0.82,
      bodyNotVisibleRatio: 0.05,
      status: SprintCoachingStatus.coaching,
      trackingReadiness: SprintTrackingReadiness.readyForAnalysis,
      feedbackCode: SprintFeedbackCode.landUnderHips,
      feedbackSeverity: SprintFeedbackSeverity.warning,
      feedbackConfidence: 0.84,
      metrics: <LiveSprintMetricSummary>[
        LiveSprintMetricSummary(
          kind: LiveSprintMetricKind.cadence,
          value: 218,
          confidence: 0.84,
          sampleCount: 8,
        ),
        LiveSprintMetricSummary(
          kind: LiveSprintMetricKind.landing,
          value: 0.22,
          secondaryValue: 68,
          confidence: 0.82,
          sampleCount: 6,
        ),
        LiveSprintMetricSummary(
          kind: LiveSprintMetricKind.trunkAngle,
          value: 12.4,
          confidence: 0.8,
          sampleCount: 12,
        ),
      ],
    ),
  );
}

class _LocalizedHarness extends StatelessWidget {
  final Widget child;

  const _LocalizedHarness({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}

Future<void> _scrollReport(WidgetTester tester) async {
  final reportList = find.byKey(
    const ValueKey('running-live-session-report-list'),
  );
  await tester.drag(reportList, const Offset(0, -520));
  await tester.pumpAndSettle();
}
