import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../gen/app_localizations.dart';
import '../screens/running_video_player_source.dart';

const runningEvidenceLoopLead = Duration(milliseconds: 500);
const runningEvidenceLoopTrail = Duration(milliseconds: 800);
const runningEvidencePlaybackSpeed = 0.5;

(Duration, Duration) runningEvidenceLoopWindow(
  Duration target,
  Duration duration,
) {
  final startMs =
      (target.inMilliseconds - runningEvidenceLoopLead.inMilliseconds)
          .clamp(0, duration.inMilliseconds)
          .toInt();
  final endMs =
      (target.inMilliseconds + runningEvidenceLoopTrail.inMilliseconds)
          .clamp(startMs, duration.inMilliseconds)
          .toInt();
  return (
    Duration(milliseconds: startMs),
    Duration(milliseconds: endMs),
  );
}

Future<void> showRunningEvidenceSlowLoopSheet({
  required BuildContext context,
  required String? videoPath,
  required Duration timestamp,
  Uint8List? capturedFrame,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => RunningEvidenceSlowLoopSheet(
      videoPath: videoPath,
      timestamp: timestamp,
      capturedFrame: capturedFrame,
    ),
  );
}

class RunningEvidenceSlowLoopSheet extends StatefulWidget {
  final String? videoPath;
  final Duration timestamp;
  final Uint8List? capturedFrame;

  const RunningEvidenceSlowLoopSheet({
    super.key,
    required this.videoPath,
    required this.timestamp,
    this.capturedFrame,
  });

  @override
  State<RunningEvidenceSlowLoopSheet> createState() =>
      _RunningEvidenceSlowLoopSheetState();
}

class _RunningEvidenceSlowLoopSheetState
    extends State<RunningEvidenceSlowLoopSheet> {
  VideoPlayerController? _controller;
  (Duration, Duration)? _loopWindow;
  var _loading = true;
  var _unavailable = false;
  var _isRewinding = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    final path = widget.videoPath?.trim();
    if (path == null || path.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _unavailable = true;
        });
      }
      return;
    }
    VideoPlayerController? controller;
    try {
      controller = await openRunningVideoPlayer(path);
      if (controller == null) throw StateError('video_unavailable');
      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(0);
      await controller.setPlaybackSpeed(runningEvidencePlaybackSpeed);
      final window = runningEvidenceLoopWindow(
        widget.timestamp,
        controller.value.duration,
      );
      await controller.seekTo(window.$1);
      controller.addListener(_enforceLoopBoundary);
      await controller.play();
      if (!mounted) {
        controller.removeListener(_enforceLoopBoundary);
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loopWindow = window;
        _loading = false;
      });
    } catch (_) {
      if (controller != null) {
        controller.removeListener(_enforceLoopBoundary);
        await controller.dispose();
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _unavailable = true;
        });
      }
    }
  }

  void _enforceLoopBoundary() {
    final controller = _controller;
    final window = _loopWindow;
    if (controller == null || window == null || _isRewinding) return;
    if (controller.value.position < window.$2) {
      if (mounted) setState(() {});
      return;
    }
    _isRewinding = true;
    unawaited(() async {
      try {
        await controller.seekTo(window.$1);
        if (!controller.value.isPlaying) await controller.play();
      } finally {
        _isRewinding = false;
        if (mounted) setState(() {});
      }
    }());
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      final window = _loopWindow;
      if (window != null && controller.value.position >= window.$2) {
        await controller.seekTo(window.$1);
      }
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final controller = _controller;
    controller?.removeListener(_enforceLoopBoundary);
    unawaited(controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = _controller;
    final ready = controller?.value.isInitialized == true;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        key: const ValueKey('running-coach-evidence-slow-loop-sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.runningCoachSlowLoopTitle,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(l10n.runningCoachSlowLoopBody),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: ready
                ? controller!.value.aspectRatio.clamp(0.45, 2.2).toDouble()
                : 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: Colors.black,
                child: ready
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          VideoPlayer(controller!),
                          Center(
                            child: IconButton.filledTonal(
                              key: const ValueKey(
                                'running-coach-slow-loop-play-pause',
                              ),
                              onPressed: _togglePlayback,
                              icon: Icon(
                                controller.value.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                            ),
                          ),
                        ],
                      )
                    : widget.capturedFrame != null
                        ? Image.memory(
                            widget.capturedFrame!,
                            fit: BoxFit.contain,
                            key: const ValueKey(
                              'running-coach-slow-loop-captured-frame',
                            ),
                          )
                        : Center(
                            child: _loading
                                ? const CircularProgressIndicator()
                                : Text(
                                    l10n.runningCoachSlowLoopUnavailable,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                          ),
              ),
            ),
          ),
          if (ready && _loopWindow != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.runningCoachSlowLoopTiming(
                _seconds(_loopWindow!.$1),
                _seconds(_loopWindow!.$2),
              ),
              key: const ValueKey('running-coach-slow-loop-timing'),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ] else if (_unavailable && widget.capturedFrame != null) ...[
            const SizedBox(height: 8),
            Text(l10n.runningCoachSlowLoopCaptureOnly),
          ],
        ],
      ),
    );
  }
}

String _seconds(Duration duration) =>
    (duration.inMilliseconds / 1000).toStringAsFixed(1);
