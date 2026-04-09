import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

class AppSplashScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const AppSplashScreen({super.key, required this.onCompleted});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 1800);
  static const _reducedMotionDelay = Duration(milliseconds: 500);

  late final AnimationController _controller;
  Timer? _completionTimer;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _complete();
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) {
      return;
    }
    if (AppMotion.reduceMotion(context)) {
      _completionTimer = Timer(_reducedMotionDelay, _complete);
      return;
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _complete() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AppMotion.reduceMotion(context);
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = reducedMotion ? 1.0 : _controller.value;
          final reveal = Curves.easeOutCubic.transform(
            const Interval(0.0, 0.75).transform(t),
          );
          final shimmer = Curves.easeInOutSine.transform(
            const Interval(0.0, 1.0).transform(t),
          );
          final cameraDrift = Curves.easeInOutCubic.transform(
            const Interval(0.08, 0.9).transform(t),
          );
          final fadeOut = Curves.easeIn.transform(
            const Interval(0.8, 1.0).transform(t),
          );
          return Opacity(
            opacity: 1 - fadeOut,
            child: CustomPaint(
              size: Size.infinite,
              painter: _GrassOnlySplashPainter(
                progress: t,
                reveal: reveal,
                shimmer: shimmer,
                cameraDrift: cameraDrift,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GrassOnlySplashPainter extends CustomPainter {
  final double progress;
  final double reveal;
  final double shimmer;
  final double cameraDrift;

  const _GrassOnlySplashPainter({
    required this.progress,
    required this.reveal,
    required this.shimmer,
    required this.cameraDrift,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final zoom = lerpDouble(1.0, 1.06, cameraDrift)!;
    final shiftY = lerpDouble(0.0, -size.height * 0.015, cameraDrift)!;

    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.5 + shiftY);
    canvas.scale(zoom, zoom);
    canvas.translate(-size.width * 0.5, -size.height * 0.5);

    _paintBaseGrass(canvas, rect);
    _paintStripeBands(canvas, rect);
    _paintFieldGlow(canvas, rect);
    _paintCenterMark(canvas, rect);
    _paintGrassTexture(canvas, size);
    _paintDewHighlights(canvas, size);
    _paintEdgeVignette(canvas, rect);

    canvas.restore();
  }

  void _paintBaseGrass(Canvas canvas, Rect rect) {
    final top =
        Color.lerp(const Color(0xFF174C1F), const Color(0xFF2C7A31), reveal)!;
    final mid =
        Color.lerp(const Color(0xFF1F6A27), const Color(0xFF3E963B), reveal)!;
    final bottom =
        Color.lerp(const Color(0xFF0E3615), const Color(0xFF1F5A25), reveal)!;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, mid, bottom],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(rect),
    );
  }

  void _paintStripeBands(Canvas canvas, Rect rect) {
    const stripeCount = 12;
    final stripeHeight = rect.height / stripeCount;
    for (var i = 0; i < stripeCount; i++) {
      final bandRect = Rect.fromLTWH(
        rect.left,
        rect.top + (stripeHeight * i),
        rect.width,
        stripeHeight,
      );
      final alphaBase = i.isEven ? 0.12 : 0.04;
      canvas.drawRect(
        bandRect,
        Paint()
          ..color = Colors.white.withValues(
            alpha: alphaBase + (shimmer * (i.isEven ? 0.04 : 0.015)),
          ),
      );
    }
  }

  void _paintFieldGlow(Canvas canvas, Rect rect) {
    final glowRect =
        Rect.fromLTWH(0, rect.height * 0.05, rect.width, rect.height * 0.7);
    canvas.drawRect(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.15),
          radius: 1.0,
          colors: [
            const Color(0xFFE9FFB2).withValues(alpha: 0.16 + (shimmer * 0.08)),
            const Color(0xFFB9F07A).withValues(alpha: 0.06 + (shimmer * 0.04)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(glowRect),
    );
  }

  void _paintCenterMark(Canvas canvas, Rect rect) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.8, rect.width * 0.0042)
      ..color = Colors.white.withValues(alpha: 0.26 + (reveal * 0.18));
    final midY = rect.height * 0.54;
    canvas.drawLine(Offset(0, midY), Offset(rect.width, midY), linePaint);
    canvas.drawCircle(
        Offset(rect.width * 0.5, midY), rect.width * 0.11, linePaint);
  }

  void _paintGrassTexture(Canvas canvas, Size size) {
    final bladePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 260; i++) {
      final seed = i / 260;
      final x = size.width * ((seed * 1.73 + (progress * 0.035)) % 1);
      final y = size.height * ((seed * 2.31 + 0.08) % 1);
      final bladeLength = lerpDouble(7, 18, (1 - y / size.height))!;
      final lean = sin((seed * 30) + (progress * 6.2)) * 2.4;
      final alpha = (0.06 + ((1 - y / size.height) * 0.16)).clamp(0.06, 0.2);
      bladePaint
        ..strokeWidth = lerpDouble(0.8, 1.5, (1 - y / size.height))!
        ..color = Color.lerp(
          const Color(0xFF7DD35B),
          const Color(0xFF184E1E),
          y / size.height,
        )!
            .withValues(alpha: alpha);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + lean, y - bladeLength),
        bladePaint,
      );
    }
  }

  void _paintDewHighlights(Canvas canvas, Size size) {
    final dewPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 48; i++) {
      final seed = i / 48;
      final x = size.width * ((seed * 2.17 + (progress * 0.022)) % 1);
      final y = size.height * (0.15 + ((seed * 1.91) % 0.72));
      final radius = 0.8 + ((i % 4) * 0.28);
      dewPaint.color = Colors.white.withValues(
        alpha: (0.05 + (shimmer * 0.09)) * (1 - (y / size.height) * 0.55),
      );
      canvas.drawCircle(Offset(x, y), radius, dewPaint);
    }
  }

  void _paintEdgeVignette(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.1),
          radius: 1.06,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.12),
            Colors.black.withValues(alpha: 0.28),
          ],
          stops: const [0.6, 0.86, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _GrassOnlySplashPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.reveal != reveal ||
        oldDelegate.shimmer != shimmer ||
        oldDelegate.cameraDrift != cameraDrift;
  }
}
