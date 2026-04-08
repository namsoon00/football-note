import 'dart:async';
import 'dart:math' as math;
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
  static const _duration = Duration(milliseconds: 2000);
  static const _reducedMotionDelay = Duration(milliseconds: 600);

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
          final groundReveal = Curves.easeOutCubic.transform(
            const Interval(0.0, 0.24).transform(t),
          );
          final forwardMotion = Curves.easeInOutCubic.transform(
            const Interval(0.08, 0.92).transform(t),
          );
          final skyBloom = Curves.easeOutCubic.transform(
            const Interval(0.24, 0.88).transform(t),
          );
          final atmosphere = Curves.easeOutQuad.transform(
            const Interval(0.08, 0.84).transform(t),
          );
          final fadeOut = Curves.easeIn.transform(
            const Interval(0.82, 1.0).transform(t),
          );
          // In the last phase, expand ground to cover full screen.
          final fullCover = Curves.easeOutCubic.transform(
            const Interval(0.9, 1.0).transform(t),
          );

          return Opacity(
            opacity: 1 - fadeOut,
            child: CustomPaint(
              size: Size.infinite,
              painter: _ForwardFieldSplashPainter(
                progress: t,
                groundReveal: groundReveal,
                forwardMotion: forwardMotion,
                skyBloom: skyBloom,
                atmosphere: atmosphere,
                fullCover: fullCover,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ForwardFieldSplashPainter extends CustomPainter {
  final double progress;
  final double groundReveal;
  final double forwardMotion;
  final double skyBloom;
  final double atmosphere;
  final double fullCover;

  const _ForwardFieldSplashPainter({
    required this.progress,
    required this.groundReveal,
    required this.forwardMotion,
    required this.skyBloom,
    required this.atmosphere,
    required this.fullCover,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final horizonY = lerpDouble(
      size.height * 0.7,
      size.height * 0.58,
      forwardMotion,
    )!;

    _paintSky(canvas, rect, horizonY);
    _paintSunGlow(canvas, size, horizonY);
    _paintClouds(canvas, size, horizonY);
    _paintDistantStands(canvas, size, horizonY);
    _paintGround(canvas, size, horizonY);
    _paintMist(canvas, size, horizonY);
    _paintAirStreaks(canvas, size, horizonY);
    _paintParticles(canvas, size, horizonY);
    _paintVignette(canvas, rect);
    _paintFullCover(canvas, size);
  }

  void _paintSky(Canvas canvas, Rect rect, double horizonY) {
    final skyRect = Rect.fromLTWH(rect.left, rect.top, rect.width, horizonY);
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(
            const Color(0xFF031424),
            const Color(0xFF9ED8FF),
            skyBloom,
          )!,
          Color.lerp(
            const Color(0xFF0A2740),
            const Color(0xFF63B6FF),
            skyBloom,
          )!,
          Color.lerp(
            const Color(0xFF103A57),
            const Color(0xFFD9F2FF),
            skyBloom,
          )!,
        ],
        stops: const [0.0, 0.58, 1.0],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    final bloomPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.45),
        radius: 1.02,
        colors: [
          Colors.white.withValues(alpha: 0.24 * skyBloom),
          const Color(0xFFBEE7FF).withValues(alpha: 0.14 * skyBloom),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, bloomPaint);
  }

  void _paintSunGlow(Canvas canvas, Size size, double horizonY) {
    final center = Offset(
      size.width * 0.56,
      lerpDouble(
        horizonY + size.height * 0.05,
        horizonY - size.height * 0.03,
        skyBloom,
      )!,
    );
    final radius = lerpDouble(size.width * 0.08, size.width * 0.18, skyBloom)!;
    canvas.drawCircle(
      center,
      radius * 1.85,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.22 * skyBloom),
            const Color(0xFFFFF0B2).withValues(alpha: 0.16 * skyBloom),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.85)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.92 * skyBloom),
            const Color(0xFFFFF3C9).withValues(alpha: 0.72 * skyBloom),
            const Color(0xFFFFC95A).withValues(alpha: 0.18 * skyBloom),
          ],
          stops: const [0.0, 0.56, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _paintClouds(Canvas canvas, Size size, double horizonY) {
    final cloudPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.18 + (i * 0.22));
      final y = lerpDouble(
        horizonY - size.height * 0.18,
        horizonY - size.height * (0.16 + (i.isEven ? 0.03 : 0.0)),
        skyBloom,
      )!;
      final width = size.width * (0.17 + (i.isOdd ? 0.03 : 0.0));
      final height = size.height * 0.055;
      cloudPaint.color = Colors.white.withValues(
        alpha: (0.04 + (0.08 * skyBloom)) * (i.isEven ? 1.0 : 0.82),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: width, height: height),
        cloudPaint,
      );
    }
  }

  void _paintDistantStands(Canvas canvas, Size size, double horizonY) {
    final standsPath = Path()
      ..moveTo(0, horizonY + size.height * 0.018)
      ..quadraticBezierTo(
        size.width * 0.18,
        horizonY - size.height * 0.014,
        size.width * 0.34,
        horizonY + size.height * 0.004,
      )
      ..quadraticBezierTo(
        size.width * 0.52,
        horizonY + size.height * 0.02,
        size.width * 0.68,
        horizonY,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        horizonY - size.height * 0.016,
        size.width,
        horizonY + size.height * 0.014,
      )
      ..lineTo(size.width, horizonY + size.height * 0.095)
      ..lineTo(0, horizonY + size.height * 0.095)
      ..close();

    canvas.drawPath(
      standsPath,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF10263C).withValues(alpha: 0.84),
                const Color(0xFF081420).withValues(alpha: 0.94),
              ],
            ).createShader(
              Rect.fromLTWH(0, horizonY, size.width, size.height * 0.1),
            ),
    );

    final lightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14 + (0.16 * skyBloom))
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.2, size.shortestSide * 0.004);
    for (var i = 0; i < 11; i++) {
      final dx = size.width * (0.08 + (i * 0.084));
      canvas.drawPoints(PointMode.points, [
        Offset(dx, horizonY + size.height * 0.03),
      ], lightPaint);
    }
  }

  void _paintGround(Canvas canvas, Size size, double horizonY) {
    final groundTop = lerpDouble(
      size.height,
      horizonY - size.height * 0.01,
      groundReveal,
    )!;
    final groundRect = Rect.fromLTWH(
      0,
      groundTop,
      size.width,
      size.height - groundTop,
    );
    final grassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(
            const Color(0xFF224C1E),
            const Color(0xFF2F6F2F),
            atmosphere,
          )!,
          Color.lerp(
            const Color(0xFF173312),
            const Color(0xFF1B4718),
            atmosphere,
          )!,
          const Color(0xFF091707),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(groundRect);
    canvas.drawRect(groundRect, grassPaint);

    final stripePaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 10; i++) {
      final startY = lerpDouble(groundTop, size.height, i / 10)!;
      final endY = lerpDouble(groundTop, size.height, (i + 1) / 10)!;
      stripePaint.color =
          (i.isEven ? const Color(0xFF75C85E) : const Color(0xFF295227))
              .withValues(alpha: 0.16 + (0.08 * forwardMotion));
      canvas.drawRect(
        Rect.fromLTWH(0, startY, size.width, endY - startY),
        stripePaint,
      );
    }

    final lanePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final ratio = (i + 1) / 9;
      final y = lerpDouble(
        groundTop + size.height * 0.02,
        size.height * 1.06,
        math.pow(ratio, 1.45).toDouble(),
      )!;
      lanePaint
        ..strokeWidth = lerpDouble(1.1, 9.5, ratio)!
        ..color = Colors.white.withValues(
          alpha: (0.04 + (0.15 * forwardMotion)) * (1 - ratio * 0.55),
        );
      canvas.drawLine(
        Offset(size.width * 0.5, horizonY + size.height * 0.015),
        Offset(size.width * (-0.08 + (ratio * 0.2)), y),
        lanePaint,
      );
      canvas.drawLine(
        Offset(size.width * 0.5, horizonY + size.height * 0.015),
        Offset(size.width * (1.08 - (ratio * 0.2)), y),
        lanePaint,
      );
    }

    final streakPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.2, size.shortestSide * 0.003);
    for (var i = 0; i < 36; i++) {
      final ratio = ((i * 19) % 100) / 100;
      final side = i.isEven ? -1.0 : 1.0;
      final start = Offset(
        size.width * 0.5 + (size.width * 0.08 * side * ratio),
        lerpDouble(
          horizonY + size.height * 0.02,
          size.height * 0.88,
          math.pow(ratio, 1.15).toDouble(),
        )!,
      );
      final end = Offset(
        size.width * 0.5 + (size.width * (0.22 + ratio * 0.42) * side),
        start.dy + size.height * (0.03 + ratio * 0.08),
      );
      streakPaint.color = const Color(
        0xFFBEF2A5,
      ).withValues(alpha: 0.06 + (0.14 * forwardMotion * (1 - ratio * 0.35)));
      canvas.drawLine(start, end, streakPaint);
    }
  }

  void _paintMist(Canvas canvas, Size size, double horizonY) {
    final mistRect = Rect.fromLTWH(
      0,
      horizonY - size.height * 0.05,
      size.width,
      size.height * 0.24,
    );
    canvas.drawRect(
      mistRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.14 * atmosphere),
            const Color(0xFFB0E4FF).withValues(alpha: 0.12 * atmosphere),
            Colors.transparent,
          ],
          stops: const [0.0, 0.44, 1.0],
        ).createShader(mistRect),
    );
  }

  void _paintAirStreaks(Canvas canvas, Size size, double horizonY) {
    final speedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i++) {
      final ratio = i / 18;
      final startX = size.width * (0.1 + ((i * 37) % 80) / 100);
      final startY = horizonY - size.height * (0.02 + ratio * 0.1);
      final length = size.width * (0.04 + ratio * 0.08);
      speedPaint
        ..strokeWidth = lerpDouble(1.0, 3.2, ratio)!
        ..color = Colors.white.withValues(
          alpha: (0.05 + (0.18 * forwardMotion)) * (1 - ratio * 0.45),
        );
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX + length, startY + size.height * 0.012),
        speedPaint,
      );
    }
  }

  void _paintParticles(Canvas canvas, Size size, double horizonY) {
    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 24; i++) {
      final dx = size.width * ((i * 41) % 100 / 100);
      final dy = lerpDouble(
        horizonY - size.height * 0.03,
        horizonY + size.height * 0.22,
        ((i * 19) % 100) / 100,
      )!;
      final radius = lerpDouble(1.0, 3.0, ((i * 13) % 100) / 100)!;
      particlePaint.color = Colors.white.withValues(
        alpha: (0.04 + (0.12 * atmosphere)) * (i.isEven ? 1.0 : 0.7),
      );
      canvas.drawCircle(Offset(dx, dy), radius, particlePaint);
    }
  }

  void _paintVignette(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.05),
          radius: 1.06,
          colors: [
            Colors.transparent,
            const Color(0xFF061019).withValues(alpha: 0.16 + (0.06 * progress)),
            const Color(0xFF02070C).withValues(alpha: 0.52),
          ],
          stops: const [0.48, 0.82, 1.0],
        ).createShader(rect),
    );
  }

  void _paintFullCover(Canvas canvas, Size size) {
    if (fullCover <= 0) return;
    final rect = Offset.zero & size;
    final shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1E4A1C).withValues(alpha: 0.85 * fullCover),
          const Color(0xFF0C1A0A).withValues(alpha: 0.95 * fullCover),
        ],
        stops: const [0.0, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _ForwardFieldSplashPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.groundReveal != groundReveal ||
        oldDelegate.forwardMotion != forwardMotion ||
        oldDelegate.skyBloom != skyBloom ||
        oldDelegate.atmosphere != atmosphere ||
        oldDelegate.fullCover != fullCover;
  }
}
