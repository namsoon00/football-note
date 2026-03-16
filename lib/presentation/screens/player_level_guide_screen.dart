import 'package:flutter/material.dart';

import '../../application/player_level_service.dart';
import '../widgets/app_background.dart';

class PlayerLevelGuideScreen extends StatelessWidget {
  final int currentLevel;

  const PlayerLevelGuideScreen({super.key, required this.currentLevel});

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final thresholds = PlayerLevelService.levelThresholds;
    final highestLevel = thresholds.length;

    return Scaffold(
      appBar: AppBar(title: Text(isKo ? '레벨 가이드' : 'Level guide')),
      body: AppBackground(
        child: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: highestLevel,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final level = index + 1;
              final tier = _LevelVisualTier.fromLevel(level);
              final minXp = thresholds[index];
              final maxXp = index + 1 < thresholds.length
                  ? thresholds[index + 1] - 1
                  : null;
              final isCurrent = level == currentLevel;
              return _LevelGuideCard(
                level: level,
                minXp: minXp,
                maxXp: maxXp,
                isCurrent: isCurrent,
                isKo: isKo,
                tier: tier,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LevelGuideCard extends StatelessWidget {
  final int level;
  final int minXp;
  final int? maxXp;
  final bool isCurrent;
  final bool isKo;
  final _LevelVisualTier tier;

  const _LevelGuideCard({
    required this.level,
    required this.minXp,
    required this.maxXp,
    required this.isCurrent,
    required this.isKo,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tier.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: isCurrent ? 0.42 : 0.18),
          width: isCurrent ? 1.4 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Lv.$level ${PlayerLevelService.levelName(level, isKo)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isKo ? '현재 레벨' : 'Current',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  PlayerLevelService.stageName(level, isKo),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  PlayerLevelService.illustrationLabel(level, isKo),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  maxXp == null
                      ? (isKo ? '$minXp XP 이상' : '$minXp XP+')
                      : (isKo
                            ? '$minXp XP ~ $maxXp XP'
                            : '$minXp XP to $maxXp XP'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 108,
            height: 108,
            child: CustomPaint(painter: _LevelIllustrationPainter(tier: tier)),
          ),
        ],
      ),
    );
  }
}

class _LevelVisualTier {
  final List<Color> colors;
  final _LevelIllustrationStage stage;

  const _LevelVisualTier({required this.colors, required this.stage});

  factory _LevelVisualTier.fromLevel(int level) {
    if (level <= 2) {
      return const _LevelVisualTier(
        colors: <Color>[Color(0xFF1D976C), Color(0xFF3A7BD5)],
        stage: _LevelIllustrationStage.kickoff,
      );
    }
    if (level <= 4) {
      return const _LevelVisualTier(
        colors: <Color>[Color(0xFFED8F03), Color(0xFFFFB75E)],
        stage: _LevelIllustrationStage.training,
      );
    }
    if (level <= 6) {
      return const _LevelVisualTier(
        colors: <Color>[Color(0xFF355C7D), Color(0xFF6C5B7B)],
        stage: _LevelIllustrationStage.tactics,
      );
    }
    if (level <= 8) {
      return const _LevelVisualTier(
        colors: <Color>[Color(0xFFC04848), Color(0xFF480048)],
        stage: _LevelIllustrationStage.captain,
      );
    }
    return const _LevelVisualTier(
      colors: <Color>[Color(0xFF232526), Color(0xFF414345)],
      stage: _LevelIllustrationStage.legend,
    );
  }
}

enum _LevelIllustrationStage { kickoff, training, tactics, captain, legend }

class _LevelIllustrationPainter extends CustomPainter {
  final _LevelVisualTier tier;

  const _LevelIllustrationPainter({required this.tier});

  @override
  void paint(Canvas canvas, Size size) {
    final whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final whiteStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final softStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    switch (tier.stage) {
      case _LevelIllustrationStage.kickoff:
        _paintKickoff(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case _LevelIllustrationStage.training:
        _paintTraining(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case _LevelIllustrationStage.tactics:
        _paintTactics(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case _LevelIllustrationStage.captain:
        _paintCaptain(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
      case _LevelIllustrationStage.legend:
        _paintLegend(canvas, size, whiteFill, whiteStroke, softStroke);
        break;
    }
  }

  void _paintKickoff(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final center = Offset(size.width * 0.5, size.height * 0.44);
    canvas.drawCircle(
      center,
      26,
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    canvas.drawCircle(center, 19, stroke);
    canvas.drawLine(
      Offset(center.dx - 24, center.dy),
      Offset(center.dx + 24, center.dy),
      softStroke,
    );
    canvas.drawCircle(center, 6.5, fill);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.22, size.height * 0.16)
        ..lineTo(size.width * 0.34, size.height * 0.08)
        ..lineTo(size.width * 0.34, size.height * 0.3)
        ..close(),
      fill,
    );
  }

  void _paintTraining(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final cone = Path()
      ..moveTo(size.width * 0.28, size.height * 0.7)
      ..lineTo(size.width * 0.44, size.height * 0.26)
      ..lineTo(size.width * 0.6, size.height * 0.7)
      ..close();
    canvas.drawPath(cone, Paint()..color = Colors.white.withValues(alpha: 0.2));
    canvas.drawPath(cone, stroke);
    canvas.drawLine(
      Offset(size.width * 0.34, size.height * 0.56),
      Offset(size.width * 0.54, size.height * 0.56),
      softStroke,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.72, size.height * 0.32),
        width: 18,
        height: 28,
      ),
      fill,
    );
    canvas.drawLine(
      Offset(size.width * 0.72, size.height * 0.45),
      Offset(size.width * 0.72, size.height * 0.64),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.62, size.height * 0.54),
      Offset(size.width * 0.82, size.height * 0.48),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.72, size.height * 0.64),
      Offset(size.width * 0.64, size.height * 0.8),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.72, size.height * 0.64),
      Offset(size.width * 0.82, size.height * 0.78),
      stroke,
    );
  }

  void _paintTactics(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.16,
        size.width * 0.64,
        size.height * 0.54,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    canvas.drawRRect(rect, stroke);
    canvas.drawLine(
      Offset(size.width * 0.48, size.height * 0.16),
      Offset(size.width * 0.48, size.height * 0.7),
      softStroke,
    );
    canvas.drawCircle(Offset(size.width * 0.32, size.height * 0.34), 5, fill);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.3), 5, fill);
    canvas.drawCircle(Offset(size.width * 0.58, size.height * 0.56), 5, fill);
    final arrow = Path()
      ..moveTo(size.width * 0.3, size.height * 0.34)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.22,
        size.width * 0.58,
        size.height * 0.3,
      )
      ..lineTo(size.width * 0.53, size.height * 0.24)
      ..moveTo(size.width * 0.58, size.height * 0.3)
      ..lineTo(size.width * 0.5, size.height * 0.3);
    canvas.drawPath(arrow, stroke);
    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.34),
      Offset(size.width * 0.68, size.height * 0.48),
      stroke,
    );
  }

  void _paintCaptain(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final shield = Path()
      ..moveTo(size.width * 0.5, size.height * 0.14)
      ..lineTo(size.width * 0.7, size.height * 0.22)
      ..lineTo(size.width * 0.66, size.height * 0.52)
      ..quadraticBezierTo(
        size.width * 0.58,
        size.height * 0.72,
        size.width * 0.5,
        size.height * 0.8,
      )
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.72,
        size.width * 0.34,
        size.height * 0.52,
      )
      ..lineTo(size.width * 0.3, size.height * 0.22)
      ..close();
    canvas.drawPath(
      shield,
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );
    canvas.drawPath(shield, stroke);
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.28),
      Offset(size.width * 0.6, size.height * 0.28),
      softStroke,
    );
    final armBand = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.6,
        size.width * 0.26,
        size.height * 0.12,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      armBand,
      Paint()..color = Colors.white.withValues(alpha: 0.2),
    );
    canvas.drawRRect(armBand, stroke);
    canvas.drawArc(
      Rect.fromLTWH(
        armBand.left + 7,
        armBand.top + 4,
        armBand.width - 14,
        armBand.height - 8,
      ),
      0.8,
      4.6,
      false,
      stroke,
    );
  }

  void _paintLegend(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint stroke,
    Paint softStroke,
  ) {
    final cup = Path()
      ..moveTo(size.width * 0.34, size.height * 0.2)
      ..lineTo(size.width * 0.66, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.64,
        size.height * 0.42,
        size.width * 0.56,
        size.height * 0.5,
      )
      ..lineTo(size.width * 0.56, size.height * 0.62)
      ..lineTo(size.width * 0.64, size.height * 0.68)
      ..lineTo(size.width * 0.36, size.height * 0.68)
      ..lineTo(size.width * 0.44, size.height * 0.62)
      ..lineTo(size.width * 0.44, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.36,
        size.height * 0.42,
        size.width * 0.34,
        size.height * 0.2,
      )
      ..close();
    canvas.drawPath(cup, Paint()..color = Colors.white.withValues(alpha: 0.16));
    canvas.drawPath(cup, stroke);
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.22,
        size.height * 0.26,
        size.width * 0.18,
        size.height * 0.18,
      ),
      1.3,
      2.6,
      false,
      softStroke,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.6,
        size.height * 0.26,
        size.width * 0.18,
        size.height * 0.18,
      ),
      -0.3,
      2.6,
      false,
      softStroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.38, size.height * 0.82),
      Offset(size.width * 0.62, size.height * 0.82),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _LevelIllustrationPainter oldDelegate) {
    return oldDelegate.tier.stage != tier.stage ||
        oldDelegate.tier.colors != tier.colors;
  }
}
