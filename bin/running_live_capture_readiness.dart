import 'dart:convert';
import 'dart:io';

import 'package:football_note/application/running_gait_calibration_evaluator.dart';
import 'package:football_note/application/running_live_capture_readiness_evaluator.dart';

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
    final fixture = GaitCalibrationFixture.fromPredictionSourceString(
      await File(parsed.logPath!).readAsString(),
      label: 'live-session-log',
      sessionId: parsed.sessionId,
    );
    final report = RunningLiveCaptureReadinessEvaluator(
      readinessGate: parsed.readinessGate,
    ).evaluate(fixture);
    final json = parsed.pretty
        ? const JsonEncoder.withIndent('  ').convert(report.toJson())
        : jsonEncode(report.toJson());
    stdout.writeln(json);
    if (!report.readinessGate.passed) {
      stderr.writeln(
        'Capture readiness gate failed with '
        '${report.readinessGate.violations.length} violation(s).',
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
  final String? logPath;
  final String? sessionId;
  final RunningLiveCaptureReadinessGate? readinessGate;
  final bool pretty;
  final bool help;
  final String? error;

  const _ParsedArgs({
    this.logPath,
    this.sessionId,
    this.readinessGate,
    this.pretty = false,
    this.help = false,
    this.error,
  });
}

_ParsedArgs _parseArgs(List<String> args) {
  String? logPath;
  String? sessionId;
  var pretty = false;
  var minElapsedMs = 5000;
  var minAnalyzedFrames = 80;
  var minAnalyzedFrameIntervalSamples = 80;
  int? maxTargetFrameIntervalMs;
  double? maxAnalyzedFrameIntervalP95Ms;
  var minTimingConfidence = 0.70;
  var minSideViewConfidence = 0.70;
  var minGaitEvents = 12;
  var maxAnalysisErrorFrames = 0;

  for (var index = 0; index < args.length; index += 1) {
    final arg = args[index];
    if (arg == '--help' || arg == '-h') {
      return const _ParsedArgs(help: true);
    }
    if (arg == '--pretty') {
      pretty = true;
      continue;
    }
    if (arg == '--logs') {
      if (index + 1 >= args.length) {
        return const _ParsedArgs(error: 'Missing value for --logs.');
      }
      logPath = args[++index];
      continue;
    }
    if (arg == '--session-id') {
      if (index + 1 >= args.length) {
        return const _ParsedArgs(error: 'Missing value for --session-id.');
      }
      final value = args[++index];
      if (value.isEmpty) {
        return const _ParsedArgs(error: '--session-id must be non-empty.');
      }
      sessionId = value;
      continue;
    }
    if (arg == '--min-elapsed-ms') {
      final parsed = _requiredPositiveInt(args, index, arg);
      if (parsed.error != null) {
        return _ParsedArgs(error: parsed.error);
      }
      minElapsedMs = parsed.value!;
      index = parsed.nextIndex;
      continue;
    }
    if (arg == '--min-analyzed-frames') {
      final parsed = _requiredPositiveInt(args, index, arg);
      if (parsed.error != null) {
        return _ParsedArgs(error: parsed.error);
      }
      minAnalyzedFrames = parsed.value!;
      index = parsed.nextIndex;
      continue;
    }
    if (arg == '--min-analyzed-frame-interval-samples') {
      final parsed = _requiredPositiveInt(args, index, arg);
      if (parsed.error != null) {
        return _ParsedArgs(error: parsed.error);
      }
      minAnalyzedFrameIntervalSamples = parsed.value!;
      index = parsed.nextIndex;
      continue;
    }
    if (arg == '--max-target-frame-interval-ms') {
      final parsed = _requiredPositiveInt(args, index, arg);
      if (parsed.error != null) {
        return _ParsedArgs(error: parsed.error);
      }
      maxTargetFrameIntervalMs = parsed.value!;
      index = parsed.nextIndex;
      continue;
    }
    if (arg == '--max-analyzed-frame-p95-ms') {
      final parsed = _requiredPositiveDouble(args, index, arg);
      if (parsed.error != null) {
        return _ParsedArgs(error: parsed.error);
      }
      maxAnalyzedFrameIntervalP95Ms = parsed.value!;
      index = parsed.nextIndex;
      continue;
    }
    if (arg == '--min-timing-confidence') {
      final parsed = _requiredUnitInterval(args, index, arg);
      if (parsed.error != null) {
        return _ParsedArgs(error: parsed.error);
      }
      minTimingConfidence = parsed.value!;
      index = parsed.nextIndex;
      continue;
    }
    if (arg == '--min-side-view-confidence') {
      final parsed = _requiredUnitInterval(args, index, arg);
      if (parsed.error != null) {
        return _ParsedArgs(error: parsed.error);
      }
      minSideViewConfidence = parsed.value!;
      index = parsed.nextIndex;
      continue;
    }
    if (arg == '--min-gait-events') {
      final parsed = _requiredPositiveInt(args, index, arg);
      if (parsed.error != null) {
        return _ParsedArgs(error: parsed.error);
      }
      minGaitEvents = parsed.value!;
      index = parsed.nextIndex;
      continue;
    }
    if (arg == '--max-analysis-error-frames') {
      final parsed = _requiredNonNegativeInt(args, index, arg);
      if (parsed.error != null) {
        return _ParsedArgs(error: parsed.error);
      }
      maxAnalysisErrorFrames = parsed.value!;
      index = parsed.nextIndex;
      continue;
    }
    return _ParsedArgs(error: 'Unknown argument: $arg');
  }

  if (logPath == null) {
    return const _ParsedArgs(error: 'Missing required --logs path.');
  }

  return _ParsedArgs(
    logPath: logPath,
    sessionId: sessionId,
    readinessGate: RunningLiveCaptureReadinessGate(
      minElapsedMs: minElapsedMs,
      minAnalyzedFrames: minAnalyzedFrames,
      minAnalyzedFrameIntervalSamples: minAnalyzedFrameIntervalSamples,
      maxTargetFrameIntervalMs: maxTargetFrameIntervalMs,
      maxAnalyzedFrameIntervalP95Ms: maxAnalyzedFrameIntervalP95Ms,
      minTimingConfidence: minTimingConfidence,
      minSideViewConfidence: minSideViewConfidence,
      minGaitEvents: minGaitEvents,
      maxAnalysisErrorFrames: maxAnalysisErrorFrames,
    ),
    pretty: pretty,
  );
}

class _ParsedIntArg {
  final int? value;
  final int nextIndex;
  final String? error;

  const _ParsedIntArg({
    this.value,
    required this.nextIndex,
    this.error,
  });
}

class _ParsedDoubleArg {
  final double? value;
  final int nextIndex;
  final String? error;

  const _ParsedDoubleArg({
    this.value,
    required this.nextIndex,
    this.error,
  });
}

_ParsedIntArg _requiredPositiveInt(List<String> args, int index, String flag) {
  if (index + 1 >= args.length) {
    return _ParsedIntArg(
      nextIndex: index,
      error: 'Missing value for $flag.',
    );
  }
  final value = int.tryParse(args[index + 1]);
  if (value == null || value <= 0) {
    return _ParsedIntArg(
      nextIndex: index,
      error: '$flag must be a positive integer.',
    );
  }
  return _ParsedIntArg(value: value, nextIndex: index + 1);
}

_ParsedIntArg _requiredNonNegativeInt(
  List<String> args,
  int index,
  String flag,
) {
  if (index + 1 >= args.length) {
    return _ParsedIntArg(
      nextIndex: index,
      error: 'Missing value for $flag.',
    );
  }
  final value = int.tryParse(args[index + 1]);
  if (value == null || value < 0) {
    return _ParsedIntArg(
      nextIndex: index,
      error: '$flag must be a non-negative integer.',
    );
  }
  return _ParsedIntArg(value: value, nextIndex: index + 1);
}

_ParsedDoubleArg _requiredPositiveDouble(
  List<String> args,
  int index,
  String flag,
) {
  if (index + 1 >= args.length) {
    return _ParsedDoubleArg(
      nextIndex: index,
      error: 'Missing value for $flag.',
    );
  }
  final value = double.tryParse(args[index + 1]);
  if (value == null || !value.isFinite || value <= 0) {
    return _ParsedDoubleArg(
      nextIndex: index,
      error: '$flag must be a positive number.',
    );
  }
  return _ParsedDoubleArg(value: value, nextIndex: index + 1);
}

_ParsedDoubleArg _requiredUnitInterval(
  List<String> args,
  int index,
  String flag,
) {
  if (index + 1 >= args.length) {
    return _ParsedDoubleArg(
      nextIndex: index,
      error: 'Missing value for $flag.',
    );
  }
  final value = double.tryParse(args[index + 1]);
  if (value == null || !value.isFinite || value < 0 || value > 1) {
    return _ParsedDoubleArg(
      nextIndex: index,
      error: '$flag must be a number from 0 to 1.',
    );
  }
  return _ParsedDoubleArg(value: value, nextIndex: index + 1);
}

const _usage = '''
Usage:
  dart bin/running_live_capture_readiness.dart \\
    --logs path/to/running_live_debug.log \\
    [--session-id running-123] [--pretty] \\
    [--min-elapsed-ms 5000] [--min-analyzed-frames 80] \\
    [--min-analyzed-frame-interval-samples 80] \\
    [--max-target-frame-interval-ms 50] \\
    [--max-analyzed-frame-p95-ms 90] \\
    [--min-timing-confidence 0.70] [--min-side-view-confidence 0.70] \\
    [--min-gait-events 12] [--max-analysis-error-frames 0]
''';
