import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  await _showTrainingXpRewardDialog(
    context,
    award: award,
    spec: spec,
    immersive: true,
  );
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
  bool immersive = false,
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
  if (immersive) {
    await _showCelebrationDialog(
      context,
      fullScreen: true,
      showBackdrop: false,
      child: _TrainingXpRewardFullScreen(
        award: award,
        spec: spec,
        progressText: progressText,
      ),
    );
    return;
  }
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
  await _showCelebrationDialog(
    context,
    fullScreen: true,
    showBackdrop: false,
    child: _TrainingStreakFullScreen(
      streakDays: streakDays,
      title: l10n.trainingStreakCheerTitle(streakDays),
      message: l10n.trainingStreakCheerMessage,
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
    final hasJumpRopeGain =
        reasons.contains('jump_rope_added') ||
        (!reasons.contains('jump_rope_missed') &&
            reasons.any((reason) => reason.contains('jump_rope')));
    final hasLiftingGain =
        reasons.contains('lifting_added') ||
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

class _TrainingXpRewardFullScreen extends StatelessWidget {
  final PlayerLevelAward award;
  final _TrainingXpDialogSpec spec;
  final String progressText;

  const _TrainingXpRewardFullScreen({
    required this.award,
    required this.spec,
    required this.progressText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = spec.color;
    final topColor = Color.alphaBlend(
      accent.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.28 : 0.18,
      ),
      scheme.surface,
    );
    final bottomColor = Color.alphaBlend(
      scheme.secondary.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10,
      ),
      scheme.surface,
    );
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, scheme.surface, bottomColor],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactHeight = constraints.maxHeight < 660;
            return Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: theme.brightness == Brightness.dark ? 0.24 : 0.18,
                  child: _FallingGemBackdrop(color: accent),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    12,
                    18,
                    compactHeight ? 16 : 22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: IconButton.filledTonal(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonLabel,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _TrainingGemRewardStage(
                                    color: accent,
                                    compact: compactHeight,
                                    label: l10n.trainingXpDialogRewardLabel,
                                    value: l10n.trainingXpDialogXp(
                                      award.gainedXp,
                                    ),
                                  ),
                                  SizedBox(height: compactHeight ? 14 : 20),
                                  Text(
                                    spec.title,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          height: 1.08,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    spec.message,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                      height: 1.35,
                                    ),
                                  ),
                                  SizedBox(height: compactHeight ? 16 : 22),
                                  _TrainingGemProgressPanel(
                                    award: award,
                                    color: accent,
                                    progressText: progressText,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: Text(l10n.trainingXpDialogAction),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TrainingGemRewardStage extends StatelessWidget {
  final Color color;
  final bool compact;
  final String label;
  final String value;

  const _TrainingGemRewardStage({
    required this.color,
    required this.compact,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stageHeight = compact ? 206.0 : 246.0;
    final heroSize = compact ? 112.0 : 138.0;
    return SizedBox(
      height: stageHeight,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _TrainingGemStagePainter(
                color: color,
                surface: scheme.surface,
              ),
            ),
          ),
          Positioned(
            left: 30,
            top: compact ? 36 : 46,
            child: Transform.rotate(
              angle: -0.18,
              child: _CuteGemIcon(
                color: Color.lerp(color, scheme.secondary, 0.38)!,
                size: compact ? 50 : 60,
                glint: 0.58,
              ),
            ),
          ),
          Positioned(
            right: 28,
            top: compact ? 48 : 62,
            child: Transform.rotate(
              angle: 0.22,
              child: _CuteGemIcon(
                color: Color.lerp(color, const Color(0xFF38BDF8), 0.46)!,
                size: compact ? 46 : 56,
                glint: 0.66,
              ),
            ),
          ),
          Positioned(
            top: compact ? 20 : 26,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.88, end: 1),
              duration: const Duration(milliseconds: 620),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: _CuteGemIcon(color: color, size: heroSize, glint: 0.92),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.86 : 0.92,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withValues(alpha: 0.24)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingGemProgressPanel extends StatelessWidget {
  final PlayerLevelAward award;
  final Color color;
  final String progressText;

  const _TrainingGemProgressPanel({
    required this.award,
    required this.color,
    required this.progressText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.82 : 0.90,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          _LevelProgressStrip(
            progress: award.after.progress,
            foreground: color,
            background: color.withValues(alpha: 0.16),
          ),
          const SizedBox(height: 10),
          _CelebrationDetailText(text: progressText),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _GemRewardMetric(
                  icon: Icons.auto_awesome_rounded,
                  color: color,
                  label: l10n.trainingXpDialogTotalLabel,
                  value: l10n.trainingXpDialogTotalValue(award.after.totalXp),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GemRewardMetric(
                  icon: Icons.workspace_premium_rounded,
                  color: color,
                  label: l10n.trainingXpDialogLevelLabel,
                  value: l10n.trainingXpDialogLevelValue(
                    award.after.level,
                    l10n.playerLevelName(award.after.level),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GemRewardMetric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _GemRewardMetric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.08), scheme.surface),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingGemStagePainter extends CustomPainter {
  final Color color;
  final Color surface;

  const _TrainingGemStagePainter({required this.color, required this.surface});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final center = Offset(size.width / 2, size.height * 0.44);
    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              color.withValues(alpha: 0.26),
              color.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.shortestSide * 0.62),
          );
    canvas.drawCircle(center, size.shortestSide * 0.62, glowPaint);

    final platformRect = Rect.fromLTWH(
      size.width * 0.17,
      size.height * 0.69,
      size.width * 0.66,
      size.height * 0.16,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(platformRect, const Radius.circular(999)),
      Paint()..color = color.withValues(alpha: 0.10),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        platformRect.deflate(1.2),
        const Radius.circular(999),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.38),
    );

    final rayPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 9; index += 1) {
      final angle = (-math.pi * 0.82) + index * (math.pi * 1.64 / 8);
      final start = center + Offset(math.cos(angle), math.sin(angle)) * 70;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * 98;
      canvas.drawLine(start, end, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrainingGemStagePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.surface != surface;
  }
}

enum _CelebrationCharacter { gem, flame }

class _CelebrationCharacterView extends StatefulWidget {
  final _CelebrationCharacter character;
  final Color color;
  final double size;

  const _CelebrationCharacterView({
    required this.character,
    required this.color,
    required this.size,
  });

  @override
  State<_CelebrationCharacterView> createState() =>
      _CelebrationCharacterViewState();
}

class _CelebrationCharacterViewState extends State<_CelebrationCharacterView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final bodySize = size * 0.78;
    return SizedBox.square(
      dimension: size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final phase = _controller.value;
          final bounce = math.sin(phase * math.pi * 2);
          final shimmer = (math.sin(phase * math.pi * 2.0) + 1) / 2;
          final lift = math.max(0.0, bounce) * size * 0.025;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: size * 0.10,
                child: Transform.scale(
                  scaleX: 1 - math.max(0.0, bounce) * 0.14,
                  child: Container(
                    width: size * 0.52,
                    height: size * 0.08,
                    decoration: BoxDecoration(
                      color: const Color(0x30111827),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: size * 0.12,
                top: size * (0.30 + shimmer * 0.02),
                child: Transform.rotate(
                  angle: -0.22,
                  child: _CelebrationAccentIcon(
                    character: widget.character,
                    color: Color.lerp(
                      widget.color,
                      Colors.white,
                      0.18,
                    )!.withValues(alpha: 0.76),
                    size: size * 0.20,
                    glint: 0.54 + shimmer * 0.24,
                  ),
                ),
              ),
              Positioned(
                right: size * 0.10,
                top: size * (0.48 - shimmer * 0.025),
                child: Transform.rotate(
                  angle: 0.26,
                  child: _CelebrationAccentIcon(
                    character: widget.character,
                    color: Color.lerp(
                      widget.color,
                      const Color(0xFF38BDF8),
                      widget.character == _CelebrationCharacter.gem ? 0.34 : 0,
                    )!.withValues(alpha: 0.72),
                    size: size * 0.17,
                    glint: 0.68,
                  ),
                ),
              ),
              Positioned(
                left: size * 0.25,
                bottom: size * (0.12 + shimmer * 0.018),
                child: Transform.rotate(
                  angle: 0.18,
                  child: _CelebrationAccentIcon(
                    character: widget.character,
                    color: widget.color.withValues(alpha: 0.64),
                    size: size * 0.14,
                    glint: 0.42 + shimmer * 0.22,
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -lift),
                child: Transform.rotate(
                  angle: bounce * 0.035,
                  child: widget.character == _CelebrationCharacter.flame
                      ? _CuteFlameIcon(color: widget.color, size: bodySize)
                      : _CuteGemIcon(
                          color: widget.color,
                          size: bodySize,
                          glint: 0.72 + math.max(0.0, bounce) * 0.24,
                        ),
                ),
              ),
              Positioned(
                top: size * 0.08,
                right: size * 0.18,
                child: Opacity(
                  opacity: 0.50 + math.max(0.0, bounce) * 0.28,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: widget.color,
                    size: size * 0.13,
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

class _CelebrationAccentIcon extends StatelessWidget {
  final _CelebrationCharacter character;
  final Color color;
  final double size;
  final double glint;

  const _CelebrationAccentIcon({
    required this.character,
    required this.color,
    required this.size,
    required this.glint,
  });

  @override
  Widget build(BuildContext context) {
    return character == _CelebrationCharacter.flame
        ? _CuteFlameIcon(color: color, size: size)
        : _CuteGemIcon(color: color, size: size, glint: glint);
  }
}

class _ChallengeStyleCelebrationFullScreen extends StatelessWidget {
  final Color accentColor;
  final _CelebrationCharacter character;
  final String title;
  final String message;
  final IconData actionIcon;
  final String actionLabel;
  final Widget? details;

  const _ChallengeStyleCelebrationFullScreen({
    required this.accentColor,
    this.character = _CelebrationCharacter.gem,
    required this.title,
    required this.message,
    required this.actionIcon,
    required this.actionLabel,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.58),
              scheme.surface,
              scheme.secondaryContainer.withValues(alpha: 0.42),
            ],
          ),
          border: Border.all(color: accentColor.withValues(alpha: 0.18)),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactHeight = constraints.maxHeight < 660;
              final mascotSize = MediaQuery.sizeOf(
                context,
              ).shortestSide.clamp(150, compactHeight ? 188 : 220).toDouble();
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: IconButton.filledTonal(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonLabel,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.fromLTRB(
                              18,
                              compactHeight ? 18 : 20,
                              18,
                              18,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surface.withValues(
                                alpha: theme.brightness == Brightness.dark
                                    ? 0.84
                                    : 0.90,
                              ),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.56,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.12),
                                  blurRadius: 28,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _CelebrationCharacterView(
                                  character: character,
                                  color: accentColor,
                                  size: mascotSize,
                                ),
                                SizedBox(height: compactHeight ? 14 : 18),
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  message,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                                if (details != null) ...[
                                  SizedBox(height: compactHeight ? 16 : 18),
                                  details!,
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(actionIcon),
                      label: Text(actionLabel),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CelebrationDetailText extends StatelessWidget {
  final String text;

  const _CelebrationDetailText({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _TrainingStreakFullScreen extends StatelessWidget {
  final int streakDays;
  final String title;
  final String message;

  const _TrainingStreakFullScreen({
    required this.streakDays,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const flame = Color(0xFFF97316);
    return _ChallengeStyleCelebrationFullScreen(
      accentColor: flame,
      character: _CelebrationCharacter.flame,
      title: title,
      message: message,
      actionIcon: Icons.local_fire_department_rounded,
      actionLabel: l10n.trainingStreakCheerAction,
      details: _StreakTrail(days: streakDays, color: flame),
    );
  }
}

class _StreakTrail extends StatelessWidget {
  final int days;
  final Color color;

  const _StreakTrail({required this.days, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleDays = days.clamp(2, 7).toInt();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var index = 0; index < visibleDays; index += 1)
          _MiniFlameToken(
            color: color,
            scale: 1 + math.min(index.toDouble(), 3) * 0.035,
            opacity: 0.12 + index * 0.018,
            animateIn: index == visibleDays - 1,
          ),
        if (days > visibleDays)
          Container(
            width: 48,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Text(
              '+${days - visibleDays}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniFlameToken extends StatelessWidget {
  final Color color;
  final double scale;
  final double opacity;
  final bool animateIn;

  const _MiniFlameToken({
    required this.color,
    required this.scale,
    required this.opacity,
    this.animateIn = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: animateIn ? 0 : 1, end: 1),
      duration: animateIn ? const Duration(milliseconds: 720) : Duration.zero,
      curve: Curves.easeOutBack,
      builder: (context, progress, child) {
        final eased = progress.clamp(0.0, 1.0);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 18),
            child: Transform.scale(
              scale: scale * (0.72 + eased * 0.28),
              child: child,
            ),
          ),
        );
      },
      child: Container(
        width: 48,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.13),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _CuteFlameIcon(color: color, size: 34),
      ),
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
  bool fullScreen = false,
  bool showBackdrop = true,
}) {
  unawaited(HapticFeedback.mediumImpact());
  unawaited(SystemSound.play(SystemSoundType.alert));
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
      final dialogWidth = math.max(280.0, math.min(availableWidth, 620.0));
      final scaledChild = ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
        child: fullScreen
            ? SizedBox.expand(child: child)
            : SizedBox(
                width: dialogWidth,
                child: SingleChildScrollView(child: child),
              ),
      );
      return FadeTransition(
        opacity: curved,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showBackdrop)
              IgnorePointer(
                child: _FallingGemBackdrop(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            Material(
              color: Colors.transparent,
              child: SafeArea(
                child: Padding(
                  padding: fullScreen
                      ? EdgeInsets.zero
                      : const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: fullScreen ? scaledChild : Center(child: scaledChild),
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
              Transform.translate(
                offset: Offset(0, math.sin(progress * math.pi * 2) * 2.4),
                child: Transform.scale(
                  scale: pulse,
                  child: _CuteGemIcon(
                    color: widget.color,
                    size: 64,
                    glint: glint,
                  ),
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

class _CuteFlameIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _CuteFlameIcon({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _CuteFlamePainter(color: color)),
    );
  }
}

class _CuteFlamePainter extends CustomPainter {
  final Color color;

  const _CuteFlamePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shadowPaint = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.88),
        width: w * 0.70,
        height: h * 0.18,
      ),
      shadowPaint,
    );

    final outer = Path()
      ..moveTo(w * 0.50, h * 0.03)
      ..cubicTo(w * 0.34, h * 0.17, w * 0.42, h * 0.29, w * 0.25, h * 0.42)
      ..cubicTo(w * 0.03, h * 0.60, w * 0.10, h * 0.88, w * 0.37, h * 0.96)
      ..cubicTo(w * 0.42, h * 0.98, w * 0.47, h * 0.99, w * 0.50, h * 0.98)
      ..cubicTo(w * 0.56, h * 0.99, w * 0.64, h * 0.97, w * 0.71, h * 0.93)
      ..cubicTo(w * 0.96, h * 0.80, w * 0.99, h * 0.57, w * 0.76, h * 0.40)
      ..cubicTo(w * 0.61, h * 0.29, w * 0.68, h * 0.15, w * 0.50, h * 0.03)
      ..close();
    final outerShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        const Color(0xFFFFF1A6),
        Color.lerp(const Color(0xFFFFB703), color, 0.34)!,
        color,
        const Color(0xFFC2410C),
      ],
      stops: const <double>[0, 0.30, 0.70, 1],
    ).createShader(Offset.zero & size);
    canvas.drawPath(outer, Paint()..shader = outerShader);

    final leftLobe = Path()
      ..moveTo(w * 0.34, h * 0.26)
      ..cubicTo(w * 0.19, h * 0.39, w * 0.16, h * 0.57, w * 0.28, h * 0.72)
      ..cubicTo(w * 0.36, h * 0.82, w * 0.49, h * 0.78, w * 0.43, h * 0.60)
      ..cubicTo(w * 0.38, h * 0.47, w * 0.45, h * 0.38, w * 0.34, h * 0.26)
      ..close();
    canvas.drawPath(
      leftLobe,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.34),
            const Color(0xFFFFD166).withValues(alpha: 0.72),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );

    final rightLobe = Path()
      ..moveTo(w * 0.66, h * 0.25)
      ..cubicTo(w * 0.79, h * 0.38, w * 0.86, h * 0.57, w * 0.73, h * 0.74)
      ..cubicTo(w * 0.64, h * 0.84, w * 0.51, h * 0.78, w * 0.59, h * 0.59)
      ..cubicTo(w * 0.64, h * 0.47, w * 0.57, h * 0.37, w * 0.66, h * 0.25)
      ..close();
    canvas.drawPath(
      rightLobe,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.26),
            Color.lerp(
              const Color(0xFFFFB703),
              color,
              0.20,
            )!.withValues(alpha: 0.58),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w * 0.035)
      ..color = Colors.white.withValues(alpha: 0.42)
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(outer, rimPaint);

    final inner = Path()
      ..moveTo(w * 0.54, h * 0.24)
      ..cubicTo(w * 0.41, h * 0.40, w * 0.51, h * 0.51, w * 0.38, h * 0.62)
      ..cubicTo(w * 0.22, h * 0.76, w * 0.34, h * 0.92, w * 0.53, h * 0.90)
      ..cubicTo(w * 0.75, h * 0.88, w * 0.82, h * 0.72, w * 0.64, h * 0.56)
      ..cubicTo(w * 0.55, h * 0.47, w * 0.64, h * 0.36, w * 0.54, h * 0.24)
      ..close();
    canvas.drawPath(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.96),
            const Color(0xFFFFD166),
            const Color(0xFFFF8A2A),
          ],
        ).createShader(Offset.zero & size),
    );

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.46)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.0, w * 0.035);
    canvas.drawLine(
      Offset(w * 0.36, h * 0.33),
      Offset(w * 0.26, h * 0.54),
      highlight,
    );
    canvas.drawLine(
      Offset(w * 0.69, h * 0.48),
      Offset(w * 0.77, h * 0.62),
      highlight..color = Colors.white.withValues(alpha: 0.30),
    );
  }

  @override
  bool shouldRepaint(covariant _CuteFlamePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _CuteGemIcon extends StatelessWidget {
  final Color color;
  final double size;
  final double glint;

  const _CuteGemIcon({
    required this.color,
    required this.size,
    required this.glint,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _CuteGemPainter(color: color, glint: glint),
      ),
    );
  }
}

class _CuteGemPainter extends CustomPainter {
  final Color color;
  final double glint;

  const _CuteGemPainter({required this.color, required this.glint});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shadowPaint = Paint()
      ..color = const Color(0x40000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.86),
        width: w * 0.86,
        height: h * 0.22,
      ),
      shadowPaint,
    );

    final top = Offset(w * 0.50, h * 0.04);
    final shoulderLeft = Offset(w * 0.22, h * 0.14);
    final shoulderRight = Offset(w * 0.78, h * 0.14);
    final upperLeft = Offset(w * 0.05, h * 0.38);
    final upperRight = Offset(w * 0.95, h * 0.38);
    final bottom = Offset(w * 0.50, h * 0.95);
    final center = Offset(w * 0.50, h * 0.45);
    final leftFacet = Path()
      ..moveTo(shoulderLeft.dx, shoulderLeft.dy)
      ..lineTo(shoulderLeft.dx, shoulderLeft.dy)
      ..lineTo(upperLeft.dx, upperLeft.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    final rightFacet = Path()
      ..moveTo(shoulderRight.dx, shoulderRight.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(upperRight.dx, upperRight.dy)
      ..lineTo(shoulderRight.dx, shoulderRight.dy)
      ..close();
    final topFacet = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(shoulderRight.dx, shoulderRight.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(shoulderLeft.dx, shoulderLeft.dy)
      ..close();
    final lowerLeftFacet = Path()
      ..moveTo(upperLeft.dx, upperLeft.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    final lowerRightFacet = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(upperRight.dx, upperRight.dy)
      ..close();
    final outline = Path()
      ..moveTo(top.dx, top.dy)
      ..cubicTo(
        w * 0.58,
        h * 0.05,
        w * 0.70,
        h * 0.08,
        shoulderRight.dx,
        shoulderRight.dy,
      )
      ..quadraticBezierTo(w * 0.93, h * 0.22, upperRight.dx, upperRight.dy)
      ..cubicTo(w * 0.99, h * 0.55, w * 0.79, h * 0.86, bottom.dx, bottom.dy)
      ..cubicTo(
        w * 0.22,
        h * 0.86,
        w * 0.01,
        h * 0.55,
        upperLeft.dx,
        upperLeft.dy,
      )
      ..quadraticBezierTo(w * 0.07, h * 0.22, shoulderLeft.dx, shoulderLeft.dy)
      ..cubicTo(w * 0.30, h * 0.08, w * 0.42, h * 0.05, top.dx, top.dy)
      ..close();

    canvas.drawPath(
      outline,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(Colors.white, color, 0.18)!,
            color,
            Color.lerp(Colors.black, color, 0.70)!,
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.save();
    canvas.clipPath(outline);
    canvas.drawPath(
      topFacet,
      Paint()..color = Color.lerp(Colors.white, color, 0.12)!,
    );
    canvas.drawPath(
      leftFacet,
      Paint()..color = Color.lerp(Colors.white, color, 0.24)!,
    );
    canvas.drawPath(
      rightFacet,
      Paint()..color = Color.lerp(Colors.white, color, 0.34)!,
    );
    canvas.drawPath(
      lowerLeftFacet,
      Paint()..color = Color.lerp(Colors.black, color, 0.78)!,
    );
    canvas.drawPath(
      lowerRightFacet,
      Paint()..color = Color.lerp(Colors.black, color, 0.64)!,
    );
    canvas.drawPath(
      Path()
        ..moveTo(shoulderLeft.dx, shoulderLeft.dy)
        ..lineTo(center.dx, center.dy)
        ..lineTo(shoulderRight.dx, shoulderRight.dy)
        ..moveTo(upperLeft.dx, upperLeft.dy)
        ..lineTo(center.dx, center.dy)
        ..lineTo(upperRight.dx, upperRight.dy)
        ..moveTo(center.dx, center.dy)
        ..lineTo(bottom.dx, bottom.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, w * 0.020)
        ..color = Colors.white.withValues(alpha: 0.38),
    );
    canvas.restore();
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, w * 0.035)
        ..color = Colors.white.withValues(alpha: 0.50 + glint * 0.22),
    );

    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.38 + glint * 0.32);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.23, h * 0.22, w * 0.28, h * 0.08),
        Radius.circular(w * 0.06),
      ),
      shinePaint,
    );
    canvas.drawCircle(
      Offset(w * 0.68, h * 0.23),
      w * (0.038 + glint * 0.020),
      shinePaint,
    );
    canvas.drawCircle(
      Offset(w * 0.36, h * 0.17),
      w * (0.024 + glint * 0.012),
      shinePaint..color = Colors.white.withValues(alpha: 0.46),
    );
    final glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.34 + glint * 0.34)
      ..strokeWidth = math.max(1.0, w * 0.018)
      ..strokeCap = StrokeCap.round;
    final glintCenter = Offset(w * 0.73, h * 0.36);
    canvas.drawLine(
      Offset(glintCenter.dx - w * 0.07, glintCenter.dy),
      Offset(glintCenter.dx + w * 0.07, glintCenter.dy),
      glintPaint,
    );
    canvas.drawLine(
      Offset(glintCenter.dx, glintCenter.dy - h * 0.07),
      Offset(glintCenter.dx, glintCenter.dy + h * 0.07),
      glintPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CuteGemPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.glint != glint;
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
      child: _CuteGemIcon(color: color, size: 30, glint: 0.54),
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
