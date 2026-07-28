import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/running_video_analysis_result.dart';
import '../../gen/app_localizations.dart';
import 'running_pose_overlay.dart';

/// Shows the single next action after the user's video frame is compared with
/// a fixed, clearly labelled target runner.
///
/// Keeping the reference runner separate avoids pretending that sparse pose
/// landmarks can reconstruct the runner in the user's video.
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

/// Shows a high-fidelity target runner while retaining the original video
/// evidence and its measurement overlay.
class RunningFootStrikeEvidenceReferencePreview extends StatelessWidget {
  final Widget evidence;
  final RunningDirection direction;
  final RunningPoseFrame? currentPose;
  final RunningCoachStatus status;

  const RunningFootStrikeEvidenceReferencePreview({
    super.key,
    required this.evidence,
    required this.direction,
    required this.currentPose,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;
        final comparisonHeight = isNarrow ? 218.0 : 244.0;
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
                    l10n.runningCoachTwoDTargetLabel,
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
              child: DecoratedBox(
                key: const ValueKey(
                  'running-coach-foot-strike-reference-runner',
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF101A2A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(
                      direction == RunningDirection.rightToLeft ? -1 : 1,
                      1,
                      1,
                    ),
                    child: Image.asset(
                      'assets/images/running_guides/'
                      'elite_foot_strike_target_reference.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _FootStrikeRenderedMotionPanel(
                          icon: Icons.track_changes_rounded,
                          accent: scheme.primary,
                          label: l10n.runningCoachTwoDTargetLabel,
                          poseFrame: currentPose,
                          direction: direction,
                          status: status,
                          isTarget: true,
                        );
                      },
                    ),
                  ),
                ),
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

class _FootStrikeRenderedMotionPanel extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final RunningPoseFrame? poseFrame;
  final RunningDirection direction;
  final RunningCoachStatus status;
  final bool isTarget;

  const _FootStrikeRenderedMotionPanel({
    required this.icon,
    required this.accent,
    required this.label,
    required this.poseFrame,
    required this.direction,
    required this.status,
    required this.isTarget,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 6),
            child: Row(
              children: [
                Icon(icon, size: 15, color: accent),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Expanded(
            child: RepaintBoundary(
              child: SizedBox.expand(
                child: CustomPaint(
                  painter: _FootStrike2DRunnerPainter(
                    poseFrame: poseFrame,
                    direction: direction,
                    status: status,
                    isTarget: isTarget,
                    currentAccent: scheme.error,
                    targetAccent: scheme.primary,
                    mutedColor: scheme.onSurfaceVariant,
                    surfaceColor: scheme.surface,
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

class _FootStrike2DRunnerPainter extends CustomPainter {
  static const _poseIndices = <int>{
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

  final RunningPoseFrame? poseFrame;
  final RunningDirection direction;
  final RunningCoachStatus status;
  final bool isTarget;
  final Color currentAccent;
  final Color targetAccent;
  final Color mutedColor;
  final Color surfaceColor;

  const _FootStrike2DRunnerPainter({
    required this.poseFrame,
    required this.direction,
    required this.status,
    required this.isTarget,
    required this.currentAccent,
    required this.targetAccent,
    required this.mutedColor,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = surfaceColor.withValues(alpha: 0.34),
    );
    final points = isTarget ? _presetTargetPoints(size) : _currentPoints(size);
    if (points.isEmpty) return;
    final groundY = _groundY(points, size);
    final accent = isTarget ? targetAccent : currentAccent;
    final kitAccent = Color.lerp(accent, const Color(0xFF5B6A80), 0.30)!;
    final kitSecondary = Color.lerp(
      accent,
      const Color(0xFFE7EDF7),
      0.38,
    )!;
    final jointColor = Color.lerp(surfaceColor, const Color(0xFFF4F7FE), 0.82)!;

    canvas.drawLine(
      Offset(size.width * 0.08, groundY),
      Offset(size.width * 0.92, groundY),
      Paint()
        ..color = mutedColor.withValues(alpha: 0.42)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    paintRunningPoseHumanForm(
      canvas,
      points: points,
      canvasSize: size,
      focusIndices: const <int>{23, 24, 25, 26, 27, 28, 31, 32},
      style: runningPoseStudioRunnerStyle(
        accentColor: kitAccent,
        secondaryAccent: kitSecondary,
        focusColor: accent,
        jointColor: jointColor,
        opacity: 0.96,
      ),
    );
    _drawFootStrikeGuide(canvas, size, points, groundY);
  }

  Map<int, Offset> _currentPoints(Size size) {
    final frame = poseFrame;
    if (frame == null) return _presetCurrentPoints(size);
    final raw = <int, Offset>{};
    for (final index in _poseIndices) {
      final landmark = frame.landmarkByIndex(index);
      if (landmark == null ||
          landmark.confidence < runningPoseOverlayMinimumJointConfidence ||
          !landmark.x.isFinite ||
          !landmark.y.isFinite) {
        continue;
      }
      raw[index] = Offset(landmark.x, landmark.y);
    }
    if (!_hasCorePose(raw)) return _presetCurrentPoints(size);

    var minX = raw.values.first.dx;
    var maxX = raw.values.first.dx;
    var minY = raw.values.first.dy;
    var maxY = raw.values.first.dy;
    for (final point in raw.values.skip(1)) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }
    final content = Rect.fromLTWH(
      size.width * 0.07,
      size.height * 0.04,
      size.width * 0.86,
      size.height * 0.84,
    );
    final width = math.max(0.14, maxX - minX);
    final height = math.max(0.18, maxY - minY);
    final scale = math.min(content.width / width, content.height / height);
    final displayWidth = width * scale;
    final displayHeight = height * scale;
    final origin = Offset(
      content.left + (content.width - displayWidth) / 2 - minX * scale,
      content.top + (content.height - displayHeight) / 2 - minY * scale,
    );
    return <int, Offset>{
      for (final entry in raw.entries) entry.key: origin + entry.value * scale,
    };
  }

  bool _hasCorePose(Map<int, Offset> points) {
    final hasHead =
        points.containsKey(0) || points.containsKey(7) || points.containsKey(8);
    return hasHead &&
        const <int>{11, 12, 23, 24, 25, 26, 27, 28}.every(
          points.containsKey,
        );
  }

  Map<int, Offset> _presetCurrentPoints(Size size) {
    final leadFoot = switch (status) {
      RunningCoachStatus.good => 0.68,
      RunningCoachStatus.watch => 0.82,
      RunningCoachStatus.needsWork => 0.92,
    };
    return _presetPoints(size, leadFoot: leadFoot);
  }

  Map<int, Offset> _presetTargetPoints(Size size) {
    return _presetPoints(size, leadFoot: 0.68);
  }

  Map<int, Offset> _presetPoints(
    Size size, {
    required double leadFoot,
  }) {
    final unit = <int, Offset>{
      0: const Offset(0.70, 0.12),
      7: const Offset(0.64, 0.16),
      8: const Offset(0.67, 0.16),
      11: const Offset(0.56, 0.31),
      12: const Offset(0.61, 0.32),
      13: const Offset(0.45, 0.43),
      14: const Offset(0.74, 0.42),
      15: const Offset(0.37, 0.37),
      16: const Offset(0.82, 0.35),
      23: const Offset(0.55, 0.52),
      24: const Offset(0.60, 0.53),
      25: const Offset(0.39, 0.68),
      26: Offset(leadFoot - 0.04, 0.66),
      27: const Offset(0.27, 0.84),
      28: Offset(leadFoot - 0.05, 0.84),
      29: const Offset(0.23, 0.87),
      30: Offset(leadFoot - 0.07, 0.87),
      31: const Offset(0.18, 0.88),
      32: Offset(leadFoot, 0.88),
    };
    final content = Rect.fromLTWH(
      size.width * 0.06,
      size.height * 0.02,
      size.width * 0.88,
      size.height * 0.90,
    );
    final shouldMirror = direction == RunningDirection.rightToLeft;
    return <int, Offset>{
      for (final entry in unit.entries)
        entry.key: Offset(
          shouldMirror
              ? content.right - entry.value.dx * content.width
              : content.left + entry.value.dx * content.width,
          content.top + entry.value.dy * content.height,
        ),
    };
  }

  double _groundY(Map<int, Offset> points, Size size) {
    final contacts = <Offset>[
      if (points[31] case final Offset point) point,
      if (points[32] case final Offset point) point,
      if (points[27] case final Offset point) point,
      if (points[28] case final Offset point) point,
    ];
    final lowest = contacts.isEmpty
        ? size.height * 0.82
        : contacts.map((point) => point.dy).reduce(math.max);
    return lowest.clamp(size.height * 0.68, size.height * 0.93).toDouble();
  }

  void _drawFootStrikeGuide(
    Canvas canvas,
    Size size,
    Map<int, Offset> points,
    double groundY,
  ) {
    final hip = _midpoint(points[23], points[24]);
    final foot = _leadFoot(points);
    if (hip == null || foot == null) return;
    final targetCenter = Offset(hip.dx, groundY);
    final zoneHeight = math.max(9.0, size.height * 0.065);
    final zone = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: targetCenter,
        width: math.max(27.0, size.width * 0.24),
        height: zoneHeight,
      ),
      Radius.circular(zoneHeight / 2),
    );
    final targetPaint = Paint()
      ..color = targetAccent.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    _drawDashedLine(
      canvas,
      hip,
      Offset(hip.dx, groundY - zoneHeight * 0.55),
      Paint()
        ..color = targetAccent.withValues(alpha: 0.70)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRRect(
      zone,
      Paint()..color = targetAccent.withValues(alpha: 0.13),
    );
    canvas.drawRRect(zone, targetPaint);
    if (!isTarget) {
      _drawArrow(
        canvas,
        Offset(foot.dx, groundY - zoneHeight * 0.90),
        Offset(targetCenter.dx, groundY - zoneHeight * 0.90),
        Paint()
          ..color = targetAccent.withValues(alpha: 0.78)
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        Offset(foot.dx, groundY),
        math.max(3.0, size.shortestSide * 0.026),
        Paint()..color = currentAccent,
      );
      return;
    }
    canvas.drawCircle(
      targetCenter,
      math.max(3.0, size.shortestSide * 0.026),
      Paint()..color = targetAccent,
    );
  }

  Offset? _midpoint(Offset? first, Offset? second) {
    if (first == null || second == null) return null;
    return Offset.lerp(first, second, 0.5);
  }

  Offset? _leadFoot(Map<int, Offset> points) {
    final left = points[31] ?? points[27];
    final right = points[32] ?? points[28];
    if (left == null) return right;
    if (right == null) return left;
    return switch (direction) {
      RunningDirection.leftToRight => left.dx >= right.dx ? left : right,
      RunningDirection.rightToLeft => left.dx <= right.dx ? left : right,
      RunningDirection.stationary => left.dy >= right.dy ? left : right,
    };
  }

  @override
  bool shouldRepaint(covariant _FootStrike2DRunnerPainter oldDelegate) {
    return oldDelegate.poseFrame != poseFrame ||
        oldDelegate.direction != direction ||
        oldDelegate.status != status ||
        oldDelegate.isTarget != isTarget ||
        oldDelegate.currentAccent != currentAccent ||
        oldDelegate.targetAccent != targetAccent ||
        oldDelegate.mutedColor != mutedColor ||
        oldDelegate.surfaceColor != surfaceColor;
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
