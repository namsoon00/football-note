import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/running_capture_screen.dart';

void main() {
  test('allows a 60-second recording by default', () {
    const screen = RunningCaptureScreen();

    expect(screen.maximumDuration, const Duration(seconds: 60));
  });

  testWidgets('shows a recoverable state when no camera is available', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: RunningCaptureScreen(cameraProvider: () async => []),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No camera is available.'), findsOneWidget);
    expect(find.text('Open camera again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the selected runner in capture', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        RunningCaptureScreen(
          runnerDisplayName: 'Minjun',
          cameraProvider: () async => const <CameraDescription>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('running-coach-capture-runner-name')),
      findsOneWidget,
    );
    expect(find.text('Analysis target: Minjun'), findsOneWidget);
  });

  testWidgets('framing status panel stays readable at 320px portrait', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _localizedApp(
        runningCaptureFramingStatusPanelForTesting(
          poseFrame: _sideViewPoseFrame(),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('running-capture-framing-status-panel')),
      findsOneWidget,
    );
    expect(find.text('Smart framing'), findsOneWidget);
    expect(find.text('Body inside guide'), findsOneWidget);
    expect(find.text('Good runner size'), findsOneWidget);
    expect(find.text('Side view'), findsOneWidget);
    expect(find.text('Clarity not measured'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('framing status panel stays readable at normal phone width', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _localizedApp(
        runningCaptureFramingStatusPanelForTesting(
          poseFrame: _sideViewPoseFrame(),
        ),
      ),
    );

    expect(find.text('6/6 ready'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('running-capture-framing-fullBodySafe')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('framing status confirms stable clear live pose samples', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _localizedApp(
        runningCaptureFramingStatusPanelForTesting(
          previousPoseFrame: _sideViewPoseFrame(offsetX: -0.004),
          poseFrame: _sideViewPoseFrame(offsetX: 0.004),
        ),
      ),
    );

    expect(find.text('7/7 ready'), findsOneWidget);
    expect(find.text('Clear and steady'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('framing status warns on low-confidence blur or occlusion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _localizedApp(
        runningCaptureFramingStatusPanelForTesting(
          previousPoseFrame: _sideViewPoseFrame(),
          poseFrame: _sideViewPoseFrame(confidence: 0.45),
        ),
      ),
    );

    expect(find.text('6/7 ready'), findsOneWidget);
    expect(find.text('Improve light; avoid blur or blocking'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fallback framing status does not claim pose checks', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _localizedApp(
        runningCaptureFramingStatusPanelForTesting(
          poseFrame: null,
          livePoseUnavailable: true,
        ),
      ),
    );

    expect(
      find.text(
        'Live pose checks are unavailable here, so only device and preview checks are shown.',
      ),
      findsOneWidget,
    );
    expect(find.text('Body not measured'), findsOneWidget);
    expect(find.text('Size not measured'), findsOneWidget);
    expect(find.text('Side view not measured'), findsOneWidget);
  });
}

Widget _localizedApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

RunningPoseFrame _sideViewPoseFrame({
  double offsetX = 0,
  double confidence = 0.95,
}) {
  final landmarks = List<RunningVideoPoseLandmark>.generate(
    mediaPipePoseLandmarkCount,
    (index) => RunningVideoPoseLandmark(
      index: index,
      x: 0.50 + offsetX,
      y: 0.50,
      z: 0,
      visibility: confidence,
      presence: confidence,
      confidence: confidence,
    ),
  );
  void setLandmark(int index, double x, double y) {
    landmarks[index] = RunningVideoPoseLandmark(
      index: index,
      x: x + offsetX,
      y: y,
      z: 0,
      visibility: confidence,
      presence: confidence,
      confidence: confidence,
    );
  }

  setLandmark(0, 0.50, 0.12);
  setLandmark(11, 0.49, 0.25);
  setLandmark(12, 0.51, 0.25);
  setLandmark(23, 0.50, 0.50);
  setLandmark(24, 0.515, 0.50);
  setLandmark(25, 0.52, 0.68);
  setLandmark(26, 0.535, 0.69);
  setLandmark(27, 0.53, 0.82);
  setLandmark(28, 0.545, 0.83);
  setLandmark(29, 0.515, 0.87);
  setLandmark(30, 0.535, 0.88);
  setLandmark(31, 0.55, 0.87);
  setLandmark(32, 0.57, 0.88);

  return RunningPoseFrame(
    timestamp: Duration.zero,
    imageWidth: 720,
    imageHeight: 1280,
    landmarks: List<RunningVideoPoseLandmark>.unmodifiable(landmarks),
  );
}
