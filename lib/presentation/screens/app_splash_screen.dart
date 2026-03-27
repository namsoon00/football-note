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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF04070D), Color(0xFF071B2A), Color(0xFF081018)],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = reduceMotion ? 1.0 : _controller.value;
              final coreEntry = Curves.easeOutCubic.transform(
                const Interval(0.0, 0.46).transform(t),
              );
              final waveBurst = Curves.easeOutCubic.transform(
                const Interval(0.18, 0.68).transform(t),
              );
              final arcSweep = Curves.easeOutCubic.transform(
                const Interval(0.14, 0.62).transform(t),
              );
              final ribbonFlow = Curves.easeInOutCubic.transform(
                const Interval(0.08, 0.82).transform(t),
              );
              final flash = Curves.easeOut.transform(
                const Interval(0.22, 0.34).transform(t),
              );
              final exitFade = Curves.easeIn.transform(
                const Interval(0.72, 1.0).transform(t),
              );

              final opacity = 1.0 - exitFade;
              final coreScale = lerpDouble(0.48, 1.0, coreEntry)!;
              final coreRotation = lerpDouble(-0.42, 0.18, ribbonFlow)!;
              final coreLift = lerpDouble(44, 0, coreEntry)!;
              final energyGlow = lerpDouble(0.0, 1.0, waveBurst)!;

              return Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    final artworkSize = min(size.width * 0.62, 296.0);

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _SplashBackgroundPainter(
                              progress: t,
                              flash: flash,
                              waveBurst: waveBurst,
                              ribbonFlow: ribbonFlow,
                            ),
                          ),
                        ),
                        Center(
                          child: Transform.translate(
                            offset: Offset(0, coreLift),
                            child: Transform.rotate(
                              angle: coreRotation,
                              child: Transform.scale(
                                scale: coreScale,
                                child: SizedBox(
                                  width: artworkSize,
                                  height: artworkSize,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      IgnorePointer(
                                        child: CustomPaint(
                                          size: Size.square(artworkSize),
                                          painter: _PulseFieldPainter(
                                            glow: energyGlow,
                                            waveBurst: waveBurst,
                                            arcSweep: arcSweep,
                                            ribbonFlow: ribbonFlow,
                                          ),
                                        ),
                                      ),
                                      CustomPaint(
                                        size: Size.square(artworkSize),
                                        painter: _EnergyCorePainter(
                                          glow: energyGlow,
                                          waveBurst: waveBurst,
                                          arcSweep: arcSweep,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  final double progress;
  final double flash;
  final double waveBurst;
  final double ribbonFlow;

  const _SplashBackgroundPainter({
    required this.progress,
    required this.flash,
    required this.waveBurst,
    required this.ribbonFlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = min(size.width, size.height) * 0.2;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF5EEAD4).withValues(alpha: 0.24 * waveBurst),
          const Color(0xFF22D3EE).withValues(alpha: 0.12 * waveBurst),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 3.4));
    canvas.drawCircle(center, baseRadius * 3.4, glowPaint);

    final flashPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.36 * flash),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 2.2));
    canvas.drawCircle(center, baseRadius * 2.2, flashPaint);

    final streakPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const streakCount = 10;
    for (var i = 0; i < streakCount; i++) {
      final angle = (-pi * 0.82) + ((pi * 1.64) / (streakCount - 1)) * i;
      final wave = sin((progress * pi * 2.2) + (i * 0.65));
      final startRadius = baseRadius * (1.35 + (i.isEven ? 0.08 : 0.18));
      final endRadius = lerpDouble(
        startRadius + 54,
        startRadius + 124,
        waveBurst,
      )!;
      final start = center + Offset(cos(angle), sin(angle)) * startRadius;
      final end = center +
          Offset(cos(angle), sin(angle)) * endRadius +
          Offset(-sin(angle), cos(angle)) * (wave * 9);

      streakPaint
        ..strokeWidth = i.isEven ? 3.2 : 1.8
        ..color =
            (i % 3 == 0 ? const Color(0xFFF8FAFC) : const Color(0xFF67E8F9))
                .withValues(alpha: 0.08 + (waveBurst * 0.18));
      canvas.drawLine(start, end, streakPaint);
    }

    final ribbonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final radius = baseRadius * (1.95 + (i * 0.42));
      final horizontalDrift = lerpDouble(
        -size.width * 0.18,
        size.width * 0.18,
        ribbonFlow,
      )!;
      final path = Path();
      for (var step = 0; step <= 48; step++) {
        final x = (step / 48) * size.width;
        final normalizedX = (x / size.width) - 0.5;
        final y = center.dy +
            (sin(
                  (normalizedX * pi * (1.4 + (i * 0.32))) +
                      (progress * pi * (1.1 + (i * 0.22))),
                ) *
                radius *
                (0.18 + (i * 0.04))) +
            (horizontalDrift * (0.16 - (i * 0.04)));
        if (step == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      ribbonPaint
        ..strokeWidth = 1.4 + (i * 0.8)
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            (i == 1 ? const Color(0xFFFDE68A) : const Color(0xFF67E8F9))
                .withValues(alpha: 0.0 + (waveBurst * 0.22)),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size);
      canvas.drawPath(path, ribbonPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.flash != flash ||
        oldDelegate.waveBurst != waveBurst ||
        oldDelegate.ribbonFlow != ribbonFlow;
  }
}

class _PulseFieldPainter extends CustomPainter {
  final double glow;
  final double waveBurst;
  final double arcSweep;
  final double ribbonFlow;

  const _PulseFieldPainter({
    required this.glow,
    required this.waveBurst,
    required this.arcSweep,
    required this.ribbonFlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.28;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final radiusScale = 1.0 + (i * 0.24) + (waveBurst * (0.18 + (i * 0.08)));
      ringPaint
        ..strokeWidth = i == 0 ? 3.8 : 2.0
        ..color = (i == 0 ? const Color(0xFFF8FAFC) : const Color(0xFF5EEAD4))
            .withValues(alpha: (0.28 - (i * 0.06)) * glow);
      canvas.drawCircle(center, radius * radiusScale, ringPaint);
    }

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final arcRect = Rect.fromCircle(
        center: center,
        radius: radius * (1.08 + (i * 0.18) + (waveBurst * 0.08)),
      );
      final startAngle =
          (-pi / 2) + (i * 0.72) + (ribbonFlow * (0.48 + (i * 0.08)));
      final sweepAngle = (pi * (0.34 + (i * 0.08))) * arcSweep;
      arcPaint
        ..strokeWidth = i.isEven ? 4.0 : 2.4
        ..color = (i.isEven ? const Color(0xFF7DD3FC) : const Color(0xFFFDE68A))
            .withValues(alpha: 0.16 + (arcSweep * 0.24));
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulseFieldPainter oldDelegate) {
    return oldDelegate.glow != glow ||
        oldDelegate.waveBurst != waveBurst ||
        oldDelegate.arcSweep != arcSweep ||
        oldDelegate.ribbonFlow != ribbonFlow;
  }
}

class _EnergyCorePainter extends CustomPainter {
  final double glow;
  final double waveBurst;
  final double arcSweep;

  const _EnergyCorePainter({
    required this.glow,
    required this.waveBurst,
    required this.arcSweep,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.2;

    final shadowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28)
      ..color = const Color(0xFF5EEAD4).withValues(alpha: 0.22 + (glow * 0.18));
    canvas.drawCircle(center, radius * 1.36, shadowPaint);

    final coreRect = Rect.fromCircle(center: center, radius: radius);
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF8FAFC).withValues(alpha: 0.98),
          const Color(0xFFBAE6FD).withValues(alpha: 0.94),
          const Color(0xFF22D3EE).withValues(alpha: 0.78 + (waveBurst * 0.12)),
          const Color(0xFF0F172A).withValues(alpha: 0.88),
        ],
        stops: const [0.0, 0.18, 0.56, 1.0],
      ).createShader(coreRect);
    canvas.drawCircle(center, radius, corePaint);

    final shardPaint = Paint()..style = PaintingStyle.fill;
    const angles = [-1.9, -1.1, -0.35, 0.42, 1.18, 1.94, 2.72];
    for (var i = 0; i < angles.length; i++) {
      final angle = angles[i];
      final shardCenter = center +
          Offset(cos(angle), sin(angle)) * (radius * (0.82 + ((i % 3) * 0.08)));
      final tangent = Offset(-sin(angle), cos(angle));
      final normal = Offset(cos(angle), sin(angle));
      final length = radius * (0.26 + ((i % 2) * 0.08) + (arcSweep * 0.08));
      final width = radius * (0.08 + ((i % 3) * 0.015));
      final path = Path()
        ..moveTo(
          shardCenter.dx + (normal.dx * length),
          shardCenter.dy + (normal.dy * length),
        )
        ..lineTo(
          shardCenter.dx + (tangent.dx * width),
          shardCenter.dy + (tangent.dy * width),
        )
        ..lineTo(
          shardCenter.dx - (normal.dx * length * 0.48),
          shardCenter.dy - (normal.dy * length * 0.48),
        )
        ..lineTo(
          shardCenter.dx - (tangent.dx * width),
          shardCenter.dy - (tangent.dy * width),
        )
        ..close();
      shardPaint.color =
          (i.isEven ? const Color(0xFFF8FAFC) : const Color(0xFFFDE68A))
              .withValues(alpha: 0.42 + (waveBurst * 0.18));
      canvas.drawPath(path, shardPaint);
    }

    final cutPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFF8FAFC).withValues(alpha: 0.46 + (glow * 0.18)),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCenter(
          center: center,
          width: radius * 2.2,
          height: radius * 1.6,
        ),
      );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.7),
      -1.1,
      1.9,
      false,
      cutPaint..strokeWidth = 2.2,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.48),
      2.2,
      1.4,
      false,
      cutPaint..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant _EnergyCorePainter oldDelegate) {
    return oldDelegate.glow != glow ||
        oldDelegate.waveBurst != waveBurst ||
        oldDelegate.arcSweep != arcSweep;
  }
}
