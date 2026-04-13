import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../application/sprint_live_coaching_service.dart';
import '../../application/sprint_live_session_metrics.dart';
import '../../domain/entities/sprint_pose_frame.dart';
import '../../domain/entities/sprint_realtime_coaching_state.dart';
import '../../gen/app_localizations.dart';
import '../../realtime_analysis/sprint_coaching/sprint_pipeline_config.dart';
import 'running_live_coach_guide_screen.dart';

class SprintLiveCoachingScreen extends StatefulWidget {
  const SprintLiveCoachingScreen({super.key});

  @override
  State<SprintLiveCoachingScreen> createState() =>
      _SprintLiveCoachingScreenState();
}

class _SprintLiveCoachingScreenState extends State<SprintLiveCoachingScreen>
    with WidgetsBindingObserver {
  static const _pipelineConfig = SprintPipelineConfig();
  static const _minimumAnalysisInterval = Duration(milliseconds: 100);
  static const _repeatSpeechCooldown = Duration(seconds: 4);
  static const _changeSpeechCooldown = Duration(milliseconds: 1400);
  static const _metricsLogInterval = Duration(seconds: 5);
  static const _metricsUiRefreshInterval = Duration(milliseconds: 450);

  final SprintLiveCoachingService _coachingService = SprintLiveCoachingService(
    config: _pipelineConfig,
  );
  final SprintLiveSessionMetricsCollector _sessionMetricsCollector =
      SprintLiveSessionMetricsCollector();
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
  SprintRealtimeCoachingState _coachingState =
      const SprintRealtimeCoachingState.initial();
  SprintLiveSessionMetricsSnapshot _sessionMetrics =
      const SprintLiveSessionMetricsSnapshot.initial();
  _SprintPoseOverlayState? _poseOverlayState;
  bool _isInitializing = true;
  bool _isSpeechEnabled = true;
  bool _isDisposed = false;
  bool _isProcessingFrame = false;
  String? _configuredTtsLanguage;
  String? _cameraErrorCode;
  DateTime? _lastAnalyzedAt;
  DateTime? _lastSpokenAt;
  String? _lastSpokenFeedbackKey;
  DateTime? _lastMetricsLoggedAt;
  DateTime? _lastMetricsUiRefreshAt;

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
      _emitSessionLog(force: true);
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
    _emitSessionLog(force: true);
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
        title: Text(l10n.runningCoachSprintLiveScreenTitle),
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
    final metrics = _buildCoachingMetrics(l10n);
    final bannerBody = _bannerText(l10n, _coachingState);
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SprintPosePainter(overlay: _poseOverlayState),
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
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final railWidth = math.min(
                    132.0,
                    math.max(100.0, constraints.maxWidth * 0.24),
                  );
                  final bannerWidth = math.min(
                    360.0,
                    constraints.maxWidth - (railWidth * 2) - 28,
                  );
                  final sessionWidth = math.min(
                    248.0,
                    math.max(190.0, constraints.maxWidth * 0.46),
                  );
                  return Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: math.max(210.0, bannerWidth),
                          ),
                          child: _CueBanner(
                            theme: statusTheme,
                            title: statusTheme.title,
                            body: bannerBody,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _MetricsRail(width: railWidth, metrics: metrics),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: _StatusDock(
                          items: [
                            _InfoChipData(
                              text: l10n
                                  .runningCoachSprintTrackingConfidenceValue(
                                (_coachingState
                                            .stateEstimate.trackingConfidence *
                                        100)
                                    .round(),
                              ),
                            ),
                            _InfoChipData(
                              text: l10n.runningCoachSprintTrackedFrames(
                                _coachingState.trackedFrames,
                              ),
                            ),
                            _InfoChipData(
                              text: l10n.runningCoachSprintDetectedSteps(
                                _coachingState.features.detectedStepEvents,
                              ),
                            ),
                            _InfoChipData(
                              text: _isSpeechEnabled
                                  ? l10n.runningCoachLiveVoiceOn
                                  : l10n.runningCoachLiveVoiceOff,
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: _SessionSummaryCard(
                          width: sessionWidth,
                          title: l10n.runningCoachSprintSessionLogTitle,
                          lines: _buildSessionSummaryLines(l10n),
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
    await _tts.setSpeechRate(0.48);
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
    _sessionMetricsCollector.reset();
    _sessionMetrics = const SprintLiveSessionMetricsSnapshot.initial();
    _coachingState = const SprintRealtimeCoachingState.initial();
    _poseOverlayState = null;
    _lastAnalyzedAt = null;
    _lastSpokenAt = null;
    _lastSpokenFeedbackKey = null;
    _lastMetricsLoggedAt = null;
    _lastMetricsUiRefreshAt = null;

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
      MaterialPageRoute(builder: (_) => const RunningLiveCoachGuideScreen()),
    );
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDisposed) {
      return;
    }

    final receivedAt = DateTime.now();
    _sessionMetricsCollector.recordCameraInputFrame(timestamp: receivedAt);

    if (_isProcessingFrame) {
      _sessionMetricsCollector.recordSkippedFrame(
        SprintSkippedFrameReason.detectorBusy,
      );
      _refreshSessionMetricsIfNeeded(receivedAt);
      return;
    }
    if (_lastAnalyzedAt != null &&
        receivedAt.difference(_lastAnalyzedAt!) < _minimumAnalysisInterval) {
      _sessionMetricsCollector.recordSkippedFrame(
        SprintSkippedFrameReason.throttled,
      );
      _refreshSessionMetricsIfNeeded(receivedAt);
      return;
    }

    final frameInput = _inputImageFromCameraImage(image);
    if (frameInput == null) {
      _sessionMetricsCollector.recordSkippedFrame(
        SprintSkippedFrameReason.invalidInput,
      );
      _refreshSessionMetricsIfNeeded(receivedAt);
      return;
    }

    _isProcessingFrame = true;
    final stopwatch = Stopwatch()..start();

    try {
      final poses = await _poseDetector.processImage(frameInput.inputImage);
      final poseFrame = poses.isEmpty
          ? null
          : _sprintPoseFrameFromPose(
              poses.first,
              Size(image.width.toDouble(), image.height.toDouble()),
              receivedAt,
            );
      final state = _coachingService.ingestPoseFrame(
        poseFrame,
        timestamp: receivedAt,
      );
      stopwatch.stop();
      _lastAnalyzedAt = receivedAt;
      _sessionMetricsCollector.recordAnalyzedFrame(
        timestamp: receivedAt,
        processingTime: stopwatch.elapsed,
        frame: poseFrame,
        state: state,
      );
      final snapshot = _sessionMetricsCollector.snapshot(now: receivedAt);

      if (_isDisposed || !mounted) {
        return;
      }

      setState(() {
        _coachingState = state;
        _sessionMetrics = snapshot;
        _poseOverlayState = poseFrame == null
            ? null
            : _SprintPoseOverlayState(
                frame: poseFrame,
                rotation: frameInput.rotation,
                lensDirection:
                    _activeCamera?.lensDirection ?? CameraLensDirection.back,
              );
      });

      _emitSessionLog(force: false);
      await _maybeSpeakFeedback(state);
    } catch (_) {
      stopwatch.stop();
      _sessionMetricsCollector.recordSkippedFrame(
        SprintSkippedFrameReason.analysisError,
      );
      _refreshSessionMetricsIfNeeded(receivedAt);
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _refreshSessionMetricsIfNeeded(DateTime now) {
    final shouldRefresh = _lastMetricsUiRefreshAt == null ||
        now.difference(_lastMetricsUiRefreshAt!) >= _metricsUiRefreshInterval;
    if (shouldRefresh) {
      final snapshot = _sessionMetricsCollector.snapshot(now: now);
      _lastMetricsUiRefreshAt = now;
      if (!_isDisposed && mounted) {
        setState(() {
          _sessionMetrics = snapshot;
        });
      }
    }
    _emitSessionLog(force: false);
  }

  void _emitSessionLog({required bool force}) {
    final now = DateTime.now();
    if (!force &&
        _lastMetricsLoggedAt != null &&
        now.difference(_lastMetricsLoggedAt!) < _metricsLogInterval) {
      return;
    }

    final l10n = mounted ? AppLocalizations.of(context) : null;
    final feedbackText = l10n == null
        ? null
        : _localizedFeedbackText(
            l10n,
            _coachingState.feedback?.localizationKey,
          );
    final snapshot = _sessionMetricsCollector.snapshot(now: now);
    final payload = _sessionMetricsCollector.buildLogPayload(
      snapshot: snapshot,
      state: _coachingState,
      feedbackText: feedbackText,
    );
    debugPrint('[SprintLiveSession] ${jsonEncode(payload)}');
    _lastMetricsLoggedAt = now;
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

  SprintPoseFrame _sprintPoseFrameFromPose(
    Pose pose,
    Size imageSize,
    DateTime timestamp,
  ) {
    final landmarks = <SprintPoseLandmarkType, SprintPoseLandmark>{};

    void addLandmark(PoseLandmarkType source, SprintPoseLandmarkType target) {
      final landmark = pose.landmarks[source];
      if (landmark == null) {
        return;
      }
      landmarks[target] = SprintPoseLandmark(
        position: Offset(landmark.x, landmark.y),
        confidence: landmark.likelihood,
      );
    }

    addLandmark(PoseLandmarkType.nose, SprintPoseLandmarkType.nose);
    addLandmark(PoseLandmarkType.leftEar, SprintPoseLandmarkType.leftEar);
    addLandmark(PoseLandmarkType.rightEar, SprintPoseLandmarkType.rightEar);
    addLandmark(
      PoseLandmarkType.leftShoulder,
      SprintPoseLandmarkType.leftShoulder,
    );
    addLandmark(
      PoseLandmarkType.rightShoulder,
      SprintPoseLandmarkType.rightShoulder,
    );
    addLandmark(PoseLandmarkType.leftElbow, SprintPoseLandmarkType.leftElbow);
    addLandmark(PoseLandmarkType.rightElbow, SprintPoseLandmarkType.rightElbow);
    addLandmark(PoseLandmarkType.leftWrist, SprintPoseLandmarkType.leftWrist);
    addLandmark(PoseLandmarkType.rightWrist, SprintPoseLandmarkType.rightWrist);
    addLandmark(PoseLandmarkType.leftHip, SprintPoseLandmarkType.leftHip);
    addLandmark(PoseLandmarkType.rightHip, SprintPoseLandmarkType.rightHip);
    addLandmark(PoseLandmarkType.leftKnee, SprintPoseLandmarkType.leftKnee);
    addLandmark(PoseLandmarkType.rightKnee, SprintPoseLandmarkType.rightKnee);
    addLandmark(PoseLandmarkType.leftAnkle, SprintPoseLandmarkType.leftAnkle);
    addLandmark(PoseLandmarkType.rightAnkle, SprintPoseLandmarkType.rightAnkle);
    addLandmark(PoseLandmarkType.leftHeel, SprintPoseLandmarkType.leftHeel);
    addLandmark(PoseLandmarkType.rightHeel, SprintPoseLandmarkType.rightHeel);
    addLandmark(
      PoseLandmarkType.leftFootIndex,
      SprintPoseLandmarkType.leftFootIndex,
    );
    addLandmark(
      PoseLandmarkType.rightFootIndex,
      SprintPoseLandmarkType.rightFootIndex,
    );

    return SprintPoseFrame(
      imageSize: imageSize,
      timestamp: timestamp,
      landmarks: landmarks,
    );
  }

  Future<void> _maybeSpeakFeedback(SprintRealtimeCoachingState state) async {
    if (!_isSpeechEnabled ||
        _isDisposed ||
        !mounted ||
        state.feedback == null) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final message = _localizedFeedbackText(
      l10n,
      state.feedback!.localizationKey,
    );
    if (message.isEmpty) {
      return;
    }

    final feedbackKey = state.feedback!.localizationKey;
    final now = DateTime.now();
    final cooldown = _lastSpokenFeedbackKey == feedbackKey
        ? _repeatSpeechCooldown
        : _changeSpeechCooldown;
    if (_lastSpokenAt != null && now.difference(_lastSpokenAt!) < cooldown) {
      return;
    }

    _lastSpokenAt = now;
    _lastSpokenFeedbackKey = feedbackKey;
    await _tts.stop();
    await _tts.speak(message);
  }

  _LiveStatusTheme _statusTheme(
    BuildContext context,
    SprintRealtimeCoachingState state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return switch (state.status) {
      SprintCoachingStatus.lowConfidence => _LiveStatusTheme(
          title: l10n.runningCoachSprintLiveStatusLowConfidence,
          icon: Icons.visibility_off_rounded,
          color: const Color(0xFFFFB74D),
          background: Colors.black.withAlpha(178),
        ),
      SprintCoachingStatus.collecting => _LiveStatusTheme(
          title: l10n.runningCoachSprintLiveStatusCollecting,
          icon: Icons.directions_run_rounded,
          color: scheme.secondary,
          background: Colors.black.withAlpha(178),
        ),
      SprintCoachingStatus.ready => _LiveStatusTheme(
          title: l10n.runningCoachSprintLiveStatusReady,
          icon: Icons.track_changes_rounded,
          color: const Color(0xFF8BC34A),
          background: Colors.black.withAlpha(178),
        ),
      SprintCoachingStatus.coaching => _LiveStatusTheme(
          title: l10n.runningCoachSprintLiveStatusCoaching,
          icon: Icons.flash_on_rounded,
          color: const Color(0xFF73F3B4),
          background: Colors.black.withAlpha(178),
        ),
    };
  }

  String _bannerText(AppLocalizations l10n, SprintRealtimeCoachingState state) {
    final feedbackText = _localizedFeedbackText(
      l10n,
      state.feedback?.localizationKey,
    );
    if (feedbackText.isNotEmpty) {
      return feedbackText;
    }

    return switch (state.status) {
      SprintCoachingStatus.lowConfidence =>
        l10n.runningCoachSprintCueBodyVisible,
      SprintCoachingStatus.collecting =>
        l10n.runningCoachSprintLiveCueCollecting,
      SprintCoachingStatus.ready => l10n.runningCoachSprintLiveCueReady,
      SprintCoachingStatus.coaching => l10n.runningCoachSprintCueKeepPushing,
    };
  }

  String _localizedFeedbackText(
    AppLocalizations l10n,
    String? localizationKey,
  ) {
    return switch (localizationKey) {
      'runningCoachSprintCueBodyVisible' =>
        l10n.runningCoachSprintCueBodyVisible,
      'runningCoachSprintCueLeanForward' =>
        l10n.runningCoachSprintCueLeanForward,
      'runningCoachSprintCueDriveKnee' => l10n.runningCoachSprintCueDriveKnee,
      'runningCoachSprintCueKeepRhythm' => l10n.runningCoachSprintCueKeepRhythm,
      'runningCoachSprintCueBalanceArms' =>
        l10n.runningCoachSprintCueBalanceArms,
      'runningCoachSprintCueKeepPushing' =>
        l10n.runningCoachSprintCueKeepPushing,
      _ => '',
    };
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

  List<_MetricTileData> _buildCoachingMetrics(AppLocalizations l10n) {
    return [
      _MetricTileData(
        label: l10n.runningCoachSprintMetricTrunkLabel,
        value: _coachingState.features.trunkAngleDegrees == null
            ? l10n.runningCoachSprintMetricPending
            : l10n.runningCoachSprintMetricTrunkValue(
                _coachingState.features.trunkAngleDegrees!.toStringAsFixed(1),
              ),
        accent: _accentForThreshold(
          value: _coachingState.features.trunkAngleDegrees,
          minimum: _pipelineConfig.minimumTrunkAngleDegrees,
          lowerIsBad: true,
        ),
      ),
      _MetricTileData(
        label: l10n.runningCoachSprintMetricKneeDriveLabel,
        value: _coachingState.features.kneeDriveHeightRatio == null
            ? l10n.runningCoachSprintMetricPending
            : l10n.runningCoachSprintMetricKneeDriveValue(
                (_coachingState.features.kneeDriveHeightRatio! * 100)
                    .round()
                    .toString(),
              ),
        accent: _accentForThreshold(
          value: _coachingState.features.kneeDriveHeightRatio,
          minimum: _pipelineConfig.minimumKneeDriveHeightRatio,
          lowerIsBad: true,
        ),
      ),
      _MetricTileData(
        label: l10n.runningCoachSprintMetricCadenceLabel,
        value: _coachingState.features.cadenceStepsPerMinute == null
            ? l10n.runningCoachSprintMetricPending
            : l10n.runningCoachSprintMetricCadenceValue(
                _coachingState.features.cadenceStepsPerMinute!
                    .round()
                    .toString(),
              ),
        accent: const Color(0xFF73F3B4),
      ),
      _MetricTileData(
        label: l10n.runningCoachSprintMetricRhythmLabel,
        value: _coachingState.features.stepIntervalStdMs == null
            ? l10n.runningCoachSprintMetricPending
            : l10n.runningCoachSprintMetricRhythmValue(
                _coachingState.features.stepIntervalStdMs!.round().toString(),
              ),
        accent: _accentForThreshold(
          value: _coachingState.features.stepIntervalStdMs,
          maximum: _pipelineConfig.maximumStepIntervalStdMs,
        ),
      ),
      _MetricTileData(
        label: l10n.runningCoachSprintMetricArmBalanceLabel,
        value: _coachingState.features.armSwingAsymmetryRatio == null
            ? l10n.runningCoachSprintMetricPending
            : l10n.runningCoachSprintMetricArmBalanceValue(
                (_coachingState.features.armSwingAsymmetryRatio! * 100)
                    .round()
                    .toString(),
              ),
        accent: _accentForThreshold(
          value: _coachingState.features.armSwingAsymmetryRatio,
          maximum: _pipelineConfig.maximumArmSwingAsymmetryRatio,
        ),
      ),
    ];
  }

  List<_SessionSummaryLine> _buildSessionSummaryLines(AppLocalizations l10n) {
    final highConfidence =
        ((_sessionMetrics.confidenceBucketRatio(4)) * 100).round();
    final midConfidence =
        ((_sessionMetrics.confidenceBucketRatio(3)) * 100).round();
    final lowConfidence = (100 - highConfidence - midConfidence).clamp(0, 100);

    return [
      _SessionSummaryLine(
        label: l10n.runningCoachSprintSessionCameraFpsLabel,
        value: _sessionMetrics.cameraInputFps.toStringAsFixed(1),
      ),
      _SessionSummaryLine(
        label: l10n.runningCoachSprintSessionAnalyzedFpsLabel,
        value: _sessionMetrics.analyzedFps.toStringAsFixed(1),
      ),
      _SessionSummaryLine(
        label: l10n.runningCoachSprintSessionAverageProcessingLabel,
        value: l10n.runningCoachSprintSessionAverageProcessingValue(
          _sessionMetrics.averageProcessingTimeMs.toStringAsFixed(1),
        ),
      ),
      _SessionSummaryLine(
        label: l10n.runningCoachSprintSessionSkippedFramesLabel,
        value: l10n.runningCoachSprintSessionSkippedFramesValue(
          _sessionMetrics.skippedFrames,
        ),
      ),
      _SessionSummaryLine(
        label: l10n.runningCoachSprintSessionBodyNotVisibleLabel,
        value: l10n.runningCoachSprintSessionBodyNotVisibleValue(
          (_sessionMetrics.bodyNotVisibleRatio * 100).round(),
        ),
      ),
      _SessionSummaryLine(
        label: l10n.runningCoachSprintSessionFeedbackChangesLabel,
        value: l10n.runningCoachSprintSessionFeedbackChangesValue(
          _sessionMetrics.feedbackChangeCount,
          _sessionMetrics.feedbackChangesPerMinute.toStringAsFixed(1),
        ),
      ),
      _SessionSummaryLine(
        label: l10n.runningCoachSprintSessionConfidenceLabel,
        value: l10n.runningCoachSprintSessionConfidenceValue(
          highConfidence,
          midConfidence,
          lowConfidence,
        ),
      ),
    ];
  }

  Color _accentForThreshold({
    required double? value,
    double? minimum,
    double? maximum,
    bool lowerIsBad = false,
  }) {
    if (value == null) {
      return Colors.white54;
    }
    if (minimum != null) {
      final passes = lowerIsBad ? value >= minimum : value > minimum;
      return passes ? const Color(0xFF8BC34A) : const Color(0xFFFF8A65);
    }
    if (maximum != null) {
      return value <= maximum
          ? const Color(0xFF8BC34A)
          : const Color(0xFFFF8A65);
    }
    return Colors.white54;
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
        border: Border.all(color: theme.color.withAlpha(178)),
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
                    maxLines: 3,
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

  const _MetricsRail({required this.width, required this.metrics});

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
            for (var index = 0; index < metrics.length; index += 1) ...[
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

  const _MetricTile({required this.metric, required this.width});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: metric.accent.withAlpha(140)),
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
                maxLines: 2,
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

class _InfoChipData {
  final String text;

  const _InfoChipData({required this.text});
}

class _StatusDock extends StatelessWidget {
  final List<_InfoChipData> items;

  const _StatusDock({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final item in items) _InfoChip(text: item.text)],
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

class _SessionSummaryLine {
  final String label;
  final String value;

  const _SessionSummaryLine({required this.label, required this.value});
}

class _SessionSummaryCard extends StatelessWidget {
  final double width;
  final String title;
  final List<_SessionSummaryLine> lines;

  const _SessionSummaryCard({
    required this.width,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xC0141921),
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
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              for (var index = 0; index < lines.length; index += 1) ...[
                _SessionSummaryRow(line: lines[index]),
                if (index != lines.length - 1) const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionSummaryRow extends StatelessWidget {
  final _SessionSummaryLine line;

  const _SessionSummaryRow({required this.line});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            line.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white60,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            line.value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
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

class _SprintPoseOverlayState {
  final SprintPoseFrame frame;
  final InputImageRotation rotation;
  final CameraLensDirection lensDirection;

  const _SprintPoseOverlayState({
    required this.frame,
    required this.rotation,
    required this.lensDirection,
  });
}

class _SprintPosePainter extends CustomPainter {
  final _SprintPoseOverlayState? overlay;

  const _SprintPosePainter({required this.overlay});

  static const _connections = [
    (SprintPoseLandmarkType.leftShoulder, SprintPoseLandmarkType.rightShoulder),
    (SprintPoseLandmarkType.leftShoulder, SprintPoseLandmarkType.leftElbow),
    (SprintPoseLandmarkType.leftElbow, SprintPoseLandmarkType.leftWrist),
    (SprintPoseLandmarkType.rightShoulder, SprintPoseLandmarkType.rightElbow),
    (SprintPoseLandmarkType.rightElbow, SprintPoseLandmarkType.rightWrist),
    (SprintPoseLandmarkType.leftShoulder, SprintPoseLandmarkType.leftHip),
    (SprintPoseLandmarkType.rightShoulder, SprintPoseLandmarkType.rightHip),
    (SprintPoseLandmarkType.leftHip, SprintPoseLandmarkType.rightHip),
    (SprintPoseLandmarkType.leftHip, SprintPoseLandmarkType.leftKnee),
    (SprintPoseLandmarkType.rightHip, SprintPoseLandmarkType.rightKnee),
    (SprintPoseLandmarkType.leftKnee, SprintPoseLandmarkType.leftAnkle),
    (SprintPoseLandmarkType.rightKnee, SprintPoseLandmarkType.rightAnkle),
    (SprintPoseLandmarkType.leftAnkle, SprintPoseLandmarkType.leftHeel),
    (SprintPoseLandmarkType.leftHeel, SprintPoseLandmarkType.leftFootIndex),
    (SprintPoseLandmarkType.rightAnkle, SprintPoseLandmarkType.rightHeel),
    (SprintPoseLandmarkType.rightHeel, SprintPoseLandmarkType.rightFootIndex),
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
      final from = overlay.frame.landmark(fromType, minimumConfidence: 0.35);
      final to = overlay.frame.landmark(toType, minimumConfidence: 0.35);
      if (from == null || to == null) {
        continue;
      }
      final fromOffset = _translatePoint(
        point: from.position,
        imageSize: overlay.frame.imageSize,
        canvasSize: size,
        rotation: overlay.rotation,
        lensDirection: overlay.lensDirection,
      );
      final toOffset = _translatePoint(
        point: to.position,
        imageSize: overlay.frame.imageSize,
        canvasSize: size,
        rotation: overlay.rotation,
        lensDirection: overlay.lensDirection,
      );
      canvas.drawLine(fromOffset, toOffset, linePaint);
    }

    for (final landmark in overlay.frame.landmarks.values) {
      if (landmark.confidence < 0.35) {
        continue;
      }
      final offset = _translatePoint(
        point: landmark.position,
        imageSize: overlay.frame.imageSize,
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
  bool shouldRepaint(covariant _SprintPosePainter oldDelegate) {
    return oldDelegate.overlay != overlay;
  }
}
