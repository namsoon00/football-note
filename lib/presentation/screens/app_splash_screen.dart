import 'dart:ui';
import 'dart:async';
import 'dart:math';

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
  late final AnimationController _controller;
  Timer? _completionTimer;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..addStatusListener((status) {
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
      _completionTimer = Timer(const Duration(milliseconds: 420), _complete);
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
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF041421), Color(0xFF0A2A45), Color(0xFF0E7A5F)],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final animationValue =
                  AppMotion.reduceMotion(context) ? 1.0 : _controller.value;
              final ballTravel = Curves.easeInOutCubic.transform(
                const Interval(0.08, 0.7).transform(animationValue),
              );
              final scaleProgress = Curves.easeInCubic.transform(
                const Interval(0.28, 1).transform(animationValue),
              );
              final ballScale = lerpDouble(0.28, 5.6, scaleProgress)!;
              final glowOpacity =
                  Tween<double>(begin: 0.18, end: 0.95).transform(
                Curves.easeOut.transform(
                  const Interval(0.3, 0.92).transform(animationValue),
                ),
              );
              final streakOpacity =
                  Tween<double>(begin: 0.0, end: 1.0).transform(
                Curves.easeOut.transform(
                  const Interval(0.02, 0.45).transform(animationValue),
                ),
              );
              final titleOpacity =
                  Tween<double>(begin: 0.0, end: 1.0).transform(
                Curves.easeOut.transform(
                  const Interval(0.18, 0.5).transform(animationValue),
                ),
              );

              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: -80,
                    left: -20,
                    child: _EnergyGlow(
                      size: 260,
                      color: const Color(
                        0xFF38BDF8,
                      ).withValues(alpha: glowOpacity * 0.45),
                    ),
                  ),
                  Positioned(
                    right: -40,
                    bottom: -60,
                    child: _EnergyGlow(
                      size: 300,
                      color: const Color(
                        0xFFFDE68A,
                      ).withValues(alpha: glowOpacity * 0.52),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SpeedLinesPainter(opacity: streakOpacity),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Opacity(
                          opacity: titleOpacity,
                          child: Text(
                            isKo ? '강하게 시작' : 'Kick Off Strong',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Opacity(
                          opacity: titleOpacity,
                          child: Text(
                            isKo
                                ? '축구공이 화면을 가르며 오늘 훈련의 리듬을 올립니다.'
                                : 'A fast strike sets the rhythm for today\'s training.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 280,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final path = _bananaKickPoint(
                                width,
                                280,
                                ballTravel,
                              );
                              final x = path.dx;
                              final y = path.dy;
                              final rotation = lerpDouble(
                                    -0.7,
                                    3.1,
                                    Curves.easeInOutCubicEmphasized.transform(
                                      scaleProgress,
                                    ),
                                  )! +
                                  (sin(ballTravel * pi * 1.2) * 0.18);
                              final trailWidth = lerpDouble(
                                width * 0.22,
                                width * 0.48,
                                scaleProgress,
                              )!;
                              final trailHeight = lerpDouble(
                                12,
                                34,
                                scaleProgress,
                              )!;
                              final trailAngle =
                                  -0.22 - (ballTravel * 0.42);

                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    left: x - (trailWidth * 0.94),
                                    top: y + (trailHeight * 0.16),
                                    child: Transform.rotate(
                                      angle: trailAngle,
                                      child: Opacity(
                                        opacity:
                                            (0.12 + (streakOpacity * 0.26))
                                                .clamp(0.0, 1.0),
                                        child: Container(
                                          width: trailWidth,
                                          height: trailHeight,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            gradient: const LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [
                                                Color(0x001CF2FF),
                                                Color(0xAA7DD3FC),
                                                Color(0xCCFEF08A),
                                                Color(0x001CF2FF),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: x - 70,
                                    top: y,
                                    child: Transform.rotate(
                                      angle: rotation,
                                      child: Transform.scale(
                                        scale: ballScale,
                                        child: SvgPicture.asset(
                                          'assets/images/icon_ball.svg',
                                          width: 84,
                                          height: 84,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Offset _bananaKickPoint(double width, double height, double t) {
    final start = Offset(-width * 0.30, height * 0.76);
    final controlA = Offset(width * 0.16, height * 0.10);
    final controlB = Offset(width * 0.58, height * 0.18);
    final end = Offset(width * 0.64, height * 0.04);
    final curvedT = Curves.easeInOutCubic.transform(t);
    final oneMinusT = 1 - curvedT;

    final point =
        (start * pow(oneMinusT, 3).toDouble()) +
        (controlA * (3 * pow(oneMinusT, 2) * curvedT).toDouble()) +
        (controlB * (3 * oneMinusT * pow(curvedT, 2)).toDouble()) +
        (end * pow(curvedT, 3).toDouble());
    final dip = sin(curvedT * pi) * height * 0.05;
    final returnLift = Curves.easeOut.transform((curvedT - 0.58).clamp(0, 1)) *
        height *
        0.09;
    return Offset(point.dx, point.dy + dip - returnLift);
  }
}

class _EnergyGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _EnergyGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: color.a * 0.24),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeedLinesPainter extends CustomPainter {
  final double opacity;

  const _SpeedLinesPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final lines = <({
      double startX,
      double startY,
      double endX,
      double endY,
      double width,
      Color color,
    })>[
      (
        startX: size.width * 0.05,
        startY: size.height * 0.28,
        endX: size.width * 0.58,
        endY: size.height * 0.18,
        width: 5,
        color: const Color(0xFF7DD3FC),
      ),
      (
        startX: size.width * 0.02,
        startY: size.height * 0.44,
        endX: size.width * 0.62,
        endY: size.height * 0.32,
        width: 8,
        color: const Color(0xFFFDE68A),
      ),
      (
        startX: size.width * 0.18,
        startY: size.height * 0.68,
        endX: size.width * 0.78,
        endY: size.height * 0.52,
        width: 6,
        color: const Color(0xFF86EFAC),
      ),
      (
        startX: size.width * 0.32,
        startY: size.height * 0.84,
        endX: size.width * 0.9,
        endY: size.height * 0.72,
        width: 4,
        color: const Color(0xFF38BDF8),
      ),
    ];

    for (final line in lines) {
      paint
        ..strokeWidth = line.width
        ..color = line.color.withValues(alpha: opacity * 0.78);
      canvas.drawLine(
        Offset(line.startX, line.startY),
        Offset(line.endX, line.endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedLinesPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}
