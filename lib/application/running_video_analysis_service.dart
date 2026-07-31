import 'dart:async';

import 'package:image_picker/image_picker.dart';

import '../domain/entities/running_video_analysis_result.dart';
import 'running_video_analysis_platform_io.dart'
    if (dart.library.js_interop) 'running_video_analysis_platform_web.dart'
    as platform;

class RunningVideoAnalysisException implements Exception {
  final String code;
  final String message;

  const RunningVideoAnalysisException(this.code, this.message);

  @override
  String toString() => 'RunningVideoAnalysisException($code, $message)';
}

/// Uses the native MediaPipe implementation on iOS/Android and the
/// MediaPipe Tasks Vision Web/Wasm bridge in browser builds.
class RunningVideoAnalysisService {
  static const maxVideoBytes = 120 * 1024 * 1024;
  static const analysisTimeout = Duration(seconds: 45);

  const RunningVideoAnalysisService();

  Future<RunningVideoAnalysisResult> analyzeVideo(XFile video) async {
    final path = video.path.trim();
    if (path.isEmpty) {
      throw const RunningVideoAnalysisException(
        'missing_file',
        'Video file is missing.',
      );
    }
    final length = await _videoLength(video);
    if (length <= 0) {
      throw const RunningVideoAnalysisException(
        'missing_file',
        'Video file is missing.',
      );
    }
    if (length > maxVideoBytes) {
      throw const RunningVideoAnalysisException(
        'video_too_large',
        'The selected video is too large for on-device analysis.',
      );
    }
    try {
      return await platform.analyzeRunningVideo(video).timeout(analysisTimeout);
    } on TimeoutException {
      throw const RunningVideoAnalysisException(
        'analysis_timeout',
        'Running video analysis timed out.',
      );
    }
  }

  Future<int> _videoLength(XFile video) async {
    try {
      return await video.length();
    } catch (_) {
      return 0;
    }
  }
}
