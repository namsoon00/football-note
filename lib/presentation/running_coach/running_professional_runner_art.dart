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

/// The source artwork faces to the right. Mirror it only for a runner whose
/// measured visual heading is right-to-left.
bool shouldMirrorProfessionalRunnerArt(double forward) => forward < 0;

/// Renders a complete, generic professional runner whose placement is driven
/// by the analyzed pose. The art is a coaching model, never a reconstruction
/// of the runner in the uploaded video.
///
/// The current side uses an overstride reference while the goal side uses a
/// compact, efficient contact reference. A restrained focus trace keeps the
/// selected body region traceable to the source coordinates without turning
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
  final shouldMirror = shouldMirrorProfessionalRunnerArt(pose.forward);

  canvas.save();
  if (shouldMirror) {
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

  _drawMeasuredFocusTrace(
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
  final visualHipFraction = shouldMirrorProfessionalRunnerArt(pose.forward)
      ? 1 - sourceHipFraction
      : sourceHipFraction;
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

void _drawMeasuredFocusTrace(
  ui.Canvas canvas, {
  required RunningProfessionalRunnerPose pose,
  required ui.Color accentColor,
  required Set<int> focusIndices,
}) {
  if (focusIndices.isEmpty) return;
  final traces = <List<ui.Offset>>[];

  final shoulders = _measuredCenter(pose, const <int>[11, 12]);
  final hips = _measuredCenter(pose, const <int>[23, 24]);
  final head = _firstMeasuredPoint(pose, const <int>[0, 7, 8]);
  final torsoFocused = const <int>{11, 12, 23, 24}.any(
    focusIndices.contains,
  );
  final headFocused = const <int>{0, 7, 8}.any(focusIndices.contains);
  if (head != null && shoulders != null && (headFocused || torsoFocused)) {
    traces.add(<ui.Offset>[head, shoulders]);
  }
  if (shoulders != null && hips != null && torsoFocused) {
    traces.add(<ui.Offset>[shoulders, hips]);
  }

  void addChain(List<int> indices) {
    if (!indices.any(focusIndices.contains)) return;
    final points = <ui.Offset>[
      for (final index in indices)
        if (pose.measuredIndices.contains(index) && pose.points[index] != null)
          pose.points[index]!,
    ];
    if (points.length >= 2) traces.add(points);
  }

  addChain(const <int>[11, 13, 15]);
  addChain(const <int>[12, 14, 16]);
  addChain(const <int>[23, 25, 27, 31]);
  addChain(const <int>[24, 26, 28, 32]);

  if (traces.isEmpty) return;
  final width = (pose.bodyScale * 0.018).clamp(2.6, 5.2).toDouble();
  final markerPoints = <ui.Offset>{};
  for (final points in traces) {
    markerPoints.addAll(points);
    final trace = ui.Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      trace.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      trace,
      ui.Paint()
        ..color = accentColor.withValues(alpha: 0.16)
        ..style = ui.PaintingStyle.stroke
        ..strokeCap = ui.StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round
        ..strokeWidth = width * 2.25,
    );
    canvas.drawPath(
      trace,
      ui.Paint()
        ..color = accentColor.withValues(alpha: 0.94)
        ..style = ui.PaintingStyle.stroke
        ..strokeCap = ui.StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round
        ..strokeWidth = width,
    );
  }
  final radius = (pose.bodyScale * 0.040).clamp(3.4, 8.6).toDouble();
  for (final point in markerPoints) {
    canvas.drawCircle(
      point,
      radius,
      ui.Paint()
        ..color = accentColor.withValues(alpha: 0.16)
        ..style = ui.PaintingStyle.fill,
    );
    canvas.drawCircle(
      point,
      radius * 0.60,
      ui.Paint()
        ..color = accentColor.withValues(alpha: 0.96)
        ..style = ui.PaintingStyle.fill,
    );
    canvas.drawCircle(
      point,
      radius * 0.22,
      ui.Paint()..color = const ui.Color(0xFFF8FBFF),
    );
  }
}

ui.Offset? _measuredCenter(
  RunningProfessionalRunnerPose pose,
  List<int> indices,
) {
  final points = <ui.Offset>[
    for (final index in indices)
      if (pose.measuredIndices.contains(index) && pose.points[index] != null)
        pose.points[index]!,
  ];
  if (points.isEmpty) return null;
  final sum = points.fold<ui.Offset>(ui.Offset.zero, (total, point) {
    return total + point;
  });
  return sum / points.length.toDouble();
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
