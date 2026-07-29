import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'running_professional_runner.dart';

const _professionalRunnerArtAsset =
    'assets/images/running_guides/professional_runner/'
    'professional_runner_pose_atlas_v2.png';

Future<ui.Image>? _professionalRunnerArtFuture;

/// Loads the two-pose professional runner artwork once for all reports.
Future<ui.Image> loadProfessionalRunnerArtAtlas() {
  return _professionalRunnerArtFuture ??= _loadProfessionalRunnerArtAtlas();
}

Future<ui.Image> _loadProfessionalRunnerArtAtlas() async {
  final data = await rootBundle.load(_professionalRunnerArtAsset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}

/// Renders a complete, generic professional runner whose placement is driven
/// by the analyzed pose. The art is a coaching model, never a reconstruction
/// of the runner in the uploaded video.
///
/// The current side uses an overstride reference while the goal side uses a
/// compact, efficient contact reference. A deliberately restrained lead-leg
/// path keeps the visual traceable to the source coordinates without turning
/// the athlete back into a joint avatar. The versioned asset name is
/// intentional: a previously deployed joint-avatar comparison must never be
/// reused from a browser asset cache after this renderer is introduced.
void paintIllustratedProfessionalRunner(
  ui.Canvas canvas, {
  required ui.Image atlas,
  required RunningProfessionalRunnerPose pose,
  required ui.Color accentColor,
  required bool isTarget,
  ui.Rect? bounds,
  Set<int> focusIndices = const <int>{},
}) {
  final reference = isTarget
      ? _ProfessionalRunnerReference.efficientContact
      : _ProfessionalRunnerReference.overstride;
  final placement = _placementFor(pose, reference, bounds: bounds);

  canvas.save();
  if (pose.forward < 0) {
    canvas.translate(placement.rect.center.dx * 2, 0);
    canvas.scale(-1, 1);
  }
  canvas.drawImageRect(
    atlas,
    _sourceRect(reference),
    placement.rect,
    (ui.Paint()
      ..filterQuality = ui.FilterQuality.high
      ..isAntiAlias = true
      ..color = const ui.Color(0xFFFFFFFF)),
  );
  canvas.restore();

  _drawMeasuredLeadLegTrace(
    canvas,
    pose: pose,
    accentColor: accentColor,
    focusIndices: focusIndices,
  );
}

enum _ProfessionalRunnerReference { overstride, efficientContact }

class _RunnerPlacement {
  final ui.Rect rect;

  const _RunnerPlacement(this.rect);
}

/// Crops include transparent breathing room so a complete head, arm, and shoe
/// stay visible when a narrow mobile panel crops the canvas.
ui.Rect _sourceRect(_ProfessionalRunnerReference reference) {
  return switch (reference) {
    _ProfessionalRunnerReference.overstride =>
      const ui.Rect.fromLTWH(22, 116, 622, 914),
    _ProfessionalRunnerReference.efficientContact =>
      const ui.Rect.fromLTWH(646, 138, 508, 894),
  };
}

_RunnerPlacement _placementFor(
  RunningProfessionalRunnerPose pose,
  _ProfessionalRunnerReference reference, {
  ui.Rect? bounds,
}) {
  final points = pose.points;
  final top = _topOfPose(points, pose);
  final ground = _groundOfPose(points);
  final bodyHeight = math.max(ground - top, pose.bodyScale * 3.05);
  final source = _sourceRect(reference);
  final scale = bodyHeight * 1.035 / source.height;
  var width = source.width * scale;
  var height = source.height * scale;
  final sourceHipFraction = switch (reference) {
    _ProfessionalRunnerReference.overstride => 0.445,
    _ProfessionalRunnerReference.efficientContact => 0.555,
  };
  final sourceTopFraction = switch (reference) {
    _ProfessionalRunnerReference.overstride => 0.018,
    _ProfessionalRunnerReference.efficientContact => 0.02,
  };
  final visualHipFraction =
      pose.forward < 0 ? 1 - sourceHipFraction : sourceHipFraction;
  var left = pose.hipCenter.dx - width * visualHipFraction;
  var placementTop = top - height * sourceTopFraction;
  if (bounds != null && !bounds.isEmpty) {
    final inset = math.min(10.0, bounds.shortestSide * 0.06);
    final available = bounds.deflate(inset);
    final fit = math.min(
      1.0,
      math.min(available.width / width, available.height / height),
    );
    width *= fit;
    height *= fit;
    left = pose.hipCenter.dx - width * visualHipFraction;
    placementTop = top - height * sourceTopFraction;
    left = left.clamp(available.left, available.right - width).toDouble();
    placementTop =
        placementTop.clamp(available.top, available.bottom - height).toDouble();
  }
  return _RunnerPlacement(
    ui.Rect.fromLTWH(left, placementTop, width, height),
  );
}

double _topOfPose(
    Map<int, ui.Offset> points, RunningProfessionalRunnerPose pose) {
  final projectedHeadTop = pose.headCenter -
      ui.Offset(
        pose.downAxis.dx * pose.bodyScale * 0.14,
        pose.downAxis.dy * pose.bodyScale * 0.14,
      );
  final candidates = <ui.Offset>[
    projectedHeadTop,
    pose.neck,
    if (points[0] case final ui.Offset point) point,
    if (points[7] case final ui.Offset point) point,
    if (points[8] case final ui.Offset point) point,
    if (points[11] case final ui.Offset point) point,
    if (points[12] case final ui.Offset point) point,
  ];
  return candidates.map((point) => point.dy).reduce(math.min);
}

double _groundOfPose(Map<int, ui.Offset> points) {
  final candidates = <ui.Offset>[
    if (points[27] case final ui.Offset point) point,
    if (points[28] case final ui.Offset point) point,
    if (points[29] case final ui.Offset point) point,
    if (points[30] case final ui.Offset point) point,
    if (points[31] case final ui.Offset point) point,
    if (points[32] case final ui.Offset point) point,
  ];
  if (candidates.isEmpty) return _poseFallbackGround(points);
  return candidates.map((point) => point.dy).reduce(math.max);
}

double _poseFallbackGround(Map<int, ui.Offset> points) {
  final hips = <ui.Offset>[
    if (points[23] case final ui.Offset point) point,
    if (points[24] case final ui.Offset point) point,
  ];
  if (hips.isEmpty) return 0;
  return hips.map((point) => point.dy).reduce(math.max);
}

void _drawMeasuredLeadLegTrace(
  ui.Canvas canvas, {
  required RunningProfessionalRunnerPose pose,
  required ui.Color accentColor,
  required Set<int> focusIndices,
}) {
  if (focusIndices.isEmpty) return;
  final indices = focusIndices.toList(growable: false)..sort();
  final hip = _firstMeasuredPoint(
    pose,
    indices.where((index) => index == 23 || index == 24),
  );
  final knee = _firstMeasuredPoint(
    pose,
    indices.where((index) => index == 25 || index == 26),
  );
  final ankle = _firstMeasuredPoint(
    pose,
    indices.where((index) => index == 27 || index == 28),
  );
  final toe = _firstMeasuredPoint(
    pose,
    indices.where((index) => index == 31 || index == 32),
  );
  if (hip == null || knee == null || ankle == null) return;

  final trace = ui.Path()
    ..moveTo(hip.dx, hip.dy)
    ..lineTo(knee.dx, knee.dy)
    ..lineTo(ankle.dx, ankle.dy);
  if (toe != null) trace.lineTo(toe.dx, toe.dy);
  final width = (pose.bodyScale * 0.013).clamp(1.0, 2.4).toDouble();
  canvas.drawPath(
    trace,
    ui.Paint()
      ..color = accentColor.withValues(alpha: 0.58)
      ..style = ui.PaintingStyle.stroke
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round
      ..strokeWidth = width,
  );
  final radius = (pose.bodyScale * 0.036).clamp(2.4, 8.0).toDouble();
  for (final point in <ui.Offset>[hip, knee, ankle, if (toe != null) toe]) {
    canvas.drawCircle(
      point,
      radius,
      ui.Paint()
        ..color = accentColor.withValues(alpha: 0.16)
        ..style = ui.PaintingStyle.fill,
    );
    canvas.drawCircle(
      point,
      radius * 0.57,
      ui.Paint()
        ..color = accentColor.withValues(alpha: 0.86)
        ..style = ui.PaintingStyle.fill,
    );
  }
}

ui.Offset? _firstMeasuredPoint(
  RunningProfessionalRunnerPose pose,
  Iterable<int> indices,
) {
  for (final index in indices) {
    if (!pose.measuredIndices.contains(index)) continue;
    final point = pose.points[index];
    if (point != null) return point;
  }
  return null;
}
