import 'dart:math' as math;
import 'dart:ui';

import '../../domain/entities/running_live_coaching_state.dart';

class RunningPoseOutlineFrame {
  final Rect rect;
  final Radius radius;

  const RunningPoseOutlineFrame({required this.rect, required this.radius});
}

const List<RunningPoseLandmarkType> _torsoOutlineTypes = [
  RunningPoseLandmarkType.leftShoulder,
  RunningPoseLandmarkType.rightShoulder,
  RunningPoseLandmarkType.leftHip,
  RunningPoseLandmarkType.rightHip,
];

const List<RunningPoseLandmarkType> _headOutlineTypes = [
  RunningPoseLandmarkType.nose,
  RunningPoseLandmarkType.leftEar,
  RunningPoseLandmarkType.rightEar,
  RunningPoseLandmarkType.leftShoulder,
  RunningPoseLandmarkType.rightShoulder,
];

const List<RunningPoseLandmarkType> _footOutlineTypes = [
  RunningPoseLandmarkType.leftKnee,
  RunningPoseLandmarkType.rightKnee,
  RunningPoseLandmarkType.leftAnkle,
  RunningPoseLandmarkType.rightAnkle,
  RunningPoseLandmarkType.leftHeel,
  RunningPoseLandmarkType.rightHeel,
  RunningPoseLandmarkType.leftFootIndex,
  RunningPoseLandmarkType.rightFootIndex,
];

const List<RunningPoseLandmarkType> _supportOutlineTypes = [
  RunningPoseLandmarkType.leftElbow,
  RunningPoseLandmarkType.rightElbow,
  RunningPoseLandmarkType.leftWrist,
  RunningPoseLandmarkType.rightWrist,
  RunningPoseLandmarkType.leftKnee,
  RunningPoseLandmarkType.rightKnee,
  RunningPoseLandmarkType.leftAnkle,
  RunningPoseLandmarkType.rightAnkle,
  RunningPoseLandmarkType.leftHeel,
  RunningPoseLandmarkType.rightHeel,
  RunningPoseLandmarkType.leftFootIndex,
  RunningPoseLandmarkType.rightFootIndex,
];

RunningPoseOutlineFrame? buildRunningPoseOutlineFrame({
  required Map<RunningPoseLandmarkType, Offset> visiblePoints,
  required Size canvasSize,
}) {
  if (visiblePoints.length < 3) {
    return null;
  }

  final allPoints = visiblePoints.values.toList(growable: false);
  final torsoPoints = _pointsForTypes(visiblePoints, _torsoOutlineTypes);
  final headPoints = _pointsForTypes(visiblePoints, _headOutlineTypes);
  final footPoints = _pointsForTypes(visiblePoints, _footOutlineTypes);
  final supportPoints = _pointsForTypes(visiblePoints, _supportOutlineTypes);

  final topPoints = headPoints.isNotEmpty ? headPoints : allPoints;
  final bottomPoints = footPoints.isNotEmpty ? footPoints : allPoints;
  final widthPoints = supportPoints.isNotEmpty ? supportPoints : allPoints;

  final topExtent = topPoints.map((point) => point.dy).reduce(math.min);
  final bottomExtent = bottomPoints.map((point) => point.dy).reduce(math.max);
  final bodyHeight = math.max(1.0, bottomExtent - topExtent);
  final verticalPadding = math.max(12.0, bodyHeight * 0.05);
  final horizontalPadding = math.max(10.0, bodyHeight * 0.04);
  final centerX = _frameCenterX(
    visiblePoints: visiblePoints,
    fallbackMinX: allPoints.map((point) => point.dx).reduce(math.min),
    fallbackMaxX: allPoints.map((point) => point.dx).reduce(math.max),
  );

  final torsoHalfWidth = torsoPoints.isEmpty
      ? widthPoints
                .map((point) => (point.dx - centerX).abs())
                .reduce(math.max) *
            0.55
      : torsoPoints.map((point) => (point.dx - centerX).abs()).reduce(math.max);
  final supportHalfWidth = widthPoints
      .map((point) => (point.dx - centerX).abs())
      .reduce(math.max);
  final cappedSupportHalfWidth = math.min(
    supportHalfWidth * 0.82,
    torsoHalfWidth * 1.65,
  );
  final halfWidth = math.min(
    math.max(torsoHalfWidth * 1.16, cappedSupportHalfWidth) + horizontalPadding,
    bodyHeight * 0.34,
  );

  final rect = Rect.fromLTWH(
    centerX - halfWidth,
    topExtent - verticalPadding,
    halfWidth * 2,
    bodyHeight + (verticalPadding * 2),
  ).intersect(Offset.zero & canvasSize);
  if (rect.isEmpty) {
    return null;
  }

  return RunningPoseOutlineFrame(
    rect: rect,
    radius: Radius.circular(math.min(rect.width * 0.48, 34)),
  );
}

double _frameCenterX({
  required Map<RunningPoseLandmarkType, Offset> visiblePoints,
  required double fallbackMinX,
  required double fallbackMaxX,
}) {
  final centers = [
    _pairMidpoint(
      visiblePoints,
      RunningPoseLandmarkType.leftShoulder,
      RunningPoseLandmarkType.rightShoulder,
    ),
    _pairMidpoint(
      visiblePoints,
      RunningPoseLandmarkType.leftHip,
      RunningPoseLandmarkType.rightHip,
    ),
    _pairMidpoint(
      visiblePoints,
      RunningPoseLandmarkType.leftAnkle,
      RunningPoseLandmarkType.rightAnkle,
    ),
  ].whereType<Offset>().toList(growable: false);
  if (centers.isEmpty) {
    return (fallbackMinX + fallbackMaxX) / 2;
  }
  final sum = centers.fold<double>(0, (total, point) => total + point.dx);
  return sum / centers.length;
}

List<Offset> _pointsForTypes(
  Map<RunningPoseLandmarkType, Offset> visiblePoints,
  List<RunningPoseLandmarkType> types,
) {
  return [
    for (final type in types)
      if (visiblePoints[type] case final point?) point,
  ];
}

Offset? _pairMidpoint(
  Map<RunningPoseLandmarkType, Offset> visiblePoints,
  RunningPoseLandmarkType firstType,
  RunningPoseLandmarkType secondType,
) {
  final first = visiblePoints[firstType];
  final second = visiblePoints[secondType];
  if (first == null || second == null) {
    return null;
  }
  return Offset((first.dx + second.dx) / 2, (first.dy + second.dy) / 2);
}
