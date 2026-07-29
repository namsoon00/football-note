import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/entities/running_video_analysis_result.dart';
import 'running_video_analysis_service.dart';

const _channel = MethodChannel('football_note/running_pose_analysis');

Future<RunningVideoAnalysisResult> analyzeRunningVideo(XFile video) async {
  if (!(Platform.isAndroid || Platform.isIOS)) {
    throw const RunningVideoAnalysisException(
      'unsupported_platform',
      'Running video analysis is not available on this platform.',
    );
  }

  final path = video.path.trim();
  if (path.isEmpty) {
    throw const RunningVideoAnalysisException(
      'missing_file',
      'Video file is missing.',
    );
  }

  try {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'analyzeRunningVideo',
      <String, Object?>{'path': path},
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
