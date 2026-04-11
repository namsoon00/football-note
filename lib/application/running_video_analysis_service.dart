import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/entities/running_video_analysis_result.dart';

class RunningVideoAnalysisException implements Exception {
  final String code;
  final String message;

  const RunningVideoAnalysisException(this.code, this.message);

  @override
  String toString() => 'RunningVideoAnalysisException($code, $message)';
}

class RunningVideoAnalysisService {
  static const MethodChannel _channel = MethodChannel(
    'football_note/running_pose_analysis',
  );

  const RunningVideoAnalysisService();

  Future<RunningVideoAnalysisResult> analyzeVideo(String path) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      throw const RunningVideoAnalysisException(
        'unsupported_platform',
        'Running video analysis is not available on web.',
      );
    }

    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'analyzeRunningVideo',
        {'path': path},
      );
      if (result == null) {
        throw const RunningVideoAnalysisException(
          'empty_result',
          'The platform analyzer returned no data.',
        );
      }
      return RunningVideoAnalysisResult.fromMap(result);
    } on PlatformException catch (error) {
      throw RunningVideoAnalysisException(
        error.code,
        error.message ?? 'Running video analysis failed.',
      );
    } on MissingPluginException {
      throw const RunningVideoAnalysisException(
        'native_analyzer_unavailable',
        'Running video analysis is not available in this app build.',
      );
    }
  }
}
