import 'dart:math' as math;
import 'dart:ui';

import '../../domain/entities/running_video_analysis_result.dart';

/// Resolves the athlete's on-screen heading for instructional rendering.
///
/// Travel direction is useful for a runner moving across the frame, but a
/// treadmill clip is intentionally classified as stationary. In that case,
/// the face is the most direct visual indication of which way the runner is
/// facing. The result is used only for presentation; it does not alter the
/// analysis metrics or their travel-direction calculation.
double resolveRunningVisualForward({
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

/// A neutral coaching pose derived from measured MediaPipe joints.
///
/// The model keeps the measured hip, hand, and foot locations and normalizes
/// elbows and knees to stable proportions. It supports a generic reference
/// athlete without inferring the runner's body or identity.
class RunningProfessionalRunnerPose {
  final Map<int, Offset> points;
  final Set<int> measuredIndices;
  final Offset shoulderCenter;
  final Offset hipCenter;
  final Offset neck;
  final Offset headCenter;
  final Offset downAxis;
  final double bodyScale;
  final double forward;

  const RunningProfessionalRunnerPose._({
    required this.points,
    required this.measuredIndices,
    required this.shoulderCenter,
    required this.hipCenter,
    required this.neck,
    required this.headCenter,
    required this.downAxis,
    required this.bodyScale,
    required this.forward,
  });
}

/// Builds a reference-runner pose from one measured side-view frame.
///
/// [forward] is positive for left-to-right running and negative for
/// right-to-left running. It only determines orientation of the reference
/// artwork; the coordinates used for the coaching trace remain measured.
///
/// Evidence frames can lose an arm or a lower leg while the torso is still
/// stable. In that case the instructional athlete completes only the missing
/// joints from the visible torso. This keeps the reference card readable
/// without turning inferred locations into measured coaching evidence.
RunningProfessionalRunnerPose? retargetProfessionalRunnerPose({
  required Map<int, Offset> measuredPoints,
  required double forward,
}) {
  final points = Map<int, Offset>.from(measuredPoints);
  final measuredIndices = Set<int>.unmodifiable(measuredPoints.keys);
  if (!_completeSparsePose(points, forward: forward)) return null;
  final shoulderCenter = _midpoint(points[11]!, points[12]!);
  final hipCenter = _midpoint(points[23]!, points[24]!);
  final torsoLength = (hipCenter - shoulderCenter).distance;
  if (!torsoLength.isFinite || torsoLength < 2) return null;

  final leftLegLength = _chainLength(points, 23, 25, 27);
  final rightLegLength = _chainLength(points, 24, 26, 28);
  final meanLegLength = (leftLegLength + rightLegLength) / 2;
  if (!meanLegLength.isFinite || meanLegLength < 3) return null;

  // A normalized knee/elbow retains the measured end point and bend side,
  // while avoiding unstable proportions in low-resolution frames.
  _retargetHinge(points, 23, 25, 27, proximalRatio: 0.525);
  _retargetHinge(points, 24, 26, 28, proximalRatio: 0.525);
  _retargetHinge(points, 11, 13, 15, proximalRatio: 0.485);
  _retargetHinge(points, 12, 14, 16, proximalRatio: 0.485);

  final bodyScale =
      (meanLegLength * 0.52 + torsoLength * 0.48).clamp(8.0, 420.0).toDouble();
  final downAxis = _unit(hipCenter - shoulderCenter);
  if (downAxis == Offset.zero) return null;
  final neck = shoulderCenter - _scale(downAxis, bodyScale * 0.075);
  final headCenter = neck -
      _scale(downAxis, bodyScale * 0.098) +
      Offset(forward.sign * bodyScale * 0.018, 0);

  _retargetFoot(points, 27, 29, 31, meanLegLength, forward);
  _retargetFoot(points, 28, 30, 32, meanLegLength, forward);

  return RunningProfessionalRunnerPose._(
    points: Map<int, Offset>.unmodifiable(points),
    measuredIndices: measuredIndices,
    shoulderCenter: shoulderCenter,
    hipCenter: hipCenter,
    neck: neck,
    headCenter: headCenter,
    downAxis: downAxis,
    bodyScale: bodyScale,
    forward: forward >= 0 ? 1 : -1,
  );
}

bool _completeSparsePose(Map<int, Offset> points, {required double forward}) {
  final shoulderCenter = _pairCenter(points[11], points[12]);
  final hipCenter = _pairCenter(points[23], points[24]);
  if (shoulderCenter == null || hipCenter == null) return false;

  final measuredTorso = hipCenter - shoulderCenter;
  final torsoLength = measuredTorso.distance.clamp(12.0, 280.0).toDouble();
  var downAxis = _unit(measuredTorso);
  if (downAxis == Offset.zero) downAxis = const Offset(0, 1);

  final lateralAxis = _perp(downAxis);
  final shoulderHalfWidth = (torsoLength * 0.065).clamp(1.5, 22.0).toDouble();
  final hipHalfWidth = (torsoLength * 0.075).clamp(1.5, 24.0).toDouble();
  _completePair(
    points,
    firstIndex: 11,
    secondIndex: 12,
    center: shoulderCenter,
    lateralAxis: lateralAxis,
    halfWidth: shoulderHalfWidth,
  );
  _completePair(
    points,
    firstIndex: 23,
    secondIndex: 24,
    center: hipCenter,
    lateralAxis: lateralAxis,
    halfWidth: hipHalfWidth,
  );

  final forwardAxis = Offset(forward >= 0 ? 1 : -1, 0);
  final legLength = (torsoLength * 1.72).clamp(20.0, 460.0).toDouble();
  _completeLeg(
    points,
    hipIndex: 23,
    kneeIndex: 25,
    ankleIndex: 27,
    downAxis: downAxis,
    forwardAxis: forwardAxis,
    legLength: legLength,
    lead: true,
  );
  _completeLeg(
    points,
    hipIndex: 24,
    kneeIndex: 26,
    ankleIndex: 28,
    downAxis: downAxis,
    forwardAxis: forwardAxis,
    legLength: legLength,
    lead: false,
  );

  final armLength = (torsoLength * 0.86).clamp(12.0, 220.0).toDouble();
  _completeArm(
    points,
    shoulderIndex: 11,
    elbowIndex: 13,
    wristIndex: 15,
    downAxis: downAxis,
    forwardAxis: forwardAxis,
    armLength: armLength,
    forwardSwing: true,
  );
  _completeArm(
    points,
    shoulderIndex: 12,
    elbowIndex: 14,
    wristIndex: 16,
    downAxis: downAxis,
    forwardAxis: forwardAxis,
    armLength: armLength,
    forwardSwing: false,
  );
  return true;
}

Offset? _pairCenter(Offset? first, Offset? second) {
  if (first == null && second == null) return null;
  if (first == null) return second;
  if (second == null) return first;
  return _midpoint(first, second);
}

void _completePair(
  Map<int, Offset> points, {
  required int firstIndex,
  required int secondIndex,
  required Offset center,
  required Offset lateralAxis,
  required double halfWidth,
}) {
  final first = points[firstIndex];
  final second = points[secondIndex];
  if (first == null && second == null) {
    points[firstIndex] = center - _scale(lateralAxis, halfWidth);
    points[secondIndex] = center + _scale(lateralAxis, halfWidth);
  } else if (first == null) {
    points[firstIndex] = second! - _scale(lateralAxis, halfWidth * 2);
  } else if (second == null) {
    points[secondIndex] = first + _scale(lateralAxis, halfWidth * 2);
  }
}

void _completeLeg(
  Map<int, Offset> points, {
  required int hipIndex,
  required int kneeIndex,
  required int ankleIndex,
  required Offset downAxis,
  required Offset forwardAxis,
  required double legLength,
  required bool lead,
}) {
  final hip = points[hipIndex];
  if (hip == null) return;
  final stride = lead ? 0.34 : -0.22;
  final knee = hip +
      _scale(downAxis, legLength * 0.42) +
      _scale(forwardAxis, legLength * stride);
  final ankle = hip +
      _scale(downAxis, legLength * (lead ? 0.96 : 0.84)) +
      _scale(forwardAxis, legLength * (lead ? 0.52 : -0.46));
  points.putIfAbsent(kneeIndex, () => knee);
  points.putIfAbsent(ankleIndex, () => ankle);
}

void _completeArm(
  Map<int, Offset> points, {
  required int shoulderIndex,
  required int elbowIndex,
  required int wristIndex,
  required Offset downAxis,
  required Offset forwardAxis,
  required double armLength,
  required bool forwardSwing,
}) {
  final shoulder = points[shoulderIndex];
  if (shoulder == null) return;
  final swing = forwardSwing ? 1.0 : -1.0;
  final elbow = shoulder +
      _scale(downAxis, armLength * 0.38) +
      _scale(forwardAxis, armLength * 0.28 * swing);
  final wrist = shoulder +
      _scale(downAxis, armLength * 0.66) +
      _scale(forwardAxis, armLength * 0.56 * swing);
  points.putIfAbsent(elbowIndex, () => elbow);
  points.putIfAbsent(wristIndex, () => wrist);
}

void _retargetHinge(
  Map<int, Offset> points,
  int rootIndex,
  int jointIndex,
  int endIndex, {
  required double proximalRatio,
}) {
  final root = points[rootIndex];
  final rawJoint = points[jointIndex];
  final end = points[endIndex];
  if (root == null || rawJoint == null || end == null) return;
  final firstLength = (rawJoint - root).distance;
  final secondLength = (end - rawJoint).distance;
  final directLength = (end - root).distance;
  if (firstLength < 0.5 || secondLength < 0.5 || directLength < 0.5) return;

  var totalLength = firstLength + secondLength;
  totalLength = math.max(totalLength, directLength * 1.025);
  var proximalLength = totalLength * proximalRatio;
  var distalLength = totalLength - proximalLength;
  final minimumReach = directLength * 1.005;
  if (proximalLength + distalLength < minimumReach) {
    final scale = minimumReach / (proximalLength + distalLength);
    proximalLength *= scale;
    distalLength *= scale;
  }
  final direction = _unit(end - root);
  final projection = ((proximalLength * proximalLength) -
          (distalLength * distalLength) +
          (directLength * directLength)) /
      (2 * directLength);
  final heightSquared = math.max(
    0.0,
    proximalLength * proximalLength - projection * projection,
  );
  final perpendicular = _perp(direction);
  final rawSide = _cross(end - root, rawJoint - root);
  final sideSign = rawSide.abs() < 0.001 ? 1.0 : rawSide.sign;
  points[jointIndex] = root +
      _scale(direction, projection) +
      _scale(perpendicular, math.sqrt(heightSquared) * sideSign);
}

void _retargetFoot(
  Map<int, Offset> points,
  int ankleIndex,
  int heelIndex,
  int toeIndex,
  double legLength,
  double forward,
) {
  final ankle = points[ankleIndex];
  if (ankle == null) return;
  final rawToe = points[toeIndex];
  final rawHeel = points[heelIndex];
  var direction = _unit(
    (rawToe ?? (ankle + Offset(forward * legLength * 0.16, 0))) -
        (rawHeel ?? ankle),
  );
  if (direction == Offset.zero) direction = Offset(forward.sign, 0);
  final footLength = (legLength * 0.20).clamp(4.0, 110.0).toDouble();
  points[toeIndex] = ankle + _scale(direction, footLength * 0.68);
  points[heelIndex] = ankle - _scale(direction, footLength * 0.40);
}

double _chainLength(Map<int, Offset> points, int first, int middle, int last) {
  return (points[first]! - points[middle]!).distance +
      (points[middle]! - points[last]!).distance;
}

Offset _midpoint(Offset first, Offset second) =>
    Offset((first.dx + second.dx) / 2, (first.dy + second.dy) / 2);

Offset _unit(Offset value) {
  final distance = value.distance;
  if (!distance.isFinite || distance < 0.0001) return Offset.zero;
  return Offset(value.dx / distance, value.dy / distance);
}

Offset _perp(Offset value) => Offset(-value.dy, value.dx);

Offset _scale(Offset value, double amount) =>
    Offset(value.dx * amount, value.dy * amount);

double _cross(Offset first, Offset second) =>
    first.dx * second.dy - first.dy * second.dx;
