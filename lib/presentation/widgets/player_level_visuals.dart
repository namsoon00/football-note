import 'dart:math';

import 'package:flutter/material.dart';

class PlayerLevelVisualSpec {
  final List<Color> colors;
  final PlayerLevelIllustrationStage stage;

  const PlayerLevelVisualSpec({required this.colors, required this.stage});

  factory PlayerLevelVisualSpec.fromLevel(int level) {
    switch (level.clamp(1, 10)) {
      case 1:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFF0F9B8E), Color(0xFF38EF7D)],
          stage: PlayerLevelIllustrationStage.whistle,
        );
      case 2:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFF2E86DE), Color(0xFF74B9FF)],
          stage: PlayerLevelIllustrationStage.ball,
        );
      case 3:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFFF7971E), Color(0xFFFFD200)],
          stage: PlayerLevelIllustrationStage.cone,
        );
      case 4:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFFE17055), Color(0xFFFFB88C)],
          stage: PlayerLevelIllustrationStage.boot,
        );
      case 5:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFF7F00FF), Color(0xFFE100FF)],
          stage: PlayerLevelIllustrationStage.jumpRope,
        );
      case 6:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFF355C7D), Color(0xFF6C5B7B)],
          stage: PlayerLevelIllustrationStage.dumbbell,
        );
      case 7:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFFB24592), Color(0xFFF15F79)],
          stage: PlayerLevelIllustrationStage.tactics,
        );
      case 8:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFF6A11CB), Color(0xFF2575FC)],
          stage: PlayerLevelIllustrationStage.crown,
        );
      case 9:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFF134E5E), Color(0xFF71B280)],
          stage: PlayerLevelIllustrationStage.trophy,
        );
      default:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFF141E30), Color(0xFF243B55)],
          stage: PlayerLevelIllustrationStage.fireworks,
        );
    }
  }
}

class PlayerLevelIllustration extends StatelessWidget {
  final int level;
  final double size;

  const PlayerLevelIllustration({
    super.key,
    required this.level,
    this.size = 108,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: PlayerLevelIllustrationPainter(
        spec: PlayerLevelVisualSpec.fromLevel(level),
      ),
    );
  }
}

enum PlayerLevelIllustrationStage {
  whistle,
  ball,
  cone,
  boot,
  jumpRope,
  dumbbell,
  tactics,
  crown,
  trophy,
  fireworks,
}

class PlayerLevelIllustrationPainter extends CustomPainter {
  final PlayerLevelVisualSpec spec;

  const PlayerLevelIllustrationPainter({required this.spec});

  @override
  void paint(Canvas canvas, Size size) {
    final whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final whiteStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.94)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final softStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    switch (spec.stage) {
      case PlayerLevelIllustrationStage.whistle:
        _paintWhistle(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case PlayerLevelIllustrationStage.ball:
        _paintBall(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case PlayerLevelIllustrationStage.cone:
        _paintCone(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case PlayerLevelIllustrationStage.boot:
        _paintBoot(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case PlayerLevelIllustrationStage.jumpRope:
        _paintJumpRope(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case PlayerLevelIllustrationStage.dumbbell:
        _paintDumbbell(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case PlayerLevelIllustrationStage.tactics:
        _paintTactics(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case PlayerLevelIllustrationStage.crown:
        _paintCrown(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case PlayerLevelIllustrationStage.trophy:
        _paintTrophy(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case PlayerLevelIllustrationStage.fireworks:
        _paintFireworks(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
    }
  }

  void _paintWhistle(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.34,
        size.width * 0.4,
        size.height * 0.24,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      body,
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );
    canvas.drawRRect(body, stroke);
    canvas.drawCircle(
      Offset(size.width * 0.44, size.height * 0.46),
      size.width * 0.07,
      softStroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.62, size.height * 0.38),
      Offset(size.width * 0.78, size.height * 0.26),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, size.height * 0.22),
      Offset(size.width * 0.82, size.height * 0.16),
      softStroke,
    );
    canvas.drawCircle(Offset(size.width * 0.76, size.height * 0.26), 4, fill);
  }

  void _paintBall(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final center = Offset(size.width * 0.5, size.height * 0.44);
    canvas.drawCircle(
      center,
      size.width * 0.24,
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );
    canvas.drawCircle(center, size.width * 0.21, stroke);
    final pentagon = Path()
      ..moveTo(center.dx, center.dy - 12)
      ..lineTo(center.dx + 10, center.dy - 2)
      ..lineTo(center.dx + 6, center.dy + 10)
      ..lineTo(center.dx - 6, center.dy + 10)
      ..lineTo(center.dx - 10, center.dy - 2)
      ..close();
    canvas.drawPath(pentagon, fill);
    canvas.drawLine(
      Offset(center.dx, center.dy - 12),
      Offset(center.dx, center.dy - 26),
      softStroke,
    );
    canvas.drawLine(
      Offset(center.dx - 10, center.dy - 2),
      Offset(center.dx - 22, center.dy - 10),
      softStroke,
    );
    canvas.drawLine(
      Offset(center.dx + 10, center.dy - 2),
      Offset(center.dx + 22, center.dy - 10),
      softStroke,
    );
    canvas.drawLine(
      Offset(center.dx - 6, center.dy + 10),
      Offset(center.dx - 18, center.dy + 22),
      softStroke,
    );
    canvas.drawLine(
      Offset(center.dx + 6, center.dy + 10),
      Offset(center.dx + 18, center.dy + 22),
      softStroke,
    );
  }

  void _paintCone(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final cone = Path()
      ..moveTo(size.width * 0.34, size.height * 0.74)
      ..lineTo(size.width * 0.5, size.height * 0.24)
      ..lineTo(size.width * 0.66, size.height * 0.74)
      ..close();
    canvas.drawPath(cone, Paint()..color = Colors.white.withValues(alpha: 0.2));
    canvas.drawPath(cone, stroke);
    canvas.drawLine(
      Offset(size.width * 0.39, size.height * 0.58),
      Offset(size.width * 0.61, size.height * 0.58),
      softStroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.36, size.height * 0.68),
      Offset(size.width * 0.64, size.height * 0.68),
      softStroke,
    );
    canvas.drawCircle(Offset(size.width * 0.76, size.height * 0.26), 6, fill);
  }

  void _paintBoot(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final boot = Path()
      ..moveTo(size.width * 0.26, size.height * 0.54)
      ..lineTo(size.width * 0.5, size.height * 0.54)
      ..lineTo(size.width * 0.62, size.height * 0.34)
      ..lineTo(size.width * 0.74, size.height * 0.38)
      ..lineTo(size.width * 0.68, size.height * 0.58)
      ..lineTo(size.width * 0.78, size.height * 0.66)
      ..lineTo(size.width * 0.76, size.height * 0.76)
      ..lineTo(size.width * 0.24, size.height * 0.76)
      ..close();
    canvas.drawPath(
      boot,
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );
    canvas.drawPath(boot, stroke);
    canvas.drawLine(
      Offset(size.width * 0.42, size.height * 0.5),
      Offset(size.width * 0.56, size.height * 0.38),
      softStroke,
    );
    for (final dx in <double>[0.38, 0.44, 0.5]) {
      canvas.drawCircle(Offset(size.width * dx, size.height * 0.58), 2.2, fill);
    }
  }

  void _paintJumpRope(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final leftHandle = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.48,
        size.width * 0.08,
        size.height * 0.18,
      ),
      const Radius.circular(8),
    );
    final rightHandle = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.72,
        size.height * 0.48,
        size.width * 0.08,
        size.height * 0.18,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(leftHandle, fill);
    canvas.drawRRect(rightHandle, fill);
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.2,
        size.width * 0.64,
        size.height * 0.58,
      ),
      3.3,
      2.8,
      false,
      stroke,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.74),
      size.width * 0.06,
      softStroke,
    );
  }

  void _paintDumbbell(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.5),
      Offset(size.width * 0.72, size.height * 0.5),
      stroke,
    );
    for (final dx in <double>[0.28, 0.36, 0.64, 0.72]) {
      final rect = Rect.fromCenter(
        center: Offset(size.width * dx, size.height * 0.5),
        width: size.width * 0.07,
        height: size.height * 0.28,
      );
      canvas.drawRect(rect, dx == 0.36 || dx == 0.64 ? softStroke : fill);
    }
  }

  void _paintTactics(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.2,
        size.width * 0.68,
        size.height * 0.48,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    canvas.drawRRect(rect, stroke);
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.68),
      softStroke,
    );
    final arrow = Path()
      ..moveTo(size.width * 0.28, size.height * 0.4)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.24,
        size.width * 0.66,
        size.height * 0.34,
      )
      ..lineTo(size.width * 0.6, size.height * 0.28)
      ..moveTo(size.width * 0.66, size.height * 0.34)
      ..lineTo(size.width * 0.56, size.height * 0.34);
    canvas.drawPath(arrow, stroke);
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.4), 4, fill);
    canvas.drawCircle(Offset(size.width * 0.66, size.height * 0.34), 4, fill);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.58), 4, fill);
  }

  void _paintCrown(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final crown = Path()
      ..moveTo(size.width * 0.2, size.height * 0.68)
      ..lineTo(size.width * 0.3, size.height * 0.34)
      ..lineTo(size.width * 0.46, size.height * 0.56)
      ..lineTo(size.width * 0.54, size.height * 0.28)
      ..lineTo(size.width * 0.7, size.height * 0.56)
      ..lineTo(size.width * 0.8, size.height * 0.34)
      ..lineTo(size.width * 0.86, size.height * 0.68)
      ..close();
    canvas.drawPath(
      crown,
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );
    canvas.drawPath(crown, stroke);
    canvas.drawLine(
      Offset(size.width * 0.24, size.height * 0.74),
      Offset(size.width * 0.82, size.height * 0.74),
      stroke,
    );
    for (final offset in <Offset>[
      Offset(size.width * 0.3, size.height * 0.3),
      Offset(size.width * 0.54, size.height * 0.24),
      Offset(size.width * 0.8, size.height * 0.3),
    ]) {
      canvas.drawCircle(offset, 5, fill);
    }
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.62),
      Offset(size.width * 0.66, size.height * 0.62),
      softStroke,
    );
  }

  void _paintTrophy(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final cup = Path()
      ..moveTo(size.width * 0.34, size.height * 0.22)
      ..lineTo(size.width * 0.66, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.46,
        size.width * 0.56,
        size.height * 0.54,
      )
      ..lineTo(size.width * 0.56, size.height * 0.66)
      ..lineTo(size.width * 0.64, size.height * 0.72)
      ..lineTo(size.width * 0.36, size.height * 0.72)
      ..lineTo(size.width * 0.44, size.height * 0.66)
      ..lineTo(size.width * 0.44, size.height * 0.54)
      ..quadraticBezierTo(
        size.width * 0.38,
        size.height * 0.46,
        size.width * 0.34,
        size.height * 0.22,
      )
      ..close();
    canvas.drawPath(cup, Paint()..color = Colors.white.withValues(alpha: 0.16));
    canvas.drawPath(cup, stroke);
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.28,
        size.width * 0.18,
        size.height * 0.18,
      ),
      1.3,
      2.6,
      false,
      softStroke,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.62,
        size.height * 0.28,
        size.width * 0.18,
        size.height * 0.18,
      ),
      -0.3,
      2.6,
      false,
      softStroke,
    );
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.44), 6, fill);
  }

  void _paintFireworks(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final center = Offset(size.width * 0.5, size.height * 0.46);
    for (final angle in <double>[0, 0.6, 1.2, 1.8, 2.4, 3.0, 3.6, 4.2, 4.8]) {
      final end = Offset(
        center.dx + (size.width * 0.24) * cos(angle),
        center.dy + (size.height * 0.24) * sin(angle),
      );
      canvas.drawLine(center, end, stroke);
    }
    canvas.drawCircle(center, 8, fill);
    canvas.drawCircle(
      Offset(size.width * 0.24, size.height * 0.28),
      5,
      softStroke,
    );
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.34),
      5,
      softStroke,
    );
    canvas.drawCircle(
      Offset(size.width * 0.34, size.height * 0.74),
      5,
      softStroke,
    );
  }

  @override
  bool shouldRepaint(covariant PlayerLevelIllustrationPainter oldDelegate) {
    return oldDelegate.spec.stage != spec.stage ||
        oldDelegate.spec.colors != spec.colors;
  }
}
