import 'package:flutter/material.dart';

class TrainingStatusVisual {
  final IconData icon;
  final Color color;
  final Color gradientStart;
  final Color gradientEnd;
  final IconData sparkleIcon;

  const TrainingStatusVisual({
    required this.icon,
    required this.color,
    required this.gradientStart,
    required this.gradientEnd,
    required this.sparkleIcon,
  });
}

TrainingStatusVisual trainingStatusVisual(String status) {
  switch (status) {
    case 'great':
      return const TrainingStatusVisual(
        icon: Icons.emoji_events_rounded,
        color: Color(0xFFFFC24D),
        gradientStart: Color(0xFFFFE082),
        gradientEnd: Color(0xFFFF8F00),
        sparkleIcon: Icons.sports_score_rounded,
      );
    case 'good':
      return const TrainingStatusVisual(
        icon: Icons.sports_soccer_rounded,
        color: Color(0xFF00C9A7),
        gradientStart: Color(0xFF6FFFE9),
        gradientEnd: Color(0xFF00A3C4),
        sparkleIcon: Icons.check_rounded,
      );
    case 'tough':
      return const TrainingStatusVisual(
        icon: Icons.fitness_center_rounded,
        color: Color(0xFFFF6B6B),
        gradientStart: Color(0xFFFFA8A8),
        gradientEnd: Color(0xFFFF5E62),
        sparkleIcon: Icons.bolt_rounded,
      );
    case 'recovery':
      return const TrainingStatusVisual(
        icon: Icons.self_improvement_rounded,
        color: Color(0xFF6EC6FF),
        gradientStart: Color(0xFF8EE3F5),
        gradientEnd: Color(0xFF5B86E5),
        sparkleIcon: Icons.favorite_rounded,
      );
    case 'normal':
    default:
      return const TrainingStatusVisual(
        icon: Icons.shield_rounded,
        color: Color(0xFF7EA8FF),
        gradientStart: Color(0xFF9EC5FF),
        gradientEnd: Color(0xFF5E7BFF),
        sparkleIcon: Icons.sports_soccer_rounded,
      );
  }
}

Color trainingStatusColor(String status) =>
    trainingStatusVisual(status).gradientEnd;
