import '../domain/entities/sprint_pose_frame.dart';
import '../domain/entities/sprint_realtime_coaching_state.dart';
import '../realtime_analysis/sprint_coaching/sprint_pipeline_config.dart';
import '../realtime_analysis/sprint_coaching/sprint_realtime_coaching_pipeline.dart';

class SprintLiveCoachingService {
  final SprintRealtimeCoachingPipeline _pipeline;

  SprintLiveCoachingService({
    SprintRealtimeCoachingPipeline? pipeline,
    SprintPipelineConfig config = const SprintPipelineConfig(),
  }) : _pipeline = pipeline ?? SprintRealtimeCoachingPipeline(config: config);

  void reset() => _pipeline.reset();

  SprintRealtimeCoachingState ingestPoseFrame(
    SprintPoseFrame? frame, {
    DateTime? timestamp,
  }) {
    return _pipeline.ingest(frame, timestamp: timestamp);
  }
}
