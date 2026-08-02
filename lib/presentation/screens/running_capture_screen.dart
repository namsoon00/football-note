import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../gen/app_localizations.dart';

/// Records a short side-view clip for the running analysis flow.
Future<XFile?> captureRunningCoachVideo(BuildContext context) {
  return Navigator.of(context).push<XFile>(
    MaterialPageRoute<XFile>(
      builder: (_) => const RunningCaptureScreen(),
      fullscreenDialog: true,
    ),
  );
}

class RunningCaptureScreen extends StatefulWidget {
  final Future<List<CameraDescription>> Function() cameraProvider;
  final Duration minimumDuration;
  final Duration maximumDuration;

  const RunningCaptureScreen({
    super.key,
    this.cameraProvider = availableCameras,
    this.minimumDuration = const Duration(seconds: 5),
    this.maximumDuration = const Duration(seconds: 60),
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

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

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
      _cameraSession++;
      final controller = _controller;
      _controller = null;
      if (controller != null) {
        unawaited(controller.dispose());
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
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  Future<void> _initializeCamera({CameraDescription? preferredCamera}) async {
    final session = ++_cameraSession;
    _cancelTimers();
    final previous = _controller;
    _controller = null;
    if (previous != null) {
      await previous.dispose();
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
      );
      await controller.initialize();
      if (!mounted || session != _cameraSession) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameras = cameras;
        _activeCamera = selected;
        _controller = controller;
        _isInitializing = false;
      });
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
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller),
                ),
              )
            else
              const ColoredBox(color: Colors.black),
            if (controller != null && controller.value.isInitialized)
              const IgnorePointer(
                  child: CustomPaint(painter: _CaptureGuidePainter())),
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
                    child: Text(
                      l10n.runningCoachCaptureTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
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
                left: 24,
                right: 24,
                bottom: 138,
                child: Text(
                  _isRecording
                      ? l10n.runningCoachCaptureRecording(
                          _recordingElapsed.inSeconds,
                          widget.maximumDuration.inSeconds,
                        )
                      : l10n.runningCoachCaptureGuide,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 8),
                    ],
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
