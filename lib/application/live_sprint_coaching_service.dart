import '../domain/entities/running_live_coaching_state.dart';
import '../domain/entities/sprint_pose_frame.dart';
import '../domain/entities/sprint_realtime_coaching_state.dart';
import '../realtime_analysis/sprint_coaching/sprint_pipeline_config.dart';
import 'mediapipe_pose_landmarker_service.dart';
import 'running_live_coaching_service.dart';
import 'sprint_live_coaching_service.dart';

class LiveSprintCoachingSnapshot {
  final RunningLiveCoachingState runningState;
  final SprintRealtimeCoachingState sprintState;
  final SprintPoseFrame? sprintPoseFrame;
  final bool sprintAnalysisUpdated;

  const LiveSprintCoachingSnapshot({
    required this.runningState,
    required this.sprintState,
    required this.sprintPoseFrame,
    required this.sprintAnalysisUpdated,
  });
}

/// Fans one MediaPipe detection out to the running and sprint evaluators.
class LiveSprintCoachingService {
  final RunningLiveCoachingService _runningService;
  final SprintLiveCoachingService _sprintService;
  final SprintPipelineConfig _sprintConfig;

  SprintRealtimeCoachingState _latestSprintState =
      const SprintRealtimeCoachingState.initial();
  DateTime? _lastSprintAnalysisAt;

  LiveSprintCoachingService({
    RunningLiveCoachingService? runningService,
    SprintLiveCoachingService? sprintService,
    SprintPipelineConfig sprintConfig = const SprintPipelineConfig(),
  })  : _runningService = runningService ?? RunningLiveCoachingService(),
        _sprintService =
            sprintService ?? SprintLiveCoachingService(config: sprintConfig),
        _sprintConfig = sprintConfig;

  void reset() {
    _runningService.reset();
    _sprintService.reset();
    _latestSprintState = const SprintRealtimeCoachingState.initial();
    _lastSprintAnalysisAt = null;
  }

  LiveSprintCoachingSnapshot ingestDetection(
    MediaPipePoseDetection detection, {
    required DateTime timestamp,
  }) {
    final shouldUpdateSprint = _lastSprintAnalysisAt == null ||
        timestamp.difference(_lastSprintAnalysisAt!) >=
            _sprintConfig.minimumAnalysisInterval;
    final sprintPoseFrame = shouldUpdateSprint
        ? sprintPoseFrameFromMediaPipeDetection(
            detection,
            timestamp: timestamp,
          )
        : null;
    if (shouldUpdateSprint) {
      _latestSprintState = _sprintService.ingestPoseFrame(
        sprintPoseFrame,
        timestamp: timestamp,
      );
      _lastSprintAnalysisAt = timestamp;
    }

    return LiveSprintCoachingSnapshot(
      runningState: _runningService.ingestObservation(
        runningPoseObservationFromMediaPipeDetection(detection),
        timestamp: timestamp,
      ),
      sprintState: _latestSprintState,
      sprintPoseFrame: sprintPoseFrame,
      sprintAnalysisUpdated: shouldUpdateSprint,
    );
  }
}

SprintPoseFrame? sprintPoseFrameFromMediaPipeDetection(
  MediaPipePoseDetection detection, {
  required DateTime timestamp,
}) {
  if (detection.imageSize.isEmpty || detection.landmarks.isEmpty) {
    return null;
  }

  final landmarks = <SprintPoseLandmarkType, SprintPoseLandmark>{};
  for (final landmark in detection.landmarks) {
    final type = sprintPoseLandmarkTypeForMediaPipeIndex(landmark.index);
    if (type == null) {
      continue;
    }
    final world = landmark.worldLandmark;
    landmarks[type] = SprintPoseLandmark(
      position: landmark.position,
      confidence: landmark.confidence,
      worldLandmark: world == null
          ? null
          : SprintPoseWorldLandmark(
              x: world.x,
              y: world.y,
              z: world.z,
              visibility: world.visibility,
            ),
    );
  }

  if (landmarks.isEmpty) {
    return null;
  }
  return SprintPoseFrame(
    imageSize: detection.imageSize,
    timestamp: timestamp,
    landmarks: landmarks,
  );
}

SprintPoseLandmarkType? sprintPoseLandmarkTypeForMediaPipeIndex(int index) {
  return switch (index) {
    0 => SprintPoseLandmarkType.nose,
    7 => SprintPoseLandmarkType.leftEar,
    8 => SprintPoseLandmarkType.rightEar,
    11 => SprintPoseLandmarkType.leftShoulder,
    12 => SprintPoseLandmarkType.rightShoulder,
    13 => SprintPoseLandmarkType.leftElbow,
    14 => SprintPoseLandmarkType.rightElbow,
    15 => SprintPoseLandmarkType.leftWrist,
    16 => SprintPoseLandmarkType.rightWrist,
    23 => SprintPoseLandmarkType.leftHip,
    24 => SprintPoseLandmarkType.rightHip,
    25 => SprintPoseLandmarkType.leftKnee,
    26 => SprintPoseLandmarkType.rightKnee,
    27 => SprintPoseLandmarkType.leftAnkle,
    28 => SprintPoseLandmarkType.rightAnkle,
    29 => SprintPoseLandmarkType.leftHeel,
    30 => SprintPoseLandmarkType.rightHeel,
    31 => SprintPoseLandmarkType.leftFootIndex,
    32 => SprintPoseLandmarkType.rightFootIndex,
    _ => null,
  };
}
