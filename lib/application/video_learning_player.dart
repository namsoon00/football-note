import 'dart:async';

import '../domain/scan_pass/scan_pass_video_learning.dart';

enum VideoLearningPlayerState {
  idle,
  loading,
  ready,
  playing,
  paused,
  ended,
  rateChanged,
  error,
}

class VideoLearningPlayerEvent {
  final VideoLearningPlayerState state;
  final double mediaTime;
  final String? sceneId;
  final List<double> supportedRates;
  final double? playbackRate;
  final String? errorCode;

  const VideoLearningPlayerEvent({
    required this.state,
    required this.mediaTime,
    this.sceneId,
    this.supportedRates = const <double>[],
    this.playbackRate,
    this.errorCode,
  });
}

abstract interface class VideoLearningPlayerPort {
  Stream<VideoLearningPlayerEvent> get events;

  Future<void> load(
    VideoLearningScene scene, {
    required double initialTime,
    required bool autoplay,
  });

  Future<void> play();

  Future<void> pause();

  Future<void> seek(double mediaTime);

  Future<void> setPlaybackRate(double rate);

  Future<void> dispose();
}

abstract interface class AttachableVideoLearningPlayerPort {
  void attachHost(Object host);
}
