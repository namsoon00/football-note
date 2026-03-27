import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
              final ballEntry = Curves.easeOutCubic.transform(
                const Interval(0.0, 0.46).transform(t),
              );
              final ringBurst = Curves.easeOutCubic.transform(
                const Interval(0.18, 0.68).transform(t),
              );
              final shardBurst = Curves.easeOut.transform(
                const Interval(0.14, 0.62).transform(t),
              );
              final flash = Curves.easeOut.transform(
                const Interval(0.22, 0.34).transform(t),
              );
              final exitFade = Curves.easeIn.transform(
                const Interval(0.72, 1.0).transform(t),
              );

              final opacity = 1.0 - exitFade;
              final ballScale = lerpDouble(0.28, 1.0, ballEntry)!;
              final ballRotation = lerpDouble(-0.9, 0.0, ballEntry)!;
              final ballLift = lerpDouble(56, 0, ballEntry)!;
              final ballGlow = lerpDouble(0.0, 1.0, ringBurst)!;

              return Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    final sphereSize = min(size.width * 0.56, 260.0);

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _SplashBackgroundPainter(
                              progress: t,
                              flash: flash,
                              ringBurst: ringBurst,
                            ),
                          ),
                        ),
                        Center(
                          child: Transform.translate(
                            offset: Offset(0, ballLift),
                            child: Transform.rotate(
                              angle: ballRotation,
                              child: Transform.scale(
                                scale: ballScale,
                                child: SizedBox(
                                  width: sphereSize,
                                  height: sphereSize,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      IgnorePointer(
                                        child: CustomPaint(
                                          size: Size.square(sphereSize),
                                          painter: _ImpactHaloPainter(
                                            glow: ballGlow,
                                            ringBurst: ringBurst,
                                            shardBurst: shardBurst,
                                          ),
                                        ),
                                      ),
                                      DecoratedBox(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF5EEAD4)
                                                  .withValues(
                                                    alpha:
                                                        0.18 +
                                                        (ballGlow * 0.16),
                                                  ),
                                              blurRadius: 48 + (ballGlow * 28),
                                              spreadRadius: 2 + (ballGlow * 6),
                                            ),
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.34,
                                              ),
                                              blurRadius: 36,
                                              offset: const Offset(0, 16),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: SvgPicture.asset(
                                            'assets/images/splash_ball.svg',
                                          ),
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
  final double ringBurst;

  const _SplashBackgroundPainter({
    required this.progress,
    required this.flash,
    required this.ringBurst,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = min(size.width, size.height) * 0.2;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF5EEAD4).withValues(alpha: 0.26 * ringBurst),
          const Color(0xFF22D3EE).withValues(alpha: 0.12 * ringBurst),
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
        ringBurst,
      )!;
      final start = center + Offset(cos(angle), sin(angle)) * startRadius;
      final end =
          center +
          Offset(cos(angle), sin(angle)) * endRadius +
          Offset(-sin(angle), cos(angle)) * (wave * 9);

      streakPaint
        ..strokeWidth = i.isEven ? 3.2 : 1.8
        ..color =
            (i % 3 == 0 ? const Color(0xFFF8FAFC) : const Color(0xFF67E8F9))
                .withValues(alpha: 0.08 + (ringBurst * 0.18));
      canvas.drawLine(start, end, streakPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.flash != flash ||
        oldDelegate.ringBurst != ringBurst;
  }
}

class _ImpactHaloPainter extends CustomPainter {
  final double glow;
  final double ringBurst;
  final double shardBurst;

  const _ImpactHaloPainter({
    required this.glow,
    required this.ringBurst,
    required this.shardBurst,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.31;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final radiusScale = 1.1 + (i * 0.18) + (ringBurst * (0.2 + (i * 0.08)));
      ringPaint
        ..strokeWidth = i == 0 ? 4 : 2.2
        ..color = (i == 0 ? const Color(0xFFF8FAFC) : const Color(0xFF5EEAD4))
            .withValues(alpha: (0.28 - (i * 0.06)) * glow);
      canvas.drawCircle(center, radius * radiusScale, ringPaint);
    }

    final shardPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const shardAngles = [-1.18, -0.62, -0.14, 0.4, 0.95, 1.54, 2.18, 2.82];
    for (var i = 0; i < shardAngles.length; i++) {
      final angle = shardAngles[i];
      final start =
          center +
          Offset(cos(angle), sin(angle)) *
              (radius * (1.1 + (i.isEven ? 0.04 : 0.0)));
      final end =
          center +
          Offset(cos(angle), sin(angle)) *
              (radius * (1.28 + (shardBurst * (0.48 + ((i % 3) * 0.08)))));
      shardPaint
        ..strokeWidth = i.isEven ? 3.6 : 2.0
        ..color = (i.isEven ? const Color(0xFFFDE68A) : const Color(0xFF7DD3FC))
            .withValues(alpha: 0.16 + (shardBurst * 0.34));
      canvas.drawLine(start, end, shardPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ImpactHaloPainter oldDelegate) {
    return oldDelegate.glow != glow ||
        oldDelegate.ringBurst != ringBurst ||
        oldDelegate.shardBurst != shardBurst;
  }
}
