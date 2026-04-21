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
import 'running_coach_insight_copy.dart';
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _buildBody(context, l10n),
      ),
    );
  }

  Widget _buildCameraViewport() {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(controller);
    }

    final portraitPreviewSize = Size(previewSize.height, previewSize.width);
    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            width: portraitPreviewSize.width,
            height: portraitPreviewSize.height,
            child: CameraPreview(controller),
          ),
        ),
      ),
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
    final scoreLabel = _coachingState.coachingReport == null
        ? l10n.runningCoachLiveScorePending
        : l10n.runningCoachLiveOverallScore(
            _coachingState.coachingReport!.overallScore,
          );
    final trackedFramesLabel = l10n.runningCoachLiveTrackedFrames(
      _coachingState.trackedFrames,
    );
    final speechLabel = _isSpeechEnabled
        ? l10n.runningCoachLiveVoiceOn
        : l10n.runningCoachLiveVoiceOff;
    final diagnosis = _diagnosisText(l10n, _coachingState);
    final actionTip = _actionTipText(l10n, _coachingState);
    final insightDetails = _buildInsightDetails(l10n);
    final strengths = [
      for (final detail in insightDetails)
        if (detail.insight.status == RunningCoachStatus.good) detail,
    ];
    final needsWork = [
      for (final detail in insightDetails)
        if (detail.insight.status != RunningCoachStatus.good) detail,
    ];
    final panelTitle = _panelTitle(l10n);
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCameraViewport(),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _RunningPosePainter(overlay: _poseOverlayState),
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
                  final overlayWidth = math.min(560.0, constraints.maxWidth);
                  final panelHeight = math.min(
                    360.0,
                    constraints.maxHeight * 0.48,
                  );
                  return Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: overlayWidth),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LiveTopBar(
                                title: l10n.runningCoachLiveScreenTitle,
                                canSwitchCamera: _cameras.length > 1,
                                isInitializing: _isInitializing,
                                isSpeechEnabled: _isSpeechEnabled,
                                onBack: () => Navigator.of(context).maybePop(),
                                onGuide: _openGuide,
                                onToggleSpeech: _toggleSpeech,
                                onSwitchCamera: _switchCamera,
                                guideTooltip: l10n.runningCoachLiveGuideAction,
                                speechTooltip: _isSpeechEnabled
                                    ? l10n.runningCoachLiveVoiceOn
                                    : l10n.runningCoachLiveVoiceOff,
                                switchTooltip:
                                    l10n.runningCoachLiveSwitchCamera,
                              ),
                              const SizedBox(height: 10),
                              _CueBanner(
                                theme: statusTheme,
                                title: statusTheme.title,
                                body: _cueText(l10n, _coachingState.primaryCue),
                                diagnosis: diagnosis,
                                actionTip: actionTip,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: overlayWidth,
                            maxHeight: panelHeight,
                          ),
                          child: _ScoreExplanationPanel(
                            title: panelTitle,
                            scoreLabel: scoreLabel,
                            trackedFramesLabel: trackedFramesLabel,
                            speechLabel: speechLabel,
                            diagnosis: diagnosis,
                            actionTip: actionTip,
                            strengths: strengths,
                            needsWork: needsWork,
                          ),
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
    if (_isIosPlatform) {
      await _tts.autoStopSharedSession(false);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        const <IosTextToSpeechAudioCategoryOptions>[
          IosTextToSpeechAudioCategoryOptions.duckOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
    }
    await _tts.awaitSpeakCompletion(true);
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
      final selectedCamera =
          preferredCamera ??
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
      MaterialPageRoute(builder: (_) => const RunningLiveCoachGuideScreen()),
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

    void addLandmark(PoseLandmarkType source, RunningPoseLandmarkType target) {
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
    final cooldown = _lastSpokenCue == cue
        ? _repeatSpeechCooldown
        : _changeSpeechCooldown;
    if (_lastSpokenAt != null && now.difference(_lastSpokenAt!) < cooldown) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final message = _coachSpeechMessage(l10n, state);
    if (message.isEmpty) {
      return;
    }

    _lastSpokenCue = cue;
    _lastSpokenAt = now;
    await _tts.stop();
    await _tts.speak(message);
  }

  String _coachSpeechMessage(
    AppLocalizations l10n,
    RunningLiveCoachingState state,
  ) {
    if (state.framingIssue != null) {
      return _voiceText(l10n, state.primaryCue);
    }
    final insight = state.highlightedInsight;
    if (insight == null) {
      return _voiceText(l10n, state.primaryCue);
    }
    final copy = RunningCoachInsightCopy.fromInsight(insight, l10n);
    if (state.primaryCue == RunningLivePrimaryCue.lookingGood) {
      return '${copy.title}. ${copy.cue}';
    }
    return '${copy.title}. ${copy.cue}';
  }

  String _panelTitle(AppLocalizations l10n) {
    final report = _coachingState.coachingReport;
    if (report == null) {
      return _coachingState.framingIssue == null
          ? l10n.runningCoachLiveStatusCollecting
          : l10n.runningCoachLiveStatusFraming;
    }
    if (report.overallScore >= 85) {
      return l10n.runningCoachOverallHeadlineStrong;
    }
    if (report.overallScore >= 70) {
      return l10n.runningCoachOverallHeadlineSolid;
    }
    return l10n.runningCoachOverallHeadlineNeedsWork;
  }

  String _diagnosisText(AppLocalizations l10n, RunningLiveCoachingState state) {
    if (state.framingIssue case final framingIssue?) {
      return switch (framingIssue) {
        RunningLiveFramingIssue.noRunnerDetected =>
          l10n.runningCoachLiveGuideTipBodyBody,
        RunningLiveFramingIssue.stepBack =>
          l10n.runningCoachLiveGuideTipBodyBody,
        RunningLiveFramingIssue.moveCloser =>
          l10n.runningCoachLiveGuideTipCameraBody,
        RunningLiveFramingIssue.centerRunner =>
          l10n.runningCoachLiveGuideTipHudBody,
        RunningLiveFramingIssue.turnSideways =>
          l10n.runningCoachLiveGuideTipSideBody,
      };
    }
    if (state.highlightedInsight case final insight?) {
      return RunningCoachInsightCopy.fromInsight(insight, l10n).summary;
    }
    return '';
  }

  String _actionTipText(AppLocalizations l10n, RunningLiveCoachingState state) {
    if (state.framingIssue != null) {
      return _voiceText(l10n, state.primaryCue);
    }
    if (state.highlightedInsight case final insight?) {
      return RunningCoachInsightCopy.fromInsight(insight, l10n).cue;
    }
    return '';
  }

  List<_LiveInsightData> _buildInsightDetails(AppLocalizations l10n) {
    final report = _coachingState.coachingReport;
    if (report == null) {
      return const [];
    }
    return [
      for (final insight in report.insights)
        _LiveInsightData(
          insight: insight,
          copy: RunningCoachInsightCopy.fromInsight(insight, l10n),
        ),
    ];
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
}

class _CueBanner extends StatelessWidget {
  final _LiveStatusTheme theme;
  final String title;
  final String body;
  final String diagnosis;
  final String actionTip;

  const _CueBanner({
    required this.theme,
    required this.title,
    required this.body,
    required this.diagnosis,
    required this.actionTip,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(theme.icon, color: theme.color, size: 20),
            const SizedBox(width: 10),
            Flexible(
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
                  if (diagnosis.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _CueDetailLine(
                      label: AppLocalizations.of(
                        context,
                      )!.runningCoachSprintCueWhyLabel,
                      text: diagnosis,
                      color: Colors.white70,
                    ),
                  ],
                  if (actionTip.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _CueDetailLine(
                      label: AppLocalizations.of(
                        context,
                      )!.runningCoachSprintCueTryLabel,
                      text: actionTip,
                      color: theme.color.withAlpha(220),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveTopBar extends StatelessWidget {
  final String title;
  final bool canSwitchCamera;
  final bool isInitializing;
  final bool isSpeechEnabled;
  final VoidCallback onBack;
  final VoidCallback onGuide;
  final VoidCallback onToggleSpeech;
  final Future<void> Function() onSwitchCamera;
  final String guideTooltip;
  final String speechTooltip;
  final String switchTooltip;

  const _LiveTopBar({
    required this.title,
    required this.canSwitchCamera,
    required this.isInitializing,
    required this.isSpeechEnabled,
    required this.onBack,
    required this.onGuide,
    required this.onToggleSpeech,
    required this.onSwitchCamera,
    required this.guideTooltip,
    required this.speechTooltip,
    required this.switchTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(150),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  _OverlayActionButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: onBack,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _OverlayActionButton(
          icon: Icons.info_outline_rounded,
          onPressed: onGuide,
          tooltip: guideTooltip,
        ),
        const SizedBox(width: 8),
        _OverlayActionButton(
          icon: isSpeechEnabled
              ? Icons.volume_up_rounded
              : Icons.volume_off_rounded,
          onPressed: onToggleSpeech,
          tooltip: speechTooltip,
        ),
        if (canSwitchCamera) ...[
          const SizedBox(width: 8),
          _OverlayActionButton(
            icon: Icons.cameraswitch_outlined,
            onPressed: isInitializing
                ? null
                : () {
                    onSwitchCamera();
                  },
            tooltip: switchTooltip,
          ),
        ],
      ],
    );
  }
}

class _OverlayActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  const _OverlayActionButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
      ),
    );
  }
}

class _CueDetailLine extends StatelessWidget {
  final String label;
  final String text;
  final Color color;

  const _CueDetailLine({
    required this.label,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: Colors.white60, height: 1.25),
        children: [
          TextSpan(
            text: '$label  ',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text: text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _LiveInsightData {
  final RunningCoachingInsight insight;
  final RunningCoachInsightCopy copy;

  const _LiveInsightData({required this.insight, required this.copy});
}

class _ScoreExplanationPanel extends StatelessWidget {
  final String title;
  final String scoreLabel;
  final String trackedFramesLabel;
  final String speechLabel;
  final String diagnosis;
  final String actionTip;
  final List<_LiveInsightData> strengths;
  final List<_LiveInsightData> needsWork;

  const _ScoreExplanationPanel({
    required this.title,
    required this.scoreLabel,
    required this.trackedFramesLabel,
    required this.speechLabel,
    required this.diagnosis,
    required this.actionTip,
    required this.strengths,
    required this.needsWork,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC121820),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.runningCoachResultsTitle,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white60,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(text: scoreLabel),
                  _InfoChip(text: trackedFramesLabel),
                  _InfoChip(text: speechLabel),
                ],
              ),
              if (diagnosis.isNotEmpty) ...[
                const SizedBox(height: 14),
                _CueDetailLine(
                  label: l10n.runningCoachSprintCueWhyLabel,
                  text: diagnosis,
                  color: Colors.white70,
                ),
              ],
              if (actionTip.isNotEmpty) ...[
                const SizedBox(height: 8),
                _CueDetailLine(
                  label: l10n.runningCoachSprintCueTryLabel,
                  text: actionTip,
                  color: Colors.white,
                ),
              ],
              if (needsWork.isNotEmpty) ...[
                const SizedBox(height: 16),
                _PanelSectionTitle(text: l10n.runningCoachStatusNeedsWork),
                const SizedBox(height: 8),
                for (var index = 0; index < needsWork.length; index += 1) ...[
                  _LiveInsightCard(data: needsWork[index]),
                  if (index != needsWork.length - 1) const SizedBox(height: 10),
                ],
              ],
              if (strengths.isNotEmpty) ...[
                const SizedBox(height: 16),
                _PanelSectionTitle(text: l10n.runningCoachStatusGood),
                const SizedBox(height: 8),
                for (var index = 0; index < strengths.length; index += 1) ...[
                  _LiveInsightCard(data: strengths[index]),
                  if (index != strengths.length - 1) const SizedBox(height: 10),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelSectionTitle extends StatelessWidget {
  final String text;

  const _PanelSectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _LiveInsightCard extends StatelessWidget {
  final _LiveInsightData data;

  const _LiveInsightCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = switch (data.insight.status) {
      RunningCoachStatus.good => const Color(0xFF8BC34A),
      RunningCoachStatus.watch => const Color(0xFFFFB74D),
      RunningCoachStatus.needsWork => const Color(0xFFFF8A65),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withAlpha(140)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    data.copy.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(text: data.copy.statusLabel, accent: accent),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data.copy.value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.copy.summary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.copy.cue,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color accent;

  const _StatusBadge({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: accent,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
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

  const _CameraFrameInput({required this.inputImage, required this.rotation});
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
    (RunningPoseLandmarkType.rightShoulder, RunningPoseLandmarkType.rightElbow),
    (RunningPoseLandmarkType.rightElbow, RunningPoseLandmarkType.rightWrist),
    (RunningPoseLandmarkType.leftShoulder, RunningPoseLandmarkType.leftHip),
    (RunningPoseLandmarkType.rightShoulder, RunningPoseLandmarkType.rightHip),
    (RunningPoseLandmarkType.leftHip, RunningPoseLandmarkType.rightHip),
    (RunningPoseLandmarkType.leftHip, RunningPoseLandmarkType.leftKnee),
    (RunningPoseLandmarkType.rightHip, RunningPoseLandmarkType.rightKnee),
    (RunningPoseLandmarkType.leftKnee, RunningPoseLandmarkType.leftAnkle),
    (RunningPoseLandmarkType.rightKnee, RunningPoseLandmarkType.rightAnkle),
    (RunningPoseLandmarkType.leftAnkle, RunningPoseLandmarkType.leftHeel),
    (RunningPoseLandmarkType.leftHeel, RunningPoseLandmarkType.leftFootIndex),
    (RunningPoseLandmarkType.rightAnkle, RunningPoseLandmarkType.rightHeel),
    (RunningPoseLandmarkType.rightHeel, RunningPoseLandmarkType.rightFootIndex),
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
      final from = overlay.observation.landmark(
        fromType,
        minimumLikelihood: 0.35,
      );
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
      InputImageRotation.rotation90deg || InputImageRotation.rotation270deg =>
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
      InputImageRotation.rotation90deg => Offset(
        point.dy,
        imageSize.width - point.dx,
      ),
      InputImageRotation.rotation180deg => Offset(
        imageSize.width - point.dx,
        imageSize.height - point.dy,
      ),
      InputImageRotation.rotation270deg => Offset(
        imageSize.height - point.dy,
        point.dx,
      ),
      _ => point,
    };
  }

  @override
  bool shouldRepaint(covariant _RunningPosePainter oldDelegate) {
    return oldDelegate.overlay != overlay;
  }
}
