import 'dart:math';

import 'package:flutter/material.dart';

class PlayerLevelVisualSpec {
  final List<Color> colors;
  final PlayerLevelIllustrationStage stage;

  const PlayerLevelVisualSpec({required this.colors, required this.stage});

  factory PlayerLevelVisualSpec.fromLevel(int level) {
    switch (level.clamp(1, 20)) {
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
      case 10:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFF3A1C71), Color(0xFFFFAF7B)],
          stage: PlayerLevelIllustrationStage.fireworks,
        );
      case 11:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFF00416A), Color(0xFFE4E5E6)],
          stage: PlayerLevelIllustrationStage.shield,
        );
      case 12:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFF1E3C72), Color(0xFF2A5298)],
          stage: PlayerLevelIllustrationStage.gloves,
        );
      case 13:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFF0F2027), Color(0xFF2C5364)],
          stage: PlayerLevelIllustrationStage.radar,
        );
      case 14:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFFF12711), Color(0xFFF5AF19)],
          stage: PlayerLevelIllustrationStage.lightning,
        );
      case 15:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFF614385), Color(0xFF516395)],
          stage: PlayerLevelIllustrationStage.medal,
        );
      case 16:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFF0B486B), Color(0xFFF56217)],
          stage: PlayerLevelIllustrationStage.stadium,
        );
      case 17:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFF232526), Color(0xFF414345)],
          stage: PlayerLevelIllustrationStage.rocket,
        );
      case 18:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFFFF512F), Color(0xFFDD2476)],
          stage: PlayerLevelIllustrationStage.star,
        );
      case 19:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFF1D4350), Color(0xFFA43931)],
          stage: PlayerLevelIllustrationStage.gift,
        );
      default:
        return const PlayerLevelVisualSpec(
          colors: <Color>[Color(0xFF141E30), Color(0xFF243B55)],
          stage: PlayerLevelIllustrationStage.galaxy,
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
  shield,
  gloves,
  radar,
  lightning,
  medal,
  stadium,
  rocket,
  star,
  gift,
  galaxy,
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
      ..color = Colors.white.withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final glow = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    _paintBackdrop(canvas, size, glow, softStroke);

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
      case PlayerLevelIllustrationStage.shield:
        _paintShield(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case PlayerLevelIllustrationStage.gloves:
        _paintGloves(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case PlayerLevelIllustrationStage.radar:
        _paintRadar(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case PlayerLevelIllustrationStage.lightning:
        _paintLightning(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case PlayerLevelIllustrationStage.medal:
        _paintMedal(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case PlayerLevelIllustrationStage.stadium:
        _paintStadium(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case PlayerLevelIllustrationStage.rocket:
        _paintRocket(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case PlayerLevelIllustrationStage.star:
        _paintStar(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case PlayerLevelIllustrationStage.gift:
        _paintGift(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case PlayerLevelIllustrationStage.galaxy:
        _paintGalaxy(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
    }
  }

  void _paintBackdrop(Canvas canvas, Size size, Paint glow, Paint softStroke) {
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.35,
      glow,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.5),
        radius: size.width * 0.32,
      ),
      -pi * 0.75,
      pi * 1.4,
      false,
      softStroke,
    );
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
    final center = Offset(size.width * 0.5, size.height * 0.46);
    canvas.drawCircle(center, size.width * 0.23, stroke);
    final pentagon = Path()
      ..moveTo(center.dx, center.dy - 12)
      ..lineTo(center.dx + 10, center.dy - 2)
      ..lineTo(center.dx + 6, center.dy + 10)
      ..lineTo(center.dx - 6, center.dy + 10)
      ..lineTo(center.dx - 10, center.dy - 2)
      ..close();
    canvas.drawPath(pentagon, fill);
    for (final offset in <Offset>[
      const Offset(0, -24),
      const Offset(-21, -10),
      const Offset(21, -10),
      const Offset(-16, 19),
      const Offset(16, 19),
    ]) {
      canvas.drawLine(
        center + Offset(offset.dx * 0.45, offset.dy * 0.45),
        center + offset,
        softStroke,
      );
    }
  }

  void _paintCone(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.22)
      ..lineTo(size.width * 0.7, size.height * 0.72)
      ..lineTo(size.width * 0.3, size.height * 0.72)
      ..close();
    canvas.drawPath(path, stroke);
    canvas.drawLine(
      Offset(size.width * 0.36, size.height * 0.52),
      Offset(size.width * 0.64, size.height * 0.52),
      softStroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.38),
      Offset(size.width * 0.6, size.height * 0.38),
      softStroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.25,
          size.height * 0.72,
          size.width * 0.5,
          size.height * 0.08,
        ),
        const Radius.circular(12),
      ),
      fill,
    );
  }

  void _paintBoot(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final path = Path()
      ..moveTo(size.width * 0.24, size.height * 0.54)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.34,
        size.width * 0.58,
        size.height * 0.42,
      )
      ..lineTo(size.width * 0.72, size.height * 0.46)
      ..lineTo(size.width * 0.78, size.height * 0.62)
      ..lineTo(size.width * 0.28, size.height * 0.62)
      ..close();
    canvas.drawPath(path, stroke);
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.46),
      Offset(size.width * 0.52, size.height * 0.46),
      softStroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.38, size.height * 0.51),
      Offset(size.width * 0.5, size.height * 0.51),
      softStroke,
    );
    for (double dx = 0.36; dx <= 0.68; dx += 0.08) {
      canvas.drawCircle(Offset(size.width * dx, size.height * 0.67), 2.5, fill);
    }
  }

  void _paintJumpRope(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    canvas.drawCircle(Offset(size.width * 0.34, size.height * 0.36), 8, fill);
    canvas.drawCircle(Offset(size.width * 0.66, size.height * 0.36), 8, fill);
    final rope = Path()
      ..moveTo(size.width * 0.34, size.height * 0.36)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.82,
        size.width * 0.66,
        size.height * 0.36,
      );
    canvas.drawPath(rope, stroke);
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.36,
        size.height * 0.26,
        size.width * 0.28,
        size.height * 0.22,
      ),
      0,
      pi,
      false,
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
      Offset(size.width * 0.32, size.height * 0.5),
      Offset(size.width * 0.68, size.height * 0.5),
      stroke,
    );
    for (final dx in <double>[0.26, 0.32, 0.68, 0.74]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * dx, size.height * 0.5),
            width: 8,
            height: size.height * 0.24,
          ),
          const Radius.circular(4),
        ),
        dx == 0.32 || dx == 0.68 ? fill : stroke,
      );
    }
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.34,
        size.height * 0.26,
        size.width * 0.32,
        size.height * 0.34,
      ),
      pi * 0.9,
      pi * 0.7,
      false,
      softStroke,
    );
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
        size.width * 0.24,
        size.height * 0.24,
        size.width * 0.52,
        size.height * 0.52,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(rect, stroke);
    for (final point in <Offset>[
      Offset(size.width * 0.34, size.height * 0.36),
      Offset(size.width * 0.46, size.height * 0.52),
      Offset(size.width * 0.62, size.height * 0.36),
    ]) {
      canvas.drawCircle(point, 5, fill);
    }
    final arrow = Path()
      ..moveTo(size.width * 0.34, size.height * 0.36)
      ..quadraticBezierTo(
        size.width * 0.44,
        size.height * 0.3,
        size.width * 0.58,
        size.height * 0.36,
      )
      ..lineTo(size.width * 0.54, size.height * 0.32)
      ..moveTo(size.width * 0.58, size.height * 0.36)
      ..lineTo(size.width * 0.52, size.height * 0.39);
    canvas.drawPath(arrow, softStroke);
  }

  void _paintCrown(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final path = Path()
      ..moveTo(size.width * 0.24, size.height * 0.64)
      ..lineTo(size.width * 0.32, size.height * 0.34)
      ..lineTo(size.width * 0.46, size.height * 0.52)
      ..lineTo(size.width * 0.54, size.height * 0.28)
      ..lineTo(size.width * 0.66, size.height * 0.52)
      ..lineTo(size.width * 0.76, size.height * 0.34)
      ..lineTo(size.width * 0.82, size.height * 0.64)
      ..close();
    canvas.drawPath(path, stroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.26,
          size.height * 0.62,
          size.width * 0.5,
          size.height * 0.1,
        ),
        const Radius.circular(10),
      ),
      fill,
    );
    for (final dx in <double>[0.32, 0.54, 0.76]) {
      canvas.drawCircle(Offset(size.width * dx, size.height * 0.32), 4, fill);
    }
    canvas.drawLine(
      Offset(size.width * 0.32, size.height * 0.48),
      Offset(size.width * 0.76, size.height * 0.48),
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
      ..moveTo(size.width * 0.34, size.height * 0.28)
      ..lineTo(size.width * 0.66, size.height * 0.28)
      ..quadraticBezierTo(
        size.width * 0.64,
        size.height * 0.5,
        size.width * 0.5,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.36,
        size.height * 0.5,
        size.width * 0.34,
        size.height * 0.28,
      );
    canvas.drawPath(cup, stroke);
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.56),
      Offset(size.width * 0.5, size.height * 0.68),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.38,
          size.height * 0.68,
          size.width * 0.24,
          size.height * 0.08,
        ),
        const Radius.circular(8),
      ),
      fill,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.3,
        size.width * 0.16,
        size.height * 0.18,
      ),
      pi * 0.5,
      pi,
      false,
      softStroke,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.6,
        size.height * 0.3,
        size.width * 0.16,
        size.height * 0.18,
      ),
      -pi * 0.5,
      pi,
      false,
      softStroke,
    );
  }

  void _paintFireworks(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    for (final burst in <Offset>[
      Offset(size.width * 0.38, size.height * 0.38),
      Offset(size.width * 0.64, size.height * 0.54),
      Offset(size.width * 0.56, size.height * 0.3),
    ]) {
      for (int i = 0; i < 8; i++) {
        final angle = (pi * 2 / 8) * i;
        final inner = Offset(cos(angle) * 6, sin(angle) * 6);
        final outer = Offset(cos(angle) * 16, sin(angle) * 16);
        canvas.drawLine(
          burst + inner,
          burst + outer,
          i.isEven ? stroke : softStroke,
        );
      }
      canvas.drawCircle(burst, 4, fill);
    }
  }

  void _paintShield(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.18)
      ..lineTo(size.width * 0.72, size.height * 0.28)
      ..lineTo(size.width * 0.68, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.58,
        size.height * 0.74,
        size.width * 0.5,
        size.height * 0.8,
      )
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.74,
        size.width * 0.32,
        size.height * 0.6,
      )
      ..lineTo(size.width * 0.28, size.height * 0.28)
      ..close();
    canvas.drawPath(path, stroke);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.28)
        ..lineTo(size.width * 0.5, size.height * 0.66)
        ..moveTo(size.width * 0.38, size.height * 0.46)
        ..lineTo(size.width * 0.62, size.height * 0.46),
      softStroke,
    );
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.28), 4, fill);
  }

  void _paintGloves(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final left = Path()
      ..moveTo(size.width * 0.34, size.height * 0.58)
      ..lineTo(size.width * 0.3, size.height * 0.36)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.22,
        size.width * 0.42,
        size.height * 0.34,
      )
      ..lineTo(size.width * 0.46, size.height * 0.58)
      ..close();
    final right = Path()
      ..moveTo(size.width * 0.66, size.height * 0.58)
      ..lineTo(size.width * 0.7, size.height * 0.36)
      ..quadraticBezierTo(
        size.width * 0.66,
        size.height * 0.22,
        size.width * 0.58,
        size.height * 0.34,
      )
      ..lineTo(size.width * 0.54, size.height * 0.58)
      ..close();
    canvas.drawPath(left, stroke);
    canvas.drawPath(right, stroke);
    canvas.drawLine(
      Offset(size.width * 0.42, size.height * 0.62),
      Offset(size.width * 0.58, size.height * 0.62),
      softStroke,
    );
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 5, fill);
  }

  void _paintRadar(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    for (final radius in <double>[0.12, 0.2, 0.28]) {
      canvas.drawCircle(center, size.width * radius, softStroke);
    }
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.5),
      Offset(size.width * 0.78, size.height * 0.5),
      softStroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.22),
      Offset(size.width * 0.5, size.height * 0.78),
      softStroke,
    );
    final sweep = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(size.width * 0.72, size.height * 0.34)
      ..arcToPoint(
        Offset(size.width * 0.72, size.height * 0.66),
        radius: Radius.circular(size.width * 0.24),
      )
      ..close();
    canvas.drawPath(
      sweep,
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );
    canvas.drawCircle(Offset(size.width * 0.64, size.height * 0.38), 4, fill);
    canvas.drawCircle(center, 5, stroke);
  }

  void _paintLightning(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final bolt = Path()
      ..moveTo(size.width * 0.56, size.height * 0.18)
      ..lineTo(size.width * 0.38, size.height * 0.48)
      ..lineTo(size.width * 0.5, size.height * 0.48)
      ..lineTo(size.width * 0.44, size.height * 0.82)
      ..lineTo(size.width * 0.66, size.height * 0.44)
      ..lineTo(size.width * 0.54, size.height * 0.44)
      ..close();
    canvas.drawPath(bolt, fill);
    canvas.drawPath(bolt, stroke);
    canvas.drawLine(
      Offset(size.width * 0.26, size.height * 0.64),
      Offset(size.width * 0.74, size.height * 0.24),
      softStroke,
    );
  }

  void _paintMedal(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final ribbon = Path()
      ..moveTo(size.width * 0.38, size.height * 0.2)
      ..lineTo(size.width * 0.48, size.height * 0.42)
      ..lineTo(size.width * 0.44, size.height * 0.46)
      ..lineTo(size.width * 0.32, size.height * 0.24)
      ..close();
    final ribbon2 = Path()
      ..moveTo(size.width * 0.62, size.height * 0.2)
      ..lineTo(size.width * 0.52, size.height * 0.42)
      ..lineTo(size.width * 0.56, size.height * 0.46)
      ..lineTo(size.width * 0.68, size.height * 0.24)
      ..close();
    canvas.drawPath(ribbon, fill);
    canvas.drawPath(ribbon2, fill);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.58),
      size.width * 0.16,
      stroke,
    );
    canvas.drawPath(
      _starPath(Offset(size.width * 0.5, size.height * 0.58), 12, 5),
      softStroke,
    );
  }

  void _paintStadium(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final bowl = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.36,
        size.width * 0.6,
        size.height * 0.34,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(bowl, stroke);
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.68),
      Offset(size.width * 0.72, size.height * 0.68),
      fill,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.44,
        size.width * 0.44,
        size.height * 0.18,
      ),
      pi,
      pi,
      false,
      softStroke,
    );
    for (final dx in <double>[0.32, 0.44, 0.56, 0.68]) {
      canvas.drawLine(
        Offset(size.width * dx, size.height * 0.3),
        Offset(size.width * dx, size.height * 0.42),
        softStroke,
      );
    }
  }

  void _paintRocket(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final body = Path()
      ..moveTo(size.width * 0.5, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.66,
        size.height * 0.34,
        size.width * 0.58,
        size.height * 0.62,
      )
      ..lineTo(size.width * 0.42, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.34,
        size.width * 0.5,
        size.height * 0.18,
      )
      ..close();
    canvas.drawPath(body, stroke);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.38), 6, fill);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.42, size.height * 0.56)
        ..lineTo(size.width * 0.32, size.height * 0.66)
        ..lineTo(size.width * 0.4, size.height * 0.66)
        ..moveTo(size.width * 0.58, size.height * 0.56)
        ..lineTo(size.width * 0.68, size.height * 0.66)
        ..lineTo(size.width * 0.6, size.height * 0.66)
        ..moveTo(size.width * 0.46, size.height * 0.62)
        ..lineTo(size.width * 0.42, size.height * 0.8)
        ..lineTo(size.width * 0.5, size.height * 0.72)
        ..lineTo(size.width * 0.58, size.height * 0.8)
        ..lineTo(size.width * 0.54, size.height * 0.62),
      softStroke,
    );
  }

  void _paintStar(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final star = _starPath(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.22,
      5,
    );
    canvas.drawPath(star, fill);
    canvas.drawPath(star, stroke);
    for (final offset in <Offset>[
      Offset(size.width * 0.28, size.height * 0.28),
      Offset(size.width * 0.72, size.height * 0.34),
      Offset(size.width * 0.66, size.height * 0.76),
    ]) {
      canvas.drawCircle(offset, 3.5, fill);
    }
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.5),
        radius: size.width * 0.34,
      ),
      pi * 0.15,
      pi * 0.8,
      false,
      softStroke,
    );
  }

  void _paintGift(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.38,
        size.width * 0.44,
        size.height * 0.3,
      ),
      const Radius.circular(14),
    );
    canvas.drawRRect(box, stroke);
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.38),
      Offset(size.width * 0.5, size.height * 0.68),
      softStroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.52),
      Offset(size.width * 0.72, size.height * 0.52),
      softStroke,
    );
    final bow = Path()
      ..moveTo(size.width * 0.5, size.height * 0.38)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.24,
        size.width * 0.34,
        size.height * 0.38,
      )
      ..moveTo(size.width * 0.5, size.height * 0.38)
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.24,
        size.width * 0.66,
        size.height * 0.38,
      );
    canvas.drawPath(bow, stroke);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.38), 4, fill);
  }

  void _paintGalaxy(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.28,
        size.width * 0.64,
        size.height * 0.34,
      ),
      pi * 0.12,
      pi * 1.62,
      false,
      stroke,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.18,
        size.width * 0.44,
        size.height * 0.5,
      ),
      -pi * 0.4,
      pi * 1.52,
      false,
      softStroke,
    );
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.48), 8, fill);
    for (final point in <Offset>[
      Offset(size.width * 0.26, size.height * 0.36),
      Offset(size.width * 0.72, size.height * 0.3),
      Offset(size.width * 0.66, size.height * 0.72),
      Offset(size.width * 0.38, size.height * 0.74),
    ]) {
      canvas.drawCircle(point, 2.5, fill);
    }
  }

  Path _starPath(Offset center, double radius, int points) {
    final path = Path();
    for (int index = 0; index < points * 2; index++) {
      final isOuter = index.isEven;
      final currentRadius = isOuter ? radius : radius * 0.45;
      final angle = (-pi / 2) + (pi / points) * index;
      final point = Offset(
        center.dx + cos(angle) * currentRadius,
        center.dy + sin(angle) * currentRadius,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant PlayerLevelIllustrationPainter oldDelegate) {
    return oldDelegate.spec != spec;
  }
}
