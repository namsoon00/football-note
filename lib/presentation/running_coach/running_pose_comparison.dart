import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../application/running_coaching_service.dart';
import '../../domain/entities/running_video_analysis_result.dart';
import 'running_coach_avatar.dart';
import 'running_pose_overlay.dart';
import 'running_professional_runner.dart';
import 'running_professional_runner_art.dart';

const _comparisonCanvasPadding = 18.0;
const _minimumMovedDistance = 0.75;

@visibleForTesting
class RunningPoseComparisonSnapshot {
  final Rect panel;
  final Map<int, Offset> currentPoints;
  final Map<int, Offset> targetPoints;
  final Set<int> movedIndices;
  final double forward;
  final double bodyHeight;
  final double groundY;

  const RunningPoseComparisonSnapshot({
    required this.panel,
    required this.currentPoints,
    required this.targetPoints,
    required this.movedIndices,
    required this.forward,
    required this.bodyHeight,
    required this.groundY,
  });

  bool get hasMovement => movedIndices.isNotEmpty;

  double movementDistanceFor(int index) {
    final current = currentPoints[index];
    final target = targetPoints[index];
    if (current == null || target == null) return 0;
    return (target - current).distance;
  }
}

class RunningPoseCoordinateComparison extends StatelessWidget {
  final RunningPoseFrame frame;
  final Iterable<RunningPoseFrame> poseFrames;
  final RunningCoachingInsight insight;
  final RunningDirection direction;
  final bool playbackActive;
  final Color surfaceColor;
  final Color mutedColor;
  final Color actualAccent;
  final Color targetAccent;
  final Color successAccent;
  final String semanticLabel;
  final String currentLabel;
  final String nextStepLabel;

  const RunningPoseCoordinateComparison({
    super.key,
    required this.frame,
    this.poseFrames = const <RunningPoseFrame>[],
    required this.insight,
    required this.direction,
    this.playbackActive = true,
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
    return Semantics(
      key: const ValueKey('running-coach-coordinate-pose-comparison'),
      container: true,
      label: semanticLabel,
      child: FutureBuilder<ui.Image>(
        future: loadProfessionalRunnerArtAtlas(),
        builder: (context, snapshot) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                key: const ValueKey(
                  'running-coach-coordinate-pose-comparison-painter',
                ),
                painter: RunningPoseCoordinateComparisonPainter(
                  frame: frame,
                  insight: insight,
                  direction: direction,
                  progress: 1,
                  surfaceColor: surfaceColor,
                  mutedColor: mutedColor,
                  actualAccent: actualAccent,
                  targetAccent: targetAccent,
                  successAccent: successAccent,
                  artAtlas: snapshot.data,
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 8,
                child: Row(
                  children: [
                    Expanded(
                      child: _ComparisonPanelLabel(
                        label: currentLabel,
                        color: insight.status == RunningCoachStatus.good
                            ? successAccent
                            : actualAccent,
                        alignEnd: false,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _ComparisonPanelLabel(
                        label: nextStepLabel,
                        color: insight.status == RunningCoachStatus.good
                            ? successAccent
                            : targetAccent,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ComparisonPanelLabel extends StatelessWidget {
  final String label;
  final Color color;
  final bool alignEnd;

  const _ComparisonPanelLabel({
    required this.label,
    required this.color,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.38)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ),
    );
  }
}

class RunningPoseCoordinateComparisonPainter extends CustomPainter {
  final RunningPoseFrame frame;
  final RunningCoachingInsight insight;
  final RunningDirection direction;
  final double progress;
  final Color surfaceColor;
  final Color mutedColor;
  final Color actualAccent;
  final Color targetAccent;
  final Color successAccent;
  final RunningCoachingThresholds thresholds;
  final ui.Image? artAtlas;

  const RunningPoseCoordinateComparisonPainter({
    required this.frame,
    required this.insight,
    required this.direction,
    required this.progress,
    required this.surfaceColor,
    required this.mutedColor,
    required this.actualAccent,
    required this.targetAccent,
    required this.successAccent,
    this.thresholds = const RunningCoachingThresholds(),
    this.artAtlas,
  });

  bool get _isGood => insight.status == RunningCoachStatus.good;

  /// The illustrated runner is a fixed coaching reference. Measured
  /// coordinates stay on the uploaded-video evidence surface, because a
  /// single side-view pose does not contain limb-twist information needed to
  /// bend a human image faithfully.
  bool get usesIllustratedRunnerReference => artAtlas != null;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final gap = (size.width * 0.036).clamp(8.0, 12.0).toDouble();
    final panelWidth = math.max(1.0, (size.width - gap) / 2);
    final currentPanel = Rect.fromLTWH(0, 0, panelWidth, size.height);
    final nextPanel = Rect.fromLTWH(
      panelWidth + gap,
      0,
      panelWidth,
      size.height,
    );
    _drawPanel(canvas, currentPanel);
    _drawPanel(canvas, nextPanel);
    final currentSnapshot = buildRunningPoseComparisonSnapshot(
      frame: frame,
      insight: insight,
      direction: direction,
      panel: currentPanel,
      thresholds: thresholds,
    );
    final nextSnapshot = buildRunningPoseComparisonSnapshot(
      frame: frame,
      insight: insight,
      direction: direction,
      panel: nextPanel,
      thresholds: thresholds,
    );
    if (currentSnapshot.currentPoints.isEmpty ||
        nextSnapshot.currentPoints.isEmpty) {
      _drawAvatarFallback(canvas, currentPanel, actualAccent);
      _drawAvatarFallback(canvas, nextPanel, targetAccent);
      return;
    }

    final currentColor = _isGood ? successAccent : actualAccent;
    final nextColor = _isGood ? successAccent : targetAccent;
    final eased = Curves.easeInOutCubic.transform(
      progress.clamp(0.0, 1.0).toDouble(),
    );
    final animatedNextPoints = _isGood
        ? nextSnapshot.currentPoints
        : _lerpPoints(
            nextSnapshot.currentPoints,
            nextSnapshot.targetPoints,
            eased,
          );

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    ));
    _drawGround(canvas, currentSnapshot);
    _drawGround(canvas, nextSnapshot);
    _drawAvatar(
      canvas,
      currentSnapshot,
      points: currentSnapshot.currentPoints,
      accent: currentColor,
      isTarget: false,
    );
    if (!usesIllustratedRunnerReference && !_isGood) {
      _drawMovementVectors(canvas, nextSnapshot);
    }
    _drawAvatar(
      canvas,
      nextSnapshot,
      points: animatedNextPoints,
      accent: nextColor,
      isTarget: true,
    );
    if (!usesIllustratedRunnerReference) {
      _drawMetricGuide(
        canvas,
        currentSnapshot,
        points: currentSnapshot.currentPoints,
        accent: currentColor,
        isTarget: false,
      );
      _drawMetricGuide(
        canvas,
        nextSnapshot,
        points: animatedNextPoints,
        accent: nextColor,
        isTarget: true,
      );
    }
    canvas.restore();
  }

  void _drawPanel(Canvas canvas, Rect panel) {
    final rounded = RRect.fromRectAndRadius(panel, const Radius.circular(8));
    canvas.drawRRect(
      rounded,
      Paint()..color = surfaceColor.withValues(alpha: 0.62),
    );
    canvas.drawRRect(
      rounded,
      Paint()
        ..color = mutedColor.withValues(alpha: 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawGround(Canvas canvas, RunningPoseComparisonSnapshot snapshot) {
    final paint = Paint()
      ..color = mutedColor.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(snapshot.panel.left + 14, snapshot.groundY),
      Offset(snapshot.panel.right - 14, snapshot.groundY),
      paint,
    );
  }

  void _drawMetricGuide(
    Canvas canvas,
    RunningPoseComparisonSnapshot snapshot, {
    required Map<int, Offset> points,
    required Color accent,
    required bool isTarget,
  }) {
    switch (insight.metric) {
      case RunningCoachMetric.posture:
        _drawPostureGuide(
          canvas,
          snapshot,
          points: points,
          accent: accent,
          isTarget: isTarget,
        );
      case RunningCoachMetric.bounce:
        _drawBounceGuide(
          canvas,
          snapshot,
          points: points,
          accent: accent,
          isTarget: isTarget,
        );
      case RunningCoachMetric.footStrike:
        _drawFootStrikeGuide(
          canvas,
          snapshot,
          points: points,
          accent: accent,
          isTarget: isTarget,
        );
      case RunningCoachMetric.kneeFlexion:
        _drawJointAngleGuide(
          canvas,
          snapshot,
          points: points,
          accent: accent,
          isArm: false,
        );
      case RunningCoachMetric.armCarriage:
        _drawJointAngleGuide(
          canvas,
          snapshot,
          points: points,
          accent: accent,
          isArm: true,
        );
    }
  }

  void _drawPostureGuide(
    Canvas canvas,
    RunningPoseComparisonSnapshot snapshot, {
    required Map<int, Offset> points,
    required Color accent,
    required bool isTarget,
  }) {
    final torso = _torso(points);
    if (torso == null) return;
    final length = math.max(18.0, (torso.shoulder - torso.hip).distance);
    final verticalTop = torso.hip - Offset(0, length);
    _drawDashedLine(
      canvas,
      verticalTop,
      torso.hip,
      _stroke(mutedColor, width: 1.2, opacity: 0.46),
    );
    final guidePaint = _stroke(accent, width: 1.8, opacity: 0.82);
    canvas.drawLine(torso.hip, torso.shoulder, guidePaint);
    _drawArc(
      canvas,
      torso.hip,
      verticalTop,
      torso.shoulder,
      length * 0.23,
      guidePaint,
    );
    if (!isTarget) return;

    final minVector = Offset(
      snapshot.forward *
          length *
          math.sin(thresholds.minimumForwardLeanDegrees * math.pi / 180),
      -length * math.cos(thresholds.minimumForwardLeanDegrees * math.pi / 180),
    );
    final maxVector = Offset(
      snapshot.forward *
          length *
          math.sin(thresholds.maximumForwardLeanDegrees * math.pi / 180),
      -length * math.cos(thresholds.maximumForwardLeanDegrees * math.pi / 180),
    );
    canvas.drawPath(
      Path()
        ..moveTo(torso.hip.dx, torso.hip.dy)
        ..lineTo((torso.hip + minVector).dx, (torso.hip + minVector).dy)
        ..lineTo((torso.hip + maxVector).dx, (torso.hip + maxVector).dy)
        ..close(),
      Paint()
        ..color = accent.withValues(alpha: 0.11)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawBounceGuide(
    Canvas canvas,
    RunningPoseComparisonSnapshot snapshot, {
    required Map<int, Offset> points,
    required Color accent,
    required bool isTarget,
  }) {
    final torso = _torso(points);
    if (torso == null) return;
    final currentSpan = (snapshot.panel.height * (insight.value / 100) * 2.4)
        .clamp(18.0, snapshot.panel.height * 0.44)
        .toDouble();
    final targetSpan = (snapshot.panel.height *
            (thresholds.maximumVerticalBouncePercent / 100) *
            2.4)
        .clamp(14.0, snapshot.panel.height * 0.30)
        .toDouble();
    final span = isTarget && !_isGood ? targetSpan : currentSpan;
    final side =
        _annotationSign(snapshot.panel, torso.shoulder, snapshot.forward);
    final x = (torso.shoulder.dx + side * snapshot.panel.width * 0.09)
        .clamp(snapshot.panel.left + 18, snapshot.panel.right - 18)
        .toDouble();
    _drawDoubleArrow(
      canvas,
      Offset(x, torso.shoulder.dy - span / 2),
      Offset(x, torso.shoulder.dy + span / 2),
      _stroke(accent, width: 2.0, opacity: 0.76),
    );
    if (!isTarget) return;
    final band = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, torso.shoulder.dy),
        width: 15,
        height: targetSpan,
      ),
      const Radius.circular(99),
    );
    canvas.drawRRect(band, Paint()..color = accent.withValues(alpha: 0.13));
    canvas.drawRRect(band, _stroke(accent, width: 1.6, opacity: 0.76));
  }

  void _drawFootStrikeGuide(
    Canvas canvas,
    RunningPoseComparisonSnapshot snapshot, {
    required Map<int, Offset> points,
    required Color accent,
    required bool isTarget,
  }) {
    final torso = _torso(points);
    if (torso == null) return;
    final leg = _leadLeg(
      points,
      forward: snapshot.forward,
    );
    if (leg == null) return;
    _drawDashedLine(
      canvas,
      torso.hip,
      Offset(torso.hip.dx, snapshot.groundY - 5),
      _stroke(mutedColor, width: 1.2, opacity: 0.48),
    );
    final foot = Offset(leg.toe.dx, snapshot.groundY);
    canvas.drawCircle(
      foot,
      6.2,
      Paint()..color = accent.withValues(alpha: 0.14),
    );
    canvas.drawCircle(foot, 3.1, Paint()..color = accent);
    if (!isTarget) return;

    final ratioToPixels = _ratioToPixels(
      metricValue: insight.value,
      currentDistance: ((leg.toe.dx - torso.hip.dx) * snapshot.forward).abs(),
      fallbackBodyHeight: snapshot.bodyHeight,
    );
    final maxDistance = thresholds.maximumFootStrikeRatio * ratioToPixels;
    final backstop = math.min(snapshot.bodyHeight * 0.035, maxDistance);
    final startX = torso.hip.dx - snapshot.forward * backstop;
    final endX = torso.hip.dx + snapshot.forward * maxDistance;
    final zone = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        math.min(startX, endX),
        snapshot.groundY - 13,
        math.max(startX, endX),
        snapshot.groundY - 3,
      ),
      const Radius.circular(99),
    );
    canvas.drawRRect(zone, Paint()..color = accent.withValues(alpha: 0.14));
    canvas.drawRRect(zone, _stroke(accent, width: 1.6, opacity: 0.82));
  }

  void _drawJointAngleGuide(
    Canvas canvas,
    RunningPoseComparisonSnapshot snapshot, {
    required Map<int, Offset> points,
    required Color accent,
    required bool isArm,
  }) {
    if (isArm) {
      final arm = _leadArm(points, forward: snapshot.forward);
      if (arm == null) return;
      _drawArc(
        canvas,
        arm.elbow,
        arm.shoulder,
        arm.wrist,
        math.max(12.0, (arm.wrist - arm.elbow).distance * 0.32),
        _stroke(accent, width: 2.0, opacity: 0.78),
      );
      return;
    }

    final leg = _leadLeg(points, forward: snapshot.forward);
    if (leg == null) return;
    _drawArc(
      canvas,
      leg.knee,
      leg.hip,
      leg.ankle,
      math.max(12.0, (leg.ankle - leg.knee).distance * 0.32),
      _stroke(accent, width: 2.0, opacity: 0.78),
    );
  }

  void _drawAvatar(
    Canvas canvas,
    RunningPoseComparisonSnapshot snapshot, {
    required Map<int, Offset> points,
    required Color accent,
    required bool isTarget,
  }) {
    final atlas = artAtlas;
    final athlete = retargetProfessionalRunnerPose(
      measuredPoints: points,
      forward: snapshot.forward,
    );
    if (atlas == null || athlete == null) {
      _drawAvatarFallback(canvas, snapshot.panel, accent);
      return;
    }

    paintIllustratedProfessionalRunner(
      canvas,
      atlas: atlas,
      pose: athlete,
      accentColor: accent,
      // A green in-range comparison should not imply that the left pose is
      // an overstride that still needs correcting.
      isTarget: _isGood || isTarget,
      bounds: snapshot.panel,
    );
  }

  void _drawAvatarFallback(Canvas canvas, Rect panel, Color accent) {
    paintRunningCoachAvatarFallback(
      canvas,
      bounds: panel,
      accentColor: accent,
    );
  }

  void _drawMovementVectors(
    Canvas canvas,
    RunningPoseComparisonSnapshot snapshot,
  ) {
    if (!snapshot.hasMovement) return;
    final paint = _stroke(targetAccent, width: 2.2, opacity: 0.86);
    final haloPaint = _stroke(targetAccent, width: 5.2, opacity: 0.15);
    int? mostMovedIndex;
    var longestDistance = 0.0;
    for (final index in snapshot.movedIndices) {
      if (!_focusIndices.contains(index)) continue;
      final distance = snapshot.movementDistanceFor(index);
      if (distance > longestDistance) {
        longestDistance = distance;
        mostMovedIndex = index;
      }
    }
    final index = mostMovedIndex;
    if (index == null || longestDistance < 2) return;
    final start = snapshot.currentPoints[index];
    final end = snapshot.targetPoints[index];
    if (start == null || end == null) return;
    final vector = end - start;
    final distance = vector.distance;
    final unit = vector / distance;
    final trimmedStart = start + unit * math.min(7.0, distance * 0.20);
    final trimmedEnd = end - unit * math.min(7.0, distance * 0.20);
    if ((trimmedEnd - trimmedStart).distance < 1) return;
    canvas.drawLine(trimmedStart, trimmedEnd, haloPaint);
    canvas.drawLine(trimmedStart, trimmedEnd, paint);
    _drawArrowHead(canvas, trimmedEnd, unit, paint);
  }

  Set<int> get _focusIndices =>
      focusIndicesForRunningPoseMetric(insight.metric);

  Paint _stroke(
    Color color, {
    required double width,
    double opacity = 1,
  }) {
    return Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    final vector = end - start;
    final distance = vector.distance;
    if (distance <= 0) return;
    final unit = vector / distance;
    for (var offset = 0.0; offset < distance; offset += 8.5) {
      canvas.drawLine(
        start + unit * offset,
        start + unit * math.min(offset + 4.8, distance),
        paint,
      );
    }
  }

  void _drawArc(
    Canvas canvas,
    Offset center,
    Offset start,
    Offset end,
    double radius,
    Paint paint,
  ) {
    if (radius <= 0) return;
    final startAngle = math.atan2(start.dy - center.dy, start.dx - center.dx);
    final endAngle = math.atan2(end.dy - center.dy, end.dx - center.dx);
    var sweep = (endAngle - startAngle) % (math.pi * 2);
    if (sweep > math.pi) sweep -= math.pi * 2;
    if (sweep < -math.pi) sweep += math.pi * 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      paint,
    );
  }

  void _drawDoubleArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    final vector = end - start;
    final distance = vector.distance;
    if (distance <= 0) return;
    final unit = vector / distance;
    _drawArrowHead(canvas, start, -unit, paint);
    _drawArrowHead(canvas, end, unit, paint);
  }

  void _drawArrowHead(
    Canvas canvas,
    Offset tip,
    Offset direction,
    Paint paint,
  ) {
    final distance = direction.distance;
    if (distance <= 0) return;
    final unit = direction / distance;
    final perpendicular = Offset(-unit.dy, unit.dx);
    final length = math.max(6.0, paint.strokeWidth * 3);
    canvas.drawLine(
      tip,
      tip - unit * length + perpendicular * (length * 0.52),
      paint,
    );
    canvas.drawLine(
      tip,
      tip - unit * length - perpendicular * (length * 0.52),
      paint,
    );
  }

  double _annotationSign(Rect panel, Offset anchor, double preferred) {
    final room =
        preferred >= 0 ? panel.right - anchor.dx : anchor.dx - panel.left;
    return room >= panel.width * 0.22 ? preferred : -preferred;
  }

  @override
  bool shouldRepaint(
    covariant RunningPoseCoordinateComparisonPainter oldDelegate,
  ) {
    return oldDelegate.frame != frame ||
        oldDelegate.insight != insight ||
        oldDelegate.direction != direction ||
        oldDelegate.progress != progress ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.mutedColor != mutedColor ||
        oldDelegate.actualAccent != actualAccent ||
        oldDelegate.targetAccent != targetAccent ||
        oldDelegate.successAccent != successAccent ||
        oldDelegate.thresholds != thresholds ||
        oldDelegate.artAtlas != artAtlas;
  }
}

@visibleForTesting
RunningPoseComparisonSnapshot buildRunningPoseComparisonSnapshot({
  required RunningPoseFrame frame,
  required RunningCoachingInsight insight,
  required RunningDirection direction,
  required Rect panel,
  RunningCoachingThresholds thresholds = const RunningCoachingThresholds(),
}) {
  final mapped = _mapPoseFramePoints(frame, panel);
  if (mapped.points.isEmpty) {
    return RunningPoseComparisonSnapshot(
      panel: panel,
      currentPoints: const <int, Offset>{},
      targetPoints: const <int, Offset>{},
      movedIndices: const <int>{},
      forward: 1,
      bodyHeight: 0,
      groundY: panel.bottom,
    );
  }
  final forward = _resolveVisualForward(
    measuredPoints: mapped.points,
    direction: direction,
  );
  final groundY = _groundYFor(panel, mapped.points);
  final targetPoints = Map<int, Offset>.from(mapped.points);
  final movedIndices = <int>{};
  if (insight.status != RunningCoachStatus.good &&
      insight.quality.isReliableForCoaching) {
    switch (insight.metric) {
      case RunningCoachMetric.posture:
        _applyPostureTarget(
          targetPoints,
          insight: insight,
          thresholds: thresholds,
          forward: forward,
          movedIndices: movedIndices,
        );
      case RunningCoachMetric.bounce:
        break;
      case RunningCoachMetric.footStrike:
        _applyFootStrikeTarget(
          targetPoints,
          sourcePoints: mapped.points,
          insight: insight,
          thresholds: thresholds,
          forward: forward,
          bodyHeight: mapped.bodyHeight,
          movedIndices: movedIndices,
        );
      case RunningCoachMetric.kneeFlexion:
        _applyKneeTarget(
          targetPoints,
          insight: insight,
          thresholds: thresholds,
          forward: forward,
          movedIndices: movedIndices,
        );
      case RunningCoachMetric.armCarriage:
        _applyArmTarget(
          targetPoints,
          insight: insight,
          thresholds: thresholds,
          forward: forward,
          movedIndices: movedIndices,
        );
    }
  }

  return RunningPoseComparisonSnapshot(
    panel: panel,
    currentPoints: Map<int, Offset>.unmodifiable(mapped.points),
    targetPoints: Map<int, Offset>.unmodifiable(targetPoints),
    movedIndices: Set<int>.unmodifiable(movedIndices),
    forward: forward,
    bodyHeight: mapped.bodyHeight,
    groundY: groundY,
  );
}

@visibleForTesting
Set<int> focusIndicesForRunningPoseMetric(RunningCoachMetric metric) {
  return switch (metric) {
    RunningCoachMetric.posture => const <int>{
        0,
        7,
        8,
        11,
        12,
        23,
        24,
      },
    RunningCoachMetric.bounce => const <int>{0, 7, 8, 11, 12, 23, 24},
    RunningCoachMetric.footStrike => const <int>{
        23,
        24,
        25,
        26,
        27,
        28,
        31,
        32,
      },
    RunningCoachMetric.kneeFlexion => const <int>{
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
      },
    RunningCoachMetric.armCarriage => const <int>{
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
      },
  };
}

({Map<int, Offset> points, double bodyHeight}) _mapPoseFramePoints(
  RunningPoseFrame frame,
  Rect panel,
) {
  final visible = frame.landmarks
      .where(
        (landmark) =>
            landmark.confidence >= runningPoseOverlayMinimumJointConfidence &&
            landmark.x.isFinite &&
            landmark.y.isFinite,
      )
      .toList(growable: false);
  if (visible.isEmpty) return (points: const <int, Offset>{}, bodyHeight: 0);

  var minX = visible.first.x;
  var maxX = visible.first.x;
  var minY = visible.first.y;
  var maxY = visible.first.y;
  for (final landmark in visible.skip(1)) {
    minX = math.min(minX, landmark.x);
    maxX = math.max(maxX, landmark.x);
    minY = math.min(minY, landmark.y);
    maxY = math.max(maxY, landmark.y);
  }
  final bodyWidth = math.max(0.08, maxX - minX);
  final bodyHeight = math.max(0.12, maxY - minY);
  final content = panel.deflate(
    math.min(_comparisonCanvasPadding, panel.shortestSide * 0.08),
  );
  final scale = math.min(
    content.width / bodyWidth,
    content.height / bodyHeight,
  );
  final displayWidth = bodyWidth * scale;
  final displayHeight = bodyHeight * scale;
  final origin = Offset(
    content.left + (content.width - displayWidth) / 2 - minX * scale,
    content.top + (content.height - displayHeight) / 2 - minY * scale,
  );
  return (
    points: <int, Offset>{
      for (final landmark in visible)
        landmark.index: origin + Offset(landmark.x * scale, landmark.y * scale),
    },
    bodyHeight: displayHeight,
  );
}

void _applyPostureTarget(
  Map<int, Offset> targetPoints, {
  required RunningCoachingInsight insight,
  required RunningCoachingThresholds thresholds,
  required double forward,
  required Set<int> movedIndices,
}) {
  final torso = _torso(targetPoints);
  if (torso == null) return;
  final currentVector = torso.shoulder - torso.hip;
  final length = currentVector.distance;
  if (length < 1) return;
  final targetDegrees = insight.finding == RunningCoachFinding.postureTooLean
      ? thresholds.maximumForwardLeanDegrees
      : thresholds.minimumForwardLeanDegrees;
  final targetRadians = targetDegrees * math.pi / 180;
  final targetVector = Offset(
    forward * length * math.sin(targetRadians),
    -length * math.cos(targetRadians),
  );
  final deltaRadians = math.atan2(targetVector.dy, targetVector.dx) -
      math.atan2(currentVector.dy, currentVector.dx);
  for (final index in _upperBodyIndices) {
    final point = targetPoints[index];
    if (point == null) continue;
    _setTargetPoint(
      targetPoints,
      index,
      _rotateAround(point, torso.hip, deltaRadians),
      movedIndices,
    );
  }
}

void _applyFootStrikeTarget(
  Map<int, Offset> targetPoints, {
  required Map<int, Offset> sourcePoints,
  required RunningCoachingInsight insight,
  required RunningCoachingThresholds thresholds,
  required double forward,
  required double bodyHeight,
  required Set<int> movedIndices,
}) {
  final torso = _torso(sourcePoints);
  final leg = _leadLeg(sourcePoints, forward: forward);
  if (torso == null || leg == null) return;
  final thighLength = (leg.knee - leg.hip).distance;
  final shinLength = (leg.ankle - leg.knee).distance;
  final footVector = leg.toe - leg.ankle;
  final footLength = footVector.distance;
  if (thighLength < 1 || shinLength < 1 || footLength < 1) return;

  final currentDistance = ((leg.toe.dx - torso.hip.dx) * forward).abs();
  final pixelsPerRatio = _ratioToPixels(
    metricValue: insight.value,
    currentDistance: currentDistance,
    fallbackBodyHeight: bodyHeight,
  );
  final targetDistance = thresholds.maximumFootStrikeRatio * pixelsPerRatio;
  var targetToe = Offset(
    torso.hip.dx + forward * targetDistance,
    leg.toe.dy,
  );
  var targetAnkle = targetToe - footVector;
  targetAnkle = _clampToReachableAnkle(
    hip: leg.hip,
    ankle: targetAnkle,
    thighLength: thighLength,
    shinLength: shinLength,
  );
  targetToe = targetAnkle + footVector;
  final targetKnee = _circleIntersectionNearest(
    firstCenter: leg.hip,
    firstRadius: thighLength,
    secondCenter: targetAnkle,
    secondRadius: shinLength,
    nearestTo: leg.knee,
  );
  if (targetKnee == null) return;

  _setTargetPoint(targetPoints, leg.kneeIndex, targetKnee, movedIndices);
  _setTargetPoint(targetPoints, leg.ankleIndex, targetAnkle, movedIndices);
  _setTargetPoint(targetPoints, leg.toeIndex, targetToe, movedIndices);
}

void _applyKneeTarget(
  Map<int, Offset> targetPoints, {
  required RunningCoachingInsight insight,
  required RunningCoachingThresholds thresholds,
  required double forward,
  required Set<int> movedIndices,
}) {
  final leg = _leadLeg(targetPoints, forward: forward);
  if (leg == null) return;
  final targetDegrees = insight.finding == RunningCoachFinding.kneeTooCollapsed
      ? thresholds.minimumStanceKneeAngleDegrees
      : thresholds.maximumStanceKneeAngleDegrees;
  final targetAnkle = _pointAtAngle(
    pivot: leg.knee,
    fixed: leg.hip,
    moving: leg.ankle,
    targetAngleDegrees: targetDegrees,
    fallbackTurn: forward,
  );
  if (targetAnkle == null) return;
  final delta = targetAnkle - leg.ankle;
  _setTargetPoint(targetPoints, leg.ankleIndex, targetAnkle, movedIndices);
  for (final index in <int>[leg.heelIndex, leg.toeIndex]) {
    final point = targetPoints[index];
    if (point != null) {
      _setTargetPoint(targetPoints, index, point + delta, movedIndices);
    }
  }
}

void _applyArmTarget(
  Map<int, Offset> targetPoints, {
  required RunningCoachingInsight insight,
  required RunningCoachingThresholds thresholds,
  required double forward,
  required Set<int> movedIndices,
}) {
  final arm = _leadArm(targetPoints, forward: forward);
  if (arm == null) return;
  final targetDegrees = insight.finding == RunningCoachFinding.armTooTight
      ? thresholds.minimumElbowAngleDegrees
      : thresholds.maximumElbowAngleDegrees;
  final targetWrist = _pointAtAngle(
    pivot: arm.elbow,
    fixed: arm.shoulder,
    moving: arm.wrist,
    targetAngleDegrees: targetDegrees,
    fallbackTurn: forward,
  );
  if (targetWrist == null) return;
  final delta = targetWrist - arm.wrist;
  _setTargetPoint(targetPoints, arm.wristIndex, targetWrist, movedIndices);
  for (final index in arm.handIndices) {
    final point = targetPoints[index];
    if (point != null) {
      _setTargetPoint(targetPoints, index, point + delta, movedIndices);
    }
  }
}

void _setTargetPoint(
  Map<int, Offset> targetPoints,
  int index,
  Offset value,
  Set<int> movedIndices,
) {
  final current = targetPoints[index];
  if (current == null) return;
  targetPoints[index] = value;
  if ((value - current).distance >= _minimumMovedDistance) {
    movedIndices.add(index);
  }
}

double _groundYFor(Rect panel, Map<int, Offset> points) {
  final contacts = <Offset>[
    if (points[31] case final point?) point,
    if (points[32] case final point?) point,
    if (points[27] case final point?) point,
    if (points[28] case final point?) point,
  ];
  final lowest = contacts.isEmpty
      ? panel.top + panel.height * 0.80
      : contacts
          .map((point) => point.dy)
          .reduce((current, next) => math.max(current, next));
  return lowest
      .clamp(panel.top + panel.height * 0.68, panel.bottom - 12)
      .toDouble();
}

double _ratioToPixels({
  required double metricValue,
  required double currentDistance,
  required double fallbackBodyHeight,
}) {
  if (metricValue.abs() >= 0.001 && currentDistance.isFinite) {
    final value = currentDistance / metricValue.abs();
    if (value.isFinite && value >= 4) return value;
  }
  return math.max(24.0, fallbackBodyHeight);
}

Offset _clampToReachableAnkle({
  required Offset hip,
  required Offset ankle,
  required double thighLength,
  required double shinLength,
}) {
  final vector = ankle - hip;
  final distance = vector.distance;
  if (distance < 0.001) {
    return hip + Offset(0, thighLength + shinLength - 0.5);
  }
  final maxDistance = math.max(1.0, thighLength + shinLength - 0.5);
  final minDistance = math.max(1.0, (thighLength - shinLength).abs() + 0.5);
  final clampedDistance = distance.clamp(minDistance, maxDistance).toDouble();
  return hip + vector / distance * clampedDistance;
}

Offset? _circleIntersectionNearest({
  required Offset firstCenter,
  required double firstRadius,
  required Offset secondCenter,
  required double secondRadius,
  required Offset nearestTo,
}) {
  final centerDelta = secondCenter - firstCenter;
  final distance = centerDelta.distance;
  if (distance < 0.001 ||
      distance > firstRadius + secondRadius ||
      distance < (firstRadius - secondRadius).abs()) {
    return null;
  }
  final unit = centerDelta / distance;
  final along = (firstRadius * firstRadius -
          secondRadius * secondRadius +
          distance * distance) /
      (2 * distance);
  final heightSquared = firstRadius * firstRadius - along * along;
  if (heightSquared < -0.001) return null;
  final height = math.sqrt(math.max(0, heightSquared));
  final base = firstCenter + unit * along;
  final perpendicular = Offset(-unit.dy, unit.dx);
  final first = base + perpendicular * height;
  final second = base - perpendicular * height;
  return (first - nearestTo).distance <= (second - nearestTo).distance
      ? first
      : second;
}

Offset? _pointAtAngle({
  required Offset pivot,
  required Offset fixed,
  required Offset moving,
  required double targetAngleDegrees,
  required double fallbackTurn,
}) {
  final fixedVector = fixed - pivot;
  final movingVector = moving - pivot;
  final fixedLength = fixedVector.distance;
  final movingLength = movingVector.distance;
  if (fixedLength < 1 || movingLength < 1) return null;
  final signedAngle = math.atan2(
    fixedVector.dx * movingVector.dy - fixedVector.dy * movingVector.dx,
    fixedVector.dx * movingVector.dx + fixedVector.dy * movingVector.dy,
  );
  final turn = signedAngle.abs() < 0.001
      ? (fallbackTurn >= 0 ? 1.0 : -1.0)
      : signedAngle >= 0
          ? 1.0
          : -1.0;
  final targetRadians =
      targetAngleDegrees.clamp(1.0, 179.0).toDouble() * math.pi / 180;
  final fixedRadians = math.atan2(fixedVector.dy, fixedVector.dx);
  return pivot +
      Offset(
        math.cos(fixedRadians + turn * targetRadians) * movingLength,
        math.sin(fixedRadians + turn * targetRadians) * movingLength,
      );
}

Offset _rotateAround(Offset point, Offset pivot, double radians) {
  final translated = point - pivot;
  final cosTheta = math.cos(radians);
  final sinTheta = math.sin(radians);
  return pivot +
      Offset(
        translated.dx * cosTheta - translated.dy * sinTheta,
        translated.dx * sinTheta + translated.dy * cosTheta,
      );
}

Map<int, Offset> _lerpPoints(
  Map<int, Offset> current,
  Map<int, Offset> target,
  double progress,
) {
  return <int, Offset>{
    for (final entry in current.entries)
      entry.key: Offset.lerp(
        entry.value,
        target[entry.key] ?? entry.value,
        progress,
      )!,
  };
}

({Offset shoulder, Offset hip})? _torso(Map<int, Offset> points) {
  final leftShoulder = points[11];
  final rightShoulder = points[12];
  final leftHip = points[23];
  final rightHip = points[24];
  if (leftShoulder == null ||
      rightShoulder == null ||
      leftHip == null ||
      rightHip == null) {
    return null;
  }
  return (
    shoulder: Offset.lerp(leftShoulder, rightShoulder, 0.5)!,
    hip: Offset.lerp(leftHip, rightHip, 0.5)!,
  );
}

_IndexedLeg? _leadLeg(
  Map<int, Offset> points, {
  required double forward,
}) {
  final left = _leg(points, isLeft: true);
  final right = _leg(points, isLeft: false);
  if (left == null) return right;
  if (right == null) return left;
  return left.toe.dx * forward >= right.toe.dx * forward ? left : right;
}

_IndexedLeg? _leg(Map<int, Offset> points, {required bool isLeft}) {
  final hipIndex = isLeft ? 23 : 24;
  final kneeIndex = isLeft ? 25 : 26;
  final ankleIndex = isLeft ? 27 : 28;
  final heelIndex = isLeft ? 29 : 30;
  final toeIndex = isLeft ? 31 : 32;
  final hip = points[hipIndex];
  final knee = points[kneeIndex];
  final ankle = points[ankleIndex];
  final toe = points[toeIndex];
  if (hip == null || knee == null || ankle == null || toe == null) {
    return null;
  }
  return _IndexedLeg(
    hipIndex: hipIndex,
    kneeIndex: kneeIndex,
    ankleIndex: ankleIndex,
    heelIndex: heelIndex,
    toeIndex: toeIndex,
    hip: hip,
    knee: knee,
    ankle: ankle,
    toe: toe,
  );
}

_IndexedArm? _leadArm(
  Map<int, Offset> points, {
  required double forward,
}) {
  final left = _arm(points, isLeft: true);
  final right = _arm(points, isLeft: false);
  if (left == null) return right;
  if (right == null) return left;
  return left.wrist.dx * forward >= right.wrist.dx * forward ? left : right;
}

_IndexedArm? _arm(Map<int, Offset> points, {required bool isLeft}) {
  final shoulderIndex = isLeft ? 11 : 12;
  final elbowIndex = isLeft ? 13 : 14;
  final wristIndex = isLeft ? 15 : 16;
  final shoulder = points[shoulderIndex];
  final elbow = points[elbowIndex];
  final wrist = points[wristIndex];
  if (shoulder == null || elbow == null || wrist == null) return null;
  return _IndexedArm(
    shoulderIndex: shoulderIndex,
    elbowIndex: elbowIndex,
    wristIndex: wristIndex,
    handIndices: isLeft ? const <int>[17, 19, 21] : const <int>[18, 20, 22],
    shoulder: shoulder,
    elbow: elbow,
    wrist: wrist,
  );
}

double _resolveVisualForward({
  required Map<int, Offset> measuredPoints,
  required RunningDirection direction,
}) {
  final shoulderCenter = _pairCenter(measuredPoints[11], measuredPoints[12]);
  final hipCenter = _pairCenter(measuredPoints[23], measuredPoints[24]);
  final faceCenter = _faceCenter(measuredPoints);
  if (faceCenter != null && shoulderCenter != null) {
    final torsoLength =
        hipCenter == null ? 0.0 : (hipCenter - shoulderCenter).distance;
    final minimumOffset = math.max(0.01, torsoLength * 0.045);
    final faceOffset = faceCenter.dx - shoulderCenter.dx;
    if (faceOffset.abs() >= minimumOffset) {
      return faceOffset.isNegative ? -1 : 1;
    }
  }
  switch (direction) {
    case RunningDirection.leftToRight:
      return 1;
    case RunningDirection.rightToLeft:
      return -1;
    case RunningDirection.stationary:
      if (shoulderCenter != null && hipCenter != null) {
        return shoulderCenter.dx >= hipCenter.dx ? 1 : -1;
      }
      return 1;
  }
}

Offset? _pairCenter(Offset? first, Offset? second) {
  if (first == null || second == null) return null;
  return Offset.lerp(first, second, 0.5);
}

Offset? _faceCenter(Map<int, Offset> points) {
  const weightedIndices = <(int, double)>[
    (0, 1.8),
    (2, 1),
    (5, 1),
    (7, 0.65),
    (8, 0.65),
  ];
  var totalWeight = 0.0;
  var totalX = 0.0;
  var totalY = 0.0;
  for (final (index, weight) in weightedIndices) {
    final point = points[index];
    if (point == null) continue;
    totalWeight += weight;
    totalX += point.dx * weight;
    totalY += point.dy * weight;
  }
  if (totalWeight == 0) return null;
  return Offset(totalX / totalWeight, totalY / totalWeight);
}

const _upperBodyIndices = <int>{
  0,
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  14,
  15,
  16,
  17,
  18,
  19,
  20,
  21,
  22,
};

class _IndexedLeg {
  final int hipIndex;
  final int kneeIndex;
  final int ankleIndex;
  final int heelIndex;
  final int toeIndex;
  final Offset hip;
  final Offset knee;
  final Offset ankle;
  final Offset toe;

  const _IndexedLeg({
    required this.hipIndex,
    required this.kneeIndex,
    required this.ankleIndex,
    required this.heelIndex,
    required this.toeIndex,
    required this.hip,
    required this.knee,
    required this.ankle,
    required this.toe,
  });

  Offset get middle => knee;
  Offset get end => ankle;
}

class _IndexedArm {
  final int shoulderIndex;
  final int elbowIndex;
  final int wristIndex;
  final List<int> handIndices;
  final Offset shoulder;
  final Offset elbow;
  final Offset wrist;

  const _IndexedArm({
    required this.shoulderIndex,
    required this.elbowIndex,
    required this.wristIndex,
    required this.handIndices,
    required this.shoulder,
    required this.elbow,
    required this.wrist,
  });

  Offset get middle => elbow;
  Offset get end => wrist;
}
