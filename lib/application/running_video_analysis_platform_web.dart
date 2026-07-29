import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:image_picker/image_picker.dart';

import '../domain/entities/running_video_analysis_result.dart';
import 'running_video_analysis_service.dart';

const _bridgeName = 'runningVideoPoseAnalysis';

@JS(_bridgeName)
external _RunningVideoPoseAnalyzer? get _runningVideoPoseAnalyzer;

extension type _RunningVideoPoseAnalyzer._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> analyze(JSUint8Array bytes, JSString name);
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
    final bytes = await video.readAsBytes();
    if (bytes.isEmpty) {
      throw const RunningVideoAnalysisException(
        'missing_file',
        'Video file is missing.',
      );
    }
    final rawResult = await bridge.analyze(bytes.toJS, video.name.toJS).toDart;
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
