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
    if (stateEstimate.trackingReadiness !=
        SprintTrackingReadiness.readyForAnalysis) {
      return null;
    }

    if (!stateEstimate.runningDetected) {
      return null;
    }

    final candidates = <SprintFeedbackMessage>[];

    if (features.trunkAngle.available &&
        features.trunkAngle.confidence >= config.minimumFeatureConfidence &&
        (features.trunkAngleDegrees ?? double.infinity) <
            config.minimumTrunkAngleDegrees) {
      candidates.add(
        SprintFeedbackMessage(
          code: SprintFeedbackCode.leanForwardMore,
          priority: 95,
          cueKey: 'runningCoachSprintCueLeanForward',
          diagnosisKey: 'runningCoachSprintDiagnosisLeanForward',
          actionTipKey: 'runningCoachSprintActionLeanForward',
          severity: _severityForGap(
            deficit: config.minimumTrunkAngleDegrees -
                (features.trunkAngleDegrees ?? 0),
            severeThreshold: 4,
          ),
          confidence: features.trunkAngle.confidence,
          sourceFeatures: const <String>['trunk_angle'],
          cooldownKey: 'lean_forward',
          debugLabel: '상체 전경사 부족',
        ),
      );
    }

    if (features.kneeDrive.available &&
        features.kneeDrive.confidence >= config.minimumFeatureConfidence &&
        (features.kneeDriveHeightRatio ?? double.infinity) <
            config.minimumKneeDriveHeight) {
      candidates.add(
        SprintFeedbackMessage(
          code: SprintFeedbackCode.driveKneeHigher,
          priority: 90,
          cueKey: 'runningCoachSprintCueDriveKnee',
          diagnosisKey: 'runningCoachSprintDiagnosisDriveKnee',
          actionTipKey: 'runningCoachSprintActionDriveKnee',
          severity: _severityForGap(
            deficit: config.minimumKneeDriveHeight -
                (features.kneeDriveHeightRatio ?? 0),
            severeThreshold: 0.08,
          ),
          confidence: features.kneeDrive.confidence,
          sourceFeatures: const <String>['knee_drive'],
          cooldownKey: 'drive_knee',
          debugLabel: '무릎 드라이브 부족',
        ),
      );
    }

    if (features.rhythm.available &&
        features.rhythm.confidence >= config.minimumFeatureConfidence &&
        (features.stepIntervalStdMs ?? 0) > config.maximumStepIntervalStdMs) {
      candidates.add(
        SprintFeedbackMessage(
          code: SprintFeedbackCode.keepRhythmSteady,
          priority: 84,
          cueKey: 'runningCoachSprintCueKeepRhythm',
          diagnosisKey: 'runningCoachSprintDiagnosisKeepRhythm',
          actionTipKey: 'runningCoachSprintActionKeepRhythm',
          severity: _severityForGap(
            deficit: (features.stepIntervalStdMs ?? 0) -
                config.maximumStepIntervalStdMs,
            severeThreshold: 35,
          ),
          confidence: features.rhythm.confidence,
          sourceFeatures: const <String>['rhythm_variance', 'step_events'],
          cooldownKey: 'keep_rhythm',
          debugLabel: '리듬 변동 과다',
        ),
      );
    }

    if (features.armBalance.available &&
        features.armBalance.confidence >= config.minimumFeatureConfidence &&
        (features.armSwingAsymmetryRatio ?? 0) >
            config.maximumArmAsymmetryRatio) {
      candidates.add(
        SprintFeedbackMessage(
          code: SprintFeedbackCode.balanceArmSwing,
          priority: 72,
          cueKey: 'runningCoachSprintCueBalanceArms',
          diagnosisKey: 'runningCoachSprintDiagnosisBalanceArms',
          actionTipKey: 'runningCoachSprintActionBalanceArms',
          severity: _severityForGap(
            deficit: (features.armSwingAsymmetryRatio ?? 0) -
                config.maximumArmAsymmetryRatio,
            severeThreshold: 0.1,
          ),
          confidence: features.armBalance.confidence,
          sourceFeatures: const <String>['arm_balance'],
          cooldownKey: 'balance_arms',
          debugLabel: '팔 스윙 좌우 불균형',
        ),
      );
    }

    if (candidates.isEmpty) {
      return SprintFeedbackMessage(
        code: SprintFeedbackCode.keepPushing,
        priority: 10,
        cueKey: 'runningCoachSprintCueKeepPushing',
        diagnosisKey: 'runningCoachSprintDiagnosisKeepPushing',
        actionTipKey: 'runningCoachSprintActionKeepPushing',
        severity: SprintFeedbackSeverity.info,
        confidence: _baselineConfidence(features),
        sourceFeatures: const <String>[
          'trunk_angle',
          'knee_drive',
          'rhythm_variance',
        ],
        cooldownKey: 'keep_pushing',
        debugLabel: '유지 피드백',
      );
    }

    candidates.sort((left, right) {
      final priorityCompare = right.priority.compareTo(left.priority);
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      return right.confidence.compareTo(left.confidence);
    });
    return candidates.first;
  }

  SprintFeedbackSeverity _severityForGap({
    required double deficit,
    required double severeThreshold,
  }) {
    if (deficit >= severeThreshold) {
      return SprintFeedbackSeverity.warning;
    }
    return SprintFeedbackSeverity.caution;
  }

  double _baselineConfidence(SprintFeatureSnapshot features) {
    final values = <double>[
      if (features.trunkAngle.available) features.trunkAngle.confidence,
      if (features.kneeDrive.available) features.kneeDrive.confidence,
      if (features.rhythm.available) features.rhythm.confidence,
    ];
    if (values.isEmpty) {
      return 0;
    }
    final total = values.reduce((sum, value) => sum + value);
    return total / values.length;
  }
}
