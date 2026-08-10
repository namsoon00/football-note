import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:image_picker/image_picker.dart';

import '../domain/entities/running_video_analysis_result.dart';
import 'running_video_analysis_service.dart';

const _bridgeName = 'runningVideoPoseAnalysis';
const maximumRunningVideoBytes = RunningVideoAnalysisService.webMaxVideoBytes;

@JS(_bridgeName)
external _RunningVideoPoseAnalyzer? get _runningVideoPoseAnalyzer;

extension type _RunningVideoPoseAnalyzer._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> analyze(JSUint8Array bytes, JSString name);
  external JSPromise<JSAny?> analyzeUrl(JSString url, JSString name);
}

Future<RunningVideoAnalysisResult> analyzeRunningVideo(XFile video) async {
  final bridge = _runningVideoPoseAnalyzer;
  if (bridge == null) {
    throw const RunningVideoAnalysisException(
      'web_analyzer_unavailable',
      'The MediaPipe Web analyzer has not loaded.',
    );
  }

  try {
    final path = video.path.trim();
    final JSAny? rawResult;
    if (RunningVideoAnalysisService.isReusableBrowserVideoUrl(path)) {
      // image_picker exposes the browser-owned Blob URL. Passing it directly
      // avoids Dart bytes -> JSUint8Array -> Blob copies of the whole video.
      rawResult = await bridge.analyzeUrl(path.toJS, video.name.toJS).toDart;
    } else {
      // Non-picker XFiles keep a bounded compatibility path. The facade has
      // already rejected anything above the web-specific memory ceiling.
      final bytes = await video.readAsBytes();
      if (bytes.isEmpty) {
        throw const RunningVideoAnalysisException(
          'missing_file',
          'Video file is missing.',
        );
      }
      rawResult = await bridge.analyze(bytes.toJS, video.name.toJS).toDart;
    }
    final converted = rawResult.dartify();
    if (converted is! Map) {
      throw const RunningVideoAnalysisException(
        'empty_result',
        'The web analyzer returned no data.',
      );
    }
    return RunningVideoAnalysisResult.fromMap(
      converted.map<Object?, Object?>((key, value) => MapEntry(key, value)),
    );
  } on RunningVideoAnalysisException {
    rethrow;
  } catch (error) {
    final code = _errorCode(error);
    final message = _errorMessage(error);
    throw RunningVideoAnalysisException(code, message);
  }
}

String _errorCode(Object error) {
  final value = _errorProperty(error, 'code');
  if (value is String && value.isNotEmpty) return value;
  return 'mediapipe_pose_failed';
}

String _errorMessage(Object error) {
  final value = _errorProperty(error, 'message');
  if (value is String && value.isNotEmpty) return value;
  return 'Running video analysis failed.';
}

Object? _errorProperty(Object error, String name) {
  if (error is JSObject) {
    final value = error[name];
    if (value is JSString) {
      return value.toDart;
    }
  }
  return null;
}
