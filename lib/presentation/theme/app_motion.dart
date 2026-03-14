import 'package:flutter/material.dart';

class AppMotion {
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static Duration fast(BuildContext context) => reduceMotion(context)
      ? const Duration(milliseconds: 80)
      : const Duration(milliseconds: 160);

  static Duration base(BuildContext context) => reduceMotion(context)
      ? const Duration(milliseconds: 120)
      : const Duration(milliseconds: 220);

  static Duration slow(BuildContext context) => reduceMotion(context)
      ? const Duration(milliseconds: 180)
      : const Duration(milliseconds: 300);

  static const Curve curveEnter = Curves.easeOutCubic;
  static const Curve curveExit = Curves.easeInCubic;
  static const Curve curveEmphasis = Curves.easeInOutCubic;
}
