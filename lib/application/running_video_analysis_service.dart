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
  const RunningVideoAnalysisService();

  Future<RunningVideoAnalysisResult> analyzeVideo(XFile video) {
    return platform.analyzeRunningVideo(video);
  }
}
