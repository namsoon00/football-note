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
    final predictions = GaitCalibrationFixture.fromJsonString(
      await File(parsed.predictionsPath!).readAsString(),
      label: 'predictions',
    );
    final report = GaitCalibrationEvaluator(
      toleranceMs: parsed.toleranceMs,
    ).evaluate(
      groundTruth: groundTruth.events,
      predictions: predictions.events,
    );
    final json = parsed.pretty
        ? const JsonEncoder.withIndent('  ').convert(report.toJson())
        : jsonEncode(report.toJson());
    stdout.writeln(json);
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
  final int toleranceMs;
  final bool pretty;
  final bool help;
  final String? error;

  const _ParsedArgs({
    this.groundTruthPath,
    this.predictionsPath,
    this.toleranceMs = 80,
    this.pretty = false,
    this.help = false,
    this.error,
  });
}

_ParsedArgs _parseArgs(List<String> args) {
  String? groundTruthPath;
  String? predictionsPath;
  var toleranceMs = 80;
  var pretty = false;

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
    toleranceMs: toleranceMs,
    pretty: pretty,
  );
}

const _usage = '''
Usage:
  dart run bin/running_gait_calibration_evaluator.dart \\
    --ground-truth path/to/ground_truth.json \\
    --predictions path/to/predictions.json \\
    [--tolerance-ms 80] [--pretty]
''';
