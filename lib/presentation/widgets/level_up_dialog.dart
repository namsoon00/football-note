import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../application/player_level_service.dart';
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
  final stageName = PlayerLevelService.stageName(award.after.level, isKo);
  final levelName = PlayerLevelService.levelName(award.after.level, isKo);

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
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: child,
          ),
        ),
      );
    },
  );
}

class _GemCluster extends StatelessWidget {
  final Color color;

  const _GemCluster({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 144,
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _GemIcon(left: 10, bottom: 12, color: color.withValues(alpha: 0.50)),
          _GemIcon(right: 8, top: 10, color: color.withValues(alpha: 0.42)),
          Icon(
            Icons.diamond_rounded,
            size: 64,
            color: color,
            shadows: const [
              Shadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          Positioned(
            top: 2,
            left: 38,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: color.withValues(alpha: 0.78),
              size: 20,
            ),
          ),
          Positioned(
            bottom: 6,
            right: 38,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: color.withValues(alpha: 0.62),
              size: 18,
            ),
          ),
        ],
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
          _BurstDot(left: 34, bottom: 2, color: Color(0xFFFF8FA3)),
          _BurstDot(right: 34, bottom: 6, color: Color(0xFF7B61FF)),
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
