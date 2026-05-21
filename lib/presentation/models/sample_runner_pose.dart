import 'dart:math' as math;
import 'dart:ui';

class SampleRunnerPose {
  final double groundY;
  final Offset hip;
  final Offset chest;
  final Offset neck;
  final Offset head;
  final Offset shoulderFront;
  final Offset shoulderRear;
  final Offset hipFront;
  final Offset hipRear;
  final SampleRunnerLegPose frontLeg;
  final SampleRunnerLegPose rearLeg;
  final SampleRunnerArmPose frontArm;
  final SampleRunnerArmPose rearArm;

  const SampleRunnerPose({
    required this.groundY,
    required this.hip,
    required this.chest,
    required this.neck,
    required this.head,
    required this.shoulderFront,
    required this.shoulderRear,
    required this.hipFront,
    required this.hipRear,
    required this.frontLeg,
    required this.rearLeg,
    required this.frontArm,
    required this.rearArm,
  });
}

class SampleRunnerLegPose {
  final Offset hip;
  final Offset knee;
  final Offset ankle;
  final Offset toe;

  const SampleRunnerLegPose({
    required this.hip,
    required this.knee,
    required this.ankle,
    required this.toe,
  });

  double get thighLength => (knee - hip).distance;
  double get shinLength => (ankle - knee).distance;
  double get footLength => (toe - ankle).distance;
}

class SampleRunnerArmPose {
  final Offset shoulder;
  final Offset elbow;
  final Offset wrist;

  const SampleRunnerArmPose({
    required this.shoulder,
    required this.elbow,
    required this.wrist,
  });

  double get upperArmLength => (elbow - shoulder).distance;
  double get forearmLength => (wrist - elbow).distance;
}

SampleRunnerPose buildSampleRunnerPose({
  required double progress,
  required Size size,
}) {
  final phase = progress * 2 * math.pi;
  final stride = math.sin(phase);
  final counterStride = math.sin(phase + math.pi);
  final drive = (stride + 1) / 2;
  final recovery = (counterStride + 1) / 2;
  final scale = size.height;
  final flightLift = (1 - math.cos(phase * 2)) * scale * 0.011;
  final bob = math.cos(phase * 2) * scale * 0.006 - flightLift;
  final groundY = scale * 0.78;
  final hip = Offset(
    (size.width * 0.54) + (stride * scale * 0.018),
    groundY - scale * 0.30 + bob,
  );
  final chest = Offset(hip.dx + scale * 0.082, hip.dy - scale * 0.195);
  final neck = Offset(chest.dx + scale * 0.030, chest.dy - scale * 0.064);
  final head = Offset(neck.dx + scale * 0.040, neck.dy - scale * 0.050);
  final shoulderFront = Offset(
    chest.dx + scale * 0.080,
    chest.dy + scale * 0.002,
  );
  final shoulderRear = Offset(
    chest.dx - scale * 0.086,
    chest.dy + scale * 0.020,
  );
  final hipFront = Offset(hip.dx + scale * 0.062, hip.dy - scale * 0.002);
  final hipRear = Offset(hip.dx - scale * 0.062, hip.dy + scale * 0.006);

  return SampleRunnerPose(
    groundY: groundY,
    hip: hip,
    chest: chest,
    neck: neck,
    head: head,
    shoulderFront: shoulderFront,
    shoulderRear: shoulderRear,
    hipFront: hipFront,
    hipRear: hipRear,
    frontLeg: _legPose(
      anchor: hipFront,
      amount: drive,
      scale: scale,
      groundY: groundY,
    ),
    rearLeg: _legPose(
      anchor: hipRear,
      amount: recovery,
      scale: scale,
      groundY: groundY,
    ),
    frontArm: _armPose(
      anchor: shoulderFront,
      amount: recovery,
      direction: -1,
      scale: scale,
    ),
    rearArm: _armPose(
      anchor: shoulderRear,
      amount: drive,
      direction: 1,
      scale: scale,
    ),
  );
}

SampleRunnerLegPose _legPose({
  required Offset anchor,
  required double amount,
  required double scale,
  required double groundY,
}) {
  final upperLegLength = scale * 0.190;
  final lowerLegLength = scale * 0.215;
  final ankleTarget = Offset(
    anchor.dx + scale * _mix(-0.255, 0.232, amount),
    groundY - scale * _mix(0.006, 0.176, amount),
  );
  final kneeHint = Offset(
    anchor.dx + scale * _mix(-0.076, 0.224, amount),
    anchor.dy + scale * _mix(0.180, -0.004, amount),
  );
  final limb = _resolveTwoBoneLimb(
    start: anchor,
    target: ankleTarget,
    hint: kneeHint,
    upperLength: upperLegLength,
    lowerLength: lowerLegLength,
  );
  return SampleRunnerLegPose(
    hip: anchor,
    knee: limb.joint,
    ankle: limb.end,
    toe: limb.end + _fixedFootVector(amount, scale),
  );
}

SampleRunnerArmPose _armPose({
  required Offset anchor,
  required double amount,
  required double direction,
  required double scale,
}) {
  final upperArmLength = scale * 0.105;
  final forearmLength = scale * 0.098;
  final wristTarget = Offset(
    anchor.dx + direction * scale * _mix(0.074, 0.210, amount),
    anchor.dy + scale * _mix(0.168, 0.044, amount),
  );
  final elbowHint = Offset(
    anchor.dx + direction * scale * _mix(0.108, 0.150, amount),
    anchor.dy + scale * _mix(0.058, 0.136, 1 - amount),
  );
  final limb = _resolveTwoBoneLimb(
    start: anchor,
    target: wristTarget,
    hint: elbowHint,
    upperLength: upperArmLength,
    lowerLength: forearmLength,
  );
  return SampleRunnerArmPose(
    shoulder: anchor,
    elbow: limb.joint,
    wrist: limb.end,
  );
}

({Offset joint, Offset end}) _resolveTwoBoneLimb({
  required Offset start,
  required Offset target,
  required Offset hint,
  required double upperLength,
  required double lowerLength,
}) {
  final targetVector = target - start;
  final rawDistance = targetVector.distance;
  final direction = rawDistance <= 0.001
      ? const Offset(0, 1)
      : targetVector / rawDistance;
  final minReach = (upperLength - lowerLength).abs() + 0.001;
  final maxReach = upperLength + lowerLength - 0.001;
  final distance = rawDistance.clamp(minReach, maxReach).toDouble();
  final end = start + direction * distance;
  final baseDistance =
      ((upperLength * upperLength) -
          (lowerLength * lowerLength) +
          (distance * distance)) /
      (2 * distance);
  final bendDistance = math.sqrt(
    math.max(0, (upperLength * upperLength) - (baseDistance * baseDistance)),
  );
  final basePoint = start + direction * baseDistance;
  final perpendicular = Offset(-direction.dy, direction.dx);
  final firstJoint = basePoint + perpendicular * bendDistance;
  final secondJoint = basePoint - perpendicular * bendDistance;
  final joint =
      (firstJoint - hint).distanceSquared <=
          (secondJoint - hint).distanceSquared
      ? firstJoint
      : secondJoint;
  return (joint: joint, end: end);
}

Offset _fixedFootVector(double amount, double scale) {
  final rawDirection = Offset(
    _mix(-0.90, 0.96, amount),
    _mix(0.20, 0.10, amount),
  );
  return rawDirection / rawDirection.distance * (scale * 0.060);
}

double _mix(double a, double b, double t) => a + (b - a) * t;
