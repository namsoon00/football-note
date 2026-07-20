import 'dart:convert';
import 'dart:io';

import 'package:football_note/application/running_gait_calibration_evaluator.dart';

Future<void> main(List<String> args) async {
  final parsed = _parseArgs(args);
  if (parsed.help) {
    stdout.writeln(_usage);
    return;
  }
  if (parsed.error != null) {
    stderr.writeln(parsed.error);
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }

  try {
    final groundTruth = GaitCalibrationFixture.fromJsonString(
      await File(parsed.groundTruthPath!).readAsString(),
      label: 'ground-truth',
    );
    final predictions = GaitCalibrationFixture.fromPredictionSourceString(
      await File(parsed.predictionsPath!).readAsString(),
      label: 'predictions',
      sessionId: parsed.predictionSessionId,
    );
    final report = GaitCalibrationEvaluator(
      toleranceMs: parsed.toleranceMs,
      qualityGate: parsed.qualityGate,
    ).evaluate(
      groundTruth: groundTruth.events,
      predictions: predictions.events,
    );
    final reportJson = report.toJson()
      ..['predictionInput'] = predictions.sourceMetadataToJson();
    final json = parsed.pretty
        ? const JsonEncoder.withIndent('  ').convert(reportJson)
        : jsonEncode(reportJson);
    stdout.writeln(json);
    if (!report.qualityGate.passed) {
      stderr.writeln(
        'Quality gate failed with '
        '${report.qualityGate.violations.length} violation(s).',
      );
      exitCode = 2;
    }
  } on GaitCalibrationInputException catch (error) {
    stderr.writeln(error.message);
    exitCode = 65;
  } on FileSystemException catch (error) {
    stderr.writeln('Unable to read input file: ${error.message}');
    exitCode = 66;
  }
}

class _ParsedArgs {
  final String? groundTruthPath;
  final String? predictionsPath;
  final String? predictionSessionId;
  final int toleranceMs;
  final GaitCalibrationQualityGate qualityGate;
  final bool pretty;
  final bool help;
  final String? error;

  const _ParsedArgs({
    this.groundTruthPath,
    this.predictionsPath,
    this.predictionSessionId,
    this.toleranceMs = 80,
    this.qualityGate = const GaitCalibrationQualityGate(),
    this.pretty = false,
    this.help = false,
    this.error,
  });
}

_ParsedArgs _parseArgs(List<String> args) {
  String? groundTruthPath;
  String? predictionsPath;
  String? predictionSessionId;
  var toleranceMs = 80;
  var pretty = false;
  int? minGroundTruthEvents;
  double? minOverallPrecision;
  double? minOverallRecall;
  double? minOverallF1;
  double? maxTimingMeanAbsoluteErrorMs;
  double? maxTimingP95AbsoluteErrorMs;
  double? minTouchdownPrecision;
  double? minTouchdownRecall;
  double? minToeOffPrecision;
  double? minToeOffRecall;

  for (var index = 0; index < args.length; index += 1) {
    final arg = args[index];
    if (arg == '--help' || arg == '-h') {
      return const _ParsedArgs(help: true);
    }
    if (arg == '--pretty') {
      pretty = true;
      continue;
    }
    if (arg == '--ground-truth') {
      if (index + 1 >= args.length) {
        return const _ParsedArgs(error: 'Missing value for --ground-truth.');
      }
      groundTruthPath = args[++index];
      continue;
    }
    if (arg == '--predictions') {
      if (index + 1 >= args.length) {
        return const _ParsedArgs(error: 'Missing value for --predictions.');
      }
      predictionsPath = args[++index];
      continue;
    }
    if (arg == '--prediction-session-id') {
      if (index + 1 >= args.length) {
        return const _ParsedArgs(
          error: 'Missing value for --prediction-session-id.',
        );
      }
      final parsedSessionId = args[++index];
      if (parsedSessionId.isEmpty) {
        return const _ParsedArgs(
          error: '--prediction-session-id must be non-empty.',
        );
      }
      predictionSessionId = parsedSessionId;
      continue;
    }
    if (arg == '--tolerance-ms') {
      if (index + 1 >= args.length) {
        return const _ParsedArgs(error: 'Missing value for --tolerance-ms.');
      }
      final parsedTolerance = int.tryParse(args[++index]);
      if (parsedTolerance == null || parsedTolerance < 0) {
        return const _ParsedArgs(
          error: '--tolerance-ms must be a non-negative integer.',
        );
      }
      toleranceMs = parsedTolerance;
      continue;
    }
    if (arg == '--min-ground-truth-events') {
      if (index + 1 >= args.length) {
        return const _ParsedArgs(
          error: 'Missing value for --min-ground-truth-events.',
        );
      }
      final parsedThreshold = int.tryParse(args[++index]);
      if (parsedThreshold == null || parsedThreshold < 0) {
        return const _ParsedArgs(
          error: '--min-ground-truth-events must be a non-negative integer.',
        );
      }
      minGroundTruthEvents = parsedThreshold;
      continue;
    }
    if (arg == '--min-overall-precision') {
      if (index + 1 >= args.length) {
        return const _ParsedArgs(
          error: 'Missing value for --min-overall-precision.',
        );
      }
      final parsedThreshold = _parseUnitIntervalThreshold(args[++index], arg);
      if (parsedThreshold.error != null) {
        return _ParsedArgs(error: parsedThreshold.error);
      }
      minOverallPrecision = parsedThreshold.value;
      continue;
    }
    if (arg == '--min-overall-recall') {
      if (index + 1 >= args.length) {
        return const _ParsedArgs(
          error: 'Missing value for --min-overall-recall.',
        );
      }
      final parsedThreshold = _parseUnitIntervalThreshold(args[++index], arg);
      if (parsedThreshold.error != null) {
        return _ParsedArgs(error: parsedThreshold.error);
      }
      minOverallRecall = parsedThreshold.value;
      continue;
    }
    if (arg == '--min-overall-f1') {
      if (index + 1 >= args.length) {
        return const _ParsedArgs(error: 'Missing value for --min-overall-f1.');
      }
      final parsedThreshold = _parseUnitIntervalThreshold(args[++index], arg);
      if (parsedThreshold.error != null) {
        return _ParsedArgs(error: parsedThreshold.error);
      }
      minOverallF1 = parsedThreshold.value;
      continue;
    }
    if (arg == '--max-timing-mae-ms') {
      if (index + 1 >= args.length) {
        return const _ParsedArgs(
            error: 'Missing value for --max-timing-mae-ms.');
      }
      final parsedThreshold = _parseNonNegativeDoubleThreshold(
        args[++index],
        arg,
      );
      if (parsedThreshold.error != null) {
        return _ParsedArgs(error: parsedThreshold.error);
      }
      maxTimingMeanAbsoluteErrorMs = parsedThreshold.value;
      continue;
    }
    if (arg == '--max-timing-p95-ms') {
      if (index + 1 >= args.length) {
        return const _ParsedArgs(
            error: 'Missing value for --max-timing-p95-ms.');
      }
      final parsedThreshold = _parseNonNegativeDoubleThreshold(
        args[++index],
        arg,
      );
      if (parsedThreshold.error != null) {
        return _ParsedArgs(error: parsedThreshold.error);
      }
      maxTimingP95AbsoluteErrorMs = parsedThreshold.value;
      continue;
    }
    if (arg == '--min-touchdown-precision') {
      if (index + 1 >= args.length) {
        return const _ParsedArgs(
          error: 'Missing value for --min-touchdown-precision.',
        );
      }
      final parsedThreshold = _parseUnitIntervalThreshold(args[++index], arg);
      if (parsedThreshold.error != null) {
        return _ParsedArgs(error: parsedThreshold.error);
      }
      minTouchdownPrecision = parsedThreshold.value;
      continue;
    }
    if (arg == '--min-touchdown-recall') {
      if (index + 1 >= args.length) {
        return const _ParsedArgs(
          error: 'Missing value for --min-touchdown-recall.',
        );
      }
      final parsedThreshold = _parseUnitIntervalThreshold(args[++index], arg);
      if (parsedThreshold.error != null) {
        return _ParsedArgs(error: parsedThreshold.error);
      }
      minTouchdownRecall = parsedThreshold.value;
      continue;
    }
    if (arg == '--min-toe-off-precision' || arg == '--min-toeOff-precision') {
      if (index + 1 >= args.length) {
        return const _ParsedArgs(
          error: 'Missing value for --min-toe-off-precision.',
        );
      }
      final parsedThreshold = _parseUnitIntervalThreshold(args[++index], arg);
      if (parsedThreshold.error != null) {
        return _ParsedArgs(error: parsedThreshold.error);
      }
      minToeOffPrecision = parsedThreshold.value;
      continue;
    }
    if (arg == '--min-toe-off-recall' || arg == '--min-toeOff-recall') {
      if (index + 1 >= args.length) {
        return const _ParsedArgs(
          error: 'Missing value for --min-toe-off-recall.',
        );
      }
      final parsedThreshold = _parseUnitIntervalThreshold(args[++index], arg);
      if (parsedThreshold.error != null) {
        return _ParsedArgs(error: parsedThreshold.error);
      }
      minToeOffRecall = parsedThreshold.value;
      continue;
    }
    return _ParsedArgs(error: 'Unknown argument: $arg');
  }

  if (groundTruthPath == null) {
    return const _ParsedArgs(error: 'Missing required --ground-truth path.');
  }
  if (predictionsPath == null) {
    return const _ParsedArgs(error: 'Missing required --predictions path.');
  }

  return _ParsedArgs(
    groundTruthPath: groundTruthPath,
    predictionsPath: predictionsPath,
    predictionSessionId: predictionSessionId,
    toleranceMs: toleranceMs,
    qualityGate: GaitCalibrationQualityGate(
      minGroundTruthEvents: minGroundTruthEvents,
      minOverallPrecision: minOverallPrecision,
      minOverallRecall: minOverallRecall,
      minOverallF1: minOverallF1,
      maxTimingMeanAbsoluteErrorMs: maxTimingMeanAbsoluteErrorMs,
      maxTimingP95AbsoluteErrorMs: maxTimingP95AbsoluteErrorMs,
      minTouchdownPrecision: minTouchdownPrecision,
      minTouchdownRecall: minTouchdownRecall,
      minToeOffPrecision: minToeOffPrecision,
      minToeOffRecall: minToeOffRecall,
    ),
    pretty: pretty,
  );
}

class _ParsedDoubleArg {
  final double? value;
  final String? error;

  const _ParsedDoubleArg({this.value, this.error});
}

_ParsedDoubleArg _parseUnitIntervalThreshold(String raw, String flag) {
  final value = double.tryParse(raw);
  if (value == null || value < 0 || value > 1) {
    return _ParsedDoubleArg(error: '$flag must be a number from 0 to 1.');
  }
  return _ParsedDoubleArg(value: value);
}

_ParsedDoubleArg _parseNonNegativeDoubleThreshold(String raw, String flag) {
  final value = double.tryParse(raw);
  if (value == null || value < 0) {
    return _ParsedDoubleArg(error: '$flag must be a non-negative number.');
  }
  return _ParsedDoubleArg(value: value);
}

const _usage = '''
Usage:
  dart bin/running_gait_calibration_evaluator.dart \\
    --ground-truth path/to/ground_truth.json \\
    --predictions path/to/predictions.json \\
    [--prediction-session-id running-123] \\
    [--tolerance-ms 80] [--pretty] \\
    [--min-ground-truth-events 20] \\
    [--min-overall-precision 0.95] [--min-overall-recall 0.95] \\
    [--min-overall-f1 0.95] \\
    [--max-timing-mae-ms 25] [--max-timing-p95-ms 60] \\
    [--min-touchdown-precision 0.95] [--min-touchdown-recall 0.95] \\
    [--min-toe-off-precision 0.95] [--min-toe-off-recall 0.95]
''';
