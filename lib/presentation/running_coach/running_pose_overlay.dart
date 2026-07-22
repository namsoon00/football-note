import 'dart:math' as math;
import 'dart:ui';

import '../../domain/entities/running_video_analysis_result.dart';

const double runningPoseOverlayMinimumJointConfidence = 0.18;
const double runningPoseOverlayMinimumConnectionConfidence = 0.24;

/// Visual styling for an anatomical pose layer derived from MediaPipe joints.
///
/// The geometry follows measured landmarks. Optional colors distinguish a
/// generic sports avatar from a skeleton without implying the runner's real
/// appearance when a limb is occluded or only partially detected.
class RunningPoseHumanFormStyle {
  final Color bodyColor;
  final Color leftSideColor;
  final Color rightSideColor;
  final Color jointColor;
  final Color focusColor;
  final Color? skinColor;
  final Color? apparelColor;
  final Color? shortsColor;
  final Color? shoeColor;
  final Color? hairColor;
  final double opacity;

  const RunningPoseHumanFormStyle({
    required this.bodyColor,
    required this.leftSideColor,
    required this.rightSideColor,
    required this.jointColor,
    required this.focusColor,
    this.skinColor,
    this.apparelColor,
    this.shortsColor,
    this.shoeColor,
    this.hairColor,
    this.opacity = 1,
  });

  Color get resolvedSkinColor => skinColor ?? bodyColor;
  Color get resolvedApparelColor => apparelColor ?? bodyColor;
  Color get resolvedShortsColor => shortsColor ?? resolvedApparelColor;
  Color get resolvedShoeColor => shoeColor ?? rightSideColor;
  Color get resolvedHairColor => hairColor ?? leftSideColor;
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
  _drawHumanShorts(canvas, points, bodyScale, style, opacity);
  _drawHumanLimbs(
    canvas,
    points,
    bodyScale,
    style,
    opacity,
    focusIndices,
    segments: _humanArmSegments,
  );
  _drawHumanJointBlends(canvas, points, bodyScale, style, opacity);
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
  final torsoColor = style.resolvedApparelColor;
  final contourColor = isFocused ? style.focusColor : style.jointColor;
  final torsoAxis = _humanUnitVector(hipCenter - shoulderCenter);
  final leftShoulderInset = _humanLerp(leftShoulder, shoulderCenter, 0.025);
  final rightShoulderInset = _humanLerp(rightShoulder, shoulderCenter, 0.025);
  final leftHipInset = _humanLerp(leftHip, hipCenter, 0.05);
  final rightHipInset = _humanLerp(rightHip, hipCenter, 0.05);
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
        leftShoulderInset,
        rightShoulderInset,
        <Color>[
          _humanLighten(torsoColor, 0.12).withValues(alpha: 0.94 * opacity),
          torsoColor.withValues(alpha: 0.88 * opacity),
          _humanDarken(torsoColor, 0.12).withValues(alpha: 0.82 * opacity),
        ],
        const <double>[0, 0.48, 1],
      )
      ..style = PaintingStyle.fill,
  );
  canvas.drawPath(
    path,
    Paint()
      ..color = contourColor.withValues(
        alpha: (isFocused ? 0.42 : 0.30) * opacity,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bodyScale * 0.007).clamp(0.75, 1.9)
      ..strokeJoin = StrokeJoin.round,
  );
  final chestLineStart = _humanLerp(leftShoulderInset, shoulderCenter, 0.24);
  final chestLineEnd = _humanLerp(rightShoulderInset, shoulderCenter, 0.24);
  canvas.drawLine(
    chestLineStart,
    chestLineEnd,
    Paint()
      ..color = style.jointColor.withValues(alpha: 0.16 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bodyScale * 0.005).clamp(0.6, 1.2)
      ..strokeCap = StrokeCap.round,
  );
  final collarCenter = shoulderCenter +
      _humanScale(torsoAxis, (bodyScale * 0.040).clamp(1.5, 9.0));
  final shoulderSpan = (leftShoulderInset - rightShoulderInset).distance;
  final collarSide = _humanPerpendicular(torsoAxis);
  final collarWidth = math.min(shoulderSpan * 0.19, bodyScale * 0.19);
  final collarDepth = (bodyScale * 0.052).clamp(2.0, 11.0);
  final collarLeft = collarCenter + _humanScale(collarSide, collarWidth);
  final collarRight = collarCenter - _humanScale(collarSide, collarWidth);
  final collarBase = collarCenter + _humanScale(torsoAxis, collarDepth);
  final collar = Path()
    ..moveTo(collarLeft.dx, collarLeft.dy)
    ..quadraticBezierTo(
      collarCenter.dx,
      collarCenter.dy + (collarDepth * 0.72),
      collarRight.dx,
      collarRight.dy,
    )
    ..quadraticBezierTo(
      collarCenter.dx,
      collarBase.dy,
      collarLeft.dx,
      collarLeft.dy,
    )
    ..close();
  canvas.drawPath(
    collar,
    Paint()
      ..color = _humanDarken(torsoColor, 0.24).withValues(alpha: 0.48 * opacity)
      ..style = PaintingStyle.fill,
  );
}

void _drawHumanShorts(
  Canvas canvas,
  Map<int, Offset> points,
  double bodyScale,
  RunningPoseHumanFormStyle style,
  double opacity,
) {
  final leftHip = points[23];
  final rightHip = points[24];
  final leftKnee = points[25];
  final rightKnee = points[26];
  if (leftHip == null ||
      rightHip == null ||
      leftKnee == null ||
      rightKnee == null) {
    return;
  }

  final hipCenter = _humanMidpoint(leftHip, rightHip);
  final kneeCenter = _humanMidpoint(leftKnee, rightKnee);
  final axis = _humanUnitVector(kneeCenter - hipCenter);
  final leftHem = _humanLerp(leftHip, leftKnee, 0.26);
  final rightHem = _humanLerp(rightHip, rightKnee, 0.26);
  final upperCrotch =
      hipCenter + _humanScale(axis, (bodyScale * 0.026).clamp(1.3, 5.4));
  final crotch =
      hipCenter + _humanScale(axis, (bodyScale * 0.082).clamp(3.2, 15.0));
  final leftInnerHem = _humanLerp(leftHem, crotch, 0.18);
  final rightInnerHem = _humanLerp(rightHem, crotch, 0.18);
  final leftShort = Path()
    ..moveTo(leftHip.dx, leftHip.dy)
    ..quadraticBezierTo(
      _humanLerp(leftHip, leftHem, 0.42).dx,
      _humanLerp(leftHip, leftHem, 0.42).dy,
      leftHem.dx,
      leftHem.dy,
    )
    ..quadraticBezierTo(
      _humanLerp(leftHem, leftInnerHem, 0.54).dx,
      _humanLerp(leftHem, leftInnerHem, 0.54).dy,
      leftInnerHem.dx,
      leftInnerHem.dy,
    )
    ..quadraticBezierTo(
      crotch.dx,
      crotch.dy,
      upperCrotch.dx,
      upperCrotch.dy,
    )
    ..quadraticBezierTo(
      _humanLerp(upperCrotch, leftHip, 0.54).dx,
      _humanLerp(upperCrotch, leftHip, 0.54).dy,
      leftHip.dx,
      leftHip.dy,
    )
    ..close();
  final rightShort = Path()
    ..moveTo(upperCrotch.dx, upperCrotch.dy)
    ..quadraticBezierTo(
      crotch.dx,
      crotch.dy,
      rightInnerHem.dx,
      rightInnerHem.dy,
    )
    ..quadraticBezierTo(
      _humanLerp(rightInnerHem, rightHem, 0.46).dx,
      _humanLerp(rightInnerHem, rightHem, 0.46).dy,
      rightHem.dx,
      rightHem.dy,
    )
    ..quadraticBezierTo(
      _humanLerp(rightHem, rightHip, 0.58).dx,
      _humanLerp(rightHem, rightHip, 0.58).dy,
      rightHip.dx,
      rightHip.dy,
    )
    ..quadraticBezierTo(
      _humanLerp(rightHip, upperCrotch, 0.46).dx,
      _humanLerp(rightHip, upperCrotch, 0.46).dy,
      upperCrotch.dx,
      upperCrotch.dy,
    )
    ..close();
  final apparel = style.resolvedShortsColor;
  for (final shorts in <Path>[leftShort, rightShort]) {
    canvas.drawPath(
      shorts,
      Paint()
        ..shader = Gradient.linear(
          hipCenter,
          crotch,
          <Color>[
            _humanLighten(apparel, 0.08).withValues(alpha: 0.96 * opacity),
            apparel.withValues(alpha: 0.90 * opacity),
            _humanDarken(apparel, 0.12).withValues(alpha: 0.82 * opacity),
          ],
          const <double>[0, 0.52, 1],
        )
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      shorts,
      Paint()
        ..color = style.jointColor.withValues(alpha: 0.14 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (bodyScale * 0.004).clamp(0.45, 1.0)
        ..strokeJoin = StrokeJoin.round,
    );
  }
  canvas.drawLine(
    leftHip,
    rightHip,
    Paint()
      ..color = _humanDarken(apparel, 0.24).withValues(alpha: 0.42 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bodyScale * 0.007).clamp(0.75, 1.6)
      ..strokeCap = StrokeCap.round,
  );
  canvas.drawLine(
    upperCrotch,
    crotch,
    Paint()
      ..color = style.jointColor.withValues(alpha: 0.20 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bodyScale * 0.004).clamp(0.45, 0.95)
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
  final leftHip = points[23];
  final rightHip = points[24];
  final shoulderCenter = leftShoulder != null && rightShoulder != null
      ? _humanMidpoint(leftShoulder, rightShoulder)
      : null;
  final hipCenter = leftHip != null && rightHip != null
      ? _humanMidpoint(leftHip, rightHip)
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
      ? earWidth.clamp(bodyScale * 0.21, bodyScale * 0.35).toDouble()
      : (bodyScale * 0.27).clamp(16.0, 54.0).toDouble();
  final headHeight = headWidth * 1.18;
  final rawHeadVector = headAnchor - shoulderCenter;
  final rawHeadDistance = rawHeadVector.distance;
  final torsoLength = hipCenter == null
      ? bodyScale * 0.52
      : (hipCenter - shoulderCenter).distance;
  // Facial landmarks can sit noticeably above the shoulder points in a small
  // or blurred frame. Limit only the avatar connector so the head and neck do
  // not become detached; the coaching metrics keep the original landmarks.
  final maxHeadCenterDistance = math.max(
    headHeight * 0.84,
    torsoLength * 0.34,
  );
  final center = rawHeadDistance > maxHeadCenterDistance
      ? shoulderCenter +
          _humanScale(
            _humanUnitVector(rawHeadVector),
            maxHeadCenterDistance,
          )
      : headAnchor;
  final skinColor = style.resolvedSkinColor;
  final hairColor = style.resolvedHairColor;
  final headAxis = _humanUnitVector(center - shoulderCenter);
  final headSide = _humanPerpendicular(headAxis);
  final halfWidth = headWidth / 2;
  final halfHeight = headHeight / 2;
  final crown = center + _humanScale(headAxis, halfHeight * 0.90);
  final leftTemple = center +
      _humanScale(headAxis, halfHeight * 0.13) +
      _humanScale(headSide, halfWidth * 0.94);
  final leftJaw = center -
      _humanScale(headAxis, halfHeight * 0.24) +
      _humanScale(headSide, halfWidth * 0.78);
  final chin = center - _humanScale(headAxis, halfHeight * 0.70);
  final rightJaw = center -
      _humanScale(headAxis, halfHeight * 0.24) -
      _humanScale(headSide, halfWidth * 0.78);
  final rightTemple = center +
      _humanScale(headAxis, halfHeight * 0.13) -
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
  final hairLeft = center +
      _humanScale(headAxis, halfHeight * 0.015) +
      _humanScale(headSide, halfWidth * 0.84);
  final hairRight = center +
      _humanScale(headAxis, halfHeight * 0.015) -
      _humanScale(headSide, halfWidth * 0.84);
  final hairPath = Path()
    ..moveTo(crown.dx, crown.dy)
    ..quadraticBezierTo(leftTemple.dx, leftTemple.dy, hairLeft.dx, hairLeft.dy)
    ..quadraticBezierTo(
      (center + _humanScale(headAxis, halfHeight * 0.12)).dx,
      (center + _humanScale(headAxis, halfHeight * 0.12)).dy,
      hairRight.dx,
      hairRight.dy,
    )
    ..quadraticBezierTo(
      rightTemple.dx,
      rightTemple.dy,
      crown.dx,
      crown.dy,
    )
    ..close();

  final neckTop = center - _humanScale(headAxis, halfHeight * 0.48);
  final neckBase = shoulderCenter + _humanScale(headAxis, bodyScale * 0.012);
  final neckPath = _humanTaperedPath(
    neckBase,
    neckTop,
    (bodyScale * 0.054).clamp(3.0, 10.0).toDouble(),
    (bodyScale * 0.039).clamp(2.3, 7.4).toDouble(),
  );
  final earRadius = (headWidth * 0.12).clamp(2.0, 7.0).toDouble();
  final leftEarCenter = center -
      _humanScale(headAxis, halfHeight * 0.03) +
      _humanScale(headSide, halfWidth * 0.91);
  final rightEarCenter = center -
      _humanScale(headAxis, halfHeight * 0.03) -
      _humanScale(headSide, halfWidth * 0.91);
  for (final ear in <Offset>[leftEarCenter, rightEarCenter]) {
    canvas.drawCircle(
      ear,
      earRadius,
      Paint()
        ..color =
            _humanDarken(skinColor, 0.05).withValues(alpha: 0.86 * opacity)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      ear,
      earRadius,
      Paint()
        ..color = style.jointColor.withValues(alpha: 0.18 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (bodyScale * 0.0035).clamp(0.35, 0.8),
    );
  }
  canvas.drawPath(
    neckPath,
    Paint()
      ..shader = Gradient.linear(
        neckBase + _humanScale(headSide, bodyScale * 0.04),
        neckBase - _humanScale(headSide, bodyScale * 0.04),
        <Color>[
          _humanLighten(skinColor, 0.08).withValues(alpha: 0.94 * opacity),
          _humanDarken(skinColor, 0.10).withValues(alpha: 0.84 * opacity),
        ],
      )
      ..style = PaintingStyle.fill,
  );
  canvas.drawPath(
    neckPath,
    Paint()
      ..color = style.jointColor.withValues(alpha: 0.20 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bodyScale * 0.005).clamp(0.6, 1.2),
  );
  canvas.drawPath(
    headPath,
    Paint()
      ..shader = Gradient.linear(
        leftTemple,
        rightTemple,
        <Color>[
          _humanLighten(skinColor, 0.12).withValues(alpha: 0.98 * opacity),
          skinColor.withValues(alpha: 0.92 * opacity),
          _humanDarken(skinColor, 0.11).withValues(alpha: 0.80 * opacity),
        ],
        const <double>[0, 0.52, 1],
      )
      ..style = PaintingStyle.fill,
  );
  canvas.drawPath(
    hairPath,
    Paint()
      ..color = hairColor.withValues(alpha: 0.88 * opacity)
      ..style = PaintingStyle.fill,
  );
  canvas.drawPath(
    headPath,
    Paint()
      ..color = style.jointColor.withValues(alpha: 0.30 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bodyScale * 0.006).clamp(0.65, 1.5),
  );
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
    final fillColor = switch (segment.material) {
      _HumanFormMaterial.skin => style.resolvedSkinColor,
      _HumanFormMaterial.apparel => style.resolvedApparelColor,
    };
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
      bodyColor: fillColor,
      accentColor: sideColor,
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
  canvas.drawPath(
    path,
    Paint()
      ..shader = Gradient.linear(
        from + _humanScale(side, fromRadius),
        from - _humanScale(side, fromRadius),
        <Color>[
          _humanLighten(bodyColor, 0.14).withValues(alpha: 0.96 * opacity),
          bodyColor.withValues(alpha: 0.90 * opacity),
          _humanDarken(bodyColor, 0.12).withValues(alpha: 0.82 * opacity),
        ],
        const <double>[0, 0.48, 1],
      )
      ..style = PaintingStyle.fill,
  );
  canvas.drawPath(
    path,
    Paint()
      ..color = accentColor.withValues(
        alpha: (isFocused ? 0.30 : 0.14) * opacity,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bodyScale * 0.005).clamp(0.55, 1.3)
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
      ..color = bodyColor.withValues(alpha: 0.16 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bodyScale * 0.004).clamp(0.45, 1.0)
      ..strokeCap = StrokeCap.round,
  );
}

void _drawHumanJointBlends(
  Canvas canvas,
  Map<int, Offset> points,
  double bodyScale,
  RunningPoseHumanFormStyle style,
  double opacity,
) {
  final blendRadius = (bodyScale * 0.047).clamp(2.8, 11.0).toDouble();
  for (final joint in _humanJointBlends) {
    final previous = points[joint.previous];
    final center = points[joint.center];
    final next = points[joint.next];
    if (previous == null || center == null || next == null) continue;

    final incoming = _humanUnitVector(center - previous);
    final outgoing = _humanUnitVector(next - center);
    final axis = _humanUnitVector(incoming + outgoing);
    final side = _humanPerpendicular(axis);
    final sideColor = switch (joint.side) {
      _HumanPoseSide.left => style.leftSideColor,
      _HumanPoseSide.right => style.rightSideColor,
    };
    final fillColor = switch (joint.material) {
      _HumanFormMaterial.skin => style.resolvedSkinColor,
      _HumanFormMaterial.apparel => style.resolvedApparelColor,
    };
    final blend = Path()
      ..moveTo(
        (center + _humanScale(side, blendRadius * 0.86)).dx,
        (center + _humanScale(side, blendRadius * 0.86)).dy,
      )
      ..quadraticBezierTo(
        (center + _humanScale(axis, blendRadius * 0.68)).dx,
        (center + _humanScale(axis, blendRadius * 0.68)).dy,
        (center - _humanScale(side, blendRadius * 0.86)).dx,
        (center - _humanScale(side, blendRadius * 0.86)).dy,
      )
      ..quadraticBezierTo(
        (center - _humanScale(axis, blendRadius * 0.68)).dx,
        (center - _humanScale(axis, blendRadius * 0.68)).dy,
        (center + _humanScale(side, blendRadius * 0.86)).dx,
        (center + _humanScale(side, blendRadius * 0.86)).dy,
      )
      ..close();
    canvas.drawPath(
      blend,
      Paint()
        ..color = fillColor.withValues(alpha: 0.92 * opacity)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      blend,
      Paint()
        ..color = sideColor.withValues(alpha: 0.14 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (bodyScale * 0.004).clamp(0.45, 1.0),
    );
  }
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
    canvas.drawPath(
      palm,
      Paint()
        ..color = style.resolvedSkinColor.withValues(alpha: 0.94 * opacity)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      palm,
      Paint()
        ..color = sideColor.withValues(
          alpha: (isFocused ? 0.34 : 0.20) * opacity,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = (bodyScale * 0.004).clamp(0.45, 1.0),
    );
    canvas.drawLine(
      base + _humanScale(side, palmRadius * 0.28),
      tip + _humanScale(side, palmRadius * 0.20),
      Paint()
        ..color = style.resolvedSkinColor.withValues(alpha: 0.16 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (bodyScale * 0.003).clamp(0.35, 0.8)
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
    final accent = sideColor;
    final shoeColor = style.resolvedShoeColor;
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
            shoeColor.withValues(alpha: 0.96 * opacity),
            shoeColor.withValues(alpha: 0.84 * opacity),
            accent.withValues(alpha: 0.34 * opacity),
          ],
          const <double>[0, 0.54, 1],
        )
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withValues(
          alpha: (isFocused ? 0.36 : 0.22) * opacity,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = (bodyScale * 0.005).clamp(0.55, 1.2)
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawLine(
      ankle,
      toe,
      Paint()
        ..color = shoeColor.withValues(alpha: 0.22 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (bodyScale * 0.003).clamp(0.35, 0.8)
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
  final radius = (bodyScale * 0.016).clamp(1.9, 4.8).toDouble();
  for (final index in focusIndices) {
    final point = points[index];
    if (point == null) continue;
    canvas.drawCircle(
      point,
      radius * 1.58,
      Paint()
        ..color = style.focusColor.withValues(alpha: 0.13 * opacity)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      point,
      radius * 1.02,
      Paint()
        ..color = style.focusColor.withValues(alpha: 0.76 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (bodyScale * 0.0055).clamp(0.55, 1.35),
    );
    canvas.drawCircle(
      point,
      radius * 0.30,
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
  final fromUpper = from + _humanScale(side, fromRadius);
  final fromLower = from - _humanScale(side, fromRadius);
  final toUpper = to + _humanScale(side, toRadius);
  final toLower = to - _humanScale(side, toRadius);
  final fromCap = from - _humanScale(direction, fromRadius * 0.48);
  final toCap = to + _humanScale(direction, toRadius * 0.48);
  final controlDistance = math.min(distance * 0.24, averageRadius * 2.2);
  final upperStart = from +
      _humanScale(direction, controlDistance) +
      _humanScale(side, fromRadius * 1.10);
  final upperEnd = to -
      _humanScale(direction, controlDistance) +
      _humanScale(side, toRadius * 1.12);
  final lowerStart = from +
      _humanScale(direction, controlDistance) -
      _humanScale(side, fromRadius * 1.10);
  final lowerEnd = to -
      _humanScale(direction, controlDistance) -
      _humanScale(side, toRadius * 1.12);

  return Path()
    ..moveTo(fromUpper.dx, fromUpper.dy)
    ..cubicTo(
      upperStart.dx,
      upperStart.dy,
      upperEnd.dx,
      upperEnd.dy,
      toUpper.dx,
      toUpper.dy,
    )
    ..quadraticBezierTo(toCap.dx, toCap.dy, toLower.dx, toLower.dy)
    ..cubicTo(
      lowerEnd.dx,
      lowerEnd.dy,
      lowerStart.dx,
      lowerStart.dy,
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

Color _humanLighten(Color color, double amount) =>
    Color.lerp(color, const Color(0xFFFFFFFF), amount.clamp(0.0, 1.0))!;

Color _humanDarken(Color color, double amount) =>
    Color.lerp(color, const Color(0xFF000000), amount.clamp(0.0, 1.0))!;

enum _HumanPoseSide { left, right }

enum _HumanFormMaterial { skin, apparel }

class _HumanLimbSegment {
  final int from;
  final int to;
  final _HumanPoseSide side;
  final double fromRadiusFactor;
  final double toRadiusFactor;
  final _HumanFormMaterial material;

  const _HumanLimbSegment(
    this.from,
    this.to,
    this.side, {
    required this.fromRadiusFactor,
    required this.toRadiusFactor,
    this.material = _HumanFormMaterial.skin,
  });
}

class _HumanHand {
  final int elbow;
  final int wrist;
  final _HumanPoseSide side;

  const _HumanHand(this.elbow, this.wrist, this.side);
}

class _HumanJointBlend {
  final int previous;
  final int center;
  final int next;
  final _HumanPoseSide side;
  final _HumanFormMaterial material;

  const _HumanJointBlend(
    this.previous,
    this.center,
    this.next,
    this.side, {
    this.material = _HumanFormMaterial.skin,
  });
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
    material: _HumanFormMaterial.apparel,
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
    material: _HumanFormMaterial.apparel,
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

const _humanJointBlends = <_HumanJointBlend>[
  _HumanJointBlend(
    11,
    13,
    15,
    _HumanPoseSide.left,
    material: _HumanFormMaterial.skin,
  ),
  _HumanJointBlend(
    12,
    14,
    16,
    _HumanPoseSide.right,
    material: _HumanFormMaterial.skin,
  ),
  _HumanJointBlend(
    23,
    25,
    27,
    _HumanPoseSide.left,
    material: _HumanFormMaterial.skin,
  ),
  _HumanJointBlend(
    24,
    26,
    28,
    _HumanPoseSide.right,
    material: _HumanFormMaterial.skin,
  ),
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
