import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../application/player_level_service.dart';
import '../localization/player_progression_localizations.dart';
import 'player_level_visuals.dart';

Future<void> showXpGemRewardDialog(
  BuildContext context, {
  required PlayerLevelAward award,
}) async {
  if (award.gainedXp <= 0) return;
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final progressText = award.after.isMaxLevel
      ? l10n.dailyTasksXpDialogMaxProgress(
          award.after.totalXp,
          award.after.xpToNextMasteryStar,
        )
      : l10n.dailyTasksXpDialogProgress(
          award.after.totalXp,
          award.after.xpToNextLevel,
        );
  await _showCelebrationDialog(
    context,
    child: Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GemCluster(color: scheme.primary),
          const SizedBox(height: 14),
          Text(
            l10n.dailyTasksXpDialogTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.dailyTasksXpDialogMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(
                  l10n.dailyTasksXpDialogGems(award.gainedXp),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                _LevelProgressStrip(
                  progress: award.after.progress,
                  foreground: scheme.onPrimaryContainer,
                  background: scheme.onPrimaryContainer.withValues(alpha: 0.18),
                ),
                const SizedBox(height: 8),
                Text(
                  progressText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.dailyTasksXpDialogAction),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> showTrainingXpRewardDialog(
  BuildContext context, {
  required PlayerLevelAward award,
}) async {
  if (award.gainedXp <= 0) return;
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final spec = _TrainingXpDialogSpec.fromAward(l10n, scheme, award);
  await _showTrainingXpRewardDialog(context, award: award, spec: spec);
}

Future<void> showDiaryXpRewardDialog(
  BuildContext context, {
  required PlayerLevelAward award,
}) async {
  if (award.gainedXp <= 0) return;
  final l10n = AppLocalizations.of(context)!;
  await _showTrainingXpRewardDialog(
    context,
    award: award,
    spec: _TrainingXpDialogSpec(
      title: l10n.diaryXpDialogTitle,
      message: l10n.diaryXpDialogMessage,
      color: const Color(0xFF0F52BA),
    ),
  );
}

Future<void> showTrainingSketchXpRewardDialog(
  BuildContext context, {
  required PlayerLevelAward award,
}) async {
  if (award.gainedXp <= 0) return;
  final l10n = AppLocalizations.of(context)!;
  await _showTrainingXpRewardDialog(
    context,
    award: award,
    spec: _TrainingXpDialogSpec(
      title: l10n.trainingSketchXpDialogTitle,
      message: l10n.trainingSketchXpDialogMessage,
      color: const Color(0xFFD6A11E),
    ),
  );
}

Future<void> _showTrainingXpRewardDialog(
  BuildContext context, {
  required PlayerLevelAward award,
  required _TrainingXpDialogSpec spec,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final progressText = award.after.isMaxLevel
      ? l10n.dailyTasksXpDialogMaxProgress(
          award.after.totalXp,
          award.after.xpToNextMasteryStar,
        )
      : l10n.dailyTasksXpDialogProgress(
          award.after.totalXp,
          award.after.xpToNextLevel,
        );
  final panelColor = Color.alphaBlend(
    spec.color.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.22 : 0.14,
    ),
    scheme.surfaceContainerHighest,
  );
  await _showCelebrationDialog(
    context,
    child: Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: spec.color.withValues(alpha: 0.18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GemCluster(color: spec.color),
          const SizedBox(height: 14),
          Text(
            spec.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            spec.message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(
                  l10n.trainingXpDialogXp(award.gainedXp),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: spec.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                _LevelProgressStrip(
                  progress: award.after.progress,
                  foreground: spec.color,
                  background: spec.color.withValues(alpha: 0.18),
                ),
                const SizedBox(height: 8),
                Text(
                  progressText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.trainingXpDialogAction),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> showTrainingStreakCheerDialog(
  BuildContext context, {
  required PlayerLevelAward award,
}) async {
  final streakDays = _trainingStreakDays(award);
  if (streakDays < 2) return;
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  await _showCelebrationDialog(
    context,
    child: Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _FlameBurst(color: Color(0xFFF97316)),
          const SizedBox(height: 14),
          Text(
            l10n.trainingStreakCheerTitle(streakDays),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.trainingStreakCheerMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.trainingStreakCheerAction),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> showLevelUpCelebrationDialog(
  BuildContext context, {
  required PlayerLevelAward award,
  required bool isKo,
  required VoidCallback? onClaimReward,
  String customRewardName = '',
}) async {
  if (!award.didLevelUp) return;
  final l10n = AppLocalizations.of(context)!;
  final reward = PlayerLevelService.rewardForLevel(award.after.level);
  final rewardName = customRewardName.trim();
  final hasCustomRewardName = rewardName.isNotEmpty;
  final hasReward = reward != null && hasCustomRewardName;
  final theme = Theme.of(context);
  final spec = PlayerLevelVisualSpec.fromLevel(award.after.level);
  final gradientColors = <Color>[
    spec.colors.first.withValues(alpha: 0.96),
    spec.colors.last.withValues(alpha: 0.96),
  ];
  const foreground = Colors.white;
  final softForeground = Colors.white.withValues(alpha: 0.86);
  final stageName = l10n.playerLevelStageName(award.after.level);
  final levelName = l10n.playerLevelName(award.after.level);

  await _showCelebrationDialog(
    context,
    child: Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _CelebrationBurst(),
          const SizedBox(height: 14),
          Text(
            l10n.levelUpDialogTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.levelUpDialogLevelLabel(award.after.level, levelName),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasCustomRewardName
                ? l10n.levelUpDialogEncouragementWithReward(rewardName)
                : l10n.levelUpDialogEncouragement,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: softForeground,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Column(
              children: [
                Text(
                  l10n.levelUpDialogProgress(award.gainedXp, stageName),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 10),
                _LevelProgressStrip(
                  progress: award.after.progress,
                  foreground: foreground,
                  background: Colors.white.withValues(alpha: 0.18),
                ),
              ],
            ),
          ),
          if (hasReward) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.levelUpDialogRewardTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rewardName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: foreground,
                    ),
                  ),
                  if ((isKo ? reward.descriptionKo : reward.descriptionEn)
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      isKo ? reward.descriptionKo : reward.descriptionEn,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: softForeground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: foreground,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(l10n.levelUpDialogLater),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onClaimReward?.call();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: spec.colors.first,
                  ),
                  child: Text(
                    hasReward
                        ? l10n.levelUpDialogClaimReward
                        : l10n.levelUpDialogConfirm,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _TrainingXpDialogSpec {
  final String title;
  final String message;
  final Color color;

  const _TrainingXpDialogSpec({
    required this.title,
    required this.message,
    required this.color,
  });

  factory _TrainingXpDialogSpec.fromAward(
    AppLocalizations l10n,
    ColorScheme scheme,
    PlayerLevelAward award,
  ) {
    final reasons = award.reasons.toSet();
    final hasJumpRopeGain = reasons.contains('jump_rope_added') ||
        (!reasons.contains('jump_rope_missed') &&
            reasons.any((reason) => reason.contains('jump_rope')));
    final hasLiftingGain = reasons.contains('lifting_added') ||
        (!reasons.contains('lifting_missed') &&
            reasons.any((reason) => reason.contains('lifting')));
    if (hasJumpRopeGain) {
      return _TrainingXpDialogSpec(
        title: l10n.trainingXpDialogJumpRopeTitle,
        message: l10n.trainingXpDialogJumpRopeMessage,
        color: scheme.primary,
      );
    }
    if (hasLiftingGain) {
      return _TrainingXpDialogSpec(
        title: l10n.trainingXpDialogLiftingTitle,
        message: l10n.trainingXpDialogLiftingMessage,
        color: scheme.secondary,
      );
    }
    if (reasons.any((reason) => reason.startsWith('meal_'))) {
      return _TrainingXpDialogSpec(
        title: l10n.trainingXpDialogMealTitle,
        message: l10n.trainingXpDialogMealMessage,
        color: const Color(0xFFB45309),
      );
    }
    return _TrainingXpDialogSpec(
      title: l10n.trainingXpDialogTitle,
      message: l10n.trainingXpDialogMessage,
      color: const Color(0xFF2563EB),
    );
  }
}

int _trainingStreakDays(PlayerLevelAward award) {
  final reasons = award.reasons.toSet();
  if (reasons.contains('streak_7') || reasons.contains('streak_daily_7_plus')) {
    return 7;
  }
  if (reasons.contains('streak_daily_4_6')) return 4;
  if (reasons.contains('streak_3')) return 3;
  if (reasons.contains('streak_daily_2_3')) return 2;
  return 0;
}

Future<void> _showCelebrationDialog(
  BuildContext context, {
  required Widget child,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, _, __) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final availableWidth = MediaQuery.sizeOf(context).width - 32;
      final dialogWidth = math.max(280.0, math.min(availableWidth, 520.0));
      return FadeTransition(
        opacity: curved,
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: _FallingGemBackdrop(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(width: dialogWidth, child: child),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _FallingGemBackdrop extends StatefulWidget {
  final Color color;

  const _FallingGemBackdrop({required this.color});

  @override
  State<_FallingGemBackdrop> createState() => _FallingGemBackdropState();
}

class _FallingGemBackdropState extends State<_FallingGemBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _FallingGemPainter(
            progress: _controller.value,
            colors: <Color>[
              widget.color,
              scheme.primary,
              scheme.secondary,
              const Color(0xFF38BDF8),
              const Color(0xFFFBBF24),
            ],
          ),
        );
      },
    );
  }
}

class _FallingGemPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;

  const _FallingGemPainter({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    for (var index = 0; index < 18; index++) {
      final seed = ((index * 37) % 100) / 100.0;
      final fall = (progress + seed * 1.37) % 1.0;
      final sway = math.sin((progress * math.pi * 2) + index) * 24;
      final x = ((seed * size.width) + sway).clamp(8.0, size.width - 8);
      final y = (fall * (size.height + 140)) - 70;
      final gemSize = 10.0 + ((index % 4) * 4);
      final color = colors[index % colors.length];
      final opacity = 0.28 + ((index % 5) * 0.055);
      final center = Offset(x.toDouble(), y);
      final halfWidth = gemSize * 0.58;
      final halfHeight = gemSize * 0.82;
      final path = Path()
        ..moveTo(center.dx, center.dy - halfHeight)
        ..lineTo(center.dx + halfWidth, center.dy)
        ..lineTo(center.dx, center.dy + halfHeight)
        ..lineTo(center.dx - halfWidth, center.dy)
        ..close();
      canvas.drawPath(
        path.shift(const Offset(0, 1.2)),
        Paint()..color = Colors.black.withValues(alpha: 0.12),
      );
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: opacity));
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.34)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9,
      );
      canvas.drawLine(
        Offset(center.dx - halfWidth * 0.45, center.dy - halfHeight * 0.12),
        Offset(center.dx + halfWidth * 0.35, center.dy - halfHeight * 0.48),
        Paint()
          ..color = Colors.white.withValues(
            alpha: (opacity * 1.45).clamp(0.0, 1.0),
          )
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FallingGemPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.colors != colors;
  }
}

class _FlameBurst extends StatefulWidget {
  final Color color;

  const _FlameBurst({required this.color});

  @override
  State<_FlameBurst> createState() => _FlameBurstState();
}

class _FlameBurstState extends State<_FlameBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 144,
      height: 78,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _controller.value;
          return CustomPaint(
            painter: _FlameBurstPainter(
              color: widget.color,
              progress: progress,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: Offset(
                    math.sin(progress * math.pi * 2) * 1.8,
                    math.cos(progress * math.pi * 2) * 1.2,
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    size: 70,
                    color: widget.color.withValues(alpha: 0.92),
                    shadows: [
                      Shadow(
                        color: widget.color.withValues(alpha: 0.38),
                        blurRadius: 22,
                      ),
                      const Shadow(
                        color: Color(0x22000000),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 3 + math.sin(progress * math.pi * 2) * 2,
                  left: 36 + math.cos(progress * math.pi * 2) * 3,
                  child: Icon(
                    Icons.whatshot_rounded,
                    color: const Color(0xFFFFD166).withValues(alpha: 0.78),
                    size: 19,
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

class _FlameBurstPainter extends CustomPainter {
  final Color color;
  final double progress;

  const _FlameBurstPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final center = Offset(size.width * 0.5, size.height * 0.68);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          color.withValues(alpha: 0.34),
          const Color(0xFFFFB703).withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const <double>[0, 0.45, 1],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.width * 0.42),
      );
    canvas.drawCircle(center, size.width * 0.42, glow);

    for (var index = 0; index < 9; index++) {
      final seed = ((index * 23) % 97) / 97.0;
      final rise = (progress + seed) % 1.0;
      final x = size.width * (0.22 + seed * 0.56) +
          math.sin((progress * math.pi * 2) + index) * 7;
      final y = size.height * (0.90 - rise * 0.76);
      final radius = 1.5 + (1 - rise) * 3.5;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = Color.lerp(
            const Color(0xFFFFF3B0),
            const Color(0xFFFF7A1A),
            rise,
          )!
              .withValues(alpha: (1 - rise).clamp(0.0, 1.0) * 0.78),
      );
    }

    final flameColors = <Color>[
      const Color(0xFFC2410C),
      color,
      const Color(0xFFFFD166),
    ];
    for (var layer = 0; layer < flameColors.length; layer++) {
      final inset = layer * 10.0;
      final height = size.height * (0.62 - layer * 0.10);
      final width = size.width * (0.34 - layer * 0.055);
      final phase = (progress * math.pi * 2) + layer;
      final tip = Offset(
        size.width * 0.5 + math.sin(phase) * (5 - layer),
        size.height * 0.12 + inset * 0.30 + math.cos(phase) * 2.5,
      );
      final baseY = size.height * 0.88 - inset * 0.10;
      final path = Path()
        ..moveTo(size.width * 0.5 - width, baseY)
        ..cubicTo(
          size.width * 0.18 + inset,
          baseY - height * 0.30,
          tip.dx - width * 0.82,
          tip.dy + height * 0.34,
          tip.dx,
          tip.dy,
        )
        ..cubicTo(
          tip.dx + width * 0.74,
          tip.dy + height * 0.36,
          size.width * 0.82 - inset,
          baseY - height * 0.34,
          size.width * 0.5 + width,
          baseY,
        )
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = flameColors[layer].withValues(alpha: 0.34 + layer * 0.19),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FlameBurstPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}

class _GemCluster extends StatefulWidget {
  final Color color;

  const _GemCluster({required this.color});

  @override
  State<_GemCluster> createState() => _GemClusterState();
}

class _GemClusterState extends State<_GemCluster>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 144,
      height: 78,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _controller.value;
          final pulse = 1 + (math.sin(progress * math.pi * 2) * 0.045);
          final glint = (math.sin((progress * math.pi * 2) + 0.8) + 1) / 2;
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GemAuraPainter(
                    color: widget.color,
                    progress: progress,
                  ),
                ),
              ),
              _GemIcon(
                left: 10,
                bottom: 12 + (math.sin(progress * math.pi * 2) * 2),
                color: widget.color.withValues(alpha: 0.50),
              ),
              _GemIcon(
                right: 8,
                top: 10 + (math.cos(progress * math.pi * 2) * 2),
                color: widget.color.withValues(alpha: 0.42),
              ),
              Transform.scale(
                scale: pulse,
                child: Icon(
                  Icons.diamond_rounded,
                  size: 64,
                  color: widget.color,
                  shadows: [
                    Shadow(
                      color: widget.color.withValues(alpha: 0.42),
                      blurRadius: 20 + (glint * 10),
                    ),
                    const Shadow(
                      color: Color(0x22000000),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 22 + (math.sin(progress * math.pi * 2) * 4),
                left: 47 + (progress * 22),
                child: Transform.rotate(
                  angle: -0.68,
                  child: Opacity(
                    opacity: 0.30 + (glint * 0.36),
                    child: Container(
                      width: 30,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 2,
                left: 38,
                child: Opacity(
                  opacity: 0.42 + (glint * 0.36),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: widget.color,
                    size: 20 + (glint * 3),
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                right: 38,
                child: Opacity(
                  opacity: 0.34 + ((1 - glint) * 0.32),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: widget.color,
                    size: 18 + ((1 - glint) * 3),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GemIcon extends StatelessWidget {
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final Color color;

  const _GemIcon({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Icon(Icons.diamond_rounded, size: 28, color: color),
    );
  }
}

class _GemAuraPainter extends CustomPainter {
  final Color color;
  final double progress;

  const _GemAuraPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = size.width * 0.31;
    final glowRect = Rect.fromCircle(center: center, radius: radius * 1.45);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          color.withValues(alpha: 0.24),
          color.withValues(alpha: 0.10),
          Colors.transparent,
        ],
        stops: const <double>[0, 0.56, 1],
      ).createShader(glowRect);
    canvas.drawCircle(center, radius * 1.45, glowPaint);

    final rayPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 8; index++) {
      final angle = (progress * math.pi * 2) + (index * math.pi / 4);
      final start = Offset(
        center.dx + math.cos(angle) * radius * 0.72,
        center.dy + math.sin(angle) * radius * 0.44,
      );
      final end = Offset(
        center.dx + math.cos(angle) * radius * 1.24,
        center.dy + math.sin(angle) * radius * 0.78,
      );
      canvas.drawLine(start, end, rayPaint);
    }

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..shader = SweepGradient(
        transform: GradientRotation(progress * math.pi * 2),
        colors: <Color>[
          Colors.transparent,
          Colors.white.withValues(alpha: 0.64),
          color.withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const <double>[0, 0.16, 0.38, 1],
      ).createShader(glowRect);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.78,
        height: size.height * 0.82,
      ),
      orbitPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GemAuraPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}

class _LevelProgressStrip extends StatelessWidget {
  final double progress;
  final Color foreground;
  final Color background;

  const _LevelProgressStrip({
    required this.progress,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 8,
        value: progress,
        backgroundColor: background,
        valueColor: AlwaysStoppedAnimation<Color>(foreground),
      ),
    );
  }
}

class _CelebrationBurst extends StatelessWidget {
  const _CelebrationBurst();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 132,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _BurstDot(left: 10, top: 30, color: Color(0xFFFF7A59)),
          _BurstDot(left: 28, top: 10, color: Color(0xFFFFC145)),
          _BurstDot(right: 26, top: 12, color: Color(0xFF57CC99)),
          _BurstDot(right: 8, top: 34, color: Color(0xFF3FA7D6)),
          _BurstDot(left: 34, bottom: 2, color: Color(0xFFF59E0B)),
          _BurstDot(right: 34, bottom: 6, color: Color(0xFF0EA5E9)),
          Icon(Icons.celebration_rounded, size: 54, color: Colors.white),
        ],
      ),
    );
  }
}

class _BurstDot extends StatelessWidget {
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final Color color;

  const _BurstDot({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
