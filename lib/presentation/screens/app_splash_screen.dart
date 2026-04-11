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
          final t = reducedMotion ? 0.78 : _controller.value;
          final expand = Curves.easeInOutCubic.transform(
            const Interval(0.0, 0.72).transform(t),
          );
          final reveal = Curves.easeOutCubic.transform(
            const Interval(0.06, 0.78).transform(t),
          );
          final shimmer = Curves.easeInOutSine.transform(
            const Interval(0.0, 1.0).transform(t),
          );
          final cameraDrift = Curves.easeInOutCubic.transform(
            const Interval(0.12, 0.88).transform(t),
          );
          final fadeOut = reducedMotion
              ? 0.0
              : Curves.easeIn.transform(const Interval(0.82, 1.0).transform(t));
          return Opacity(
            opacity: 1 - fadeOut,
            child: CustomPaint(
              size: Size.infinite,
              painter: _GrassOnlySplashPainter(
                progress: t,
                expand: expand,
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
  final double expand;
  final double reveal;
  final double shimmer;
  final double cameraDrift;

  const _GrassOnlySplashPainter({
    required this.progress,
    required this.expand,
    required this.reveal,
    required this.shimmer,
    required this.cameraDrift,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final screenRect = Offset.zero & size;
    final fieldRect = _fieldRectFor(size);
    final fieldRadius = lerpDouble(
      min(fieldRect.height * 0.42, 40.0),
      0.0,
      Curves.easeOut.transform(expand),
    )!;
    final fieldClip = RRect.fromRectAndRadius(
      fieldRect,
      Radius.circular(fieldRadius),
    );

    _paintBackdrop(canvas, screenRect, fieldRect);
    _paintFieldShadow(canvas, fieldRect, fieldRadius);

    canvas.save();
    canvas.clipRRect(fieldClip);

    final zoom = lerpDouble(1.08, 1.0, cameraDrift)!;
    final shiftY = lerpDouble(
      fieldRect.height * 0.025,
      -fieldRect.height * 0.015,
      cameraDrift,
    )!;
    canvas.translate(fieldRect.center.dx, fieldRect.center.dy + shiftY);
    canvas.scale(zoom, zoom);
    canvas.translate(-fieldRect.center.dx, -fieldRect.center.dy);

    _paintBaseGrass(canvas, fieldRect);
    _paintStripeBands(canvas, fieldRect);
    _paintFieldGlow(canvas, fieldRect);
    _paintCenterMark(canvas, fieldRect);
    _paintGrassTexture(canvas, fieldRect);
    _paintDewHighlights(canvas, fieldRect);
    _paintFieldVignette(canvas, fieldRect);

    canvas.restore();

    _paintFieldEdge(canvas, fieldRect, fieldRadius);
    _paintScreenVignette(canvas, screenRect);
  }

  Rect _fieldRectFor(Size size) {
    final initialWidth = size.shortestSide * 0.54;
    final initialHeight = initialWidth * 0.62;
    final finalWidth = size.width * 1.18;
    final finalHeight = size.height * 1.18;
    final width = lerpDouble(initialWidth, finalWidth, expand)!;
    final height = lerpDouble(initialHeight, finalHeight, expand)!;
    final centerY = lerpDouble(
      size.height * 0.54,
      size.height * 0.52,
      cameraDrift,
    )!;

    return Rect.fromCenter(
      center: Offset(size.width * 0.5, centerY),
      width: width,
      height: height,
    );
  }

  void _paintBackdrop(Canvas canvas, Rect screenRect, Rect fieldRect) {
    canvas.drawRect(
      screenRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF020503),
            Color(0xFF06140B),
            Color(0xFF071009),
          ],
          stops: [0.0, 0.45, 1.0],
        ).createShader(screenRect),
    );

    final glowRect = Rect.fromCenter(
      center: Offset(
        screenRect.center.dx,
        fieldRect.center.dy - (fieldRect.height * 0.16),
      ),
      width: screenRect.width * 1.2,
      height: screenRect.height * 0.96,
    );
    canvas.drawRect(
      screenRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.08),
          radius: 1.0,
          colors: [
            const Color(0xFF204B1F).withValues(alpha: 0.24 + (reveal * 0.08)),
            const Color(0xFF0C2410).withValues(alpha: 0.14 + (reveal * 0.04)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(glowRect),
    );
  }

  void _paintFieldShadow(Canvas canvas, Rect fieldRect, double fieldRadius) {
    final shadowInflate = lerpDouble(26.0, 8.0, expand)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        fieldRect.inflate(shadowInflate),
        Radius.circular(fieldRadius + shadowInflate),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.26 - (expand * 0.08))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
  }

  void _paintBaseGrass(Canvas canvas, Rect rect) {
    final top = Color.lerp(
      const Color(0xFF174C1F),
      const Color(0xFF2C7A31),
      reveal,
    )!;
    final mid = Color.lerp(
      const Color(0xFF1F6A27),
      const Color(0xFF3E963B),
      reveal,
    )!;
    final bottom = Color.lerp(
      const Color(0xFF0E3615),
      const Color(0xFF1F5A25),
      reveal,
    )!;

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
    final glowRect = Rect.fromLTWH(
      rect.left,
      rect.top + (rect.height * 0.05),
      rect.width,
      rect.height * 0.7,
    );
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
    final midY = rect.top + (rect.height * 0.54);
    canvas.drawLine(
      Offset(rect.left, midY),
      Offset(rect.right, midY),
      linePaint,
    );
    canvas.drawCircle(
      Offset(rect.center.dx, midY),
      rect.width * 0.11,
      linePaint,
    );
  }

  void _paintGrassTexture(Canvas canvas, Rect rect) {
    final bladePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 260; i++) {
      final seed = i / 260;
      final x =
          rect.left + (rect.width * ((seed * 1.73 + (progress * 0.035)) % 1));
      final y = rect.top + (rect.height * ((seed * 2.31 + 0.08) % 1));
      final heightProgress = 1 - ((y - rect.top) / rect.height);
      final bladeLength = lerpDouble(7, 18, heightProgress)!;
      final lean = sin((seed * 30) + (progress * 6.2)) * 2.4;
      final alpha = (0.06 + (heightProgress * 0.16)).clamp(0.06, 0.2);
      bladePaint
        ..strokeWidth = lerpDouble(0.8, 1.5, heightProgress)!
        ..color = Color.lerp(
          const Color(0xFF7DD35B),
          const Color(0xFF184E1E),
          (y - rect.top) / rect.height,
        )!.withValues(alpha: alpha);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + lean, y - bladeLength),
        bladePaint,
      );
    }
  }

  void _paintDewHighlights(Canvas canvas, Rect rect) {
    final dewPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 48; i++) {
      final seed = i / 48;
      final x =
          rect.left + (rect.width * ((seed * 2.17 + (progress * 0.022)) % 1));
      final y = rect.top + (rect.height * (0.15 + ((seed * 1.91) % 0.72)));
      final radius = 0.8 + ((i % 4) * 0.28);
      final heightProgress = 1 - ((y - rect.top) / rect.height);
      dewPaint.color = Colors.white.withValues(
        alpha: (0.05 + (shimmer * 0.09)) * (1 - ((1 - heightProgress) * 0.55)),
      );
      canvas.drawCircle(Offset(x, y), radius, dewPaint);
    }
  }

  void _paintFieldVignette(Canvas canvas, Rect rect) {
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

  void _paintFieldEdge(Canvas canvas, Rect rect, double radius) {
    final strokeWidth = lerpDouble(1.6, 0.0, Curves.easeOut.transform(expand))!;
    if (strokeWidth <= 0) {
      return;
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(strokeWidth * 0.5),
        Radius.circular(max(0.0, radius - (strokeWidth * 0.5))),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.white.withValues(
          alpha: ((1 - expand) * 0.22) + (shimmer * 0.03),
        ),
    );
  }

  void _paintScreenVignette(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.06),
          radius: 1.08,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.18),
            Colors.black.withValues(alpha: 0.36),
          ],
          stops: const [0.58, 0.84, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _GrassOnlySplashPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.expand != expand ||
        oldDelegate.reveal != reveal ||
        oldDelegate.shimmer != shimmer ||
        oldDelegate.cameraDrift != cameraDrift;
  }
}
