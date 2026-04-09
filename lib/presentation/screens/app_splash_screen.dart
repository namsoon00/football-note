import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme/app_motion.dart';

class AppSplashScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const AppSplashScreen({super.key, required this.onCompleted});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _minVisibleDuration = Duration(milliseconds: 2000);
  static const Duration _fadeDuration = Duration(milliseconds: 300);
  static const Duration _reducedMotionDelay = Duration(milliseconds: 600);
  static const String _lottiePath = 'assets/animations/hope_gate_sunrise.json';

  late final AnimationController _fadeController;
  Timer? _completeTimer;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: _fadeDuration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_completeTimer != null || _completed) return;
    if (AppMotion.reduceMotion(context)) {
      _completeTimer = Timer(_reducedMotionDelay, _complete);
      return;
    }
    _completeTimer = Timer(_minVisibleDuration - _fadeDuration, () async {
      if (!mounted || _completed) return;
      await _fadeController.forward();
      _complete();
    });
  }

  @override
  void dispose() {
    _completeTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _complete() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotion(context);
    return Scaffold(
      body: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeInCubic),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0A1528),
                Color(0xFF143056),
                Color(0xFF2C5E8A),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Lottie.asset(
                _lottiePath,
                fit: BoxFit.cover,
                repeat: !reduceMotion,
                animate: true,
                frameRate: FrameRate.max,
              ),
              IgnorePointer(
                child: Align(
                  alignment: const Alignment(0, -0.66),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '오늘도 한 걸음 성장!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
