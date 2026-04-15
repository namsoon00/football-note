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
import '../../realtime_analysis/sprint_coaching/sprint_landmark_smoother.dart';
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
  static const _repeatSpeechCooldown = Duration(seconds: 7);
  static const _changeSpeechCooldown = Duration(milliseconds: 2500);
  static const _metricsLogInterval = Duration(seconds: 5);
  static const _metricsUiRefreshInterval = Duration(milliseconds: 450);
  static const _skipEventLogInterval = Duration(seconds: 2);
  static const _minimumSpeechConfidence = 0.72;
  static const _minimumStableFramesForSpeech = 8;

  final SprintLiveCoachingService _coachingService = SprintLiveCoachingService(
    config: _pipelineConfig,
  );
  final SprintLiveSessionMetricsCollector _sessionMetricsCollector =
      SprintLiveSessionMetricsCollector();
  final SprintLandmarkSmoother _debugOverlaySmoother = SprintLandmarkSmoother();
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
  bool _isDebugModeEnabled = true;
  bool _isDisposed = false;
  bool _isProcessingFrame = false;
  String? _configuredTtsLanguage;
  String? _cameraErrorCode;
  DateTime? _lastAnalyzedAt;
  DateTime? _lastSpokenAt;
  String? _lastSpokenCooldownKey;
  DateTime? _lastMetricsLoggedAt;
  DateTime? _lastMetricsUiRefreshAt;
  String? _sessionId;
  int _lastLoggedStepCount = 0;
  bool _lastBodyNotVisibleActive = false;
  _SpeechDebugState _speechDebugState = const _SpeechDebugState.initial();
  String? _lastSpeechEventFingerprint;
  final Map<SprintSkippedFrameReason, DateTime> _lastSkipLogAtByReason =
      <SprintSkippedFrameReason, DateTime>{};

  bool get _isAndroidPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isIosPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  bool get _isSupportedMobilePlatform => _isAndroidPlatform || _isIosPlatform;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bindTtsHandlers();
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
      _endSessionLogging(reason: 'lifecycle_${state.name}');
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
    _endSessionLogging(reason: 'dispose');
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
            onPressed: () {
              setState(() {
                _isDebugModeEnabled = !_isDebugModeEnabled;
              });
            },
            icon: Icon(
              _isDebugModeEnabled
                  ? Icons.bug_report_rounded
                  : Icons.bug_report_outlined,
            ),
            tooltip: l10n.runningCoachSprintDebugToggle,
          ),
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
    final bannerCue = _bannerCueText(l10n, _coachingState);
    final diagnosis = _diagnosisText(l10n, _coachingState);
    final actionTip = _actionTipText(l10n, _coachingState);
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCameraViewport(),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SprintPosePainter(
                overlay: _poseOverlayState,
                showDebug: _isDebugModeEnabled,
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
                            body: bannerCue,
                            diagnosis: diagnosis,
                            actionTip: actionTip,
                            hints: <String>[
                              _trackingSummaryText(l10n),
                              _speechSummaryText(l10n),
                            ],
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
                            _InfoChipData(text: _bodyVisibilityText(l10n)),
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
                          title: _isDebugModeEnabled
                              ? l10n.runningCoachSprintDebugPanelTitle
                              : l10n.runningCoachSprintSessionLogTitle,
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

  String _trackingSummaryText(AppLocalizations l10n) {
    return l10n.runningCoachSprintTrackingSummary(
      _trackingReadinessLabel(
          l10n, _coachingState.stateEstimate.trackingReadiness),
      (_coachingState.stateEstimate.personHeightRatio * 100).round(),
      (_coachingState.stateEstimate.personAreaRatio * 100).round(),
    );
  }

  String _speechSummaryText(AppLocalizations l10n) {
    return l10n.runningCoachSprintSpeechSummary(
      _speechStateLabel(l10n, _speechDebugState.speechState),
      _speechSkipReasonLabel(l10n, _speechDebugState.skippedReason),
    );
  }

  void _bindTtsHandlers() {
    _tts.setStartHandler(() {
      if (_isDisposed || !mounted) {
        return;
      }
      final updated = _speechDebugState.copyWith(
        speechState: _SpeechLifecycleState.started,
        lastTransitionAt: DateTime.now(),
        skippedReason: null,
      );
      setState(() {
        _speechDebugState = updated;
      });
      _emitSpeechEvent(
        event: 'speech_started',
        details: _speechDebugDetails(updated),
      );
    });
    _tts.setCompletionHandler(() {
      if (_isDisposed || !mounted) {
        return;
      }
      final updated = _speechDebugState.copyWith(
        speechState: _SpeechLifecycleState.completed,
        lastTransitionAt: DateTime.now(),
      );
      setState(() {
        _speechDebugState = updated;
      });
      _emitSpeechEvent(
        event: 'speech_completed',
        details: _speechDebugDetails(updated),
      );
    });
    _tts.setCancelHandler(() {
      if (_isDisposed || !mounted) {
        return;
      }
      final updated = _speechDebugState.copyWith(
        speechState: _SpeechLifecycleState.cancelled,
        lastTransitionAt: DateTime.now(),
      );
      setState(() {
        _speechDebugState = updated;
      });
      _emitSpeechEvent(
        event: 'speech_cancelled',
        details: _speechDebugDetails(updated),
      );
    });
    _tts.setErrorHandler((message) {
      if (_isDisposed || !mounted) {
        return;
      }
      final updated = _speechDebugState.copyWith(
        speechState: _SpeechLifecycleState.error,
        lastTransitionAt: DateTime.now(),
        skippedReason: message,
      );
      setState(() {
        _speechDebugState = updated;
      });
      _emitSpeechEvent(
        event: 'speech_error',
        details: _speechDebugDetails(updated),
      );
    });
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

    _endSessionLogging(reason: 'reinitialize');

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
    _debugOverlaySmoother.reset();
    _lastAnalyzedAt = null;
    _lastSpokenAt = null;
    _lastSpokenCooldownKey = null;
    _lastMetricsLoggedAt = null;
    _lastMetricsUiRefreshAt = null;
    _sessionId = null;
    _lastLoggedStepCount = 0;
    _lastBodyNotVisibleActive = false;
    _speechDebugState = const _SpeechDebugState.initial();
    _lastSpeechEventFingerprint = null;
    _lastSkipLogAtByReason.clear();

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
      _startSessionLogging();
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
    final previousState = _coachingState;
    _sessionMetricsCollector.recordCameraInputFrame(timestamp: receivedAt);

    if (_isProcessingFrame) {
      _sessionMetricsCollector.recordSkippedFrame(
        SprintSkippedFrameReason.detectorBusy,
      );
      _emitSkippedFrameEvent(SprintSkippedFrameReason.detectorBusy, receivedAt);
      _refreshSessionMetricsIfNeeded(receivedAt);
      return;
    }
    if (_lastAnalyzedAt != null &&
        receivedAt.difference(_lastAnalyzedAt!) <
            _pipelineConfig.minimumAnalysisInterval) {
      _sessionMetricsCollector.recordSkippedFrame(
        SprintSkippedFrameReason.throttled,
      );
      _emitSkippedFrameEvent(SprintSkippedFrameReason.throttled, receivedAt);
      _refreshSessionMetricsIfNeeded(receivedAt);
      return;
    }

    final frameInput = _inputImageFromCameraImage(image);
    if (frameInput == null) {
      _sessionMetricsCollector.recordSkippedFrame(
        SprintSkippedFrameReason.invalidInput,
      );
      _emitSkippedFrameEvent(SprintSkippedFrameReason.invalidInput, receivedAt);
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
      final debugSmoothedFrame = poseFrame == null
          ? null
          : _debugOverlaySmoother.smooth(
              _filterDebugFrame(poseFrame),
              alpha: _pipelineConfig.smoothingFactor,
              maxDisplacementRatio:
                  _pipelineConfig.outlierJointDisplacementRatio,
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
                rawFrame: poseFrame,
                smoothedFrame: debugSmoothedFrame,
                stateEstimate: state.stateEstimate,
                rotation: frameInput.rotation,
                lensDirection:
                    _activeCamera?.lensDirection ?? CameraLensDirection.back,
              );
      });

      _logStateTransitions(
        previousState: previousState,
        nextState: state,
        timestamp: receivedAt,
      );
      _emitSessionLog(event: 'periodic', force: false, now: receivedAt);
      await _maybeSpeakFeedback(previousState: previousState, state: state);
    } catch (_) {
      stopwatch.stop();
      _sessionMetricsCollector.recordSkippedFrame(
        SprintSkippedFrameReason.analysisError,
      );
      _emitSkippedFrameEvent(
        SprintSkippedFrameReason.analysisError,
        receivedAt,
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
    _emitSessionLog(event: 'periodic', force: false, now: now);
  }

  void _startSessionLogging() {
    final now = DateTime.now();
    _sessionId = 'sprint-${now.microsecondsSinceEpoch}';
    _emitSessionLog(
      event: 'start',
      force: true,
      now: now,
      details: <String, Object?>{
        'cameraLensDirection': _activeCamera?.lensDirection.name,
        'minimumAnalysisIntervalMs':
            _pipelineConfig.minimumAnalysisInterval.inMilliseconds,
      },
    );
  }

  void _endSessionLogging({required String reason}) {
    if (_sessionId == null) {
      return;
    }
    _emitSessionLog(
      event: 'end',
      force: true,
      details: <String, Object?>{'reason': reason},
    );
    _sessionId = null;
  }

  void _emitSessionLog({
    required String event,
    required bool force,
    DateTime? now,
    Map<String, Object?>? details,
  }) {
    final timestamp = now ?? DateTime.now();
    if (event == 'periodic' &&
        !force &&
        _lastMetricsLoggedAt != null &&
        timestamp.difference(_lastMetricsLoggedAt!) < _metricsLogInterval) {
      return;
    }

    final l10n = mounted ? AppLocalizations.of(context) : null;
    final feedbackText = l10n == null
        ? null
        : _localizedFeedbackCue(l10n, _coachingState.activeFeedbackKey);
    final snapshot = _sessionMetricsCollector.snapshot(now: timestamp);
    final payload = _sessionMetricsCollector.buildLogPayload(
      event: event,
      sessionId: _sessionId ?? 'inactive',
      timestamp: timestamp,
      config: _pipelineConfig,
      snapshot: snapshot,
      state: _coachingState,
      feedbackText: feedbackText,
      details: details,
    );
    debugPrint('[SprintLiveSession] ${jsonEncode(payload)}');
    if (event == 'periodic') {
      _lastMetricsLoggedAt = timestamp;
    }
  }

  void _emitSkippedFrameEvent(
    SprintSkippedFrameReason reason,
    DateTime timestamp,
  ) {
    final lastLoggedAt = _lastSkipLogAtByReason[reason];
    if (lastLoggedAt != null &&
        timestamp.difference(lastLoggedAt) < _skipEventLogInterval) {
      return;
    }

    _emitSessionLog(
      event: 'analysis_skipped',
      force: true,
      now: timestamp,
      details: <String, Object?>{
        'reason': reason.name,
        'count': _skippedFrameCount(reason),
      },
    );
    _lastSkipLogAtByReason[reason] = timestamp;
  }

  int _skippedFrameCount(SprintSkippedFrameReason reason) {
    final snapshot = _sessionMetricsCollector.snapshot();
    return switch (reason) {
      SprintSkippedFrameReason.detectorBusy => snapshot.busySkippedFrames,
      SprintSkippedFrameReason.throttled => snapshot.throttledSkippedFrames,
      SprintSkippedFrameReason.invalidInput => snapshot.invalidInputFrames,
      SprintSkippedFrameReason.analysisError => snapshot.analysisErrorFrames,
    };
  }

  void _logStateTransitions({
    required SprintRealtimeCoachingState previousState,
    required SprintRealtimeCoachingState nextState,
    required DateTime timestamp,
  }) {
    final previousFeedbackKey = previousState.activeFeedbackKey;
    final nextFeedbackKey = nextState.activeFeedbackKey;
    if (nextFeedbackKey != previousFeedbackKey) {
      _emitSessionLog(
        event: 'feedback_changed',
        force: true,
        now: timestamp,
        details: <String, Object?>{
          'from': previousFeedbackKey,
          'to': nextFeedbackKey,
          'text': _localizedFeedbackCue(
            AppLocalizations.of(context)!,
            nextFeedbackKey,
          ),
        },
      );
    }

    if (nextState.features.detectedStepEvents > _lastLoggedStepCount) {
      final delta =
          nextState.features.detectedStepEvents - _lastLoggedStepCount;
      _lastLoggedStepCount = nextState.features.detectedStepEvents;
      _emitSessionLog(
        event: 'step_detected',
        force: true,
        now: timestamp,
        details: <String, Object?>{
          'delta': delta,
          'acceptedEvents': nextState.features.detectedStepEvents,
          'leadSwitches': nextState.features.stepCrossoverCount,
        },
      );
    } else {
      _lastLoggedStepCount = nextState.features.detectedStepEvents;
    }

    final nextBodyNotVisible = nextState.bodyNotVisibleActive;
    if (nextBodyNotVisible != _lastBodyNotVisibleActive) {
      _emitSessionLog(
        event: nextBodyNotVisible
            ? 'body_not_visible_entered'
            : 'body_not_visible_exited',
        force: true,
        now: timestamp,
        details: <String, Object?>{
          'status': nextState.stateEstimate.bodyVisibilityStatus.name,
          'visibleCoreLandmarks':
              nextState.stateEstimate.visibleCoreLandmarkCount,
          'bodyVisibilityRatio':
              nextState.stateEstimate.bodyVisibilityRatio.toStringAsFixed(3),
        },
      );
      _lastBodyNotVisibleActive = nextBodyNotVisible;
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

  SprintPoseFrame _filterDebugFrame(SprintPoseFrame frame) {
    final filtered = <SprintPoseLandmarkType, SprintPoseLandmark>{
      for (final entry in frame.landmarks.entries)
        if (entry.value.confidence >= _pipelineConfig.minimumLandmarkConfidence)
          entry.key: entry.value,
    };
    return frame.copyWith(landmarks: filtered);
  }

  Future<void> _maybeSpeakFeedback({
    required SprintRealtimeCoachingState previousState,
    required SprintRealtimeCoachingState state,
  }) async {
    final selectedFeedback = state.feedback;
    final generatedFeedbackId = selectedFeedback?.code.name;
    final now = DateTime.now();
    final featureConfidence = _currentFeatureConfidence(state);
    final trackingState = state.stateEstimate.trackingReadiness.name;

    if (_isDisposed || !mounted) {
      return;
    }

    if (!_isSpeechEnabled) {
      _recordSpeechSkip(
        generatedFeedbackId: generatedFeedbackId,
        selectedFeedbackId: generatedFeedbackId,
        reason: 'speech_disabled',
        trackingState: trackingState,
        featureConfidence: featureConfidence,
        now: now,
      );
      return;
    }

    if (selectedFeedback == null) {
      _recordSpeechSkip(
        generatedFeedbackId: generatedFeedbackId,
        selectedFeedbackId: null,
        reason: 'no_feedback_selected',
        trackingState: trackingState,
        featureConfidence: featureConfidence,
        now: now,
      );
      return;
    }

    final cue = _localizedFeedbackCue(
      AppLocalizations.of(context)!,
      selectedFeedback.cueKey,
    );
    if (cue.isEmpty) {
      _recordSpeechSkip(
        generatedFeedbackId: generatedFeedbackId,
        selectedFeedbackId: selectedFeedback.code.name,
        reason: 'empty_cue',
        trackingState: trackingState,
        featureConfidence: featureConfidence,
        now: now,
      );
      return;
    }

    if (selectedFeedback.severity == SprintFeedbackSeverity.info) {
      _recordSpeechSkip(
        generatedFeedbackId: generatedFeedbackId,
        selectedFeedbackId: selectedFeedback.code.name,
        reason: 'info_feedback_screen_only',
        trackingState: trackingState,
        featureConfidence: featureConfidence,
        now: now,
      );
      return;
    }

    if (state.stateEstimate.trackingReadiness !=
        SprintTrackingReadiness.readyForAnalysis) {
      _recordSpeechSkip(
        generatedFeedbackId: generatedFeedbackId,
        selectedFeedbackId: selectedFeedback.code.name,
        reason: 'tracking_not_ready',
        trackingState: trackingState,
        featureConfidence: featureConfidence,
        now: now,
      );
      return;
    }

    if (selectedFeedback.confidence < _minimumSpeechConfidence ||
        featureConfidence < _minimumSpeechConfidence) {
      _recordSpeechSkip(
        generatedFeedbackId: generatedFeedbackId,
        selectedFeedbackId: selectedFeedback.code.name,
        reason: 'feedback_confidence_low',
        trackingState: trackingState,
        featureConfidence: featureConfidence,
        now: now,
      );
      return;
    }

    if (state.stateEstimate.stableFrameCount < _minimumStableFramesForSpeech) {
      _recordSpeechSkip(
        generatedFeedbackId: generatedFeedbackId,
        selectedFeedbackId: selectedFeedback.code.name,
        reason: 'tracking_not_stable_yet',
        trackingState: trackingState,
        featureConfidence: featureConfidence,
        now: now,
      );
      return;
    }

    final feedbackChanged =
        previousState.feedback?.cooldownKey != selectedFeedback.cooldownKey;
    final cooldown =
        feedbackChanged ? _changeSpeechCooldown : _repeatSpeechCooldown;
    final globalRemaining = _lastSpokenAt == null
        ? Duration.zero
        : cooldown - now.difference(_lastSpokenAt!);
    final sameFeedbackRemaining = _lastSpokenAt == null ||
            _lastSpokenCooldownKey != selectedFeedback.cooldownKey
        ? Duration.zero
        : _repeatSpeechCooldown - now.difference(_lastSpokenAt!);
    final remaining = feedbackChanged
        ? globalRemaining
        : (globalRemaining > sameFeedbackRemaining
            ? globalRemaining
            : sameFeedbackRemaining);
    if (remaining > Duration.zero) {
      _recordSpeechSkip(
        generatedFeedbackId: generatedFeedbackId,
        selectedFeedbackId: selectedFeedback.code.name,
        reason: 'speech_cooldown_active',
        trackingState: trackingState,
        featureConfidence: featureConfidence,
        cooldownRemaining: remaining,
        now: now,
      );
      return;
    }

    final nextDebugState = _speechDebugState.copyWith(
      generatedFeedbackId: generatedFeedbackId,
      selectedFeedbackId: selectedFeedback.code.name,
      speechState: _SpeechLifecycleState.queued,
      cooldownRemaining: Duration.zero,
      skippedReason: null,
      trackingState: trackingState,
      currentFeatureConfidence: featureConfidence,
      lastTransitionAt: now,
    );
    setState(() {
      _speechDebugState = nextDebugState;
    });
    _emitSpeechEvent(
      event: 'speech_triggered',
      details: _speechDebugDetails(nextDebugState),
    );

    _lastSpokenAt = now;
    _lastSpokenCooldownKey = selectedFeedback.cooldownKey;
    await _tts.stop();
    await _tts.speak(cue);
  }

  void _recordSpeechSkip({
    required String? generatedFeedbackId,
    required String? selectedFeedbackId,
    required String reason,
    required String trackingState,
    required double featureConfidence,
    required DateTime now,
    Duration cooldownRemaining = Duration.zero,
  }) {
    final nextState = _speechDebugState.copyWith(
      generatedFeedbackId: generatedFeedbackId,
      selectedFeedbackId: selectedFeedbackId,
      speechState: _SpeechLifecycleState.skipped,
      skippedReason: reason,
      cooldownRemaining: cooldownRemaining,
      trackingState: trackingState,
      currentFeatureConfidence: featureConfidence,
      lastTransitionAt: now,
    );
    if (!_isDisposed && mounted) {
      setState(() {
        _speechDebugState = nextState;
      });
    } else {
      _speechDebugState = nextState;
    }
    _emitSpeechEvent(
      event: 'speech_skipped',
      details: _speechDebugDetails(nextState),
    );
  }

  double _currentFeatureConfidence(SprintRealtimeCoachingState state) {
    final values = <double>[
      if (state.features.trunkAngle.available)
        state.features.trunkAngle.confidence,
      if (state.features.kneeDrive.available)
        state.features.kneeDrive.confidence,
      if (state.features.rhythm.available) state.features.rhythm.confidence,
    ];
    if (values.isEmpty) {
      return 0;
    }
    final total = values.reduce((sum, value) => sum + value);
    return total / values.length;
  }

  Map<String, Object?> _speechDebugDetails(_SpeechDebugState state) {
    return <String, Object?>{
      'generated_feedback_id': state.generatedFeedbackId,
      'selected_feedback_id': state.selectedFeedbackId,
      'speech_state': state.speechState.name,
      'speech_skipped_reason': state.skippedReason,
      'cooldown_remaining_ms': state.cooldownRemaining.inMilliseconds,
      'tracking_state': state.trackingState,
      'current_feature_confidence':
          state.currentFeatureConfidence.toStringAsFixed(3),
    };
  }

  void _emitSpeechEvent({
    required String event,
    required Map<String, Object?> details,
  }) {
    final fingerprint = [
      event,
      details['generated_feedback_id'],
      details['selected_feedback_id'],
      details['speech_state'],
      details['speech_skipped_reason'],
    ].join('|');
    if (_lastSpeechEventFingerprint == fingerprint &&
        event == 'speech_skipped') {
      return;
    }
    _lastSpeechEventFingerprint = fingerprint;
    _emitSessionLog(
      event: event,
      force: true,
      details: details,
    );
  }

  _LiveStatusTheme _statusTheme(
    BuildContext context,
    SprintRealtimeCoachingState state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return switch (state.stateEstimate.trackingReadiness) {
      SprintTrackingReadiness.bodyTooSmall => _LiveStatusTheme(
          title: l10n.runningCoachSprintTrackingStateBodyTooSmall,
          icon: Icons.zoom_in_rounded,
          color: const Color(0xFFFFB74D),
          background: Colors.black.withAlpha(178),
        ),
      SprintTrackingReadiness.bodyPartiallyOutOfFrame => _LiveStatusTheme(
          title: l10n.runningCoachSprintTrackingStateBodyOutOfFrame,
          icon: Icons.visibility_off_rounded,
          color: const Color(0xFFFFB74D),
          background: Colors.black.withAlpha(178),
        ),
      SprintTrackingReadiness.lowConfidence => _LiveStatusTheme(
          title: l10n.runningCoachSprintTrackingStateLowConfidence,
          icon: Icons.blur_on_rounded,
          color: const Color(0xFFFFB74D),
          background: Colors.black.withAlpha(178),
        ),
      SprintTrackingReadiness.sideViewUnstable => _LiveStatusTheme(
          title: l10n.runningCoachSprintTrackingStateSideViewUnstable,
          icon: Icons.swap_horiz_rounded,
          color: const Color(0xFFFFD54F),
          background: Colors.black.withAlpha(178),
        ),
      SprintTrackingReadiness.readyForAnalysis => switch (state.status) {
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
          SprintCoachingStatus.lowConfidence => _LiveStatusTheme(
              title: l10n.runningCoachSprintLiveStatusLowConfidence,
              icon: Icons.visibility_off_rounded,
              color: const Color(0xFFFFB74D),
              background: Colors.black.withAlpha(178),
            ),
        },
    };
  }

  String _bannerCueText(
    AppLocalizations l10n,
    SprintRealtimeCoachingState state,
  ) {
    final feedback = state.feedback;
    if (feedback != null) {
      final cue = _localizedFeedbackCue(l10n, feedback.cueKey);
      if (cue.isNotEmpty) {
        return cue;
      }
    }

    return switch (state.stateEstimate.trackingReadiness) {
      SprintTrackingReadiness.bodyTooSmall =>
        l10n.runningCoachSprintTrackingHintBodyTooSmall,
      SprintTrackingReadiness.bodyPartiallyOutOfFrame =>
        l10n.runningCoachSprintTrackingHintBodyOutOfFrame,
      SprintTrackingReadiness.lowConfidence =>
        l10n.runningCoachSprintTrackingHintLowConfidence,
      SprintTrackingReadiness.sideViewUnstable =>
        l10n.runningCoachSprintTrackingHintSideViewUnstable,
      SprintTrackingReadiness.readyForAnalysis => switch (state.status) {
          SprintCoachingStatus.collecting =>
            l10n.runningCoachSprintLiveCueCollecting,
          SprintCoachingStatus.ready => l10n.runningCoachSprintLiveCueReady,
          SprintCoachingStatus.coaching =>
            l10n.runningCoachSprintCueKeepPushing,
          SprintCoachingStatus.lowConfidence =>
            l10n.runningCoachSprintTrackingHintLowConfidence,
        },
    };
  }

  String _diagnosisText(
      AppLocalizations l10n, SprintRealtimeCoachingState state) {
    final feedback = state.feedback;
    if (feedback == null) {
      return switch (state.stateEstimate.trackingReadiness) {
        SprintTrackingReadiness.bodyTooSmall =>
          l10n.runningCoachSprintTrackingDiagnosisBodyTooSmall,
        SprintTrackingReadiness.bodyPartiallyOutOfFrame =>
          l10n.runningCoachSprintTrackingDiagnosisBodyOutOfFrame,
        SprintTrackingReadiness.lowConfidence =>
          l10n.runningCoachSprintTrackingDiagnosisLowConfidence,
        SprintTrackingReadiness.sideViewUnstable =>
          l10n.runningCoachSprintTrackingDiagnosisSideViewUnstable,
        SprintTrackingReadiness.readyForAnalysis => '',
      };
    }
    return _localizedFeedbackDiagnosis(l10n, feedback.diagnosisKey);
  }

  String _actionTipText(
      AppLocalizations l10n, SprintRealtimeCoachingState state) {
    final feedback = state.feedback;
    if (feedback == null) {
      return switch (state.stateEstimate.trackingReadiness) {
        SprintTrackingReadiness.bodyTooSmall =>
          l10n.runningCoachSprintTrackingActionBodyTooSmall,
        SprintTrackingReadiness.bodyPartiallyOutOfFrame =>
          l10n.runningCoachSprintTrackingActionBodyOutOfFrame,
        SprintTrackingReadiness.lowConfidence =>
          l10n.runningCoachSprintTrackingActionLowConfidence,
        SprintTrackingReadiness.sideViewUnstable =>
          l10n.runningCoachSprintTrackingActionSideViewUnstable,
        SprintTrackingReadiness.readyForAnalysis => '',
      };
    }
    return _localizedFeedbackActionTip(l10n, feedback.actionTipKey);
  }

  String _localizedFeedbackCue(
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

  String _localizedFeedbackDiagnosis(
    AppLocalizations l10n,
    String? localizationKey,
  ) {
    return switch (localizationKey) {
      'runningCoachSprintDiagnosisLeanForward' =>
        l10n.runningCoachSprintDiagnosisLeanForward,
      'runningCoachSprintDiagnosisDriveKnee' =>
        l10n.runningCoachSprintDiagnosisDriveKnee,
      'runningCoachSprintDiagnosisKeepRhythm' =>
        l10n.runningCoachSprintDiagnosisKeepRhythm,
      'runningCoachSprintDiagnosisBalanceArms' =>
        l10n.runningCoachSprintDiagnosisBalanceArms,
      'runningCoachSprintDiagnosisKeepPushing' =>
        l10n.runningCoachSprintDiagnosisKeepPushing,
      _ => '',
    };
  }

  String _localizedFeedbackActionTip(
    AppLocalizations l10n,
    String? localizationKey,
  ) {
    return switch (localizationKey) {
      'runningCoachSprintActionLeanForward' =>
        l10n.runningCoachSprintActionLeanForward,
      'runningCoachSprintActionDriveKnee' =>
        l10n.runningCoachSprintActionDriveKnee,
      'runningCoachSprintActionKeepRhythm' =>
        l10n.runningCoachSprintActionKeepRhythm,
      'runningCoachSprintActionBalanceArms' =>
        l10n.runningCoachSprintActionBalanceArms,
      'runningCoachSprintActionKeepPushing' =>
        l10n.runningCoachSprintActionKeepPushing,
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
          minimum: _pipelineConfig.minimumKneeDriveHeight,
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
          maximum: _pipelineConfig.maximumArmAsymmetryRatio,
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
        label: l10n.runningCoachSprintSessionTrackingStateLabel,
        value: _trackingReadinessLabel(
          l10n,
          _coachingState.stateEstimate.trackingReadiness,
        ),
      ),
      _SessionSummaryLine(
        label: l10n.runningCoachSprintSessionPersonSizeLabel,
        value: l10n.runningCoachSprintSessionPersonSizeValue(
          (_coachingState.stateEstimate.personHeightRatio * 100).round(),
          (_coachingState.stateEstimate.personAreaRatio * 100).round(),
        ),
      ),
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
        label: l10n.runningCoachSprintSessionBodyVisibilityLabel,
        value: l10n.runningCoachSprintSessionBodyVisibilityValue(
          _bodyVisibilityStatusText(l10n),
          _coachingState.stateEstimate.visibleCoreLandmarkCount,
          sprintMvpCoreLandmarkCount,
          (_coachingState.stateEstimate.bodyVisibilityRatio * 100).round(),
        ),
      ),
      _SessionSummaryLine(
        label: l10n.runningCoachSprintSessionVisibleJointCountLabel,
        value: l10n.runningCoachSprintSessionVisibleJointCountValue(
          _coachingState.stateEstimate.visibleLandmarkCount,
          _coachingState.stateEstimate.averageLandmarkConfidence
              .toStringAsFixed(2),
        ),
      ),
      _SessionSummaryLine(
        label: l10n.runningCoachSprintSessionActiveFeedbackLabel,
        value: _activeFeedbackDebugValue(l10n),
      ),
      _SessionSummaryLine(
        label: l10n.runningCoachSprintSessionReadinessLabel,
        value: l10n.runningCoachSprintSessionReadinessValue(
          _coachingState.stateEstimate.visibleLandmarkCount,
          _coachingState.stateEstimate.missingCoreLandmarkCount,
          _coachingState.stateEstimate.stableFrameCount,
          _coachingState.stateEstimate.hipTravelRatio.toStringAsFixed(3),
        ),
      ),
      _SessionSummaryLine(
        label: l10n.runningCoachSprintSessionStepDetectorLabel,
        value: l10n.runningCoachSprintSessionStepDetectorValue(
          _coachingState.features.stepCrossoverCount,
          _coachingState.features.detectedStepEvents,
          _coachingState.features.rejectedStepEventsLowVelocity,
          _coachingState.features.rejectedStepEventsMinInterval,
        ),
      ),
      _SessionSummaryLine(
        label: l10n.runningCoachSprintSessionFeedbackChangesLabel,
        value: l10n.runningCoachSprintSessionFeedbackChangesValue(
          _sessionMetrics.feedbackChangeCount,
          _sessionMetrics.feedbackChangesPerMinute.toStringAsFixed(1),
          _sessionMetrics.feedbackSuppressedByCooldownCount,
        ),
      ),
      _SessionSummaryLine(
        label: l10n.runningCoachSprintSessionSpeechStateLabel,
        value: l10n.runningCoachSprintSessionSpeechStateValue(
          _speechStateLabel(l10n, _speechDebugState.speechState),
          _speechSkipReasonLabel(l10n, _speechDebugState.skippedReason),
          _speechDebugState.cooldownRemaining.inMilliseconds,
        ),
      ),
      _SessionSummaryLine(
        label: l10n.runningCoachSprintSessionFeatureConfidenceLabel,
        value: l10n.runningCoachSprintSessionFeatureConfidenceValue(
          _featureDebugValue(
            l10n,
            label: l10n.runningCoachSprintMetricTrunkLabel,
            value: _coachingState.features.trunkAngleDegrees,
            confidence: _coachingState.features.trunkAngle.confidence,
            unavailableReason:
                _coachingState.features.trunkAngle.reasonIfUnavailable,
            valueFormatter: (value) => value.toStringAsFixed(1),
          ),
          _featureDebugValue(
            l10n,
            label: l10n.runningCoachSprintMetricKneeDriveLabel,
            value: _coachingState.features.kneeDriveHeightRatio,
            confidence: _coachingState.features.kneeDrive.confidence,
            unavailableReason:
                _coachingState.features.kneeDrive.reasonIfUnavailable,
            valueFormatter: (value) => value.toStringAsFixed(2),
          ),
          _featureDebugValue(
            l10n,
            label: l10n.runningCoachSprintMetricRhythmLabel,
            value: _coachingState.features.stepIntervalStdMs,
            confidence: _coachingState.features.rhythm.confidence,
            unavailableReason:
                _coachingState.features.rhythm.reasonIfUnavailable,
            valueFormatter: (value) => value.toStringAsFixed(0),
          ),
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

  String _bodyVisibilityText(AppLocalizations l10n) {
    return l10n.runningCoachSprintSessionBodyVisibilityValue(
      _bodyVisibilityStatusText(l10n),
      _coachingState.stateEstimate.visibleCoreLandmarkCount,
      sprintMvpCoreLandmarkCount,
      (_coachingState.stateEstimate.bodyVisibilityRatio * 100).round(),
    );
  }

  String _bodyVisibilityStatusText(AppLocalizations l10n) {
    return switch (_coachingState.stateEstimate.bodyVisibilityStatus) {
      SprintBodyVisibilityStatus.full =>
        l10n.runningCoachSprintBodyVisibilityFull,
      SprintBodyVisibilityStatus.partial =>
        l10n.runningCoachSprintBodyVisibilityPartial,
      SprintBodyVisibilityStatus.notVisible =>
        l10n.runningCoachSprintBodyVisibilityNotVisible,
    };
  }

  String _activeFeedbackDebugValue(AppLocalizations l10n) {
    final feedbackKey = _coachingState.activeFeedbackKey;
    final feedbackText = _localizedFeedbackCue(l10n, feedbackKey);
    if (feedbackKey == null || feedbackKey.isEmpty || feedbackText.isEmpty) {
      return l10n.runningCoachSprintSessionFeedbackEmpty;
    }
    return l10n.runningCoachSprintSessionActiveFeedbackValue(
      feedbackKey,
      feedbackText,
    );
  }

  String _trackingReadinessLabel(
    AppLocalizations l10n,
    SprintTrackingReadiness readiness,
  ) {
    return switch (readiness) {
      SprintTrackingReadiness.bodyTooSmall =>
        l10n.runningCoachSprintTrackingStateBodyTooSmall,
      SprintTrackingReadiness.bodyPartiallyOutOfFrame =>
        l10n.runningCoachSprintTrackingStateBodyOutOfFrame,
      SprintTrackingReadiness.lowConfidence =>
        l10n.runningCoachSprintTrackingStateLowConfidence,
      SprintTrackingReadiness.sideViewUnstable =>
        l10n.runningCoachSprintTrackingStateSideViewUnstable,
      SprintTrackingReadiness.readyForAnalysis =>
        l10n.runningCoachSprintTrackingStateReady,
    };
  }

  String _speechStateLabel(
    AppLocalizations l10n,
    _SpeechLifecycleState state,
  ) {
    return switch (state) {
      _SpeechLifecycleState.idle => l10n.runningCoachSprintSpeechStateIdle,
      _SpeechLifecycleState.queued => l10n.runningCoachSprintSpeechStateQueued,
      _SpeechLifecycleState.started =>
        l10n.runningCoachSprintSpeechStateStarted,
      _SpeechLifecycleState.completed =>
        l10n.runningCoachSprintSpeechStateCompleted,
      _SpeechLifecycleState.skipped =>
        l10n.runningCoachSprintSpeechStateSkipped,
      _SpeechLifecycleState.cancelled =>
        l10n.runningCoachSprintSpeechStateCancelled,
      _SpeechLifecycleState.error => l10n.runningCoachSprintSpeechStateError,
    };
  }

  String _speechSkipReasonLabel(AppLocalizations l10n, String? reason) {
    return switch (reason) {
      'speech_disabled' => l10n.runningCoachSprintSpeechSkipDisabled,
      'no_feedback_selected' =>
        l10n.runningCoachSprintSpeechSkipNoFeedbackSelected,
      'empty_cue' => l10n.runningCoachSprintSpeechSkipEmptyCue,
      'info_feedback_screen_only' =>
        l10n.runningCoachSprintSpeechSkipInfoFeedback,
      'tracking_not_ready' => l10n.runningCoachSprintSpeechSkipTrackingNotReady,
      'feedback_confidence_low' =>
        l10n.runningCoachSprintSpeechSkipLowConfidence,
      'tracking_not_stable_yet' =>
        l10n.runningCoachSprintSpeechSkipTrackingNotStable,
      'speech_cooldown_active' =>
        l10n.runningCoachSprintSpeechSkipCooldownActive,
      null || '' => l10n.runningCoachSprintSpeechSkipNone,
      _ => reason,
    };
  }

  String _featureUnavailableReasonLabel(AppLocalizations l10n, String? reason) {
    return switch (reason) {
      'insufficient_joint_window' =>
        l10n.runningCoachSprintFeatureUnavailableJointWindow,
      'insufficient_step_events' =>
        l10n.runningCoachSprintFeatureUnavailableStepEvents,
      null || '' => l10n.runningCoachSprintMetricPending,
      _ => reason,
    };
  }

  String _featureDebugValue(
    AppLocalizations l10n, {
    required String label,
    required double? value,
    required double confidence,
    required String? unavailableReason,
    required String Function(double value) valueFormatter,
  }) {
    if (value == null) {
      return l10n.runningCoachSprintSessionFeatureUnavailableValue(
        label,
        _featureUnavailableReasonLabel(l10n, unavailableReason),
      );
    }
    return l10n.runningCoachSprintSessionFeatureDebugValue(
      label,
      valueFormatter(value),
      (confidence * 100).round(),
    );
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
  final String diagnosis;
  final String actionTip;
  final List<String> hints;

  const _CueBanner({
    required this.theme,
    required this.title,
    required this.body,
    required this.diagnosis,
    required this.actionTip,
    required this.hints,
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 142),
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
                        label: AppLocalizations.of(context)!
                            .runningCoachSprintCueWhyLabel,
                        text: diagnosis,
                        color: Colors.white70,
                      ),
                    ],
                    if (actionTip.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _CueDetailLine(
                        label: AppLocalizations.of(context)!
                            .runningCoachSprintCueTryLabel,
                        text: actionTip,
                        color: theme.color.withAlpha(220),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final hint in hints)
                          _CueHintPill(text: hint, color: theme.color),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CueHintPill extends StatelessWidget {
  final String text;
  final Color color;

  const _CueHintPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(96)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
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
  final SprintPoseFrame rawFrame;
  final SprintPoseFrame? smoothedFrame;
  final SprintStateEstimate stateEstimate;
  final InputImageRotation rotation;
  final CameraLensDirection lensDirection;

  const _SprintPoseOverlayState({
    required this.rawFrame,
    required this.smoothedFrame,
    required this.stateEstimate,
    required this.rotation,
    required this.lensDirection,
  });
}

class _SprintPosePainter extends CustomPainter {
  final _SprintPoseOverlayState? overlay;
  final bool showDebug;

  const _SprintPosePainter({
    required this.overlay,
    required this.showDebug,
  });

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

    final mapper = _SprintViewportMapper(
      imageSize: overlay.rawFrame.imageSize,
      canvasSize: size,
      rotation: overlay.rotation,
      lensDirection: overlay.lensDirection,
    );
    final linePaint = Paint()
      ..color = const Color(0xFF73F3B4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final jointPaint = Paint()
      ..color = const Color(0xFFE8FFF4)
      ..style = PaintingStyle.fill;
    final rawJointPaint = Paint()
      ..color = const Color(0xFFFF8A65)
      ..style = PaintingStyle.fill;
    final rawLinePaint = Paint()
      ..color = const Color(0x99FF8A65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final smoothedFrame = overlay.smoothedFrame ?? overlay.rawFrame;
    if (showDebug) {
      _paintSkeleton(
        canvas,
        mapper,
        overlay.rawFrame,
        rawLinePaint,
        rawJointPaint,
        jointRadius: 2.4,
      );
      _paintDebugRects(canvas, mapper, overlay);
    }
    _paintSkeleton(
      canvas,
      mapper,
      smoothedFrame,
      linePaint,
      jointPaint,
      jointRadius: 3.4,
    );
  }

  void _paintSkeleton(
    Canvas canvas,
    _SprintViewportMapper mapper,
    SprintPoseFrame frame,
    Paint linePaint,
    Paint jointPaint, {
    required double jointRadius,
  }) {
    for (final (fromType, toType) in _connections) {
      final from = frame.landmark(fromType, minimumConfidence: 0.35);
      final to = frame.landmark(toType, minimumConfidence: 0.35);
      if (from == null || to == null) {
        continue;
      }
      canvas.drawLine(
        mapper.translatePoint(from.position),
        mapper.translatePoint(to.position),
        linePaint,
      );
    }

    for (final landmark in frame.landmarks.values) {
      if (landmark.confidence < 0.35) {
        continue;
      }
      canvas.drawCircle(
        mapper.translatePoint(landmark.position),
        jointRadius,
        jointPaint,
      );
    }
  }

  void _paintDebugRects(
    Canvas canvas,
    _SprintViewportMapper mapper,
    _SprintPoseOverlayState overlay,
  ) {
    final personBounds = overlay.stateEstimate.personBounds;
    if (personBounds != null) {
      final boundsPaint = Paint()
        ..color = const Color(0xFF64B5F6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(mapper.translateRect(personBounds), boundsPaint);
    }
    final cropRect = overlay.stateEstimate.suggestedCropRect;
    if (cropRect != null) {
      final cropPaint = Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawRect(mapper.translateRect(cropRect), cropPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SprintPosePainter oldDelegate) {
    return oldDelegate.overlay != overlay || oldDelegate.showDebug != showDebug;
  }
}

class _SprintViewportMapper {
  final Size imageSize;
  final Size canvasSize;
  final InputImageRotation rotation;
  final CameraLensDirection lensDirection;

  const _SprintViewportMapper({
    required this.imageSize,
    required this.canvasSize,
    required this.rotation,
    required this.lensDirection,
  });

  Offset translatePoint(Offset point) {
    final rotatedPoint = _rotatePoint(point);
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

  Rect translateRect(Rect rect) {
    final topLeft = translatePoint(rect.topLeft);
    final bottomRight = translatePoint(rect.bottomRight);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  Offset _rotatePoint(Offset point) {
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
}

enum _SpeechLifecycleState {
  idle,
  queued,
  started,
  completed,
  skipped,
  cancelled,
  error,
}

class _SpeechDebugState {
  final String? generatedFeedbackId;
  final String? selectedFeedbackId;
  final _SpeechLifecycleState speechState;
  final String? skippedReason;
  final Duration cooldownRemaining;
  final String trackingState;
  final double currentFeatureConfidence;
  final DateTime? lastTransitionAt;

  const _SpeechDebugState({
    required this.generatedFeedbackId,
    required this.selectedFeedbackId,
    required this.speechState,
    required this.skippedReason,
    required this.cooldownRemaining,
    required this.trackingState,
    required this.currentFeatureConfidence,
    required this.lastTransitionAt,
  });

  const _SpeechDebugState.initial()
      : generatedFeedbackId = null,
        selectedFeedbackId = null,
        speechState = _SpeechLifecycleState.idle,
        skippedReason = null,
        cooldownRemaining = Duration.zero,
        trackingState = '',
        currentFeatureConfidence = 0,
        lastTransitionAt = null;

  _SpeechDebugState copyWith({
    String? generatedFeedbackId,
    String? selectedFeedbackId,
    _SpeechLifecycleState? speechState,
    String? skippedReason,
    Duration? cooldownRemaining,
    String? trackingState,
    double? currentFeatureConfidence,
    DateTime? lastTransitionAt,
  }) {
    return _SpeechDebugState(
      generatedFeedbackId: generatedFeedbackId ?? this.generatedFeedbackId,
      selectedFeedbackId: selectedFeedbackId ?? this.selectedFeedbackId,
      speechState: speechState ?? this.speechState,
      skippedReason: skippedReason,
      cooldownRemaining: cooldownRemaining ?? this.cooldownRemaining,
      trackingState: trackingState ?? this.trackingState,
      currentFeatureConfidence:
          currentFeatureConfidence ?? this.currentFeatureConfidence,
      lastTransitionAt: lastTransitionAt ?? this.lastTransitionAt,
    );
  }
}
