import 'dart:math' as math;
import 'dart:ui';

/// A neutral coaching pose derived from measured MediaPipe joints.
///
/// The model keeps the measured hip, hand, and foot locations and normalizes
/// elbows and knees to stable proportions. It supports a generic reference
/// athlete without inferring the runner's body or identity.
class RunningProfessionalRunnerPose {
  final Map<int, Offset> points;
  final Offset shoulderCenter;
  final Offset hipCenter;
  final Offset neck;
  final Offset headCenter;
  final Offset downAxis;
  final double bodyScale;
  final double forward;

  const RunningProfessionalRunnerPose._({
    required this.points,
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
RunningProfessionalRunnerPose? retargetProfessionalRunnerPose({
  required Map<int, Offset> measuredPoints,
  required double forward,
}) {
  const requiredIndices = <int>{
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
  };
  if (!requiredIndices.every(measuredPoints.containsKey)) return null;

  final points = Map<int, Offset>.from(measuredPoints);
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
    shoulderCenter: shoulderCenter,
    hipCenter: hipCenter,
    neck: neck,
    headCenter: headCenter,
    downAxis: downAxis,
    bodyScale: bodyScale,
    forward: forward >= 0 ? 1 : -1,
  );
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
