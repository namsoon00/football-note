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
            const Interval(0.0, 0.46).transform(t),
          );
          final cameraLift = Curves.easeInOutCubic.transform(
            const Interval(0.18, 0.86).transform(t),
          );
          final skyBloom = Curves.easeOutCubic.transform(
            const Interval(0.34, 0.9).transform(t),
          );
          final atmosphere = Curves.easeOutQuad.transform(
            const Interval(0.08, 0.84).transform(t),
          );
          final fadeOut = Curves.easeIn.transform(
            const Interval(0.82, 1.0).transform(t),
          );

          return Opacity(
            opacity: 1 - fadeOut,
            child: CustomPaint(
              size: Size.infinite,
              painter: _GroundToSkySplashPainter(
                progress: t,
                groundReveal: groundReveal,
                cameraLift: cameraLift,
                skyBloom: skyBloom,
                atmosphere: atmosphere,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GroundToSkySplashPainter extends CustomPainter {
  final double progress;
  final double groundReveal;
  final double cameraLift;
  final double skyBloom;
  final double atmosphere;

  const _GroundToSkySplashPainter({
    required this.progress,
    required this.groundReveal,
    required this.cameraLift,
    required this.skyBloom,
    required this.atmosphere,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final horizonY = lerpDouble(
      size.height * 0.84,
      size.height * 0.34,
      cameraLift,
    )!;

    _paintSky(canvas, rect, horizonY);
    _paintSunGlow(canvas, size, horizonY);
    _paintClouds(canvas, size, horizonY);
    _paintDistantStands(canvas, size, horizonY);
    _paintGround(canvas, size, horizonY);
    _paintMistBridge(canvas, size, horizonY);
    _paintPlayerAction(canvas, size, horizonY);
    _paintParticles(canvas, size, horizonY);
    _paintVignette(canvas, rect);
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
            const Color(0xFFBEE7FF),
            skyBloom,
          )!,
        ],
        stops: const [0.0, 0.56, 1.0],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    final bloomPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.4),
        radius: 1.0,
        colors: [
          Colors.white.withValues(alpha: 0.22 * skyBloom),
          const Color(0xFFBEE7FF).withValues(alpha: 0.12 * skyBloom),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, bloomPaint);
  }

  void _paintSunGlow(Canvas canvas, Size size, double horizonY) {
    final center = Offset(
      size.width * 0.5,
      lerpDouble(
        horizonY + size.height * 0.08,
        horizonY - size.height * 0.02,
        skyBloom,
      )!,
    );
    final radius = lerpDouble(size.width * 0.1, size.width * 0.22, skyBloom)!;
    canvas.drawCircle(
      center,
      radius * 1.8,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.24 * skyBloom),
            const Color(0xFFFFF0B2).withValues(alpha: 0.16 * skyBloom),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.8)),
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
      final x = size.width * (0.18 + (i * 0.21));
      final y = lerpDouble(
        horizonY - size.height * 0.16,
        horizonY - size.height * (0.18 + (i.isEven ? 0.02 : 0.0)),
        skyBloom,
      )!;
      final width = size.width * (0.18 + (i.isOdd ? 0.03 : 0.0));
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
      ..moveTo(0, horizonY + size.height * 0.015)
      ..quadraticBezierTo(
        size.width * 0.18,
        horizonY - size.height * 0.008,
        size.width * 0.34,
        horizonY + size.height * 0.004,
      )
      ..quadraticBezierTo(
        size.width * 0.52,
        horizonY + size.height * 0.018,
        size.width * 0.68,
        horizonY,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        horizonY - size.height * 0.016,
        size.width,
        horizonY + size.height * 0.012,
      )
      ..lineTo(size.width, horizonY + size.height * 0.09)
      ..lineTo(0, horizonY + size.height * 0.09)
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
      ..strokeWidth = max(1.2, size.shortestSide * 0.004);
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
      horizonY - size.height * 0.02,
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
          const Color(0xFF0B1809),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(groundRect);
    canvas.drawRect(groundRect, grassPaint);

    final stripPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 9; i++) {
      final startY = lerpDouble(groundTop, size.height, i / 9)!;
      final endY = lerpDouble(groundTop, size.height, (i + 1) / 9)!;
      stripPaint.color =
          (i.isEven ? const Color(0xFF7ACB63) : const Color(0xFF315E2B))
              .withValues(
                alpha: (0.08 + (0.07 * groundReveal)) * (1.0 - (i / 12)),
              );
      canvas.drawRect(
        Rect.fromLTWH(0, startY, size.width, endY - startY),
        stripPaint,
      );
    }

    final bladesPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = max(1.0, size.shortestSide * 0.0024);
    for (var i = 0; i < 120; i++) {
      final dx = size.width * ((i * 73) % 100 / 100);
      final baseY = lerpDouble(
        groundTop + size.height * 0.04,
        size.height,
        ((i * 29) % 100) / 100,
      )!;
      final length = lerpDouble(
        size.height * 0.012,
        size.height * 0.05,
        ((i * 17) % 100) / 100,
      )!;
      bladesPaint.color =
          (i.isEven ? const Color(0xFF8BDE70) : const Color(0xFF2A7A2B))
              .withValues(alpha: 0.18 + (0.12 * groundReveal));
      canvas.drawLine(
        Offset(dx, baseY),
        Offset(dx + (i.isEven ? 2 : -2), baseY - length),
        bladesPaint,
      );
    }
  }

  void _paintMistBridge(Canvas canvas, Size size, double horizonY) {
    final mistRect = Rect.fromLTWH(
      0,
      horizonY - size.height * 0.05,
      size.width,
      size.height * 0.22,
    );
    canvas.drawRect(
      mistRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.18 * atmosphere),
            const Color(0xFFB0E4FF).withValues(alpha: 0.14 * atmosphere),
            Colors.transparent,
          ],
          stops: const [0.0, 0.44, 1.0],
        ).createShader(mistRect),
    );
  }

  void _paintPlayerAction(Canvas canvas, Size size, double horizonY) {
    final action = Curves.easeInOutCubic.transform(
      const Interval(0.08, 0.92).transform(progress),
    );
    final kickLift = Curves.easeOutCubic.transform(
      const Interval(0.52, 0.92).transform(progress),
    );
    final bodyColor = Color.lerp(
      const Color(0xFF071018),
      const Color(0xFF14344A),
      skyBloom * 0.45,
    )!;
    final shadowColor = Colors.black.withValues(alpha: 0.18 + (0.16 * action));
    final bodyPaint = Paint()..color = bodyColor;
    final jerseyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF66E0A0).withValues(alpha: 0.82),
          const Color(0xFF1A7F54).withValues(alpha: 0.92),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final limbPaint = Paint()
      ..color = bodyColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = max(3.2, size.shortestSide * 0.011);

    final playerX = lerpDouble(size.width * 0.43, size.width * 0.56, action)!;
    final footY = lerpDouble(
      horizonY + size.height * 0.17,
      horizonY + size.height * 0.12,
      kickLift,
    )!;
    final bodyLean = lerpDouble(0.28, -0.12, kickLift)!;
    final torsoHeight = size.height * 0.145;
    final torsoWidth = size.width * 0.07;
    final hip = Offset(playerX, footY - torsoHeight * 0.5);
    final shoulder = Offset(
      hip.dx - torsoWidth * 0.14,
      hip.dy - torsoHeight * 0.52,
    );
    final headCenter = Offset(
      shoulder.dx + torsoWidth * 0.22,
      shoulder.dy - size.height * 0.06,
    );
    final gazeLift = lerpDouble(0.16, -0.42, kickLift)!;
    final faceOffset = Offset(
      torsoWidth * 0.16,
      size.height * 0.006 * gazeLift,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(playerX, footY + size.height * 0.012),
        width: torsoWidth * 1.7,
        height: size.height * 0.038,
      ),
      Paint()..color = shadowColor,
    );

    canvas.save();
    canvas.translate(hip.dx, hip.dy);
    canvas.rotate(bodyLean);
    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -torsoHeight * 0.16),
        width: torsoWidth,
        height: torsoHeight,
      ),
      Radius.circular(torsoWidth * 0.36),
    );
    canvas.drawRRect(torsoRect, jerseyPaint);
    canvas.restore();

    canvas.drawCircle(headCenter, size.shortestSide * 0.026, bodyPaint);
    canvas.drawCircle(
      headCenter.translate(faceOffset.dx, faceOffset.dy),
      size.shortestSide * 0.005,
      Paint()..color = const Color(0xFFE7F7FF).withValues(alpha: 0.78),
    );

    final leadFoot = Offset(
      hip.dx + size.width * 0.055,
      footY - size.height * 0.01 * kickLift,
    );
    final trailFoot = Offset(
      hip.dx - size.width * 0.048,
      footY + size.height * 0.014 * (1 - kickLift),
    );
    final kneeFront = Offset(
      hip.dx + size.width * 0.028,
      footY - size.height * (0.056 + (0.028 * kickLift)),
    );
    final kneeBack = Offset(
      hip.dx - size.width * 0.02,
      footY - size.height * (0.045 - (0.012 * kickLift)),
    );
    final elbowFront = Offset(
      shoulder.dx + size.width * 0.042,
      shoulder.dy + size.height * 0.018,
    );
    final handFront = Offset(
      shoulder.dx + size.width * (0.072 - (0.014 * kickLift)),
      shoulder.dy + size.height * (0.058 - (0.022 * kickLift)),
    );
    final elbowBack = Offset(
      shoulder.dx - size.width * 0.03,
      shoulder.dy + size.height * 0.025,
    );
    final handBack = Offset(
      shoulder.dx - size.width * 0.054,
      shoulder.dy + size.height * 0.07,
    );

    canvas.drawLine(shoulder, elbowFront, limbPaint);
    canvas.drawLine(elbowFront, handFront, limbPaint);
    canvas.drawLine(shoulder, elbowBack, limbPaint);
    canvas.drawLine(elbowBack, handBack, limbPaint);
    canvas.drawLine(hip, kneeFront, limbPaint);
    canvas.drawLine(kneeFront, leadFoot, limbPaint);
    canvas.drawLine(hip, kneeBack, limbPaint);
    canvas.drawLine(kneeBack, trailFoot, limbPaint);

    final ballStart = Offset(
      leadFoot.dx + size.width * 0.032,
      footY - size.height * 0.012,
    );
    final ballControl = Offset(
      size.width * 0.56,
      horizonY + size.height * 0.05,
    );
    final ballEnd = Offset(size.width * 0.61, horizonY - size.height * 0.14);
    final ballPosition = Offset(
      _quadraticAt(ballStart.dx, ballControl.dx, ballEnd.dx, kickLift),
      _quadraticAt(ballStart.dy, ballControl.dy, ballEnd.dy, kickLift),
    );
    final trailPath = Path()..moveTo(ballStart.dx, ballStart.dy);
    for (var i = 1; i <= 18; i++) {
      final t = kickLift * (i / 18);
      trailPath.lineTo(
        _quadraticAt(ballStart.dx, ballControl.dx, ballEnd.dx, t),
        _quadraticAt(ballStart.dy, ballControl.dy, ballEnd.dy, t),
      );
    }
    canvas.drawPath(
      trailPath,
      Paint()
        ..color = const Color(
          0xFFDBF4FF,
        ).withValues(alpha: 0.22 + (0.22 * kickLift))
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.4, size.shortestSide * 0.004)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      ballPosition,
      size.shortestSide * 0.018,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.98),
                const Color(0xFFF7D76B).withValues(alpha: 0.92),
                const Color(0xFFF39C12).withValues(alpha: 0.78),
              ],
            ).createShader(
              Rect.fromCircle(
                center: ballPosition,
                radius: size.shortestSide * 0.018,
              ),
            ),
    );
    canvas.drawCircle(
      ballPosition,
      size.shortestSide * 0.032,
      Paint()
        ..color = const Color(
          0xFFFFF6B8,
        ).withValues(alpha: 0.16 + (0.16 * kickLift)),
    );
  }

  double _quadraticAt(double start, double control, double end, double t) {
    final mt = 1 - t;
    return (mt * mt * start) + (2 * mt * t * control) + (t * t * end);
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

  @override
  bool shouldRepaint(covariant _GroundToSkySplashPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.groundReveal != groundReveal ||
        oldDelegate.cameraLift != cameraLift ||
        oldDelegate.skyBloom != skyBloom ||
        oldDelegate.atmosphere != atmosphere;
  }
}
