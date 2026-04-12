import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../application/running_live_coaching_service.dart';
import '../../domain/entities/running_live_coaching_state.dart';
import '../../domain/entities/running_video_analysis_result.dart';
import '../../gen/app_localizations.dart';
import 'running_live_coach_guide_screen.dart';

class RunningLiveCoachScreen extends StatefulWidget {
  const RunningLiveCoachScreen({super.key});

  @override
  State<RunningLiveCoachScreen> createState() => _RunningLiveCoachScreenState();
}

class _RunningLiveCoachScreenState extends State<RunningLiveCoachScreen>
    with WidgetsBindingObserver {
  static const _frameProcessingInterval = Duration(milliseconds: 350);
  static const _repeatSpeechCooldown = Duration(seconds: 6);
  static const _changeSpeechCooldown = Duration(seconds: 2);

  final RunningLiveCoachingService _coachingService =
      RunningLiveCoachingService();
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
  );
  final FlutterTts _tts = FlutterTts();

  final Map<DeviceOrientation, int> _orientations = const {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  CameraDescription? _activeCamera;
  RunningLiveCoachingState _coachingState = const RunningLiveCoachingState(
    primaryCue: RunningLivePrimaryCue.keepRunning,
  );
  _PoseOverlayState? _poseOverlayState;
  bool _isInitializing = true;
  bool _isSpeechEnabled = true;
  bool _isDisposed = false;
  bool _isProcessingFrame = false;
  String? _configuredTtsLanguage;
  DateTime? _lastProcessedAt;
  DateTime? _lastSpokenAt;
  RunningLivePrimaryCue? _lastSpokenCue;
  String? _cameraErrorCode;

  bool get _isAndroidPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isIosPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  bool get _isSupportedMobilePlatform => _isAndroidPlatform || _isIosPlatform;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_configureTts());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(controller.dispose());
      _controller = null;
      return;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(_initializeCamera(preferredCamera: _activeCamera));
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    unawaited(_poseDetector.close());
    unawaited(_tts.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.runningCoachLiveScreenTitle),
        actions: [
          IconButton(
            onPressed: _openGuide,
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: l10n.runningCoachLiveGuideAction,
          ),
          IconButton(
            onPressed: _toggleSpeech,
            icon: Icon(
              _isSpeechEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
            ),
            tooltip: _isSpeechEnabled
                ? l10n.runningCoachLiveVoiceOn
                : l10n.runningCoachLiveVoiceOff,
          ),
          if (_cameras.length > 1)
            IconButton(
              onPressed: _isInitializing ? null : _switchCamera,
              icon: const Icon(Icons.cameraswitch_outlined),
              tooltip: l10n.runningCoachLiveSwitchCamera,
            ),
        ],
      ),
      body: _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_cameraErrorCode != null) {
      return _StatusPane(
        title: l10n.runningCoachLiveCameraIssueTitle,
        body: _cameraErrorMessage(l10n, _cameraErrorCode!),
        actionLabel: l10n.runningCoachLiveRetryAction,
        onAction: _initializeCamera,
      );
    }

    if (_isInitializing ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return _StatusPane(
        title: l10n.runningCoachLivePreparingTitle,
        body: l10n.runningCoachLivePreparingBody,
      );
    }

    final statusTheme = _statusTheme(context, _coachingState);
    final metrics = _buildMetrics(l10n);
    final scoreLabel = _coachingState.coachingReport == null
        ? l10n.runningCoachLiveScorePending
        : l10n.runningCoachLiveOverallScore(
            _coachingState.coachingReport!.overallScore,
          );
    final trackedFramesLabel =
        l10n.runningCoachLiveTrackedFrames(_coachingState.trackedFrames);
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _RunningPosePainter(
                overlay: _poseOverlayState,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GuideFramePainter(color: statusTheme.color),
            ),
          ),
        ),
        Positioned.fill(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final railWidth = math.min(
                    112.0,
                    math.max(88.0, constraints.maxWidth * 0.22),
                  );
                  final bannerWidth = math.min(
                    340.0,
                    constraints.maxWidth - (railWidth * 2) - 24,
                  );
                  return Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: math.max(180.0, bannerWidth),
                          ),
                          child: _CueBanner(
                            theme: statusTheme,
                            title: statusTheme.title,
                            body: _cueText(l10n, _coachingState.primaryCue),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _MetricsRail(
                          width: railWidth,
                          metrics: metrics,
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: _StatusDock(
                          speechLabel: _isSpeechEnabled
                              ? l10n.runningCoachLiveVoiceOn
                              : l10n.runningCoachLiveVoiceOff,
                          scoreLabel: scoreLabel,
                          trackedFramesLabel: trackedFramesLabel,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _configureTts() async {
    if (_isDisposed || !mounted) {
      return;
    }

    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode == 'ko' ? 'ko-KR' : 'en-US';
    if (_configuredTtsLanguage == languageCode) {
      return;
    }
    await _tts.setSharedInstance(true);
    await _tts.awaitSpeakCompletion(false);
    await _tts.setSpeechRate(0.46);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.setLanguage(languageCode);
    _configuredTtsLanguage = languageCode;
  }

  Future<void> _initializeCamera({CameraDescription? preferredCamera}) async {
    if (_isDisposed) {
      return;
    }

    if (!_isSupportedMobilePlatform) {
      setState(() {
        _cameraErrorCode = 'unsupported_platform';
        _isInitializing = false;
      });
      return;
    }

    setState(() {
      _isInitializing = true;
      _cameraErrorCode = null;
    });

    final oldController = _controller;
    _controller = null;
    if (oldController != null) {
      await oldController.dispose();
    }
    _coachingService.reset();
    _poseOverlayState = null;
    _lastProcessedAt = null;
    _lastSpokenAt = null;
    _lastSpokenCue = null;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('no_camera', 'No camera is available.');
      }

      _cameras = cameras;
      final selectedCamera = preferredCamera ??
          cameras.cast<CameraDescription?>().firstWhere(
                (camera) => camera?.lensDirection == CameraLensDirection.back,
                orElse: () => cameras.first,
              )!;
      _activeCamera = selectedCamera;

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: _isAndroidPlatform
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      await controller.startImageStream(_processCameraImage);
      if (_isDisposed) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } on CameraException catch (error) {
      if (_isDisposed) {
        return;
      }
      setState(() {
        _cameraErrorCode = error.code;
        _isInitializing = false;
      });
    } catch (_) {
      if (_isDisposed) {
        return;
      }
      setState(() {
        _cameraErrorCode = 'camera_failed';
        _isInitializing = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _activeCamera == null) {
      return;
    }
    final currentIndex = _cameras.indexOf(_activeCamera!);
    final nextIndex = (currentIndex + 1) % _cameras.length;
    await _initializeCamera(preferredCamera: _cameras[nextIndex]);
  }

  void _toggleSpeech() {
    setState(() {
      _isSpeechEnabled = !_isSpeechEnabled;
    });
    if (!_isSpeechEnabled) {
      unawaited(_tts.stop());
    }
  }

  void _openGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RunningLiveCoachGuideScreen(),
      ),
    );
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDisposed || _isProcessingFrame) {
      return;
    }
    final now = DateTime.now();
    if (_lastProcessedAt != null &&
        now.difference(_lastProcessedAt!) < _frameProcessingInterval) {
      return;
    }

    final frameInput = _inputImageFromCameraImage(image);
    if (frameInput == null) {
      return;
    }

    _isProcessingFrame = true;
    _lastProcessedAt = now;

    try {
      final poses = await _poseDetector.processImage(frameInput.inputImage);
      final observation = poses.isEmpty
          ? null
          : _observationFromPose(
              poses.first,
              Size(image.width.toDouble(), image.height.toDouble()),
            );
      final state = _coachingService.ingestObservation(
        observation,
        timestamp: now,
      );
      if (_isDisposed || !mounted) {
        return;
      }
      setState(() {
        _coachingState = state;
        _poseOverlayState = observation == null
            ? null
            : _PoseOverlayState(
                observation: observation,
                rotation: frameInput.rotation,
                lensDirection:
                    _activeCamera?.lensDirection ?? CameraLensDirection.back,
              );
      });
      await _maybeSpeakCue(state);
    } catch (_) {
      // Ignore transient pose errors and keep the live stream running.
    } finally {
      _isProcessingFrame = false;
    }
  }

  _CameraFrameInput? _inputImageFromCameraImage(CameraImage image) {
    final controller = _controller;
    final camera = _activeCamera;
    if (controller == null || camera == null) {
      return null;
    }

    final rotation = _resolveImageRotation(controller, camera);
    if (rotation == null) {
      return null;
    }

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (_isAndroidPlatform && format != InputImageFormat.nv21) ||
        (_isIosPlatform && format != InputImageFormat.bgra8888)) {
      return null;
    }
    if (image.planes.length != 1) {
      return null;
    }

    final plane = image.planes.first;
    return _CameraFrameInput(
      inputImage: InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      ),
      rotation: rotation,
    );
  }

  InputImageRotation? _resolveImageRotation(
    CameraController controller,
    CameraDescription camera,
  ) {
    if (_isIosPlatform) {
      return InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    }

    if (_isAndroidPlatform) {
      var rotationCompensation =
          _orientations[controller.value.deviceOrientation];
      if (rotationCompensation == null) {
        return null;
      }
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation =
            (camera.sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (camera.sensorOrientation - rotationCompensation + 360) % 360;
      }
      return InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    return null;
  }

  RunningPoseObservation _observationFromPose(Pose pose, Size imageSize) {
    final landmarks = <RunningPoseLandmarkType, RunningPoseLandmark>{};

    void addLandmark(
      PoseLandmarkType source,
      RunningPoseLandmarkType target,
    ) {
      final landmark = pose.landmarks[source];
      if (landmark == null) {
        return;
      }
      landmarks[target] = RunningPoseLandmark(
        position: Offset(landmark.x, landmark.y),
        likelihood: landmark.likelihood,
      );
    }

    addLandmark(PoseLandmarkType.nose, RunningPoseLandmarkType.nose);
    addLandmark(PoseLandmarkType.leftEar, RunningPoseLandmarkType.leftEar);
    addLandmark(PoseLandmarkType.rightEar, RunningPoseLandmarkType.rightEar);
    addLandmark(
      PoseLandmarkType.leftShoulder,
      RunningPoseLandmarkType.leftShoulder,
    );
    addLandmark(
      PoseLandmarkType.rightShoulder,
      RunningPoseLandmarkType.rightShoulder,
    );
    addLandmark(PoseLandmarkType.leftElbow, RunningPoseLandmarkType.leftElbow);
    addLandmark(
      PoseLandmarkType.rightElbow,
      RunningPoseLandmarkType.rightElbow,
    );
    addLandmark(PoseLandmarkType.leftWrist, RunningPoseLandmarkType.leftWrist);
    addLandmark(
      PoseLandmarkType.rightWrist,
      RunningPoseLandmarkType.rightWrist,
    );
    addLandmark(PoseLandmarkType.leftHip, RunningPoseLandmarkType.leftHip);
    addLandmark(PoseLandmarkType.rightHip, RunningPoseLandmarkType.rightHip);
    addLandmark(PoseLandmarkType.leftKnee, RunningPoseLandmarkType.leftKnee);
    addLandmark(PoseLandmarkType.rightKnee, RunningPoseLandmarkType.rightKnee);
    addLandmark(PoseLandmarkType.leftAnkle, RunningPoseLandmarkType.leftAnkle);
    addLandmark(
      PoseLandmarkType.rightAnkle,
      RunningPoseLandmarkType.rightAnkle,
    );
    addLandmark(PoseLandmarkType.leftHeel, RunningPoseLandmarkType.leftHeel);
    addLandmark(PoseLandmarkType.rightHeel, RunningPoseLandmarkType.rightHeel);
    addLandmark(
      PoseLandmarkType.leftFootIndex,
      RunningPoseLandmarkType.leftFootIndex,
    );
    addLandmark(
      PoseLandmarkType.rightFootIndex,
      RunningPoseLandmarkType.rightFootIndex,
    );

    return RunningPoseObservation(imageSize: imageSize, landmarks: landmarks);
  }

  Future<void> _maybeSpeakCue(RunningLiveCoachingState state) async {
    if (!_isSpeechEnabled || _isDisposed || !mounted) {
      return;
    }

    final cue = state.primaryCue;
    if (cue == RunningLivePrimaryCue.keepRunning) {
      return;
    }

    final now = DateTime.now();
    final cooldown =
        _lastSpokenCue == cue ? _repeatSpeechCooldown : _changeSpeechCooldown;
    if (_lastSpokenAt != null && now.difference(_lastSpokenAt!) < cooldown) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final message = _voiceText(l10n, cue);
    if (message.isEmpty) {
      return;
    }

    _lastSpokenCue = cue;
    _lastSpokenAt = now;
    await _tts.stop();
    await _tts.speak(message);
  }

  String _voiceText(AppLocalizations l10n, RunningLivePrimaryCue cue) {
    return switch (cue) {
      RunningLivePrimaryCue.noRunnerDetected =>
        l10n.runningCoachLiveCueNoRunner,
      RunningLivePrimaryCue.stepBack => l10n.runningCoachLiveCueStepBack,
      RunningLivePrimaryCue.moveCloser => l10n.runningCoachLiveCueMoveCloser,
      RunningLivePrimaryCue.centerRunner =>
        l10n.runningCoachLiveCueCenterRunner,
      RunningLivePrimaryCue.turnSideways =>
        l10n.runningCoachLiveCueTurnSideways,
      RunningLivePrimaryCue.keepRunning => '',
      RunningLivePrimaryCue.lookingGood => l10n.runningCoachLiveCueLookingGood,
      RunningLivePrimaryCue.postureTooUpright =>
        l10n.runningCoachPostureUprightCue,
      RunningLivePrimaryCue.postureTooLean => l10n.runningCoachPostureLeanCue,
      RunningLivePrimaryCue.bounceTooHigh => l10n.runningCoachBounceHighCue,
      RunningLivePrimaryCue.footStrikeOverstride =>
        l10n.runningCoachFootStrikeOverCue,
      RunningLivePrimaryCue.kneeTooStraight => l10n.runningCoachKneeStraightCue,
      RunningLivePrimaryCue.kneeTooCollapsed =>
        l10n.runningCoachKneeCollapseCue,
      RunningLivePrimaryCue.armTooOpen => l10n.runningCoachArmOpenCue,
      RunningLivePrimaryCue.armTooTight => l10n.runningCoachArmTightCue,
    };
  }

  String _cueText(AppLocalizations l10n, RunningLivePrimaryCue cue) {
    return switch (cue) {
      RunningLivePrimaryCue.noRunnerDetected =>
        l10n.runningCoachLiveCueNoRunner,
      RunningLivePrimaryCue.stepBack => l10n.runningCoachLiveCueStepBack,
      RunningLivePrimaryCue.moveCloser => l10n.runningCoachLiveCueMoveCloser,
      RunningLivePrimaryCue.centerRunner =>
        l10n.runningCoachLiveCueCenterRunner,
      RunningLivePrimaryCue.turnSideways =>
        l10n.runningCoachLiveCueTurnSideways,
      RunningLivePrimaryCue.keepRunning => l10n.runningCoachLiveCueKeepRunning,
      RunningLivePrimaryCue.lookingGood => l10n.runningCoachLiveCueLookingGood,
      RunningLivePrimaryCue.postureTooUpright =>
        l10n.runningCoachPostureUprightCue,
      RunningLivePrimaryCue.postureTooLean => l10n.runningCoachPostureLeanCue,
      RunningLivePrimaryCue.bounceTooHigh => l10n.runningCoachBounceHighCue,
      RunningLivePrimaryCue.footStrikeOverstride =>
        l10n.runningCoachFootStrikeOverCue,
      RunningLivePrimaryCue.kneeTooStraight => l10n.runningCoachKneeStraightCue,
      RunningLivePrimaryCue.kneeTooCollapsed =>
        l10n.runningCoachKneeCollapseCue,
      RunningLivePrimaryCue.armTooOpen => l10n.runningCoachArmOpenCue,
      RunningLivePrimaryCue.armTooTight => l10n.runningCoachArmTightCue,
    };
  }

  _LiveStatusTheme _statusTheme(
    BuildContext context,
    RunningLiveCoachingState state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    if (state.framingIssue != null) {
      return _LiveStatusTheme(
        title: l10n.runningCoachLiveStatusFraming,
        icon: Icons.center_focus_strong_rounded,
        color: const Color(0xFFFFB74D),
        background: Colors.black.withAlpha(170),
      );
    }
    if (!state.hasStableAnalysis) {
      return _LiveStatusTheme(
        title: l10n.runningCoachLiveStatusCollecting,
        icon: Icons.directions_run_rounded,
        color: scheme.secondary,
        background: Colors.black.withAlpha(170),
      );
    }
    return _LiveStatusTheme(
      title: l10n.runningCoachLiveStatusCoaching,
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF8BC34A),
      background: Colors.black.withAlpha(170),
    );
  }

  String _cameraErrorMessage(AppLocalizations l10n, String code) {
    return switch (code) {
      'unsupported_platform' => l10n.runningCoachUnsupportedPlatform,
      'CameraAccessDenied' => l10n.runningCoachLiveCameraDenied,
      'CameraAccessDeniedWithoutPrompt' => l10n.runningCoachLiveCameraDenied,
      'cameraPermission' => l10n.runningCoachLiveCameraDenied,
      _ => l10n.runningCoachLiveCameraFailed,
    };
  }

  List<_MetricTileData> _buildMetrics(AppLocalizations l10n) {
    final report = _coachingState.coachingReport;
    if (report == null) {
      return [
        _MetricTileData(
          label: l10n.runningCoachInsightPostureTitle,
          value: '--',
          accent: Colors.white54,
        ),
        _MetricTileData(
          label: l10n.runningCoachInsightBounceTitle,
          value: '--',
          accent: Colors.white54,
        ),
        _MetricTileData(
          label: l10n.runningCoachInsightFootStrikeTitle,
          value: '--',
          accent: Colors.white54,
        ),
        _MetricTileData(
          label: l10n.runningCoachInsightKneeTitle,
          value: '--',
          accent: Colors.white54,
        ),
        _MetricTileData(
          label: l10n.runningCoachInsightArmTitle,
          value: '--',
          accent: Colors.white54,
        ),
      ];
    }

    final metrics = <_MetricTileData>[];
    for (final insight in report.insights) {
      final label = switch (insight.metric) {
        RunningCoachMetric.posture => l10n.runningCoachInsightPostureTitle,
        RunningCoachMetric.bounce => l10n.runningCoachInsightBounceTitle,
        RunningCoachMetric.footStrike =>
          l10n.runningCoachInsightFootStrikeTitle,
        RunningCoachMetric.kneeFlexion => l10n.runningCoachInsightKneeTitle,
        RunningCoachMetric.armCarriage => l10n.runningCoachInsightArmTitle,
      };
      final value = switch (insight.metric) {
        RunningCoachMetric.posture =>
          l10n.runningCoachLeanValue(insight.value.toStringAsFixed(1)),
        RunningCoachMetric.bounce =>
          l10n.runningCoachBounceValue(insight.value.toStringAsFixed(1)),
        RunningCoachMetric.footStrike =>
          l10n.runningCoachFootStrikeValue(insight.value.toStringAsFixed(2)),
        RunningCoachMetric.kneeFlexion =>
          l10n.runningCoachKneeValue(insight.value.toStringAsFixed(0)),
        RunningCoachMetric.armCarriage =>
          l10n.runningCoachArmValue(insight.value.toStringAsFixed(0)),
      };
      metrics.add(
        _MetricTileData(
          label: label,
          value: value,
          accent: switch (insight.status) {
            RunningCoachStatus.good => const Color(0xFF8BC34A),
            RunningCoachStatus.watch => const Color(0xFFFFB74D),
            RunningCoachStatus.needsWork => const Color(0xFFFF8A65),
          },
        ),
      );
    }
    return metrics;
  }
}

class _CueBanner extends StatelessWidget {
  final _LiveStatusTheme theme;
  final String title;
  final String body;

  const _CueBanner({
    required this.theme,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.color.withAlpha(170)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(theme.icon, color: theme.color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          height: 1.25,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTileData {
  final String label;
  final String value;
  final Color accent;

  const _MetricTileData({
    required this.label,
    required this.value,
    required this.accent,
  });
}

class _MetricsRail extends StatelessWidget {
  final double width;
  final List<_MetricTileData> metrics;

  const _MetricsRail({
    required this.width,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xB8121720),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < metrics.length; index++) ...[
              _MetricTile(metric: metrics[index], width: width - 24),
              if (index != metrics.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final _MetricTileData metric;
  final double width;

  const _MetricTile({
    required this.metric,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: metric.accent.withAlpha(120)),
      ),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                metric.value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDock extends StatelessWidget {
  final String speechLabel;
  final String scoreLabel;
  final String trackedFramesLabel;

  const _StatusDock({
    required this.speechLabel,
    required this.scoreLabel,
    required this.trackedFramesLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoChip(text: scoreLabel),
        const SizedBox(height: 8),
        _InfoChip(text: trackedFramesLabel),
        const SizedBox(height: 8),
        _InfoChip(text: speechLabel),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;

  const _InfoChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _StatusPane extends StatelessWidget {
  final String title;
  final String body;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _StatusPane({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF11161C),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () => onAction!.call(),
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveStatusTheme {
  final String title;
  final IconData icon;
  final Color color;
  final Color background;

  const _LiveStatusTheme({
    required this.title,
    required this.icon,
    required this.color,
    required this.background,
  });
}

class _GuideFramePainter extends CustomPainter {
  final Color color;

  const _GuideFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withAlpha(70);
    canvas.drawRect(Offset.zero & size, overlayPaint);

    final guideRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.56,
      height: size.height * 0.78,
    );

    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, overlayPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(guideRect, const Radius.circular(28)),
      clearPaint,
    );
    canvas.restore();

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(guideRect, const Radius.circular(28)),
      borderPaint,
    );

    final accentPaint = Paint()
      ..color = color.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const corner = 28.0;
    final corners = [
      (guideRect.left, guideRect.top, 1, 1),
      (guideRect.right, guideRect.top, -1, 1),
      (guideRect.left, guideRect.bottom, 1, -1),
      (guideRect.right, guideRect.bottom, -1, -1),
    ];
    for (final (x, y, dx, dy) in corners) {
      canvas.drawLine(Offset(x, y), Offset(x + (corner * dx), y), accentPaint);
      canvas.drawLine(Offset(x, y), Offset(x, y + (corner * dy)), accentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GuideFramePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _CameraFrameInput {
  final InputImage inputImage;
  final InputImageRotation rotation;

  const _CameraFrameInput({
    required this.inputImage,
    required this.rotation,
  });
}

class _PoseOverlayState {
  final RunningPoseObservation observation;
  final InputImageRotation rotation;
  final CameraLensDirection lensDirection;

  const _PoseOverlayState({
    required this.observation,
    required this.rotation,
    required this.lensDirection,
  });
}

class _RunningPosePainter extends CustomPainter {
  final _PoseOverlayState? overlay;

  const _RunningPosePainter({required this.overlay});

  static const _connections = [
    (
      RunningPoseLandmarkType.leftShoulder,
      RunningPoseLandmarkType.rightShoulder,
    ),
    (RunningPoseLandmarkType.leftShoulder, RunningPoseLandmarkType.leftElbow),
    (RunningPoseLandmarkType.leftElbow, RunningPoseLandmarkType.leftWrist),
    (
      RunningPoseLandmarkType.rightShoulder,
      RunningPoseLandmarkType.rightElbow,
    ),
    (RunningPoseLandmarkType.rightElbow, RunningPoseLandmarkType.rightWrist),
    (RunningPoseLandmarkType.leftShoulder, RunningPoseLandmarkType.leftHip),
    (RunningPoseLandmarkType.rightShoulder, RunningPoseLandmarkType.rightHip),
    (RunningPoseLandmarkType.leftHip, RunningPoseLandmarkType.rightHip),
    (RunningPoseLandmarkType.leftHip, RunningPoseLandmarkType.leftKnee),
    (RunningPoseLandmarkType.rightHip, RunningPoseLandmarkType.rightKnee),
    (RunningPoseLandmarkType.leftKnee, RunningPoseLandmarkType.leftAnkle),
    (RunningPoseLandmarkType.rightKnee, RunningPoseLandmarkType.rightAnkle),
    (RunningPoseLandmarkType.leftAnkle, RunningPoseLandmarkType.leftHeel),
    (
      RunningPoseLandmarkType.leftHeel,
      RunningPoseLandmarkType.leftFootIndex,
    ),
    (
      RunningPoseLandmarkType.rightAnkle,
      RunningPoseLandmarkType.rightHeel,
    ),
    (
      RunningPoseLandmarkType.rightHeel,
      RunningPoseLandmarkType.rightFootIndex,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = this.overlay;
    if (overlay == null) {
      return;
    }

    final linePaint = Paint()
      ..color = const Color(0xFF73F3B4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final jointPaint = Paint()
      ..color = const Color(0xFFE8FFF4)
      ..style = PaintingStyle.fill;

    for (final (fromType, toType) in _connections) {
      final from =
          overlay.observation.landmark(fromType, minimumLikelihood: 0.35);
      final to = overlay.observation.landmark(toType, minimumLikelihood: 0.35);
      if (from == null || to == null) {
        continue;
      }
      final fromOffset = _translatePoint(
        point: from.position,
        imageSize: overlay.observation.imageSize,
        canvasSize: size,
        rotation: overlay.rotation,
        lensDirection: overlay.lensDirection,
      );
      final toOffset = _translatePoint(
        point: to.position,
        imageSize: overlay.observation.imageSize,
        canvasSize: size,
        rotation: overlay.rotation,
        lensDirection: overlay.lensDirection,
      );
      canvas.drawLine(fromOffset, toOffset, linePaint);
    }

    for (final landmark in overlay.observation.landmarks.values) {
      if (landmark.likelihood < 0.35) {
        continue;
      }
      final offset = _translatePoint(
        point: landmark.position,
        imageSize: overlay.observation.imageSize,
        canvasSize: size,
        rotation: overlay.rotation,
        lensDirection: overlay.lensDirection,
      );
      canvas.drawCircle(offset, 3.4, jointPaint);
    }
  }

  Offset _translatePoint({
    required Offset point,
    required Size imageSize,
    required Size canvasSize,
    required InputImageRotation rotation,
    required CameraLensDirection lensDirection,
  }) {
    final rotatedPoint = _rotatePoint(point, imageSize, rotation);
    final rotatedImageSize = switch (rotation) {
      InputImageRotation.rotation90deg ||
      InputImageRotation.rotation270deg =>
        Size(imageSize.height, imageSize.width),
      _ => imageSize,
    };
    final fitted = applyBoxFit(BoxFit.cover, rotatedImageSize, canvasSize);
    final sourceRect = Alignment.center.inscribe(
      fitted.source,
      Offset.zero & rotatedImageSize,
    );
    final destinationRect = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & canvasSize,
    );

    var translated = Offset(
      destinationRect.left +
          ((rotatedPoint.dx - sourceRect.left) *
              destinationRect.width /
              sourceRect.width),
      destinationRect.top +
          ((rotatedPoint.dy - sourceRect.top) *
              destinationRect.height /
              sourceRect.height),
    );

    if (lensDirection == CameraLensDirection.front) {
      translated = Offset(canvasSize.width - translated.dx, translated.dy);
    }
    return translated;
  }

  Offset _rotatePoint(
    Offset point,
    Size imageSize,
    InputImageRotation rotation,
  ) {
    return switch (rotation) {
      InputImageRotation.rotation90deg =>
        Offset(point.dy, imageSize.width - point.dx),
      InputImageRotation.rotation180deg =>
        Offset(imageSize.width - point.dx, imageSize.height - point.dy),
      InputImageRotation.rotation270deg =>
        Offset(imageSize.height - point.dy, point.dx),
      _ => point,
    };
  }

  @override
  bool shouldRepaint(covariant _RunningPosePainter oldDelegate) {
    return oldDelegate.overlay != overlay;
  }
}
