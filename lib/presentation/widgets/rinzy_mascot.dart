import 'package:flutter/material.dart';

class RinzyMascot extends StatefulWidget {
  final double size;
  final double progress;
  final bool animate;

  const RinzyMascot({
    super.key,
    this.size = 112,
    this.progress = 0,
    this.animate = true,
  });

  @override
  State<RinzyMascot> createState() => _RinzyMascotState();
}

class _RinzyMascotState extends State<RinzyMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(RinzyMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Rinzy',
      image: true,
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _RinzyMascotPainter(
                  progress: widget.progress.clamp(0, 1).toDouble(),
                  animation: widget.animate ? _controller.value : 0,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RinzyMascotPainter extends CustomPainter {
  final double progress;
  final double animation;

  const _RinzyMascotPainter({
    required this.progress,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = _sin(animation);
    final kick = _sin((animation + 0.18) % 1);
    final scarfWave = _sin((animation + 0.35) % 1);
    final scale = size.width / 112;
    canvas.save();
    canvas.scale(scale);

    final field = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEAF7E8), Color(0xFFD7F1F7)],
      ).createShader(const Rect.fromLTWH(6, 6, 100, 100));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6, 6, 100, 100),
        const Radius.circular(28),
      ),
      field,
    );
    final fieldLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawArc(
      const Rect.fromLTWH(8, 74, 96, 30),
      3.25,
      2.9,
      false,
      fieldLine,
    );
    canvas.drawLine(const Offset(12, 91), const Offset(100, 91), fieldLine);

    final shadow = Paint()
      ..color = const Color(0x1F152033)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromLTWH(20, 94 + pulse * 1.5, 72, 10 - pulse.abs()),
      shadow,
    );

    canvas.save();
    canvas.translate(0, -2 - pulse * 2.8);

    final body = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFE08A), Color(0xFFFFB84D)],
      ).createShader(const Rect.fromLTWH(25, 8, 72, 95));
    final outline = Paint()
      ..color = const Color(0xFF6B4A1F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final spot = Paint()..color = const Color(0xFFB8792B);
    final white = Paint()..color = Colors.white;
    final black = Paint()..color = const Color(0xFF182033);
    final boot = Paint()..color = const Color(0xFF2446A8);
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final ballLine = Paint()
      ..color = const Color(0xFF182033)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final bodyPath = Path()
      ..moveTo(35, 58)
      ..cubicTo(47, 45, 70, 48, 78, 63)
      ..cubicTo(86, 77, 76, 91, 55, 91)
      ..cubicTo(36, 91, 25, 76, 35, 58);
    canvas.drawPath(bodyPath, body);
    canvas.drawPath(bodyPath, outline);
    canvas.drawArc(
      const Rect.fromLTWH(39, 54, 25, 22),
      3.55,
      1.1,
      false,
      highlight,
    );

    final neckPath = Path()
      ..moveTo(59, 56)
      ..cubicTo(58, 42, 61, 27, 68, 18)
      ..lineTo(79, 22)
      ..cubicTo(72, 34, 71, 46, 73, 59)
      ..close();
    canvas.drawPath(neckPath, body);
    canvas.drawPath(neckPath, outline);

    final headPath = Path()
      ..moveTo(66, 18)
      ..cubicTo(70, 7, 87, 9, 93, 18)
      ..cubicTo(99, 27, 92, 38, 80, 38)
      ..cubicTo(70, 38, 63, 29, 66, 18);
    canvas.drawPath(headPath, body);
    canvas.drawPath(headPath, outline);

    canvas.drawCircle(const Offset(68, 12), 4.2, body);
    canvas.drawCircle(const Offset(88, 10), 4.2, body);
    canvas.drawLine(const Offset(69, 15), const Offset(71, 20), outline);
    canvas.drawLine(const Offset(87, 14), const Offset(85, 20), outline);
    canvas.drawOval(const Rect.fromLTWH(61, 17, 10, 13), body);
    canvas.drawOval(const Rect.fromLTWH(90, 18, 11, 13), body);
    canvas.drawCircle(const Offset(78, 23), 5, white);
    canvas.drawCircle(const Offset(79.5, 24), 2.2, black);
    canvas.drawOval(const Rect.fromLTWH(79, 22, 4, 5), black);
    canvas.drawCircle(const Offset(82, 21), 2, white);
    canvas.drawArc(
      const Rect.fromLTWH(82, 26, 9, 7),
      0.1,
      2.6,
      false,
      outline,
    );

    for (final circle in const <Rect>[
      Rect.fromLTWH(45, 56, 8, 8),
      Rect.fromLTWH(61, 63, 10, 9),
      Rect.fromLTWH(42, 75, 9, 8),
      Rect.fromLTWH(66, 78, 7, 7),
      Rect.fromLTWH(65, 34, 6, 8),
      Rect.fromLTWH(72, 48, 6, 8),
      Rect.fromLTWH(75, 15, 6, 6),
    ]) {
      canvas.drawOval(circle, spot);
    }

    final leftLeg = Path()
      ..moveTo(44, 86)
      ..lineTo(38, 102)
      ..lineTo(45, 102)
      ..lineTo(52, 88);
    final rightLeg = Path()
      ..moveTo(68, 86)
      ..lineTo(82 + kick * 4, 98 - kick.abs() * 3)
      ..lineTo(88 + kick * 5, 94 - kick.abs() * 4)
      ..lineTo(75, 84);
    canvas.drawPath(leftLeg, body);
    canvas.drawPath(leftLeg, outline);
    canvas.drawPath(rightLeg, body);
    canvas.drawPath(rightLeg, outline);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(34, 99, 14, 7), const Radius.circular(3)),
      boot,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(82 + kick * 5, 91 - kick.abs() * 4, 14, 7),
        const Radius.circular(3),
      ),
      boot,
    );

    final scarf = Paint()..color = const Color(0xFF2B6FF3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(58, 51, 24, 7), const Radius.circular(4)),
      scarf,
    );
    canvas.drawPath(
      Path()
        ..moveTo(76, 56)
        ..quadraticBezierTo(83, 61 + scarfWave * 4, 91, 66 - scarfWave * 2)
        ..lineTo(83, 69 + scarfWave * 2)
        ..quadraticBezierTo(77, 63, 72, 58)
        ..close(),
      scarf,
    );

    canvas.restore();

    final ballCenter = Offset(
      21 + progress * 8 + kick * 4,
      82 - progress * 4 - kick.abs() * 7,
    );
    final ballShadow = Paint()
      ..color = const Color(0x26152033)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(ballCenter.dx, 96),
        width: 22 - kick.abs() * 3,
        height: 5,
      ),
      ballShadow,
    );
    canvas.drawCircle(ballCenter, 12, white);
    canvas.drawCircle(ballCenter, 12, outline);
    canvas.drawCircle(ballCenter, 4, black);
    canvas.drawLine(ballCenter + const Offset(-4, -4),
        ballCenter + const Offset(-10, -8), ballLine);
    canvas.drawLine(ballCenter + const Offset(4, -4),
        ballCenter + const Offset(10, -8), ballLine);
    canvas.drawLine(ballCenter + const Offset(-4, 4),
        ballCenter + const Offset(-8, 10), ballLine);
    canvas.drawLine(ballCenter + const Offset(4, 4),
        ballCenter + const Offset(9, 8), ballLine);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_RinzyMascotPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animation != animation;
  }

  double _sin(double value) {
    final shifted = value < 0.5 ? value * 2 : (1 - value) * 2;
    return shifted * 2 - 1;
  }
}
