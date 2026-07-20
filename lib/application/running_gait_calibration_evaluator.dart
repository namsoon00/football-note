import 'dart:convert';

enum GaitCalibrationFootSide { left, right }

enum GaitCalibrationEventType { touchdown, toeOff }

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

  const GaitCalibrationFixture({required this.events});

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

class GaitCalibrationReport {
  final int toleranceMs;
  final GaitCalibrationMetrics overall;
  final Map<GaitCalibrationEventType, GaitCalibrationMetrics> byEventType;
  final List<GaitCalibrationMatch> matches;

  const GaitCalibrationReport({
    required this.toleranceMs,
    required this.overall,
    required this.byEventType,
    required this.matches,
  });

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'toleranceMs': toleranceMs,
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

  const GaitCalibrationEvaluator({required this.toleranceMs})
      : assert(toleranceMs >= 0);

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

    return GaitCalibrationReport(
      toleranceMs: toleranceMs,
      overall: _metricsFor(
        groundTruth: groundTruth,
        predictions: predictions,
        matches: matches,
      ),
      byEventType: <GaitCalibrationEventType, GaitCalibrationMetrics>{
        for (final type in GaitCalibrationEventType.values)
          type: _metricsFor(
            groundTruth: groundTruth.where((event) => event.type == type),
            predictions: predictions.where((event) => event.type == type),
            matches: matches.where(
              (match) => match.groundTruth.type == type,
            ),
          ),
      },
      matches: List.unmodifiable(matches),
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
