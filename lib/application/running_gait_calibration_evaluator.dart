import 'dart:convert';

enum GaitCalibrationFootSide { left, right }

enum GaitCalibrationEventType { touchdown, toeOff }

enum GaitCalibrationInputFormat { flatEvents, runningLiveSessionLog }

class GaitCalibrationInputException implements Exception {
  final String message;

  const GaitCalibrationInputException(this.message);

  @override
  String toString() => message;
}

class GaitCalibrationEvent {
  final int timestampMs;
  final GaitCalibrationFootSide side;
  final GaitCalibrationEventType type;
  final int sourceIndex;

  const GaitCalibrationEvent({
    required this.timestampMs,
    required this.side,
    required this.type,
    required this.sourceIndex,
  });
}

class GaitCalibrationFixture {
  final List<GaitCalibrationEvent> events;
  final GaitCalibrationInputFormat format;
  final String? sessionId;
  final int sourceLogCount;
  final int repeatedEventCount;

  const GaitCalibrationFixture({
    required this.events,
    this.format = GaitCalibrationInputFormat.flatEvents,
    this.sessionId,
    this.sourceLogCount = 0,
    this.repeatedEventCount = 0,
  });

  factory GaitCalibrationFixture.fromJsonString(
    String source, {
    required String label,
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw GaitCalibrationInputException(
        '$label must be valid JSON: ${error.message}',
      );
    }
    return GaitCalibrationFixture.fromJson(decoded, label: label);
  }

  factory GaitCalibrationFixture.fromJson(
    Object? decoded, {
    required String label,
  }) {
    if (decoded is! Map<String, Object?>) {
      throw GaitCalibrationInputException(
        '$label must be a JSON object with an events array.',
      );
    }
    final rawEvents = decoded['events'];
    if (rawEvents is! List<Object?>) {
      throw GaitCalibrationInputException(
        '$label.events must be an array of gait events.',
      );
    }

    final events = <GaitCalibrationEvent>[];
    final seenKeys = <String>{};
    int? previousTimestampMs;
    for (var index = 0; index < rawEvents.length; index += 1) {
      final raw = rawEvents[index];
      if (raw is! Map<String, Object?>) {
        throw GaitCalibrationInputException(
          '$label.events[$index] must be an object.',
        );
      }
      final timestampMs = _parseTimestamp(raw['timestampMs'], label, index);
      final previous = previousTimestampMs;
      if (previous != null && timestampMs < previous) {
        throw GaitCalibrationInputException(
          '$label.events[$index].timestampMs is non-monotonic: '
          '$timestampMs appears after $previous.',
        );
      }
      previousTimestampMs = timestampMs;

      final side = _parseSide(raw['side'], label, index);
      final type = _parseType(raw['type'], label, index);
      final duplicateKey = '${side.name}|${type.name}|$timestampMs';
      if (!seenKeys.add(duplicateKey)) {
        throw GaitCalibrationInputException(
          '$label.events[$index] duplicates side=${side.name}, '
          'type=${type.name}, timestampMs=$timestampMs.',
        );
      }
      events.add(
        GaitCalibrationEvent(
          timestampMs: timestampMs,
          side: side,
          type: type,
          sourceIndex: index,
        ),
      );
    }

    return GaitCalibrationFixture(events: List.unmodifiable(events));
  }

  factory GaitCalibrationFixture.fromPredictionSourceString(
    String source, {
    required String label,
    String? sessionId,
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      return _fromRunningLiveSessionLogLines(
        source,
        label: label,
        requestedSessionId: sessionId,
      );
    }

    if (decoded is Map<String, Object?> && decoded['events'] is List<Object?>) {
      return GaitCalibrationFixture.fromJson(decoded, label: label);
    }
    if (_isRunningLiveSessionPayload(decoded)) {
      return _fromRunningLiveSessionPayloads(
        <_RunningLiveSessionPayload>[
          _RunningLiveSessionPayload(decoded as Map<String, Object?>, label),
        ],
        label: label,
        requestedSessionId: sessionId,
      );
    }
    if (decoded is List<Object?>) {
      return _fromRunningLiveSessionPayloads(
        [
          for (var index = 0; index < decoded.length; index += 1)
            _RunningLiveSessionPayload(
              _expectJsonObject(
                decoded[index],
                '$label[$index]',
              ),
              '$label[$index]',
            ),
        ],
        label: label,
        requestedSessionId: sessionId,
      );
    }
    if (decoded is Map<String, Object?> && decoded.containsKey('events')) {
      return GaitCalibrationFixture.fromJson(decoded, label: label);
    }

    throw GaitCalibrationInputException(
      '$label must be either a flat events JSON object or '
      'RunningLiveSession JSON/debug-log lines.',
    );
  }

  Map<String, Object?> sourceMetadataToJson() {
    return <String, Object?>{
      'format': format.name,
      'eventCount': events.length,
      if (sessionId != null) 'sessionId': sessionId,
      if (sourceLogCount > 0) 'sourceLogCount': sourceLogCount,
      if (repeatedEventCount > 0)
        'deduplicatedRepeatedEvents': repeatedEventCount,
    };
  }

  static int _parseTimestamp(Object? value, String label, int index) {
    if (value is! int) {
      throw GaitCalibrationInputException(
        '$label.events[$index].timestampMs must be an integer millisecond '
        'timestamp.',
      );
    }
    if (value < 0) {
      throw GaitCalibrationInputException(
        '$label.events[$index].timestampMs must be non-negative.',
      );
    }
    return value;
  }

  static GaitCalibrationFootSide _parseSide(
    Object? value,
    String label,
    int index,
  ) {
    if (value == 'left') {
      return GaitCalibrationFootSide.left;
    }
    if (value == 'right') {
      return GaitCalibrationFootSide.right;
    }
    throw GaitCalibrationInputException(
      '$label.events[$index].side must be "left" or "right".',
    );
  }

  static GaitCalibrationEventType _parseType(
    Object? value,
    String label,
    int index,
  ) {
    if (value == 'touchdown') {
      return GaitCalibrationEventType.touchdown;
    }
    if (value == 'toeOff') {
      return GaitCalibrationEventType.toeOff;
    }
    throw GaitCalibrationInputException(
      '$label.events[$index].type must be "touchdown" or "toeOff".',
    );
  }

  static GaitCalibrationFixture _fromRunningLiveSessionLogLines(
    String source, {
    required String label,
    required String? requestedSessionId,
  }) {
    final payloads = <_RunningLiveSessionPayload>[];
    final lines = const LineSplitter().convert(source);
    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index];
      final markerIndex = line.indexOf(_runningLiveSessionMarker);
      if (markerIndex < 0) {
        continue;
      }
      final rawPayload =
          line.substring(markerIndex + _runningLiveSessionMarker.length).trim();
      if (rawPayload.isEmpty) {
        throw GaitCalibrationInputException(
          '$label line ${index + 1} has an empty RunningLiveSession payload.',
        );
      }
      final Object? decoded;
      try {
        decoded = jsonDecode(rawPayload);
      } on FormatException catch (error) {
        throw GaitCalibrationInputException(
          '$label line ${index + 1} RunningLiveSession payload must be valid '
          'JSON: ${error.message}',
        );
      }
      payloads.add(
        _RunningLiveSessionPayload(
          _expectJsonObject(decoded, '$label line ${index + 1}'),
          '$label line ${index + 1}',
        ),
      );
    }

    if (payloads.isEmpty) {
      throw GaitCalibrationInputException(
        '$label must be valid flat events JSON or contain '
        '$_runningLiveSessionMarker JSON log lines.',
      );
    }

    return _fromRunningLiveSessionPayloads(
      payloads,
      label: label,
      requestedSessionId: requestedSessionId,
    );
  }

  static GaitCalibrationFixture _fromRunningLiveSessionPayloads(
    List<_RunningLiveSessionPayload> payloads, {
    required String label,
    required String? requestedSessionId,
  }) {
    final bySessionId = <String, List<_RunningLiveSessionPayload>>{};
    for (final payload in payloads) {
      final sessionId = payload.map['sessionId'];
      if (sessionId is! String || sessionId.isEmpty) {
        throw GaitCalibrationInputException(
          '${payload.label}.sessionId must be a non-empty string.',
        );
      }
      bySessionId.putIfAbsent(sessionId, () => []).add(payload);
    }

    final selectedSessionId = _selectRunningLiveSessionId(
      bySessionId.keys.toList(growable: false),
      requestedSessionId: requestedSessionId,
      label: label,
    );
    final selectedPayloads = bySessionId[selectedSessionId]!;
    final byEventKey = <String, _RunningLiveSessionEventRecord>{};
    var sourceIndex = 0;
    var repeatedEventCount = 0;

    for (var payloadIndex = 0;
        payloadIndex < selectedPayloads.length;
        payloadIndex += 1) {
      final payload = selectedPayloads[payloadIndex];
      final events = payload.map['events'];
      if (events is! Map<String, Object?>) {
        throw GaitCalibrationInputException(
          '${payload.label}.events must be an object with a timeline array.',
        );
      }
      final timeline = events['timeline'];
      if (timeline is! List<Object?>) {
        throw GaitCalibrationInputException(
          '${payload.label}.events.timeline must be an array.',
        );
      }
      for (var timelineIndex = 0;
          timelineIndex < timeline.length;
          timelineIndex += 1) {
        final eventLabel = '${payload.label}.events.timeline[$timelineIndex]';
        final rawEvent = _expectJsonObject(timeline[timelineIndex], eventLabel);
        final timestampMs = _parseTimelineTimestamp(
          rawEvent['timestampMs'],
          eventLabel,
        );
        final side = _parseTimelineSide(rawEvent['side'], eventLabel);
        final type = _parseTimelineType(rawEvent['type'], eventLabel);
        final eventKey = '${side.name}|${type.name}|$timestampMs';
        final canonicalEvent = _canonicalJson(rawEvent);
        final existing = byEventKey[eventKey];
        if (existing != null) {
          if (existing.canonicalEvent != canonicalEvent) {
            throw GaitCalibrationInputException(
              '$eventLabel conflicts with an earlier RunningLiveSession event '
              'for side=${side.name}, type=${type.name}, '
              'timestampMs=$timestampMs. Repeated cumulative events must be '
              'identical to be deduplicated.',
            );
          }
          repeatedEventCount += 1;
          continue;
        }
        byEventKey[eventKey] = _RunningLiveSessionEventRecord(
          event: GaitCalibrationEvent(
            timestampMs: timestampMs,
            side: side,
            type: type,
            sourceIndex: sourceIndex,
          ),
          canonicalEvent: canonicalEvent,
        );
        sourceIndex += 1;
      }
    }

    final events = [
      for (final record in byEventKey.values) record.event,
    ]..sort(_compareEventsForReport);

    return GaitCalibrationFixture(
      events: List.unmodifiable(events),
      format: GaitCalibrationInputFormat.runningLiveSessionLog,
      sessionId: selectedSessionId,
      sourceLogCount: selectedPayloads.length,
      repeatedEventCount: repeatedEventCount,
    );
  }

  static int _parseTimelineTimestamp(Object? value, String label) {
    if (value is! int) {
      throw GaitCalibrationInputException(
        '$label.timestampMs must be an integer millisecond timestamp.',
      );
    }
    if (value < 0) {
      throw GaitCalibrationInputException(
        '$label.timestampMs must be non-negative.',
      );
    }
    return value;
  }

  static GaitCalibrationFootSide _parseTimelineSide(
    Object? value,
    String label,
  ) {
    if (value == 'left') {
      return GaitCalibrationFootSide.left;
    }
    if (value == 'right') {
      return GaitCalibrationFootSide.right;
    }
    throw GaitCalibrationInputException(
      '$label.side must be "left" or "right".',
    );
  }

  static GaitCalibrationEventType _parseTimelineType(
    Object? value,
    String label,
  ) {
    if (value == 'touchdown') {
      return GaitCalibrationEventType.touchdown;
    }
    if (value == 'toeOff') {
      return GaitCalibrationEventType.toeOff;
    }
    throw GaitCalibrationInputException(
      '$label.type must be "touchdown" or "toeOff".',
    );
  }
}

const _runningLiveSessionMarker = '[RunningLiveSession]';

bool _isRunningLiveSessionPayload(Object? value) {
  return value is Map<String, Object?> &&
      value['sessionId'] is String &&
      value['events'] is Map<String, Object?>;
}

Map<String, Object?> _expectJsonObject(Object? value, String label) {
  if (value is! Map<String, Object?>) {
    throw GaitCalibrationInputException('$label must be a JSON object.');
  }
  return value;
}

String _selectRunningLiveSessionId(
  List<String> sessionIds, {
  required String? requestedSessionId,
  required String label,
}) {
  sessionIds.sort();
  if (requestedSessionId != null) {
    if (sessionIds.contains(requestedSessionId)) {
      return requestedSessionId;
    }
    throw GaitCalibrationInputException(
      '$label does not contain RunningLiveSession session '
      '"$requestedSessionId". Available sessions: ${sessionIds.join(', ')}.',
    );
  }
  if (sessionIds.length == 1) {
    return sessionIds.single;
  }
  throw GaitCalibrationInputException(
    '$label contains multiple RunningLiveSession sessions: '
    '${sessionIds.join(', ')}. Pass --prediction-session-id to select one.',
  );
}

String _canonicalJson(Object? value) {
  if (value is Map<String, Object?>) {
    return jsonEncode(<String, Object?>{
      for (final key in value.keys.toList(growable: false)..sort())
        key: jsonDecode(_canonicalJson(value[key])),
    });
  }
  if (value is List<Object?>) {
    return jsonEncode([
      for (final item in value) jsonDecode(_canonicalJson(item)),
    ]);
  }
  return jsonEncode(value);
}

int _compareEventsForReport(
  GaitCalibrationEvent first,
  GaitCalibrationEvent second,
) {
  final timeCompare = first.timestampMs.compareTo(second.timestampMs);
  if (timeCompare != 0) {
    return timeCompare;
  }
  final sideCompare = first.side.index.compareTo(second.side.index);
  if (sideCompare != 0) {
    return sideCompare;
  }
  final typeCompare = first.type.index.compareTo(second.type.index);
  if (typeCompare != 0) {
    return typeCompare;
  }
  return first.sourceIndex.compareTo(second.sourceIndex);
}

class _RunningLiveSessionPayload {
  final Map<String, Object?> map;
  final String label;

  const _RunningLiveSessionPayload(this.map, this.label);
}

class _RunningLiveSessionEventRecord {
  final GaitCalibrationEvent event;
  final String canonicalEvent;

  const _RunningLiveSessionEventRecord({
    required this.event,
    required this.canonicalEvent,
  });
}

class GaitCalibrationMatch {
  final GaitCalibrationEvent groundTruth;
  final GaitCalibrationEvent prediction;

  const GaitCalibrationMatch({
    required this.groundTruth,
    required this.prediction,
  });

  int get signedErrorMs => prediction.timestampMs - groundTruth.timestampMs;

  int get absoluteErrorMs => signedErrorMs.abs();

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'side': groundTruth.side.name,
      'type': groundTruth.type.name,
      'groundTruthTimestampMs': groundTruth.timestampMs,
      'predictionTimestampMs': prediction.timestampMs,
      'signedErrorMs': signedErrorMs,
      'absoluteErrorMs': absoluteErrorMs,
    };
  }
}

class GaitCalibrationMetrics {
  final int truePositive;
  final int falsePositive;
  final int falseNegative;
  final double precision;
  final double recall;
  final double f1;
  final double? signedBiasMs;
  final double? meanAbsoluteErrorMs;
  final double? p95AbsoluteErrorMs;

  const GaitCalibrationMetrics({
    required this.truePositive,
    required this.falsePositive,
    required this.falseNegative,
    required this.precision,
    required this.recall,
    required this.f1,
    required this.signedBiasMs,
    required this.meanAbsoluteErrorMs,
    required this.p95AbsoluteErrorMs,
  });

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'tp': truePositive,
      'fp': falsePositive,
      'fn': falseNegative,
      'precision': _roundMetric(precision),
      'recall': _roundMetric(recall),
      'f1': _roundMetric(f1),
      'signedBiasMs': _roundNullable(signedBiasMs),
      'maeMs': _roundNullable(meanAbsoluteErrorMs),
      'p95AbsoluteErrorMs': _roundNullable(p95AbsoluteErrorMs),
    };
  }
}

class GaitCalibrationQualityGate {
  final int? minGroundTruthEvents;
  final double? minOverallPrecision;
  final double? minOverallRecall;
  final double? minOverallF1;
  final double? maxTimingMeanAbsoluteErrorMs;
  final double? maxTimingP95AbsoluteErrorMs;
  final double? minTouchdownPrecision;
  final double? minTouchdownRecall;
  final double? minToeOffPrecision;
  final double? minToeOffRecall;

  const GaitCalibrationQualityGate({
    this.minGroundTruthEvents,
    this.minOverallPrecision,
    this.minOverallRecall,
    this.minOverallF1,
    this.maxTimingMeanAbsoluteErrorMs,
    this.maxTimingP95AbsoluteErrorMs,
    this.minTouchdownPrecision,
    this.minTouchdownRecall,
    this.minToeOffPrecision,
    this.minToeOffRecall,
  })  : assert(minGroundTruthEvents == null || minGroundTruthEvents >= 0),
        assert(minOverallPrecision == null ||
            (minOverallPrecision >= 0 && minOverallPrecision <= 1)),
        assert(minOverallRecall == null ||
            (minOverallRecall >= 0 && minOverallRecall <= 1)),
        assert(
          minOverallF1 == null || (minOverallF1 >= 0 && minOverallF1 <= 1),
        ),
        assert(maxTimingMeanAbsoluteErrorMs == null ||
            maxTimingMeanAbsoluteErrorMs >= 0),
        assert(maxTimingP95AbsoluteErrorMs == null ||
            maxTimingP95AbsoluteErrorMs >= 0),
        assert(minTouchdownPrecision == null ||
            (minTouchdownPrecision >= 0 && minTouchdownPrecision <= 1)),
        assert(minTouchdownRecall == null ||
            (minTouchdownRecall >= 0 && minTouchdownRecall <= 1)),
        assert(minToeOffPrecision == null ||
            (minToeOffPrecision >= 0 && minToeOffPrecision <= 1)),
        assert(minToeOffRecall == null ||
            (minToeOffRecall >= 0 && minToeOffRecall <= 1));

  GaitCalibrationQualityGateReport evaluate({
    required GaitCalibrationMetrics overall,
    required Map<GaitCalibrationEventType, GaitCalibrationMetrics> byEventType,
  }) {
    final violations = <GaitCalibrationQualityGateViolation>[];
    final groundTruthEventCount = overall.truePositive + overall.falseNegative;

    _checkMinimumInt(
      violations,
      metric: 'groundTruth.eventCount',
      actual: groundTruthEventCount,
      threshold: minGroundTruthEvents,
    );
    _checkMinimumDouble(
      violations,
      metric: 'overall.precision',
      actual: overall.precision,
      threshold: minOverallPrecision,
    );
    _checkMinimumDouble(
      violations,
      metric: 'overall.recall',
      actual: overall.recall,
      threshold: minOverallRecall,
    );
    _checkMinimumDouble(
      violations,
      metric: 'overall.f1',
      actual: overall.f1,
      threshold: minOverallF1,
    );
    _checkMaximumDouble(
      violations,
      metric: 'overall.maeMs',
      actual: overall.meanAbsoluteErrorMs,
      threshold: maxTimingMeanAbsoluteErrorMs,
    );
    _checkMaximumDouble(
      violations,
      metric: 'overall.p95AbsoluteErrorMs',
      actual: overall.p95AbsoluteErrorMs,
      threshold: maxTimingP95AbsoluteErrorMs,
    );

    final touchdown = byEventType[GaitCalibrationEventType.touchdown]!;
    _checkMinimumDouble(
      violations,
      metric: 'touchdown.precision',
      actual: touchdown.precision,
      threshold: minTouchdownPrecision,
    );
    _checkMinimumDouble(
      violations,
      metric: 'touchdown.recall',
      actual: touchdown.recall,
      threshold: minTouchdownRecall,
    );

    final toeOff = byEventType[GaitCalibrationEventType.toeOff]!;
    _checkMinimumDouble(
      violations,
      metric: 'toeOff.precision',
      actual: toeOff.precision,
      threshold: minToeOffPrecision,
    );
    _checkMinimumDouble(
      violations,
      metric: 'toeOff.recall',
      actual: toeOff.recall,
      threshold: minToeOffRecall,
    );

    return GaitCalibrationQualityGateReport(
      thresholds: this,
      violations: List.unmodifiable(violations),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'minGroundTruthEvents': minGroundTruthEvents,
      'overall': <String, Object?>{
        'minPrecision': _roundNullable(minOverallPrecision),
        'minRecall': _roundNullable(minOverallRecall),
        'minF1': _roundNullable(minOverallF1),
        'maxMaeMs': _roundNullable(maxTimingMeanAbsoluteErrorMs),
        'maxP95AbsoluteErrorMs': _roundNullable(maxTimingP95AbsoluteErrorMs),
      },
      'byEventType': <String, Object?>{
        'touchdown': <String, Object?>{
          'minPrecision': _roundNullable(minTouchdownPrecision),
          'minRecall': _roundNullable(minTouchdownRecall),
        },
        'toeOff': <String, Object?>{
          'minPrecision': _roundNullable(minToeOffPrecision),
          'minRecall': _roundNullable(minToeOffRecall),
        },
      },
    };
  }
}

class GaitCalibrationQualityGateReport {
  final GaitCalibrationQualityGate thresholds;
  final List<GaitCalibrationQualityGateViolation> violations;

  const GaitCalibrationQualityGateReport({
    required this.thresholds,
    required this.violations,
  });

  const GaitCalibrationQualityGateReport.unconfigured()
      : thresholds = const GaitCalibrationQualityGate(),
        violations = const <GaitCalibrationQualityGateViolation>[];

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

class GaitCalibrationQualityGateViolation {
  final String metric;
  final Object? actual;
  final Object threshold;
  final String comparison;
  final String message;

  const GaitCalibrationQualityGateViolation({
    required this.metric,
    required this.actual,
    required this.threshold,
    required this.comparison,
    required this.message,
  });

  Map<String, Object?> toJson() {
    final actualValue = actual;
    final thresholdValue = threshold;
    return <String, Object?>{
      'metric': metric,
      'actual': actualValue is double ? _roundMetric(actualValue) : actualValue,
      'comparison': comparison,
      'threshold': thresholdValue is double
          ? _roundMetric(thresholdValue)
          : thresholdValue,
      'message': message,
    };
  }
}

class GaitCalibrationReport {
  final int toleranceMs;
  final GaitCalibrationMetrics overall;
  final Map<GaitCalibrationEventType, GaitCalibrationMetrics> byEventType;
  final List<GaitCalibrationMatch> matches;
  final GaitCalibrationQualityGateReport qualityGate;

  const GaitCalibrationReport({
    required this.toleranceMs,
    required this.overall,
    required this.byEventType,
    required this.matches,
    this.qualityGate = const GaitCalibrationQualityGateReport.unconfigured(),
  });

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'toleranceMs': toleranceMs,
      'qualityGate': qualityGate.toJson(),
      'overall': overall.toJson(),
      'byEventType': <String, Object?>{
        for (final type in GaitCalibrationEventType.values)
          type.name: byEventType[type]!.toJson(),
      },
      'matches': [for (final match in matches) match.toJson()],
    };
  }
}

class GaitCalibrationEvaluator {
  final int toleranceMs;
  final GaitCalibrationQualityGate qualityGate;

  const GaitCalibrationEvaluator({
    required this.toleranceMs,
    this.qualityGate = const GaitCalibrationQualityGate(),
  }) : assert(toleranceMs >= 0);

  GaitCalibrationReport evaluate({
    required List<GaitCalibrationEvent> groundTruth,
    required List<GaitCalibrationEvent> predictions,
  }) {
    final matches = <GaitCalibrationMatch>[];
    for (final type in GaitCalibrationEventType.values) {
      for (final side in GaitCalibrationFootSide.values) {
        matches.addAll(
          _matchGroup(
            groundTruth.where(
              (event) => event.type == type && event.side == side,
            ),
            predictions.where(
              (event) => event.type == type && event.side == side,
            ),
          ),
        );
      }
    }
    matches.sort((first, second) {
      final timeCompare = first.groundTruth.timestampMs.compareTo(
        second.groundTruth.timestampMs,
      );
      if (timeCompare != 0) {
        return timeCompare;
      }
      final sideCompare = first.groundTruth.side.index.compareTo(
        second.groundTruth.side.index,
      );
      if (sideCompare != 0) {
        return sideCompare;
      }
      return first.groundTruth.type.index.compareTo(
        second.groundTruth.type.index,
      );
    });

    final overall = _metricsFor(
      groundTruth: groundTruth,
      predictions: predictions,
      matches: matches,
    );
    final byEventType = <GaitCalibrationEventType, GaitCalibrationMetrics>{
      for (final type in GaitCalibrationEventType.values)
        type: _metricsFor(
          groundTruth: groundTruth.where((event) => event.type == type),
          predictions: predictions.where((event) => event.type == type),
          matches: matches.where(
            (match) => match.groundTruth.type == type,
          ),
        ),
    };

    return GaitCalibrationReport(
      toleranceMs: toleranceMs,
      overall: overall,
      byEventType: byEventType,
      matches: List.unmodifiable(matches),
      qualityGate: qualityGate.evaluate(
        overall: overall,
        byEventType: byEventType,
      ),
    );
  }

  List<GaitCalibrationMatch> _matchGroup(
    Iterable<GaitCalibrationEvent> groundTruth,
    Iterable<GaitCalibrationEvent> predictions,
  ) {
    final truth = groundTruth.toList(growable: false)
      ..sort(_compareEventsForMatching);
    final predicted = predictions.toList(growable: false)
      ..sort(_compareEventsForMatching);
    final table = List<List<_GaitMatchCell?>>.generate(
      truth.length + 1,
      (_) => List<_GaitMatchCell?>.filled(predicted.length + 1, null),
      growable: false,
    );

    for (var truthIndex = truth.length; truthIndex >= 0; truthIndex -= 1) {
      for (var predictionIndex = predicted.length;
          predictionIndex >= 0;
          predictionIndex -= 1) {
        if (truthIndex == truth.length && predictionIndex == predicted.length) {
          table[truthIndex][predictionIndex] = const _GaitMatchCell(
            matchCount: 0,
            totalAbsoluteErrorMs: 0,
            action: _GaitMatchAction.end,
          );
          continue;
        }

        final candidates = <_GaitMatchCell>[];
        if (truthIndex < truth.length) {
          final next = table[truthIndex + 1][predictionIndex]!;
          candidates.add(
            _GaitMatchCell(
              matchCount: next.matchCount,
              totalAbsoluteErrorMs: next.totalAbsoluteErrorMs,
              action: _GaitMatchAction.skipTruth,
            ),
          );
        }
        if (predictionIndex < predicted.length) {
          final next = table[truthIndex][predictionIndex + 1]!;
          candidates.add(
            _GaitMatchCell(
              matchCount: next.matchCount,
              totalAbsoluteErrorMs: next.totalAbsoluteErrorMs,
              action: _GaitMatchAction.skipPrediction,
            ),
          );
        }
        if (truthIndex < truth.length && predictionIndex < predicted.length) {
          final absoluteError = (predicted[predictionIndex].timestampMs -
                  truth[truthIndex].timestampMs)
              .abs();
          if (absoluteError <= toleranceMs) {
            final next = table[truthIndex + 1][predictionIndex + 1]!;
            candidates.add(
              _GaitMatchCell(
                matchCount: next.matchCount + 1,
                totalAbsoluteErrorMs: next.totalAbsoluteErrorMs + absoluteError,
                action: _GaitMatchAction.match,
              ),
            );
          }
        }

        table[truthIndex][predictionIndex] = candidates.reduce(
          (best, candidate) =>
              _isBetterMatchCell(candidate, best) ? candidate : best,
        );
      }
    }

    final matches = <GaitCalibrationMatch>[];
    var truthIndex = 0;
    var predictionIndex = 0;
    while (truthIndex < truth.length || predictionIndex < predicted.length) {
      switch (table[truthIndex][predictionIndex]!.action) {
        case _GaitMatchAction.match:
          matches.add(
            GaitCalibrationMatch(
              groundTruth: truth[truthIndex],
              prediction: predicted[predictionIndex],
            ),
          );
          truthIndex += 1;
          predictionIndex += 1;
        case _GaitMatchAction.skipTruth:
          truthIndex += 1;
        case _GaitMatchAction.skipPrediction:
          predictionIndex += 1;
        case _GaitMatchAction.end:
          return matches;
      }
    }

    return matches;
  }

  GaitCalibrationMetrics _metricsFor({
    required Iterable<GaitCalibrationEvent> groundTruth,
    required Iterable<GaitCalibrationEvent> predictions,
    required Iterable<GaitCalibrationMatch> matches,
  }) {
    final truthCount = groundTruth.length;
    final predictionCount = predictions.length;
    final matched = matches.toList(growable: false);
    final truePositive = matched.length;
    final falsePositive = predictionCount - truePositive;
    final falseNegative = truthCount - truePositive;
    final precisionDenominator = truePositive + falsePositive;
    final recallDenominator = truePositive + falseNegative;
    final precision =
        precisionDenominator == 0 ? 0.0 : truePositive / precisionDenominator;
    final recall =
        recallDenominator == 0 ? 0.0 : truePositive / recallDenominator;
    final f1 = precision + recall == 0
        ? 0.0
        : (2 * precision * recall) / (precision + recall);
    final signedErrors = [
      for (final match in matched) match.signedErrorMs.toDouble(),
    ];
    final absoluteErrors = [
      for (final match in matched) match.absoluteErrorMs.toDouble(),
    ];

    return GaitCalibrationMetrics(
      truePositive: truePositive,
      falsePositive: falsePositive < 0 ? 0 : falsePositive,
      falseNegative: falseNegative < 0 ? 0 : falseNegative,
      precision: precision,
      recall: recall,
      f1: f1,
      signedBiasMs: signedErrors.isEmpty ? null : _average(signedErrors),
      meanAbsoluteErrorMs:
          absoluteErrors.isEmpty ? null : _average(absoluteErrors),
      p95AbsoluteErrorMs:
          absoluteErrors.isEmpty ? null : _percentile(absoluteErrors, 0.95),
    );
  }
}

enum _GaitMatchAction { end, skipTruth, skipPrediction, match }

class _GaitMatchCell {
  final int matchCount;
  final int totalAbsoluteErrorMs;
  final _GaitMatchAction action;

  const _GaitMatchCell({
    required this.matchCount,
    required this.totalAbsoluteErrorMs,
    required this.action,
  });
}

bool _isBetterMatchCell(_GaitMatchCell candidate, _GaitMatchCell current) {
  if (candidate.matchCount != current.matchCount) {
    return candidate.matchCount > current.matchCount;
  }
  if (candidate.totalAbsoluteErrorMs != current.totalAbsoluteErrorMs) {
    return candidate.totalAbsoluteErrorMs < current.totalAbsoluteErrorMs;
  }
  return candidate.action.index > current.action.index;
}

void _checkMinimumInt(
  List<GaitCalibrationQualityGateViolation> violations, {
  required String metric,
  required int actual,
  required int? threshold,
}) {
  if (threshold != null && threshold < 0) {
    throw ArgumentError.value(threshold, metric, 'must be non-negative');
  }
  if (threshold == null || actual >= threshold) {
    return;
  }
  violations.add(
    GaitCalibrationQualityGateViolation(
      metric: metric,
      actual: actual,
      comparison: '>=',
      threshold: threshold,
      message: '$metric must be >= $threshold but was $actual.',
    ),
  );
}

void _checkMinimumDouble(
  List<GaitCalibrationQualityGateViolation> violations, {
  required String metric,
  required double actual,
  required double? threshold,
}) {
  if (threshold != null &&
      (!threshold.isFinite || threshold < 0 || threshold > 1)) {
    throw ArgumentError.value(threshold, metric, 'must be finite and 0 to 1');
  }
  if (threshold == null || actual >= threshold) {
    return;
  }
  violations.add(
    GaitCalibrationQualityGateViolation(
      metric: metric,
      actual: actual,
      comparison: '>=',
      threshold: threshold,
      message: '$metric must be >= ${_roundMetric(threshold)} but was '
          '${_roundMetric(actual)}.',
    ),
  );
}

void _checkMaximumDouble(
  List<GaitCalibrationQualityGateViolation> violations, {
  required String metric,
  required double? actual,
  required double? threshold,
}) {
  if (threshold != null && (!threshold.isFinite || threshold < 0)) {
    throw ArgumentError.value(
      threshold,
      metric,
      'must be finite and non-negative',
    );
  }
  if (threshold == null) {
    return;
  }
  if (actual != null && actual <= threshold) {
    return;
  }
  violations.add(
    GaitCalibrationQualityGateViolation(
      metric: metric,
      actual: actual,
      comparison: '<=',
      threshold: threshold,
      message: actual == null
          ? '$metric must be <= ${_roundMetric(threshold)} but was '
              'unavailable because no events matched.'
          : '$metric must be <= ${_roundMetric(threshold)} but was '
              '${_roundMetric(actual)}.',
    ),
  );
}

int _compareEventsForMatching(
  GaitCalibrationEvent first,
  GaitCalibrationEvent second,
) {
  final timeCompare = first.timestampMs.compareTo(second.timestampMs);
  if (timeCompare != 0) {
    return timeCompare;
  }
  return first.sourceIndex.compareTo(second.sourceIndex);
}

double _average(List<double> values) {
  return values.reduce((sum, value) => sum + value) / values.length;
}

double _percentile(List<double> values, double percentile) {
  final sorted = values.toList(growable: false)..sort();
  final rank = ((sorted.length - 1) * percentile).ceil();
  final clampedRank = rank.clamp(0, sorted.length - 1).toInt();
  return sorted[clampedRank];
}

double _roundMetric(double value) {
  final rounded = double.parse(value.toStringAsFixed(6));
  return rounded == 0 ? 0 : rounded;
}

double? _roundNullable(double? value) {
  return value == null ? null : _roundMetric(value);
}
