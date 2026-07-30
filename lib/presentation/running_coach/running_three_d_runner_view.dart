import 'package:flutter/material.dart';

import '../../domain/entities/running_video_analysis_result.dart';
import '../../gen/app_localizations.dart';
import 'running_three_d_runner.dart';
import 'running_three_d_runner_view_stub.dart'
    if (dart.library.js_interop) 'running_three_d_runner_view_web.dart'
    if (dart.library.io) 'running_three_d_runner_view_io.dart';

class RunningThreeDRunnerComparisonView extends StatelessWidget {
  final Iterable<RunningPoseFrame> poseFrames;
  final RunningPoseFrame selectedFrame;
  final RunningCoachingInsight insight;
  final RunningDirection direction;
  final Color currentColor;
  final Color targetColor;
  final Color successColor;
  final String currentLabel;
  final String targetLabel;
  final double? playbackProgress;

  const RunningThreeDRunnerComparisonView({
    super.key,
    required this.poseFrames,
    required this.selectedFrame,
    required this.insight,
    required this.direction,
    required this.currentColor,
    required this.targetColor,
    required this.successColor,
    required this.currentLabel,
    required this.targetLabel,
    this.playbackProgress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final payload =
        const RunningThreeDRunnerRetargeter().buildComparisonPayload(
      poseFrames: poseFrames,
      selectedFrame: selectedFrame,
      insight: insight,
      direction: direction,
      currentLabel: currentLabel,
      targetLabel: targetLabel,
      confidenceLabel: l10n.runningCoachThreeDConfidenceLabel,
      loadingLabel: l10n.runningCoachThreeDRendererLoading,
      errorLabel: l10n.runningCoachThreeDRendererError,
      referenceNotice: l10n.runningCoachThreeDReferenceNotice,
      currentColor: _hexColor(currentColor),
      targetColor: _hexColor(targetColor),
      successColor: _hexColor(successColor),
      playbackProgress: playbackProgress,
    );
    final frames = payload.data['frames'];
    if (frames is! List || frames.isEmpty) {
      return RunningThreeDRunnerUnavailablePanel(
        message: l10n.runningCoachThreeDRendererUnavailable,
      );
    }
    return RunningThreeDRunnerPlatformView(
      key: const ValueKey('running-coach-3d-runner-platform-view'),
      payloadJson: payload.toJson(),
      loadingLabel: l10n.runningCoachThreeDRendererLoading,
      unavailableLabel: l10n.runningCoachThreeDRendererUnavailable,
    );
  }
}

class RunningThreeDRunnerUnavailablePanel extends StatelessWidget {
  final String message;

  const RunningThreeDRunnerUnavailablePanel({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: const ValueKey('running-coach-3d-runner-unavailable'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.view_in_ar_outlined,
                color: scheme.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _hexColor(Color color) {
  final value = color.toARGB32() & 0x00FFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0')}';
}
