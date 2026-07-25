import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_quick_video_encoder/flutter_quick_video_encoder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> encodeAndShareTrainingSketchVideo({
  required int width,
  required int height,
  required int framesPerSecond,
  required int frameCount,
  required String filename,
  required Future<Uint8List> Function(int frameIndex) frameProvider,
}) async {
  if (width <= 0 || height <= 0 || frameCount <= 0) {
    throw StateError('Training sketch video has no frames to encode.');
  }
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$filename');
  if (await file.exists()) {
    await file.delete();
  }
  final bitrate = (width * height * framesPerSecond * 0.14)
      .round()
      .clamp(900000, 6000000)
      .toInt();
  var encoderStarted = false;
  try {
    await FlutterQuickVideoEncoder.setup(
      width: width,
      height: height,
      fps: framesPerSecond,
      videoBitrate: bitrate,
      profileLevel: ProfileLevel.baselineAutoLevel,
      audioChannels: 0,
      audioBitrate: 0,
      sampleRate: 0,
      filepath: file.path,
    );
    encoderStarted = true;
    for (var frameIndex = 0; frameIndex < frameCount; frameIndex++) {
      final rgbaBytes = await frameProvider(frameIndex);
      if (rgbaBytes.lengthInBytes != width * height * 4) {
        throw StateError('Training sketch video frame size does not match.');
      }
      await FlutterQuickVideoEncoder.appendVideoFrame(rgbaBytes);
    }
    await FlutterQuickVideoEncoder.finish();
    encoderStarted = false;
    if (!await file.exists() || await file.length() == 0) {
      throw StateError('Training sketch video file is empty.');
    }
    await SharePlus.instance.share(
      ShareParams(
        title: filename,
        files: [XFile(file.path, mimeType: 'video/mp4', name: filename)],
      ),
    );
  } finally {
    if (encoderStarted) {
      await FlutterQuickVideoEncoder.finish();
    }
  }
}
