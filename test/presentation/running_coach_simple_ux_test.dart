import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_coach_history_service.dart';
import 'package:football_note/application/running_coach_runner_profile_service.dart';
import 'package:football_note/domain/entities/running_coach_session.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/running_coach_screen.dart';

void main() {
  testWidgets(
      'single runner stays implicit while multi-runner identity is clear',
      (tester) async {
    final singleRepository = _MemoryOptionRepository();
    await tester.pumpWidget(
      _app(RunningCoachScreen(optionRepository: singleRepository)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('running-coach-single-runner-identity')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-runner-switcher')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('running-coach-capture-and-analyze-action')),
      findsOneWidget,
    );

    final multiRepository = _MemoryOptionRepository();
    final profileService = RunningCoachRunnerProfileService(multiRepository);
    await profileService.ensureDefaultRunner(defaultDisplayName: 'Me');
    final minjun = await profileService.addRunner(
      displayName: 'Minjun',
      defaultDisplayName: 'Me',
      createdAt: DateTime(2026, 8, 10),
    );
    final fixture = _fixture();
    await multiRepository.setValue(
      RunningCoachHistoryService.storageKey,
      jsonEncode(<Map<String, Object?>>[
        fixture.session.copyWith(runnerId: minjun.id).toMap(),
      ]),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      _app(RunningCoachScreen(optionRepository: multiRepository)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('running-coach-runner-switcher')),
      findsOneWidget,
    );
    expect(find.text('Analysis target: Minjun'), findsOneWidget);
    await tester.tap(find.text('All 1'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('running-coach-history-runner-name')),
      findsOneWidget,
    );
    expect(find.text('Analysis target: Minjun'), findsWidgets);
  });

  testWidgets('simple result prioritizes identity, real evidence, cue and grid',
      (tester) async {
    final fixture = _fixture();
    await tester.pumpWidget(
      _app(
        runningAnalysisResultScreenForTesting(
          result: fixture.result,
          report: fixture.report,
          session: fixture.session,
          runnerDisplayName: 'Minjun',
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('running-coach-result-runner-name')),
      findsOneWidget,
    );
    expect(find.textContaining('Minjun'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('running-coach-primary-real-evidence')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('running-coach-primary-cue')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const ValueKey('running-coach-analysis-result-list')),
      const Offset(0, -420),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('running-coach-compact-metric-grid')),
      findsOneWidget,
    );
    for (final metric in RunningCoachMetric.values) {
      expect(
        find.byKey(ValueKey('running-coach-metric-tile-${metric.name}')),
        findsOneWidget,
      );
    }
    expect(find.text('9.0°'), findsNothing);
    expect(
      find.byKey(const ValueKey('running-coach-evidence-archive-status')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('running-coach-rhythm-card')),
      findsNothing,
    );
  });

  testWidgets('metric tap opens one sheet and keeps raw values collapsed',
      (tester) async {
    final fixture = _fixture();
    await tester.pumpWidget(
      _app(
        runningAnalysisResultScreenForTesting(
          result: fixture.result,
          report: fixture.report,
          session: fixture.session,
        ),
      ),
    );
    await tester.pump();

    await tester.drag(
      find.byKey(const ValueKey('running-coach-analysis-result-list')),
      const Offset(0, -420),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('running-coach-metric-tile-posture')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('running-coach-metric-detail-sheet')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('running-coach-metric-detail-real-evidence'),
      ),
      findsOneWidget,
    );
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('9.0°'), findsNothing);
    await tester.drag(
      find.byKey(const ValueKey('running-coach-metric-detail-sheet')),
      const Offset(0, -420),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('running-coach-raw-measurement-expansion')),
      findsOneWidget,
    );
  });

  testWidgets('result has no overflow at 320px with large text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _fixture();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: _app(
          runningAnalysisResultScreenForTesting(
            result: fixture.result,
            report: fixture.report,
            session: fixture.session,
            runnerDisplayName: 'A very long runner name for accessibility',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('running-coach-score-hero')),
      findsOneWidget,
    );
  });
}

({
  RunningVideoAnalysisResult result,
  RunningCoachingReport report,
  RunningCoachSessionAnalysis session,
}) _fixture() {
  const qualities = <RunningCoachMetric, RunningMetricQuality>{
    RunningCoachMetric.posture:
        RunningMetricQuality(confidence: 0.9, sampleCount: 8),
    RunningCoachMetric.bounce:
        RunningMetricQuality(confidence: 0.9, sampleCount: 8),
    RunningCoachMetric.footStrike:
        RunningMetricQuality(confidence: 0.9, sampleCount: 8),
    RunningCoachMetric.kneeFlexion:
        RunningMetricQuality(confidence: 0.9, sampleCount: 8),
    RunningCoachMetric.armCarriage:
        RunningMetricQuality(confidence: 0.9, sampleCount: 8),
  };
  final insights = <RunningCoachingInsight>[
    RunningCoachingInsight(
      metric: RunningCoachMetric.posture,
      finding: RunningCoachFinding.postureTooUpright,
      status: RunningCoachStatus.needsWork,
      score: 62,
      value: 9,
      quality: qualities[RunningCoachMetric.posture]!,
    ),
    RunningCoachingInsight(
      metric: RunningCoachMetric.bounce,
      finding: RunningCoachFinding.bounceEfficient,
      status: RunningCoachStatus.good,
      score: 90,
      value: 6,
      quality: qualities[RunningCoachMetric.bounce]!,
    ),
    RunningCoachingInsight(
      metric: RunningCoachMetric.footStrike,
      finding: RunningCoachFinding.footStrikeUnderBody,
      status: RunningCoachStatus.good,
      score: 88,
      value: 0.12,
      quality: qualities[RunningCoachMetric.footStrike]!,
    ),
    RunningCoachingInsight(
      metric: RunningCoachMetric.kneeFlexion,
      finding: RunningCoachFinding.kneeFlexionLoaded,
      status: RunningCoachStatus.good,
      score: 88,
      value: 150,
      quality: qualities[RunningCoachMetric.kneeFlexion]!,
    ),
    RunningCoachingInsight(
      metric: RunningCoachMetric.armCarriage,
      finding: RunningCoachFinding.armCompact,
      status: RunningCoachStatus.good,
      score: 90,
      value: 90,
      quality: qualities[RunningCoachMetric.armCarriage]!,
    ),
  ];
  const result = RunningVideoAnalysisResult(
    analysisVersion: 2,
    videoDuration: Duration(seconds: 5),
    sampledFrames: 18,
    validFrames: 16,
    direction: RunningDirection.leftToRight,
    forwardLeanDegrees: 9,
    verticalBounceRatio: 0.06,
    footStrikeDistanceRatio: 0.12,
    stanceKneeAngleDegrees: 150,
    elbowAngleDegrees: 90,
    metricQualities: qualities,
  );
  final report = RunningCoachingReport(
    overallScore: 82,
    insights: insights,
  );
  final session = RunningCoachSessionAnalysis(
    id: 'simple-result',
    runnerId: 'runner-minjun',
    analyzedAt: DateTime.now(),
    source: RunningCoachSessionSource.uploadVideo,
    overallScore: 82,
    scoreEligibility: RunningCoachScoreEligibility.verified,
    scoreVersion: RunningCoachHistoryService.runningScoreVersion,
    analysisVersion: 2,
    duration: const Duration(seconds: 5),
    sampledFrames: 18,
    validFrames: 16,
    primaryMetric: RunningCoachMetric.posture,
    primaryFinding: RunningCoachFinding.postureTooUpright,
    primaryStatus: RunningCoachStatus.needsWork,
    primaryScore: 62,
    primaryValue: 9,
    primaryConfidence: 0.9,
    evidenceImages: const <RunningCoachEvidenceImage>[
      RunningCoachEvidenceImage(
        id: 'real-posture-frame',
        timestamp: Duration(milliseconds: 900),
        kind: RunningMetricEvidenceKind.posture,
        role: RunningMetricEvidenceFrameRole.representativePosture,
        storageReference: '/missing/real-posture-frame.jpg',
        confidence: 0.9,
      ),
    ],
    evidenceArchive: const RunningCoachEvidenceArchiveSummary(
      requestedCount: 1,
      savedCount: 1,
      status: RunningCoachEvidenceArchiveStatus.success,
    ),
  );
  return (result: result, report: report, session: session);
}

Widget _app(Widget home) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, Object?> values = <String, Object?>{};

  @override
  List<int> getIntOptions(String key, List<int> defaults) => defaults;

  @override
  List<String> getOptions(String key, List<String> defaults) => defaults;

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
