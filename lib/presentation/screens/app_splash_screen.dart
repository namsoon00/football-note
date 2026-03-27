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
  static const _duration = Duration(milliseconds: 1650);
  static const _reducedMotionDelay = Duration(milliseconds: 450);

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
    if (_completed || !mounted) {
      return;
    }
    _completed = true;
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotion(context);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = reduceMotion ? 1.0 : _controller.value;
          final lightRise = Curves.easeIn.transform(
            const Interval(0.08, 0.78).transform(t),
          );
          final fieldReveal = Curves.easeOutCubic.transform(
            const Interval(0.22, 0.88).transform(t),
          );
          final playerAdvance = Curves.easeInOutCubic.transform(
            const Interval(0.0, 0.72).transform(t),
          );
          final haze = Curves.easeOut.transform(
            const Interval(0.28, 0.82).transform(t),
          );
          final exitFade = Curves.easeIn.transform(
            const Interval(0.82, 1.0).transform(t),
          );

          return Opacity(
            opacity: 1.0 - exitFade,
            child: SizedBox.expand(
              child: CustomPaint(
                painter: _TunnelSplashPainter(
                  progress: t,
                  lightRise: lightRise,
                  fieldReveal: fieldReveal,
                  playerAdvance: playerAdvance,
                  haze: haze,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TunnelSplashPainter extends CustomPainter {
  final double progress;
  final double lightRise;
  final double fieldReveal;
  final double playerAdvance;
  final double haze;

  const _TunnelSplashPainter({
    required this.progress,
    required this.lightRise,
    required this.fieldReveal,
    required this.playerAdvance,
    required this.haze,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width / 2, size.height * 0.5);
    final gateWidth = size.width * 0.36;
    final gateHeight = size.height * 0.54;
    final gateRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.45),
      width: gateWidth,
      height: gateHeight,
    );

    _paintBackdrop(canvas, rect, gateRect);
    _paintTunnel(canvas, size, gateRect);
    _paintField(canvas, size, gateRect);
    _paintPlayer(canvas, size, gateRect);
    _paintAtmosphere(canvas, rect, gateRect, center);
  }

  void _paintBackdrop(Canvas canvas, Rect rect, Rect gateRect) {
    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(
            const Color(0xFF020304),
            const Color(0xFF173B2E),
            fieldReveal * 0.32,
          )!,
          Color.lerp(
            const Color(0xFF05080B),
            const Color(0xFF0E241F),
            lightRise * 0.24,
          )!,
          Color.lerp(
            const Color(0xFF070A0E),
            const Color(0xFF10251A),
            fieldReveal * 0.4,
          )!,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final beamPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.18),
        radius: 1.05,
        colors: [
          Colors.white.withValues(alpha: 0.08 + (lightRise * 0.42)),
          const Color(
            0xFFE8FFBE,
          ).withValues(alpha: 0.04 + (fieldReveal * 0.18)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.26, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, beamPaint);

    final floorShadow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.14),
          Colors.black.withValues(alpha: 0.42 - (fieldReveal * 0.18)),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, floorShadow);

    final lintelPaint = Paint()
      ..color = const Color(0xFF11161B).withValues(alpha: 0.9);
    canvas.drawRect(
      Rect.fromLTWH(
        gateRect.left - sizePadding(rect.width, 0.02),
        0,
        gateRect.width + sizePadding(rect.width, 0.04),
        gateRect.top,
      ),
      lintelPaint,
    );
  }

  void _paintTunnel(Canvas canvas, Size size, Rect gateRect) {
    final wallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF050608),
          const Color(0xFF11151A).withValues(alpha: 0.94),
          const Color(0xFF050608),
        ],
      ).createShader(Offset.zero & size);

    final leftWall = Path()
      ..moveTo(0, 0)
      ..lineTo(gateRect.left, gateRect.top)
      ..lineTo(gateRect.left, gateRect.bottom)
      ..lineTo(0, size.height)
      ..close();
    final rightWall = Path()
      ..moveTo(size.width, 0)
      ..lineTo(gateRect.right, gateRect.top)
      ..lineTo(gateRect.right, gateRect.bottom)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(leftWall, wallPaint);
    canvas.drawPath(rightWall, wallPaint);

    final tunnelFrame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(4, size.width * 0.012)
      ..color = const Color(0xFF171C20).withValues(alpha: 0.96);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        gateRect.inflate(size.width * 0.012),
        const Radius.circular(18),
      ),
      tunnelFrame,
    );

    final thresholdPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF101214).withValues(alpha: 0.0),
              const Color(0xFF080A0D).withValues(alpha: 0.82),
            ],
          ).createShader(
            Rect.fromLTWH(
              0,
              gateRect.bottom - size.height * 0.1,
              size.width,
              size.height * 0.2,
            ),
          );
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        gateRect.bottom - size.height * 0.1,
        size.width,
        size.height * 0.2,
      ),
      thresholdPaint,
    );
  }

  void _paintField(Canvas canvas, Size size, Rect gateRect) {
    final fieldRect = gateRect.deflate(gateRect.width * 0.04);
    final grassTop = lerpDouble(
      fieldRect.bottom - fieldRect.height * 0.16,
      fieldRect.top + fieldRect.height * 0.32,
      fieldReveal,
    )!;
    final grassRect = Rect.fromLTRB(
      fieldRect.left,
      grassTop,
      fieldRect.right,
      fieldRect.bottom,
    );

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(const Color(0xFFF8F4D6), Colors.white, lightRise * 0.8)!,
          Color.lerp(
            const Color(0xFFCFF3AD),
            const Color(0xFFE8FFCC),
            fieldReveal,
          )!,
          const Color(0xFF7FBF66),
        ],
      ).createShader(fieldRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(fieldRect, const Radius.circular(12)),
      skyPaint,
    );

    final grassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(
            const Color(0xFF5A993A),
            const Color(0xFF89D55B),
            fieldReveal,
          )!,
          Color.lerp(
            const Color(0xFF255A1D),
            const Color(0xFF397D26),
            fieldReveal,
          )!,
        ],
      ).createShader(grassRect);
    canvas.drawRect(grassRect, grassPaint);

    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16 + (fieldReveal * 0.2))
      ..strokeWidth = max(1.2, size.width * 0.003)
      ..style = PaintingStyle.stroke;
    final midY = lerpDouble(
      grassRect.center.dy + grassRect.height * 0.08,
      grassRect.top + grassRect.height * 0.38,
      fieldReveal,
    )!;
    canvas.drawLine(
      Offset(grassRect.left, midY),
      Offset(grassRect.right, midY),
      stripePaint,
    );
    canvas.drawCircle(
      Offset(grassRect.center.dx, midY),
      grassRect.width * 0.08,
      stripePaint,
    );

    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(0, lerpDouble(0.18, -0.42, lightRise)!),
        radius: 0.92,
        colors: [
          Colors.white.withValues(alpha: 0.38 + (lightRise * 0.3)),
          const Color(
            0xFFF9FFD7,
          ).withValues(alpha: 0.18 + (fieldReveal * 0.16)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.28, 1.0],
      ).createShader(fieldRect.inflate(size.width * 0.14));
    canvas.drawRect(fieldRect.inflate(size.width * 0.14), glowPaint);
  }

  void _paintPlayer(Canvas canvas, Size size, Rect gateRect) {
    final playerScale = lerpDouble(1.0, 0.72, playerAdvance)!;
    final playerY = lerpDouble(
      gateRect.bottom - gateRect.height * 0.12,
      gateRect.bottom - gateRect.height * 0.22,
      playerAdvance,
    )!;
    final playerX = gateRect.center.dx - gateRect.width * 0.04;
    final silhouette = const Color(
      0xFF020303,
    ).withValues(alpha: lerpDouble(0.88, 0.26, lightRise)!);
    final line = Paint()
      ..color = silhouette
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = max(2.0, size.width * 0.01) * playerScale;
    final fill = Paint()..color = silhouette;

    final headCenter = Offset(
      playerX,
      playerY - size.height * 0.12 * playerScale,
    );
    canvas.drawCircle(headCenter, size.width * 0.026 * playerScale, fill);

    final shoulder = Offset(
      playerX,
      playerY - size.height * 0.078 * playerScale,
    );
    final hip = Offset(playerX, playerY - size.height * 0.02 * playerScale);
    canvas.drawLine(shoulder, hip, line);
    canvas.drawLine(
      shoulder,
      Offset(
        playerX - size.width * 0.04 * playerScale,
        playerY - size.height * 0.038 * playerScale,
      ),
      line,
    );
    canvas.drawLine(
      shoulder,
      Offset(
        playerX + size.width * 0.045 * playerScale,
        playerY - size.height * 0.018 * playerScale,
      ),
      line,
    );
    canvas.drawLine(
      hip,
      Offset(
        playerX - size.width * 0.03 * playerScale,
        playerY + size.height * 0.07 * playerScale,
      ),
      line,
    );
    canvas.drawLine(
      hip,
      Offset(
        playerX + size.width * 0.05 * playerScale,
        playerY + size.height * 0.058 * playerScale,
      ),
      line,
    );

    final ballCenter = Offset(
      playerX + size.width * 0.075 * playerScale,
      playerY + size.height * 0.07 * playerScale,
    );
    canvas.drawCircle(ballCenter, size.width * 0.018 * playerScale, fill);
  }

  void _paintAtmosphere(
    Canvas canvas,
    Rect rect,
    Rect gateRect,
    Offset center,
  ) {
    final mist = Paint()
      ..shader = RadialGradient(
        center: Alignment(0, 0.22 - (progress * 0.38)),
        radius: 1.0,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: haze * 0.12),
          Colors.white.withValues(alpha: haze * 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.48, 0.72, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, mist);

    final dust = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = max(1.2, rect.width * 0.004);
    for (var i = 0; i < 9; i++) {
      final dx =
          gateRect.center.dx -
          gateRect.width * 0.22 +
          (i * gateRect.width * 0.055);
      final drift = sin((progress * pi * 2.0) + (i * 0.7)) * rect.height * 0.01;
      final dy =
          gateRect.top +
          gateRect.height * (0.18 + ((i % 4) * 0.09)) -
          (haze * rect.height * 0.05) +
          drift;
      dust.color = Colors.white.withValues(alpha: 0.05 + (haze * 0.12));
      canvas.drawPoints(PointMode.points, [Offset(dx, dy)], dust);
    }

    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.98,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.12),
          Colors.black.withValues(alpha: 0.42 - (fieldReveal * 0.18)),
        ],
        stops: const [0.48, 0.78, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);

    final flarePaint = Paint()
      ..shader =
          RadialGradient(
            radius: 0.36,
            colors: [
              Colors.white.withValues(alpha: 0.12 + (lightRise * 0.18)),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: rect.width * 0.28),
          );
    canvas.drawCircle(center, rect.width * 0.28, flarePaint);
  }

  double sizePadding(double value, double ratio) => value * ratio;

  @override
  bool shouldRepaint(covariant _TunnelSplashPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.lightRise != lightRise ||
        oldDelegate.fieldReveal != fieldReveal ||
        oldDelegate.playerAdvance != playerAdvance ||
        oldDelegate.haze != haze;
  }
}
