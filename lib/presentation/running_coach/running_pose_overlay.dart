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

  _drawHumanTorso(
    canvas,
    points,
    bodyScale,
    style,
    opacity,
    focusIndices,
  );
  _drawHumanHead(canvas, points, bodyScale, style, opacity);
  _drawHumanLimbs(
    canvas,
    points,
    bodyScale,
    style,
    opacity,
    focusIndices,
  );
  _drawHumanFeet(canvas, points, bodyScale, style, opacity, focusIndices);
  _drawHumanJoints(canvas, points, bodyScale, style, opacity, focusIndices);
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
  final path = Path()
    ..moveTo(leftShoulder.dx, leftShoulder.dy)
    ..quadraticBezierTo(
      shoulderCenter.dx,
      shoulderCenter.dy - (bodyScale * 0.025),
      rightShoulder.dx,
      rightShoulder.dy,
    )
    ..lineTo(rightHip.dx, rightHip.dy)
    ..quadraticBezierTo(
      hipCenter.dx,
      hipCenter.dy + (bodyScale * 0.018),
      leftHip.dx,
      leftHip.dy,
    )
    ..close();
  canvas.drawPath(
    path,
    Paint()
      ..color = torsoColor.withValues(alpha: 0.26 * opacity)
      ..style = PaintingStyle.fill,
  );
  canvas.drawPath(
    path,
    Paint()
      ..color = torsoColor.withValues(alpha: 0.72 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bodyScale * 0.015).clamp(1.1, 3.6)
      ..strokeJoin = StrokeJoin.round,
  );
  canvas.drawLine(
    shoulderCenter,
    hipCenter,
    Paint()
      ..color = style.jointColor.withValues(alpha: 0.48 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bodyScale * 0.008).clamp(0.9, 2.1)
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
  if (headAnchor == null) return;

  final earWidth = leftEar != null && rightEar != null
      ? (leftEar - rightEar).distance * 1.36
      : 0.0;
  final headWidth = earWidth > 0
      ? earWidth.clamp(bodyScale * 0.16, bodyScale * 0.34).toDouble()
      : (bodyScale * 0.25).clamp(14.0, 52.0).toDouble();
  final headHeight = headWidth * 1.18;
  final center = headAnchor;
  final head = Rect.fromCenter(
    center: center,
    width: headWidth,
    height: headHeight,
  );
  canvas.drawOval(
    head,
    Paint()
      ..color = style.bodyColor.withValues(alpha: 0.26 * opacity)
      ..style = PaintingStyle.fill,
  );
  canvas.drawOval(
    head,
    Paint()
      ..color = style.jointColor.withValues(alpha: 0.82 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bodyScale * 0.013).clamp(1.0, 3.0),
  );
  if (shoulderCenter != null) {
    canvas.drawLine(
      head.bottomCenter,
      shoulderCenter,
      Paint()
        ..color = style.jointColor.withValues(alpha: 0.58 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (bodyScale * 0.040).clamp(2.2, 7.4)
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
  Set<int> focusIndices,
) {
  for (final segment in _humanLimbSegments) {
    final from = points[segment.from];
    final to = points[segment.to];
    if (from == null || to == null) continue;
    final isFocused = focusIndices.contains(segment.from) &&
        focusIndices.contains(segment.to);
    final width =
        (bodyScale * 0.125 * segment.widthFactor).clamp(5.0, 28.0).toDouble();
    final sideColor = switch (segment.side) {
      _HumanPoseSide.left => style.leftSideColor,
      _HumanPoseSide.right => style.rightSideColor,
    };
    final accent = isFocused ? style.focusColor : sideColor;
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = style.bodyColor.withValues(alpha: 0.30 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = accent.withValues(
          alpha: (isFocused ? 0.92 : 0.70) * opacity,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.56
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
    final width = (bodyScale * 0.090).clamp(4.0, 18.0).toDouble();
    final sideColor = switch (foot.side) {
      _HumanPoseSide.left => style.leftSideColor,
      _HumanPoseSide.right => style.rightSideColor,
    };
    final accent = isFocused ? style.focusColor : sideColor;
    final path = Path()
      ..moveTo(ankle.dx, ankle.dy)
      ..quadraticBezierTo(through.dx, through.dy, toe.dx, toe.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = style.bodyColor.withValues(alpha: 0.32 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withValues(
          alpha: (isFocused ? 0.92 : 0.74) * opacity,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.60
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }
}

void _drawHumanJoints(
  Canvas canvas,
  Map<int, Offset> points,
  double bodyScale,
  RunningPoseHumanFormStyle style,
  double opacity,
  Set<int> focusIndices,
) {
  final radius = (bodyScale * 0.026).clamp(2.6, 8.0).toDouble();
  for (final index in _humanJointIndices) {
    final point = points[index];
    if (point == null) continue;
    final isFocused = focusIndices.contains(index);
    final accent = isFocused ? style.focusColor : style.jointColor;
    canvas.drawCircle(
      point,
      radius * (isFocused ? 1.54 : 1.18),
      Paint()
        ..color = accent.withValues(
          alpha: (isFocused ? 0.22 : 0.16) * opacity,
        )
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      point,
      radius * 0.60,
      Paint()
        ..color = accent.withValues(
          alpha: (isFocused ? 0.98 : 0.78) * opacity,
        )
        ..style = PaintingStyle.fill,
    );
  }
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
      xs.reduce(math.max) - xs.reduce(math.min),
      ys.reduce(math.max) - ys.reduce(math.min),
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

enum _HumanPoseSide { left, right }

class _HumanLimbSegment {
  final int from;
  final int to;
  final _HumanPoseSide side;
  final double widthFactor;

  const _HumanLimbSegment(
    this.from,
    this.to,
    this.side, {
    this.widthFactor = 1,
  });
}

class _HumanFoot {
  final int ankle;
  final int heel;
  final int toe;
  final _HumanPoseSide side;

  const _HumanFoot(this.ankle, this.heel, this.toe, this.side);
}

const _humanLimbSegments = <_HumanLimbSegment>[
  _HumanLimbSegment(11, 13, _HumanPoseSide.left, widthFactor: 0.78),
  _HumanLimbSegment(13, 15, _HumanPoseSide.left, widthFactor: 0.64),
  _HumanLimbSegment(12, 14, _HumanPoseSide.right, widthFactor: 0.78),
  _HumanLimbSegment(14, 16, _HumanPoseSide.right, widthFactor: 0.64),
  _HumanLimbSegment(23, 25, _HumanPoseSide.left, widthFactor: 1.24),
  _HumanLimbSegment(25, 27, _HumanPoseSide.left, widthFactor: 1.04),
  _HumanLimbSegment(24, 26, _HumanPoseSide.right, widthFactor: 1.24),
  _HumanLimbSegment(26, 28, _HumanPoseSide.right, widthFactor: 1.04),
];

const _humanFeet = <_HumanFoot>[
  _HumanFoot(27, 29, 31, _HumanPoseSide.left),
  _HumanFoot(28, 30, 32, _HumanPoseSide.right),
];

const _humanJointIndices = <int>{
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
  31,
  32,
};

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
