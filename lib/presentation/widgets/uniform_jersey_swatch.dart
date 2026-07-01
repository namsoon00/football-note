import 'package:flutter/material.dart';

class UniformJerseySwatch extends StatelessWidget {
  final Color color;
  final double size;
  final Color borderColor;
  final double borderWidth;
  final bool selected;
  final Color? checkColor;
  final String? semanticLabel;

  const UniformJerseySwatch({
    super.key,
    required this.color,
    required this.size,
    required this.borderColor,
    this.borderWidth = 1.2,
    this.selected = false,
    this.checkColor,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final swatch = SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _UniformJerseyPainter(
              fillColor: color,
              borderColor: borderColor,
              borderWidth: borderWidth,
            ),
          ),
          if (selected)
            Icon(
              Icons.check,
              size: size * 0.48,
              color: checkColor ?? _contrastColor(color),
            ),
        ],
      ),
    );

    if (semanticLabel == null) return swatch;
    return Semantics(label: semanticLabel, child: swatch);
  }

  static Color _contrastColor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}

class _UniformJerseyPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;

  const _UniformJerseyPainter({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);

    final path = Path()
      ..moveTo(11.1, 4.1)
      ..lineTo(8.2, 5.2)
      ..lineTo(3.8, 10.3)
      ..lineTo(7.7, 14.5)
      ..lineTo(9.7, 12.7)
      ..lineTo(9.7, 27.0)
      ..quadraticBezierTo(9.7, 28.6, 11.3, 28.6)
      ..lineTo(20.7, 28.6)
      ..quadraticBezierTo(22.3, 28.6, 22.3, 27.0)
      ..lineTo(22.3, 12.7)
      ..lineTo(24.3, 14.5)
      ..lineTo(28.2, 10.3)
      ..lineTo(23.8, 5.2)
      ..lineTo(20.9, 4.1)
      ..cubicTo(20.4, 7.1, 18.5, 8.9, 16.0, 8.9)
      ..cubicTo(13.5, 8.9, 11.6, 7.1, 11.1, 4.1)
      ..close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final detailColor =
        ThemeData.estimateBrightnessForColor(fillColor) == Brightness.dark
            ? Colors.white.withValues(alpha: 0.42)
            : Colors.black.withValues(alpha: 0.24);
    final detailPaint = Paint()
      ..color = detailColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = borderWidth;

    final collarPath = Path()
      ..moveTo(11.8, 4.5)
      ..quadraticBezierTo(12.8, 10.2, 16.0, 10.2)
      ..quadraticBezierTo(19.2, 10.2, 20.2, 4.5);
    canvas.drawPath(collarPath, detailPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = borderWidth;
    canvas.drawPath(path, borderPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _UniformJerseyPainter oldDelegate) {
    return fillColor != oldDelegate.fillColor ||
        borderColor != oldDelegate.borderColor ||
        borderWidth != oldDelegate.borderWidth;
  }
}
