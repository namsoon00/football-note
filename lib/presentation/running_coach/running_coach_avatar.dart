import 'dart:math' as math;
import 'dart:ui' as ui;

import 'running_professional_runner.dart';

/// Draws a compact, code-native coaching avatar for a measured running pose.
///
/// This deliberately has no image or bundle dependency: the comparison card
/// remains useful immediately on web and on a cold app launch. It is an
/// explanatory mannequin, not a reconstruction of the person in the video.
void paintRunningCoachAvatar(
  ui.Canvas canvas, {
  required RunningProfessionalRunnerPose pose,
  required ui.Rect bounds,
  required ui.Color accentColor,
  required bool isTarget,
}) {
  final points = pose.points;
  final scale = pose.bodyScale.clamp(26.0, 220.0).toDouble();
  final down = _unit(pose.downAxis);
  final across = _perpendicular(down);
  final forward = ui.Offset(pose.forward >= 0 ? 1 : -1, 0);
  const outline = ui.Color(0xFF101B2D);
  final shirt =
      isTarget ? const ui.Color(0xFF4B93E8) : const ui.Color(0xFF2E7DD2);
  const shorts = ui.Color(0xFF263B5B);
  const skin = ui.Color(0xFFE4A077);
  const skinShadow = ui.Color(0xFFBD7657);

  canvas.save();
  canvas.clipRRect(ui.RRect.fromRectAndRadius(
    bounds,
    const ui.Radius.circular(8),
  ));

  _drawAccentHalo(
    canvas,
    center: pose.hipCenter,
    scale: scale,
    color: accentColor,
  );

  // Far-side limbs sit behind the torso so this reads as a person, rather
  // than as the coordinate skeleton that is drawn later for the selected cue.
  _drawLeg(
    canvas,
    pose: pose,
    hip: points[24],
    knee: points[26],
    ankle: points[28],
    heel: points[30],
    toe: points[32],
    scale: scale,
    skin: skinShadow.withValues(alpha: 0.78),
    outline: outline.withValues(alpha: 0.72),
    shorts: shorts.withValues(alpha: 0.78),
    shoeOpacity: 0.76,
  );
  _drawArm(
    canvas,
    shoulder: points[12],
    elbow: points[14],
    wrist: points[16],
    scale: scale,
    skin: skinShadow.withValues(alpha: 0.78),
    outline: outline.withValues(alpha: 0.72),
    sleeve: shirt.withValues(alpha: 0.78),
  );
  _drawLeg(
    canvas,
    pose: pose,
    hip: points[23],
    knee: points[25],
    ankle: points[27],
    heel: points[29],
    toe: points[31],
    scale: scale,
    skin: skin,
    outline: outline,
    shorts: shorts,
    shoeOpacity: 1,
  );

  _drawTorso(
    canvas,
    shoulder: pose.shoulderCenter,
    hip: pose.hipCenter,
    down: down,
    across: across,
    scale: scale,
    shirt: shirt,
    shorts: shorts,
    outline: outline,
  );
  _drawNeckAndHead(
    canvas,
    neck: pose.neck,
    shoulder: pose.shoulderCenter,
    head: pose.headCenter,
    down: down,
    forward: forward,
    scale: scale,
    skin: skin,
    outline: outline,
  );

  _drawArm(
    canvas,
    shoulder: points[11],
    elbow: points[13],
    wrist: points[15],
    scale: scale,
    skin: skin,
    outline: outline,
    sleeve: shirt,
  );
  canvas.restore();
}

/// Keeps the illustration card populated even when an unusually sparse frame
/// lacks enough torso joints to derive a measured avatar.
void paintRunningCoachAvatarFallback(
  ui.Canvas canvas, {
  required ui.Rect bounds,
  required ui.Color accentColor,
}) {
  final scale = math.min(bounds.width * 0.43, bounds.height * 0.29);
  final hip = ui.Offset(
    bounds.center.dx - scale * 0.04,
    bounds.center.dy + scale * 0.30,
  );
  final shoulder = hip - ui.Offset(scale * 0.04, scale * 0.96);
  final head = shoulder - ui.Offset(scale * 0.02, scale * 0.30);
  const outline = ui.Color(0xFF101B2D);
  const skin = ui.Color(0xFFE4A077);
  final limbWidth = (scale * 0.17).clamp(5.0, 14.0).toDouble();

  canvas.save();
  canvas.clipRRect(ui.RRect.fromRectAndRadius(
    bounds,
    const ui.Radius.circular(8),
  ));
  _drawAccentHalo(canvas, center: hip, scale: scale, color: accentColor);
  _drawSolidLimb(
    canvas,
    <ui.Offset>[
      hip + ui.Offset(-scale * 0.06, 0),
      hip + ui.Offset(-scale * 0.37, scale * 0.50),
      hip + ui.Offset(-scale * 0.62, scale * 1.06),
    ],
    width: limbWidth * 1.18,
    fill: skin.withValues(alpha: 0.72),
    outline: outline.withValues(alpha: 0.70),
  );
  _drawSolidLimb(
    canvas,
    <ui.Offset>[
      hip + ui.Offset(scale * 0.07, 0),
      hip + ui.Offset(scale * 0.43, scale * 0.42),
      hip + ui.Offset(scale * 0.70, scale * 0.98),
    ],
    width: limbWidth * 1.22,
    fill: skin,
    outline: outline,
  );
  _drawTorso(
    canvas,
    shoulder: shoulder,
    hip: hip,
    down: const ui.Offset(0, 1),
    across: const ui.Offset(-1, 0),
    scale: scale,
    shirt: accentColor.withValues(alpha: 0.88),
    shorts: const ui.Color(0xFF263B5B),
    outline: outline,
  );
  _drawNeckAndHead(
    canvas,
    neck: shoulder - ui.Offset(0, scale * 0.07),
    shoulder: shoulder,
    head: head,
    down: const ui.Offset(0, 1),
    forward: const ui.Offset(1, 0),
    scale: scale,
    skin: skin,
    outline: outline,
  );
  _drawSolidLimb(
    canvas,
    <ui.Offset>[
      shoulder + ui.Offset(scale * 0.04, scale * 0.02),
      shoulder + ui.Offset(scale * 0.39, scale * 0.25),
      shoulder + ui.Offset(scale * 0.60, scale * 0.05),
    ],
    width: limbWidth * 0.82,
    fill: skin,
    outline: outline,
  );
  canvas.restore();
}

void _drawAccentHalo(
  ui.Canvas canvas, {
  required ui.Offset center,
  required double scale,
  required ui.Color color,
}) {
  canvas.drawOval(
    ui.Rect.fromCenter(
      center: center,
      width: scale * 1.12,
      height: scale * 1.62,
    ),
    ui.Paint()..color = color.withValues(alpha: 0.075),
  );
}

void _drawTorso(
  ui.Canvas canvas, {
  required ui.Offset shoulder,
  required ui.Offset hip,
  required ui.Offset down,
  required ui.Offset across,
  required double scale,
  required ui.Color shirt,
  required ui.Color shorts,
  required ui.Color outline,
}) {
  final shoulderHalf = scale * 0.185;
  final hipHalf = scale * 0.205;
  final shirtHem = hip - down * (scale * 0.16);
  final body = ui.Path()
    ..moveTo((shoulder - across * shoulderHalf).dx,
        (shoulder - across * shoulderHalf).dy)
    ..lineTo((shoulder + across * shoulderHalf).dx,
        (shoulder + across * shoulderHalf).dy)
    ..lineTo((shirtHem + across * hipHalf).dx, (shirtHem + across * hipHalf).dy)
    ..lineTo((shirtHem - across * hipHalf).dx, (shirtHem - across * hipHalf).dy)
    ..close();
  canvas.drawPath(
    body,
    ui.Paint()
      ..color = shirt
      ..style = ui.PaintingStyle.fill,
  );
  canvas.drawPath(
    body,
    ui.Paint()
      ..color = outline
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = ui.StrokeJoin.round,
  );
  final highlight = ui.Path()
    ..moveTo((shoulder + across * shoulderHalf * 0.42).dx,
        (shoulder + across * shoulderHalf * 0.42).dy)
    ..lineTo((shirtHem + across * hipHalf * 0.35).dx,
        (shirtHem + across * hipHalf * 0.35).dy)
    ..lineTo((shirtHem + across * hipHalf * 0.07).dx,
        (shirtHem + across * hipHalf * 0.07).dy)
    ..lineTo((shoulder + across * shoulderHalf * 0.10).dx,
        (shoulder + across * shoulderHalf * 0.10).dy)
    ..close();
  canvas.drawPath(
    highlight,
    ui.Paint()..color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.14),
  );
  canvas.drawLine(
    shoulder - down * (scale * 0.17),
    shirtHem - down * (scale * 0.04),
    ui.Paint()
      ..color = const ui.Color(0xFF10213B).withValues(alpha: 0.22)
      ..strokeWidth = math.max(1.1, scale * 0.025)
      ..strokeCap = ui.StrokeCap.round,
  );

  final shortBottom = hip + down * (scale * 0.15);
  final shortShape = ui.Path()
    ..moveTo((shirtHem - across * hipHalf).dx, (shirtHem - across * hipHalf).dy)
    ..lineTo((shirtHem + across * hipHalf).dx, (shirtHem + across * hipHalf).dy)
    ..lineTo((shortBottom + across * hipHalf * 0.84).dx,
        (shortBottom + across * hipHalf * 0.84).dy)
    ..lineTo((shortBottom - across * hipHalf * 0.84).dx,
        (shortBottom - across * hipHalf * 0.84).dy)
    ..close();
  canvas.drawPath(
    shortShape,
    ui.Paint()..color = shorts,
  );
  canvas.drawPath(
    shortShape,
    ui.Paint()
      ..color = outline
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = ui.StrokeJoin.round,
  );
}

void _drawNeckAndHead(
  ui.Canvas canvas, {
  required ui.Offset neck,
  required ui.Offset shoulder,
  required ui.Offset head,
  required ui.Offset down,
  required ui.Offset forward,
  required double scale,
  required ui.Color skin,
  required ui.Color outline,
}) {
  final neckWidth = (scale * 0.115).clamp(4.0, 13.0).toDouble();
  _drawSolidLimb(
    canvas,
    <ui.Offset>[neck, shoulder],
    width: neckWidth,
    fill: skin,
    outline: outline,
  );
  final radius = (scale * 0.14).clamp(7.0, 22.0).toDouble();
  canvas.drawCircle(head, radius + 1.25, ui.Paint()..color = outline);
  canvas.drawCircle(head, radius, ui.Paint()..color = skin);
  final hairRect = ui.Rect.fromCenter(
    center: head - down * (radius * 0.33),
    width: radius * 1.75,
    height: radius * 1.18,
  );
  canvas.drawArc(
    hairRect,
    math.pi,
    math.pi,
    true,
    ui.Paint()..color = const ui.Color(0xFF1A2638),
  );
  final noseTip = head + forward * (radius * 1.02) + down * (radius * 0.08);
  final noseBase = head + forward * (radius * 0.67);
  final nose = ui.Path()
    ..moveTo(noseBase.dx, noseBase.dy - radius * 0.16)
    ..lineTo(noseTip.dx, noseTip.dy)
    ..lineTo(noseBase.dx, noseBase.dy + radius * 0.16)
    ..close();
  canvas.drawPath(nose, ui.Paint()..color = skin);
  canvas.drawPath(
    nose,
    ui.Paint()
      ..color = outline.withValues(alpha: 0.72)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.9,
  );
}

void _drawLeg(
  ui.Canvas canvas, {
  required RunningProfessionalRunnerPose pose,
  required ui.Offset? hip,
  required ui.Offset? knee,
  required ui.Offset? ankle,
  required ui.Offset? heel,
  required ui.Offset? toe,
  required double scale,
  required ui.Color skin,
  required ui.Color outline,
  required ui.Color shorts,
  required double shoeOpacity,
}) {
  if (hip == null || knee == null || ankle == null) return;
  final width = (scale * 0.175).clamp(6.0, 25.0).toDouble();
  final shortEnd = ui.Offset.lerp(hip, knee, 0.53)!;
  _drawSolidLimb(
    canvas,
    <ui.Offset>[hip, shortEnd],
    width: width * 1.08,
    fill: shorts,
    outline: outline,
  );
  _drawSolidLimb(
    canvas,
    <ui.Offset>[shortEnd, knee, ankle],
    width: width * 0.88,
    fill: skin,
    outline: outline,
  );
  _drawShoe(
    canvas,
    ankle: ankle,
    heel: heel,
    toe: toe,
    forward: pose.forward,
    scale: scale,
    opacity: shoeOpacity,
  );
}

void _drawArm(
  ui.Canvas canvas, {
  required ui.Offset? shoulder,
  required ui.Offset? elbow,
  required ui.Offset? wrist,
  required double scale,
  required ui.Color skin,
  required ui.Color outline,
  required ui.Color sleeve,
}) {
  if (shoulder == null || elbow == null || wrist == null) return;
  final width = (scale * 0.115).clamp(4.5, 16.0).toDouble();
  final sleeveEnd = ui.Offset.lerp(shoulder, elbow, 0.34)!;
  _drawSolidLimb(
    canvas,
    <ui.Offset>[shoulder, sleeveEnd],
    width: width * 1.08,
    fill: sleeve,
    outline: outline,
  );
  _drawSolidLimb(
    canvas,
    <ui.Offset>[sleeveEnd, elbow, wrist],
    width: width * 0.86,
    fill: skin,
    outline: outline,
  );
}

void _drawShoe(
  ui.Canvas canvas, {
  required ui.Offset ankle,
  required ui.Offset? heel,
  required ui.Offset? toe,
  required double forward,
  required double scale,
  required double opacity,
}) {
  final direction = _unit((toe ?? ankle) - (heel ?? ankle));
  final axis = direction == ui.Offset.zero
      ? ui.Offset(forward >= 0 ? 1 : -1, 0)
      : direction;
  final start = heel ?? ankle - axis * (scale * 0.05);
  final end = toe ?? ankle + axis * (scale * 0.13);
  final width = (scale * 0.105).clamp(4.0, 15.0).toDouble();
  final outline = ui.Paint()
    ..color = const ui.Color(0xFF101B2D).withValues(alpha: opacity)
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round
    ..strokeWidth = width + 2.2;
  final upper = ui.Paint()
    ..color = const ui.Color(0xFFF2F6FC).withValues(alpha: opacity)
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round
    ..strokeWidth = width;
  canvas.drawLine(start, end, outline);
  canvas.drawLine(start, end, upper);
  canvas.drawLine(
    start + ui.Offset(0, width * 0.32),
    end + ui.Offset(0, width * 0.32),
    ui.Paint()
      ..color = const ui.Color(0xFF52647B).withValues(alpha: opacity)
      ..strokeWidth = 1.1
      ..strokeCap = ui.StrokeCap.round,
  );
}

void _drawSolidLimb(
  ui.Canvas canvas,
  List<ui.Offset> points, {
  required double width,
  required ui.Color fill,
  required ui.Color outline,
}) {
  if (points.length < 2) return;
  final path = ui.Path()..moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  final outlinePaint = ui.Paint()
    ..color = outline
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = width + 2.1
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;
  final fillPaint = ui.Paint()
    ..color = fill
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;
  canvas.drawPath(path, outlinePaint);
  canvas.drawPath(path, fillPaint);
}

ui.Offset _unit(ui.Offset value) {
  final distance = value.distance;
  if (!distance.isFinite || distance < 0.0001) return ui.Offset.zero;
  return value / distance;
}

ui.Offset _perpendicular(ui.Offset value) => ui.Offset(-value.dy, value.dx);
