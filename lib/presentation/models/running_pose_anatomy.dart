import 'dart:math' as math;
import 'dart:ui';

import '../../domain/entities/running_live_coaching_state.dart';
import '../../realtime_analysis/running_coaching/running_visual_pose_tracker.dart';

class RunningPoseAnatomyGeometry {
  final double bodyScale;
  final Rect? headEllipse;
  final Offset? neck;
  final List<Offset> torsoPolygon;
  final List<RunningPoseAnatomySegment> segments;
  final List<RunningPoseAnatomyJoint> joints;
  final List<RunningPoseAnatomyFoot> feet;
  final RunningPoseAnatomyCenterline? centerline;

  const RunningPoseAnatomyGeometry({
    required this.bodyScale,
    required this.headEllipse,
    required this.neck,
    required this.torsoPolygon,
    required this.segments,
    required this.joints,
    required this.feet,
    required this.centerline,
  });
}

class RunningPoseAnatomySegment {
  final RunningPoseLandmarkType fromType;
  final RunningPoseLandmarkType toType;
  final Offset from;
  final Offset to;
  final double width;
  final double opacity;
  final bool dashed;
  final RunningFootSide? side;

  const RunningPoseAnatomySegment({
    required this.fromType,
    required this.toType,
    required this.from,
    required this.to,
    required this.width,
    required this.opacity,
    required this.dashed,
    required this.side,
  });
}

class RunningPoseAnatomyJoint {
  final RunningPoseLandmarkType type;
  final Offset center;
  final double radius;
  final double opacity;
  final bool inferred;

  const RunningPoseAnatomyJoint({
    required this.type,
    required this.center,
    required this.radius,
    required this.opacity,
    required this.inferred,
  });
}

class RunningPoseAnatomyFoot {
  final RunningFootSide side;
  final Offset ankle;
  final Offset heel;
  final Offset toe;
  final double width;
  final double opacity;
  final bool dashed;

  const RunningPoseAnatomyFoot({
    required this.side,
    required this.ankle,
    required this.heel,
    required this.toe,
    required this.width,
    required this.opacity,
    required this.dashed,
  });
}

class RunningPoseAnatomyCenterline {
  final Offset from;
  final Offset to;
  final double opacity;

  const RunningPoseAnatomyCenterline({
    required this.from,
    required this.to,
    required this.opacity,
  });
}

RunningPoseAnatomyGeometry buildRunningPoseAnatomyGeometry({
  required Map<RunningPoseLandmarkType, RunningVisualPoseLandmark> landmarks,
  required Size canvasSize,
}) {
  final bodyScale = _estimateBodyScale(landmarks, canvasSize);
  final limbWidth = (bodyScale * 0.034).clamp(3.4, 13.0).toDouble();
  final jointRadius = (bodyScale * 0.022).clamp(2.6, 7.5).toDouble();
  final depthRange = _DepthRange(landmarks.values);
  final torsoPolygon = _torsoPolygon(landmarks);
  final neck = _pairMidpoint(
    landmarks,
    RunningPoseLandmarkType.leftShoulder,
    RunningPoseLandmarkType.rightShoulder,
  );
  final hipCenter = _pairMidpoint(
    landmarks,
    RunningPoseLandmarkType.leftHip,
    RunningPoseLandmarkType.rightHip,
  );
  final headEllipse = _headEllipse(landmarks, bodyScale);

  final segments = <RunningPoseAnatomySegment>[
    for (final segment in _anatomicalSegments)
      if (_segmentGeometry(
        landmarks,
        segment,
        bodyScale: bodyScale,
        limbWidth: limbWidth,
        depthRange: depthRange,
      )
          case final geometry?)
        geometry,
  ];

  final feet = <RunningPoseAnatomyFoot>[
    if (_footGeometry(
      landmarks,
      RunningFootSide.left,
      bodyScale: bodyScale,
      depthRange: depthRange,
    )
        case final foot?)
      foot,
    if (_footGeometry(
      landmarks,
      RunningFootSide.right,
      bodyScale: bodyScale,
      depthRange: depthRange,
    )
        case final foot?)
      foot,
  ];

  final joints = <RunningPoseAnatomyJoint>[
    for (final entry in landmarks.entries)
      if (entry.value.confidence > 0.035)
        RunningPoseAnatomyJoint(
          type: entry.key,
          center: entry.value.position,
          radius: jointRadius,
          opacity: _landmarkOpacity(entry.value, depthRange),
          inferred:
              entry.value.state != RunningVisualPoseLandmarkState.observed,
        ),
  ];

  final centerline = neck == null || hipCenter == null
      ? null
      : RunningPoseAnatomyCenterline(
          from: headEllipse?.bottomCenter ?? neck,
          to: hipCenter,
          opacity: 0.44,
        );

  return RunningPoseAnatomyGeometry(
    bodyScale: bodyScale,
    headEllipse: headEllipse,
    neck: neck,
    torsoPolygon: torsoPolygon,
    segments: segments,
    joints: joints,
    feet: feet,
    centerline: centerline,
  );
}

class _AnatomicalSegmentSpec {
  final RunningPoseLandmarkType from;
  final RunningPoseLandmarkType to;
  final RunningFootSide? side;
  final double widthScale;

  const _AnatomicalSegmentSpec({
    required this.from,
    required this.to,
    required this.side,
    this.widthScale = 1,
  });
}

const List<_AnatomicalSegmentSpec> _anatomicalSegments = [
  _AnatomicalSegmentSpec(
    from: RunningPoseLandmarkType.leftShoulder,
    to: RunningPoseLandmarkType.leftElbow,
    side: RunningFootSide.left,
  ),
  _AnatomicalSegmentSpec(
    from: RunningPoseLandmarkType.leftElbow,
    to: RunningPoseLandmarkType.leftWrist,
    side: RunningFootSide.left,
    widthScale: 0.82,
  ),
  _AnatomicalSegmentSpec(
    from: RunningPoseLandmarkType.rightShoulder,
    to: RunningPoseLandmarkType.rightElbow,
    side: RunningFootSide.right,
  ),
  _AnatomicalSegmentSpec(
    from: RunningPoseLandmarkType.rightElbow,
    to: RunningPoseLandmarkType.rightWrist,
    side: RunningFootSide.right,
    widthScale: 0.82,
  ),
  _AnatomicalSegmentSpec(
    from: RunningPoseLandmarkType.leftHip,
    to: RunningPoseLandmarkType.leftKnee,
    side: RunningFootSide.left,
    widthScale: 1.22,
  ),
  _AnatomicalSegmentSpec(
    from: RunningPoseLandmarkType.leftKnee,
    to: RunningPoseLandmarkType.leftAnkle,
    side: RunningFootSide.left,
    widthScale: 1.04,
  ),
  _AnatomicalSegmentSpec(
    from: RunningPoseLandmarkType.rightHip,
    to: RunningPoseLandmarkType.rightKnee,
    side: RunningFootSide.right,
    widthScale: 1.22,
  ),
  _AnatomicalSegmentSpec(
    from: RunningPoseLandmarkType.rightKnee,
    to: RunningPoseLandmarkType.rightAnkle,
    side: RunningFootSide.right,
    widthScale: 1.04,
  ),
];

RunningPoseAnatomySegment? _segmentGeometry(
  Map<RunningPoseLandmarkType, RunningVisualPoseLandmark> landmarks,
  _AnatomicalSegmentSpec segment, {
  required double bodyScale,
  required double limbWidth,
  required _DepthRange depthRange,
}) {
  final from = landmarks[segment.from];
  final to = landmarks[segment.to];
  if (from == null || to == null) {
    return null;
  }

  final opacity = math.min(
    _landmarkOpacity(from, depthRange),
    _landmarkOpacity(to, depthRange),
  );
  if (opacity <= 0.025) {
    return null;
  }
  return RunningPoseAnatomySegment(
    fromType: segment.from,
    toType: segment.to,
    from: from.position,
    to: to.position,
    width: limbWidth * segment.widthScale,
    opacity: opacity,
    dashed: opacity < 0.5 ||
        from.state != RunningVisualPoseLandmarkState.observed ||
        to.state != RunningVisualPoseLandmarkState.observed,
    side: segment.side,
  );
}

RunningPoseAnatomyFoot? _footGeometry(
  Map<RunningPoseLandmarkType, RunningVisualPoseLandmark> landmarks,
  RunningFootSide side, {
  required double bodyScale,
  required _DepthRange depthRange,
}) {
  final ankleType = side == RunningFootSide.left
      ? RunningPoseLandmarkType.leftAnkle
      : RunningPoseLandmarkType.rightAnkle;
  final heelType = side == RunningFootSide.left
      ? RunningPoseLandmarkType.leftHeel
      : RunningPoseLandmarkType.rightHeel;
  final toeType = side == RunningFootSide.left
      ? RunningPoseLandmarkType.leftFootIndex
      : RunningPoseLandmarkType.rightFootIndex;
  final ankle = landmarks[ankleType];
  final heel = landmarks[heelType];
  final toe = landmarks[toeType];
  if (ankle == null || heel == null || toe == null) {
    return null;
  }
  final opacity = [
    _landmarkOpacity(ankle, depthRange),
    _landmarkOpacity(heel, depthRange),
    _landmarkOpacity(toe, depthRange),
  ].reduce(math.min);
  if (opacity <= 0.025) {
    return null;
  }
  return RunningPoseAnatomyFoot(
    side: side,
    ankle: ankle.position,
    heel: heel.position,
    toe: toe.position,
    width: (bodyScale * 0.026).clamp(3.0, 9.0).toDouble(),
    opacity: opacity,
    dashed: opacity < 0.5 ||
        ankle.state != RunningVisualPoseLandmarkState.observed ||
        heel.state != RunningVisualPoseLandmarkState.observed ||
        toe.state != RunningVisualPoseLandmarkState.observed,
  );
}

List<Offset> _torsoPolygon(
  Map<RunningPoseLandmarkType, RunningVisualPoseLandmark> landmarks,
) {
  final leftShoulder = landmarks[RunningPoseLandmarkType.leftShoulder];
  final rightShoulder = landmarks[RunningPoseLandmarkType.rightShoulder];
  final rightHip = landmarks[RunningPoseLandmarkType.rightHip];
  final leftHip = landmarks[RunningPoseLandmarkType.leftHip];
  if (leftShoulder == null ||
      rightShoulder == null ||
      rightHip == null ||
      leftHip == null) {
    return const <Offset>[];
  }
  return <Offset>[
    leftShoulder.position,
    rightShoulder.position,
    rightHip.position,
    leftHip.position,
  ];
}

Rect? _headEllipse(
  Map<RunningPoseLandmarkType, RunningVisualPoseLandmark> landmarks,
  double bodyScale,
) {
  final nose = landmarks[RunningPoseLandmarkType.nose];
  final leftEar = landmarks[RunningPoseLandmarkType.leftEar];
  final rightEar = landmarks[RunningPoseLandmarkType.rightEar];
  final shoulderCenter = _pairMidpoint(
    landmarks,
    RunningPoseLandmarkType.leftShoulder,
    RunningPoseLandmarkType.rightShoulder,
  );
  if (nose == null && shoulderCenter == null) {
    return null;
  }

  final earCenter = leftEar != null && rightEar != null
      ? _midpoint(leftEar.position, rightEar.position)
      : null;
  final headWidth = leftEar != null && rightEar != null
      ? (_distance(leftEar.position, rightEar.position) * 1.28)
          .clamp(bodyScale * 0.16, bodyScale * 0.38)
          .toDouble()
      : (bodyScale * 0.25).clamp(16.0, 58.0).toDouble();
  final center = earCenter ??
      (nose == null || shoulderCenter == null
          ? (nose?.position ?? shoulderCenter!)
          : Offset(
              nose.position.dx,
              nose.position.dy - (bodyScale * 0.035),
            ));
  final height = headWidth * 1.18;
  return Rect.fromCenter(center: center, width: headWidth, height: height);
}

double _estimateBodyScale(
  Map<RunningPoseLandmarkType, RunningVisualPoseLandmark> landmarks,
  Size canvasSize,
) {
  final shoulderCenter = _pairMidpoint(
    landmarks,
    RunningPoseLandmarkType.leftShoulder,
    RunningPoseLandmarkType.rightShoulder,
  );
  final hipCenter = _pairMidpoint(
    landmarks,
    RunningPoseLandmarkType.leftHip,
    RunningPoseLandmarkType.rightHip,
  );
  final ankleCenter = _pairMidpoint(
    landmarks,
    RunningPoseLandmarkType.leftAnkle,
    RunningPoseLandmarkType.rightAnkle,
  );
  if (shoulderCenter != null && hipCenter != null && ankleCenter != null) {
    return math.max(
      _distance(shoulderCenter, hipCenter),
      _distance(hipCenter, ankleCenter),
    );
  }
  if (landmarks.length >= 2) {
    final xs = landmarks.values.map((landmark) => landmark.position.dx);
    final ys = landmarks.values.map((landmark) => landmark.position.dy);
    return math.max(
      xs.reduce(math.max) - xs.reduce(math.min),
      ys.reduce(math.max) - ys.reduce(math.min),
    );
  }
  return math.max(1, canvasSize.shortestSide * 0.22);
}

double _landmarkOpacity(
  RunningVisualPoseLandmark landmark,
  _DepthRange depthRange,
) {
  final stateFactor = switch (landmark.state) {
    RunningVisualPoseLandmarkState.observed => 1.0,
    RunningVisualPoseLandmarkState.inferred => 0.72,
    RunningVisualPoseLandmarkState.occluded => 0.46,
  };
  return (landmark.confidence * stateFactor * depthRange.opacity(landmark))
      .clamp(0.0, 1.0)
      .toDouble();
}

class _DepthRange {
  final double minDepth;
  final double maxDepth;

  factory _DepthRange(Iterable<RunningVisualPoseLandmark> landmarks) {
    final depths = [
      for (final landmark in landmarks) landmark.worldZ ?? landmark.z,
    ];
    if (depths.isEmpty) {
      return const _DepthRange._(0, 0);
    }
    return _DepthRange._(depths.reduce(math.min), depths.reduce(math.max));
  }

  const _DepthRange._(this.minDepth, this.maxDepth);

  double opacity(RunningVisualPoseLandmark landmark) {
    final range = maxDepth - minDepth;
    if (range.abs() < 0.0001) {
      return 1;
    }
    final depth = landmark.worldZ ?? landmark.z;
    final farRatio = ((depth - minDepth) / range).clamp(0.0, 1.0);
    return (0.54 + ((1.0 - farRatio) * 0.46)).toDouble();
  }
}

Offset? _pairMidpoint(
  Map<RunningPoseLandmarkType, RunningVisualPoseLandmark> landmarks,
  RunningPoseLandmarkType firstType,
  RunningPoseLandmarkType secondType,
) {
  final first = landmarks[firstType];
  final second = landmarks[secondType];
  if (first == null || second == null) {
    return null;
  }
  return _midpoint(first.position, second.position);
}

Offset _midpoint(Offset first, Offset second) {
  return Offset((first.dx + second.dx) / 2, (first.dy + second.dy) / 2);
}

double _distance(Offset first, Offset second) {
  final dx = first.dx - second.dx;
  final dy = first.dy - second.dy;
  return math.sqrt((dx * dx) + (dy * dy));
}
