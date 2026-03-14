import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

class AppPressableScale extends StatefulWidget {
  final Widget child;

  const AppPressableScale({super.key, required this.child});

  @override
  State<AppPressableScale> createState() => _AppPressableScaleState();
}

class _AppPressableScaleState extends State<AppPressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: AppMotion.fast(context),
        curve: AppMotion.curveEmphasis,
        scale: _pressed ? 0.98 : 1,
        child: widget.child,
      ),
    );
  }
}
