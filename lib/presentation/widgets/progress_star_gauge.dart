import 'package:flutter/material.dart';

class ProgressStarGauge extends StatelessWidget {
  final double progress;
  final double height;
  final double trackHeight;
  final double iconSize;
  final bool showStartIcon;

  const ProgressStarGauge({
    super.key,
    required this.progress,
    this.height = 34,
    this.trackHeight = 9,
    this.iconSize = 30,
    this.showStartIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ratio = progress.clamp(0, 1).toDouble();
    final fillColor = Color.lerp(
      const Color(0xFF40D697),
      const Color(0xFF087658),
      ratio,
    )!;
    final glowColor = Color.lerp(
      const Color(0xFFFFC857),
      const Color(0xFFFFA500),
      ratio,
    )!;
    final trackColor = scheme.surfaceContainerHighest.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.62 : 0.82,
    );
    final leftInset = showStartIcon ? iconSize * 0.86 : iconSize * 0.5;
    final rightInset = iconSize * 0.5;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = (constraints.maxWidth - leftInset - rightInset)
              .clamp(0.0, double.infinity);
          final fillWidth = trackWidth * ratio;
          final markerLeft = (leftInset + fillWidth - iconSize / 2).clamp(
            0.0,
            (constraints.maxWidth - iconSize).clamp(0.0, double.infinity),
          );
          return Stack(
            alignment: Alignment.center,
            children: [
              PositionedDirectional(
                start: leftInset,
                end: rightInset,
                child: Container(
                  height: trackHeight,
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              PositionedDirectional(
                start: leftInset,
                width: fillWidth,
                child: Container(
                  height: trackHeight,
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: fillColor.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              if (showStartIcon)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _GaugeIcon(
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF7A1A),
                    size: iconSize,
                  ),
                ),
              PositionedDirectional(
                start: markerLeft,
                child: _GaugeIcon(
                  icon: Icons.star_rounded,
                  color: glowColor,
                  size: iconSize,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GaugeIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _GaugeIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [Colors.white, color.withValues(alpha: 0.42)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.32),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: color,
        size: size * 0.72,
        shadows: const [
          Shadow(
            color: Color(0x26000000),
            blurRadius: 4,
            offset: Offset(0, 1.5),
          ),
        ],
      ),
    );
  }
}
