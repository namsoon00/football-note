import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_gait_calibration_evaluator.dart';
import 'package:football_note/application/running_live_calibration_capture_contract.dart';
import 'package:football_note/application/running_live_capture_readiness_evaluator.dart';

void main() {
  group('RunningLiveCaptureReadinessEvaluator', () {
    test('accepts a complete compact end capture at the default thresholds',
        () {
      final fixture = GaitCalibrationFixture.fromPredictionSourceString(
        _captureLog(_capturePayload()),
        label: 'live-session-log',
      );

      final report = RunningLiveCaptureReadinessEvaluator().evaluate(fixture);

      expect(
        fixture.format,
        GaitCalibrationInputFormat.runningLiveCalibrationCapture,
      );
      expect(fixture.events, hasLength(12));
      expect(fixture.liveSessionDiagnostics!.hasEndEvent, isTrue);
      expect(fixture.liveSessionDiagnostics!.analyzedFrameIntervalP95Ms, 76);
      expect(report.readinessGate.passed, isTrue);
      expect(report.readinessGate.violations, isEmpty);
      expect(report.toJson()['capture'], isA<Map<String, Object?>>());
    });

    test('reports every failed quality condition before label collection', () {
      final payload = _capturePayload(
        elapsedMs: 2400,
        targetFrameIntervalMs: 120,
        analyzedFrames: 30,
        analyzedFrameIntervalSampleCount: 20,
        analyzedFrameIntervalP95Ms: 135,
        timingConfidence: 0.52,
        sideViewConfidence: 0.61,
        analysisErrorFrames: 1,
        reportedEventCount: 20,
        timelineEventCount: 4,
      );
      final fixture = GaitCalibrationFixture.fromPredictionSourceString(
        _captureLog(payload),
        label: 'live-session-log',
      );

      final report = RunningLiveCaptureReadinessEvaluator().evaluate(fixture);

      expect(report.readinessGate.passed, isFalse);
      expect(
        report.readinessGate.violations.map((violation) => violation.metric),
        [
          'session.elapsedMs',
          'session.targetFrameIntervalMs',
          'metrics.analyzedFrames',
          'metrics.analyzedFrameIntervalMs.sampleCount',
          'metrics.analyzedFrameIntervalMs.p95',
          'metrics.averageConfidence.timing',
          'metrics.averageConfidence.sideView',
          'metrics.skippedFrames.analysisError',
          'events.timelineCount',
        ],
      );
    });

    test('reads terminal diagnostics from the verbose RunningLiveSession log',
        () {
      final payload = _verboseSessionPayload();
      final fixture = GaitCalibrationFixture.fromPredictionSourceString(
        '$runningLiveSessionLogMarker ${jsonEncode(payload)}',
        label: 'live-session-log',
      );

      final report = RunningLiveCaptureReadinessEvaluator().evaluate(fixture);

      expect(fixture.format, GaitCalibrationInputFormat.runningLiveSessionLog);
      expect(fixture.liveSessionDiagnostics!.elapsedMs, 6000);
      expect(fixture.liveSessionDiagnostics!.averageTimingConfidence, 0.82);
      expect(report.readinessGate.passed, isTrue);
    });

    test('requires the final end log even when metrics otherwise pass', () {
      final fixture = GaitCalibrationFixture.fromPredictionSourceString(
        _captureLog(_capturePayload(event: 'periodic')),
        label: 'live-session-log',
      );

      final report = RunningLiveCaptureReadinessEvaluator().evaluate(fixture);

      expect(report.readinessGate.passed, isFalse);
      expect(
        report.readinessGate.violations.map((violation) => violation.metric),
        contains('session.endEvent'),
      );
    });

    test('rejects non-finite programmatic readiness thresholds', () {
      expect(
        () => RunningLiveCaptureReadinessGate(
          maxAnalyzedFrameIntervalP95Ms: double.infinity,
        ),
        throwsArgumentError,
      );
    });
  });

  group('running live capture readiness CLI', () {
    test('prints a machine-readable passing report', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'running_live_capture_readiness_cli_test_',
      );
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });
      final log = File('${tempDir.path}/session.log')
        ..writeAsStringSync(_captureLog(_capturePayload()));

      final result = await Process.run(
        'dart',
        [
          'bin/running_live_capture_readiness.dart',
          '--logs',
          log.path,
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final report =
          jsonDecode(result.stdout as String) as Map<String, Object?>;
      expect(
        (report['readinessGate'] as Map<String, Object?>)['passed'],
        isTrue,
      );
      expect(
        (report['input'] as Map<String, Object?>)['format'],
        'runningLiveCalibrationCapture',
      );
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}

String _captureLog(Map<String, Object?> payload) {
  return 'I/flutter (123): $runningLiveCalibrationCaptureLogMarker '
      '${jsonEncode(payload)}';
}

Map<String, Object?> _capturePayload({
  String event = 'end',
  int elapsedMs = 6000,
  int targetFrameIntervalMs = 50,
  int analyzedFrames = 110,
  int analyzedFrameIntervalSampleCount = 109,
  double analyzedFrameIntervalP95Ms = 76,
  double timingConfidence = 0.82,
  double sideViewConfidence = 0.86,
  int analysisErrorFrames = 0,
  int reportedEventCount = 12,
  int timelineEventCount = 12,
}) {
  return <String, Object?>{
    'schemaVersion': runningLiveCalibrationCaptureSchemaVersion,
    'sessionId': 'running-ready',
    'event': event,
    'elapsedMs': elapsedMs,
    'targetFrameIntervalMs': targetFrameIntervalMs,
    'metrics': <String, Object?>{
      'analyzedFrames': analyzedFrames,
      'analyzedFrameIntervalMs': <String, Object?>{
        'sampleCount': analyzedFrameIntervalSampleCount,
        'p95': analyzedFrameIntervalP95Ms,
      },
      'averageConfidence': <String, Object?>{
        'timing': timingConfidence,
        'sideView': sideViewConfidence,
      },
      'skippedFrames': <String, Object?>{
        'analysisError': analysisErrorFrames,
      },
    },
    'events': <String, Object?>{
      'total': reportedEventCount,
      'timeline': [
        for (var index = 0; index < timelineEventCount; index += 1)
          <Object>[
            100 + index * 150,
            index.isEven ? 'left' : 'right',
            index.isEven ? 'touchdown' : 'toeOff',
            900,
          ],
      ],
    },
  };
}

Map<String, Object?> _verboseSessionPayload() {
  final compact = _capturePayload();
  final compactEvents =
      ((compact['events'] as Map<String, Object?>)['timeline'] as List)
          .cast<List>();
  return <String, Object?>{
    'sessionId': compact['sessionId'],
    'event': compact['event'],
    'elapsedMs': compact['elapsedMs'],
    'targetFrameIntervalMs': compact['targetFrameIntervalMs'],
    'metrics': <String, Object?>{
      'analyzedFrames': compact['metrics'] is Map
          ? ((compact['metrics'] as Map<String, Object?>)['analyzedFrames'])
          : 0,
      'analyzedFrameIntervalMs': <String, Object?>{
        'sampleCount': '109',
        'p95': '76.00',
      },
      'averageConfidence': <String, Object?>{
        'timing': '0.820',
        'sideView': '0.860',
      },
      'skippedFrames': <String, Object?>{'analysisError': 0},
    },
    'events': <String, Object?>{
      'total': 12,
      'timeline': [
        for (final event in compactEvents)
          <String, Object?>{
            'timestampMs': event[0],
            'side': event[1],
            'type': event[2],
          },
      ],
    },
  };
}
