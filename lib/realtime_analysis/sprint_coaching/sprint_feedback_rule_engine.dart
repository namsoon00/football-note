import '../../domain/entities/sprint_realtime_coaching_state.dart';
import 'sprint_pipeline_config.dart';

class SprintFeedbackRuleEngine {
  const SprintFeedbackRuleEngine();

  SprintFeedbackMessage? selectFeedback({
    required SprintFeatureSnapshot features,
    required SprintStateEstimate stateEstimate,
    required SprintPipelineConfig config,
    required SprintFeedbackMessage? activeFeedback,
  }) {
    if (stateEstimate.lowConfidence || !stateEstimate.bodyFullyVisible) {
      return const SprintFeedbackMessage(
        code: SprintFeedbackCode.bodyNotVisible,
        priority: 100,
        localizationKey: 'runningCoachSprintCueBodyVisible',
        debugLabel: '몸 전체가 화면에 보이게 해주세요',
      );
    }

    if (!stateEstimate.runningDetected) {
      return null;
    }

    if ((features.trunkAngleDegrees ?? double.infinity) <
        config.minimumTrunkAngleDegrees) {
      return const SprintFeedbackMessage(
        code: SprintFeedbackCode.leanForwardMore,
        priority: 90,
        localizationKey: 'runningCoachSprintCueLeanForward',
        debugLabel: '상체를 조금 더 앞으로 유지하세요',
      );
    }

    if ((features.kneeDriveHeightRatio ?? double.infinity) <
        config.minimumKneeDriveHeightRatio) {
      return const SprintFeedbackMessage(
        code: SprintFeedbackCode.driveKneeHigher,
        priority: 80,
        localizationKey: 'runningCoachSprintCueDriveKnee',
        debugLabel: '무릎을 조금 더 강하게 들어보세요',
      );
    }

    if ((features.stepIntervalStdMs ?? 0) > config.maximumStepIntervalStdMs) {
      return const SprintFeedbackMessage(
        code: SprintFeedbackCode.keepRhythmSteady,
        priority: 70,
        localizationKey: 'runningCoachSprintCueKeepRhythm',
        debugLabel: '리듬을 일정하게 유지하세요',
      );
    }

    if ((features.armSwingAsymmetryRatio ?? 0) >
        config.maximumArmSwingAsymmetryRatio) {
      return const SprintFeedbackMessage(
        code: SprintFeedbackCode.balanceArmSwing,
        priority: 60,
        localizationKey: 'runningCoachSprintCueBalanceArms',
        debugLabel: '팔 스윙 균형을 맞춰보세요',
      );
    }

    return const SprintFeedbackMessage(
      code: SprintFeedbackCode.keepPushing,
      priority: 10,
      localizationKey: 'runningCoachSprintCueKeepPushing',
      debugLabel: '좋아요. 지금 리듬을 유지하세요',
    );
  }
}
