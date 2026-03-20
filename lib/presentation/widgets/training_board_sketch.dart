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
              return Stack(
                children: [
                  CustomPaint(
                    size: Size(width, height),
                    painter: _TrainingBoardSketchPainter(
                      page: page,
                      showStrokes: showStrokes,
                      showPlayerPath: showPlayerPath,
                      showBallPath: showBallPath,
                    ),
                  ),
                  ...page.items.take(maxVisibleItems).map((item) {
                    final icon = switch (item.type) {
                      'cone' => Icons.change_history,
                      'player' => Icons.person,
                      'ball' => Icons.sports_soccer,
                      'ladder' => Icons.view_week,
                      _ => Icons.circle,
                    };
                    final iconSize = switch (item.type) {
                      'ball' => (item.size * 0.86).clamp(22.0, 30.0),
                      'player' => (item.size * 0.7).clamp(20.0, 30.0),
                      _ => (item.size * 0.58).clamp(16.0, 24.0),
                    };
                    final offsetX = item.type == 'ball'
                        ? -iconSize * 0.45
                        : -iconSize * 0.5;
                    final offsetY = item.type == 'ball'
                        ? -iconSize * 0.55
                        : -iconSize * 0.5;
                    return Positioned(
                      left: (item.x * width + offsetX).clamp(
                        4.0,
                        width - iconSize - 4,
                      ),
                      top: (item.y * height + offsetY).clamp(
                        4.0,
                        height - iconSize - 4,
                      ),
                      child: Transform.rotate(
                        angle: item.rotationDeg * 3.1415926535897932 / 180,
                        child: Icon(
                          icon,
                          size: iconSize,
                          color: Color(item.colorValue).withValues(alpha: 0.96),
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

class _TrainingBoardSketchPainter extends CustomPainter {
  final TrainingMethodPage page;
  final bool showStrokes;
  final bool showPlayerPath;
  final bool showBallPath;

  const _TrainingBoardSketchPainter({
    required this.page,
    required this.showStrokes,
    required this.showPlayerPath,
    required this.showBallPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final playerPathPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
        const Radius.circular(14),
      ),
      line,
    );
    canvas.drawLine(Offset(centerX, 2), Offset(centerX, size.height - 2), line);
    canvas.drawCircle(Offset(centerX, centerY), 16, line);

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

    if (showPlayerPath && page.playerPath.length >= 2) {
      final playerPath = Path()
        ..moveTo(
          page.playerPath.first.x * size.width,
          page.playerPath.first.y * size.height,
        );
      for (final point in page.playerPath.skip(1)) {
        playerPath.lineTo(point.x * size.width, point.y * size.height);
      }
      canvas.drawPath(playerPath, playerPathPaint);
    }

    if (showBallPath && page.ballPath.length >= 2) {
      final ballPaint = Paint()
        ..color = const Color(0xFFFFF59D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final ballPath = Path()
        ..moveTo(
          page.ballPath.first.x * size.width,
          page.ballPath.first.y * size.height,
        );
      for (final point in page.ballPath.skip(1)) {
        ballPath.lineTo(point.x * size.width, point.y * size.height);
      }
      canvas.drawPath(ballPath, ballPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrainingBoardSketchPainter oldDelegate) {
    return oldDelegate.page != page ||
        oldDelegate.showStrokes != showStrokes ||
        oldDelegate.showPlayerPath != showPlayerPath ||
        oldDelegate.showBallPath != showBallPath;
  }
}
