import 'dart:math' as math;

import 'package:flutter/material.dart';

class RinzyMascot extends StatefulWidget {
  static const String assetPath = 'assets/images/rinzy_mascot.png';

  final double size;
  final double progress;
  final bool animate;

  const RinzyMascot({
    super.key,
    this.size = 112,
    this.progress = 0,
    this.animate = true,
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
                            child: Image.asset(
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
