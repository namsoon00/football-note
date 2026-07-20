import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/running_live_coaching_state.dart';
import 'package:football_note/realtime_analysis/running_coaching/running_gait_event_detector.dart';
import 'package:football_note/realtime_analysis/running_coaching/running_live_timing_config.dart';

void main() {
  group('RunningGaitEventDetector', () {
    test('uses the shared live temporal resolution contract', () {
      const config = RunningGaitEventDetectorConfig();

      expect(config.targetFrameInterval, runningLiveGaitTargetFrameInterval);
      expect(config.maximumFrameGap, runningLiveGaitMaximumFrameGap);
      expect(config.debounceDuration, const Duration(milliseconds: 50));
      expect(config.minimumEventSpacing, const Duration(milliseconds: 80));
    });

    test('orders touchdown and toe-off events by foot', () {
      final result = _runSeries(_runningSeries());

      final eventsBySide = <RunningFootSide, List<RunningGaitEvent>>{
        RunningFootSide.left: [
          for (final event in result.recentEvents)
            if (event.side == RunningFootSide.left) event,
        ],
        RunningFootSide.right: [
          for (final event in result.recentEvents)
            if (event.side == RunningFootSide.right) event,
        ],
      };

      for (final events in eventsBySide.values) {
        expect(events.first.type, RunningGaitEventType.touchdown);
        for (var index = 1; index < events.length; index += 1) {
          expect(events[index].type, isNot(events[index - 1].type));
          expect(
            events[index].timestamp.isAfter(events[index - 1].timestamp),
            isTrue,
          );
        }
      }
    });

    test('reports flight and per-side contact phase transitions', () {
      final detector = RunningGaitEventDetector();
      final start = DateTime(2026, 7, 20, 9);
      final phases = <RunningGaitPhase>{};

      for (var index = 0; index < _runningSeries().length; index += 1) {
        final analysis = detector.ingestObservation(
          _observationFor(_runningSeries()[index]),
          timestamp: start.add(runningLiveGaitTargetFrameInterval * index),
          cameraSideViewFramingOk: true,
        );
        if (analysis.currentPhase != RunningGaitPhase.unknown) {
          phases.add(analysis.currentPhase);
        }
      }

      expect(phases, contains(RunningGaitPhase.flight));
      expect(phases, contains(RunningGaitPhase.leftContact));
      expect(phases, contains(RunningGaitPhase.rightContact));
    });

    test('keeps the first observed transition timestamp after debounce', () {
      final start = DateTime(2026, 7, 20, 9);
      final analysis = _runSeries(_runningSeries());
      final leftEvents = analysis.recentEvents
          .where((event) => event.side == RunningFootSide.left)
          .toList(growable: false);
      expect(leftEvents.map((event) => event.type), [
        RunningGaitEventType.touchdown,
        RunningGaitEventType.toeOff,
        RunningGaitEventType.touchdown,
        RunningGaitEventType.toeOff,
      ]);
      expect(
        leftEvents.map((event) => event.timestamp),
        [
          start.add(const Duration(milliseconds: 400)),
          start.add(const Duration(milliseconds: 500)),
          start.add(const Duration(milliseconds: 800)),
          start.add(const Duration(milliseconds: 900)),
        ],
      );
    });

    test('calculates cadence and per-side contact duration when gated in', () {
      final result = _runSeries(_runningSeries());

      expect(result.cadence.available, isTrue);
      expect(result.cadence.value, closeTo(300, 0.001));
      expect(result.cadence.sampleCount, 4);
      expect(result.leftContactDuration.available, isTrue);
      expect(result.leftContactDuration.value, closeTo(100, 0.001));
      expect(result.leftContactDuration.sampleCount, 2);
      expect(result.rightContactDuration.available, isTrue);
      expect(result.rightContactDuration.value, closeTo(100, 0.001));
      expect(result.rightContactDuration.sampleCount, 2);
    });

    test('keeps gait metrics unavailable for sparse frame timing', () {
      final result = _runSeries(
        _runningSeries(),
        frameInterval: const Duration(milliseconds: 350),
      );

      expect(result.cadence.available, isFalse);
      expect(
        result.cadence.reasonIfUnavailable,
        'insufficient_temporal_resolution',
      );
      expect(result.leftContactDuration.available, isFalse);
    });

    test('rejects gaps that cannot support the live timing target', () {
      final result = _runSeries(
        _runningSeries(),
        frameInterval: const Duration(milliseconds: 100),
      );

      expect(result.cadence.available, isFalse);
      expect(
        result.cadence.reasonIfUnavailable,
        'insufficient_temporal_resolution',
      );
      expect(result.leftContactDuration.available, isFalse);
      expect(result.rightContactDuration.available, isFalse);
    });

    test('keeps gait metrics unavailable for low-confidence frames', () {
      final result = _runSeries(
        _runningSeries(),
        landmarkLikelihood: 0.46,
      );

      expect(result.cadence.available, isFalse);
      expect(result.cadence.reasonIfUnavailable, 'low_confidence');
      expect(result.currentPhase, RunningGaitPhase.unknown);
    });

    test('drops contact durations after they leave the analysis window', () {
      final detector = RunningGaitEventDetector();
      final start = DateTime(2026, 7, 20, 9);
      final series = _runningSeries();
      RunningGaitAnalysis analysis = const RunningGaitAnalysis.empty();

      for (var index = 0; index < series.length; index += 1) {
        analysis = detector.ingestObservation(
          _observationFor(series[index]),
          timestamp: start.add(runningLiveGaitTargetFrameInterval * index),
          cameraSideViewFramingOk: true,
        );
      }
      expect(analysis.leftContactDuration.available, isTrue);

      final seriesEnd =
          start.add(runningLiveGaitTargetFrameInterval * series.length);
      for (var index = 0; index < 60; index += 1) {
        analysis = detector.ingestObservation(
          null,
          timestamp: seriesEnd.add(runningLiveGaitTargetFrameInterval * index),
          cameraSideViewFramingOk: true,
        );
      }

      expect(analysis.recentEvents, isEmpty);
      expect(analysis.leftContactDuration.available, isFalse);
      expect(analysis.leftContactDuration.sampleCount, 0);
      expect(analysis.rightContactDuration.sampleCount, 0);
    });

    test('discards a rapid false contact instead of keeping an event pair', () {
      final detector = RunningGaitEventDetector(
        config: const RunningGaitEventDetectorConfig(
          minimumEventSpacing: Duration(milliseconds: 300),
        ),
      );
      final start = DateTime(2026, 7, 20, 9);
      const states = <_SyntheticGaitState>[
        _SyntheticGaitState.flight,
        _SyntheticGaitState.flight,
        _SyntheticGaitState.leftContact,
        _SyntheticGaitState.leftContact,
        _SyntheticGaitState.flight,
        _SyntheticGaitState.flight,
      ];
      RunningGaitAnalysis analysis = const RunningGaitAnalysis.empty();

      for (var index = 0; index < states.length; index += 1) {
        analysis = detector.ingestObservation(
          _observationFor(states[index]),
          timestamp: start.add(Duration(milliseconds: 120 * index)),
          cameraSideViewFramingOk: true,
        );
      }

      expect(
        analysis.recentEvents.where(
          (event) => event.side == RunningFootSide.left,
        ),
        isEmpty,
      );
      expect(analysis.leftContactDuration.sampleCount, 0);
    });

    test('reset clears event history and availability', () {
      final detector = RunningGaitEventDetector();
      final start = DateTime(2026, 7, 20, 9);
      RunningGaitAnalysis analysis = const RunningGaitAnalysis.empty();

      for (var index = 0; index < _runningSeries().length; index += 1) {
        analysis = detector.ingestObservation(
          _observationFor(_runningSeries()[index]),
          timestamp: start.add(runningLiveGaitTargetFrameInterval * index),
          cameraSideViewFramingOk: true,
        );
      }
      expect(analysis.cadence.available, isTrue);

      detector.reset();
      analysis = detector.ingestObservation(
        _observationFor(_SyntheticGaitState.leftContact),
        timestamp: start.add(const Duration(seconds: 5)),
        cameraSideViewFramingOk: true,
      );

      expect(analysis.touchdownCount, 0);
      expect(analysis.cadence.available, isFalse);
      expect(analysis.currentPhase, RunningGaitPhase.unknown);
    });
  });
}

RunningGaitAnalysis _runSeries(
  List<_SyntheticGaitState> states, {
  Duration frameInterval = runningLiveGaitTargetFrameInterval,
  double landmarkLikelihood = 0.98,
}) {
  final detector = RunningGaitEventDetector();
  final start = DateTime(2026, 7, 20, 9);
  RunningGaitAnalysis analysis = const RunningGaitAnalysis.empty();
  for (var index = 0; index < states.length; index += 1) {
    analysis = detector.ingestObservation(
      _observationFor(states[index], likelihood: landmarkLikelihood),
      timestamp: start.add(frameInterval * index),
      cameraSideViewFramingOk: true,
    );
  }
  return analysis;
}

List<_SyntheticGaitState> _runningSeries() {
  return const [
    _SyntheticGaitState.leftContact,
    _SyntheticGaitState.leftContact,
    _SyntheticGaitState.flight,
    _SyntheticGaitState.flight,
    _SyntheticGaitState.rightContact,
    _SyntheticGaitState.rightContact,
    _SyntheticGaitState.flight,
    _SyntheticGaitState.flight,
    _SyntheticGaitState.leftContact,
    _SyntheticGaitState.leftContact,
    _SyntheticGaitState.flight,
    _SyntheticGaitState.flight,
    _SyntheticGaitState.rightContact,
    _SyntheticGaitState.rightContact,
    _SyntheticGaitState.flight,
    _SyntheticGaitState.flight,
    _SyntheticGaitState.leftContact,
    _SyntheticGaitState.leftContact,
    _SyntheticGaitState.flight,
    _SyntheticGaitState.flight,
  ];
}

RunningPoseObservation _observationFor(
  _SyntheticGaitState state, {
  double likelihood = 0.98,
}) {
  const groundY = 790.0;
  const flightY = 720.0;
  final leftFootY = switch (state) {
    _SyntheticGaitState.leftContact => groundY,
    _SyntheticGaitState.rightContact => flightY,
    _SyntheticGaitState.flight => flightY,
    _SyntheticGaitState.doubleContact => groundY,
  };
  final rightFootY = switch (state) {
    _SyntheticGaitState.leftContact => flightY,
    _SyntheticGaitState.rightContact => groundY,
    _SyntheticGaitState.flight => flightY,
    _SyntheticGaitState.doubleContact => groundY,
  };

  return RunningPoseObservation(
    imageSize: const Size(1000, 1000),
    landmarks: <RunningPoseLandmarkType, RunningPoseLandmark>{
      RunningPoseLandmarkType.leftShoulder:
          _landmark(const Offset(494, 220), likelihood),
      RunningPoseLandmarkType.rightShoulder:
          _landmark(const Offset(506, 220), likelihood),
      RunningPoseLandmarkType.leftHip:
          _landmark(const Offset(497, 430), likelihood),
      RunningPoseLandmarkType.rightHip:
          _landmark(const Offset(503, 430), likelihood),
      RunningPoseLandmarkType.leftAnkle:
          _landmark(Offset(492, leftFootY - 20), likelihood),
      RunningPoseLandmarkType.rightAnkle:
          _landmark(Offset(508, rightFootY - 20), likelihood),
      RunningPoseLandmarkType.leftHeel:
          _landmark(Offset(490, leftFootY), likelihood),
      RunningPoseLandmarkType.rightHeel:
          _landmark(Offset(510, rightFootY), likelihood),
      RunningPoseLandmarkType.leftFootIndex:
          _landmark(Offset(494, leftFootY - 4), likelihood),
      RunningPoseLandmarkType.rightFootIndex:
          _landmark(Offset(506, rightFootY - 4), likelihood),
    },
  );
}

RunningPoseLandmark _landmark(Offset position, double likelihood) {
  return RunningPoseLandmark(position: position, likelihood: likelihood);
}

enum _SyntheticGaitState {
  leftContact,
  rightContact,
  flight,
  doubleContact,
}
