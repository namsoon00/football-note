import 'dart:typed_data';

Future<void> encodeAndShareTrainingSketchVideo({
  required int width,
  required int height,
  required int framesPerSecond,
  required int frameCount,
  required String filename,
  required Future<Uint8List> Function(int frameIndex) frameProvider,
}) {
  throw UnsupportedError('Training sketch video export is unavailable.');
}
