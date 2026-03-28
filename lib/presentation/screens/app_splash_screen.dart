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
  static const _duration = Duration(milliseconds: 1850);
  static const _reducedMotionDelay = Duration(milliseconds: 420);

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
          final doorOpen = Curves.easeInOutCubic.transform(
            const Interval(0.08, 0.7).transform(t),
          );
          final gateZoom = Curves.easeOutQuart.transform(
            const Interval(0.0, 0.82).transform(t),
          );
          final lightBurst = Curves.easeOut.transform(
            const Interval(0.22, 0.9).transform(t),
          );
          final fieldReveal = Curves.easeOutCubic.transform(
            const Interval(0.18, 0.94).transform(t),
          );
          final fadeOut = Curves.easeIn.transform(
            const Interval(0.84, 1.0).transform(t),
          );

          return Opacity(
            opacity: 1 - fadeOut,
            child: CustomPaint(
              size: Size.infinite,
              painter: _GateSplashPainter(
                progress: t,
                doorOpen: doorOpen,
                gateZoom: gateZoom,
                lightBurst: lightBurst,
                fieldReveal: fieldReveal,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GateSplashPainter extends CustomPainter {
  final double progress;
  final double doorOpen;
  final double gateZoom;
  final double lightBurst;
  final double fieldReveal;

  const _GateSplashPainter({
    required this.progress,
    required this.doorOpen,
    required this.gateZoom,
    required this.lightBurst,
    required this.fieldReveal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    _paintBackdrop(canvas, rect);

    final gateCenter = Offset(size.width * 0.5, size.height * 0.48);
    final gateWidth =
        lerpDouble(size.width * 0.24, size.width * 2.05, gateZoom)!;
    final gateHeight =
        lerpDouble(size.height * 0.36, size.height * 1.7, gateZoom)!;

    final gateRect = Rect.fromCenter(
      center: gateCenter,
      width: gateWidth,
      height: gateHeight,
    );

    final frameStroke = max(4.0, size.shortestSide * 0.016);
    final openingWidth = gateRect.width * (0.16 + (doorOpen * 0.82));
    final openingRect = Rect.fromCenter(
      center: gateRect.center,
      width: openingWidth,
      height: gateRect.height * 0.92,
    );

    _paintFieldInside(canvas, size, openingRect);
    _paintLight(canvas, size, openingRect);
    _paintGateFrame(canvas, gateRect, frameStroke);
    _paintDoorPanels(canvas, gateRect, openingRect);
    _paintAtmosphere(canvas, rect, openingRect);
  }

  void _paintBackdrop(Canvas canvas, Rect rect) {
    final night = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF04070B),
          Color(0xFF081018),
          Color(0xFF03070C),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, night);

    final vignette = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.08),
        radius: 1.08,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.34),
          Colors.black.withValues(alpha: 0.72),
        ],
        stops: const [0.5, 0.84, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);
  }

  void _paintGateFrame(Canvas canvas, Rect gateRect, double frameStroke) {
    final frameRect = gateRect.inflate(frameStroke * 0.66);
    final frame = RRect.fromRectAndRadius(
      frameRect,
      Radius.circular(frameStroke * 2.3),
    );
    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = frameStroke
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1C252E).withValues(alpha: 0.95),
          const Color(0xFF0E141A).withValues(alpha: 0.96),
        ],
      ).createShader(frameRect);
    canvas.drawRRect(frame, framePaint);

    final innerGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = frameStroke * 0.52
      ..color = Colors.white.withValues(alpha: 0.06 + (lightBurst * 0.16));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        gateRect.deflate(frameStroke * 0.4),
        Radius.circular(frameStroke * 1.8),
      ),
      innerGlow,
    );
  }

  void _paintDoorPanels(Canvas canvas, Rect gateRect, Rect openingRect) {
    final leftDoor = Rect.fromLTRB(
      gateRect.left,
      gateRect.top,
      openingRect.left,
      gateRect.bottom,
    );
    final rightDoor = Rect.fromLTRB(
      openingRect.right,
      gateRect.top,
      gateRect.right,
      gateRect.bottom,
    );

    final panelPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F171E), Color(0xFF080E13)],
      ).createShader(gateRect);
    canvas.drawRect(leftDoor, panelPaint);
    canvas.drawRect(rightDoor, panelPaint);

    final edgeGlow = Paint()
      ..color = Colors.white.withValues(alpha: 0.06 + (lightBurst * 0.1))
      ..strokeWidth = max(1.2, gateRect.width * 0.0032)
      ..style = PaintingStyle.stroke;
    canvas.drawLine(leftDoor.topRight, leftDoor.bottomRight, edgeGlow);
    canvas.drawLine(rightDoor.topLeft, rightDoor.bottomLeft, edgeGlow);
  }

  void _paintFieldInside(Canvas canvas, Size size, Rect openingRect) {
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        openingRect,
        Radius.circular(max(6, openingRect.width * 0.03)),
      ),
    );

    final fieldBase = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(
              const Color(0xFF0D2315), const Color(0xFF1F6B35), fieldReveal)!,
          Color.lerp(
              const Color(0xFF0B1D11), const Color(0xFF2D8C41), fieldReveal)!,
        ],
      ).createShader(openingRect);
    canvas.drawRect(openingRect, fieldBase);

    const stripeCount = 7;
    final stripeHeight = openingRect.height / stripeCount;
    for (var i = 0; i < stripeCount; i++) {
      if (i.isOdd) continue;
      final y = openingRect.top + (i * stripeHeight);
      final stripeRect = Rect.fromLTWH(
        openingRect.left,
        y,
        openingRect.width,
        stripeHeight,
      );
      canvas.drawRect(
        stripeRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.03 + (fieldReveal * 0.05)),
      );
    }

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.54 + (fieldReveal * 0.36))
      ..strokeWidth = max(1.4, openingRect.width * 0.007)
      ..style = PaintingStyle.stroke;

    final centerY = openingRect.center.dy + (openingRect.height * 0.16);
    canvas.drawLine(
      Offset(openingRect.left, centerY),
      Offset(openingRect.right, centerY),
      linePaint,
    );
    canvas.drawCircle(
      Offset(openingRect.center.dx, centerY),
      openingRect.width * 0.14,
      linePaint,
    );

    canvas.restore();
  }

  void _paintLight(Canvas canvas, Size size, Rect openingRect) {
    final glowRect = Rect.fromCenter(
      center: Offset(
          openingRect.center.dx, openingRect.center.dy - size.height * 0.02),
      width: openingRect.width * 2.6,
      height: openingRect.height * 1.9,
    );

    final source = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.08),
        radius: 0.92,
        colors: [
          Colors.white.withValues(alpha: 0.16 + (lightBurst * 0.56)),
          const Color(0xFFF7FFC8).withValues(alpha: 0.1 + (lightBurst * 0.26)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(glowRect)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 24 + (lightBurst * 12));
    canvas.drawOval(glowRect, source);

    final beam = Path()
      ..moveTo(openingRect.left, openingRect.bottom)
      ..lineTo(openingRect.right, openingRect.bottom)
      ..lineTo(size.width * 0.82, size.height)
      ..lineTo(size.width * 0.18, size.height)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.14 + (lightBurst * 0.22)),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );
  }

  void _paintAtmosphere(Canvas canvas, Rect rect, Rect openingRect) {
    final dust = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          ((openingRect.center.dx / rect.width) * 2) - 1,
          ((openingRect.center.dy / rect.height) * 2) - 1,
        ),
        radius: 1.15,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.04 + (progress * 0.06)),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, dust);
  }

  @override
  bool shouldRepaint(covariant _GateSplashPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.doorOpen != doorOpen ||
        oldDelegate.gateZoom != gateZoom ||
        oldDelegate.lightBurst != lightBurst ||
        oldDelegate.fieldReveal != fieldReveal;
  }
}
