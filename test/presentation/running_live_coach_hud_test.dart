import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/running_coach_session.dart';
import 'package:football_note/domain/entities/sprint_capture_calibration_profile.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/running_live_coach_screen.dart';

void main() {
  testWidgets('compact HUD fits a 320px wide mobile viewport', (tester) async {
    await _pumpHud(tester, size: const Size(320, 640), compact: true);

    final hudSize = tester.getSize(
      find.byKey(const ValueKey('running-live-coach-compact-hud')),
    );
    expect(hudSize.height, inInclusiveRange(96, 140));
    expect(
      find.byKey(const ValueKey('running-live-coach-expanded-scroll')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('expanded HUD remains scrollable in short landscape', (
    tester,
  ) async {
    await _pumpHud(
      tester,
      size: const Size(640, 320),
      compact: true,
      initiallyExpanded: true,
      maxExpandedHeight: 176,
    );

    expect(
      find.byKey(const ValueKey('running-live-coach-expanded-scroll')),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byType(AnimatedSize)).height,
      lessThanOrEqualTo(176),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact HUD tolerates 2.0 text scale without overflow', (
    tester,
  ) async {
    await _pumpHud(
      tester,
      size: const Size(320, 480),
      compact: true,
      textScale: 2,
    );

    final hudSize = tester.getSize(
      find.byKey(const ValueKey('running-live-coach-compact-hud')),
    );
    expect(hudSize.height, inInclusiveRange(96, 140));
    expect(tester.takeException(), isNull);
  });

  testWidgets('HUD expands and collapses with localized controls', (
    tester,
  ) async {
    await _pumpHud(tester, size: const Size(390, 720));

    expect(find.byKey(const ValueKey('running-live-coach-test-details')),
        findsNothing);

    await tester.tap(find.byTooltip('Show details'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('running-live-coach-test-details')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Hide details'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('running-live-coach-test-details')),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cue banner exposes a screen reader live region', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        const _LocalizedHarness(
          child: Center(
            child: SizedBox(
              width: 320,
              child: RunningLiveCoachCueBanner(
                icon: Icons.check_circle_rounded,
                color: Colors.greenAccent,
                background: Colors.black,
                title: 'Live coaching active',
                body: 'Keep this rhythm.',
              ),
            ),
          ),
        ),
      );

      final node = tester.getSemantics(
        find.bySemanticsLabel('Live coaching active. Keep this rhythm.'),
      );
      expect(node.flagsCollection.isLiveRegion, isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('voice toggle exposes button and toggled semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var enabled = true;
    try {
      await tester.pumpWidget(
        _LocalizedHarness(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Center(
                child: RunningLiveCoachVoiceToggleButton(
                  isSpeechEnabled: enabled,
                  onToggleSpeech: () {
                    setState(() {
                      enabled = !enabled;
                    });
                  },
                ),
              );
            },
          ),
        ),
      );

      var node = tester.getSemantics(
        find.byKey(const ValueKey('running-live-coach-voice-toggle-semantics')),
      );
      expect(node.label, 'Voice coaching');
      expect(node.hint, 'Double tap to mute voice cues.');
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isToggled, isNot(ui.Tristate.none));
      expect(node.flagsCollection.isToggled, ui.Tristate.isTrue);

      await tester.tap(find.byTooltip('Turn voice coaching off'));
      await tester.pump();

      node = tester.getSemantics(
        find.byKey(const ValueKey('running-live-coach-voice-toggle-semantics')),
      );
      expect(node.hint, 'Double tap to hear voice cues.');
      expect(node.flagsCollection.isToggled, isNot(ui.Tristate.none));
      expect(node.flagsCollection.isToggled, ui.Tristate.isFalse);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('calibration panel fits a 320px mobile viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SprintCaptureCalibrationProfile? changedProfile;

    await tester.pumpWidget(
      _LocalizedHarness(
        child: Center(
          child: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: RunningLiveSprintCalibrationPanel(
                selectedProfile: SprintCaptureCalibrationProfile.balanced,
                onProfileChanged: (profile) => changedProfile = profile,
                diagnostic: _captureDiagnostic(),
                compact: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('running-live-sprint-calibration-profile-selector'),
      ),
      findsOneWidget,
    );
    expect(find.text('Balanced'), findsOneWidget);
    expect(find.text('Capture readiness'), findsOneWidget);
    expect(find.text('Framing'), findsOneWidget);
    expect(find.text('Side view'), findsOneWidget);
    expect(find.text('Core joints'), findsOneWidget);
    expect(find.text('Gait phase'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey('running-live-sprint-calibration-profile-selector'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Responsive').last);
    await tester.pumpAndSettle();
    expect(changedProfile, SprintCaptureCalibrationProfile.responsive);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHud(
  WidgetTester tester, {
  required Size size,
  bool compact = false,
  bool initiallyExpanded = false,
  double textScale = 1,
  double maxExpandedHeight = 360,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    _LocalizedHarness(
      textScale: textScale,
      child: Center(
        child: SizedBox(
          width: size.width,
          child: _HudHarness(
            compact: compact,
            initiallyExpanded: initiallyExpanded,
            maxExpandedHeight: maxExpandedHeight,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _HudHarness extends StatefulWidget {
  final bool compact;
  final bool initiallyExpanded;
  final double maxExpandedHeight;

  const _HudHarness({
    required this.compact,
    required this.initiallyExpanded,
    required this.maxExpandedHeight,
  });

  @override
  State<_HudHarness> createState() => _HudHarnessState();
}

class _HudHarnessState extends State<_HudHarness> {
  late bool _isExpanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return RunningLiveCoachHud(
      compact: widget.compact,
      isExpanded: _isExpanded,
      statusTitle: 'Collecting movement',
      scoreLabel: 'Scoring...',
      cueText:
          'Keep the same rhythm for a few more steps while the coach reads.',
      maxExpandedHeight: widget.maxExpandedHeight,
      onToggleExpanded: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      expandedDetails: const _TestHudDetails(),
    );
  }
}

class _TestHudDetails extends StatelessWidget {
  const _TestHudDetails();

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: ValueKey('running-live-coach-test-details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gait detail', style: TextStyle(color: Colors.white)),
        SizedBox(height: 120),
        Text('Metric detail', style: TextStyle(color: Colors.white)),
        SizedBox(height: 120),
        Text('Diagnosis detail', style: TextStyle(color: Colors.white)),
      ],
    );
  }
}

LiveSprintPoseEvidenceDiagnostic _captureDiagnostic() {
  return const LiveSprintPoseEvidenceDiagnostic(
    evaluatedFrames: 24,
    eligibleFrames: 7,
    capturedPhaseCount: 1,
    fullBodyBlockedFrames: 2,
    sideViewBlockedFrames: 4,
    coreJointsBlockedFrames: 8,
    gaitPhaseBlockedFrames: 3,
    currentBlocker: LiveSprintPoseEvidenceBlocker.observedCoreJoints,
    readinessSummary: LiveSprintCaptureReadinessSummary(
      framing: LiveSprintCaptureReadinessCheck(
        ready: true,
        value: 1,
        threshold: 1,
      ),
      sideView: LiveSprintCaptureReadinessCheck(
        ready: true,
        value: 0.72,
        threshold: 0.65,
      ),
      coreJointConfidence: LiveSprintCaptureReadinessCheck(
        ready: false,
        value: 0.61,
        threshold: 0.70,
        observedCount: 12,
        requiredCount: 15,
      ),
      gaitPhase: LiveSprintCaptureReadinessCheck(
        ready: true,
        value: 0.76,
        threshold: 0.62,
      ),
    ),
  );
}

class _LocalizedHarness extends StatelessWidget {
  final Widget child;
  final double textScale;

  const _LocalizedHarness({required this.child, this.textScale = 1});

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
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: child,
        ),
      ),
    );
  }
}
