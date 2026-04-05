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
          final doorOpen = Curves.easeInOutCubic.transform(
            const Interval(0.0, 0.54).transform(t),
          );
          final gateZoom = Curves.easeInExpo.transform(
            const Interval(0.0, 0.66).transform(t),
          );
          final lightBurst = Curves.easeOutCubic.transform(
            const Interval(0.06, 0.78).transform(t),
          );
          final fieldReveal = Curves.easeOutCubic.transform(
            const Interval(0.08, 0.84).transform(t),
          );
          final fieldPan = Curves.easeInOutCubic.transform(
            const Interval(0.12, 0.9).transform(t),
          );
          final rush = Curves.easeInCubic.transform(
            const Interval(0.0, 0.68).transform(t),
          );
          final seamDrop = Curves.easeInOutCubic.transform(
            const Interval(0.52, 0.96).transform(t),
          );
          final centerGuideDrop = Curves.easeInOutCubic.transform(
            const Interval(0.62, 0.99).transform(t),
          );
          final fadeOut = Curves.easeIn.transform(
            const Interval(0.76, 1.0).transform(t),
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
                fieldPan: fieldPan,
                rush: rush,
                seamDrop: seamDrop,
                centerGuideDrop: centerGuideDrop,
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
  final double fieldPan;
  final double rush;
  final double seamDrop;
  final double centerGuideDrop;

  const _GateSplashPainter({
    required this.progress,
    required this.doorOpen,
    required this.gateZoom,
    required this.lightBurst,
    required this.fieldReveal,
    required this.fieldPan,
    required this.rush,
    required this.seamDrop,
    required this.centerGuideDrop,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    _paintBackdrop(canvas, rect);

    final gateCenter = Offset(
      size.width * 0.5,
      lerpDouble(size.height * 0.56, size.height * 0.46, rush)!,
    );
    final gateWidth = lerpDouble(
      size.width * 1.08,
      size.width * 2.55,
      gateZoom,
    )!;
    final gateHeight = lerpDouble(
      size.height * 1.22,
      size.height * 2.3,
      gateZoom,
    )!;

    final gateRect = Rect.fromCenter(
      center: gateCenter,
      width: gateWidth,
      height: gateHeight,
    );

    final frameStroke = max(4.0, size.shortestSide * 0.016);
    final openingWidth = lerpDouble(
      size.width * 0.008,
      gateRect.width * 0.9,
      doorOpen,
    )!;
    final openingRect = Rect.fromCenter(
      center: gateRect.center,
      width: openingWidth,
      height: gateRect.height * 0.92,
    );

    _paintFieldInside(canvas, size, openingRect);
    _paintLight(canvas, size, openingRect);
    _paintSpeedLines(canvas, size, openingRect);
    _paintCenterSplit(canvas, size, gateRect, openingRect);
    _paintGateFrame(canvas, gateRect, frameStroke);
    _paintDoorPanels(canvas, gateRect, openingRect);
    _paintAtmosphere(canvas, rect, openingRect);
  }

  void _paintBackdrop(Canvas canvas, Rect rect) {
    final night = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF04070B), Color(0xFF081018), Color(0xFF03070C)],
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

  void _paintCenterSplit(
    Canvas canvas,
    Size size,
    Rect gateRect,
    Rect openingRect,
  ) {
    final splitProgress = (openingRect.width / gateRect.width).clamp(0.0, 1.0);
    final seamVanish = Curves.easeInCubic.transform(
      const Interval(0.0, 0.24).transform(progress),
    );
    final seamAlpha = ((1.0 - splitProgress) * (1.0 - seamVanish)).clamp(
      0.0,
      1.0,
    );
    if (seamAlpha <= 0.001) return;

    final eraseFrontY = lerpDouble(gateRect.top, gateRect.bottom, seamVanish)!;
    final seamTopSweep = lerpDouble(
      gateRect.top - gateRect.height,
      gateRect.bottom + gateRect.height * 0.2,
      seamDrop,
    )!;
    final visibleTop = max(
      eraseFrontY.clamp(gateRect.top, gateRect.bottom),
      seamTopSweep,
    );
    final visibleHeight = gateRect.bottom - visibleTop;
    if (visibleHeight <= 0.0) return;

    final seamX = gateRect.center.dx;
    final seamRect = Rect.fromLTWH(
      seamX - (size.width * 0.012),
      visibleTop,
      size.width * 0.024,
      visibleHeight,
    );
    canvas.drawRect(
      seamRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.05 + (0.25 * seamAlpha)),
            Colors.white.withValues(alpha: 0.12 + (0.32 * seamAlpha)),
            Colors.white.withValues(alpha: 0.05 + (0.22 * seamAlpha)),
          ],
        ).createShader(seamRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _paintFieldInside(Canvas canvas, Size size, Rect openingRect) {
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        openingRect,
        Radius.circular(max(6, openingRect.width * 0.03)),
      ),
    );

    final fieldWorldHeight = openingRect.height * 1.9;
    final fieldTop = lerpDouble(
      openingRect.bottom - fieldWorldHeight + (openingRect.height * 0.18),
      openingRect.top - (openingRect.height * 0.1),
      fieldPan,
    )!;
    final fieldRect = Rect.fromLTWH(
      openingRect.left,
      fieldTop,
      openingRect.width,
      fieldWorldHeight,
    );

    final fieldBase = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(
            const Color(0xFF0D2315),
            const Color(0xFF1F6B35),
            fieldReveal,
          )!,
          Color.lerp(
            const Color(0xFF0B1D11),
            const Color(0xFF2D8C41),
            fieldReveal,
          )!,
        ],
      ).createShader(fieldRect);
    canvas.drawRect(fieldRect, fieldBase);

    const stripeCount = 11;
    final stripeHeight = fieldRect.height / stripeCount;
    for (var i = 0; i < stripeCount; i++) {
      if (i.isOdd) continue;
      final y = fieldRect.top + (i * stripeHeight);
      final stripeRect = Rect.fromLTWH(
        fieldRect.left,
        y,
        fieldRect.width,
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

    final goalLineY = lerpDouble(
      fieldRect.top + (fieldRect.height * 0.22),
      fieldRect.top + (fieldRect.height * 0.12),
      fieldPan,
    )!;
    _paintGoalMark(canvas, fieldRect, goalLineY, linePaint);

    final centerLineLeadY = lerpDouble(
      fieldRect.top + (fieldRect.height * 0.62),
      fieldRect.top + (fieldRect.height * 0.72),
      fieldPan,
    )!;
    final centerY = lerpDouble(
      centerLineLeadY,
      fieldRect.bottom - (fieldRect.height * 0.1),
      centerGuideDrop,
    )!;
    canvas.drawLine(
      Offset(fieldRect.left, centerY),
      Offset(fieldRect.right, centerY),
      linePaint,
    );

    final centerCircleRect = Rect.fromCenter(
      center: Offset(fieldRect.center.dx, centerY),
      width: fieldRect.width * 0.52,
      height: fieldRect.height * 0.28,
    );
    canvas.drawOval(centerCircleRect, linePaint);

    canvas.restore();
  }

  void _paintGoalMark(
    Canvas canvas,
    Rect fieldRect,
    double centerY,
    Paint linePaint,
  ) {
    final goalWidth = fieldRect.width * 0.22;
    final goalHeight = fieldRect.height * 0.12;
    final goalRect = Rect.fromCenter(
      center: Offset(fieldRect.center.dx, centerY - (goalHeight * 0.12)),
      width: goalWidth,
      height: goalHeight,
    );
    final postPath = Path()
      ..moveTo(goalRect.left, goalRect.bottom)
      ..lineTo(goalRect.left, goalRect.top)
      ..lineTo(goalRect.right, goalRect.top)
      ..lineTo(goalRect.right, goalRect.bottom);
    canvas.drawPath(postPath, linePaint);

    final netPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18 + (fieldReveal * 0.18))
      ..strokeWidth = linePaint.strokeWidth * 0.54
      ..style = PaintingStyle.stroke;
    final netInset = goalWidth * 0.14;
    for (var i = 1; i <= 2; i++) {
      final ratio = i / 3;
      final x = lerpDouble(
        goalRect.left + netInset,
        goalRect.right - netInset,
        ratio,
      )!;
      canvas.drawLine(
        Offset(x, goalRect.top + netInset * 0.4),
        Offset(x, goalRect.bottom),
        netPaint,
      );
    }
    for (var i = 1; i <= 2; i++) {
      final ratio = i / 3;
      final y = lerpDouble(
        goalRect.top + netInset * 0.5,
        goalRect.bottom,
        ratio,
      )!;
      canvas.drawLine(
        Offset(goalRect.left + netInset * 0.6, y),
        Offset(goalRect.right - netInset * 0.6, y),
        netPaint,
      );
    }
  }

  void _paintLight(Canvas canvas, Size size, Rect openingRect) {
    final glowRect = Rect.fromCenter(
      center: Offset(
        openingRect.center.dx,
        openingRect.center.dy - size.height * 0.02,
      ),
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

  void _paintSpeedLines(Canvas canvas, Size size, Rect openingRect) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, size.width * 0.0026)
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);

    for (var i = 0; i < 9; i++) {
      final ratio = (i + 1) / 10;
      final x = lerpDouble(
        openingRect.left - (size.width * 0.2),
        openingRect.right + (size.width * 0.2),
        ratio,
      )!;
      final y0 = openingRect.bottom - (size.height * 0.04 * ratio);
      final y1 = size.height + (size.height * 0.08 * ratio);
      linePaint.color = Colors.white.withValues(
        alpha: (0.02 + (rush * 0.2)) * (1 - ratio * 0.5),
      );
      canvas.drawLine(Offset(x, y0), Offset(x, y1), linePaint);
    }
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
        oldDelegate.fieldReveal != fieldReveal ||
        oldDelegate.fieldPan != fieldPan ||
        oldDelegate.rush != rush ||
        oldDelegate.seamDrop != seamDrop ||
        oldDelegate.centerGuideDrop != centerGuideDrop;
  }
}
