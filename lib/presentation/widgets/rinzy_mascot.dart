import 'dart:math' as math;

import 'package:flutter/material.dart';

class RinzyMascot extends StatefulWidget {
  static const String assetPath = 'assets/images/rinzy_mascot.png';

  final double size;
  final double progress;
  final bool animate;
  final bool cute;

  const RinzyMascot({
    super.key,
    this.size = 112,
    this.progress = 0,
    this.animate = true,
    this.cute = true,
  });

  @override
  State<RinzyMascot> createState() => _RinzyMascotState();
}

class _RinzyMascotState extends State<RinzyMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(RinzyMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Rinzy',
      image: true,
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = widget.progress.clamp(0, 1).toDouble();
              final t = widget.animate ? _controller.value : 0.0;
              final wave = math.sin(t * math.pi * 2);
              final stride = math.sin(t * math.pi * 4);
              final hop = math.max(0.0, math.sin((t + 0.08) * math.pi * 4));
              final tilt = wave * (0.035 + progress * 0.014);
              final scale = 1 + hop * 0.022 + progress * 0.014;
              final lift = hop * widget.size * 0.045;
              final runX = stride * widget.size * 0.026;

              return Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    bottom: widget.size * 0.03,
                    child: Transform.scale(
                      scaleX: 1 - hop * 0.12,
                      child: Container(
                        width: widget.size * 0.54,
                        height: widget.size * 0.08,
                        decoration: BoxDecoration(
                          color: const Color(0x33152033),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F152033),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: widget.size * 0.04,
                        left: widget.size * 0.02,
                        right: widget.size * 0.02,
                      ),
                      child: Transform.translate(
                        offset: Offset(runX, -lift),
                        child: Transform.rotate(
                          angle: tilt,
                          child: Transform.scale(
                            scale: scale,
                            child: widget.cute
                                ? CustomPaint(
                                    painter: _RinzyChibiPainter(
                                      progress: progress,
                                      phase: t,
                                    ),
                                  )
                                : Image.asset(
                                    RinzyMascot.assetPath,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.sports_soccer,
                                        size: widget.size * 0.58,
                                      );
                                    },
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
        ),
      ),
    );
  }
}

class CheerRinzyMascot extends StatefulWidget {
  final double size;
  final double progress;
  final bool animate;

  const CheerRinzyMascot({
    super.key,
    this.size = 112,
    this.progress = 1,
    this.animate = true,
  });

  @override
  State<CheerRinzyMascot> createState() => _CheerRinzyMascotState();
}

class _CheerRinzyMascotState extends State<CheerRinzyMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(CheerRinzyMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cheering Rinzy',
      image: true,
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final phase = widget.animate ? _controller.value : 0.0;
              return CustomPaint(
                painter: _RinzyChibiPainter(
                  progress: widget.progress,
                  phase: phase,
                  cheer: true,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class SadRinzyMascot extends StatelessWidget {
  final double size;
  final double progress;

  const SadRinzyMascot({super.key, this.size = 112, this.progress = 0});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sad Rinzy',
      image: true,
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _RinzyChibiPainter(
              progress: progress,
              phase: 0,
              sad: true,
            ),
          ),
        ),
      ),
    );
  }
}

class CryingRinzyMascot extends StatefulWidget {
  final double size;
  final bool animate;

  const CryingRinzyMascot({super.key, this.size = 112, this.animate = true});

  @override
  State<CryingRinzyMascot> createState() => _CryingRinzyMascotState();
}

class _CryingRinzyMascotState extends State<CryingRinzyMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(CryingRinzyMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final phase = widget.animate ? _controller.value : 0.0;
              final shiver =
                  math.sin(phase * math.pi * 8) * widget.size * 0.006;
              return Transform.translate(
                offset: Offset(shiver, 0),
                child: CustomPaint(
                  painter: _RinzyChibiPainter(
                    progress: 0,
                    phase: phase,
                    sad: true,
                    crying: true,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RinzyChibiPainter extends CustomPainter {
  final double progress;
  final double phase;
  final bool cheer;
  final bool sad;
  final bool crying;

  const _RinzyChibiPainter({
    required this.progress,
    required this.phase,
    this.cheer = false,
    this.sad = false,
    this.crying = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    if (unit <= 0) return;

    final cheerWave = math.sin(phase * math.pi * 2);
    final cheerPulse = cheer ? 1 + math.max(0.0, cheerWave) * 0.035 : 1.0;
    canvas.save();
    canvas.scale(cheerPulse, cheerPulse);
    canvas.translate(
      size.width * (1 - cheerPulse) / (2 * cheerPulse),
      size.height * (1 - cheerPulse) / (2 * cheerPulse),
    );

    if (cheer) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.50, size.height * 0.90),
          width: unit * 0.58,
          height: unit * 0.09,
        ),
        Paint()..color = const Color(0x22152033),
      );
    }

    final outlinePaint = Paint()
      ..color = const Color(0xFF7F552A)
      ..strokeWidth = unit * 0.016
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final bodyPaint = Paint()..color = const Color(0xFFF3B64A);
    final facePaint = Paint()..color = const Color(0xFFFFCF6E);
    final snoutPaint = Paint()..color = const Color(0xFFFFE1A3);
    final spotPaint = Paint()
      ..color = const Color(0xFFB8792E).withValues(alpha: 0.76);
    final blushPaint = Paint()
      ..color = (sad ? const Color(0xFF8FB9FF) : const Color(0xFFFF8FB3))
          .withValues(alpha: 0.34 + progress * 0.14);
    final eyePaint = Paint()..color = const Color(0xFF33251B);
    final eyeHighlightPaint = Paint()..color = Colors.white;
    final scarfPaint = Paint()..color = const Color(0xFF40B8A8);
    final armPaint = Paint()
      ..color = const Color(0xFFE7A53E)
      ..strokeWidth = unit * 0.032
      ..strokeCap = StrokeCap.round;

    final bodyRect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.66),
      width: unit * 0.32,
      height: unit * 0.28,
    );
    final neckRect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.51),
      width: unit * 0.16,
      height: unit * 0.25,
    );
    final headRect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.31),
      width: unit * 0.61,
      height: unit * 0.46,
    );

    _drawTail(canvas, size, unit, outlinePaint);
    _drawLegs(canvas, size, unit, outlinePaint, armPaint);
    _drawArms(canvas, size, unit, armPaint, outlinePaint, cheerWave: cheerWave);

    final neck = RRect.fromRectAndRadius(
      neckRect,
      Radius.circular(unit * 0.08),
    );
    canvas.drawRRect(neck, bodyPaint);
    canvas.drawRRect(neck, outlinePaint);

    final body = RRect.fromRectAndRadius(
      bodyRect,
      Radius.circular(unit * 0.16),
    );
    canvas.drawRRect(body, bodyPaint);
    canvas.drawRRect(body, outlinePaint);
    _drawBodySpots(canvas, size, unit, spotPaint);

    final scarf = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.54),
        width: unit * 0.24,
        height: unit * 0.07,
      ),
      Radius.circular(unit * 0.05),
    );
    canvas.drawRRect(scarf, scarfPaint);

    _drawHeadDetails(
      canvas,
      size,
      unit,
      headRect,
      facePaint,
      snoutPaint,
      spotPaint,
      outlinePaint,
      eyePaint,
      eyeHighlightPaint,
      blushPaint,
    );

    if (cheer) {
      final leftPom = Offset(
        size.width * 0.22,
        size.height * (0.39 + cheerWave * 0.035),
      );
      final rightPom = Offset(
        size.width * 0.78,
        size.height * (0.39 - cheerWave * 0.035),
      );
      _drawPomPom(canvas, leftPom, unit * 0.13, phase + 0.10);
      _drawPomPom(canvas, rightPom, unit * 0.13, phase + 0.60);
      _drawSparkle(
        canvas,
        center: Offset(size.width * 0.50, size.height * 0.10),
        radius: unit * 0.032,
        alpha: 0.55 + math.max(0.0, cheerWave) * 0.24,
      );
    } else {
      _drawSparkle(
        canvas,
        center: Offset(size.width * 0.72, size.height * 0.18),
        radius: unit * 0.026,
        alpha: 0.42 + progress * 0.18,
      );
    }
    canvas.restore();
  }

  void _drawHeadDetails(
    Canvas canvas,
    Size size,
    double unit,
    Rect headRect,
    Paint facePaint,
    Paint snoutPaint,
    Paint spotPaint,
    Paint outlinePaint,
    Paint eyePaint,
    Paint eyeHighlightPaint,
    Paint blushPaint,
  ) {
    final leftEar = Rect.fromCenter(
      center: Offset(size.width * 0.28, size.height * 0.22),
      width: unit * 0.16,
      height: unit * 0.19,
    );
    final rightEar = Rect.fromCenter(
      center: Offset(size.width * 0.72, size.height * 0.22),
      width: unit * 0.16,
      height: unit * 0.19,
    );
    canvas.drawOval(leftEar, facePaint);
    canvas.drawOval(rightEar, facePaint);
    canvas.drawOval(leftEar, outlinePaint);
    canvas.drawOval(rightEar, outlinePaint);

    _drawHorn(canvas, Offset(size.width * 0.42, size.height * 0.12), unit);
    _drawHorn(canvas, Offset(size.width * 0.58, size.height * 0.12), unit);

    final head = RRect.fromRectAndRadius(
      headRect,
      Radius.circular(unit * 0.24),
    );
    canvas.drawRRect(head, facePaint);
    canvas.drawRRect(head, outlinePaint);
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.24),
      unit * 0.038,
      spotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.64, size.height * 0.20),
      unit * 0.030,
      spotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.71, size.height * 0.34),
      unit * 0.026,
      spotPaint,
    );

    final snout = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.39),
      width: unit * 0.31,
      height: unit * 0.17,
    );
    canvas.drawOval(snout, snoutPaint);
    canvas.drawOval(snout, outlinePaint);

    _drawEye(
      canvas,
      Offset(size.width * 0.41, size.height * 0.31),
      unit,
      eyePaint,
      eyeHighlightPaint,
    );
    _drawEye(
      canvas,
      Offset(size.width * 0.59, size.height * 0.31),
      unit,
      eyePaint,
      eyeHighlightPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.38, size.height * 0.41),
        width: unit * 0.08,
        height: unit * 0.04,
      ),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.62, size.height * 0.41),
        width: unit * 0.08,
        height: unit * 0.04,
      ),
      blushPaint,
    );

    final smilePaint = Paint()
      ..color = const Color(0xFF6D4825)
      ..strokeWidth = unit * 0.010
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.395),
        width: unit * 0.10,
        height: unit * 0.08,
      ),
      sad ? math.pi + 0.25 : 0.15,
      sad ? math.pi - 0.50 : math.pi - 0.30,
      false,
      smilePaint,
    );
    if (sad) {
      final tearPaint = Paint()
        ..color = const Color(0xFF62B5FF).withValues(alpha: 0.82)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.39, size.height * 0.36),
          width: unit * 0.028,
          height: unit * 0.060,
        ),
        tearPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.61, size.height * 0.36),
          width: unit * 0.028,
          height: unit * 0.060,
        ),
        tearPaint,
      );
      if (crying) {
        _drawCryingTears(canvas, size, unit, tearPaint);
      }
    }
  }

  void _drawCryingTears(
    Canvas canvas,
    Size size,
    double unit,
    Paint tearPaint,
  ) {
    final streamPaint = Paint()
      ..color = const Color(0xFF62B5FF).withValues(alpha: 0.58)
      ..strokeWidth = unit * 0.018
      ..strokeCap = StrokeCap.round;
    for (final dx in <double>[0.39, 0.61]) {
      final start = Offset(size.width * dx, size.height * 0.36);
      final end = Offset(size.width * dx, size.height * 0.48);
      canvas.drawLine(start, end, streamPaint);
      for (var index = 0; index < 3; index++) {
        final fall = (phase + index * 0.31 + (dx < 0.5 ? 0.08 : 0.0)) % 1.0;
        final dropletCenter = Offset(
          size.width * dx +
              math.sin((phase + index) * math.pi * 2) * unit * 0.01,
          size.height * (0.40 + fall * 0.30),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: dropletCenter,
            width: unit * (0.024 + fall * 0.010),
            height: unit * (0.052 + fall * 0.016),
          ),
          tearPaint
            ..color = const Color(
              0xFF62B5FF,
            ).withValues(alpha: 0.82 * (1 - fall * 0.55)),
        );
      }
    }
    final puddlePaint = Paint()
      ..color = const Color(0xFF62B5FF).withValues(
        alpha: 0.18 + math.max(0.0, math.sin(phase * math.pi * 2)) * 0.08,
      );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.91),
        width: unit * 0.32,
        height: unit * 0.045,
      ),
      puddlePaint,
    );
  }

  void _drawHorn(Canvas canvas, Offset base, double unit) {
    final paint = Paint()
      ..color = const Color(0xFF8C5D28)
      ..strokeWidth = unit * 0.018
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, Offset(base.dx, base.dy - unit * 0.065), paint);
    canvas.drawCircle(
      Offset(base.dx, base.dy - unit * 0.078),
      unit * 0.024,
      paint,
    );
  }

  void _drawEye(
    Canvas canvas,
    Offset center,
    double unit,
    Paint eyePaint,
    Paint highlightPaint,
  ) {
    canvas.drawCircle(center, unit * 0.035, eyePaint);
    canvas.drawCircle(
      Offset(center.dx - unit * 0.010, center.dy - unit * 0.012),
      unit * 0.010,
      highlightPaint,
    );
  }

  void _drawBodySpots(Canvas canvas, Size size, double unit, Paint spotPaint) {
    canvas.drawCircle(
      Offset(size.width * 0.43, size.height * 0.64),
      unit * 0.030,
      spotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.57, size.height * 0.70),
      unit * 0.034,
      spotPaint,
    );
  }

  void _drawTail(Canvas canvas, Size size, double unit, Paint outlinePaint) {
    final tailPaint = Paint()
      ..color = const Color(0xFFE7A53E)
      ..strokeWidth = unit * 0.022
      ..strokeCap = StrokeCap.round;
    final start = Offset(size.width * 0.36, size.height * 0.62);
    final end = Offset(size.width * 0.24, size.height * 0.57);
    canvas.drawLine(start, end, tailPaint);
    canvas.drawLine(start, end, outlinePaint);
    canvas.drawCircle(
      end,
      unit * 0.026,
      Paint()..color = const Color(0xFF7F552A),
    );
  }

  void _drawLegs(
    Canvas canvas,
    Size size,
    double unit,
    Paint outlinePaint,
    Paint legPaint,
  ) {
    for (final dx in <double>[0.44, 0.56]) {
      final start = Offset(size.width * dx, size.height * 0.78);
      final end = Offset(size.width * dx, size.height * 0.87);
      canvas.drawLine(start, end, legPaint);
      canvas.drawLine(start, end, outlinePaint);
      canvas.drawLine(
        end,
        Offset(end.dx + (dx < 0.5 ? -unit * 0.035 : unit * 0.035), end.dy),
        outlinePaint,
      );
    }
  }

  void _drawArms(
    Canvas canvas,
    Size size,
    double unit,
    Paint armPaint,
    Paint outlinePaint, {
    required double cheerWave,
  }) {
    final leftShoulder = Offset(size.width * 0.39, size.height * 0.61);
    final rightShoulder = Offset(size.width * 0.61, size.height * 0.61);
    final leftHand = cheer
        ? Offset(size.width * 0.25, size.height * (0.43 + cheerWave * 0.035))
        : Offset(size.width * 0.31, size.height * 0.72);
    final rightHand = cheer
        ? Offset(size.width * 0.75, size.height * (0.43 - cheerWave * 0.035))
        : Offset(size.width * 0.69, size.height * 0.72);
    canvas.drawLine(leftShoulder, leftHand, outlinePaint);
    canvas.drawLine(rightShoulder, rightHand, outlinePaint);
    canvas.drawLine(leftShoulder, leftHand, armPaint);
    canvas.drawLine(rightShoulder, rightHand, armPaint);
    if (!cheer) {
      final handPaint = Paint()..color = const Color(0xFFF3B64A);
      canvas.drawCircle(leftHand, unit * 0.024, handPaint);
      canvas.drawCircle(rightHand, unit * 0.024, handPaint);
    }
  }

  void _drawPomPom(Canvas canvas, Offset center, double radius, double spin) {
    final colors = <Color>[
      const Color(0xFFFFD85C),
      const Color(0xFFFF7AAE),
      const Color(0xFF66D9FF),
      Colors.white,
    ];
    for (var i = 0; i < 18; i++) {
      final angle = spin * math.pi * 2 + i * math.pi * 2 / 18;
      final color = colors[i % colors.length];
      final paint = Paint()
        ..color = color.withValues(alpha: 0.86)
        ..strokeWidth = radius * 0.12
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center,
        Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        ),
        paint,
      );
    }
    canvas.drawCircle(center, radius * 0.24, Paint()..color = Colors.white);
  }

  void _drawSparkle(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double alpha,
  }) {
    final paint = Paint()
      ..color = const Color(0xFFFFD66B).withValues(alpha: alpha)
      ..strokeWidth = radius * 0.26
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RinzyChibiPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.cheer != cheer ||
        oldDelegate.sad != sad ||
        oldDelegate.crying != crying;
  }
}
