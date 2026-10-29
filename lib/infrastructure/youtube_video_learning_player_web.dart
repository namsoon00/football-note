import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import '../application/video_learning_player.dart';
import '../domain/scan_pass/scan_pass_video_learning.dart';

@JS('footballLearningVideo')
external _FootballLearningVideoBridge? get _bridge;

extension type _FootballLearningVideoBridge._(JSObject _) implements JSObject {
  external JSObject create(
    JSObject host,
    JSString configurationJson,
    JSFunction callback,
  );

  external void command(
    JSObject handle,
    JSString name,
    JSNumber? value,
  );

  external void destroy(JSObject handle);
}

VideoLearningPlayerPort createYouTubeVideoLearningPlayer() =>
    YouTubeVideoLearningPlayer();

class YouTubeVideoLearningPlayer
    implements VideoLearningPlayerPort, AttachableVideoLearningPlayerPort {
  final StreamController<VideoLearningPlayerEvent> _events =
      StreamController<VideoLearningPlayerEvent>.broadcast();

  JSObject? _host;
  JSObject? _handle;
  VideoLearningScene? _scene;
  double _initialTime = 0;
  bool _autoplay = false;
  int _generation = 0;
  bool _disposed = false;

  @override
  Stream<VideoLearningPlayerEvent> get events => _events.stream;

  @override
  void attachHost(Object host) {
    if (_disposed || host is! JSObject) return;
    final changed = !identical(_host, host);
    _host = host;
    if (changed && _handle != null) {
      _replacePlayer();
    } else {
      _createIfReady();
    }
  }

  @override
  Future<void> load(
    VideoLearningScene scene, {
    required double initialTime,
    required bool autoplay,
  }) async {
    _scene = scene;
    _initialTime = scene.clip.clamp(initialTime);
    _autoplay = autoplay;
    _replacePlayer();
  }

  void _replacePlayer() {
    final handle = _handle;
    _handle = null;
    _generation++;
    if (handle != null) {
      try {
        _bridge?.destroy(handle);
      } catch (_) {
        // The stale iframe is replaced below; no user state relies on destroy.
      }
    }
    _createIfReady();
  }

  void _createIfReady() {
    final bridge = _bridge;
    final host = _host;
    final scene = _scene;
    if (_disposed ||
        bridge == null ||
        host == null ||
        scene == null ||
        _handle != null) {
      if (bridge == null && scene != null && !_disposed) {
        _events.add(VideoLearningPlayerEvent(
          state: VideoLearningPlayerState.error,
          mediaTime: _initialTime,
          sceneId: scene.id,
          errorCode: 'adapter_unavailable',
        ));
      }
      return;
    }
    final generation = _generation;
    _events.add(VideoLearningPlayerEvent(
      state: VideoLearningPlayerState.loading,
      mediaTime: _initialTime,
      sceneId: scene.id,
    ));
    final callback = ((JSAny? raw) {
      if (_disposed || generation != _generation) return;
      final value = raw?.dartify();
      if (value is! Map) return;
      final event = _eventFromMap(value, scene);
      if (event != null && !_events.isClosed) _events.add(event);
    }).toJS;
    final configuration = jsonEncode(<String, dynamic>{
      'videoId': scene.videoId,
      'start': scene.clip.start,
      'end': scene.clip.end,
      'initialTime': _initialTime,
      'autoplay': _autoplay,
      'origin': Uri.base.hasScheme &&
              (Uri.base.scheme == 'http' || Uri.base.scheme == 'https')
          ? Uri.base.origin
          : '',
    });
    try {
      _handle = bridge.create(host, configuration.toJS, callback);
    } catch (_) {
      _events.add(VideoLearningPlayerEvent(
        state: VideoLearningPlayerState.error,
        mediaTime: _initialTime,
        sceneId: scene.id,
        errorCode: 'adapter_create_failed',
      ));
    }
  }

  VideoLearningPlayerEvent? _eventFromMap(
    Map<dynamic, dynamic> value,
    VideoLearningScene scene,
  ) {
    final type = value['type'];
    final rawTime = value['time'];
    final time = rawTime is num && rawTime.isFinite
        ? scene.clip.clamp(rawTime.toDouble())
        : _initialTime;
    final state = switch (type) {
      'loading' => VideoLearningPlayerState.loading,
      'ready' => VideoLearningPlayerState.ready,
      'playing' || 'time' => VideoLearningPlayerState.playing,
      'paused' => VideoLearningPlayerState.paused,
      'ended' => VideoLearningPlayerState.ended,
      'rate' => VideoLearningPlayerState.rateChanged,
      'error' => VideoLearningPlayerState.error,
      _ => null,
    };
    if (state == null) return null;
    final rates = <double>[];
    final rawRates = value['rates'];
    if (rawRates is List) {
      for (final rate in rawRates) {
        if (rate is num && rate.isFinite && rate > 0) {
          rates.add(rate.toDouble());
        }
      }
    }
    return VideoLearningPlayerEvent(
      state: state,
      mediaTime: time,
      sceneId: scene.id,
      supportedRates: List.unmodifiable(rates),
      playbackRate:
          value['rate'] is num ? (value['rate'] as num).toDouble() : null,
      errorCode: value['code']?.toString(),
    );
  }

  void _command(String name, [double? value]) {
    final bridge = _bridge;
    final handle = _handle;
    if (_disposed || bridge == null || handle == null) return;
    bridge.command(handle, name.toJS, value?.toJS);
  }

  @override
  Future<void> pause() async => _command('pause');

  @override
  Future<void> play() async => _command('play');

  @override
  Future<void> seek(double mediaTime) async => _command('seek', mediaTime);

  @override
  Future<void> setPlaybackRate(double rate) async => _command('rate', rate);

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    final handle = _handle;
    _handle = null;
    if (handle != null) {
      try {
        _bridge?.destroy(handle);
      } catch (_) {
        // Disposing a browser-owned iframe is best effort.
      }
    }
    await _events.close();
  }
}
