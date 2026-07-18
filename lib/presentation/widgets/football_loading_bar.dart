import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FootballLoadingBar extends StatefulWidget {
  final double width;

  const FootballLoadingBar({
    super.key,
    this.width = 252,
  });

  @override
  State<FootballLoadingBar> createState() => _FootballLoadingBarState();
}

class _FootballLoadingBarState extends State<FootballLoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final ballShadow = brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.34)
        : Colors.black.withValues(alpha: 0.14);

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = Curves.easeInOutCubic.transform(_controller.value);
          final bounce = math.sin(progress * math.pi) * 7;
          const ballSize = 42.0;
          final trackWidth = math.max(widget.width, ballSize);
          final travel = trackWidth - ballSize;

          return SizedBox(
            width: trackWidth,
            height: 82,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: _FootballLoadingTrack(progress: progress),
                ),
                Positioned(
                  left: travel * progress,
                  bottom: 26 + bounce,
                  child: Transform.rotate(
                    angle: _controller.value * math.pi * 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.82)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ballShadow,
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const SizedBox(
                        width: ballSize,
                        height: ballSize,
                        child: Icon(
                          Icons.sports_soccer,
                          color: Color(0xFF111827),
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FootballLoadingTrack extends StatelessWidget {
  final double progress;

  const _FootballLoadingTrack({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final baseColor = brightness == Brightness.dark
        ? const Color(0xFF10231C)
        : const Color(0xFFE6F7EC);
    final fillStart = Color.lerp(
          scheme.primary,
          const Color(0xFF16A34A),
          brightness == Brightness.dark ? 0.42 : 0.68,
        ) ??
        scheme.primary;
    final fillEnd = Color.lerp(
          scheme.secondary,
          const Color(0xFF22C55E),
          brightness == Brightness.dark ? 0.48 : 0.72,
        ) ??
        scheme.secondary;

    return SizedBox(
      height: 18,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: AppRadius.full,
          border: Border.all(
            color: brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFFB7E7C7),
          ),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.full,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FractionallySizedBox(
                widthFactor:
                    (0.08 + (progress * 0.92)).clamp(0.0, 1.0).toDouble(),
                alignment: AlignmentDirectional.centerStart,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [fillStart, fillEnd],
                    ),
                  ),
                ),
              ),
              CustomPaint(
                painter: _FootballPitchMarksPainter(
                  brightness: brightness,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FootballPitchMarksPainter extends CustomPainter {
  final Brightness brightness;

  const _FootballPitchMarksPainter({required this.brightness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(
        alpha: brightness == Brightness.dark ? 0.32 : 0.52,
      )
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final centerY = size.height / 2;

    canvas.drawLine(
      Offset(size.width * 0.5, 3),
      Offset(size.width * 0.5, size.height - 3),
      paint,
    );
    canvas.drawCircle(Offset(size.width * 0.5, centerY), 8, paint);

    final boxWidth = size.width * 0.18;
    final boxHeight = size.height - 6;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 3, boxWidth, boxHeight),
        const Radius.circular(8),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - boxWidth - 2, 3, boxWidth, boxHeight),
        const Radius.circular(8),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FootballPitchMarksPainter oldDelegate) {
    return oldDelegate.brightness != brightness;
  }
}
