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
          final dawnToMorning = Curves.easeInOutCubic.transform(
            const Interval(0.0, 0.72).transform(t),
          );
          final sunRise = Curves.easeOutCubic.transform(
            const Interval(0.08, 0.84).transform(t),
          );
          final fieldReveal = Curves.easeOutCubic.transform(
            const Interval(0.12, 0.9).transform(t),
          );
          final hopeGlow = Curves.easeInOutCubic.transform(
            const Interval(0.2, 1.0).transform(t),
          );
          final titleFade = Curves.easeOut.transform(
            const Interval(0.22, 0.78).transform(t),
          );
          final fadeOut = Curves.easeIn.transform(
            const Interval(0.8, 1.0).transform(t),
          );

          return Opacity(
            opacity: 1 - fadeOut,
            child: CustomPaint(
              size: Size.infinite,
              painter: _HopeFieldSplashPainter(
                progress: t,
                dawnToMorning: dawnToMorning,
                sunRise: sunRise,
                fieldReveal: fieldReveal,
                hopeGlow: hopeGlow,
                titleFade: titleFade,
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
  final double dawnToMorning;
  final double sunRise;
  final double fieldReveal;
  final double hopeGlow;
  final double titleFade;

  const _HopeFieldSplashPainter({
    required this.progress,
    required this.dawnToMorning,
    required this.sunRise,
    required this.fieldReveal,
    required this.hopeGlow,
    required this.titleFade,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    _paintSky(canvas, rect);
    _paintSunAndGlow(canvas, rect);
    _paintCloudMist(canvas, rect);
    _paintField(canvas, size);
    _paintGoalSilhouette(canvas, size);
    _paintMessage(canvas, size);
    _paintVignette(canvas, rect);
  }

  void _paintSky(Canvas canvas, Rect rect) {
    final top = Color.lerp(
      const Color(0xFF0B1A2C),
      const Color(0xFF71C6FF),
      dawnToMorning,
    )!;
    final middle = Color.lerp(
      const Color(0xFF1B2A46),
      const Color(0xFFA9DCFF),
      dawnToMorning,
    )!;
    final bottom = Color.lerp(
      const Color(0xFF2A3A56),
      const Color(0xFFEAF7FF),
      dawnToMorning,
    )!;

    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, middle, bottom],
      ).createShader(rect);
    canvas.drawRect(rect, sky);

    final horizonWarmth = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(0, 0.18),
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFFFFF0C8).withValues(alpha: 0.12 + (hopeGlow * 0.25)),
          const Color(0xFFFFDFA0).withValues(alpha: 0.08 + (hopeGlow * 0.16)),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, horizonWarmth);
  }

  void _paintSunAndGlow(Canvas canvas, Rect rect) {
    final center = Offset(
      rect.center.dx,
      lerpDouble(rect.height * 0.88, rect.height * 0.2, sunRise)!,
    );
    final sunRadius =
        lerpDouble(rect.width * 0.08, rect.width * 0.13, sunRise)!;

    final auraRect = Rect.fromCircle(center: center, radius: sunRadius * 4.2);
    final aura = Paint()
      ..shader = RadialGradient(
        radius: 1.0,
        colors: [
          const Color(0xFFFFF5C6).withValues(alpha: 0.42 + (hopeGlow * 0.32)),
          const Color(0xFFFFE39A).withValues(alpha: 0.22 + (hopeGlow * 0.2)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.38, 1.0],
      ).createShader(auraRect)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18 + (hopeGlow * 12));
    canvas.drawCircle(center, sunRadius * 3.8, aura);

    final sunPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFFFBE2),
          Color(0xFFFFE8A8),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: sunRadius));
    canvas.drawCircle(center, sunRadius, sunPaint);
  }

  void _paintCloudMist(Canvas canvas, Rect rect) {
    final haze = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.04 + (dawnToMorning * 0.1)),
          Colors.white.withValues(alpha: 0.08 + (dawnToMorning * 0.15)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.34, 0.65, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, haze);

    final cloudY = lerpDouble(rect.height * 0.52, rect.height * 0.4, progress)!;
    final cloud = Paint()
      ..color = Colors.white.withValues(alpha: 0.06 + (dawnToMorning * 0.1))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rect.width * 0.34, cloudY),
        width: rect.width * 0.46,
        height: rect.height * 0.11,
      ),
      cloud,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rect.width * 0.72, cloudY * 1.02),
        width: rect.width * 0.42,
        height: rect.height * 0.1,
      ),
      cloud,
    );
  }

  void _paintField(Canvas canvas, Size size) {
    final horizonY = lerpDouble(
      size.height * 0.72,
      size.height * 0.62,
      fieldReveal,
    )!;
    final fieldRect = Rect.fromLTRB(0, horizonY, size.width, size.height);

    final field = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(
              const Color(0xFF1E6131), const Color(0xFF2F9447), fieldReveal)!,
          Color.lerp(
              const Color(0xFF174E29), const Color(0xFF1F6D35), fieldReveal)!,
        ],
      ).createShader(fieldRect);
    canvas.drawRect(fieldRect, field);

    const stripeCount = 9;
    final stripeHeight = fieldRect.height / stripeCount;
    for (var i = 0; i < stripeCount; i++) {
      if (i.isOdd) continue;
      final y = fieldRect.top + (i * stripeHeight);
      canvas.drawRect(
        Rect.fromLTWH(fieldRect.left, y, fieldRect.width, stripeHeight),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.03 + (fieldReveal * 0.05)),
      );
    }

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.58 + (fieldReveal * 0.24))
      ..strokeWidth = max(1.4, size.width * 0.006)
      ..style = PaintingStyle.stroke;

    final midY = fieldRect.top + (fieldRect.height * 0.42);
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), linePaint);
    canvas.drawCircle(
        Offset(size.width * 0.5, midY), size.width * 0.11, linePaint);
  }

  void _paintGoalSilhouette(Canvas canvas, Size size) {
    final y = lerpDouble(size.height * 0.7, size.height * 0.62, fieldReveal)!;
    final w = size.width * 0.28;
    final h = size.height * 0.12;
    final left = (size.width - w) / 2;

    final post = Paint()
      ..color = Colors.white.withValues(alpha: 0.24 + (fieldReveal * 0.4))
      ..strokeWidth = max(2.0, size.width * 0.006)
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(left, y, w, h), post);
  }

  void _paintMessage(Canvas canvas, Size size) {
    if (titleFade <= 0.001) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '오늘도 한 걸음 성장!',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.78 * titleFade),
          fontSize: max(22, size.width * 0.062),
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width * 0.9);

    final offset = Offset(
      (size.width - textPainter.width) / 2,
      lerpDouble(size.height * 0.18, size.height * 0.14, hopeGlow)!,
    );
    textPainter.paint(canvas, offset);
  }

  void _paintVignette(Canvas canvas, Rect rect) {
    final vignette = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.15),
        radius: 1.08,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.14),
          Colors.black.withValues(alpha: 0.34),
        ],
        stops: const [0.64, 0.88, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);
  }

  @override
  bool shouldRepaint(covariant _HopeFieldSplashPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.dawnToMorning != dawnToMorning ||
        oldDelegate.sunRise != sunRise ||
        oldDelegate.fieldReveal != fieldReveal ||
        oldDelegate.hopeGlow != hopeGlow ||
        oldDelegate.titleFade != titleFade;
  }
}
