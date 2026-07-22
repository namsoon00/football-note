import 'dart:math' as math;
import 'dart:ui';

import '../../domain/entities/running_video_analysis_result.dart';

const double runningPoseOverlayMinimumJointConfidence = 0.18;
const double runningPoseOverlayMinimumConnectionConfidence = 0.24;

/// Visual styling for an anatomical pose layer derived from MediaPipe joints.
///
/// The renderer only connects measured landmarks; it does not generate or
/// reshape a person's body. This keeps the coaching overlay trustworthy when
/// a limb is occluded or only partially detected.
class RunningPoseHumanFormStyle {
  final Color bodyColor;
  final Color leftSideColor;
  final Color rightSideColor;
  final Color jointColor;
  final Color focusColor;
  final double opacity;

  const RunningPoseHumanFormStyle({
    required this.bodyColor,
    required this.leftSideColor,
    required this.rightSideColor,
    required this.jointColor,
    required this.focusColor,
    this.opacity = 1,
  });
}

/// Paints a lightweight human-form overlay from MediaPipe's measured points.
///
/// The map uses MediaPipe landmark indices. Missing points simply omit the
/// affected body part so the drawing never implies a pose the camera did not
/// observe.
void paintRunningPoseHumanForm(
  Canvas canvas, {
  required Map<int, Offset> points,
  required Size canvasSize,
  required RunningPoseHumanFormStyle style,
  Set<int> focusIndices = const <int>{},
}) {
  if (points.isEmpty || canvasSize.isEmpty) return;

  final bodyScale = _humanBodyScale(points, canvasSize);
  final opacity = style.opacity.clamp(0.0, 1.0).toDouble();
  if (opacity <= 0) return;

  // Each contour begins and ends at measured joints. The larger, rearward
  // masses are painted first to keep the overlay readable without inventing
  // an unmeasured pose.
  _drawHumanLimbs(
    canvas,
    points,
    bodyScale,
    style,
    opacity,
    focusIndices,
    segments: _humanLegSegments,
  );
  _drawHumanTorso(
    canvas,
    points,
    bodyScale,
    style,
    opacity,
    focusIndices,
  );
  _drawHumanLimbs(
    canvas,
    points,
    bodyScale,
    style,
    opacity,
    focusIndices,
    segments: _humanArmSegments,
  );
  _drawHumanHands(canvas, points, bodyScale, style, opacity, focusIndices);
  _drawHumanFeet(canvas, points, bodyScale, style, opacity, focusIndices);
  _drawHumanHead(canvas, points, bodyScale, style, opacity);
  _drawHumanFocusLandmarks(
    canvas,
    points,
    bodyScale,
    style,
    opacity,
    focusIndices,
  );
}

void _drawHumanTorso(
  Canvas canvas,
  Map<int, Offset> points,
  double bodyScale,
  RunningPoseHumanFormStyle style,
  double opacity,
  Set<int> focusIndices,
) {
  final leftShoulder = points[11];
  final rightShoulder = points[12];
  final leftHip = points[23];
  final rightHip = points[24];
  if (leftShoulder == null ||
      rightShoulder == null ||
      leftHip == null ||
      rightHip == null) {
    return;
  }

  final shoulderCenter = _humanMidpoint(leftShoulder, rightShoulder);
  final hipCenter = _humanMidpoint(leftHip, rightHip);
  final isFocused = const <int>{11, 12, 23, 24}.any(focusIndices.contains);
  final torsoColor = isFocused ? style.focusColor : style.bodyColor;
  final torsoAxis = _humanUnitVector(hipCenter - shoulderCenter);
  final leftShoulderInset = _humanLerp(leftShoulder, shoulderCenter, 0.05);
  final rightShoulderInset = _humanLerp(rightShoulder, shoulderCenter, 0.05);
  final leftHipInset = _humanLerp(leftHip, hipCenter, 0.07);
  final rightHipInset = _humanLerp(rightHip, hipCenter, 0.07);
  final leftWaist = _humanLerp(
    _humanLerp(leftShoulderInset, leftHipInset, 0.58),
    _humanLerp(shoulderCenter, hipCenter, 0.58),
    0.18,
  );
  final rightWaist = _humanLerp(
    _humanLerp(rightShoulderInset, rightHipInset, 0.58),
    _humanLerp(shoulderCenter, hipCenter, 0.58),
    0.18,
  );
  final shoulderCrest = shoulderCenter -
      _humanScale(torsoAxis, (bodyScale * 0.035).clamp(1.2, 8.0));
  final hipBase =
      hipCenter + _humanScale(torsoAxis, (bodyScale * 0.048).clamp(1.4, 11));
  final path = Path()
    ..moveTo(leftShoulderInset.dx, leftShoulderInset.dy)
    ..quadraticBezierTo(
      shoulderCrest.dx,
      shoulderCrest.dy,
      rightShoulderInset.dx,
      rightShoulderInset.dy,
    )
    ..quadraticBezierTo(
      _humanLerp(rightShoulderInset, rightWaist, 0.46).dx,
      _humanLerp(rightShoulderInset, rightWaist, 0.46).dy,
      rightWaist.dx,
      rightWaist.dy,
    )
    ..quadraticBezierTo(
      _humanLerp(rightWaist, rightHipInset, 0.48).dx,
      _humanLerp(rightWaist, rightHipInset, 0.48).dy,
      rightHipInset.dx,
      rightHipInset.dy,
    )
    ..quadraticBezierTo(
      hipBase.dx,
      hipBase.dy,
      leftHipInset.dx,
      leftHipInset.dy,
    )
    ..quadraticBezierTo(
      _humanLerp(leftHipInset, leftWaist, 0.48).dx,
      _humanLerp(leftHipInset, leftWaist, 0.48).dy,
      leftWaist.dx,
      leftWaist.dy,
    )
    ..quadraticBezierTo(
      _humanLerp(leftWaist, leftShoulderInset, 0.46).dx,
      _humanLerp(leftWaist, leftShoulderInset, 0.46).dy,
      leftShoulderInset.dx,
      leftShoulderInset.dy,
    )
    ..close();
  canvas.drawPath(
    path,
    Paint()
      ..shader = Gradient.linear(
        shoulderCenter,
        hipCenter,
        <Color>[
          style.jointColor.withValues(alpha: 0.58 * opacity),
          torsoColor.withValues(alpha: 0.64 * opacity),
          torsoColor.withValues(alpha: 0.34 * opacity),
        ],
        const <double>[0, 0.46, 1],
      )
      ..style = PaintingStyle.fill,
  );
  canvas.drawPath(
    path,
    Paint()
      ..color = torsoColor.withValues(alpha: 0.76 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bodyScale * 0.010).clamp(1.0, 2.8)
      ..strokeJoin = StrokeJoin.round,
  );
  final chestLineStart = _humanLerp(leftShoulderInset, shoulderCenter, 0.24);
  final chestLineEnd = _humanLerp(rightShoulderInset, shoulderCenter, 0.24);
  canvas.drawLine(
    chestLineStart,
    chestLineEnd,
    Paint()
      ..color = style.jointColor.withValues(alpha: 0.20 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bodyScale * 0.007).clamp(0.8, 1.8)
      ..strokeCap = StrokeCap.round,
  );
}

void _drawHumanHead(
  Canvas canvas,
  Map<int, Offset> points,
  double bodyScale,
  RunningPoseHumanFormStyle style,
  double opacity,
) {
  final nose = points[0];
  final leftEar = points[7];
  final rightEar = points[8];
  final leftShoulder = points[11];
  final rightShoulder = points[12];
  final shoulderCenter = leftShoulder != null && rightShoulder != null
      ? _humanMidpoint(leftShoulder, rightShoulder)
      : null;
  final earCenter = leftEar != null && rightEar != null
      ? _humanMidpoint(leftEar, rightEar)
      : null;
  final headAnchor = earCenter ?? nose ?? leftEar ?? rightEar;
  if (headAnchor == null || shoulderCenter == null) return;

  final earWidth = leftEar != null && rightEar != null
      ? (leftEar - rightEar).distance * 1.36
      : 0.0;
  final headWidth = earWidth > 0
      ? earWidth.clamp(bodyScale * 0.16, bodyScale * 0.34).toDouble()
      : (bodyScale * 0.25).clamp(14.0, 52.0).toDouble();
  final headHeight = headWidth * 1.30;
  final center = headAnchor;
  final headAxis = _humanUnitVector(center - shoulderCenter);
  final headSide = _humanPerpendicular(headAxis);
  final halfWidth = headWidth / 2;
  final halfHeight = headHeight / 2;
  final crown = center + _humanScale(headAxis, halfHeight * 1.02);
  final leftTemple = center +
      _humanScale(headAxis, halfHeight * 0.24) +
      _humanScale(headSide, halfWidth * 0.94);
  final leftJaw = center -
      _humanScale(headAxis, halfHeight * 0.34) +
      _humanScale(headSide, halfWidth * 0.70);
  final chin = center - _humanScale(headAxis, halfHeight * 0.82);
  final rightJaw = center -
      _humanScale(headAxis, halfHeight * 0.34) -
      _humanScale(headSide, halfWidth * 0.70);
  final rightTemple = center +
      _humanScale(headAxis, halfHeight * 0.24) -
      _humanScale(headSide, halfWidth * 0.94);
  final crownLeft = crown + _humanScale(headSide, halfWidth * 0.68);
  final crownRight = crown - _humanScale(headSide, halfWidth * 0.68);
  final headPath = Path()
    ..moveTo(crown.dx, crown.dy)
    ..cubicTo(
      crownLeft.dx,
      crownLeft.dy,
      leftTemple.dx,
      leftTemple.dy,
      leftJaw.dx,
      leftJaw.dy,
    )
    ..quadraticBezierTo(chin.dx, chin.dy, rightJaw.dx, rightJaw.dy)
    ..cubicTo(
      rightTemple.dx,
      rightTemple.dy,
      crownRight.dx,
      crownRight.dy,
      crown.dx,
      crown.dy,
    )
    ..close();

  final neckTop = center - _humanScale(headAxis, halfHeight * 0.58);
  final neckBase = shoulderCenter + _humanScale(headAxis, bodyScale * 0.025);
  final neckPath = _humanTaperedPath(
    neckBase,
    neckTop,
    (bodyScale * 0.050).clamp(2.8, 10.0).toDouble(),
    (bodyScale * 0.035).clamp(2.0, 7.0).toDouble(),
  );
  canvas.drawPath(
    neckPath,
    Paint()
      ..color = style.bodyColor.withValues(alpha: 0.54 * opacity)
      ..style = PaintingStyle.fill,
  );
  canvas.drawPath(
    neckPath,
    Paint()
      ..color = style.jointColor.withValues(alpha: 0.30 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bodyScale * 0.006).clamp(0.8, 1.6),
  );
  canvas.drawPath(
    headPath,
    Paint()
      ..shader = Gradient.linear(
        crown,
        chin,
        <Color>[
          style.jointColor.withValues(alpha: 0.76 * opacity),
          style.bodyColor.withValues(alpha: 0.62 * opacity),
          style.bodyColor.withValues(alpha: 0.36 * opacity),
        ],
        const <double>[0, 0.48, 1],
      )
      ..style = PaintingStyle.fill,
  );
  canvas.drawPath(
    headPath,
    Paint()
      ..color = style.jointColor.withValues(alpha: 0.72 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bodyScale * 0.010).clamp(0.9, 2.4),
  );
  if (nose != null && (nose - center).distance > headWidth * 0.12) {
    final faceDirection = _humanUnitVector(nose - center);
    final brow = center + _humanScale(headAxis, halfHeight * 0.10);
    final faceCue = brow + _humanScale(faceDirection, halfWidth * 0.56);
    canvas.drawLine(
      brow,
      faceCue,
      Paint()
        ..color = style.jointColor.withValues(alpha: 0.30 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (bodyScale * 0.007).clamp(0.8, 1.7)
        ..strokeCap = StrokeCap.round,
    );
  }
}

void _drawHumanLimbs(
  Canvas canvas,
  Map<int, Offset> points,
  double bodyScale,
  RunningPoseHumanFormStyle style,
  double opacity,
  Set<int> focusIndices, {
  required List<_HumanLimbSegment> segments,
}) {
  for (final segment in segments) {
    final from = points[segment.from];
    final to = points[segment.to];
    if (from == null || to == null) continue;
    final isFocused = focusIndices.contains(segment.from) &&
        focusIndices.contains(segment.to);
    final sideColor = switch (segment.side) {
      _HumanPoseSide.left => style.leftSideColor,
      _HumanPoseSide.right => style.rightSideColor,
    };
    final accent = isFocused ? style.focusColor : sideColor;
    final baseRadius = (bodyScale * 0.060).clamp(3.4, 16.0).toDouble();
    final fromRadius =
        (baseRadius * segment.fromRadiusFactor).clamp(2.8, 22.0).toDouble();
    final toRadius =
        (baseRadius * segment.toRadiusFactor).clamp(2.4, 19.0).toDouble();
    _drawHumanLimbSurface(
      canvas,
      from: from,
      to: to,
      fromRadius: fromRadius,
      toRadius: toRadius,
      bodyColor: style.bodyColor,
      accentColor: accent,
      opacity: opacity,
      isFocused: isFocused,
      bodyScale: bodyScale,
    );
  }
}

void _drawHumanLimbSurface(
  Canvas canvas, {
  required Offset from,
  required Offset to,
  required double fromRadius,
  required double toRadius,
  required Color bodyColor,
  required Color accentColor,
  required double opacity,
  required bool isFocused,
  required double bodyScale,
}) {
  if ((to - from).distance < 1) return;
  final path = _humanTaperedPath(from, to, fromRadius, toRadius);
  final direction = _humanUnitVector(to - from);
  final side = _humanPerpendicular(direction);
  final shadowOffset = Offset(0, (bodyScale * 0.012).clamp(0.8, 2.6));
  canvas.drawPath(
    path.shift(shadowOffset),
    Paint()
      ..color = const Color(0xFF050B15).withValues(alpha: 0.24 * opacity)
      ..style = PaintingStyle.fill,
  );
  canvas.drawPath(
    path,
    Paint()
      ..shader = Gradient.linear(
        from + _humanScale(side, fromRadius),
        to - _humanScale(side, toRadius),
        <Color>[
          bodyColor.withValues(alpha: 0.74 * opacity),
          accentColor.withValues(
            alpha: (isFocused ? 0.94 : 0.76) * opacity,
          ),
          accentColor.withValues(
            alpha: (isFocused ? 0.64 : 0.40) * opacity,
          ),
        ],
        const <double>[0, 0.44, 1],
      )
      ..style = PaintingStyle.fill,
  );
  canvas.drawPath(
    path,
    Paint()
      ..color = accentColor.withValues(
        alpha: (isFocused ? 0.92 : 0.54) * opacity,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bodyScale * 0.008).clamp(0.8, 2.1)
      ..strokeJoin = StrokeJoin.round,
  );
  final highlightStart = from +
      _humanScale(direction, (to - from).distance * 0.12) +
      _humanScale(side, fromRadius * 0.42);
  final highlightEnd = to -
      _humanScale(direction, (to - from).distance * 0.16) +
      _humanScale(side, toRadius * 0.35);
  canvas.drawLine(
    highlightStart,
    highlightEnd,
    Paint()
      ..color = bodyColor.withValues(alpha: 0.30 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bodyScale * 0.006).clamp(0.65, 1.5)
      ..strokeCap = StrokeCap.round,
  );
}

void _drawHumanHands(
  Canvas canvas,
  Map<int, Offset> points,
  double bodyScale,
  RunningPoseHumanFormStyle style,
  double opacity,
  Set<int> focusIndices,
) {
  for (final hand in _humanHands) {
    final elbow = points[hand.elbow];
    final wrist = points[hand.wrist];
    if (elbow == null || wrist == null) continue;
    final direction = _humanUnitVector(wrist - elbow);
    final side = _humanPerpendicular(direction);
    final palmLength = (bodyScale * 0.092).clamp(5.0, 17.0).toDouble();
    final palmRadius = (bodyScale * 0.038).clamp(2.5, 8.0).toDouble();
    final base = wrist - _humanScale(direction, palmLength * 0.20);
    final tip = wrist + _humanScale(direction, palmLength * 0.80);
    final palm = _humanTaperedPath(base, tip, palmRadius, palmRadius * 0.68);
    final isFocused = focusIndices.contains(hand.wrist);
    final sideColor = switch (hand.side) {
      _HumanPoseSide.left => style.leftSideColor,
      _HumanPoseSide.right => style.rightSideColor,
    };
    final color = isFocused ? style.focusColor : sideColor;
    canvas.drawPath(
      palm,
      Paint()
        ..color = style.bodyColor.withValues(alpha: 0.64 * opacity)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      palm,
      Paint()
        ..color = color.withValues(alpha: 0.72 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (bodyScale * 0.007).clamp(0.8, 1.7),
    );
    canvas.drawLine(
      base + _humanScale(side, palmRadius * 0.28),
      tip + _humanScale(side, palmRadius * 0.20),
      Paint()
        ..color = color.withValues(alpha: 0.36 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (bodyScale * 0.005).clamp(0.6, 1.2)
        ..strokeCap = StrokeCap.round,
    );
  }
}

void _drawHumanFeet(
  Canvas canvas,
  Map<int, Offset> points,
  double bodyScale,
  RunningPoseHumanFormStyle style,
  double opacity,
  Set<int> focusIndices,
) {
  for (final foot in _humanFeet) {
    final ankle = points[foot.ankle];
    final heel = points[foot.heel];
    final toe = points[foot.toe];
    if (ankle == null || toe == null) continue;
    final through = heel ?? ankle;
    final isFocused = focusIndices.contains(foot.ankle) &&
        (focusIndices.contains(foot.heel) || focusIndices.contains(foot.toe));
    final sideColor = switch (foot.side) {
      _HumanPoseSide.left => style.leftSideColor,
      _HumanPoseSide.right => style.rightSideColor,
    };
    final accent = isFocused ? style.focusColor : sideColor;
    final footDirection = _humanUnitVector(toe - through);
    final footSide = _humanPerpendicular(footDirection);
    final footWidth = (bodyScale * 0.048).clamp(3.2, 12.0).toDouble();
    final heelBack = through - _humanScale(footDirection, footWidth * 0.55);
    final toeFront = toe + _humanScale(footDirection, footWidth * 0.62);
    final upperAnkle = ankle + _humanScale(footSide, footWidth * 0.42);
    final lowerAnkle = ankle - _humanScale(footSide, footWidth * 0.42);
    final path = Path()
      ..moveTo(upperAnkle.dx, upperAnkle.dy)
      ..quadraticBezierTo(
        (through + _humanScale(footSide, footWidth * 0.56)).dx,
        (through + _humanScale(footSide, footWidth * 0.56)).dy,
        (toe + _humanScale(footSide, footWidth * 0.48)).dx,
        (toe + _humanScale(footSide, footWidth * 0.48)).dy,
      )
      ..quadraticBezierTo(
        toeFront.dx,
        toeFront.dy,
        (toe - _humanScale(footSide, footWidth * 0.46)).dx,
        (toe - _humanScale(footSide, footWidth * 0.46)).dy,
      )
      ..quadraticBezierTo(
        (heelBack - _humanScale(footSide, footWidth * 0.42)).dx,
        (heelBack - _humanScale(footSide, footWidth * 0.42)).dy,
        lowerAnkle.dx,
        lowerAnkle.dy,
      )
      ..quadraticBezierTo(
        heelBack.dx,
        heelBack.dy,
        upperAnkle.dx,
        upperAnkle.dy,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = Gradient.linear(
          upperAnkle,
          toeFront,
          <Color>[
            style.bodyColor.withValues(alpha: 0.66 * opacity),
            accent.withValues(alpha: (isFocused ? 0.94 : 0.72) * opacity),
            accent.withValues(alpha: 0.42 * opacity),
          ],
          const <double>[0, 0.48, 1],
        )
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withValues(
          alpha: (isFocused ? 0.94 : 0.58) * opacity,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = (bodyScale * 0.008).clamp(0.8, 2.0)
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawLine(
      ankle,
      toe,
      Paint()
        ..color = style.bodyColor.withValues(alpha: 0.24 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (bodyScale * 0.006).clamp(0.6, 1.4)
        ..strokeCap = StrokeCap.round,
    );
  }
}

void _drawHumanFocusLandmarks(
  Canvas canvas,
  Map<int, Offset> points,
  double bodyScale,
  RunningPoseHumanFormStyle style,
  double opacity,
  Set<int> focusIndices,
) {
  if (focusIndices.isEmpty) return;
  final radius = (bodyScale * 0.026).clamp(2.8, 8.0).toDouble();
  for (final index in focusIndices) {
    final point = points[index];
    if (point == null) continue;
    canvas.drawCircle(
      point,
      radius * 2.15,
      Paint()
        ..color = style.focusColor.withValues(alpha: 0.16 * opacity)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      point,
      radius * 1.28,
      Paint()
        ..color = style.focusColor.withValues(alpha: 0.90 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (bodyScale * 0.008).clamp(0.8, 2.0),
    );
    canvas.drawCircle(
      point,
      radius * 0.42,
      Paint()
        ..color = style.jointColor.withValues(alpha: 0.94 * opacity)
        ..style = PaintingStyle.fill,
    );
  }
}

Path _humanTaperedPath(
  Offset from,
  Offset to,
  double fromRadius,
  double toRadius,
) {
  final direction = _humanUnitVector(to - from);
  final side = _humanPerpendicular(direction);
  final distance = (to - from).distance;
  final averageRadius = (fromRadius + toRadius) / 2;
  final contourBend = math.min(distance * 0.12, averageRadius * 0.72);
  final fromUpper = from + _humanScale(side, fromRadius);
  final fromLower = from - _humanScale(side, fromRadius);
  final toUpper = to + _humanScale(side, toRadius);
  final toLower = to - _humanScale(side, toRadius);
  final fromCap = from - _humanScale(direction, fromRadius * 0.48);
  final toCap = to + _humanScale(direction, toRadius * 0.48);
  final center = _humanMidpoint(from, to);

  return Path()
    ..moveTo(fromUpper.dx, fromUpper.dy)
    ..quadraticBezierTo(
      (center + _humanScale(side, averageRadius + contourBend * 0.18)).dx,
      (center + _humanScale(side, averageRadius + contourBend * 0.18)).dy,
      toUpper.dx,
      toUpper.dy,
    )
    ..quadraticBezierTo(toCap.dx, toCap.dy, toLower.dx, toLower.dy)
    ..quadraticBezierTo(
      (center - _humanScale(side, averageRadius + contourBend * 0.18)).dx,
      (center - _humanScale(side, averageRadius + contourBend * 0.18)).dy,
      fromLower.dx,
      fromLower.dy,
    )
    ..quadraticBezierTo(fromCap.dx, fromCap.dy, fromUpper.dx, fromUpper.dy)
    ..close();
}

double _humanBodyScale(Map<int, Offset> points, Size canvasSize) {
  final shoulderCenter = _humanMidpointFor(points, 11, 12);
  final hipCenter = _humanMidpointFor(points, 23, 24);
  final ankleCenter = _humanMidpointFor(points, 27, 28);
  if (shoulderCenter != null && hipCenter != null && ankleCenter != null) {
    return math.max(
      (shoulderCenter - hipCenter).distance,
      (hipCenter - ankleCenter).distance,
    );
  }
  if (points.length >= 2) {
    final xs = points.values.map((point) => point.dx);
    final ys = points.values.map((point) => point.dy);
    return math.max(
      1,
      math.max(
        xs.reduce(math.max) - xs.reduce(math.min),
        ys.reduce(math.max) - ys.reduce(math.min),
      ),
    );
  }
  return math.max(1, canvasSize.shortestSide * 0.22);
}

Offset? _humanMidpointFor(Map<int, Offset> points, int first, int second) {
  final firstPoint = points[first];
  final secondPoint = points[second];
  if (firstPoint == null || secondPoint == null) return null;
  return _humanMidpoint(firstPoint, secondPoint);
}

Offset _humanMidpoint(Offset first, Offset second) =>
    Offset((first.dx + second.dx) / 2, (first.dy + second.dy) / 2);

Offset _humanLerp(Offset first, Offset second, double t) =>
    Offset.lerp(first, second, t)!;

Offset _humanScale(Offset vector, double scale) =>
    Offset(vector.dx * scale, vector.dy * scale);

Offset _humanUnitVector(Offset vector) {
  final length = vector.distance;
  if (length < 0.001) return const Offset(0, -1);
  return Offset(vector.dx / length, vector.dy / length);
}

Offset _humanPerpendicular(Offset vector) => Offset(-vector.dy, vector.dx);

enum _HumanPoseSide { left, right }

class _HumanLimbSegment {
  final int from;
  final int to;
  final _HumanPoseSide side;
  final double fromRadiusFactor;
  final double toRadiusFactor;

  const _HumanLimbSegment(
    this.from,
    this.to,
    this.side, {
    required this.fromRadiusFactor,
    required this.toRadiusFactor,
  });
}

class _HumanHand {
  final int elbow;
  final int wrist;
  final _HumanPoseSide side;

  const _HumanHand(this.elbow, this.wrist, this.side);
}

class _HumanFoot {
  final int ankle;
  final int heel;
  final int toe;
  final _HumanPoseSide side;

  const _HumanFoot(this.ankle, this.heel, this.toe, this.side);
}

const _humanArmSegments = <_HumanLimbSegment>[
  _HumanLimbSegment(
    11,
    13,
    _HumanPoseSide.left,
    fromRadiusFactor: 0.80,
    toRadiusFactor: 0.70,
  ),
  _HumanLimbSegment(
    13,
    15,
    _HumanPoseSide.left,
    fromRadiusFactor: 0.64,
    toRadiusFactor: 0.52,
  ),
  _HumanLimbSegment(
    12,
    14,
    _HumanPoseSide.right,
    fromRadiusFactor: 0.80,
    toRadiusFactor: 0.70,
  ),
  _HumanLimbSegment(
    14,
    16,
    _HumanPoseSide.right,
    fromRadiusFactor: 0.64,
    toRadiusFactor: 0.52,
  ),
];

const _humanLegSegments = <_HumanLimbSegment>[
  _HumanLimbSegment(
    23,
    25,
    _HumanPoseSide.left,
    fromRadiusFactor: 1.28,
    toRadiusFactor: 1.00,
  ),
  _HumanLimbSegment(
    25,
    27,
    _HumanPoseSide.left,
    fromRadiusFactor: 0.94,
    toRadiusFactor: 0.72,
  ),
  _HumanLimbSegment(
    24,
    26,
    _HumanPoseSide.right,
    fromRadiusFactor: 1.28,
    toRadiusFactor: 1.00,
  ),
  _HumanLimbSegment(
    26,
    28,
    _HumanPoseSide.right,
    fromRadiusFactor: 0.94,
    toRadiusFactor: 0.72,
  ),
];

const _humanHands = <_HumanHand>[
  _HumanHand(13, 15, _HumanPoseSide.left),
  _HumanHand(14, 16, _HumanPoseSide.right),
];

const _humanFeet = <_HumanFoot>[
  _HumanFoot(27, 29, 31, _HumanPoseSide.left),
  _HumanFoot(28, 30, 32, _HumanPoseSide.right),
];

RunningPoseFrame? runningPoseFrameAtPosition({
  required List<RunningPoseFrame> frames,
  required Duration position,
}) {
  final sortedFrames = frames
      .where((frame) => frame.landmarks.length == mediaPipePoseLandmarkCount)
      .toList(growable: false)
    ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
  if (sortedFrames.isEmpty) return null;

  final targetMs = position.inMilliseconds;
  if (sortedFrames.length == 1) {
    return sortedFrames.first;
  }

  final medianIntervalMs = _medianIntervalMs(sortedFrames);
  final halfIntervalMs = math.max(1, (medianIntervalMs / 2).round());
  final bracket = _bracketFrames(sortedFrames, targetMs, halfIntervalMs);
  if (bracket == null) return null;

  final baseFrame = _interpolateFrame(bracket.$1, bracket.$2, targetMs);
  return _smoothFrame(
    baseFrame,
    sortedFrames,
    targetMs,
    smoothingWindowMs: medianIntervalMs,
  );
}

Offset runningPoseCoverOffset({
  required RunningVideoPoseLandmark landmark,
  required int imageWidth,
  required int imageHeight,
  required Size outputSize,
}) {
  if (imageWidth <= 0 || imageHeight <= 0 || outputSize.isEmpty) {
    return Offset.zero;
  }
  final scale = math.max(
    outputSize.width / imageWidth,
    outputSize.height / imageHeight,
  );
  final displayWidth = imageWidth * scale;
  final displayHeight = imageHeight * scale;
  final dx = (outputSize.width - displayWidth) / 2;
  final dy = (outputSize.height - displayHeight) / 2;
  return Offset(
    dx + (landmark.x * imageWidth * scale),
    dy + (landmark.y * imageHeight * scale),
  );
}

/// Maps a normalized pose point into a video area rendered with BoxFit.contain.
/// Evidence playback intentionally preserves the whole frame so coaching marks
/// stay aligned even when the source and panel aspect ratios differ.
Offset runningPoseContainOffset({
  required RunningVideoPoseLandmark landmark,
  required int imageWidth,
  required int imageHeight,
  required Size outputSize,
}) {
  if (imageWidth <= 0 || imageHeight <= 0 || outputSize.isEmpty) {
    return Offset.zero;
  }
  final scale = math.min(
    outputSize.width / imageWidth,
    outputSize.height / imageHeight,
  );
  final displayWidth = imageWidth * scale;
  final displayHeight = imageHeight * scale;
  final dx = (outputSize.width - displayWidth) / 2;
  final dy = (outputSize.height - displayHeight) / 2;
  return Offset(
    dx + (landmark.x * imageWidth * scale),
    dy + (landmark.y * imageHeight * scale),
  );
}

int? nearestRunningPoseFrameIndex({
  required List<RunningPoseFrame> frames,
  required Duration position,
}) {
  if (frames.isEmpty) return null;
  final targetMs = position.inMilliseconds;
  var bestIndex = 0;
  var bestDistance = (frames.first.timestampMs - targetMs).abs();
  for (var index = 1; index < frames.length; index += 1) {
    final distance = (frames[index].timestampMs - targetMs).abs();
    if (distance < bestDistance) {
      bestDistance = distance;
      bestIndex = index;
    }
  }
  return bestIndex;
}

(RunningPoseFrame, RunningPoseFrame)? _bracketFrames(
  List<RunningPoseFrame> frames,
  int targetMs,
  int halfIntervalMs,
) {
  final first = frames.first;
  if (targetMs <= first.timestampMs) {
    return (first.timestampMs - targetMs).abs() <= halfIntervalMs
        ? (first, first)
        : null;
  }

  final last = frames.last;
  if (targetMs >= last.timestampMs) {
    return (targetMs - last.timestampMs).abs() <= halfIntervalMs
        ? (last, last)
        : null;
  }

  for (var index = 0; index < frames.length - 1; index += 1) {
    final current = frames[index];
    final next = frames[index + 1];
    if (targetMs >= current.timestampMs && targetMs <= next.timestampMs) {
      return (current, next);
    }
  }
  return null;
}

RunningPoseFrame _interpolateFrame(
  RunningPoseFrame first,
  RunningPoseFrame second,
  int targetMs,
) {
  if (first.timestampMs == second.timestampMs) return first;
  final t = ((targetMs - first.timestampMs) /
          (second.timestampMs - first.timestampMs))
      .clamp(0.0, 1.0)
      .toDouble();
  final landmarks = <RunningVideoPoseLandmark>[];
  for (var index = 0; index < mediaPipePoseLandmarkCount; index += 1) {
    final a = first.landmarkByIndex(index);
    final b = second.landmarkByIndex(index);
    if (a == null || b == null) {
      return first;
    }
    landmarks.add(_lerpLandmark(a, b, t));
  }
  return RunningPoseFrame(
    timestamp: Duration(milliseconds: targetMs),
    imageWidth: first.imageWidth,
    imageHeight: first.imageHeight,
    landmarks: List<RunningVideoPoseLandmark>.unmodifiable(landmarks),
  );
}

RunningPoseFrame _smoothFrame(
  RunningPoseFrame baseFrame,
  List<RunningPoseFrame> sourceFrames,
  int targetMs, {
  required int smoothingWindowMs,
}) {
  final windowMs = math.max(1, smoothingWindowMs);
  final nearby = sourceFrames
      .where((frame) => (frame.timestampMs - targetMs).abs() <= windowMs)
      .toList(growable: false);
  if (nearby.isEmpty) return baseFrame;

  final smoothed = <RunningVideoPoseLandmark>[];
  for (var index = 0; index < mediaPipePoseLandmarkCount; index += 1) {
    final base = baseFrame.landmarkByIndex(index);
    if (base == null) return baseFrame;

    var totalWeight = 1.0 + base.confidence;
    var x = base.x * totalWeight;
    var y = base.y * totalWeight;
    var z = base.z * totalWeight;
    var visibility = (base.visibility ?? 0) * totalWeight;
    var visibilityWeight = base.visibility == null ? 0.0 : totalWeight;
    var presence = (base.presence ?? 0) * totalWeight;
    var presenceWeight = base.presence == null ? 0.0 : totalWeight;
    var confidence = base.confidence * totalWeight;

    for (final frame in nearby) {
      final landmark = frame.landmarkByIndex(index);
      if (landmark == null) continue;
      final distanceRatio = ((frame.timestampMs - targetMs).abs() / windowMs)
          .clamp(0.0, 1.0)
          .toDouble();
      final temporalWeight = 1.0 - distanceRatio;
      if (temporalWeight <= 0) continue;
      final confidenceWeight = landmark.confidence.clamp(0.05, 1.0).toDouble();
      final weight = 0.45 * temporalWeight * confidenceWeight;
      totalWeight += weight;
      x += landmark.x * weight;
      y += landmark.y * weight;
      z += landmark.z * weight;
      confidence += landmark.confidence * weight;
      if (landmark.visibility != null) {
        visibility += landmark.visibility! * weight;
        visibilityWeight += weight;
      }
      if (landmark.presence != null) {
        presence += landmark.presence! * weight;
        presenceWeight += weight;
      }
    }

    smoothed.add(
      RunningVideoPoseLandmark(
        index: index,
        x: x / totalWeight,
        y: y / totalWeight,
        z: z / totalWeight,
        visibility:
            visibilityWeight <= 0 ? null : visibility / visibilityWeight,
        presence: presenceWeight <= 0 ? null : presence / presenceWeight,
        confidence: (confidence / totalWeight).clamp(0.0, 1.0).toDouble(),
      ),
    );
  }

  return RunningPoseFrame(
    timestamp: baseFrame.timestamp,
    imageWidth: baseFrame.imageWidth,
    imageHeight: baseFrame.imageHeight,
    landmarks: List<RunningVideoPoseLandmark>.unmodifiable(smoothed),
  );
}

RunningVideoPoseLandmark _lerpLandmark(
  RunningVideoPoseLandmark first,
  RunningVideoPoseLandmark second,
  double t,
) {
  return RunningVideoPoseLandmark(
    index: first.index,
    x: _lerpDouble(first.x, second.x, t),
    y: _lerpDouble(first.y, second.y, t),
    z: _lerpDouble(first.z, second.z, t),
    visibility: _lerpNullable(first.visibility, second.visibility, t),
    presence: _lerpNullable(first.presence, second.presence, t),
    confidence: _lerpDouble(first.confidence, second.confidence, t)
        .clamp(0.0, 1.0)
        .toDouble(),
  );
}

int _medianIntervalMs(List<RunningPoseFrame> frames) {
  final intervals = <int>[];
  for (var index = 0; index < frames.length - 1; index += 1) {
    final interval = frames[index + 1].timestampMs - frames[index].timestampMs;
    if (interval > 0) {
      intervals.add(interval);
    }
  }
  if (intervals.isEmpty) return 1;
  intervals.sort();
  return intervals[intervals.length ~/ 2];
}

double _lerpDouble(double a, double b, double t) => a + ((b - a) * t);

double? _lerpNullable(double? a, double? b, double t) {
  if (a == null && b == null) return null;
  if (a == null) return b;
  if (b == null) return a;
  return _lerpDouble(a, b, t);
}
