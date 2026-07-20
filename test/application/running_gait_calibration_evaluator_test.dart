import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_gait_calibration_evaluator.dart';

void main() {
  group('GaitCalibrationEvaluator', () {
    test('reports perfect metrics for exact event matches', () {
      final events = <GaitCalibrationEvent>[
        _event(100, GaitCalibrationFootSide.left,
            GaitCalibrationEventType.touchdown, 0),
        _event(
          220,
          GaitCalibrationFootSide.left,
          GaitCalibrationEventType.toeOff,
          1,
        ),
        _event(360, GaitCalibrationFootSide.right,
            GaitCalibrationEventType.touchdown, 2),
        _event(
          480,
          GaitCalibrationFootSide.right,
          GaitCalibrationEventType.toeOff,
          3,
        ),
      ];

      final report = const GaitCalibrationEvaluator(
        toleranceMs: 40,
      ).evaluate(groundTruth: events, predictions: events);

      expect(report.overall.truePositive, 4);
      expect(report.overall.falsePositive, 0);
      expect(report.overall.falseNegative, 0);
      expect(report.overall.precision, 1);
      expect(report.overall.recall, 1);
      expect(report.overall.f1, 1);
      expect(report.overall.signedBiasMs, 0);
      expect(report.overall.meanAbsoluteErrorMs, 0);
      expect(report.overall.p95AbsoluteErrorMs, 0);
      expect(
        report.byEventType[GaitCalibrationEventType.touchdown]!.truePositive,
        2,
      );
      expect(
        report.byEventType[GaitCalibrationEventType.toeOff]!.truePositive,
        2,
      );
    });

    test('matches jittered events within tolerance and reports timing errors',
        () {
      final groundTruth = <GaitCalibrationEvent>[
        _event(1000, GaitCalibrationFootSide.left,
            GaitCalibrationEventType.touchdown, 0),
        _event(
          1120,
          GaitCalibrationFootSide.left,
          GaitCalibrationEventType.toeOff,
          1,
        ),
        _event(1500, GaitCalibrationFootSide.right,
            GaitCalibrationEventType.touchdown, 2),
      ];
      final predictions = <GaitCalibrationEvent>[
        _event(1010, GaitCalibrationFootSide.left,
            GaitCalibrationEventType.touchdown, 0),
        _event(
          1175,
          GaitCalibrationFootSide.left,
          GaitCalibrationEventType.toeOff,
          1,
        ),
        _event(1480, GaitCalibrationFootSide.right,
            GaitCalibrationEventType.touchdown, 2),
      ];

      final report = const GaitCalibrationEvaluator(
        toleranceMs: 80,
      ).evaluate(groundTruth: groundTruth, predictions: predictions);

      expect(report.overall.truePositive, 3);
      expect(report.overall.signedBiasMs, 15);
      expect(report.overall.meanAbsoluteErrorMs, closeTo(28.333, 0.001));
      expect(report.overall.p95AbsoluteErrorMs, 55);
      expect(report.matches.map((match) => match.signedErrorMs), [
        10,
        55,
        -20,
      ]);
    });

    test('maximizes one-to-one matches before minimizing timing error', () {
      final groundTruth = <GaitCalibrationEvent>[
        _event(100, GaitCalibrationFootSide.left,
            GaitCalibrationEventType.touchdown, 0),
        _event(160, GaitCalibrationFootSide.left,
            GaitCalibrationEventType.touchdown, 1),
      ];
      final predictions = <GaitCalibrationEvent>[
        _event(40, GaitCalibrationFootSide.left,
            GaitCalibrationEventType.touchdown, 0),
        _event(120, GaitCalibrationFootSide.left,
            GaitCalibrationEventType.touchdown, 1),
      ];

      final report = const GaitCalibrationEvaluator(
        toleranceMs: 60,
      ).evaluate(groundTruth: groundTruth, predictions: predictions);

      expect(report.overall.truePositive, 2);
      expect(report.overall.falsePositive, 0);
      expect(report.overall.falseNegative, 0);
      expect(report.matches.map((match) => match.signedErrorMs), [-60, -40]);
    });

    test('minimizes total timing error when match counts are equal', () {
      final groundTruth = <GaitCalibrationEvent>[
        _event(100, GaitCalibrationFootSide.right,
            GaitCalibrationEventType.toeOff, 0),
        _event(200, GaitCalibrationFootSide.right,
            GaitCalibrationEventType.toeOff, 1),
      ];
      final predictions = <GaitCalibrationEvent>[
        _event(90, GaitCalibrationFootSide.right,
            GaitCalibrationEventType.toeOff, 0),
        _event(130, GaitCalibrationFootSide.right,
            GaitCalibrationEventType.toeOff, 1),
        _event(210, GaitCalibrationFootSide.right,
            GaitCalibrationEventType.toeOff, 2),
      ];

      final report = const GaitCalibrationEvaluator(
        toleranceMs: 50,
      ).evaluate(groundTruth: groundTruth, predictions: predictions);

      expect(report.overall.truePositive, 2);
      expect(report.overall.meanAbsoluteErrorMs, 10);
      expect(report.matches.map((match) => match.signedErrorMs), [-10, 10]);
    });

    test('counts missing ground truth and extra predictions', () {
      final groundTruth = <GaitCalibrationEvent>[
        _event(100, GaitCalibrationFootSide.left,
            GaitCalibrationEventType.touchdown, 0),
        _event(
          180,
          GaitCalibrationFootSide.left,
          GaitCalibrationEventType.toeOff,
          1,
        ),
        _event(300, GaitCalibrationFootSide.right,
            GaitCalibrationEventType.touchdown, 2),
      ];
      final predictions = <GaitCalibrationEvent>[
        _event(102, GaitCalibrationFootSide.left,
            GaitCalibrationEventType.touchdown, 0),
        _event(700, GaitCalibrationFootSide.right,
            GaitCalibrationEventType.touchdown, 1),
        _event(
          900,
          GaitCalibrationFootSide.left,
          GaitCalibrationEventType.toeOff,
          2,
        ),
      ];

      final report = const GaitCalibrationEvaluator(
        toleranceMs: 50,
      ).evaluate(groundTruth: groundTruth, predictions: predictions);

      expect(report.overall.truePositive, 1);
      expect(report.overall.falsePositive, 2);
      expect(report.overall.falseNegative, 2);
      expect(report.overall.precision, closeTo(1 / 3, 0.0001));
      expect(report.overall.recall, closeTo(1 / 3, 0.0001));
      expect(report.overall.f1, closeTo(1 / 3, 0.0001));
    });

    test('does not match predictions with the wrong side or event type', () {
      final groundTruth = <GaitCalibrationEvent>[
        _event(100, GaitCalibrationFootSide.left,
            GaitCalibrationEventType.touchdown, 0),
      ];
      final predictions = <GaitCalibrationEvent>[
        _event(100, GaitCalibrationFootSide.right,
            GaitCalibrationEventType.touchdown, 0),
        _event(
          100,
          GaitCalibrationFootSide.left,
          GaitCalibrationEventType.toeOff,
          1,
        ),
      ];

      final report = const GaitCalibrationEvaluator(
        toleranceMs: 80,
      ).evaluate(groundTruth: groundTruth, predictions: predictions);

      expect(report.overall.truePositive, 0);
      expect(report.overall.falsePositive, 2);
      expect(report.overall.falseNegative, 1);
      expect(
        report.byEventType[GaitCalibrationEventType.touchdown]!.falseNegative,
        1,
      );
      expect(report.byEventType[GaitCalibrationEventType.toeOff]!.falsePositive,
          1);
    });

    test('rejects duplicate fixture events clearly', () {
      expect(
        () => GaitCalibrationFixture.fromJsonString(
          jsonEncode({
            'events': [
              {'timestampMs': 100, 'side': 'left', 'type': 'touchdown'},
              {'timestampMs': 100, 'side': 'left', 'type': 'touchdown'},
            ],
          }),
          label: 'ground-truth',
        ),
        throwsA(
          isA<GaitCalibrationInputException>().having(
            (error) => error.message,
            'message',
            contains('duplicates side=left, type=touchdown, timestampMs=100'),
          ),
        ),
      );
    });

    test('rejects non-monotonic fixture events clearly', () {
      expect(
        () => GaitCalibrationFixture.fromJsonString(
          jsonEncode({
            'events': [
              {'timestampMs': 200, 'side': 'left', 'type': 'touchdown'},
              {'timestampMs': 100, 'side': 'right', 'type': 'touchdown'},
            ],
          }),
          label: 'predictions',
        ),
        throwsA(
          isA<GaitCalibrationInputException>().having(
            (error) => error.message,
            'message',
            contains('non-monotonic'),
          ),
        ),
      );
    });

    test('rejects malformed side and type fields clearly', () {
      expect(
        () => GaitCalibrationFixture.fromJsonString(
          jsonEncode({
            'events': [
              {'timestampMs': 100, 'side': 'both', 'type': 'landing'},
            ],
          }),
          label: 'ground-truth',
        ),
        throwsA(
          isA<GaitCalibrationInputException>().having(
            (error) => error.message,
            'message',
            contains('side must be "left" or "right"'),
          ),
        ),
      );
    });

    test('parses cumulative RunningLiveSession prediction logs', () {
      final touchdown = <String, Object?>{
        'timestampMs': 100,
        'side': 'left',
        'type': 'touchdown',
        'timestamp': '2026-07-21T09:00:00.100',
        'absoluteTimestampMs': 1784592000100,
        'confidence': '0.900',
      };
      final lateToeOff = <String, Object?>{
        'timestampMs': 240,
        'side': 'left',
        'type': 'toeOff',
        'timestamp': '2026-07-21T09:00:00.240',
        'absoluteTimestampMs': 1784592000240,
        'confidence': '0.800',
      };
      final earlierRight = <String, Object?>{
        'timestampMs': 90,
        'side': 'right',
        'type': 'touchdown',
        'timestamp': '2026-07-21T09:00:00.090',
        'absoluteTimestampMs': 1784592000090,
        'confidence': '0.850',
      };
      final source = [
        'unrelated debug line',
        '[RunningLiveSession] ${jsonEncode({
              'sessionId': 'running-a',
              'event': 'periodic',
              'events': {
                'timeline': [touchdown],
              },
            })}',
        'I/flutter (123): [RunningLiveSession] ${jsonEncode({
              'sessionId': 'running-a',
              'event': 'periodic',
              'events': {
                'timeline': [touchdown, lateToeOff, earlierRight],
              },
            })}',
      ].join('\n');

      final fixture = GaitCalibrationFixture.fromPredictionSourceString(
        source,
        label: 'predictions',
      );

      expect(fixture.format, GaitCalibrationInputFormat.runningLiveSessionLog);
      expect(fixture.sessionId, 'running-a');
      expect(fixture.sourceLogCount, 2);
      expect(fixture.repeatedEventCount, 1);
      expect(fixture.events.map((event) => event.timestampMs), [90, 100, 240]);
      expect(fixture.events.map((event) => event.side), [
        GaitCalibrationFootSide.right,
        GaitCalibrationFootSide.left,
        GaitCalibrationFootSide.left,
      ]);
      expect(fixture.sourceMetadataToJson(), {
        'format': 'runningLiveSessionLog',
        'eventCount': 3,
        'sessionId': 'running-a',
        'sourceLogCount': 2,
        'deduplicatedRepeatedEvents': 1,
      });
    });

    test('requires an explicit session id for multi-session logs', () {
      final source = [
        '[RunningLiveSession] ${jsonEncode({
              'sessionId': 'running-a',
              'events': {
                'timeline': [
                  {'timestampMs': 100, 'side': 'left', 'type': 'touchdown'},
                ],
              },
            })}',
        '[RunningLiveSession] ${jsonEncode({
              'sessionId': 'running-b',
              'events': {
                'timeline': [
                  {'timestampMs': 300, 'side': 'right', 'type': 'toeOff'},
                ],
              },
            })}',
      ].join('\n');

      expect(
        () => GaitCalibrationFixture.fromPredictionSourceString(
          source,
          label: 'predictions',
        ),
        throwsA(
          isA<GaitCalibrationInputException>().having(
            (error) => error.message,
            'message',
            contains('multiple RunningLiveSession sessions'),
          ),
        ),
      );

      final selected = GaitCalibrationFixture.fromPredictionSourceString(
        source,
        label: 'predictions',
        sessionId: 'running-b',
      );

      expect(selected.sessionId, 'running-b');
      expect(selected.events, hasLength(1));
      expect(selected.events.single.timestampMs, 300);
      expect(selected.events.single.type, GaitCalibrationEventType.toeOff);
    });

    test('rejects conflicting repeated live events instead of hiding them', () {
      final first = <String, Object?>{
        'timestampMs': 100,
        'side': 'left',
        'type': 'touchdown',
        'confidence': '0.900',
      };
      final conflicting = <String, Object?>{
        'timestampMs': 100,
        'side': 'left',
        'type': 'touchdown',
        'confidence': '0.700',
      };
      final source = [
        '[RunningLiveSession] ${jsonEncode({
              'sessionId': 'running-a',
              'events': {
                'timeline': [first],
              },
            })}',
        '[RunningLiveSession] ${jsonEncode({
              'sessionId': 'running-a',
              'events': {
                'timeline': [conflicting],
              },
            })}',
      ].join('\n');

      expect(
        () => GaitCalibrationFixture.fromPredictionSourceString(
          source,
          label: 'predictions',
        ),
        throwsA(
          isA<GaitCalibrationInputException>().having(
            (error) => error.message,
            'message',
            allOf(contains('conflicts'), contains('timestampMs=100')),
          ),
        ),
      );
    });

    test('reports every configured quality gate violation', () {
      final report = const GaitCalibrationEvaluator(
        toleranceMs: 30,
        qualityGate: GaitCalibrationQualityGate(
          minGroundTruthEvents: 3,
          minOverallPrecision: 0.9,
          minOverallRecall: 0.9,
          minOverallF1: 0.9,
          maxTimingMeanAbsoluteErrorMs: 10,
          maxTimingP95AbsoluteErrorMs: 20,
          minTouchdownPrecision: 0.9,
          minTouchdownRecall: 0.9,
          minToeOffPrecision: 0.9,
          minToeOffRecall: 0.9,
        ),
      ).evaluate(
        groundTruth: <GaitCalibrationEvent>[
          _event(100, GaitCalibrationFootSide.left,
              GaitCalibrationEventType.touchdown, 0),
          _event(
            220,
            GaitCalibrationFootSide.left,
            GaitCalibrationEventType.toeOff,
            1,
          ),
        ],
        predictions: const <GaitCalibrationEvent>[],
      );

      expect(report.qualityGate.passed, isFalse);
      expect(
        report.qualityGate.violations.map((violation) => violation.metric),
        [
          'groundTruth.eventCount',
          'overall.precision',
          'overall.recall',
          'overall.f1',
          'overall.maeMs',
          'overall.p95AbsoluteErrorMs',
          'touchdown.precision',
          'touchdown.recall',
          'toeOff.precision',
          'toeOff.recall',
        ],
      );
      final gateJson = report.toJson()['qualityGate'] as Map<String, Object?>;
      expect(gateJson['passed'], isFalse);
      final violations = gateJson['violations'] as List<Object?>;
      expect(violations, hasLength(10));
      expect(
        violations.cast<Map<String, Object?>>().where(
              (violation) =>
                  violation['metric'] == 'overall.maeMs' &&
                  violation['actual'] == null,
            ),
        hasLength(1),
      );
    });
  });

  group('running gait calibration CLI', () {
    test('prints the JSON report contract', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'running_gait_calibration_cli_test_',
      );
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });
      final groundTruth = File('${tempDir.path}/ground_truth.json')
        ..writeAsStringSync(
          jsonEncode({
            'schemaVersion': 1,
            'events': [
              {'timestampMs': 100, 'side': 'left', 'type': 'touchdown'},
              {'timestampMs': 220, 'side': 'left', 'type': 'toeOff'},
            ],
          }),
        );
      final predictions = File('${tempDir.path}/predictions.json')
        ..writeAsStringSync(
          jsonEncode({
            'schemaVersion': 1,
            'events': [
              {'timestampMs': 108, 'side': 'left', 'type': 'touchdown'},
              {'timestampMs': 260, 'side': 'left', 'type': 'toeOff'},
            ],
          }),
        );

      final result = await Process.run(
        'dart',
        [
          'bin/running_gait_calibration_evaluator.dart',
          '--ground-truth',
          groundTruth.path,
          '--predictions',
          predictions.path,
          '--tolerance-ms',
          '30',
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final decoded =
          jsonDecode(result.stdout as String) as Map<String, Object?>;
      expect(decoded['toleranceMs'], 30);
      expect(decoded['overall'], {
        'tp': 1,
        'fp': 1,
        'fn': 1,
        'precision': 0.5,
        'recall': 0.5,
        'f1': 0.5,
        'signedBiasMs': 8.0,
        'maeMs': 8.0,
        'p95AbsoluteErrorMs': 8.0,
      });
      expect(decoded['byEventType'], isA<Map<String, Object?>>());
      expect(decoded['matches'], isA<List<Object?>>());
      expect(
        (decoded['qualityGate'] as Map<String, Object?>)['passed'],
        isTrue,
      );
      expect(decoded['predictionInput'], {
        'format': 'flatEvents',
        'eventCount': 2,
      });
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}

GaitCalibrationEvent _event(
  int timestampMs,
  GaitCalibrationFootSide side,
  GaitCalibrationEventType type,
  int sourceIndex,
) {
  return GaitCalibrationEvent(
    timestampMs: timestampMs,
    side: side,
    type: type,
    sourceIndex: sourceIndex,
  );
}
