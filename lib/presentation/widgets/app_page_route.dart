import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final reduced = AppMotion.reduceMotion(context);
            if (reduced) {
              return FadeTransition(opacity: animation, child: child);
            }
            final fade = CurvedAnimation(
              parent: animation,
              curve: AppMotion.curveEnter,
              reverseCurve: AppMotion.curveExit,
            );
            final slide = Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(fade);
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        );
}
