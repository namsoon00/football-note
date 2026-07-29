import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../application/running_coaching_service.dart';
import '../../domain/entities/running_video_analysis_result.dart';
import 'running_coordinate_athlete_art.dart';
import 'running_pose_overlay.dart';

const _comparisonCanvasPadding = 18.0;
const _minimumMovedDistance = 0.75;
const _athleteArtworkSource = Rect.fromLTWH(40, 96, 920, 1236);

const _coordinateTraceChains = <List<int>>[
  <int>[0, 7, 11, 23],
  <int>[0, 8, 12, 24],
  <int>[11, 13, 15, 19],
  <int>[12, 14, 16, 20],
  <int>[23, 25, 27, 31],
  <int>[24, 26, 28, 32],
  <int>[27, 29, 31],
  <int>[28, 30, 32],
];

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
  final RunningCoachingInsight insight;
  final RunningDirection direction;
  final Animation<double> progress;
  final Color surfaceColor;
  final Color mutedColor;
  final Color actualAccent;
  final Color targetAccent;
  final Color successAccent;
  final String semanticLabel;

  const RunningPoseCoordinateComparison({
    super.key,
    required this.frame,
    required this.insight,
    required this.direction,
    required this.progress,
    required this.surfaceColor,
    required this.mutedColor,
    required this.actualAccent,
    required this.targetAccent,
    required this.successAccent,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: FutureBuilder<ui.Image>(
        future: loadRunningCoordinateAthleteArt(),
        builder: (context, snapshot) {
          return AnimatedBuilder(
            animation: progress,
            builder: (context, _) {
              return CustomPaint(
                key: const ValueKey(
                  'running-coach-coordinate-pose-comparison',
                ),
                painter: RunningPoseCoordinateComparisonPainter(
                  frame: frame,
                  insight: insight,
                  direction: direction,
                  progress: progress.value,
                  surfaceColor: surfaceColor,
                  mutedColor: mutedColor,
                  actualAccent: actualAccent,
                  targetAccent: targetAccent,
                  successAccent: successAccent,
                  athleteArt: snapshot.data,
                ),
              );
            },
          );
        },
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
  final ui.Image? athleteArt;
  final RunningCoachingThresholds thresholds;

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
    this.athleteArt,
    this.thresholds = const RunningCoachingThresholds(),
  });

  bool get _isGood => insight.status == RunningCoachStatus.good;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final panel = Offset.zero & size;
    _drawPanel(canvas, panel);
    final snapshot = buildRunningPoseComparisonSnapshot(
      frame: frame,
      insight: insight,
      direction: direction,
      panel: panel,
      thresholds: thresholds,
    );
    if (snapshot.currentPoints.isEmpty) return;

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(panel, const Radius.circular(8)),
    );
    _drawGround(canvas, snapshot);
    _drawAthleteArtwork(canvas, snapshot);
    _drawMetricGuide(canvas, snapshot);

    if (_isGood) {
      _drawMeasuredCoordinateTrace(
        canvas,
        snapshot.currentPoints,
        accent: successAccent,
        opacity: 0.92,
        focusIndices: _focusIndices,
      );
    } else {
      final eased = Curves.easeInOutCubic.transform(
        progress.clamp(0.0, 1.0).toDouble(),
      );
      final animatedPoints = _lerpPoints(
        snapshot.currentPoints,
        snapshot.targetPoints,
        eased,
      );
      _drawMeasuredCoordinateTrace(
        canvas,
        snapshot.currentPoints,
        accent: actualAccent,
        opacity: 0.64,
        focusIndices: _focusIndices,
      );
      _drawMeasuredCoordinateTrace(
        canvas,
        snapshot.targetPoints,
        accent: targetAccent,
        opacity: 0.22,
        focusIndices: _focusIndices,
      );
      _drawMovementVectors(canvas, snapshot);
      _drawMeasuredCoordinateTrace(
        canvas,
        animatedPoints,
        accent: targetAccent,
        opacity: 0.86,
        focusIndices: _focusIndices,
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
    RunningPoseComparisonSnapshot snapshot,
  ) {
    switch (insight.metric) {
      case RunningCoachMetric.posture:
        _drawPostureGuide(canvas, snapshot);
      case RunningCoachMetric.bounce:
        _drawBounceGuide(canvas, snapshot);
      case RunningCoachMetric.footStrike:
        _drawFootStrikeGuide(canvas, snapshot);
      case RunningCoachMetric.kneeFlexion:
        _drawJointAngleGuide(canvas, snapshot, isArm: false);
      case RunningCoachMetric.armCarriage:
        _drawJointAngleGuide(canvas, snapshot, isArm: true);
    }
  }

  void _drawPostureGuide(
    Canvas canvas,
    RunningPoseComparisonSnapshot snapshot,
  ) {
    final torso = _torso(snapshot.currentPoints);
    if (torso == null) return;
    final length = math.max(18.0, (torso.shoulder - torso.hip).distance);
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
    final verticalTop = torso.hip - Offset(0, length);
    final minPoint = torso.hip + minVector;
    final maxPoint = torso.hip + maxVector;
    final rangePaint = Paint()
      ..color = (_isGood ? successAccent : targetAccent).withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    final guidePaint = _stroke(
      _isGood ? successAccent : targetAccent,
      width: 1.6,
      opacity: 0.66,
    );
    canvas.drawPath(
      Path()
        ..moveTo(torso.hip.dx, torso.hip.dy)
        ..lineTo(minPoint.dx, minPoint.dy)
        ..lineTo(maxPoint.dx, maxPoint.dy)
        ..close(),
      rangePaint,
    );
    _drawDashedLine(
      canvas,
      verticalTop,
      torso.hip,
      _stroke(mutedColor, width: 1.2, opacity: 0.46),
    );
    _drawArc(
        canvas, torso.hip, verticalTop, minPoint, length * 0.24, guidePaint);
    _drawArc(canvas, torso.hip, minPoint, maxPoint, length * 0.29, guidePaint);
  }

  void _drawBounceGuide(
    Canvas canvas,
    RunningPoseComparisonSnapshot snapshot,
  ) {
    final torso = _torso(snapshot.currentPoints);
    if (torso == null) return;
    final currentSpan = (snapshot.panel.height * (insight.value / 100) * 2.4)
        .clamp(18.0, snapshot.panel.height * 0.44)
        .toDouble();
    final targetSpan = (snapshot.panel.height *
            (thresholds.maximumVerticalBouncePercent / 100) *
            2.4)
        .clamp(14.0, snapshot.panel.height * 0.30)
        .toDouble();
    final side =
        _annotationSign(snapshot.panel, torso.shoulder, snapshot.forward);
    final currentX = (torso.shoulder.dx + side * snapshot.panel.width * 0.08)
        .clamp(snapshot.panel.left + 18, snapshot.panel.right - 18)
        .toDouble();
    final targetX = (currentX + side * snapshot.panel.width * 0.12)
        .clamp(snapshot.panel.left + 18, snapshot.panel.right - 18)
        .toDouble();
    _drawDoubleArrow(
      canvas,
      Offset(currentX, torso.shoulder.dy - currentSpan / 2),
      Offset(currentX, torso.shoulder.dy + currentSpan / 2),
      _stroke(_isGood ? successAccent : actualAccent,
          width: 2.2, opacity: 0.72),
    );
    final targetRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(targetX, torso.shoulder.dy),
        width: 16,
        height: targetSpan,
      ),
      const Radius.circular(99),
    );
    final color = _isGood ? successAccent : targetAccent;
    canvas.drawRRect(
      targetRect,
      Paint()..color = color.withValues(alpha: 0.18),
    );
    canvas.drawRRect(targetRect, _stroke(color, width: 1.8, opacity: 0.78));
  }

  void _drawFootStrikeGuide(
    Canvas canvas,
    RunningPoseComparisonSnapshot snapshot,
  ) {
    final torso = _torso(snapshot.currentPoints);
    final leg = _leadLeg(
      snapshot.currentPoints,
      forward: snapshot.forward,
    );
    if (torso == null || leg == null) return;
    final ratioToPixels = _ratioToPixels(
      metricValue: insight.value,
      currentDistance: ((leg.toe.dx - torso.hip.dx) * snapshot.forward).abs(),
      fallbackBodyHeight: snapshot.bodyHeight,
    );
    final maxDistance = thresholds.maximumFootStrikeRatio * ratioToPixels;
    final smallBackstop = math.min(snapshot.bodyHeight * 0.035, maxDistance);
    final startX = torso.hip.dx - snapshot.forward * smallBackstop;
    final endX = torso.hip.dx + snapshot.forward * maxDistance;
    final left = math.min(startX, endX);
    final right = math.max(startX, endX);
    final color = _isGood ? successAccent : targetAccent;
    final zone = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, snapshot.groundY - 13, right, snapshot.groundY - 3),
      const Radius.circular(99),
    );
    canvas.drawRRect(
      zone,
      Paint()..color = color.withValues(alpha: 0.16),
    );
    canvas.drawRRect(zone, _stroke(color, width: 1.8, opacity: 0.78));
    _drawDashedLine(
      canvas,
      torso.hip,
      Offset(torso.hip.dx, snapshot.groundY - 5),
      _stroke(mutedColor, width: 1.2, opacity: 0.48),
    );
  }

  void _drawJointAngleGuide(
    Canvas canvas,
    RunningPoseComparisonSnapshot snapshot, {
    required bool isArm,
  }) {
    final color = _isGood ? successAccent : targetAccent;
    if (isArm) {
      final current = _leadArm(
        snapshot.currentPoints,
        forward: snapshot.forward,
      );
      final target = _leadArm(
        snapshot.targetPoints,
        forward: snapshot.forward,
      );
      if (current == null || target == null) return;
      _drawArc(
        canvas,
        current.elbow,
        current.wrist,
        target.wrist,
        math.max(12.0, (current.wrist - current.elbow).distance * 0.32),
        _stroke(color, width: 2.0, opacity: 0.76),
      );
      return;
    }

    final current = _leadLeg(
      snapshot.currentPoints,
      forward: snapshot.forward,
    );
    final target = _leadLeg(
      snapshot.targetPoints,
      forward: snapshot.forward,
    );
    if (current == null || target == null) return;
    _drawArc(
      canvas,
      current.knee,
      current.ankle,
      target.ankle,
      math.max(12.0, (current.ankle - current.knee).distance * 0.32),
      _stroke(color, width: 2.0, opacity: 0.76),
    );
  }

  void _drawAthleteArtwork(
    Canvas canvas,
    RunningPoseComparisonSnapshot snapshot,
  ) {
    final art = athleteArt;
    if (art == null) return;
    final destination = _athleteArtworkRect(snapshot);
    if (destination.isEmpty) return;
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true
      ..color = Colors.white.withValues(alpha: _isGood ? 0.94 : 0.48);

    canvas.save();
    if (snapshot.forward < 0) {
      canvas.translate(destination.center.dx * 2, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawImageRect(art, _athleteArtworkSource, destination, paint);
    canvas.restore();
  }

  Rect _athleteArtworkRect(RunningPoseComparisonSnapshot snapshot) {
    final torso = _torso(snapshot.currentPoints);
    final panel = snapshot.panel.deflate(10);
    if (torso == null || panel.isEmpty) return panel;

    final top = _poseTop(snapshot.currentPoints, fallback: panel.top);
    final naturalHeight = math.max(1.0, snapshot.groundY - top + 10);
    final sourceAspect =
        _athleteArtworkSource.width / _athleteArtworkSource.height;
    var height = naturalHeight.clamp(panel.height * 0.68, panel.height * 0.98);
    var width = height * sourceAspect;
    if (width > panel.width * 0.90) {
      width = panel.width * 0.90;
      height = width / sourceAspect;
    }

    const sourceHipFraction = 0.51;
    final visualHipFraction =
        snapshot.forward < 0 ? 1 - sourceHipFraction : sourceHipFraction;
    final left = (torso.hip.dx - width * visualHipFraction)
        .clamp(panel.left, panel.right - width)
        .toDouble();
    final placementTop = (top - height * 0.02)
        .clamp(panel.top, panel.bottom - height)
        .toDouble();
    return Rect.fromLTWH(left, placementTop, width, height);
  }

  double _poseTop(Map<int, Offset> points, {required double fallback}) {
    final candidates = <Offset>[
      for (final index in <int>[0, 7, 8, 11, 12])
        if (points[index] case final point?) point,
    ];
    if (candidates.isEmpty) return fallback;
    return candidates.map((point) => point.dy).reduce(math.min);
  }

  void _drawMeasuredCoordinateTrace(
    Canvas canvas,
    Map<int, Offset> points, {
    required Color accent,
    required double opacity,
    required Set<int> focusIndices,
  }) {
    final neutral = Color.lerp(mutedColor, Colors.white, 0.64)!;
    final neutralPaint = _stroke(
      neutral,
      width: 1.35,
      opacity: opacity * 0.22,
    );
    final accentHalo = _stroke(
      accent,
      width: 7.4,
      opacity: opacity * 0.16,
    );
    final accentPaint = _stroke(
      accent,
      width: 3.0,
      opacity: opacity,
    );

    for (final chain in _coordinateTraceChains) {
      final isFocused = chain.any(focusIndices.contains);
      if (isFocused) {
        _drawCoordinateChain(canvas, points, chain, accentHalo);
        _drawCoordinateChain(canvas, points, chain, accentPaint);
      } else {
        _drawCoordinateChain(canvas, points, chain, neutralPaint);
      }
    }

    for (final index in focusIndices) {
      final point = points[index];
      if (point == null) continue;
      canvas.drawCircle(
        point,
        7.4,
        Paint()..color = accent.withValues(alpha: opacity * 0.17),
      );
      canvas.drawCircle(
        point,
        4.0,
        Paint()..color = accent.withValues(alpha: opacity),
      );
      canvas.drawCircle(
        point,
        1.8,
        Paint()..color = surfaceColor.withValues(alpha: opacity * 0.94),
      );
    }
  }

  void _drawCoordinateChain(
    Canvas canvas,
    Map<int, Offset> points,
    List<int> chain,
    Paint paint,
  ) {
    for (var index = 0; index < chain.length - 1; index += 1) {
      final start = points[chain[index]];
      final end = points[chain[index + 1]];
      if (start == null || end == null) continue;
      canvas.drawLine(start, end, paint);
    }
  }

  void _drawMovementVectors(
    Canvas canvas,
    RunningPoseComparisonSnapshot snapshot,
  ) {
    if (!snapshot.hasMovement) return;
    final paint = _stroke(targetAccent, width: 2.2, opacity: 0.86);
    final haloPaint = _stroke(targetAccent, width: 5.2, opacity: 0.15);
    for (final index in snapshot.movedIndices) {
      if (!_focusIndices.contains(index)) continue;
      final start = snapshot.currentPoints[index];
      final end = snapshot.targetPoints[index];
      if (start == null || end == null) continue;
      final vector = end - start;
      final distance = vector.distance;
      if (distance < 2) continue;
      final unit = vector / distance;
      final trimmedStart = start + unit * math.min(7.0, distance * 0.20);
      final trimmedEnd = end - unit * math.min(7.0, distance * 0.20);
      if ((trimmedEnd - trimmedStart).distance < 1) continue;
      canvas.drawLine(trimmedStart, trimmedEnd, haloPaint);
      canvas.drawLine(trimmedStart, trimmedEnd, paint);
      _drawArrowHead(canvas, trimmedEnd, unit, paint);
    }
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
        oldDelegate.athleteArt != athleteArt ||
        oldDelegate.thresholds != thresholds;
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
