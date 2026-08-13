import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/running_live_framing_analysis.dart';
import '../../domain/entities/running_video_analysis_result.dart';
import '../../gen/app_localizations.dart';
import '../running_coach/running_pose_overlay.dart';

/// Records a short side-view clip for the running analysis flow.
Future<XFile?> captureRunningCoachVideo(BuildContext context) {
  return captureRunningCoachVideoForRunner(context);
}

Future<XFile?> captureRunningCoachVideoForRunner(
  BuildContext context, {
  String? runnerDisplayName,
}) {
  return Navigator.of(context).push<XFile>(
    MaterialPageRoute<XFile>(
      builder: (_) => RunningCaptureScreen(
        runnerDisplayName: runnerDisplayName,
      ),
      fullscreenDialog: true,
    ),
  );
}

class RunningCaptureScreen extends StatefulWidget {
  final Future<List<CameraDescription>> Function() cameraProvider;
  final Duration minimumDuration;
  final Duration maximumDuration;
  final String? runnerDisplayName;

  const RunningCaptureScreen({
    super.key,
    this.cameraProvider = availableCameras,
    this.minimumDuration = const Duration(seconds: 5),
    this.maximumDuration = const Duration(seconds: 60),
    this.runnerDisplayName,
  });

  @override
  State<RunningCaptureScreen> createState() => _RunningCaptureScreenState();
}

class _RunningCaptureScreenState extends State<RunningCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const <CameraDescription>[];
  CameraDescription? _activeCamera;
  Timer? _countdownTimer;
  Timer? _recordingTimer;
  Duration _recordingElapsed = Duration.zero;
  int? _countdown;
  bool _isInitializing = true;
  bool _isRecording = false;
  bool _isStopping = false;
  String? _errorCode;
  int _cameraSession = 0;
  bool _liveFramingActive = false;
  bool _liveFrameInFlight = false;
  bool _livePoseUnavailable = false;
  DateTime? _lastLiveFrameSentAt;
  RunningPoseFrame? _livePoseFrame;
  String? _livePoseErrorCode;

  static const _liveFrameInterval = Duration(milliseconds: 1100);

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  ImageFormatGroup? get _liveImageFormatGroup {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ImageFormatGroup.bgra8888;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return ImageFormatGroup.yuv420;
    }
    return null;
  }

  bool get _canStopRecording =>
      _recordingElapsed >= widget.minimumDuration && !_isStopping;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_controller == null && !_isStopping) {
        unawaited(_initializeCamera(preferredCamera: _activeCamera));
      }
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cancelTimers();
      _liveFramingActive = false;
      _cameraSession++;
      final controller = _controller;
      _controller = null;
      if (controller != null) {
        unawaited(_disposeController(controller));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraSession++;
    _cancelTimers();
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(_disposeController(controller));
    }
    super.dispose();
  }

  Future<void> _initializeCamera({CameraDescription? preferredCamera}) async {
    final session = ++_cameraSession;
    _cancelTimers();
    await _stopLiveFraming();
    final previous = _controller;
    _controller = null;
    if (previous != null) {
      await _disposeController(previous);
    }
    if (!mounted || session != _cameraSession) {
      return;
    }
    if (!_isSupportedPlatform) {
      setState(() {
        _isInitializing = false;
        _errorCode = 'unsupported_platform';
      });
      return;
    }

    setState(() {
      _isInitializing = true;
      _errorCode = null;
      _isRecording = false;
      _isStopping = false;
      _countdown = null;
      _recordingElapsed = Duration.zero;
    });

    try {
      final cameras = await widget.cameraProvider();
      if (cameras.isEmpty) {
        throw CameraException('no_camera', 'No camera is available.');
      }
      final selected = preferredCamera ??
          cameras.cast<CameraDescription?>().firstWhere(
                (camera) => camera?.lensDirection == CameraLensDirection.back,
                orElse: () => cameras.first,
              )!;
      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: _liveImageFormatGroup,
      );
      await controller.initialize();
      if (!mounted || session != _cameraSession) {
        await _disposeController(controller);
        return;
      }
      setState(() {
        _cameras = cameras;
        _activeCamera = selected;
        _controller = controller;
        _isInitializing = false;
        _livePoseFrame = null;
        _livePoseErrorCode = null;
        _livePoseUnavailable = false;
      });
      unawaited(_startLiveFraming(controller, session));
    } on CameraException catch (error) {
      if (!mounted || session != _cameraSession) {
        return;
      }
      setState(() {
        _isInitializing = false;
        _errorCode = error.code;
      });
    } catch (_) {
      if (!mounted || session != _cameraSession) {
        return;
      }
      setState(() {
        _isInitializing = false;
        _errorCode = 'camera_failed';
      });
    }
  }

  Future<void> _startLiveFraming(
    CameraController controller,
    int session,
  ) async {
    if (!_isSupportedPlatform ||
        _livePoseUnavailable ||
        _isRecording ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages) {
      return;
    }
    try {
      await controller.startImageStream(_handleLiveCameraImage);
      if (!mounted || session != _cameraSession) {
        await _stopLiveFraming(controller: controller);
        return;
      }
      setState(() {
        _liveFramingActive = true;
        _livePoseErrorCode = null;
      });
    } on CameraException catch (error) {
      if (!mounted || session != _cameraSession) return;
      setState(() {
        _liveFramingActive = false;
        _livePoseUnavailable = true;
        _livePoseErrorCode = error.code;
      });
    } catch (_) {
      if (!mounted || session != _cameraSession) return;
      setState(() {
        _liveFramingActive = false;
        _livePoseUnavailable = true;
        _livePoseErrorCode = 'live_pose_unavailable';
      });
    }
  }

  Future<void> _handleLiveCameraImage(CameraImage image) async {
    if (!_liveFramingActive || _liveFrameInFlight || _isRecording) {
      return;
    }
    final now = DateTime.now();
    final lastSentAt = _lastLiveFrameSentAt;
    if (lastSentAt != null && now.difference(lastSentAt) < _liveFrameInterval) {
      return;
    }
    final activeCamera = _activeCamera;
    if (activeCamera == null) return;
    _lastLiveFrameSentAt = now;
    _liveFrameInFlight = true;
    final session = _cameraSession;
    try {
      final poseFrame = await analyzeRunningLiveCameraImage(
        image: image,
        rotationDegrees: _liveFrameRotationDegrees(activeCamera),
        isFrontCamera: activeCamera.lensDirection == CameraLensDirection.front,
      );
      if (!mounted || session != _cameraSession) return;
      setState(() {
        _livePoseFrame = poseFrame;
        _livePoseErrorCode = poseFrame == null ? 'no_pose_detected' : null;
      });
    } on MissingPluginException {
      if (!mounted || session != _cameraSession) return;
      setState(() {
        _livePoseUnavailable = true;
        _livePoseErrorCode = 'live_pose_unavailable';
      });
      unawaited(_stopLiveFraming());
    } on PlatformException catch (error) {
      if (!mounted || session != _cameraSession) return;
      setState(() {
        _livePoseErrorCode = error.code;
        if (error.code == 'live_pose_unsupported' ||
            error.code == 'mediapipe_pose_failed' ||
            error.code == 'model_missing') {
          _livePoseUnavailable = true;
        }
      });
      if (_livePoseUnavailable) {
        unawaited(_stopLiveFraming());
      }
    } catch (_) {
      if (!mounted || session != _cameraSession) return;
      setState(() {
        _livePoseErrorCode = 'live_pose_failed';
      });
    } finally {
      _liveFrameInFlight = false;
    }
  }

  int _liveFrameRotationDegrees(CameraDescription camera) {
    final deviceDegrees = switch (_controller?.value.deviceOrientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeLeft => 90,
      DeviceOrientation.portraitDown => 180,
      DeviceOrientation.landscapeRight => 270,
      _ => 0,
    };
    final sensorDegrees = camera.sensorOrientation;
    if (camera.lensDirection == CameraLensDirection.front) {
      return (sensorDegrees + deviceDegrees) % 360;
    }
    return (sensorDegrees - deviceDegrees + 360) % 360;
  }

  void _beginCountdown() {
    if (_controller == null ||
        _isInitializing ||
        _isRecording ||
        _countdown != null) {
      return;
    }
    setState(() => _countdown = 3);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final countdown = _countdown;
      if (!mounted || countdown == null) {
        timer.cancel();
        return;
      }
      if (countdown <= 1) {
        timer.cancel();
        _countdownTimer = null;
        setState(() => _countdown = null);
        unawaited(_startRecording());
        return;
      }
      setState(() => _countdown = countdown - 1);
    });
  }

  Future<void> _startRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    try {
      await _stopLiveFraming(controller: controller);
      await controller.startVideoRecording();
      if (!mounted) {
        return;
      }
      setState(() {
        _isRecording = true;
        _recordingElapsed = Duration.zero;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || !_isRecording) {
          timer.cancel();
          return;
        }
        final next = _recordingElapsed + const Duration(seconds: 1);
        if (next >= widget.maximumDuration) {
          setState(() => _recordingElapsed = widget.maximumDuration);
          timer.cancel();
          _recordingTimer = null;
          unawaited(_stopRecording());
          return;
        }
        setState(() => _recordingElapsed = next);
      });
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorCode = error.code);
    } catch (_) {
      if (mounted) {
        setState(() => _errorCode = 'recording_failed');
      }
    }
  }

  Future<void> _stopRecording() async {
    final controller = _controller;
    if (controller == null || !_isRecording || _isStopping) {
      return;
    }
    if (!_canStopRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.runningCoachCaptureMinimumDuration(
              widget.minimumDuration.inSeconds,
            ),
          ),
        ),
      );
      return;
    }
    _recordingTimer?.cancel();
    _recordingTimer = null;
    setState(() => _isStopping = true);
    try {
      final clip = await controller.stopVideoRecording();
      if (mounted) {
        Navigator.of(context).pop(clip);
      }
    } on CameraException catch (error) {
      if (mounted) {
        setState(() {
          _isStopping = false;
          _errorCode = error.code;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isStopping = false;
          _errorCode = 'recording_failed';
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _activeCamera == null || _isRecording) {
      return;
    }
    final currentIndex = _cameras.indexOf(_activeCamera!);
    final next = _cameras[(currentIndex + 1) % _cameras.length];
    await _initializeCamera(preferredCamera: next);
  }

  void _cancelTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  Future<void> _stopLiveFraming({CameraController? controller}) async {
    _liveFramingActive = false;
    final target = controller ?? _controller;
    if (target == null || !target.value.isInitialized) return;
    if (!target.value.isStreamingImages) return;
    try {
      await target.stopImageStream();
    } on CameraException {
      // The stream is only a framing aid. Recording and disposal must continue.
    } catch (_) {}
  }

  Future<void> _disposeController(CameraController controller) async {
    await _stopLiveFraming(controller: controller);
    await controller.dispose();
  }

  String _errorMessage(AppLocalizations l10n) {
    return switch (_errorCode) {
      'unsupported_platform' => l10n.runningCoachCaptureUnsupportedPlatform,
      'cameraAccessDenied' ||
      'camera_access_denied' ||
      'CameraAccessDenied' =>
        l10n.runningCoachCapturePermissionDenied,
      'no_camera' => l10n.runningCoachCaptureUnavailable,
      _ => l10n.runningCoachCaptureFailed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = _controller;
    final countdown = _countdown;
    final canSwitchCamera =
        _cameras.length > 1 && !_isRecording && countdown == null;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (controller != null && controller.value.isInitialized)
              _CoverCameraPreview(controller: controller)
            else
              const ColoredBox(color: Colors.black),
            if (controller != null && controller.value.isInitialized)
              const IgnorePointer(
                  child: CustomPaint(painter: _CaptureGuidePainter())),
            if (controller != null &&
                controller.value.isInitialized &&
                _livePoseFrame != null &&
                !_isRecording)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    key: const ValueKey('running-capture-live-pose-overlay'),
                    painter: RunningPoseFrameOverlayPainter(
                      poseFrame: _livePoseFrame,
                      fit: BoxFit.cover,
                      primaryColor: const Color(0xFF75A7FF),
                      secondaryColor: const Color(0xFF62D6C5),
                      jointColor: Colors.white,
                      focusColor: const Color(0xFFFFD180),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  _CaptureIconButton(
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    icon: Icons.close_rounded,
                    onPressed: _isStopping || _isRecording
                        ? null
                        : () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.runningCoachCaptureTitle,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        if (widget.runnerDisplayName != null)
                          Text(
                            l10n.runningCoachRunnerTarget(
                              widget.runnerDisplayName!,
                            ),
                            key: const ValueKey(
                              'running-coach-capture-runner-name',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                      ],
                    ),
                  ),
                  if (canSwitchCamera)
                    _CaptureIconButton(
                      tooltip: l10n.runningCoachCaptureSwitchCamera,
                      icon: Icons.cameraswitch_outlined,
                      onPressed: _switchCamera,
                    ),
                ],
              ),
            ),
            if (_isInitializing)
              const Center(child: CircularProgressIndicator())
            else if (_errorCode != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam_off_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _errorMessage(l10n),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () => unawaited(_initializeCamera()),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.runningCoachCaptureRetry),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Positioned(
                left: 12,
                right: 12,
                bottom: 118,
                child: _CaptureFramingStatusPanel(
                  status: _captureFramingStatus(
                    controller: controller,
                    poseFrame: _livePoseFrame,
                    livePoseUnavailable:
                        _livePoseUnavailable || !_isSupportedPlatform,
                    livePoseActive: _liveFramingActive,
                    livePoseErrorCode: _livePoseErrorCode,
                    isRecording: _isRecording,
                  ),
                  recordingLabel: _isRecording
                      ? l10n.runningCoachCaptureRecording(
                          _recordingElapsed.inSeconds,
                          widget.maximumDuration.inSeconds,
                        )
                      : l10n.runningCoachCaptureGuide,
                ),
              ),
              if (!_isRecording && !_livePoseUnavailable)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 92,
                  child: Center(
                    child: Text(
                      _livePoseFrame == null
                          ? l10n.runningCoachCaptureFramingLiveSearching
                          : l10n.runningCoachCaptureFramingLiveReady,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 28,
                child: Center(
                  child: Semantics(
                    button: true,
                    label: _isRecording
                        ? l10n.runningCoachCaptureStop
                        : l10n.runningCoachCaptureStart,
                    child: GestureDetector(
                      onTap: _isStopping
                          ? null
                          : _isRecording
                              ? _stopRecording
                              : _beginCountdown,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _isRecording
                                ? const Color(0xffef5350)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(
                              _isRecording ? 12 : 100,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (countdown != null)
              Center(
                child: Text(
                  '$countdown',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 14)
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CoverCameraPreview extends StatelessWidget {
  final CameraController controller;

  const _CoverCameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewAspectRatio = _cameraPreviewAspectRatio(controller);
        final viewportAspectRatio =
            constraints.maxWidth / math.max(1.0, constraints.maxHeight);
        final scale = previewAspectRatio > viewportAspectRatio
            ? previewAspectRatio / viewportAspectRatio
            : viewportAspectRatio / previewAspectRatio;
        return ClipRect(
          child: Transform.scale(
            scale: math.max(1.0, scale),
            child: Center(
              child: AspectRatio(
                aspectRatio: previewAspectRatio,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      },
    );
  }
}

double _cameraPreviewAspectRatio(CameraController controller) {
  final orientation = controller.value.isRecordingVideo
      ? controller.value.recordingOrientation
      : controller.value.previewPauseOrientation ??
          controller.value.lockedCaptureOrientation ??
          controller.value.deviceOrientation;
  final isLandscape = orientation == DeviceOrientation.landscapeLeft ||
      orientation == DeviceOrientation.landscapeRight;
  return isLandscape
      ? controller.value.aspectRatio
      : 1 / controller.value.aspectRatio;
}

enum _CaptureFramingCheckKind {
  phoneLevel,
  previewFill,
  fullBodySafe,
  runnerScale,
  landmarksVisible,
  sideView,
}

enum _CaptureFramingCheckState { good, warning, unknown }

class _CaptureFramingStatus {
  final bool livePoseUnavailable;
  final bool livePoseActive;
  final String? livePoseErrorCode;
  final List<_CaptureFramingCheck> checks;

  const _CaptureFramingStatus({
    required this.livePoseUnavailable,
    required this.livePoseActive,
    required this.livePoseErrorCode,
    required this.checks,
  });

  int get readyCount => checks
      .where((check) => check.state == _CaptureFramingCheckState.good)
      .length;
}

class _CaptureFramingCheck {
  final _CaptureFramingCheckKind kind;
  final _CaptureFramingCheckState state;
  final String? code;

  const _CaptureFramingCheck({
    required this.kind,
    required this.state,
    this.code,
  });
}

_CaptureFramingStatus _captureFramingStatus({
  required CameraController? controller,
  required RunningPoseFrame? poseFrame,
  required bool livePoseUnavailable,
  required bool livePoseActive,
  required String? livePoseErrorCode,
  required bool isRecording,
}) {
  final isPhoneUpright =
      controller?.value.deviceOrientation == DeviceOrientation.portraitUp ||
          controller?.value.deviceOrientation == DeviceOrientation.portraitDown;
  final checks = <_CaptureFramingCheck>[
    _CaptureFramingCheck(
      kind: _CaptureFramingCheckKind.phoneLevel,
      state: isPhoneUpright
          ? _CaptureFramingCheckState.good
          : _CaptureFramingCheckState.warning,
      code: isPhoneUpright ? null : 'not_upright',
    ),
    const _CaptureFramingCheck(
      kind: _CaptureFramingCheckKind.previewFill,
      state: _CaptureFramingCheckState.good,
    ),
  ];
  if (poseFrame == null || livePoseUnavailable || isRecording) {
    checks.addAll(
      const <_CaptureFramingCheck>[
        _CaptureFramingCheck(
          kind: _CaptureFramingCheckKind.fullBodySafe,
          state: _CaptureFramingCheckState.unknown,
        ),
        _CaptureFramingCheck(
          kind: _CaptureFramingCheckKind.runnerScale,
          state: _CaptureFramingCheckState.unknown,
        ),
        _CaptureFramingCheck(
          kind: _CaptureFramingCheckKind.landmarksVisible,
          state: _CaptureFramingCheckState.unknown,
        ),
        _CaptureFramingCheck(
          kind: _CaptureFramingCheckKind.sideView,
          state: _CaptureFramingCheckState.unknown,
        ),
      ],
    );
    return _CaptureFramingStatus(
      livePoseUnavailable: livePoseUnavailable,
      livePoseActive: livePoseActive,
      livePoseErrorCode: livePoseErrorCode,
      checks: List<_CaptureFramingCheck>.unmodifiable(checks),
    );
  }

  final poseQuality = _LivePoseFramingQuality(poseFrame);
  checks.addAll(<_CaptureFramingCheck>[
    _CaptureFramingCheck(
      kind: _CaptureFramingCheckKind.fullBodySafe,
      state: poseQuality.isInsideSafeArea
          ? _CaptureFramingCheckState.good
          : _CaptureFramingCheckState.warning,
      code: poseQuality.isInsideSafeArea ? null : 'body_outside_safe_area',
    ),
    _CaptureFramingCheck(
      kind: _CaptureFramingCheckKind.runnerScale,
      state: poseQuality.runnerScaleState,
      code: poseQuality.runnerScaleCode,
    ),
    _CaptureFramingCheck(
      kind: _CaptureFramingCheckKind.landmarksVisible,
      state: poseQuality.hasRequiredLandmarks
          ? _CaptureFramingCheckState.good
          : _CaptureFramingCheckState.warning,
      code: poseQuality.hasRequiredLandmarks ? null : 'missing_landmarks',
    ),
    _CaptureFramingCheck(
      kind: _CaptureFramingCheckKind.sideView,
      state: poseQuality.isSideView
          ? _CaptureFramingCheckState.good
          : _CaptureFramingCheckState.warning,
      code: poseQuality.isSideView ? null : 'not_side_view',
    ),
  ]);
  return _CaptureFramingStatus(
    livePoseUnavailable: livePoseUnavailable,
    livePoseActive: livePoseActive,
    livePoseErrorCode: livePoseErrorCode,
    checks: List<_CaptureFramingCheck>.unmodifiable(checks),
  );
}

class _LivePoseFramingQuality {
  final RunningPoseFrame frame;
  late final List<RunningVideoPoseLandmark> _visibleLandmarks = frame.landmarks
      .where((landmark) =>
          landmark.confidence >= runningLiveFramingMinimumConfidence)
      .toList(growable: false);

  _LivePoseFramingQuality(this.frame);

  static const _safeLeft = 0.06;
  static const _safeRight = 0.94;
  static const _safeTop = 0.04;
  static const _safeBottom = 0.96;
  static const _minimumRunnerHeight = 0.40;
  static const _idealMinimumRunnerHeight = 0.50;
  static const _idealMaximumRunnerHeight = 0.78;
  static const _maximumRunnerHeight = 0.88;
  static const _maximumSidePairRatio = 0.22;

  Rect? get _bounds {
    if (_visibleLandmarks.isEmpty) return null;
    var minX = _visibleLandmarks.first.x;
    var maxX = _visibleLandmarks.first.x;
    var minY = _visibleLandmarks.first.y;
    var maxY = _visibleLandmarks.first.y;
    for (final landmark in _visibleLandmarks.skip(1)) {
      minX = math.min(minX, landmark.x);
      maxX = math.max(maxX, landmark.x);
      minY = math.min(minY, landmark.y);
      maxY = math.max(maxY, landmark.y);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  bool get isInsideSafeArea {
    final bounds = _bounds;
    if (bounds == null) return false;
    return bounds.left >= _safeLeft &&
        bounds.right <= _safeRight &&
        bounds.top >= _safeTop &&
        bounds.bottom <= _safeBottom;
  }

  _CaptureFramingCheckState get runnerScaleState {
    final height = _bounds?.height ?? 0;
    if (height >= _idealMinimumRunnerHeight &&
        height <= _idealMaximumRunnerHeight) {
      return _CaptureFramingCheckState.good;
    }
    return _CaptureFramingCheckState.warning;
  }

  String? get runnerScaleCode {
    final height = _bounds?.height ?? 0;
    if (height < _minimumRunnerHeight || height < _idealMinimumRunnerHeight) {
      return 'runner_too_small';
    }
    if (height > _maximumRunnerHeight || height > _idealMaximumRunnerHeight) {
      return 'runner_too_large';
    }
    return null;
  }

  bool get hasRequiredLandmarks {
    return const <int>[
      0,
      11,
      12,
      23,
      24,
      25,
      26,
      27,
      28,
      29,
      30,
      31,
      32,
    ].every(_hasConfidentLandmark);
  }

  bool get isSideView {
    final bounds = _bounds;
    if (bounds == null || bounds.height <= 0) return false;
    final shoulderSpan = _pairSpan(11, 12);
    final hipSpan = _pairSpan(23, 24);
    if (shoulderSpan == null || hipSpan == null) return false;
    final pairRatio = ((shoulderSpan + hipSpan) / 2) / bounds.height;
    return pairRatio <= _maximumSidePairRatio;
  }

  bool _hasConfidentLandmark(int index) {
    final landmark = frame.landmarkByIndex(index);
    return landmark != null &&
        landmark.confidence >= runningLiveFramingMinimumConfidence &&
        landmark.x.isFinite &&
        landmark.y.isFinite;
  }

  double? _pairSpan(int firstIndex, int secondIndex) {
    final first = frame.landmarkByIndex(firstIndex);
    final second = frame.landmarkByIndex(secondIndex);
    if (first == null ||
        second == null ||
        first.confidence < runningLiveFramingMinimumConfidence ||
        second.confidence < runningLiveFramingMinimumConfidence) {
      return null;
    }
    return (first.x - second.x).abs();
  }
}

const runningLiveFramingMinimumConfidence = 0.35;

class _CaptureFramingStatusPanel extends StatelessWidget {
  final _CaptureFramingStatus status;
  final String recordingLabel;

  const _CaptureFramingStatusPanel({
    required this.status,
    required this.recordingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final measuredCount = status.checks
        .where((check) => check.state != _CaptureFramingCheckState.unknown)
        .length;
    final compactChecks = status.checks
        .where(
          (check) =>
              check.kind == _CaptureFramingCheckKind.fullBodySafe ||
              check.kind == _CaptureFramingCheckKind.runnerScale ||
              check.kind == _CaptureFramingCheckKind.sideView,
        )
        .toList(growable: false);
    _CaptureFramingCheck? priorityWarning;
    for (final check in <_CaptureFramingCheck>[
      ...status.checks.where(
        (item) => item.kind == _CaptureFramingCheckKind.phoneLevel,
      ),
      ...compactChecks,
      ...status.checks.where(
        (item) => item.kind == _CaptureFramingCheckKind.landmarksVisible,
      ),
    ]) {
      if (check.state == _CaptureFramingCheckState.warning) {
        priorityWarning = check;
        break;
      }
    }
    return DecoratedBox(
      key: const ValueKey('running-capture-framing-status-panel'),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status.readyCount >= measuredCount
                      ? Icons.verified_outlined
                      : Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.runningCoachCaptureFramingTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  l10n.runningCoachCaptureFramingReadyCount(
                    status.readyCount,
                    measuredCount,
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              priorityWarning == null
                  ? status.livePoseUnavailable
                      ? l10n.runningCoachCaptureFramingFallbackBody
                      : status.livePoseActive
                          ? l10n.runningCoachCaptureFramingLiveReady
                          : l10n.runningCoachCaptureFramingLiveSearching
                  : _framingCheckText(l10n, priorityWarning),
              key: const ValueKey('running-capture-priority-guidance'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final check in compactChecks)
                  _CaptureFramingStatusChip(check: check),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              status.readyCount >= measuredCount
                  ? recordingLabel
                  : l10n.runningCoachCaptureWarningAnalysisLimited,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureFramingStatusChip extends StatelessWidget {
  final _CaptureFramingCheck check;

  const _CaptureFramingStatusChip({required this.check});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = switch (check.state) {
      _CaptureFramingCheckState.good => const Color(0xff80cbc4),
      _CaptureFramingCheckState.warning => const Color(0xffffcc80),
      _CaptureFramingCheckState.unknown => Colors.white70,
    };
    final icon = switch (check.state) {
      _CaptureFramingCheckState.good => Icons.check_circle_outline_rounded,
      _CaptureFramingCheckState.warning => Icons.warning_amber_rounded,
      _CaptureFramingCheckState.unknown => Icons.radio_button_unchecked,
    };
    return Container(
      key: ValueKey('running-capture-framing-${check.kind.name}'),
      constraints: const BoxConstraints(maxWidth: 148),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.44)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              _framingCheckText(l10n, check),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

String _framingCheckText(
  AppLocalizations l10n,
  _CaptureFramingCheck check,
) {
  if (check.state == _CaptureFramingCheckState.unknown) {
    return switch (check.kind) {
      _CaptureFramingCheckKind.fullBodySafe =>
        l10n.runningCoachCaptureFramingFullBodyUnknown,
      _CaptureFramingCheckKind.runnerScale =>
        l10n.runningCoachCaptureFramingScaleUnknown,
      _CaptureFramingCheckKind.landmarksVisible =>
        l10n.runningCoachCaptureFramingLandmarksUnknown,
      _CaptureFramingCheckKind.sideView =>
        l10n.runningCoachCaptureFramingSideUnknown,
      _ => l10n.runningCoachCaptureFramingNotMeasured,
    };
  }
  if (check.state == _CaptureFramingCheckState.good) {
    return switch (check.kind) {
      _CaptureFramingCheckKind.phoneLevel =>
        l10n.runningCoachCaptureFramingPhoneGood,
      _CaptureFramingCheckKind.previewFill =>
        l10n.runningCoachCaptureFramingPreviewGood,
      _CaptureFramingCheckKind.fullBodySafe =>
        l10n.runningCoachCaptureFramingFullBodyGood,
      _CaptureFramingCheckKind.runnerScale =>
        l10n.runningCoachCaptureFramingScaleGood,
      _CaptureFramingCheckKind.landmarksVisible =>
        l10n.runningCoachCaptureFramingLandmarksGood,
      _CaptureFramingCheckKind.sideView =>
        l10n.runningCoachCaptureFramingSideGood,
    };
  }
  return switch (check.code) {
    'not_upright' => l10n.runningCoachCaptureFramingPhoneWarning,
    'body_outside_safe_area' => l10n.runningCoachCaptureFramingFullBodyWarning,
    'runner_too_small' => l10n.runningCoachCaptureFramingScaleTooSmall,
    'runner_too_large' => l10n.runningCoachCaptureFramingScaleTooLarge,
    'missing_landmarks' => l10n.runningCoachCaptureFramingLandmarksWarning,
    'not_side_view' => l10n.runningCoachCaptureFramingSideWarning,
    _ => l10n.runningCoachCaptureFramingCheckWarning,
  };
}

@visibleForTesting
Widget runningCaptureFramingStatusPanelForTesting({
  required RunningPoseFrame? poseFrame,
  bool livePoseUnavailable = false,
  bool livePoseActive = true,
  String? livePoseErrorCode,
  bool isPhoneUpright = true,
}) {
  final controllerStatus = _CaptureFramingStatus(
    livePoseUnavailable: livePoseUnavailable,
    livePoseActive: livePoseActive,
    livePoseErrorCode: livePoseErrorCode,
    checks: _captureFramingStatusForTesting(
      poseFrame: poseFrame,
      livePoseUnavailable: livePoseUnavailable,
      isPhoneUpright: isPhoneUpright,
    ),
  );
  return _CaptureFramingStatusPanel(
    status: controllerStatus,
    recordingLabel: '',
  );
}

List<_CaptureFramingCheck> _captureFramingStatusForTesting({
  required RunningPoseFrame? poseFrame,
  required bool livePoseUnavailable,
  required bool isPhoneUpright,
}) {
  final checks = _captureFramingStatus(
    controller: null,
    poseFrame: poseFrame,
    livePoseUnavailable: livePoseUnavailable,
    livePoseActive: true,
    livePoseErrorCode: null,
    isRecording: false,
  ).checks.toList();
  checks[0] = _CaptureFramingCheck(
    kind: _CaptureFramingCheckKind.phoneLevel,
    state: isPhoneUpright
        ? _CaptureFramingCheckState.good
        : _CaptureFramingCheckState.warning,
    code: isPhoneUpright ? null : 'not_upright',
  );
  return List<_CaptureFramingCheck>.unmodifiable(checks);
}

class _CaptureIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _CaptureIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.48),
        foregroundColor: Colors.white,
      ),
      icon: Icon(icon),
    );
  }
}

class _CaptureGuidePainter extends CustomPainter {
  const _CaptureGuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final guideColor = Colors.white.withValues(alpha: 0.76);
    final mutedColor = Colors.white.withValues(alpha: 0.28);
    final frame = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.66,
      height: size.height * 0.70,
    );
    final framePaint = Paint()
      ..color = guideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final mutedPaint = Paint()
      ..color = mutedColor
      ..strokeWidth = 1;
    const cornerLength = 22.0;
    for (final corner in [
      frame.topLeft,
      frame.topRight,
      frame.bottomLeft,
      frame.bottomRight,
    ]) {
      final horizontal = corner.dx == frame.left ? 1.0 : -1.0;
      final vertical = corner.dy == frame.top ? 1.0 : -1.0;
      canvas.drawLine(corner,
          Offset(corner.dx + horizontal * cornerLength, corner.dy), framePaint);
      canvas.drawLine(corner,
          Offset(corner.dx, corner.dy + vertical * cornerLength), framePaint);
    }
    final ground = frame.bottom - 18;
    canvas.drawLine(Offset(frame.left + 14, ground),
        Offset(frame.right - 14, ground), mutedPaint);
    final guideCenter =
        Offset(frame.center.dx, frame.top + frame.height * 0.47);
    final silhouettePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final head = Offset(guideCenter.dx, frame.top + 42);
    canvas.drawCircle(head, 12, silhouettePaint);
    final shoulder = Offset(guideCenter.dx, head.dy + 38);
    final hip = Offset(guideCenter.dx - 8, head.dy + 142);
    canvas.drawLine(head + const Offset(0, 12), shoulder, silhouettePaint);
    canvas.drawLine(shoulder, hip, silhouettePaint);
    canvas.drawLine(shoulder + const Offset(-28, 14),
        shoulder + const Offset(-54, 62), silhouettePaint);
    canvas.drawLine(shoulder + const Offset(26, 16),
        shoulder + const Offset(58, 46), silhouettePaint);
    canvas.drawLine(hip, hip + const Offset(-46, 66), silhouettePaint);
    canvas.drawLine(hip + const Offset(-46, 66), hip + const Offset(-82, 105),
        silhouettePaint);
    canvas.drawLine(hip, hip + const Offset(42, 48), silhouettePaint);
    canvas.drawLine(hip + const Offset(42, 48), hip + const Offset(96, 54),
        silhouettePaint);
  }

  @override
  bool shouldRepaint(covariant _CaptureGuidePainter oldDelegate) => false;
}
