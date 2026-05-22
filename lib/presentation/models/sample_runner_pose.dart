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
  final normalizedProgress = progress % 1.0;
  final phase = normalizedProgress * 2 * math.pi;
  final stride = math.sin(phase);
  final scale = size.height;
  final flightLift = (1 - math.cos(phase * 2)) * scale * 0.008;
  final bob = math.cos(phase * 2) * scale * 0.004 - flightLift;
  final groundY = scale * 0.80;
  final hip = Offset(
    (size.width * 0.54) + (stride * scale * 0.012),
    groundY - scale * 0.315 + bob,
  );
  final chest = Offset(hip.dx + scale * 0.074, hip.dy - scale * 0.205);
  final neck = Offset(chest.dx + scale * 0.032, chest.dy - scale * 0.065);
  final head = Offset(neck.dx + scale * 0.042, neck.dy - scale * 0.050);
  final shoulderFront = Offset(
    chest.dx + scale * 0.074,
    chest.dy - scale * 0.002,
  );
  final shoulderRear = Offset(
    chest.dx - scale * 0.078,
    chest.dy + scale * 0.018,
  );
  final hipFront = Offset(hip.dx + scale * 0.056, hip.dy - scale * 0.004);
  final hipRear = Offset(hip.dx - scale * 0.058, hip.dy + scale * 0.008);
  final frontLegCycle = (normalizedProgress + 0.43) % 1.0;
  final rearLegCycle = (frontLegCycle + 0.50) % 1.0;

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
      cycle: frontLegCycle,
      scale: scale,
      groundY: groundY,
    ),
    rearLeg: _legPose(
      anchor: hipRear,
      cycle: rearLegCycle,
      scale: scale,
      groundY: groundY,
    ),
    frontArm: _armPose(
      anchor: shoulderFront,
      cycle: (frontLegCycle + 0.50) % 1.0,
      scale: scale,
    ),
    rearArm: _armPose(anchor: shoulderRear, cycle: frontLegCycle, scale: scale),
  );
}

SampleRunnerLegPose _legPose({
  required Offset anchor,
  required double cycle,
  required double scale,
  required double groundY,
}) {
  final upperLegLength = scale * 0.190;
  final lowerLegLength = scale * 0.215;
  final key = _sampleLegKey(cycle);
  final ankleTarget = Offset(
    anchor.dx + scale * key.ankleX,
    groundY - scale * key.ankleLift,
  );
  final kneeHint = Offset(
    anchor.dx + scale * key.kneeX,
    anchor.dy + scale * key.kneeDrop,
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
    toe: limb.end + _fixedFootVector(cycle, scale),
  );
}

SampleRunnerArmPose _armPose({
  required Offset anchor,
  required double cycle,
  required double scale,
}) {
  final upperArmLength = scale * 0.105;
  final forearmLength = scale * 0.098;
  final key = _sampleArmKey(cycle);
  final wristTarget = Offset(
    anchor.dx + scale * key.wristX,
    anchor.dy + scale * key.wristDrop,
  );
  final elbowHint = Offset(
    anchor.dx + scale * key.elbowX,
    anchor.dy + scale * key.elbowDrop,
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

class _LegGaitKey {
  final double phase;
  final double ankleX;
  final double ankleLift;
  final double kneeX;
  final double kneeDrop;

  const _LegGaitKey({
    required this.phase,
    required this.ankleX,
    required this.ankleLift,
    required this.kneeX,
    required this.kneeDrop,
  });
}

class _ArmGaitKey {
  final double phase;
  final double wristX;
  final double wristDrop;
  final double elbowX;
  final double elbowDrop;

  const _ArmGaitKey({
    required this.phase,
    required this.wristX,
    required this.wristDrop,
    required this.elbowX,
    required this.elbowDrop,
  });
}

const List<_LegGaitKey> _legGaitKeys = [
  _LegGaitKey(
    phase: 0.00,
    ankleX: 0.10,
    ankleLift: 0.010,
    kneeX: 0.060,
    kneeDrop: 0.175,
  ),
  _LegGaitKey(
    phase: 0.18,
    ankleX: -0.245,
    ankleLift: 0.000,
    kneeX: -0.100,
    kneeDrop: 0.192,
  ),
  _LegGaitKey(
    phase: 0.40,
    ankleX: -0.070,
    ankleLift: 0.145,
    kneeX: 0.060,
    kneeDrop: 0.132,
  ),
  _LegGaitKey(
    phase: 0.68,
    ankleX: 0.245,
    ankleLift: 0.180,
    kneeX: 0.228,
    kneeDrop: 0.038,
  ),
  _LegGaitKey(
    phase: 0.84,
    ankleX: 0.248,
    ankleLift: 0.052,
    kneeX: 0.158,
    kneeDrop: 0.142,
  ),
  _LegGaitKey(
    phase: 1.00,
    ankleX: 0.10,
    ankleLift: 0.010,
    kneeX: 0.060,
    kneeDrop: 0.175,
  ),
];

const List<_ArmGaitKey> _armGaitKeys = [
  _ArmGaitKey(
    phase: 0.00,
    wristX: 0.128,
    wristDrop: 0.050,
    elbowX: 0.062,
    elbowDrop: 0.094,
  ),
  _ArmGaitKey(
    phase: 0.25,
    wristX: 0.046,
    wristDrop: 0.138,
    elbowX: 0.022,
    elbowDrop: 0.126,
  ),
  _ArmGaitKey(
    phase: 0.50,
    wristX: -0.120,
    wristDrop: 0.150,
    elbowX: -0.070,
    elbowDrop: 0.088,
  ),
  _ArmGaitKey(
    phase: 0.75,
    wristX: -0.010,
    wristDrop: 0.128,
    elbowX: 0.000,
    elbowDrop: 0.124,
  ),
  _ArmGaitKey(
    phase: 1.00,
    wristX: 0.128,
    wristDrop: 0.050,
    elbowX: 0.062,
    elbowDrop: 0.094,
  ),
];

_LegGaitKey _sampleLegKey(double cycle) {
  final pair = _keyPair(_legGaitKeys, cycle);
  final t = _smoothStep(pair.t);
  return _LegGaitKey(
    phase: cycle,
    ankleX: _mix(pair.a.ankleX, pair.b.ankleX, t),
    ankleLift: _mix(pair.a.ankleLift, pair.b.ankleLift, t),
    kneeX: _mix(pair.a.kneeX, pair.b.kneeX, t),
    kneeDrop: _mix(pair.a.kneeDrop, pair.b.kneeDrop, t),
  );
}

_ArmGaitKey _sampleArmKey(double cycle) {
  final pair = _keyPair(_armGaitKeys, cycle);
  final t = _smoothStep(pair.t);
  return _ArmGaitKey(
    phase: cycle,
    wristX: _mix(pair.a.wristX, pair.b.wristX, t),
    wristDrop: _mix(pair.a.wristDrop, pair.b.wristDrop, t),
    elbowX: _mix(pair.a.elbowX, pair.b.elbowX, t),
    elbowDrop: _mix(pair.a.elbowDrop, pair.b.elbowDrop, t),
  );
}

({T a, T b, double t}) _keyPair<T extends Object>(List<T> keys, double cycle) {
  double phaseOf(T key) {
    if (key case _LegGaitKey legKey) return legKey.phase;
    if (key case _ArmGaitKey armKey) return armKey.phase;
    return (key as _FootGaitKey).phase;
  }

  final normalized = cycle % 1.0;
  for (var index = 0; index < keys.length - 1; index += 1) {
    final current = keys[index];
    final next = keys[index + 1];
    final start = phaseOf(current);
    final end = phaseOf(next);
    if (normalized >= start && normalized <= end) {
      return (a: current, b: next, t: (normalized - start) / (end - start));
    }
  }
  return (a: keys.first, b: keys[1], t: 0);
}

double _smoothStep(double value) {
  final t = value.clamp(0, 1).toDouble();
  return t * t * (3 - (2 * t));
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

Offset _fixedFootVector(double cycle, double scale) {
  final pair = _keyPair(_footGaitKeys, cycle);
  final t = _smoothStep(pair.t);
  final rawDirection = Offset(
    _mix(pair.a.x, pair.b.x, t),
    _mix(pair.a.y, pair.b.y, t),
  );
  return rawDirection / rawDirection.distance * (scale * 0.060);
}

class _FootGaitKey {
  final double phase;
  final double x;
  final double y;

  const _FootGaitKey({required this.phase, required this.x, required this.y});
}

const List<_FootGaitKey> _footGaitKeys = [
  _FootGaitKey(phase: 0.00, x: 0.98, y: 0.08),
  _FootGaitKey(phase: 0.18, x: 0.96, y: -0.02),
  _FootGaitKey(phase: 0.40, x: 0.82, y: 0.30),
  _FootGaitKey(phase: 0.68, x: 0.90, y: 0.18),
  _FootGaitKey(phase: 0.84, x: 0.98, y: 0.05),
  _FootGaitKey(phase: 1.00, x: 0.98, y: 0.08),
];

double _mix(double a, double b, double t) => a + (b - a) * t;
