import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/training_method_layout.dart';

class TrainingBoardSketch extends StatelessWidget {
  final TrainingMethodPage page;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool showItemCountBadge;
  final int maxVisibleItems;
  final bool showStrokes;
  final bool showPlayerPath;
  final bool showBallPath;
  final bool showTacticalOverlay;

  const TrainingBoardSketch({
    super.key,
    required this.page,
    this.borderRadius = 18,
    this.padding = EdgeInsets.zero,
    this.showItemCountBadge = false,
    this.maxVisibleItems = 18,
    this.showStrokes = true,
    this.showPlayerPath = true,
    this.showBallPath = true,
    this.showTacticalOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = page.items.length;
    return Padding(
      padding: padding,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              final visibleItems =
                  page.items.take(maxVisibleItems).toList(growable: false);
              return Stack(
                children: [
                  CustomPaint(
                    size: Size(width, height),
                    painter: _TrainingBoardSketchPainter(
                      page: page,
                      showStrokes: showStrokes,
                      showPlayerPath: showPlayerPath,
                      showBallPath: showBallPath,
                      showTacticalOverlay: showTacticalOverlay,
                    ),
                  ),
                  ...visibleItems.map((item) {
                    final tokenSize = switch (item.type) {
                      'ball' => (item.size * 0.9).clamp(24.0, 34.0),
                      'player' => (item.size * 0.82).clamp(24.0, 36.0),
                      _ => (item.size * 0.72).clamp(20.0, 30.0),
                    };
                    return Positioned(
                      left: (item.x * width - tokenSize / 2).clamp(
                        4.0,
                        width - tokenSize - 4,
                      ),
                      top: (item.y * height - tokenSize / 2).clamp(
                        4.0,
                        height - tokenSize - 4,
                      ),
                      child: Transform.rotate(
                        angle: item.rotationDeg * math.pi / 180,
                        child: _TrainingBoardSketchToken(
                          item: item,
                          size: tokenSize,
                          label: _sketchTokenLabelFor(visibleItems, item),
                        ),
                      ),
                    );
                  }),
                  if (showItemCountBadge)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$itemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

String? _sketchTokenLabelFor(
  List<TrainingMethodItem> items,
  TrainingMethodItem item,
) {
  if (item.type != 'player') return null;
  final index = items
      .where((entry) => entry.type == 'player')
      .toList(growable: false)
      .indexWhere((entry) => identical(entry, item));
  return index < 0 ? null : '${index + 1}';
}

class _TrainingBoardSketchToken extends StatelessWidget {
  final TrainingMethodItem item;
  final double size;
  final String? label;

  const _TrainingBoardSketchToken({
    required this.item,
    required this.size,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.type) {
      'cone' => Icons.change_history,
      'hurdle' => Icons.horizontal_rule,
      'player' => Icons.person,
      'ball' => Icons.sports_soccer,
      'ladder' => Icons.view_week,
      _ => Icons.circle,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.72),
          width: (size * 0.055).clamp(1.0, 2.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: size * 0.16,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            size: switch (item.type) {
              'ball' => size * 0.58,
              'player' => size * 0.56,
              _ => size * 0.50,
            },
            color: Color(item.colorValue).withValues(alpha: 0.98),
          ),
          if (label != null)
            Positioned(
              right: -size * 0.09,
              bottom: -size * 0.09,
              child: _SketchTokenNumberBadge(label: label!, size: size),
            ),
        ],
      ),
    );
  }
}

class _SketchTokenNumberBadge extends StatelessWidget {
  final String label;
  final double size;

  const _SketchTokenNumberBadge({required this.label, required this.size});

  @override
  Widget build(BuildContext context) {
    final badgeSize = (size * 0.46).clamp(13.0, 17.0);
    return Container(
      width: badgeSize,
      height: badgeSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.42)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.black87,
          fontSize: (badgeSize * 0.52).clamp(7.0, 9.0),
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _TrainingBoardSketchPainter extends CustomPainter {
  final TrainingMethodPage page;
  final bool showStrokes;
  final bool showPlayerPath;
  final bool showBallPath;
  final bool showTacticalOverlay;

  const _TrainingBoardSketchPainter({
    required this.page,
    required this.showStrokes,
    required this.showPlayerPath,
    required this.showBallPath,
    required this.showTacticalOverlay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawPitch(canvas, size);

    if (showStrokes) {
      for (final stroke in page.strokes) {
        if (stroke.points.length < 2) continue;
        final strokePaint = Paint()
          ..color = Color(stroke.colorValue).withValues(alpha: 0.92)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke.width.clamp(1.0, 4.0)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        final path = Path()
          ..moveTo(
            stroke.points.first.x * size.width,
            stroke.points.first.y * size.height,
          );
        for (final point in stroke.points.skip(1)) {
          path.lineTo(point.x * size.width, point.y * size.height);
        }
        canvas.drawPath(path, strokePaint);
      }
    }

    for (final route in page.routes) {
      if (route.points.length < 2) continue;
      final shouldDraw = switch (route.kind) {
        TrainingMethodRouteKind.player => showPlayerPath,
        TrainingMethodRouteKind.ball => showBallPath,
      };
      if (!shouldDraw) continue;
      _drawRoute(canvas, size, route);
    }
  }

  void _drawPitch(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, math.min(size.width, size.height) * 0.006);

    final margin = math.max(3.0, math.min(size.width, size.height) * 0.025);
    final fieldRect = Rect.fromLTWH(
      margin,
      margin,
      size.width - margin * 2,
      size.height - margin * 2,
    );
    final radius = Radius.circular(math.min(14, fieldRect.shortestSide * 0.08));
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;
    final stripeWidth = fieldRect.width / 8;
    for (var i = 0; i < 8; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(
          fieldRect.left + stripeWidth * i,
          fieldRect.top,
          stripeWidth,
          fieldRect.height,
        ),
        stripePaint,
      );
    }
    if (showTacticalOverlay) {
      _drawTacticalOverlay(canvas, fieldRect);
    }

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    canvas.drawRRect(RRect.fromRectAndRadius(fieldRect, radius), line);
    canvas.drawLine(
      Offset(centerX, fieldRect.top),
      Offset(centerX, fieldRect.bottom),
      line,
    );
    canvas.drawCircle(
      Offset(centerX, centerY),
      math.min(24, fieldRect.shortestSide * 0.13),
      line,
    );

    final boxDepth = math.min(fieldRect.width * 0.17, 58.0);
    final boxHeight = math.min(fieldRect.height * 0.48, 96.0);
    final boxTop = centerY - boxHeight / 2;
    canvas.drawRect(
      Rect.fromLTWH(fieldRect.left, boxTop, boxDepth, boxHeight),
      line,
    );
    canvas.drawRect(
      Rect.fromLTWH(fieldRect.right - boxDepth, boxTop, boxDepth, boxHeight),
      line,
    );
    final goalDepth = math.min(fieldRect.width * 0.025, 9.0);
    final goalHeight = math.min(fieldRect.height * 0.22, 42.0);
    canvas.drawRect(
      Rect.fromLTWH(
        fieldRect.left - goalDepth,
        centerY - goalHeight / 2,
        goalDepth,
        goalHeight,
      ),
      line,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        fieldRect.right,
        centerY - goalHeight / 2,
        goalDepth,
        goalHeight,
      ),
      line,
    );

    final spotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 2, spotPaint);
  }

  void _drawTacticalOverlay(Canvas canvas, Rect fieldRect) {
    final halfSpacePaint = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    final centralPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.028)
      ..style = PaintingStyle.fill;
    final laneYs = _sketchLaneFractions
        .map((fraction) => fieldRect.top + fieldRect.height * fraction)
        .toList(growable: false);
    canvas.drawRect(
      Rect.fromLTRB(fieldRect.left, laneYs[0], fieldRect.right, laneYs[1]),
      halfSpacePaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(fieldRect.left, laneYs[2], fieldRect.right, laneYs[3]),
      halfSpacePaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(fieldRect.left, laneYs[1], fieldRect.right, laneYs[2]),
      centralPaint,
    );

    final thirdPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, fieldRect.shortestSide * 0.004);
    for (final fraction in const [1 / 3, 2 / 3]) {
      final x = fieldRect.left + fieldRect.width * fraction;
      _drawDashedLine(
        canvas,
        Offset(x, fieldRect.top),
        Offset(x, fieldRect.bottom),
        thirdPaint,
        dash: 8,
        gap: 6,
      );
    }

    final lanePaint = Paint()
      ..color = const Color(0xFFE0F7FA).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, fieldRect.shortestSide * 0.003);
    for (final y in laneYs) {
      _drawDashedLine(
        canvas,
        Offset(fieldRect.left, y),
        Offset(fieldRect.right, y),
        lanePaint,
        dash: 7,
        gap: 5,
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    final vector = end - start;
    final distance = vector.distance;
    if (distance <= 0) return;
    final direction = vector / distance;
    var drawn = 0.0;
    while (drawn < distance) {
      final segmentStart = start + direction * drawn;
      final segmentEnd = start + direction * math.min(drawn + dash, distance);
      canvas.drawLine(segmentStart, segmentEnd, paint);
      drawn += dash + gap;
    }
  }

  void _drawRoute(Canvas canvas, Size size, TrainingMethodRoute route) {
    final points = route.points
        .map((point) => Offset(point.x * size.width, point.y * size.height))
        .toList(growable: false);
    final color = Color(route.colorValue).withValues(
      alpha: route.kind == TrainingMethodRouteKind.player ? 0.82 : 0.94,
    );
    final width = route.width.clamp(1.6, 3.6);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (route.kind == TrainingMethodRouteKind.ball) {
      _drawDashedPolyline(canvas, points, paint);
    } else {
      canvas.drawPath(_smoothPath(points), paint);
    }
    _drawArrowHead(canvas, points, color, width);
    _drawRouteStart(canvas, points.first, color, width);
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 2) {
      return path..lineTo(points.last.dx, points.last.dy);
    }
    for (var i = 1; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final mid = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }
    return path..lineTo(points.last.dx, points.last.dy);
  }

  void _drawDashedPolyline(Canvas canvas, List<Offset> points, Paint paint) {
    const dash = 10.0;
    const gap = 7.0;
    for (var i = 1; i < points.length; i++) {
      final start = points[i - 1];
      final end = points[i];
      final vector = end - start;
      final distance = vector.distance;
      if (distance < 0.1) continue;
      final direction = vector / distance;
      var drawn = 0.0;
      while (drawn < distance) {
        final segmentStart = start + direction * drawn;
        final segmentEnd = start + direction * math.min(drawn + dash, distance);
        canvas.drawLine(segmentStart, segmentEnd, paint);
        drawn += dash + gap;
      }
    }
  }

  void _drawRouteStart(
    Canvas canvas,
    Offset center,
    Color color,
    double width,
  ) {
    final outerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    final innerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, math.max(3.5, width * 1.35), outerPaint);
    canvas.drawCircle(center, math.max(2.0, width * 0.72), innerPaint);
  }

  void _drawArrowHead(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double width,
  ) {
    if (points.length < 2) return;
    final tip = points.last;
    Offset? tail;
    for (var i = points.length - 2; i >= 0; i--) {
      if ((tip - points[i]).distance > 0.5) {
        tail = points[i];
        break;
      }
    }
    if (tail == null) return;
    final angle = math.atan2(tip.dy - tail.dy, tip.dx - tail.dx);
    final length = math.max(8.0, width * 3.1);
    const spread = math.pi / 6;
    final left = Offset(
      tip.dx - math.cos(angle - spread) * length,
      tip.dy - math.sin(angle - spread) * length,
    );
    final right = Offset(
      tip.dx - math.cos(angle + spread) * length,
      tip.dy - math.sin(angle + spread) * length,
    );
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close(),
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TrainingBoardSketchPainter oldDelegate) {
    return oldDelegate.page != page ||
        oldDelegate.showStrokes != showStrokes ||
        oldDelegate.showPlayerPath != showPlayerPath ||
        oldDelegate.showBallPath != showBallPath ||
        oldDelegate.showTacticalOverlay != showTacticalOverlay;
  }
}

const List<double> _sketchLaneFractions = <double>[0.18, 0.38, 0.62, 0.82];
