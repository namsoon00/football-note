import 'package:flutter/material.dart';

import '../../domain/entities/running_video_analysis_result.dart';
import 'running_coach_illustration_case.dart';

/// Presents a curated current-to-target coaching reference.
///
/// This widget deliberately does not retarget a body image from the user’s
/// coordinates. The actual video and measured overlay are shown separately as
/// evidence; this surface only explains the selected coaching change.
class RunningCoachIllustratedComparison extends StatelessWidget {
  final RunningCoachingInsight insight;
  final Color surfaceColor;
  final Color mutedColor;
  final Color actualAccent;
  final Color targetAccent;
  final Color successAccent;
  final String semanticLabel;
  final String currentLabel;
  final String nextStepLabel;

  const RunningCoachIllustratedComparison({
    super.key,
    required this.insight,
    required this.surfaceColor,
    required this.mutedColor,
    required this.actualAccent,
    required this.targetAccent,
    required this.successAccent,
    required this.semanticLabel,
    required this.currentLabel,
    required this.nextStepLabel,
  });

  @override
  Widget build(BuildContext context) {
    final illustrationCase = resolveRunningCoachIllustrationCase(insight);
    final isMaintainCase = illustrationCase.isMaintainCase;
    final currentColor = isMaintainCase ? successAccent : actualAccent;
    final targetColor = isMaintainCase ? successAccent : targetAccent;

    return Semantics(
      image: true,
      label: semanticLabel,
      child: Column(
        children: [
          if (isMaintainCase)
            _IllustrationPanelLabel(
              icon: Icons.check_circle_outline_rounded,
              color: currentColor,
              label: currentLabel,
            )
          else
            Row(
              children: [
                Expanded(
                  child: _IllustrationPanelLabel(
                    icon: Icons.radio_button_checked_rounded,
                    color: currentColor,
                    label: currentLabel,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: targetColor,
                    size: 19,
                  ),
                ),
                Expanded(
                  child: _IllustrationPanelLabel(
                    icon: Icons.near_me_outlined,
                    color: targetColor,
                    label: nextStepLabel,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _IllustrationArtwork(
              key: const ValueKey('running-coach-illustrated-comparison'),
              assetPath: isMaintainCase
                  ? illustrationCase.targetAssetPath
                  : illustrationCase.assetPath,
              surfaceColor: surfaceColor,
              mutedColor: mutedColor,
              emphasis: illustrationCase.severity,
            ),
          ),
        ],
      ),
    );
  }
}

class _IllustrationPanelLabel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool alignEnd;

  const _IllustrationPanelLabel({
    required this.icon,
    required this.color,
    required this.label,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = <Widget>[
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    ];
    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: alignEnd ? content.reversed.toList(growable: false) : content,
    );
  }
}

class _IllustrationArtwork extends StatelessWidget {
  final String assetPath;
  final Color surfaceColor;
  final Color mutedColor;
  final RunningCoachIllustrationSeverity emphasis;

  const _IllustrationArtwork({
    super.key,
    required this.assetPath,
    required this.surfaceColor,
    required this.mutedColor,
    required this.emphasis,
  });

  @override
  Widget build(BuildContext context) {
    final borderWidth = emphasis.needsPronouncedReference ? 1.4 : 1.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: mutedColor.withValues(alpha: 0.28),
          width: borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: mutedColor,
            ),
          ),
        ),
      ),
    );
  }
}
