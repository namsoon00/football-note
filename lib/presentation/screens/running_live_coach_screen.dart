import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../application/live_sprint_coaching_service.dart';
import '../../application/live_sprint_calibration_readiness_service.dart';
import '../../application/live_sprint_calibration_candidate_service.dart';
import '../../application/live_sprint_capture_context_service.dart';
import '../../application/live_sprint_field_validation_matrix_service.dart';
import '../../application/live_sprint_pose_evidence_collector.dart';
import '../../application/live_sprint_session_report_service.dart';
import '../../application/live_sprint_trend_service.dart';
import '../../application/mediapipe_pose_landmarker_service.dart';
import '../../application/running_coach_history_service.dart';
import '../../application/running_live_calibration_capture_contract.dart';
import '../../application/running_live_session_metrics.dart';
import '../../application/sprint_capture_calibration_service.dart';
import '../../application/sprint_live_session_metrics.dart';
import '../../domain/entities/running_coach_session.dart';
import '../../domain/entities/running_live_coaching_state.dart';
import '../../domain/entities/running_video_analysis_result.dart';
import '../../domain/entities/sprint_capture_calibration_profile.dart';
import '../../domain/repositories/option_repository.dart';
import '../../domain/entities/sprint_realtime_coaching_state.dart';
import '../../gen/app_localizations.dart';
import '../../realtime_analysis/running_coaching/running_live_timing_config.dart';
import '../../realtime_analysis/running_coaching/running_visual_pose_tracker.dart';
import '../../realtime_analysis/sprint_coaching/sprint_pipeline_config.dart';
import '../models/camera_viewport_transform.dart';
import '../painters/running_pose_anatomical_painter.dart';
import 'running_coach_insight_copy.dart';
import 'running_live_coach_guide_screen.dart';
import 'running_live_session_result_screen.dart';
import '../widgets/live_sprint_calibration_summary_cards.dart';

class RunningLiveCoachScreen extends StatefulWidget {
  final OptionRepository? optionRepository;
  final String? sportId;

  const RunningLiveCoachScreen({
    super.key,
    this.optionRepository,
    this.sportId,
  });

  @override
  State<RunningLiveCoachScreen> createState() => _RunningLiveCoachScreenState();
}

class _RunningLiveCoachScreenState extends State<RunningLiveCoachScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // Serialized inference keeps native MediaPipe backpressure intact while
  // targeting 20 Hz contact-event resolution on capable devices.
  static const _frameProcessingInterval = runningLiveGaitTargetFrameInterval;
  static const _repeatSpeechCooldown = Duration(seconds: 6);
  static const _changeSpeechCooldown = Duration(seconds: 2);
  static const _metricsLogInterval = Duration(seconds: 5);
  static const _skipEventLogInterval = Duration(seconds: 2);
  static const _uiStateThrottleInterval = Duration(milliseconds: 500);
  static const _initialCoachingState = RunningLiveCoachingState(
    primaryCue: RunningLivePrimaryCue.keepRunning,
  );
  static const _initialSprintCoachingState =
      SprintRealtimeCoachingState.initial();

  final LiveSprintCoachingService _coachingService =
      LiveSprintCoachingService();
  final LiveSprintTrendService _liveSprintTrendService =
      const LiveSprintTrendService();
  final LiveSprintCalibrationReadinessService
      _liveSprintCalibrationReadinessService =
      const LiveSprintCalibrationReadinessService();
  final LiveSprintFieldValidationMatrixService
      _liveSprintFieldValidationMatrixService =
      const LiveSprintFieldValidationMatrixService();
  final LiveSprintCalibrationCandidateService
      _liveSprintCalibrationCandidateService =
      const LiveSprintCalibrationCandidateService();
  final LiveSprintCaptureContextService _liveSprintCaptureContextService =
      const LiveSprintCaptureContextService();
  final RunningLiveSessionMetricsCollector _sessionMetricsCollector =
      RunningLiveSessionMetricsCollector();
  final SprintLiveSessionMetricsCollector _sprintSessionMetricsCollector =
      SprintLiveSessionMetricsCollector();
  final LiveSprintPoseEvidenceCollector _poseEvidenceCollector =
      LiveSprintPoseEvidenceCollector();
  final MediaPipePoseLandmarkerService _mediaPipePoseLandmarker =
      const MediaPipePoseLandmarkerService();
  final RunningVisualPoseTracker _visualPoseTracker =
      RunningVisualPoseTracker();
  final ValueNotifier<RunningVisualPoseFrame?> _poseOverlayFrame =
      ValueNotifier<RunningVisualPoseFrame?>(null);
  final FlutterTts _tts = FlutterTts();
  final Stopwatch _frameClock = Stopwatch();
  late final Ticker _poseOverlayTicker;
  RunningCoachHistoryService? _historyService;

  final Map<DeviceOrientation, int> _orientations = const {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  CameraDescription? _activeCamera;
  RunningLiveCoachingState _coachingState = _initialCoachingState;
  RunningLiveCoachingState _latestCoachingState = _initialCoachingState;
  SprintRealtimeCoachingState _sprintCoachingState =
      _initialSprintCoachingState;
  SprintRealtimeCoachingState _latestSprintCoachingState =
      _initialSprintCoachingState;
  SprintCaptureCalibrationProfile _sprintCalibrationProfile =
      SprintCaptureCalibrationProfile.balanced;
  SprintPipelineConfig _sprintPipelineConfig = const SprintPipelineConfig();
  bool _isInitializing = true;
  bool _isSpeechEnabled = true;
  bool _isHudExpanded = false;
  bool _isDisposed = false;
  bool _isFinalizingSession = false;
  bool _allowRoutePop = false;
  bool _isProcessingFrame = false;
  String? _configuredTtsLanguage;
  DateTime _frameClockEpoch = DateTime.now();
  DateTime? _lastProcessedAt;
  DateTime? _lastSpokenAt;
  DateTime? _lastMetricsLoggedAt;
  DateTime? _lastUiStatePublishedAt;
  String? _lastSpokenGuidanceKey;
  Size? _latestDetectorImageSize;
  String? _cameraErrorCode;
  String? _liveCoachErrorCode;
  String? _sessionId;
  int _cameraSessionId = 0;
  final Map<RunningLiveSkippedFrameReason, DateTime> _lastSkipLogAtByReason =
      <RunningLiveSkippedFrameReason, DateTime>{};
  List<RunningCoachSessionAnalysis> _recentSessions =
      const <RunningCoachSessionAnalysis>[];

  bool get _isAndroidPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isIosPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  bool get _isSupportedMobilePlatform => _isAndroidPlatform || _isIosPlatform;

  @override
  void initState() {
    super.initState();
    final optionRepository = widget.optionRepository;
    if (optionRepository != null) {
      _historyService = RunningCoachHistoryService(
        optionRepository,
        sportId: widget.sportId,
      );
      _recentSessions = _historyService!.allSessions();
    }
    _applySprintCalibrationProfile(
      SprintCaptureCalibrationProfileService(
        optionRepository,
      ).loadSelectedProfile(),
      resetSprintState: false,
    );
    WidgetsBinding.instance.addObserver(this);
    _poseOverlayTicker = createTicker(_handlePoseOverlayTick)..start();
    _resetFrameClock();
    unawaited(_initializeCamera());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_configureTts());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _endSessionLogging(reason: 'lifecycle_${state.name}');
      _cameraSessionId++;
      _isProcessingFrame = false;
      _frameClock.stop();
      _poseOverlayTicker.stop();
      _latestDetectorImageSize = null;
      _resetVisualPoseOverlay();
      final controller = _controller;
      _controller = null;
      unawaited(_mediaPipePoseLandmarker.close());
      if (controller != null) {
        unawaited(controller.dispose());
      }
      return;
    }
    if (state == AppLifecycleState.resumed) {
      if (!_poseOverlayTicker.isActive) {
        _poseOverlayTicker.start();
      }
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
    _cameraSessionId++;
    _isProcessingFrame = false;
    _frameClock.stop();
    _poseOverlayTicker.dispose();
    _resetVisualPoseOverlay();
    _poseOverlayFrame.dispose();
    if (controller != null) {
      unawaited(controller.dispose());
    }
    unawaited(_mediaPipePoseLandmarker.close());
    unawaited(_tts.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: _allowRoutePop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _isFinalizingSession) {
          return;
        }
        unawaited(_finishSessionOrBack());
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: _buildBody(context, l10n),
        ),
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

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final detectorImageSize = _latestDetectorImageSize;
          final previewSourceSize = detectorImageSize == null
              ? cameraPreviewSourceSizeForViewport(
                  controllerPreviewSize: previewSize,
                  viewportSize: constraints.biggest,
                )
              : CameraDisplayGeometry.fromDetectorImageSize(
                  detectorImageSize: detectorImageSize,
                  controllerPreviewSize: previewSize,
                  mirrorHorizontally:
                      _activeCamera?.lensDirection == CameraLensDirection.front,
                ).previewSourceSize;
          return SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.center,
              child: SizedBox(
                width: previewSourceSize.width,
                height: previewSourceSize.height,
                child: CameraPreview(controller),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_liveCoachErrorCode != null) {
      return _StatusPane(
        title: l10n.runningCoachLivePoseIssueTitle,
        body: _liveCoachErrorMessage(l10n, _liveCoachErrorCode!),
        actionLabel: l10n.runningCoachLiveRetryAction,
        onAction: _initializeCamera,
      );
    }

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
    final guidance = _guidanceFor(
      l10n,
      runningState: _coachingState,
      sprintState: _sprintCoachingState,
    );
    final poseEvidenceDiagnostic = _poseEvidenceCollector.diagnosticSnapshot();
    final poseEvidenceCue = _poseEvidenceBlockerCue(
      l10n,
      poseEvidenceDiagnostic.currentBlocker,
    );
    final cueText = poseEvidenceCue ?? guidance.cueText;
    final diagnosis = guidance.diagnosis;
    final actionTip = guidance.actionTip;
    final insightDetails = _buildInsightDetails(l10n);
    final focusPriorities =
        _coachingState.coachingReport?.focusPriorityByMetric ??
            const <RunningCoachMetric, int>{};
    final insightSections = _buildInsightSections(l10n, insightDetails);
    final panelTitle = _panelTitle(l10n);
    final hasPersistedLiveSessions = _recentSessions.any(
      (session) =>
          session.source == RunningCoachSessionSource.sprintLive &&
          session.liveSprintReport != null,
    );
    final fieldMatrixSummary = hasPersistedLiveSessions
        ? _liveSprintFieldValidationMatrixService.build(_recentSessions)
        : null;
    final calibrationCandidateSummary = hasPersistedLiveSessions
        ? _liveSprintCalibrationCandidateService.build(_recentSessions)
        : null;
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCameraViewport(),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: RunningPoseAnatomicalPainter(
                frameListenable: _poseOverlayFrame,
                mirrorHorizontally:
                    _activeCamera?.lensDirection == CameraLensDirection.front,
              ),
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
                  final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                  final isShortHeight = constraints.maxHeight < 430;
                  final isVeryShortHeight = constraints.maxHeight < 300;
                  final isCompactChrome = constraints.maxWidth < 360 ||
                      isShortHeight ||
                      textScale >= 1.5;
                  final topGap = isShortHeight ? 6.0 : 10.0;
                  final topReserve = isVeryShortHeight
                      ? 64.0
                      : isCompactChrome
                          ? 130.0
                          : 168.0;
                  final expandedPanelMaxHeight = math.max(
                    96.0,
                    math.min(440.0, constraints.maxHeight - topReserve),
                  );
                  return Column(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: overlayWidth),
                          child: _LiveTopBar(
                            title: l10n.runningCoachLiveScreenTitle,
                            showTitle: !isCompactChrome,
                            canSwitchCamera: _cameras.length > 1,
                            isInitializing: _isInitializing,
                            isSpeechEnabled: _isSpeechEnabled,
                            onBack: () => unawaited(_finishSessionOrBack()),
                            onGuide: _openGuide,
                            onToggleSpeech: _toggleSpeech,
                            onSwitchCamera: _switchCamera,
                            guideTooltip: l10n.runningCoachLiveGuideAction,
                            switchTooltip: l10n.runningCoachLiveSwitchCamera,
                          ),
                        ),
                      ),
                      if (!isVeryShortHeight) ...[
                        SizedBox(height: topGap),
                        Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: overlayWidth),
                            child: RunningLiveCoachCueBanner(
                              icon: statusTheme.icon,
                              color: statusTheme.color,
                              background: statusTheme.background,
                              title: statusTheme.title,
                              body: cueText,
                              compact: isCompactChrome,
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: overlayWidth),
                            child: RunningLiveCoachHud(
                              isExpanded: _isHudExpanded,
                              compact: isCompactChrome,
                              statusTitle: statusTheme.title,
                              scoreLabel: scoreLabel,
                              cueText: cueText,
                              maxExpandedHeight: expandedPanelMaxHeight,
                              onToggleExpanded: _toggleHudExpanded,
                              expandedDetails: _ScoreExplanationPanel(
                                title: panelTitle,
                                scoreLabel: scoreLabel,
                                trackedFramesLabel: trackedFramesLabel,
                                speechLabel: speechLabel,
                                cueText: cueText,
                                diagnosis: diagnosis,
                                actionTip: actionTip,
                                gaitAnalysis: _coachingState.gaitAnalysis,
                                sprintState: _sprintCoachingState,
                                calibrationProfile: _sprintCalibrationProfile,
                                profileSelectionEnabled: !_isInitializing,
                                onCalibrationProfileChanged:
                                    _selectSprintCalibrationProfile,
                                poseEvidenceDiagnostic: poseEvidenceDiagnostic,
                                fieldMatrixSummary: fieldMatrixSummary,
                                calibrationCandidateSummary:
                                    calibrationCandidateSummary,
                                metricScores: insightDetails,
                                focusPriorities: focusPriorities,
                                metricSections: insightSections,
                                compact: isCompactChrome,
                              ),
                            ),
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

    final sessionId = ++_cameraSessionId;
    _endSessionLogging(reason: 'reinitialize');
    _isFinalizingSession = false;
    _allowRoutePop = false;
    _isProcessingFrame = false;
    _resetFrameClock();

    if (!_isSupportedMobilePlatform) {
      _resetVisualPoseOverlay();
      setState(() {
        _coachingState = _initialCoachingState;
        _latestCoachingState = _initialCoachingState;
        _sprintCoachingState = _initialSprintCoachingState;
        _latestSprintCoachingState = _initialSprintCoachingState;
        _cameraErrorCode = 'unsupported_platform';
        _liveCoachErrorCode = null;
        _isInitializing = false;
        _isHudExpanded = false;
        _lastUiStatePublishedAt = null;
        _latestDetectorImageSize = null;
      });
      return;
    }

    setState(() {
      _coachingState = _initialCoachingState;
      _latestCoachingState = _initialCoachingState;
      _sprintCoachingState = _initialSprintCoachingState;
      _latestSprintCoachingState = _initialSprintCoachingState;
      _isInitializing = true;
      _cameraErrorCode = null;
      _liveCoachErrorCode = null;
      _isHudExpanded = false;
      _lastUiStatePublishedAt = null;
      _latestDetectorImageSize = null;
    });

    final oldController = _controller;
    _controller = null;
    if (oldController != null) {
      await oldController.dispose();
    }
    await _mediaPipePoseLandmarker.close();
    if (_isDisposed || sessionId != _cameraSessionId) {
      return;
    }
    _coachingService.reset();
    _sessionMetricsCollector.reset();
    _sprintSessionMetricsCollector.reset();
    _poseEvidenceCollector.reset();
    _resetVisualPoseOverlay();
    _lastProcessedAt = null;
    _lastSpokenAt = null;
    _lastMetricsLoggedAt = null;
    _lastUiStatePublishedAt = null;
    _lastSpokenGuidanceKey = null;
    _sessionId = null;
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
      if (_isDisposed || sessionId != _cameraSessionId) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
      _startSessionLogging();
    } on CameraException catch (error) {
      if (_isDisposed || sessionId != _cameraSessionId) {
        return;
      }
      setState(() {
        _cameraErrorCode = error.code;
        _isInitializing = false;
      });
    } catch (_) {
      if (_isDisposed || sessionId != _cameraSessionId) {
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

  void _toggleHudExpanded() {
    setState(() {
      _isHudExpanded = !_isHudExpanded;
    });
  }

  void _applySprintCalibrationProfile(
    SprintCaptureCalibrationProfile profile, {
    required bool resetSprintState,
  }) {
    _sprintCalibrationProfile = profile;
    _sprintPipelineConfig =
        SprintCaptureCalibrationProfileService.pipelineConfigFor(profile);
    _coachingService.updateSprintConfig(_sprintPipelineConfig);
    _poseEvidenceCollector.updateThresholds(
      SprintCaptureCalibrationProfileService.evidenceThresholdsFor(profile),
    );
    if (!resetSprintState) {
      return;
    }
    _sprintSessionMetricsCollector.reset();
    _poseEvidenceCollector.reset(startedAt: DateTime.now());
    _sprintCoachingState = _initialSprintCoachingState;
    _latestSprintCoachingState = _initialSprintCoachingState;
    _lastUiStatePublishedAt = null;
  }

  void _selectSprintCalibrationProfile(
    SprintCaptureCalibrationProfile profile,
  ) {
    if (profile == _sprintCalibrationProfile) {
      return;
    }
    final preferredCamera = _activeCamera;
    setState(() {
      _applySprintCalibrationProfile(profile, resetSprintState: false);
    });
    unawaited(
      SprintCaptureCalibrationProfileService(
        widget.optionRepository,
      ).saveSelectedProfile(profile),
    );
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.runningCoachSprintCalibrationProfileRestarted),
        ),
      );
    unawaited(_initializeCamera(preferredCamera: preferredCamera));
  }

  void _openGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RunningLiveCoachGuideScreen()),
    );
  }

  void _startSessionLogging() {
    final now = DateTime.now();
    _poseEvidenceCollector.reset(startedAt: now);
    _sessionId = 'live-sprint-${now.microsecondsSinceEpoch}';
    _emitSessionLog(
      event: 'start',
      force: true,
      now: now,
      details: <String, Object?>{
        'cameraLensDirection': _activeCamera?.lensDirection.name,
        'targetFrameIntervalMs': _frameProcessingInterval.inMilliseconds,
        'sprintCalibrationProfile': _sprintCalibrationProfile.name,
      },
    );
  }

  bool get _hasReportableSession {
    return _latestCoachingState.coachingReport != null ||
        _latestSprintCoachingState.features.hasEnoughSignal ||
        _sessionMetricsCollector.snapshot().eventCount >= 2;
  }

  Future<void> _finishSessionOrBack() async {
    if (_isFinalizingSession) {
      return;
    }
    if (!_hasReportableSession) {
      _endSessionLogging(reason: 'user_exit_without_report');
      if (mounted) {
        setState(() {
          _allowRoutePop = true;
        });
        await Navigator.of(context).maybePop();
      }
      return;
    }

    setState(() {
      _isFinalizingSession = true;
    });
    final completedAt = DateTime.now();
    final sessionId =
        _sessionId ?? 'live-sprint-${completedAt.microsecondsSinceEpoch}';
    final runningSnapshot = _sessionMetricsCollector.snapshot(now: completedAt);
    final sprintSnapshot = _sprintSessionMetricsCollector.snapshot(
      now: completedAt,
    );
    final runningState = _latestCoachingState;
    final sprintState = _latestSprintCoachingState;
    final poseEvidence = _poseEvidenceCollector.snapshot();
    final poseEvidenceDiagnostic = _poseEvidenceCollector.diagnosticSnapshot();
    final captureContext = _liveSprintCaptureContextService.build(
      deviceClass: LiveSprintCaptureContextService.deviceClassForShortestSide(
        MediaQuery.sizeOf(context).shortestSide,
      ),
      cameraLensDirection: _captureLensDirectionFor(
        _activeCamera?.lensDirection,
      ),
      poseEvidence: poseEvidence,
      poseEvidenceDiagnostic: poseEvidenceDiagnostic,
    );
    final fallbackSession = const LiveSprintSessionReportService().buildSession(
      sessionId: sessionId,
      completedAt: completedAt,
      runningSnapshot: runningSnapshot,
      sprintSnapshot: sprintSnapshot,
      runningState: runningState,
      sprintState: sprintState,
      calibrationProfile: _sprintCalibrationProfile,
      poseEvidence: poseEvidence,
      poseEvidenceDiagnostic: poseEvidenceDiagnostic,
      captureContext: captureContext,
    );
    _endSessionLogging(reason: 'completed');

    var session = fallbackSession;
    var isPersisted = false;
    var trendSessions = <RunningCoachSessionAnalysis>[session];
    final historyService = _historyService;
    if (historyService != null) {
      try {
        final savedSessions = await historyService.saveLiveSprintSession(
          sessionId: sessionId,
          completedAt: completedAt,
          runningSnapshot: runningSnapshot,
          sprintSnapshot: sprintSnapshot,
          runningState: runningState,
          sprintState: sprintState,
          calibrationProfile: _sprintCalibrationProfile,
          poseEvidence: poseEvidence,
          poseEvidenceDiagnostic: poseEvidenceDiagnostic,
          captureContext: captureContext,
        );
        if (savedSessions.isNotEmpty) {
          session = savedSessions.first;
          isPersisted = true;
          trendSessions = savedSessions;
          _recentSessions = savedSessions;
        }
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Saving live sprint session report failed: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
    }

    if (!mounted || _isDisposed) {
      return;
    }
    await _tts.stop();
    if (!mounted || _isDisposed) {
      return;
    }
    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => RunningLiveSessionResultScreen(
          session: session,
          isPersisted: isPersisted,
          trendSummary: _liveSprintTrendService.build(
            trendSessions,
            currentSessionId: session.id,
          ),
          calibrationReadinessSummary:
              _liveSprintCalibrationReadinessService.build(
            trendSessions,
            currentSessionId: session.id,
          ),
          fieldValidationMatrixSummary:
              _liveSprintFieldValidationMatrixService.build(
            trendSessions,
            currentSessionId: session.id,
          ),
          calibrationCandidateSummary:
              _liveSprintCalibrationCandidateService.build(
            trendSessions,
            currentSessionId: session.id,
          ),
        ),
      ),
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
    if (_isDisposed && event != 'end') {
      return;
    }

    final timestamp = now ?? DateTime.now();
    if (event == 'periodic' &&
        !force &&
        _lastMetricsLoggedAt != null &&
        timestamp.difference(_lastMetricsLoggedAt!) < _metricsLogInterval) {
      return;
    }

    final snapshot = _sessionMetricsCollector.snapshot(now: timestamp);
    final payload = _sessionMetricsCollector.buildLogPayload(
      event: event,
      sessionId: _sessionId ?? 'inactive',
      timestamp: timestamp,
      targetFrameInterval: _frameProcessingInterval,
      snapshot: snapshot,
      state: _latestCoachingState,
      details: details,
    );
    final sprintSnapshot = _sprintSessionMetricsCollector.snapshot(
      now: timestamp,
    );
    payload['sprint'] = _sprintSessionMetricsCollector.buildLogPayload(
      event: event,
      sessionId: _sessionId ?? 'inactive',
      timestamp: timestamp,
      config: _sprintPipelineConfig,
      snapshot: sprintSnapshot,
      state: _latestSprintCoachingState,
    );
    payload['sprintCapture'] = <String, Object?>{
      'calibrationProfile': _sprintCalibrationProfile.name,
      'poseEvidenceDiagnostic':
          _poseEvidenceCollector.diagnosticSnapshot().toMap(),
    };
    if (kDebugMode) {
      debugPrint('[RunningLiveSession] ${jsonEncode(payload)}');
      final sessionId = _sessionId;
      if (event == 'end' && sessionId != null) {
        final capture = _sessionMetricsCollector.buildCalibrationCapturePayload(
          sessionId: sessionId,
          targetFrameInterval: _frameProcessingInterval,
          snapshot: snapshot,
        );
        debugPrint(
          '$runningLiveCalibrationCaptureLogMarker ${jsonEncode(capture)}',
          wrapWidth: 4096,
        );
      }
    }
    if (event == 'periodic') {
      _lastMetricsLoggedAt = timestamp;
    }
  }

  void _emitSkippedFrameEvent(
    RunningLiveSkippedFrameReason reason,
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

  int _skippedFrameCount(RunningLiveSkippedFrameReason reason) {
    final snapshot = _sessionMetricsCollector.snapshot();
    return switch (reason) {
      RunningLiveSkippedFrameReason.detectorBusy => snapshot.busySkippedFrames,
      RunningLiveSkippedFrameReason.throttled =>
        snapshot.throttledSkippedFrames,
      RunningLiveSkippedFrameReason.invalidInput => snapshot.invalidInputFrames,
      RunningLiveSkippedFrameReason.analysisError =>
        snapshot.analysisErrorFrames,
    };
  }

  void _recordSkippedFrame(RunningLiveSkippedFrameReason reason) {
    _sessionMetricsCollector.recordSkippedFrame(reason);
    _sprintSessionMetricsCollector.recordSkippedFrame(
      switch (reason) {
        RunningLiveSkippedFrameReason.detectorBusy =>
          SprintSkippedFrameReason.detectorBusy,
        RunningLiveSkippedFrameReason.throttled =>
          SprintSkippedFrameReason.throttled,
        RunningLiveSkippedFrameReason.invalidInput =>
          SprintSkippedFrameReason.invalidInput,
        RunningLiveSkippedFrameReason.analysisError =>
          SprintSkippedFrameReason.analysisError,
      },
    );
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDisposed || _isFinalizingSession || _liveCoachErrorCode != null) {
      return;
    }
    final receivedAt = DateTime.now();
    _sessionMetricsCollector.recordCameraInputFrame(timestamp: receivedAt);
    _sprintSessionMetricsCollector.recordCameraInputFrame(
      timestamp: receivedAt,
    );

    if (_isProcessingFrame) {
      _recordSkippedFrame(RunningLiveSkippedFrameReason.detectorBusy);
      _emitSkippedFrameEvent(
        RunningLiveSkippedFrameReason.detectorBusy,
        receivedAt,
      );
      _emitSessionLog(event: 'periodic', force: false, now: receivedAt);
      return;
    }

    final sessionId = _cameraSessionId;
    final now = _monotonicFrameTimestamp();
    if (_lastProcessedAt != null &&
        now.difference(_lastProcessedAt!) < _frameProcessingInterval) {
      _recordSkippedFrame(RunningLiveSkippedFrameReason.throttled);
      _emitSkippedFrameEvent(
        RunningLiveSkippedFrameReason.throttled,
        receivedAt,
      );
      _emitSessionLog(event: 'periodic', force: false, now: receivedAt);
      return;
    }

    final frameInput = _cameraFrameInputFromCameraImage(image);
    if (frameInput == null) {
      _recordSkippedFrame(RunningLiveSkippedFrameReason.invalidInput);
      _emitSkippedFrameEvent(
        RunningLiveSkippedFrameReason.invalidInput,
        receivedAt,
      );
      _emitSessionLog(event: 'periodic', force: false, now: receivedAt);
      return;
    }
    _rememberDetectorImageSize(frameInput.detectorImageSize);

    _isProcessingFrame = true;
    _lastProcessedAt = now;
    final stopwatch = Stopwatch()..start();

    try {
      final detection =
          await _mediaPipePoseLandmarker.detectPoseFromCameraImage(
        image: image,
        rotationDegrees: frameInput.rotationDegrees,
        timestamp: now,
      );
      if (_isDisposed ||
          _isFinalizingSession ||
          !mounted ||
          sessionId != _cameraSessionId) {
        stopwatch.stop();
        return;
      }
      final visualFrame = _visualPoseTracker.ingestDetection(
        detection,
        timestamp: now,
        fallbackImageSize: frameInput.detectorImageSize,
      );
      final coachingSnapshot = _coachingService.ingestDetection(
        detection,
        timestamp: now,
      );
      final state = coachingSnapshot.runningState;
      final sprintState = coachingSnapshot.sprintState;
      stopwatch.stop();
      _sessionMetricsCollector.recordAnalyzedFrame(
        timestamp: now,
        processingTime: stopwatch.elapsed,
        state: state,
      );
      if (coachingSnapshot.sprintAnalysisUpdated) {
        _sprintSessionMetricsCollector.recordAnalyzedFrame(
          timestamp: now,
          processingTime: stopwatch.elapsed,
          frame: coachingSnapshot.sprintPoseFrame,
          state: sprintState,
        );
      } else {
        _sprintSessionMetricsCollector.recordSkippedFrame(
          SprintSkippedFrameReason.throttled,
        );
      }
      if (_isDisposed ||
          _isFinalizingSession ||
          !mounted ||
          sessionId != _cameraSessionId) {
        return;
      }
      _visualPoseTracker.ingestGaitEvents(state.gaitAnalysis.recentEvents);
      final poseFrame =
          _visualPoseTracker.frameAt(_currentFrameClockTimestamp()) ??
              visualFrame;
      _poseOverlayFrame.value = poseFrame;
      _poseEvidenceCollector.record(
        visualFrame: poseFrame,
        gaitAnalysis: state.gaitAnalysis,
        sprintState: sprintState,
        timestamp: now,
      );
      _publishCoachingState(state, sprintState, now);
      _emitSessionLog(event: 'periodic', force: false, now: now);
      await _maybeSpeakGuidance(
        _guidanceFor(
          AppLocalizations.of(context)!,
          runningState: state,
          sprintState: sprintState,
        ),
      );
    } catch (error, stackTrace) {
      stopwatch.stop();
      _recordSkippedFrame(RunningLiveSkippedFrameReason.analysisError);
      _emitSkippedFrameEvent(
        RunningLiveSkippedFrameReason.analysisError,
        receivedAt,
      );
      _emitSessionLog(
        event: 'mediapipe_error',
        force: true,
        now: now,
        details: <String, Object?>{
          'errorType': error.runtimeType.toString(),
          'message': error.toString(),
        },
      );
      await _showLiveCoachError(
        error,
        stackTrace,
        sessionId: sessionId,
      );
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _publishCoachingState(
    RunningLiveCoachingState state,
    SprintRealtimeCoachingState sprintState,
    DateTime timestamp,
  ) {
    _latestCoachingState = state;
    _latestSprintCoachingState = sprintState;
    if (_isDisposed || !mounted) {
      return;
    }
    if (!_shouldPublishCoachingUiState(state, sprintState, timestamp)) {
      return;
    }
    setState(() {
      _coachingState = state;
      _sprintCoachingState = sprintState;
      _lastUiStatePublishedAt = timestamp;
    });
  }

  bool _shouldPublishCoachingUiState(
    RunningLiveCoachingState state,
    SprintRealtimeCoachingState sprintState,
    DateTime timestamp,
  ) {
    if (state.primaryCue != _coachingState.primaryCue ||
        state.framingIssue != _coachingState.framingIssue ||
        sprintState.status != _sprintCoachingState.status ||
        sprintState.feedback?.code != _sprintCoachingState.feedback?.code) {
      return true;
    }
    final lastPublishedAt = _lastUiStatePublishedAt;
    return lastPublishedAt == null ||
        timestamp.difference(lastPublishedAt) >= _uiStateThrottleInterval;
  }

  void _resetFrameClock() {
    _frameClock
      ..reset()
      ..start();
    _frameClockEpoch = DateTime.now();
  }

  void _handlePoseOverlayTick(Duration _) {
    if (_isDisposed || !_frameClock.isRunning) {
      return;
    }
    _poseOverlayFrame.value = _visualPoseTracker.frameAt(
      _currentFrameClockTimestamp(),
    );
  }

  DateTime _currentFrameClockTimestamp() {
    if (!_frameClock.isRunning) {
      return _frameClockEpoch;
    }
    return _frameClockEpoch.add(_frameClock.elapsed);
  }

  void _resetVisualPoseOverlay() {
    _visualPoseTracker.reset();
    _poseOverlayFrame.value = null;
  }

  void _rememberDetectorImageSize(Size detectorImageSize) {
    if (_latestDetectorImageSize == detectorImageSize) {
      return;
    }
    _latestDetectorImageSize = detectorImageSize;
    if (_isDisposed || !mounted) {
      return;
    }
    setState(() {});
  }

  DateTime _monotonicFrameTimestamp() {
    if (!_frameClock.isRunning) {
      _frameClock.start();
    }
    final candidate = _frameClockEpoch.add(_frameClock.elapsed);
    final lastProcessedAt = _lastProcessedAt;
    if (lastProcessedAt != null && !candidate.isAfter(lastProcessedAt)) {
      return lastProcessedAt.add(const Duration(milliseconds: 1));
    }
    return candidate;
  }

  _CameraFrameInput? _cameraFrameInputFromCameraImage(CameraImage image) {
    final controller = _controller;
    final camera = _activeCamera;
    if (controller == null || camera == null) {
      return null;
    }

    final rotationDegrees = _resolveImageRotationDegrees(controller, camera);
    if (rotationDegrees == null) {
      return null;
    }

    final format = image.format.group;
    if ((_isAndroidPlatform && format != ImageFormatGroup.nv21) ||
        (_isIosPlatform && format != ImageFormatGroup.bgra8888)) {
      return null;
    }
    if (image.planes.length != 1) {
      return null;
    }

    return _CameraFrameInput(
      rotationDegrees: rotationDegrees,
      detectorImageSize: detectorImageSizeForRotation(
        Size(image.width.toDouble(), image.height.toDouble()),
        rotationDegrees,
      ),
    );
  }

  int? _resolveImageRotationDegrees(
    CameraController controller,
    CameraDescription camera,
  ) {
    if (_isIosPlatform) {
      return camera.sensorOrientation;
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
      return rotationCompensation;
    }

    return null;
  }

  Future<void> _showLiveCoachError(
    Object error,
    StackTrace stackTrace, {
    required int sessionId,
  }) async {
    if (_isDisposed || sessionId != _cameraSessionId) {
      return;
    }
    if (kDebugMode) {
      debugPrint('Running live MediaPipe inference failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    _endSessionLogging(reason: 'pose_failed');
    _cameraSessionId++;
    _isProcessingFrame = false;
    final controller = _controller;
    _controller = null;
    _coachingService.reset();
    _resetVisualPoseOverlay();
    _lastProcessedAt = null;
    _lastSpokenAt = null;
    _lastUiStatePublishedAt = null;
    _lastSpokenGuidanceKey = null;
    _latestDetectorImageSize = null;
    _latestCoachingState = _initialCoachingState;
    _latestSprintCoachingState = _initialSprintCoachingState;

    if (mounted) {
      setState(() {
        _liveCoachErrorCode = 'pose_failed';
        _cameraErrorCode = null;
        _isInitializing = false;
        _coachingState = _initialCoachingState;
        _sprintCoachingState = _initialSprintCoachingState;
        _isHudExpanded = false;
        _latestDetectorImageSize = null;
      });
    }

    if (controller != null) {
      await controller.dispose();
    }
    await _mediaPipePoseLandmarker.close();
  }

  Future<void> _maybeSpeakGuidance(_LiveCoachingGuidance guidance) async {
    if (!_isSpeechEnabled || _isDisposed || !mounted) {
      return;
    }
    if (!guidance.shouldSpeak || guidance.cueText.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final cooldown = _lastSpokenGuidanceKey == guidance.key
        ? _repeatSpeechCooldown
        : _changeSpeechCooldown;
    if (_lastSpokenAt != null && now.difference(_lastSpokenAt!) < cooldown) {
      return;
    }

    _lastSpokenGuidanceKey = guidance.key;
    _lastSpokenAt = now;
    await _tts.stop();
    await _tts.speak(guidance.cueText);
  }

  String _panelTitle(AppLocalizations l10n) {
    if (_sprintCoachingState.status == SprintCoachingStatus.coaching) {
      return l10n.runningCoachSprintLiveStatusCoaching;
    }
    if (_sprintCoachingState.status == SprintCoachingStatus.ready) {
      return l10n.runningCoachSprintLiveStatusReady;
    }
    final report = _coachingState.coachingReport;
    if (report == null) {
      return _coachingState.framingIssue == null
          ? l10n.runningCoachLiveStatusCollecting
          : l10n.runningCoachLiveStatusFraming;
    }
    if (_coachingState.highlightedInsight?.quality.isLowConfidence ?? false) {
      return l10n.runningCoachLiveStatusCollecting;
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
        RunningLiveFramingIssue.trackingUncertain =>
          l10n.runningCoachLiveTrackingUncertainBody,
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
      if (insight.quality.isLowConfidence) {
        return _runningLiveQualityReasonText(l10n, insight.quality);
      }
      return RunningCoachInsightCopy.fromInsight(insight, l10n).summary;
    }
    return '';
  }

  String _actionTipText(AppLocalizations l10n, RunningLiveCoachingState state) {
    if (state.framingIssue != null) {
      return _voiceText(l10n, state.primaryCue);
    }
    if (state.highlightedInsight case final insight?) {
      if (insight.quality.isLowConfidence) {
        return l10n.runningCoachLiveCueKeepRunning;
      }
      return RunningCoachInsightCopy.fromInsight(insight, l10n).cue;
    }
    return '';
  }

  _LiveCoachingGuidance _guidanceFor(
    AppLocalizations l10n, {
    required RunningLiveCoachingState runningState,
    required SprintRealtimeCoachingState sprintState,
  }) {
    final sprintFeedback = sprintState.feedback;
    if (runningState.framingIssue == null &&
        sprintFeedback != null &&
        sprintFeedback.severity != SprintFeedbackSeverity.info) {
      final cueText = _localizedSprintFeedbackCue(
        l10n,
        sprintFeedback.localizationKey,
      );
      if (cueText.isNotEmpty) {
        return _LiveCoachingGuidance(
          key: 'sprint-${sprintFeedback.cooldownKey}',
          cueText: cueText,
          diagnosis: _localizedSprintFeedbackDiagnosis(
            l10n,
            sprintFeedback.diagnosisKey,
          ),
          actionTip: _localizedSprintFeedbackActionTip(
            l10n,
            sprintFeedback.actionTipKey,
          ),
        );
      }
    }

    final cue = runningState.primaryCue;
    return _LiveCoachingGuidance(
      key: 'running-${cue.name}',
      cueText: _cueText(l10n, cue),
      diagnosis: _diagnosisText(l10n, runningState),
      actionTip: _actionTipText(l10n, runningState),
      shouldSpeak: cue != RunningLivePrimaryCue.keepRunning,
    );
  }

  String _localizedSprintFeedbackCue(
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
      'runningCoachSprintCueLandUnderHips' =>
        l10n.runningCoachSprintCueLandUnderHips,
      'runningCoachSprintCueLiftOffQuickly' =>
        l10n.runningCoachSprintCueLiftOffQuickly,
      'runningCoachSprintCueHoldLateForm' =>
        l10n.runningCoachSprintCueHoldLateForm,
      'runningCoachSprintCueKeepPushing' =>
        l10n.runningCoachSprintCueKeepPushing,
      _ => '',
    };
  }

  String _localizedSprintFeedbackDiagnosis(
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
      'runningCoachSprintDiagnosisLandUnderHips' =>
        l10n.runningCoachSprintDiagnosisLandUnderHips,
      'runningCoachSprintDiagnosisLiftOffQuickly' =>
        l10n.runningCoachSprintDiagnosisLiftOffQuickly,
      'runningCoachSprintDiagnosisHoldLateForm' =>
        l10n.runningCoachSprintDiagnosisHoldLateForm,
      'runningCoachSprintDiagnosisKeepPushing' =>
        l10n.runningCoachSprintDiagnosisKeepPushing,
      _ => '',
    };
  }

  String _localizedSprintFeedbackActionTip(
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
      'runningCoachSprintActionLandUnderHips' =>
        l10n.runningCoachSprintActionLandUnderHips,
      'runningCoachSprintActionLiftOffQuickly' =>
        l10n.runningCoachSprintActionLiftOffQuickly,
      'runningCoachSprintActionHoldLateForm' =>
        l10n.runningCoachSprintActionHoldLateForm,
      'runningCoachSprintActionKeepPushing' =>
        l10n.runningCoachSprintActionKeepPushing,
      _ => '',
    };
  }

  List<_LiveInsightData> _buildInsightDetails(AppLocalizations l10n) {
    final report = _coachingState.coachingReport;
    if (report == null) {
      return const [];
    }
    return [
      for (final insight in report.rankedInsights)
        _LiveInsightData(
          insight: insight,
          copy: RunningCoachInsightCopy.fromInsight(insight, l10n),
        ),
    ];
  }

  List<_LiveInsightSection> _buildInsightSections(
    AppLocalizations l10n,
    List<_LiveInsightData> insightDetails,
  ) {
    const order = [
      RunningCoachBodyRegion.upperBody,
      RunningCoachBodyRegion.lowerBody,
      RunningCoachBodyRegion.wholeBody,
    ];
    return [
      for (final region in order)
        if (insightDetails
                .where((detail) => detail.insight.metric.bodyRegion == region)
                .toList(growable: false)
            case final items when items.isNotEmpty)
          _LiveInsightSection(
            title: _bodyRegionTitle(l10n, region),
            items: items,
          ),
    ];
  }

  String _bodyRegionTitle(
    AppLocalizations l10n,
    RunningCoachBodyRegion region,
  ) {
    return switch (region) {
      RunningCoachBodyRegion.upperBody => l10n.runningCoachBodyRegionUpper,
      RunningCoachBodyRegion.lowerBody => l10n.runningCoachBodyRegionLower,
      RunningCoachBodyRegion.wholeBody => l10n.runningCoachBodyRegionWhole,
    };
  }

  String _voiceText(AppLocalizations l10n, RunningLivePrimaryCue cue) {
    return switch (cue) {
      RunningLivePrimaryCue.noRunnerDetected =>
        l10n.runningCoachLiveCueNoRunner,
      RunningLivePrimaryCue.trackingUncertain =>
        l10n.runningCoachLiveCueTrackingUncertain,
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
      RunningLivePrimaryCue.trackingUncertain =>
        l10n.runningCoachLiveCueTrackingUncertain,
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

  String _liveCoachErrorMessage(AppLocalizations l10n, String code) {
    return switch (code) {
      _ => l10n.runningCoachLivePoseFailed,
    };
  }
}

class RunningLiveCoachCueBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String body;
  final bool compact;

  const RunningLiveCoachCueBanner({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.body,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final semanticsLabel = body.isEmpty ? title : '$title. $body';
    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withAlpha(170)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: compact ? 9 : 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (!compact && body.isNotEmpty)
                        const SizedBox(height: 3),
                      if (body.isNotEmpty)
                        Text(
                          body,
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
        ),
      ),
    );
  }
}

class RunningLiveCoachVoiceToggleButton extends StatelessWidget {
  final bool isSpeechEnabled;
  final VoidCallback onToggleSpeech;

  const RunningLiveCoachVoiceToggleButton({
    super.key,
    required this.isSpeechEnabled,
    required this.onToggleSpeech,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tooltip = isSpeechEnabled
        ? l10n.runningCoachLiveVoiceToggleOnTooltip
        : l10n.runningCoachLiveVoiceToggleOffTooltip;
    final hint = isSpeechEnabled
        ? l10n.runningCoachLiveVoiceToggleOnHint
        : l10n.runningCoachLiveVoiceToggleOffHint;
    return Semantics(
      key: const ValueKey('running-live-coach-voice-toggle-semantics'),
      button: true,
      enabled: true,
      toggled: isSpeechEnabled,
      label: l10n.runningCoachLiveVoiceToggleLabel,
      hint: hint,
      onTap: onToggleSpeech,
      child: ExcludeSemantics(
        child: _OverlayActionButton(
          key: const ValueKey('running-live-coach-voice-toggle'),
          icon: isSpeechEnabled
              ? Icons.volume_up_rounded
              : Icons.volume_off_rounded,
          onPressed: onToggleSpeech,
          tooltip: tooltip,
        ),
      ),
    );
  }
}

@visibleForTesting
class RunningLiveCoachHud extends StatelessWidget {
  final bool isExpanded;
  final bool compact;
  final String statusTitle;
  final String scoreLabel;
  final String cueText;
  final double maxExpandedHeight;
  final VoidCallback onToggleExpanded;
  final Widget expandedDetails;

  const RunningLiveCoachHud({
    super.key,
    required this.isExpanded,
    required this.statusTitle,
    required this.scoreLabel,
    required this.cueText,
    required this.maxExpandedHeight,
    required this.onToggleExpanded,
    required this.expandedDetails,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final toggleLabel = isExpanded
        ? l10n.runningCoachLiveCollapseDetails
        : l10n.runningCoachLiveExpandDetails;
    final semanticLabel = isExpanded
        ? l10n.runningCoachLiveHudExpandedLabel
        : l10n.runningCoachLiveHudCollapsedLabel;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final compactHeight = textScale >= 1.5
        ? 140.0
        : compact
            ? 116.0
            : 132.0;
    final panelRadius = BorderRadius.circular(24);
    return Semantics(
      key: const ValueKey('running-live-coach-hud-semantics'),
      container: true,
      label: '$semanticLabel. $statusTitle. $scoreLabel. $cueText',
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: isExpanded ? maxExpandedHeight : compactHeight,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xDD121820),
              borderRadius: panelRadius,
              border: Border.all(color: Colors.white12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: panelRadius,
              child: isExpanded
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LiveCoachHudHeader(
                          compact: compact,
                          statusTitle: statusTitle,
                          scoreLabel: scoreLabel,
                          cueText: cueText,
                          toggleLabel: toggleLabel,
                          isExpanded: isExpanded,
                          onToggleExpanded: onToggleExpanded,
                        ),
                        const Divider(height: 1, color: Colors.white12),
                        Flexible(
                          fit: FlexFit.loose,
                          child: SingleChildScrollView(
                            key: const ValueKey(
                              'running-live-coach-expanded-scroll',
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                            child: expandedDetails,
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      key: const ValueKey('running-live-coach-compact-hud'),
                      height: compactHeight,
                      child: _LiveCoachHudHeader(
                        compact: compact,
                        statusTitle: statusTitle,
                        scoreLabel: scoreLabel,
                        cueText: cueText,
                        toggleLabel: toggleLabel,
                        isExpanded: isExpanded,
                        onToggleExpanded: onToggleExpanded,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveCoachHudHeader extends StatelessWidget {
  final bool compact;
  final String statusTitle;
  final String scoreLabel;
  final String cueText;
  final String toggleLabel;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  const _LiveCoachHudHeader({
    required this.compact,
    required this.statusTitle,
    required this.scoreLabel,
    required this.cueText,
    required this.toggleLabel,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final cueMaxLines = compact ? 1 : 2;
    return Padding(
      padding:
          EdgeInsets.fromLTRB(14, compact ? 10 : 12, 10, compact ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  cueText,
                  maxLines: cueMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  scoreLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFFB8F28B),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            key: const ValueKey('running-live-coach-hud-toggle'),
            onPressed: onToggleExpanded,
            tooltip: toggleLabel,
            icon: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveTopBar extends StatelessWidget {
  final String title;
  final bool showTitle;
  final bool canSwitchCamera;
  final bool isInitializing;
  final bool isSpeechEnabled;
  final VoidCallback onBack;
  final VoidCallback onGuide;
  final VoidCallback onToggleSpeech;
  final Future<void> Function() onSwitchCamera;
  final String guideTooltip;
  final String switchTooltip;

  const _LiveTopBar({
    required this.title,
    required this.showTitle,
    required this.canSwitchCamera,
    required this.isInitializing,
    required this.isSpeechEnabled,
    required this.onBack,
    required this.onGuide,
    required this.onToggleSpeech,
    required this.onSwitchCamera,
    required this.guideTooltip,
    required this.switchTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          fit: showTitle ? FlexFit.tight : FlexFit.loose,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(150),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: showTitle ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  _OverlayActionButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: onBack,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                  ),
                  if (showTitle) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                  ],
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
        RunningLiveCoachVoiceToggleButton(
          isSpeechEnabled: isSpeechEnabled,
          onToggleSpeech: onToggleSpeech,
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
    super.key,
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

class _LiveCoachingGuidance {
  final String key;
  final String cueText;
  final String diagnosis;
  final String actionTip;
  final bool shouldSpeak;

  const _LiveCoachingGuidance({
    required this.key,
    required this.cueText,
    required this.diagnosis,
    required this.actionTip,
    this.shouldSpeak = true,
  });
}

String _runningLiveQualityReasonText(
  AppLocalizations l10n,
  RunningMetricQuality quality,
) {
  return switch (quality.reason) {
    'low_coverage' => l10n.runningCoachQualityReasonLowCoverage,
    'limited_samples' => l10n.runningCoachQualityReasonLimitedSamples,
    'contact_phase_proxy' => l10n.runningCoachQualityReasonContactPhaseProxy,
    'low_confidence' => l10n.runningCoachQualityReasonLowConfidence,
    _ => l10n.runningCoachQualityReasonGeneric,
  };
}

String? _poseEvidenceBlockerCue(
  AppLocalizations l10n,
  LiveSprintPoseEvidenceBlocker? blocker,
) {
  return switch (blocker) {
    LiveSprintPoseEvidenceBlocker.fullBodyVisibility =>
      l10n.runningCoachPoseEvidenceBlockerFullBody,
    LiveSprintPoseEvidenceBlocker.stableSideView =>
      l10n.runningCoachPoseEvidenceBlockerSideView,
    LiveSprintPoseEvidenceBlocker.observedCoreJoints =>
      l10n.runningCoachPoseEvidenceBlockerCoreJoints,
    LiveSprintPoseEvidenceBlocker.gaitPhaseReadiness =>
      l10n.runningCoachPoseEvidenceBlockerGaitPhase,
    null => null,
  };
}

LiveSprintCameraLensDirection _captureLensDirectionFor(
  CameraLensDirection? direction,
) {
  return switch (direction) {
    CameraLensDirection.back => LiveSprintCameraLensDirection.rear,
    CameraLensDirection.front => LiveSprintCameraLensDirection.front,
    CameraLensDirection.external => LiveSprintCameraLensDirection.external,
    null => LiveSprintCameraLensDirection.unknown,
  };
}

String _sprintCalibrationProfileLabel(
  AppLocalizations l10n,
  SprintCaptureCalibrationProfile profile,
) {
  return switch (profile) {
    SprintCaptureCalibrationProfile.conservative =>
      l10n.runningCoachSprintCalibrationProfileConservative,
    SprintCaptureCalibrationProfile.balanced =>
      l10n.runningCoachSprintCalibrationProfileBalanced,
    SprintCaptureCalibrationProfile.responsive =>
      l10n.runningCoachSprintCalibrationProfileResponsive,
  };
}

String _sprintCalibrationProfileDescription(
  AppLocalizations l10n,
  SprintCaptureCalibrationProfile profile,
) {
  return switch (profile) {
    SprintCaptureCalibrationProfile.conservative =>
      l10n.runningCoachSprintCalibrationProfileConservativeDescription,
    SprintCaptureCalibrationProfile.balanced =>
      l10n.runningCoachSprintCalibrationProfileBalancedDescription,
    SprintCaptureCalibrationProfile.responsive =>
      l10n.runningCoachSprintCalibrationProfileResponsiveDescription,
  };
}

String _readinessStatusLabel(AppLocalizations l10n, bool ready) {
  return ready
      ? l10n.runningCoachSprintCaptureReadinessReady
      : l10n.runningCoachSprintCaptureReadinessAdjust;
}

String _readinessValueText(
  AppLocalizations l10n,
  LiveSprintCaptureReadinessCheck check, {
  bool includeJointCount = false,
}) {
  final current = _readinessPercent(check.value);
  final target = _readinessPercent(check.threshold);
  if (includeJointCount) {
    return l10n.runningCoachSprintCaptureReadinessCoreValue(
      current,
      target,
      check.observedCount,
      check.requiredCount,
    );
  }
  return l10n.runningCoachSprintCaptureReadinessPercentValue(current, target);
}

int _readinessPercent(double value) {
  return (value.clamp(0.0, 1.0).toDouble() * 100).round();
}

class _LiveInsightSection {
  final String title;
  final List<_LiveInsightData> items;

  const _LiveInsightSection({required this.title, required this.items});
}

class _ScoreExplanationPanel extends StatelessWidget {
  final String title;
  final String scoreLabel;
  final String trackedFramesLabel;
  final String speechLabel;
  final String cueText;
  final String diagnosis;
  final String actionTip;
  final RunningGaitAnalysis gaitAnalysis;
  final SprintRealtimeCoachingState sprintState;
  final SprintCaptureCalibrationProfile calibrationProfile;
  final bool profileSelectionEnabled;
  final ValueChanged<SprintCaptureCalibrationProfile>
      onCalibrationProfileChanged;
  final LiveSprintPoseEvidenceDiagnostic poseEvidenceDiagnostic;
  final LiveSprintFieldValidationMatrixSummary? fieldMatrixSummary;
  final LiveSprintCalibrationCandidateSummary? calibrationCandidateSummary;
  final List<_LiveInsightData> metricScores;
  final Map<RunningCoachMetric, int> focusPriorities;
  final List<_LiveInsightSection> metricSections;
  final bool compact;

  const _ScoreExplanationPanel({
    required this.title,
    required this.scoreLabel,
    required this.trackedFramesLabel,
    required this.speechLabel,
    required this.cueText,
    required this.diagnosis,
    required this.actionTip,
    required this.gaitAnalysis,
    required this.sprintState,
    required this.calibrationProfile,
    required this.profileSelectionEnabled,
    required this.onCalibrationProfileChanged,
    required this.poseEvidenceDiagnostic,
    required this.fieldMatrixSummary,
    required this.calibrationCandidateSummary,
    required this.metricScores,
    required this.focusPriorities,
    required this.metricSections,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
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
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (!compact) _InfoChip(text: scoreLabel),
            _InfoChip(text: trackedFramesLabel),
            _InfoChip(text: speechLabel),
          ],
        ),
        const SizedBox(height: 10),
        _GaitStatusChips(gaitAnalysis: gaitAnalysis),
        const SizedBox(height: 16),
        _PanelSectionTitle(text: l10n.runningCoachLivePoseEvidenceTitle),
        const SizedBox(height: 8),
        RunningLiveSprintCalibrationPanel(
          selectedProfile: calibrationProfile,
          profileSelectionEnabled: profileSelectionEnabled,
          onProfileChanged: onCalibrationProfileChanged,
          diagnostic: poseEvidenceDiagnostic,
          compact: compact,
        ),
        if (fieldMatrixSummary != null) ...[
          const SizedBox(height: 12),
          LiveSprintFieldValidationMatrixCard(
            summary: fieldMatrixSummary!,
            dark: true,
          ),
        ],
        if (calibrationCandidateSummary != null) ...[
          const SizedBox(height: 12),
          LiveSprintCalibrationCandidateCard(
            summary: calibrationCandidateSummary!,
            dark: true,
          ),
        ],
        const SizedBox(height: 16),
        _PanelSectionTitle(text: l10n.runningCoachLiveSprintMetricsTitle),
        const SizedBox(height: 8),
        _SprintMetricSummary(state: sprintState),
        if (cueText.isNotEmpty ||
            diagnosis.isNotEmpty ||
            actionTip.isNotEmpty) ...[
          const SizedBox(height: 16),
          _PanelSectionTitle(text: l10n.runningCoachLiveGuidanceTitle),
          const SizedBox(height: 8),
          _LiveGuidanceCard(
            cueText: cueText,
            diagnosis: diagnosis,
            actionTip: actionTip,
          ),
        ],
        if (metricScores.isNotEmpty) ...[
          const SizedBox(height: 16),
          _PanelSectionTitle(text: l10n.runningCoachMetricScoresTitle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final metricScore in metricScores)
                _CompactMetricScoreCard(
                  data: metricScore,
                  priority: focusPriorities[metricScore.insight.metric],
                ),
            ],
          ),
        ],
        if (metricSections.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (var index = 0; index < metricSections.length; index += 1) ...[
            _PanelSectionTitle(text: metricSections[index].title),
            const SizedBox(height: 8),
            for (var itemIndex = 0;
                itemIndex < metricSections[index].items.length;
                itemIndex += 1) ...[
              _LiveInsightCard(
                data: metricSections[index].items[itemIndex],
                priority: focusPriorities[
                    metricSections[index].items[itemIndex].insight.metric],
              ),
              if (itemIndex != metricSections[index].items.length - 1)
                const SizedBox(height: 10),
            ],
            if (index != metricSections.length - 1) const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }
}

@visibleForTesting
class RunningLiveSprintCalibrationPanel extends StatelessWidget {
  final SprintCaptureCalibrationProfile selectedProfile;
  final bool profileSelectionEnabled;
  final ValueChanged<SprintCaptureCalibrationProfile> onProfileChanged;
  final LiveSprintPoseEvidenceDiagnostic diagnostic;
  final bool compact;

  const RunningLiveSprintCalibrationPanel({
    super.key,
    required this.selectedProfile,
    this.profileSelectionEnabled = true,
    required this.onProfileChanged,
    required this.diagnostic,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final blockerText = _poseEvidenceBlockerCue(
      l10n,
      diagnostic.currentBlocker,
    );
    final readiness = diagnostic.readinessSummary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<SprintCaptureCalibrationProfile>(
          key: const ValueKey(
            'running-live-sprint-calibration-profile-selector',
          ),
          initialValue: selectedProfile,
          isExpanded: true,
          dropdownColor: const Color(0xFF1B2430),
          iconEnabledColor: Colors.white70,
          decoration: InputDecoration(
            labelText: l10n.runningCoachSprintCalibrationProfileLabel,
            labelStyle: textTheme.labelMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
            filled: true,
            fillColor: Colors.white.withAlpha(8),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFB8F28B)),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: compact ? 8 : 10,
            ),
          ),
          style: textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          items: [
            for (final profile in SprintCaptureCalibrationProfile.values)
              DropdownMenuItem<SprintCaptureCalibrationProfile>(
                value: profile,
                child: Text(
                  _sprintCalibrationProfileLabel(l10n, profile),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: profileSelectionEnabled
              ? (profile) {
                  if (profile != null) {
                    onProfileChanged(profile);
                  }
                }
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          _sprintCalibrationProfileDescription(l10n, selectedProfile),
          style: textTheme.bodySmall?.copyWith(
            color: Colors.white60,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(
              text: l10n.runningCoachLivePoseEvidenceProgress(
                diagnostic.capturedPhaseCount,
              ),
            ),
            if (diagnostic.eligibleFrames > 0)
              _InfoChip(
                text: l10n.runningCoachLivePoseEvidenceStableFrames(
                  diagnostic.eligibleFrames,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.runningCoachSprintCaptureReadinessTitle,
          style: textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        _SprintReadinessRow(
          icon: Icons.center_focus_strong_rounded,
          label: l10n.runningCoachSprintCaptureReadinessFraming,
          statusLabel: _readinessStatusLabel(l10n, readiness.framing.ready),
          valueText: _readinessValueText(l10n, readiness.framing),
          check: readiness.framing,
        ),
        const SizedBox(height: 8),
        _SprintReadinessRow(
          icon: Icons.switch_video_rounded,
          label: l10n.runningCoachSprintCaptureReadinessSideView,
          statusLabel: _readinessStatusLabel(l10n, readiness.sideView.ready),
          valueText: _readinessValueText(l10n, readiness.sideView),
          check: readiness.sideView,
        ),
        const SizedBox(height: 8),
        _SprintReadinessRow(
          icon: Icons.hub_outlined,
          label: l10n.runningCoachSprintCaptureReadinessCoreJoints,
          statusLabel: _readinessStatusLabel(
            l10n,
            readiness.coreJointConfidence.ready,
          ),
          valueText: _readinessValueText(
            l10n,
            readiness.coreJointConfidence,
            includeJointCount: true,
          ),
          check: readiness.coreJointConfidence,
        ),
        const SizedBox(height: 8),
        _SprintReadinessRow(
          icon: Icons.directions_run_rounded,
          label: l10n.runningCoachSprintCaptureReadinessGaitPhase,
          statusLabel: _readinessStatusLabel(l10n, readiness.gaitPhase.ready),
          valueText: _readinessValueText(l10n, readiness.gaitPhase),
          check: readiness.gaitPhase,
        ),
        const SizedBox(height: 8),
        Text(
          blockerText ??
              (diagnostic.hasCompleteEvidence
                  ? l10n.runningCoachLivePoseEvidenceReady
                  : l10n.runningCoachPoseEvidenceBlockerGaitPhase),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: blockerText == null ? Colors.white70 : Colors.amber,
                height: 1.3,
              ),
        ),
      ],
    );
  }
}

class _SprintReadinessRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String statusLabel;
  final String valueText;
  final LiveSprintCaptureReadinessCheck check;

  const _SprintReadinessRow({
    required this.icon,
    required this.label,
    required this.statusLabel,
    required this.valueText,
    required this.check,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        check.ready ? const Color(0xFFB8F28B) : const Color(0xFFFFCC80);
    final value = check.value.clamp(0.0, 1.0).toDouble();
    return Semantics(
      label: '$label. $statusLabel. $valueText',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 17),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: value,
              minHeight: 5,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 3),
            Text(
              valueText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white60,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaitStatusChips extends StatelessWidget {
  final RunningGaitAnalysis gaitAnalysis;

  const _GaitStatusChips({required this.gaitAnalysis});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InfoChip(
          text: l10n.runningCoachLiveGaitPhaseValue(
            _phaseLabel(l10n, gaitAnalysis.currentPhase),
          ),
        ),
        _InfoChip(text: _cadenceLabel(l10n, gaitAnalysis.cadence)),
        _InfoChip(
          text: _contactLabel(
            l10n,
            side: RunningFootSide.left,
            metric: gaitAnalysis.leftContactDuration,
          ),
        ),
        _InfoChip(
          text: _contactLabel(
            l10n,
            side: RunningFootSide.right,
            metric: gaitAnalysis.rightContactDuration,
          ),
        ),
      ],
    );
  }

  String _phaseLabel(AppLocalizations l10n, RunningGaitPhase phase) {
    return switch (phase) {
      RunningGaitPhase.unknown => l10n.runningCoachLiveGaitPending,
      RunningGaitPhase.flight => l10n.runningCoachLiveGaitPhaseFlight,
      RunningGaitPhase.leftContact => l10n.runningCoachLiveGaitPhaseLeftContact,
      RunningGaitPhase.rightContact =>
        l10n.runningCoachLiveGaitPhaseRightContact,
      RunningGaitPhase.doubleContact =>
        l10n.runningCoachLiveGaitPhaseDoubleContact,
    };
  }

  String _cadenceLabel(AppLocalizations l10n, RunningGaitMetric metric) {
    final value = metric.value;
    if (!metric.available || value == null) {
      return l10n.runningCoachLiveGaitCadencePending;
    }
    return l10n.runningCoachLiveGaitCadenceValue(value.round());
  }

  String _contactLabel(
    AppLocalizations l10n, {
    required RunningFootSide side,
    required RunningGaitMetric metric,
  }) {
    final sideLabel = switch (side) {
      RunningFootSide.left => l10n.runningCoachLiveGaitSideLeft,
      RunningFootSide.right => l10n.runningCoachLiveGaitSideRight,
    };
    final value = metric.value;
    if (!metric.available || value == null) {
      return l10n.runningCoachLiveGaitContactPending(sideLabel);
    }
    return l10n.runningCoachLiveGaitContactValue(sideLabel, value.round());
  }
}

class _SprintMetricSummary extends StatelessWidget {
  final SprintRealtimeCoachingState state;

  const _SprintMetricSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final features = state.features;
    final metrics = <_SprintMetricSummaryItem>[
      _SprintMetricSummaryItem(
        label: l10n.runningCoachSprintMetricTrunkLabel,
        value: features.trunkAngleDegrees == null
            ? l10n.runningCoachSprintMetricPending
            : l10n.runningCoachSprintMetricTrunkValue(
                features.trunkAngleDegrees!.toStringAsFixed(1),
              ),
      ),
      _SprintMetricSummaryItem(
        label: l10n.runningCoachSprintMetricKneeDriveLabel,
        value: features.kneeDriveHeightRatio == null
            ? l10n.runningCoachSprintMetricPending
            : l10n.runningCoachSprintMetricKneeDriveValue(
                (features.kneeDriveHeightRatio! * 100).round().toString(),
              ),
      ),
      _SprintMetricSummaryItem(
        label: l10n.runningCoachSprintMetricCadenceLabel,
        value: features.cadenceStepsPerMinute == null
            ? l10n.runningCoachSprintMetricPending
            : l10n.runningCoachSprintMetricCadenceValue(
                features.cadenceStepsPerMinute!.round().toString(),
              ),
      ),
      _SprintMetricSummaryItem(
        label: l10n.runningCoachSprintMetricRhythmLabel,
        value: features.stepIntervalStdMs == null
            ? l10n.runningCoachSprintMetricPending
            : l10n.runningCoachSprintMetricRhythmValue(
                features.stepIntervalStdMs!.round().toString(),
              ),
      ),
      _SprintMetricSummaryItem(
        label: l10n.runningCoachSprintMetricLandingLabel,
        value: features.overstrideRatio == null ||
                features.landingShinAngleDegrees == null
            ? l10n.runningCoachSprintMetricPending
            : l10n.runningCoachSprintMetricLandingValue(
                (features.overstrideRatio! * 100).round().toString(),
                features.landingShinAngleDegrees!.round().toString(),
              ),
      ),
      _SprintMetricSummaryItem(
        label: l10n.runningCoachSprintMetricFlightLabel,
        value: features.estimatedFlightRatio == null
            ? l10n.runningCoachSprintMetricPending
            : l10n.runningCoachSprintMetricFlightValue(
                (features.estimatedFlightRatio! * 100).round().toString(),
              ),
      ),
      _SprintMetricSummaryItem(
        label: l10n.runningCoachSprintMetricArmBalanceLabel,
        value: features.armSwingAsymmetryRatio == null
            ? l10n.runningCoachSprintMetricPending
            : l10n.runningCoachSprintMetricArmBalanceValue(
                (features.armSwingAsymmetryRatio! * 100).round().toString(),
              ),
      ),
      _SprintMetricSummaryItem(
        label: l10n.runningCoachSprintMetricLateFormLabel,
        value: features.lateFormDropScore == null
            ? l10n.runningCoachSprintMetricPending
            : l10n.runningCoachSprintMetricLateFormValue(
                (features.lateFormDropScore! * 100).round().toString(),
              ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(
              text: l10n.runningCoachSprintTrackingConfidenceValue(
                (state.stateEstimate.trackingConfidence * 100).round(),
              ),
            ),
            _InfoChip(
              text: l10n.runningCoachSprintTrackedFrames(state.trackedFrames),
            ),
            _InfoChip(
              text: l10n.runningCoachSprintDetectedSteps(
                features.detectedStepEvents,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final useTwoColumns = constraints.maxWidth >= 360;
            final itemWidth = useTwoColumns
                ? (constraints.maxWidth - 8) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final metric in metrics)
                  SizedBox(
                    width: itemWidth,
                    child: _SprintMetricTile(item: metric),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SprintMetricSummaryItem {
  final String label;
  final String value;

  const _SprintMetricSummaryItem({required this.label, required this.value});
}

class _SprintMetricTile extends StatelessWidget {
  final _SprintMetricSummaryItem item;

  const _SprintMetricTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white60,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 3),
            Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class _LiveGuidanceCard extends StatelessWidget {
  final String cueText;
  final String diagnosis;
  final String actionTip;

  const _LiveGuidanceCard({
    required this.cueText,
    required this.diagnosis,
    required this.actionTip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cueText.isNotEmpty) ...[
              Text(
                cueText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
              ),
            ],
            if (diagnosis.isNotEmpty) ...[
              if (cueText.isNotEmpty) const SizedBox(height: 10),
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
          ],
        ),
      ),
    );
  }
}

class _LiveInsightCard extends StatelessWidget {
  final _LiveInsightData data;
  final int? priority;

  const _LiveInsightCard({required this.data, this.priority});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            Text(
              data.copy.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (priority != null)
                  _PriorityBadge(priority: priority!, accent: accent),
                _ScoreBadge(score: data.insight.score, accent: accent),
                _ConfidenceBadge(
                  quality: data.insight.quality,
                  accent: accent,
                ),
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
            if (data.insight.quality.isLowConfidence) ...[
              const SizedBox(height: 6),
              Text(
                _runningLiveQualityReasonText(l10n, data.insight.quality),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
              ),
            ],
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

class _CompactMetricScoreCard extends StatelessWidget {
  final _LiveInsightData data;
  final int? priority;

  const _CompactMetricScoreCard({required this.data, this.priority});

  @override
  Widget build(BuildContext context) {
    final accent = switch (data.insight.status) {
      RunningCoachStatus.good => const Color(0xFF8BC34A),
      RunningCoachStatus.watch => const Color(0xFFFFB74D),
      RunningCoachStatus.needsWork => const Color(0xFFFF8A65),
    };

    return SizedBox(
      width: 148,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withAlpha(110)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.copy.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (priority != null)
                    _PriorityBadge(priority: priority!, accent: accent),
                  _ScoreBadge(score: data.insight.score, accent: accent),
                  _ConfidenceBadge(
                    quality: data.insight.quality,
                    accent: accent,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: data.insight.score / 100,
                  minHeight: 6,
                  color: accent,
                  backgroundColor: Colors.white12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.copy.value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
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

class _ConfidenceBadge extends StatelessWidget {
  final RunningMetricQuality quality;
  final Color accent;

  const _ConfidenceBadge({required this.quality, required this.accent});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLow = quality.isLowConfidence;
    final color = isLow ? const Color(0xFFFF8A65) : accent;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withAlpha(isLow ? 34 : 22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(isLow ? 120 : 70)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          l10n.runningCoachConfidenceLabel(quality.confidencePercent),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final int priority;
  final Color accent;

  const _PriorityBadge({required this.priority, required this.accent});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          l10n.runningCoachPriorityLabel(priority),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  final Color accent;

  const _ScoreBadge({required this.score, required this.accent});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          l10n.runningCoachMetricScore(score),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
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
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: 12,
            left: 12,
            child: _OverlayActionButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
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
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          body,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.white70),
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
          ),
        ],
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

class _CameraFrameInput {
  final int rotationDegrees;
  final Size detectorImageSize;

  const _CameraFrameInput({
    required this.rotationDegrees,
    required this.detectorImageSize,
  });
}
