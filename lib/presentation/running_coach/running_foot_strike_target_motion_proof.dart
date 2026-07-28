import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/running_video_analysis_result.dart';
import '../../gen/app_localizations.dart';
import 'running_pose_overlay.dart';

/// Shows the single next action after the coordinate-driven comparison.
///
/// The compact rail below the comparison only explains the landing direction;
/// the body rig above is the surface that uses measured joint coordinates.
class RunningFootStrikeTargetMotionProof extends StatefulWidget {
  final RunningCoachingInsight insight;
  final RunningDirection direction;
  final String currentValue;
  final String cue;

  const RunningFootStrikeTargetMotionProof({
    super.key,
    required this.insight,
    required this.direction,
    required this.currentValue,
    required this.cue,
  });

  @override
  State<RunningFootStrikeTargetMotionProof> createState() =>
      _RunningFootStrikeTargetMotionProofState();
}

class _RunningFootStrikeTargetMotionProofState
    extends State<RunningFootStrikeTargetMotionProof>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motionController;
  bool _isMotionPlaying = true;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  void _toggleMotion() {
    setState(() {
      _isMotionPlaying = !_isMotionPlaying;
      if (_isMotionPlaying) {
        _motionController.repeat(reverse: true);
      } else {
        _motionController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final actualAccent = scheme.error;
    final targetAccent = scheme.primary;
    final title = l10n.runningCoachEvidenceTransitionTitle;
    return Semantics(
      container: true,
      label: title,
      child: DecoratedBox(
        key: const ValueKey('running-coach-evidence-pose-transition'),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.straighten_rounded,
                    size: 19,
                    color: targetAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('running-coach-goal-motion-toggle'),
                    tooltip: _isMotionPlaying
                        ? l10n.runningCoachGoalMotionPause
                        : l10n.runningCoachGoalMotionPlay,
                    onPressed: _toggleMotion,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      _isMotionPlaying
                          ? Icons.pause_circle_outline_rounded
                          : Icons.play_circle_outline_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _motionController,
                builder: (context, _) {
                  return _FootStrikeDirectionPanel(
                    currentValue: widget.currentValue,
                    cue: widget.cue,
                    status: widget.insight.status,
                    direction: widget.direction,
                    progress: _motionController.value,
                    actualAccent: actualAccent,
                    targetAccent: targetAccent,
                    mutedColor: scheme.onSurfaceVariant,
                    currentLabel: l10n.runningCoachEvidenceCurrentLabel,
                    targetLabel: l10n.runningCoachEvidenceNextLabel,
                  );
                },
              ),
              const SizedBox(height: 9),
              Text(
                l10n.runningCoachGoalMotionFootnote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a coordinate-driven running rig while retaining the original video
/// evidence and its measurement overlay.
class RunningFootStrikeEvidenceReferencePreview extends StatelessWidget {
  final Widget evidence;
  final RunningDirection direction;
  final RunningPoseFrame? currentPose;

  const RunningFootStrikeEvidenceReferencePreview({
    super.key,
    required this.evidence,
    required this.direction,
    required this.currentPose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;
        final comparisonHeight = isNarrow ? 236.0 : 256.0;
        final overlayHeight = isNarrow ? 166.0 : 188.0;
        return Column(
          key: const ValueKey('running-coach-goal-motion'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.compare_arrows_rounded,
                  color: scheme.primary,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.runningCoachTwoDComparisonTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              key: const ValueKey(
                'running-coach-foot-strike-rendered-comparison',
              ),
              height: comparisonHeight,
              width: double.infinity,
              child: _FootStrikeCoordinateRigComparison(
                key: const ValueKey(
                  'running-coach-foot-strike-reference-runner',
                ),
                poseFrame: currentPose,
                direction: direction,
                currentLabel: l10n.runningCoachTwoDCurrentLabel,
                targetLabel: l10n.runningCoachTwoDTargetLabel,
                unavailableLabel: l10n.runningCoachCoordinateRigUnavailable,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.videocam_outlined,
                  color: scheme.tertiary,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.runningCoachTwoDVideoOverlayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              key: const ValueKey('running-coach-analysis-evidence-preview'),
              height: overlayHeight,
              width: double.infinity,
              child: DecoratedBox(
                key: const ValueKey(
                  'running-coach-foot-strike-uploaded-overlay',
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: evidence,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FootStrikeCoordinateRigComparison extends StatelessWidget {
  final RunningPoseFrame? poseFrame;
  final RunningDirection direction;
  final String currentLabel;
  final String targetLabel;
  final String unavailableLabel;

  const _FootStrikeCoordinateRigComparison({
    super.key,
    required this.poseFrame,
    required this.direction,
    required this.currentLabel,
    required this.targetLabel,
    required this.unavailableLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rig = _FootStrikeCoordinateRig.fromPoseFrame(
      poseFrame,
      direction: direction,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: rig == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_off_outlined,
                        color: scheme.onSurfaceVariant,
                        size: 26,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        unavailableLabel,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _FootStrikeCoordinateRigCaption(
                            icon: Icons.person_search_outlined,
                            color: scheme.error,
                            label: currentLabel,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 22,
                          color: scheme.outlineVariant,
                        ),
                        Expanded(
                          child: _FootStrikeCoordinateRigCaption(
                            icon: Icons.track_changes_rounded,
                            color: scheme.primary,
                            label: targetLabel,
                            alignEnd: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Expanded(
                      child: RepaintBoundary(
                        child: SizedBox.expand(
                          child: CustomPaint(
                            key: const ValueKey(
                              'running-coach-foot-strike-coordinate-rig',
                            ),
                            painter: _FootStrikeCoordinateRigPainter(
                              rig: rig,
                              currentAccent: scheme.error,
                              targetAccent: scheme.primary,
                              mutedColor: scheme.onSurfaceVariant,
                              panelColor: scheme.surface,
                              panelBorderColor: scheme.outlineVariant,
                            ),
                          ),
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

class _FootStrikeCoordinateRigCaption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool alignEnd;

  const _FootStrikeCoordinateRigCaption({
    required this.icon,
    required this.color,
    required this.label,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = <Widget>[
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
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

class _FootStrikeDirectionPanel extends StatelessWidget {
  final String currentValue;
  final String cue;
  final RunningCoachStatus status;
  final RunningDirection direction;
  final double progress;
  final Color actualAccent;
  final Color targetAccent;
  final Color mutedColor;
  final String currentLabel;
  final String targetLabel;

  const _FootStrikeDirectionPanel({
    required this.currentValue,
    required this.cue,
    required this.status,
    required this.direction,
    required this.progress,
    required this.actualAccent,
    required this.targetAccent,
    required this.mutedColor,
    required this.currentLabel,
    required this.targetLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: const ValueKey('running-coach-foot-strike-current-target'),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _FootStrikeDirectionLabel(
                  icon: Icons.radio_button_checked_rounded,
                  color: actualAccent,
                  label: currentLabel,
                ),
                const Spacer(),
                _FootStrikeDirectionLabel(
                  icon: Icons.track_changes_rounded,
                  color: targetAccent,
                  label: targetLabel,
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: CustomPaint(
                painter: _FootStrikeDirectionPainter(
                  status: status,
                  direction: direction,
                  progress: progress,
                  actualAccent: actualAccent,
                  targetAccent: targetAccent,
                  mutedColor: mutedColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currentValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: actualAccent,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              cue,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FootStrikeDirectionLabel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _FootStrikeDirectionLabel({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

/// A small 2D rig derived from one analyzed MediaPipe pose frame.
///
/// The target keeps every measured point except the lead leg. Only that leg
/// is repositioned to a controlled landing zone beneath the hip, so the UI
/// never presents a full-body reconstruction or an unmeasured gait phase.
class _FootStrikeCoordinateRig {
  static const _capturedIndices = <int>{
    0,
    7,
    8,
    11,
    12,
    13,
    14,
    15,
    16,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
    31,
    32,
  };

  static const _requiredCoreIndices = <int>{
    11,
    12,
    23,
    24,
    25,
    26,
    27,
    28,
  };

  final Map<int, Offset> currentPoints;
  final Map<int, Offset> targetPoints;
  final int leadHipIndex;
  final int leadKneeIndex;
  final int leadAnkleIndex;
  final int leadHeelIndex;
  final int leadToeIndex;

  const _FootStrikeCoordinateRig({
    required this.currentPoints,
    required this.targetPoints,
    required this.leadHipIndex,
    required this.leadKneeIndex,
    required this.leadAnkleIndex,
    required this.leadHeelIndex,
    required this.leadToeIndex,
  });

  static _FootStrikeCoordinateRig? fromPoseFrame(
    RunningPoseFrame? poseFrame, {
    required RunningDirection direction,
  }) {
    if (poseFrame == null) return null;
    final points = <int, Offset>{};
    for (final index in _capturedIndices) {
      final landmark = poseFrame.landmarkByIndex(index);
      if (landmark == null ||
          landmark.confidence < runningPoseOverlayMinimumJointConfidence ||
          !landmark.x.isFinite ||
          !landmark.y.isFinite) {
        continue;
      }
      points[index] = Offset(landmark.x, landmark.y);
    }
    final hasHead =
        points.containsKey(0) || points.containsKey(7) || points.containsKey(8);
    if (!hasHead || !_requiredCoreIndices.every(points.containsKey)) {
      return null;
    }

    final hipCenter = _midpoint(points[23]!, points[24]!);
    final leftFoot = points[31] ?? points[27]!;
    final rightFoot = points[32] ?? points[28]!;
    final forward = _forwardSign(
      direction,
      hipCenter: hipCenter,
      leftFoot: leftFoot,
      rightFoot: rightFoot,
    );
    final leftProgress = (leftFoot.dx - hipCenter.dx) * forward;
    final rightProgress = (rightFoot.dx - hipCenter.dx) * forward;
    final leadIsLeft = leftProgress >= rightProgress;
    final leadHipIndex = leadIsLeft ? 23 : 24;
    final leadKneeIndex = leadIsLeft ? 25 : 26;
    final leadAnkleIndex = leadIsLeft ? 27 : 28;
    final leadHeelIndex = leadIsLeft ? 29 : 30;
    final leadToeIndex = leadIsLeft ? 31 : 32;

    final leadHip = points[leadHipIndex]!;
    final leadKnee = points[leadKneeIndex]!;
    final leadAnkle = points[leadAnkleIndex]!;
    final trailingHip = points[leadIsLeft ? 24 : 23]!;
    final trailingKnee = points[leadIsLeft ? 26 : 25]!;
    final trailingAnkle = points[leadIsLeft ? 28 : 27]!;
    final leadLegLength =
        (leadHip - leadKnee).distance + (leadKnee - leadAnkle).distance;
    final trailingLegLength = (trailingHip - trailingKnee).distance +
        (trailingKnee - trailingAnkle).distance;
    final legLength =
        ((leadLegLength + trailingLegLength) / 2).clamp(0.08, 1.4).toDouble();
    final leadToe = points[leadToeIndex];
    final leadHeel = points[leadHeelIndex];
    final contactY = <double>[
      leadAnkle.dy,
      if (leadToe != null) leadToe.dy,
      if (leadHeel != null) leadHeel.dy,
    ].reduce(math.max);

    final targetPoints = Map<int, Offset>.from(points);
    final targetAnkle = Offset(
      hipCenter.dx + forward * legLength * 0.012,
      contactY - legLength * 0.024,
    );
    final targetKnee = Offset.lerp(leadHip, targetAnkle, 0.53)! +
        Offset(forward * legLength * 0.105, -legLength * 0.012);
    final targetToe =
        targetAnkle + Offset(forward * legLength * 0.145, legLength * 0.022);
    final targetHeel =
        targetAnkle + Offset(-forward * legLength * 0.078, legLength * 0.018);
    targetPoints[leadKneeIndex] = targetKnee;
    targetPoints[leadAnkleIndex] = targetAnkle;
    targetPoints[leadHeelIndex] = targetHeel;
    targetPoints[leadToeIndex] = targetToe;

    return _FootStrikeCoordinateRig(
      currentPoints: Map<int, Offset>.unmodifiable(points),
      targetPoints: Map<int, Offset>.unmodifiable(targetPoints),
      leadHipIndex: leadHipIndex,
      leadKneeIndex: leadKneeIndex,
      leadAnkleIndex: leadAnkleIndex,
      leadHeelIndex: leadHeelIndex,
      leadToeIndex: leadToeIndex,
    );
  }

  static Offset _midpoint(Offset first, Offset second) {
    return Offset((first.dx + second.dx) / 2, (first.dy + second.dy) / 2);
  }

  static double _forwardSign(
    RunningDirection direction, {
    required Offset hipCenter,
    required Offset leftFoot,
    required Offset rightFoot,
  }) {
    return switch (direction) {
      RunningDirection.leftToRight => 1,
      RunningDirection.rightToLeft => -1,
      RunningDirection.stationary =>
        ((leftFoot.dx + rightFoot.dx) / 2) >= hipCenter.dx ? 1 : -1,
    };
  }
}

class _FootStrikeCoordinateRigPainter extends CustomPainter {
  final _FootStrikeCoordinateRig rig;
  final Color currentAccent;
  final Color targetAccent;
  final Color mutedColor;
  final Color panelColor;
  final Color panelBorderColor;

  const _FootStrikeCoordinateRigPainter({
    required this.rig,
    required this.currentAccent,
    required this.targetAccent,
    required this.mutedColor,
    required this.panelColor,
    required this.panelBorderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final gap = (size.width * 0.042).clamp(7.0, 13.0).toDouble();
    final panelWidth = math.max(1.0, (size.width - gap) / 2);
    final currentPanel = Rect.fromLTWH(0, 0, panelWidth, size.height);
    final targetPanel = Rect.fromLTWH(
      panelWidth + gap,
      0,
      panelWidth,
      size.height,
    );
    final bounds = _poseBounds(rig.currentPoints, rig.targetPoints);
    final current = _projectPose(rig.currentPoints, currentPanel, bounds);
    final target = _projectPose(rig.targetPoints, targetPanel, bounds);
    final currentGhostInTarget =
        _projectPose(rig.currentPoints, targetPanel, bounds);

    _drawPanelSurface(canvas, currentPanel);
    _drawPanelSurface(canvas, targetPanel);
    _drawRunner(
      canvas,
      currentPanel,
      current,
      accent: currentAccent,
      isTarget: false,
    );
    _drawTargetMotionTrail(canvas, currentGhostInTarget, target);
    _drawRunner(
      canvas,
      targetPanel,
      target,
      accent: targetAccent,
      isTarget: true,
    );
  }

  Rect _poseBounds(
    Map<int, Offset> current,
    Map<int, Offset> target,
  ) {
    final all = <Offset>[...current.values, ...target.values];
    var minX = all.first.dx;
    var maxX = all.first.dx;
    var minY = all.first.dy;
    var maxY = all.first.dy;
    for (final point in all.skip(1)) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }
    final width = math.max(maxX - minX, 0.14);
    final height = math.max(maxY - minY, 0.20);
    final horizontalPadding = math.max(width * 0.20, 0.045);
    final verticalPadding = math.max(height * 0.10, 0.035);
    return Rect.fromLTRB(
      minX - horizontalPadding,
      minY - verticalPadding,
      maxX + horizontalPadding,
      maxY + verticalPadding,
    );
  }

  Map<int, Offset> _projectPose(
    Map<int, Offset> source,
    Rect panel,
    Rect bounds,
  ) {
    final content = Rect.fromLTWH(
      panel.left + panel.width * 0.055,
      panel.top + panel.height * 0.025,
      panel.width * 0.89,
      panel.height * 0.91,
    );
    final scale = math.min(
      content.width / math.max(bounds.width, 0.01),
      content.height / math.max(bounds.height, 0.01),
    );
    final displayWidth = bounds.width * scale;
    final displayHeight = bounds.height * scale;
    final origin = Offset(
      content.left + (content.width - displayWidth) / 2 - bounds.left * scale,
      content.top + (content.height - displayHeight) / 2 - bounds.top * scale,
    );
    return <int, Offset>{
      for (final entry in source.entries)
        entry.key: origin + entry.value * scale,
    };
  }

  void _drawPanelSurface(Canvas canvas, Rect panel) {
    final panelShape = RRect.fromRectAndRadius(panel, const Radius.circular(6));
    canvas.drawRRect(
      panelShape,
      Paint()..color = panelColor.withValues(alpha: 0.40),
    );
    canvas.drawRRect(
      panelShape,
      Paint()
        ..color = panelBorderColor.withValues(alpha: 0.56)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    for (final fraction in const <double>[0.24, 0.49, 0.74]) {
      final y = panel.top + panel.height * fraction;
      canvas.drawLine(
        Offset(panel.left + panel.width * 0.10, y),
        Offset(panel.right - panel.width * 0.10, y),
        Paint()
          ..color = mutedColor.withValues(alpha: 0.10)
          ..strokeWidth = 0.8,
      );
    }
  }

  void _drawRunner(
    Canvas canvas,
    Rect panel,
    Map<int, Offset> points, {
    required Color accent,
    required bool isTarget,
  }) {
    final groundY = _groundY(points, panel);
    final hip = _midpoint(points[23], points[24]);
    final foot = points[rig.leadToeIndex] ?? points[rig.leadAnkleIndex];
    if (hip == null || foot == null) return;
    _drawLandingGuide(
      canvas,
      panel,
      hip: hip,
      foot: foot,
      groundY: groundY,
      isTarget: isTarget,
    );
    final kitAccent = Color.lerp(accent, const Color(0xFF53637A), 0.38)!;
    final kitSecondary = Color.lerp(
      accent,
      const Color(0xFFE9F0FA),
      0.42,
    )!;
    final jointColor = Color.lerp(panelColor, const Color(0xFFF4F7FE), 0.88)!;
    paintRunningPoseHumanForm(
      canvas,
      points: points,
      canvasSize: panel.size,
      focusIndices: <int>{
        rig.leadHipIndex,
        rig.leadKneeIndex,
        rig.leadAnkleIndex,
        rig.leadHeelIndex,
        rig.leadToeIndex,
      },
      style: runningPoseStudioRunnerStyle(
        accentColor: kitAccent,
        secondaryAccent: kitSecondary,
        focusColor: accent,
        jointColor: jointColor,
        volumeScale: 1.18,
        opacity: 0.98,
      ),
    );
  }

  void _drawLandingGuide(
    Canvas canvas,
    Rect panel, {
    required Offset hip,
    required Offset foot,
    required double groundY,
    required bool isTarget,
  }) {
    final zoneHeight = math.max(7.0, panel.height * 0.052);
    final targetCenter = Offset(hip.dx, groundY);
    final zone = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: targetCenter,
        width: math.max(24.0, panel.width * 0.38),
        height: zoneHeight,
      ),
      Radius.circular(zoneHeight / 2),
    );
    canvas.drawLine(
      Offset(panel.left + panel.width * 0.08, groundY),
      Offset(panel.right - panel.width * 0.08, groundY),
      Paint()
        ..color = mutedColor.withValues(alpha: 0.48)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );
    _drawDashedLine(
      canvas,
      hip,
      Offset(hip.dx, groundY - zoneHeight * 0.62),
      Paint()
        ..color = targetAccent.withValues(alpha: 0.50)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRRect(
      zone,
      Paint()..color = targetAccent.withValues(alpha: 0.12),
    );
    canvas.drawRRect(
      zone,
      Paint()
        ..color = targetAccent.withValues(alpha: 0.82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    if (isTarget) {
      canvas.drawCircle(
        targetCenter,
        math.max(2.7, panel.shortestSide * 0.025),
        Paint()..color = targetAccent,
      );
      return;
    }
    _drawArrow(
      canvas,
      Offset(foot.dx, groundY - zoneHeight * 1.35),
      Offset(targetCenter.dx, groundY - zoneHeight * 1.35),
      Paint()
        ..color = targetAccent.withValues(alpha: 0.74)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(foot.dx, groundY),
      math.max(2.7, panel.shortestSide * 0.025),
      Paint()..color = currentAccent,
    );
  }

  void _drawTargetMotionTrail(
    Canvas canvas,
    Map<int, Offset> current,
    Map<int, Offset> target,
  ) {
    final currentKnee = current[rig.leadKneeIndex];
    final currentAnkle = current[rig.leadAnkleIndex];
    final targetKnee = target[rig.leadKneeIndex];
    final targetAnkle = target[rig.leadAnkleIndex];
    if (currentKnee == null ||
        currentAnkle == null ||
        targetKnee == null ||
        targetAnkle == null) {
      return;
    }
    final trailPaint = Paint()
      ..color = targetAccent.withValues(alpha: 0.38)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    _drawDashedLine(canvas, currentKnee, targetKnee, trailPaint);
    _drawDashedLine(canvas, currentAnkle, targetAnkle, trailPaint);
    canvas.drawCircle(
      currentAnkle,
      3.0,
      Paint()
        ..color = currentAccent.withValues(alpha: 0.44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  Offset? _midpoint(Offset? first, Offset? second) {
    if (first == null || second == null) return null;
    return Offset((first.dx + second.dx) / 2, (first.dy + second.dy) / 2);
  }

  double _groundY(Map<int, Offset> points, Rect panel) {
    final contacts = <Offset>[
      if (points[31] case final Offset point) point,
      if (points[32] case final Offset point) point,
      if (points[27] case final Offset point) point,
      if (points[28] case final Offset point) point,
    ];
    final lowest = contacts.isEmpty
        ? panel.top + panel.height * 0.84
        : contacts.map((point) => point.dy).reduce(math.max);
    return lowest
        .clamp(
          panel.top + panel.height * 0.62,
          panel.bottom - panel.height * 0.05,
        )
        .toDouble();
  }

  @override
  bool shouldRepaint(covariant _FootStrikeCoordinateRigPainter oldDelegate) {
    return oldDelegate.rig != rig ||
        oldDelegate.currentAccent != currentAccent ||
        oldDelegate.targetAccent != targetAccent ||
        oldDelegate.mutedColor != mutedColor ||
        oldDelegate.panelColor != panelColor ||
        oldDelegate.panelBorderColor != panelBorderColor;
  }
}

class _FootStrikeDirectionPainter extends CustomPainter {
  final RunningCoachStatus status;
  final RunningDirection direction;
  final double progress;
  final Color actualAccent;
  final Color targetAccent;
  final Color mutedColor;

  const _FootStrikeDirectionPainter({
    required this.status,
    required this.direction,
    required this.progress,
    required this.actualAccent,
    required this.targetAccent,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final forward = direction == RunningDirection.rightToLeft ? -1.0 : 1.0;
    final groundY = size.height * 0.72;
    final hipX = size.width * 0.5;
    final targetX = hipX + forward * size.width * 0.035;
    final distance = switch (status) {
      RunningCoachStatus.good => size.width * 0.035,
      RunningCoachStatus.watch => size.width * 0.15,
      RunningCoachStatus.needsWork => size.width * 0.27,
    };
    final currentX = targetX + forward * distance;
    final eased = Curves.easeInOutCubic.transform(progress);
    final movingX = currentX + (targetX - currentX) * eased;
    final targetZone = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(targetX, groundY),
        width: math.max(28.0, size.width * 0.15),
        height: math.max(9.0, size.height * 0.20),
      ),
      const Radius.circular(12),
    );
    canvas.drawLine(
      Offset(size.width * 0.06, groundY),
      Offset(size.width * 0.94, groundY),
      Paint()
        ..color = mutedColor.withValues(alpha: 0.42)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    _drawDashedLine(
      canvas,
      Offset(hipX, size.height * 0.08),
      Offset(hipX, groundY),
      Paint()
        ..color = mutedColor.withValues(alpha: 0.66)
        ..strokeWidth = 1.1,
    );
    canvas.drawRRect(
      targetZone,
      Paint()..color = targetAccent.withValues(alpha: 0.18),
    );
    canvas.drawRRect(
      targetZone,
      Paint()
        ..color = targetAccent.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    _drawArrow(
      canvas,
      Offset(currentX, groundY - 8),
      Offset(targetX, groundY - 8),
      Paint()
        ..color = targetAccent.withValues(alpha: 0.64)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(currentX, groundY),
      math.max(3.5, size.height * 0.095),
      Paint()..color = actualAccent.withValues(alpha: 0.90),
    );
    canvas.drawCircle(
      Offset(movingX, groundY),
      math.max(3.2, size.height * 0.078),
      Paint()..color = targetAccent,
    );
  }

  @override
  bool shouldRepaint(covariant _FootStrikeDirectionPainter oldDelegate) {
    return oldDelegate.status != status ||
        oldDelegate.direction != direction ||
        oldDelegate.progress != progress ||
        oldDelegate.actualAccent != actualAccent ||
        oldDelegate.targetAccent != targetAccent ||
        oldDelegate.mutedColor != mutedColor;
  }
}

void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
  final vector = to - from;
  final distance = vector.distance;
  if (distance <= 0) return;
  final unit = vector / distance;
  const dash = 5.0;
  const gap = 4.0;
  for (var offset = 0.0; offset < distance; offset += dash + gap) {
    canvas.drawLine(
      from + unit * offset,
      from + unit * math.min(offset + dash, distance),
      paint,
    );
  }
}

void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
  final vector = to - from;
  final distance = vector.distance;
  if (distance <= 0) return;
  final unit = vector / distance;
  final perpendicular = Offset(-unit.dy, unit.dx);
  final head = math.max(4.0, paint.strokeWidth * 3.2);
  canvas.drawLine(from, to, paint);
  canvas.drawLine(to, to - unit * head + perpendicular * (head * 0.5), paint);
  canvas.drawLine(to, to - unit * head - perpendicular * (head * 0.5), paint);
}
