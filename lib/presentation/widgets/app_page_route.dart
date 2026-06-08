import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

class AppPageRoute<T> extends CupertinoPageRoute<T> {
  AppPageRoute({required super.builder, T? initialResult})
      : currentResultValue = initialResult;

  T? currentResultValue;

  bool _usesPlatformBackGesture(TargetPlatform platform) {
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  @override
  T? get currentResult => currentResultValue ?? super.currentResult;

  @override
  Duration get transitionDuration =>
      _usesPlatformBackGesture(defaultTargetPlatform)
          ? super.transitionDuration
          : const Duration(milliseconds: 160);

  @override
  Duration get reverseTransitionDuration =>
      _usesPlatformBackGesture(defaultTargetPlatform)
          ? super.reverseTransitionDuration
          : const Duration(milliseconds: 130);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final platform = Theme.of(context).platform;
    if (_usesPlatformBackGesture(platform)) {
      return super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
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
      begin: const Offset(0.025, 0),
      end: Offset.zero,
    ).animate(fade);
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
