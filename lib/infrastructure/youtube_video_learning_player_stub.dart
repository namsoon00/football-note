import 'dart:async';

import '../application/video_learning_player.dart';
import '../domain/scan_pass/scan_pass_video_learning.dart';

VideoLearningPlayerPort createYouTubeVideoLearningPlayer() =>
    NativeVideoLearningPlayerStub();

class NativeVideoLearningPlayerStub implements VideoLearningPlayerPort {
  final StreamController<VideoLearningPlayerEvent> _events =
      StreamController<VideoLearningPlayerEvent>.broadcast();
  double _time = 0;

  @override
  Stream<VideoLearningPlayerEvent> get events => _events.stream;

  @override
  Future<void> load(
    VideoLearningScene scene, {
    required double initialTime,
    required bool autoplay,
  }) async {
    _time = scene.clip.clamp(initialTime);
    _events.add(VideoLearningPlayerEvent(
      state: VideoLearningPlayerState.error,
      mediaTime: _time,
      sceneId: scene.id,
      errorCode: 'native_unavailable',
    ));
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> seek(double mediaTime) async => _time = mediaTime;

  @override
  Future<void> setPlaybackRate(double rate) async {}

  @override
  Future<void> dispose() async => _events.close();
}
