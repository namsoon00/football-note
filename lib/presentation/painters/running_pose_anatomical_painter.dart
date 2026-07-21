import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/running_live_coaching_state.dart';
import '../../realtime_analysis/running_coaching/running_visual_pose_tracker.dart';
import '../models/camera_viewport_transform.dart';
import '../models/running_pose_anatomy.dart';

class RunningPoseAnatomicalPainter extends CustomPainter {
  final ValueListenable<RunningVisualPoseFrame?> frameListenable;
  final bool mirrorHorizontally;
  final BoxFit fit;

  RunningPoseAnatomicalPainter({
    required this.frameListenable,
    required this.mirrorHorizontally,
    this.fit = BoxFit.cover,
  }) : super(repaint: frameListenable);

  static const Color _nearColor = Color(0xFF79F2BA);
  static const Color _farColor = Color(0xFF65B7FF);
  static const Color _centerlineColor = Color(0xFFEFFFF9);
  static const Color _jointColor = Color(0xFFF8FFF9);

  @override
  void paint(Canvas canvas, Size size) {
    final frame = frameListenable.value;
    if (frame == null || frame.landmarks.isEmpty) {
      return;
    }

    final transform = fit == BoxFit.cover
        ? CameraViewportTransform.cover(
            sourceSize: frame.imageSize,
            viewportSize: size,
            mirrorHorizontally: mirrorHorizontally,
          )
        : CameraViewportTransform.fit(
            sourceSize: frame.imageSize,
            viewportSize: size,
            fit: fit,
            mirrorHorizontally: mirrorHorizontally,
          );
    if (!transform.isValid) {
      return;
    }

    final projectedLandmarks =
        <RunningPoseLandmarkType, RunningVisualPoseLandmark>{
      for (final entry in frame.landmarks.entries)
        entry.key: _projectLandmark(entry.value, transform),
    };
    final anatomy = buildRunningPoseAnatomyGeometry(
      landmarks: projectedLandmarks,
      canvasSize: size,
    );

    _drawTorso(canvas, anatomy);
    _drawHeadAndNeck(canvas, anatomy);
    _drawCenterline(canvas, anatomy);
    _drawSegments(canvas, anatomy);
    _drawFeet(canvas, anatomy);
    _drawJoints(canvas, anatomy);
  }

  RunningVisualPoseLandmark _projectLandmark(
    RunningVisualPoseLandmark landmark,
    CameraViewportTransform transform,
  ) {
    return RunningVisualPoseLandmark(
      position: transform.project(landmark.position),
      confidence: landmark.confidence,
      rawConfidence: landmark.rawConfidence,
      z: landmark.z,
      worldZ: landmark.worldZ,
      visibility: landmark.visibility,
      presence: landmark.presence,
      state: landmark.state,
    );
  }

  void _drawTorso(Canvas canvas, RunningPoseAnatomyGeometry anatomy) {
    if (anatomy.torsoPolygon.length != 4) {
      return;
    }
    final path = Path()..addPolygon(anatomy.torsoPolygon, true);
    final fill = Paint()
      ..color = _nearColor.withAlpha(34)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = _nearColor.withAlpha(145)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (anatomy.bodyScale * 0.012).clamp(1.4, 4.0)
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawHeadAndNeck(Canvas canvas, RunningPoseAnatomyGeometry anatomy) {
    final head = anatomy.headEllipse;
    if (head != null) {
      final fill = Paint()
        ..color = _nearColor.withAlpha(42)
        ..style = PaintingStyle.fill;
      final stroke = Paint()
        ..color = _jointColor.withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (anatomy.bodyScale * 0.012).clamp(1.2, 3.8);
      canvas.drawOval(head, fill);
      canvas.drawOval(head, stroke);
    }

    final neck = anatomy.neck;
    if (neck != null && head != null) {
      final paint = Paint()
        ..color = _jointColor.withAlpha(150)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = (anatomy.bodyScale * 0.018).clamp(2.0, 6.0);
      canvas.drawLine(neck, head.bottomCenter, paint);
    }
  }

  void _drawCenterline(Canvas canvas, RunningPoseAnatomyGeometry anatomy) {
    final centerline = anatomy.centerline;
    if (centerline == null) {
      return;
    }
    final paint = Paint()
      ..color = _centerlineColor.withAlpha((centerline.opacity * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (anatomy.bodyScale * 0.008).clamp(1.0, 2.4);
    canvas.drawLine(centerline.from, centerline.to, paint);
  }

  void _drawSegments(Canvas canvas, RunningPoseAnatomyGeometry anatomy) {
    final orderedSegments = anatomy.segments.toList(growable: false)
      ..sort((first, second) => first.opacity.compareTo(second.opacity));
    for (final segment in orderedSegments) {
      final paint = Paint()
        ..color = _segmentColor(segment).withAlpha(
          (segment.opacity * 220).round().clamp(0, 220),
        )
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = segment.width;
      if (segment.dashed) {
        _drawDashedLine(
          canvas,
          segment.from,
          segment.to,
          paint,
          dashLength: math.max(5, segment.width * 1.55),
          gapLength: math.max(4, segment.width * 0.95),
        );
      } else {
        canvas.drawLine(segment.from, segment.to, paint);
      }
    }
  }

  void _drawFeet(Canvas canvas, RunningPoseAnatomyGeometry anatomy) {
    for (final foot in anatomy.feet) {
      final paint = Paint()
        ..color = _segmentColorForSide(foot.side).withAlpha(
          (foot.opacity * 230).round().clamp(0, 230),
        )
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = foot.width;
      final path = Path()
        ..moveTo(foot.heel.dx, foot.heel.dy)
        ..quadraticBezierTo(
          foot.ankle.dx,
          foot.ankle.dy,
          foot.toe.dx,
          foot.toe.dy,
        );
      if (foot.dashed) {
        _drawDashedPath(
          canvas,
          [foot.heel, foot.ankle, foot.toe],
          paint,
          dashLength: math.max(5, foot.width * 1.8),
          gapLength: math.max(4, foot.width),
        );
      } else {
        canvas.drawPath(path, paint);
      }

      final toePaint = Paint()
        ..color = _jointColor.withAlpha((foot.opacity * 160).round())
        ..style = PaintingStyle.fill;
      canvas.drawCircle(foot.heel, foot.width * 0.62, toePaint);
      canvas.drawCircle(foot.toe, foot.width * 0.68, toePaint);
    }
  }

  void _drawJoints(Canvas canvas, RunningPoseAnatomyGeometry anatomy) {
    for (final joint in anatomy.joints) {
      final alpha = (joint.opacity * 230).round().clamp(0, 230);
      if (alpha <= 0) {
        continue;
      }
      if (joint.inferred) {
        final paint = Paint()
          ..color = _jointColor.withAlpha(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (joint.radius * 0.34).clamp(1.0, 2.4);
        canvas.drawCircle(joint.center, joint.radius, paint);
      } else {
        final paint = Paint()
          ..color = _jointColor.withAlpha(alpha)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(joint.center, joint.radius, paint);
      }
    }
  }

  Color _segmentColor(RunningPoseAnatomySegment segment) {
    final side = segment.side;
    if (side == null) {
      return _nearColor;
    }
    return _segmentColorForSide(side);
  }

  Color _segmentColorForSide(RunningFootSide side) {
    return switch (side) {
      RunningFootSide.left => _nearColor,
      RunningFootSide.right => _farColor,
    };
  }

  void _drawDashedPath(
    Canvas canvas,
    List<Offset> points,
    Paint paint, {
    required double dashLength,
    required double gapLength,
  }) {
    for (var i = 0; i < points.length - 1; i++) {
      _drawDashedLine(
        canvas,
        points[i],
        points[i + 1],
        paint,
        dashLength: dashLength,
        gapLength: gapLength,
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint, {
    required double dashLength,
    required double gapLength,
  }) {
    final vector = to - from;
    final distance = vector.distance;
    if (distance <= 0) {
      return;
    }
    final direction = Offset(vector.dx / distance, vector.dy / distance);
    var traveled = 0.0;
    while (traveled < distance) {
      final start = traveled;
      final end = math.min(distance, start + dashLength);
      canvas.drawLine(
        from + (direction * start),
        from + (direction * end),
        paint,
      );
      traveled = end + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant RunningPoseAnatomicalPainter oldDelegate) {
    return oldDelegate.frameListenable != frameListenable ||
        oldDelegate.mirrorHorizontally != mirrorHorizontally ||
        oldDelegate.fit != fit;
  }
}
