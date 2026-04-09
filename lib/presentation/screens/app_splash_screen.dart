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
          final dawnMix = Curves.easeInOutCubic.transform(
            const Interval(0.0, 0.74).transform(t),
          );
          final sunRise = Curves.easeOutCubic.transform(
            const Interval(0.06, 0.84).transform(t),
          );
          final fieldReveal = Curves.easeOutCubic.transform(
            const Interval(0.12, 0.9).transform(t),
          );
          final glow = Curves.easeInOutCubic.transform(
            const Interval(0.18, 1.0).transform(t),
          );
          final cameraPush = Curves.easeInOutCubic.transform(
            const Interval(0.0, 0.86).transform(t),
          );
          final mistFlow = Curves.easeInOutSine.transform(
            const Interval(0.0, 1.0).transform(t),
          );
          final fadeOut = Curves.easeIn.transform(
            const Interval(0.82, 1.0).transform(t),
          );

          return Opacity(
            opacity: 1 - fadeOut,
            child: CustomPaint(
              size: Size.infinite,
              painter: _HopeFieldSplashPainter(
                progress: t,
                dawnMix: dawnMix,
                sunRise: sunRise,
                fieldReveal: fieldReveal,
                glow: glow,
                cameraPush: cameraPush,
                mistFlow: mistFlow,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HopeFieldSplashPainter extends CustomPainter {
  final double progress;
  final double dawnMix;
  final double sunRise;
  final double fieldReveal;
  final double glow;
  final double cameraPush;
  final double mistFlow;

  const _HopeFieldSplashPainter({
    required this.progress,
    required this.dawnMix,
    required this.sunRise,
    required this.fieldReveal,
    required this.glow,
    required this.cameraPush,
    required this.mistFlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    _paintSky(canvas, rect);
    _paintSunAndRays(canvas, rect);
    _paintCloudLayers(canvas, rect);

    canvas.save();
    final zoom = lerpDouble(1.0, 1.1, cameraPush)!;
    final shiftY = lerpDouble(0.0, -size.height * 0.03, cameraPush)!;
    canvas.translate(size.width * 0.5, size.height * 0.5 + shiftY);
    canvas.scale(zoom, zoom);
    canvas.translate(-size.width * 0.5, -size.height * 0.5);

    _paintField(canvas, size);
    _paintGoalAndDepth(canvas, size);
    _paintParticles(canvas, size);
    canvas.restore();

    _paintVignette(canvas, rect);
  }

  void _paintSky(Canvas canvas, Rect rect) {
    final top =
        Color.lerp(const Color(0xFF071428), const Color(0xFF74C8FF), dawnMix)!;
    final mid =
        Color.lerp(const Color(0xFF112743), const Color(0xFFB4E2FF), dawnMix)!;
    final bottom =
        Color.lerp(const Color(0xFF24384F), const Color(0xFFF4FBFF), dawnMix)!;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, mid, bottom],
        ).createShader(rect),
    );

    final warmthRect =
        Rect.fromLTWH(0, rect.height * 0.28, rect.width, rect.height * 0.72);
    canvas.drawRect(
      warmthRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFFFFE9B5).withValues(alpha: 0.12 + (glow * 0.24)),
            const Color(0xFFFFD892).withValues(alpha: 0.08 + (glow * 0.18)),
          ],
        ).createShader(warmthRect),
    );
  }

  void _paintSunAndRays(Canvas canvas, Rect rect) {
    final center = Offset(
      rect.center.dx,
      lerpDouble(rect.height * 0.92, rect.height * 0.2, sunRise)!,
    );
    final sunRadius =
        lerpDouble(rect.width * 0.07, rect.width * 0.12, sunRise)!;

    final haloRect = Rect.fromCircle(center: center, radius: sunRadius * 4.8);
    canvas.drawCircle(
      center,
      sunRadius * 4.5,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF6CC).withValues(alpha: 0.46 + (glow * 0.26)),
            const Color(0xFFFFE09E).withValues(alpha: 0.22 + (glow * 0.2)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(haloRect)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 24 + (glow * 10)),
    );

    for (var i = 0; i < 5; i++) {
      final spread = (i + 1) / 6;
      final rayW = lerpDouble(rect.width * 0.14, rect.width * 0.44, spread)!;
      final rayPath = Path()
        ..moveTo(center.dx - rayW, center.dy + sunRadius * 0.25)
        ..lineTo(center.dx + rayW, center.dy + sunRadius * 0.25)
        ..lineTo(rect.width * (0.75 + (spread * 0.06)), rect.height)
        ..lineTo(rect.width * (0.25 - (spread * 0.06)), rect.height)
        ..close();
      canvas.drawPath(
        rayPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(
                alpha: (0.03 + (glow * 0.05)) * (1 - spread * 0.22),
              ),
              Colors.transparent,
            ],
          ).createShader(rect),
      );
    }

    canvas.drawCircle(
      center,
      sunRadius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFFCEA), Color(0xFFFFE7AA)],
        ).createShader(Rect.fromCircle(center: center, radius: sunRadius)),
    );
  }

  void _paintCloudLayers(Canvas canvas, Rect rect) {
    final nearY = lerpDouble(rect.height * 0.48, rect.height * 0.4, mistFlow)!;
    final farY =
        lerpDouble(rect.height * 0.38, rect.height * 0.34, 1 - mistFlow)!;

    final farCloud = Paint()
      ..color = Colors.white.withValues(alpha: 0.07 + (dawnMix * 0.07))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    final nearCloud = Paint()
      ..color = Colors.white.withValues(alpha: 0.09 + (dawnMix * 0.1))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rect.width * (0.28 + (mistFlow * 0.03)), farY),
        width: rect.width * 0.52,
        height: rect.height * 0.12,
      ),
      farCloud,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rect.width * (0.78 - (mistFlow * 0.03)), farY * 1.02),
        width: rect.width * 0.44,
        height: rect.height * 0.11,
      ),
      farCloud,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rect.width * (0.36 - (mistFlow * 0.025)), nearY),
        width: rect.width * 0.5,
        height: rect.height * 0.12,
      ),
      nearCloud,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rect.width * (0.74 + (mistFlow * 0.02)), nearY * 1.03),
        width: rect.width * 0.42,
        height: rect.height * 0.1,
      ),
      nearCloud,
    );
  }

  void _paintField(Canvas canvas, Size size) {
    final horizonY =
        lerpDouble(size.height * 0.74, size.height * 0.6, fieldReveal)!;
    final fieldRect = Rect.fromLTRB(0, horizonY, size.width, size.height);

    canvas.drawRect(
      fieldRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(
              const Color(0xFF1F6633),
              const Color(0xFF38A44D),
              fieldReveal,
            )!,
            Color.lerp(
              const Color(0xFF144B26),
              const Color(0xFF216D37),
              fieldReveal,
            )!,
          ],
        ).createShader(fieldRect),
    );

    const stripeCount = 10;
    final stripeHeight = fieldRect.height / stripeCount;
    for (var i = 0; i < stripeCount; i++) {
      if (i.isOdd) continue;
      final y = fieldRect.top + (stripeHeight * i);
      canvas.drawRect(
        Rect.fromLTWH(fieldRect.left, y, fieldRect.width, stripeHeight),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.03 + (fieldReveal * 0.05)),
      );
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, size.width * 0.006)
      ..color = Colors.white.withValues(alpha: 0.58 + (fieldReveal * 0.24));
    final midY = fieldRect.top + (fieldRect.height * 0.42);
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), linePaint);
    canvas.drawCircle(
      Offset(size.width * 0.5, midY),
      size.width * 0.11,
      linePaint,
    );

    final depthShadow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.1),
          Colors.black.withValues(alpha: 0.2),
        ],
      ).createShader(fieldRect);
    canvas.drawRect(fieldRect, depthShadow);
  }

  void _paintGoalAndDepth(Canvas canvas, Size size) {
    final y = lerpDouble(size.height * 0.72, size.height * 0.61, fieldReveal)!;
    final w = size.width * 0.3;
    final h = size.height * 0.12;
    final left = (size.width - w) / 2;

    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.0, size.width * 0.006)
      ..color = Colors.white.withValues(alpha: 0.34 + (fieldReveal * 0.42));
    canvas.drawRect(Rect.fromLTWH(left, y, w, h), frame);

    final net = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, size.width * 0.0025)
      ..color = Colors.white.withValues(alpha: 0.12 + (fieldReveal * 0.12));
    for (var i = 1; i < 5; i++) {
      final xx = left + (w * i / 5);
      canvas.drawLine(Offset(xx, y), Offset(xx, y + h), net);
    }
    for (var i = 1; i < 4; i++) {
      final yy = y + (h * i / 4);
      canvas.drawLine(Offset(left, yy), Offset(left + w, yy), net);
    }
  }

  void _paintParticles(Canvas canvas, Size size) {
    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 18; i++) {
      final seed = i / 18;
      final x = size.width * (0.14 + (0.72 * ((seed + (progress * 0.12)) % 1)));
      final y =
          size.height * (0.26 + (0.5 * ((seed * 1.7 + (progress * 0.22)) % 1)));
      final radius = 0.9 + ((i % 3) * 0.55);
      final alpha = (0.05 + (glow * 0.12)) * (1 - ((seed - 0.5).abs() * 0.8));
      particlePaint.color =
          Colors.white.withValues(alpha: alpha.clamp(0.02, 0.18));
      canvas.drawCircle(Offset(x, y), radius, particlePaint);
    }
  }

  void _paintVignette(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 1.08,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.14),
            Colors.black.withValues(alpha: 0.34),
          ],
          stops: const [0.62, 0.88, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _HopeFieldSplashPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.dawnMix != dawnMix ||
        oldDelegate.sunRise != sunRise ||
        oldDelegate.fieldReveal != fieldReveal ||
        oldDelegate.glow != glow ||
        oldDelegate.cameraPush != cameraPush ||
        oldDelegate.mistFlow != mistFlow;
  }
}
