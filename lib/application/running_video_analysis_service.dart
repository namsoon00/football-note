import 'dart:async';

import 'package:image_picker/image_picker.dart';

import '../domain/entities/running_video_analysis_result.dart';
import '../domain/services/running_analysis_v2.dart';
import 'running_video_analysis_platform_io.dart'
    if (dart.library.html) 'running_video_analysis_platform_web.dart'
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
  /// Files over 120 MB receive the same bounded frame-budget analysis instead
  /// of being rejected before the platform decoder gets a chance to read an
  /// analysis window. The larger ceiling protects browsers from an
  /// unbounded in-memory upload while keeping the previous 120 MB value as a
  /// soft proxy threshold.
  static const proxyPreferredVideoBytes = 120 * 1024 * 1024;
  static const mobileMaxVideoBytes = 512 * 1024 * 1024;
  static const webMaxVideoBytes = 96 * 1024 * 1024;
  static const maxVideoBytes = mobileMaxVideoBytes;
  // A dense 60-second scan can legitimately take longer than the old
  // 14-frame pass, especially on lower-powered phones.
  static const analysisTimeout = Duration(seconds: 120);
  static const previewPoseAnalysisTimeout = Duration(seconds: 8);

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
    if (length > platform.maximumRunningVideoBytes) {
      if (platform.maximumRunningVideoBytes == webMaxVideoBytes) {
        throw const RunningVideoAnalysisException(
          'web_video_too_large',
          'The selected browser video exceeds the 96 MB analysis budget.',
        );
      }
      throw const RunningVideoAnalysisException(
        'video_too_large',
        'The selected video is too large for this platform analysis budget.',
      );
    }
    try {
      final platformResult =
          await platform.analyzeRunningVideo(video).timeout(analysisTimeout);
      return deriveRunningAnalysisV2(platformResult);
    } on TimeoutException {
      throw const RunningVideoAnalysisException(
        'analysis_timeout',
        'Running video analysis timed out.',
      );
    }
  }

  Future<RunningVideoPosePreviewResult> analyzePreviewPose(XFile video) async {
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
    if (length > platform.maximumRunningVideoBytes) {
      if (platform.maximumRunningVideoBytes == webMaxVideoBytes) {
        throw const RunningVideoAnalysisException(
          'web_video_too_large',
          'The selected browser video exceeds the 96 MB analysis budget.',
        );
      }
      throw const RunningVideoAnalysisException(
        'video_too_large',
        'The selected video is too large for this platform analysis budget.',
      );
    }
    try {
      final preview = await platform
          .analyzeRunningVideoPreviewPose(video)
          .timeout(previewPoseAnalysisTimeout);
      if (preview.poseFrames.isEmpty) {
        throw const RunningVideoAnalysisException(
          'preview_pose_unavailable',
          'No readable pose frame was found for preview.',
        );
      }
      return preview;
    } on TimeoutException {
      throw const RunningVideoAnalysisException(
        'preview_pose_timeout',
        'Running video preview pose analysis timed out.',
      );
    }
  }

  static bool isReusableBrowserVideoUrl(String path) {
    final uri = Uri.tryParse(path.trim());
    return uri != null && uri.scheme == 'blob';
  }

  Future<int> _videoLength(XFile video) async {
    try {
      return await video.length();
    } catch (_) {
      return 0;
    }
  }
}
