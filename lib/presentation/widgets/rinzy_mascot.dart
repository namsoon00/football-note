import 'package:flutter/material.dart';

class RinzyMascot extends StatelessWidget {
  final double size;
  final double progress;

  const RinzyMascot({
    super.key,
    this.size = 112,
    this.progress = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Rinzy',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RinzyMascotPainter(
            progress: progress.clamp(0, 1).toDouble(),
          ),
        ),
      ),
    );
  }
}

class _RinzyMascotPainter extends CustomPainter {
  final double progress;

  const _RinzyMascotPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 112;
    canvas.save();
    canvas.scale(scale);

    final shadow = Paint()
      ..color = const Color(0x1F152033)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(const Rect.fromLTWH(20, 93, 72, 10), shadow);

    final body = Paint()..color = const Color(0xFFFFC857);
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

    canvas.drawCircle(const Offset(68, 12), 4, body);
    canvas.drawCircle(const Offset(88, 10), 4, body);
    canvas.drawLine(const Offset(69, 15), const Offset(71, 20), outline);
    canvas.drawLine(const Offset(87, 14), const Offset(85, 20), outline);
    canvas.drawOval(const Rect.fromLTWH(61, 17, 10, 13), body);
    canvas.drawOval(const Rect.fromLTWH(90, 18, 11, 13), body);
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
      ..lineTo(82, 98)
      ..lineTo(88, 94)
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
          const Rect.fromLTWH(82, 91, 14, 7), const Radius.circular(3)),
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
        ..lineTo(88, 66)
        ..lineTo(81, 68)
        ..lineTo(72, 58)
        ..close(),
      scarf,
    );

    final ballCenter = Offset(21 + progress * 8, 82 - progress * 4);
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
    return oldDelegate.progress != progress;
  }
}
