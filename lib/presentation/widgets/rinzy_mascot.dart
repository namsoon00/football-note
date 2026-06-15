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

class ChallengeRinzyMascot extends StatelessWidget {
  static const String assetPath = 'assets/images/challenge_rinzy_ready.png';

  final double size;
  final double progress;
  final bool animate;
  final bool useImage;

  const ChallengeRinzyMascot({
    super.key,
    this.size = 112,
    this.progress = 0,
    this.animate = true,
    this.useImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ChallengeRinzyCharacter(
      size: size,
      progress: progress,
      animate: animate,
      pose: _ChallengeRinzyPose.ready,
      useImage: useImage,
    );
  }
}

class ChallengeCheerRinzyMascot extends StatelessWidget {
  static const String assetPath = 'assets/images/challenge_rinzy_cheer.png';

  final double size;
  final double progress;
  final bool animate;
  final bool useImage;

  const ChallengeCheerRinzyMascot({
    super.key,
    this.size = 112,
    this.progress = 1,
    this.animate = true,
    this.useImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ChallengeRinzyCharacter(
      size: size,
      progress: progress,
      animate: animate,
      pose: _ChallengeRinzyPose.cheer,
      useImage: useImage,
    );
  }
}

class ChallengeSadRinzyMascot extends StatelessWidget {
  static const String assetPath = 'assets/images/challenge_rinzy_sad.png';

  final double size;
  final double progress;
  final bool animate;
  final bool useImage;

  const ChallengeSadRinzyMascot({
    super.key,
    this.size = 112,
    this.progress = 0,
    this.animate = true,
    this.useImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ChallengeRinzyCharacter(
      size: size,
      progress: progress,
      animate: animate,
      pose: _ChallengeRinzyPose.sad,
      useImage: useImage,
    );
  }
}

enum _ChallengeRinzyPose { ready, cheer, sad }

class _ChallengeRinzyCharacter extends StatefulWidget {
  final double size;
  final double progress;
  final bool animate;
  final _ChallengeRinzyPose pose;
  final bool useImage;

  const _ChallengeRinzyCharacter({
    required this.size,
    required this.progress,
    required this.animate,
    required this.pose,
    required this.useImage,
  });

  @override
  State<_ChallengeRinzyCharacter> createState() =>
      _ChallengeRinzyCharacterState();
}

class _ChallengeRinzyCharacterState extends State<_ChallengeRinzyCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.pose == _ChallengeRinzyPose.cheer ? 900 : 1500,
      ),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_ChallengeRinzyCharacter oldWidget) {
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

  String get _assetPath {
    return switch (widget.pose) {
      _ChallengeRinzyPose.ready => ChallengeRinzyMascot.assetPath,
      _ChallengeRinzyPose.cheer => ChallengeCheerRinzyMascot.assetPath,
      _ChallengeRinzyPose.sad => ChallengeSadRinzyMascot.assetPath,
    };
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
              final progress = widget.progress.clamp(0, 1).toDouble();
              final motion = _challengeRinzyMotion(
                widget.pose,
                phase,
                progress,
                widget.size,
              );

              return Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  if (!widget.useImage)
                    Positioned(
                      bottom: widget.size * 0.02,
                      child: Transform.scale(
                        scaleX: motion.shadowScale,
                        child: Container(
                          width: widget.size * 0.42,
                          height: widget.size * 0.06,
                          decoration: BoxDecoration(
                            color: const Color(0x24152033),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x17152033),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.all(widget.size * 0.01),
                      child: Transform.translate(
                        offset: Offset(motion.dx, motion.dy),
                        child: Transform.rotate(
                          angle: motion.rotation,
                          child: Transform.scale(
                            scale: motion.scale,
                            child: widget.useImage
                                ? Image.asset(
                                    _assetPath,
                                    key: ValueKey(
                                      'challenge-rinzy-${widget.pose.name}-image',
                                    ),
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    gaplessPlayback: true,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _PaintedChallengeRinzyPose(
                                        pose: widget.pose,
                                        progress: progress,
                                        phase: phase,
                                      );
                                    },
                                  )
                                : _PaintedChallengeRinzyPose(
                                    pose: widget.pose,
                                    progress: progress,
                                    phase: phase,
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

class _PaintedChallengeRinzyPose extends StatelessWidget {
  final _ChallengeRinzyPose pose;
  final double progress;
  final double phase;

  const _PaintedChallengeRinzyPose({
    required this.pose,
    required this.progress,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      key: ValueKey('challenge-rinzy-${pose.name}'),
      painter: _RinzyChibiPainter(
        progress: progress,
        phase: phase,
        cheer: pose == _ChallengeRinzyPose.cheer,
        sad: pose == _ChallengeRinzyPose.sad,
        challenge: true,
      ),
    );
  }
}

_ChallengeRinzyMotion _challengeRinzyMotion(
  _ChallengeRinzyPose pose,
  double phase,
  double progress,
  double size,
) {
  final wave = math.sin(phase * math.pi * 2);
  switch (pose) {
    case _ChallengeRinzyPose.ready:
      final stride = math.sin(phase * math.pi * 4);
      final hop = math.max(0.0, math.sin((phase + 0.08) * math.pi * 4));
      return _ChallengeRinzyMotion(
        dx: stride * size * 0.014,
        dy: -hop * size * 0.036,
        rotation: wave * (0.025 + progress * 0.01),
        scale: 1 + hop * 0.016 + progress * 0.008,
        shadowScale: 1 - hop * 0.10,
      );
    case _ChallengeRinzyPose.cheer:
      final hop = math.max(0.0, math.sin(phase * math.pi * 4));
      return _ChallengeRinzyMotion(
        dx: wave * size * 0.012,
        dy: -hop * size * 0.07,
        rotation: wave * 0.045,
        scale: 1 + hop * 0.026,
        shadowScale: 1 - hop * 0.16,
      );
    case _ChallengeRinzyPose.sad:
      final sigh = math.sin((phase + 0.15) * math.pi * 2);
      return _ChallengeRinzyMotion(
        dx: math.sin(phase * math.pi * 6) * size * 0.003,
        dy: -((sigh + 1) * 0.5) * size * 0.012,
        rotation: sigh * 0.012,
        scale: 1,
        shadowScale: 0.96,
      );
  }
}

class _ChallengeRinzyMotion {
  final double dx;
  final double dy;
  final double rotation;
  final double scale;
  final double shadowScale;

  const _ChallengeRinzyMotion({
    required this.dx,
    required this.dy,
    required this.rotation,
    required this.scale,
    required this.shadowScale,
  });
}

class _RinzyChibiPainter extends CustomPainter {
  final double progress;
  final double phase;
  final bool cheer;
  final bool sad;
  final bool crying;
  final bool challenge;

  const _RinzyChibiPainter({
    required this.progress,
    required this.phase,
    this.cheer = false,
    this.sad = false,
    this.crying = false,
    this.challenge = false,
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
      ..color = const Color(0xFF5E3E1E)
      ..strokeWidth = unit * 0.014
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final bodyColor = challenge
        ? const Color(0xFFF8C94B)
        : const Color(0xFFFBD35F);
    final bodyPaint = Paint()..color = bodyColor;
    final facePaint = Paint()
      ..color = challenge ? const Color(0xFFFFDC85) : const Color(0xFFFFD978);
    final snoutPaint = Paint()..color = const Color(0xFFFFE8B5);
    final spotPaint = Paint()
      ..color = const Color(0xFF8E5521).withValues(alpha: 0.84);
    final blushPaint = Paint()
      ..color = (sad ? const Color(0xFF8FB9FF) : const Color(0xFFFF8FB3))
          .withValues(alpha: 0.34 + progress * 0.14);
    final eyePaint = Paint()..color = const Color(0xFF33251B);
    final eyeHighlightPaint = Paint()..color = Colors.white;
    final scarfPaint = Paint()
      ..color = challenge ? const Color(0xFF38BDF8) : const Color(0xFF40B8A8);
    final armPaint = Paint()
      ..color = Color.lerp(bodyColor, const Color(0xFFE1A13A), 0.34)!
      ..strokeWidth = unit * 0.032
      ..strokeCap = StrokeCap.round;

    final bodyRect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.715),
      width: unit * 0.36,
      height: unit * 0.25,
    );
    final neckRect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.515),
      width: unit * 0.19,
      height: unit * 0.38,
    );
    final headRect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.255),
      width: unit * 0.58,
      height: unit * 0.40,
    );

    _drawTail(canvas, size, unit, outlinePaint);
    _drawLegs(canvas, size, unit, outlinePaint, armPaint);
    _drawArms(canvas, size, unit, armPaint, outlinePaint, cheerWave: cheerWave);

    final neck = RRect.fromRectAndRadius(
      neckRect,
      Radius.circular(unit * 0.08),
    );
    canvas.drawRRect(neck, bodyPaint);
    _drawMane(canvas, size, unit);
    _drawNeckSpots(canvas, size, unit, spotPaint);
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
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.56, size.height * 0.59),
          width: unit * 0.16,
          height: unit * 0.055,
        ),
        Radius.circular(unit * 0.045),
      ),
      Paint()
        ..color = (challenge ? const Color(0xFF2563EB) : scarfPaint.color)
            .withValues(alpha: 0.86),
    );

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
    if (!sad) {
      _drawSoccerBall(
        canvas,
        center: Offset(size.width * 0.73, size.height * 0.78),
        radius: unit * (challenge ? 0.070 : 0.058),
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
      center: Offset(size.width * 0.245, size.height * 0.18),
      width: unit * 0.18,
      height: unit * 0.22,
    );
    final rightEar = Rect.fromCenter(
      center: Offset(size.width * 0.755, size.height * 0.18),
      width: unit * 0.18,
      height: unit * 0.22,
    );
    canvas.drawOval(leftEar, facePaint);
    canvas.drawOval(rightEar, facePaint);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.25, size.height * 0.19),
        width: unit * 0.09,
        height: unit * 0.13,
      ),
      Paint()..color = const Color(0xFFFFC4A0).withValues(alpha: 0.48),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.75, size.height * 0.19),
        width: unit * 0.09,
        height: unit * 0.13,
      ),
      Paint()..color = const Color(0xFFFFC4A0).withValues(alpha: 0.48),
    );
    canvas.drawOval(leftEar, outlinePaint);
    canvas.drawOval(rightEar, outlinePaint);

    _drawHorn(canvas, Offset(size.width * 0.405, size.height * 0.095), unit);
    _drawHorn(canvas, Offset(size.width * 0.595, size.height * 0.095), unit);

    final head = RRect.fromRectAndRadius(
      headRect,
      Radius.circular(unit * 0.24),
    );
    canvas.drawRRect(head, facePaint);
    canvas.drawRRect(head, outlinePaint);
    canvas.drawCircle(
      Offset(size.width * 0.33, size.height * 0.205),
      unit * 0.044,
      spotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.175),
      unit * 0.036,
      spotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.70, size.height * 0.305),
      unit * 0.030,
      spotPaint,
    );

    final snout = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.355),
      width: unit * 0.34,
      height: unit * 0.19,
    );
    canvas.drawOval(snout, snoutPaint);
    canvas.drawOval(snout, outlinePaint);

    _drawEye(
      canvas,
      Offset(size.width * 0.40, size.height * 0.275),
      unit,
      eyePaint,
      eyeHighlightPaint,
    );
    _drawEye(
      canvas,
      Offset(size.width * 0.60, size.height * 0.275),
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
      ..color = const Color(0xFF6F431C)
      ..strokeWidth = unit * 0.022
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, Offset(base.dx, base.dy - unit * 0.095), paint);
    canvas.drawCircle(
      Offset(base.dx, base.dy - unit * 0.110),
      unit * 0.034,
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
      Offset(size.width * 0.40, size.height * 0.685),
      unit * 0.038,
      spotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.59, size.height * 0.735),
      unit * 0.042,
      spotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.625),
      unit * 0.026,
      spotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.48, size.height * 0.765),
      unit * 0.020,
      spotPaint,
    );
  }

  void _drawNeckSpots(Canvas canvas, Size size, double unit, Paint spotPaint) {
    canvas.drawCircle(
      Offset(size.width * 0.455, size.height * 0.405),
      unit * 0.026,
      spotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.555, size.height * 0.500),
      unit * 0.030,
      spotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.465, size.height * 0.580),
      unit * 0.022,
      spotPaint,
    );
  }

  void _drawMane(Canvas canvas, Size size, double unit) {
    final manePaint = Paint()
      ..color = const Color(0xFF6F431C).withValues(alpha: 0.88);
    final path = Path()
      ..moveTo(size.width * 0.595, size.height * 0.330)
      ..lineTo(size.width * 0.655, size.height * 0.380)
      ..lineTo(size.width * 0.595, size.height * 0.430)
      ..lineTo(size.width * 0.655, size.height * 0.480)
      ..lineTo(size.width * 0.595, size.height * 0.530)
      ..lineTo(size.width * 0.650, size.height * 0.585)
      ..lineTo(size.width * 0.575, size.height * 0.615)
      ..close();
    canvas.drawPath(path, manePaint);
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
      final end = Offset(size.width * dx, size.height * 0.88);
      canvas.drawLine(start, end, legPaint);
      canvas.drawLine(start, end, outlinePaint);
      canvas.drawCircle(
        Offset(start.dx, start.dy + unit * 0.030),
        unit * 0.018,
        Paint()..color = const Color(0xFF8E5521).withValues(alpha: 0.68),
      );
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
      final handPaint = Paint()..color = const Color(0xFFF7C95E);
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

  void _drawSoccerBall(
    Canvas canvas, {
    required Offset center,
    required double radius,
  }) {
    final outline = Paint()
      ..color = const Color(0xFF263241)
      ..strokeWidth = radius * 0.12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(
      center.translate(radius * 0.10, radius * 0.16),
      radius,
      Paint()..color = const Color(0x2A111827),
    );
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius, outline);

    final patch = Path();
    for (var index = 0; index < 5; index += 1) {
      final angle = -math.pi / 2 + index * math.pi * 2 / 5;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.36;
      if (index == 0) {
        patch.moveTo(point.dx, point.dy);
      } else {
        patch.lineTo(point.dx, point.dy);
      }
    }
    patch.close();
    canvas.drawPath(patch, Paint()..color = const Color(0xFF263241));

    for (var index = 0; index < 5; index += 1) {
      final angle = -math.pi / 2 + index * math.pi * 2 / 5;
      final start =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.38;
      final end =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.82;
      canvas.drawLine(start, end, outline);
    }
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
        oldDelegate.crying != crying ||
        oldDelegate.challenge != challenge;
  }
}
