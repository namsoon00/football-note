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
          _CuteGemIcon(color: spec.colors.first, size: 150, glint: 0.92),
          const SizedBox(height: 12),
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
                    backgroundColor: Colors.black.withValues(alpha: 0.14),
                    foregroundColor: foreground,
                    disabledForegroundColor: foreground.withValues(alpha: 0.54),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.62),
                    ),
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
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
                  opacity: theme.brightness == Brightness.dark ? 0.34 : 0.28,
                  child: _FallingGemBackdrop(
                    color: accent,
                    count: 44,
                    speed: 1.38,
                    gemScale: 1.18,
                  ),
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
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
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
          Positioned.fill(
            child: IgnorePointer(
              child: _GemCascadeLayer(color: color, compact: compact),
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
      ..shader = RadialGradient(
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

class _GemCascadeLayer extends StatefulWidget {
  final Color color;
  final bool compact;

  const _GemCascadeLayer({required this.color, required this.compact});

  @override
  State<_GemCascadeLayer> createState() => _GemCascadeLayerState();
}

class _GemCascadeLayerState extends State<_GemCascadeLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
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
          painter: _GemCascadePainter(
            progress: _controller.value,
            compact: widget.compact,
            colors: <Color>[
              widget.color,
              Color.lerp(widget.color, scheme.secondary, 0.42)!,
              const Color(0xFF38BDF8),
              const Color(0xFFFBBF24),
            ],
          ),
        );
      },
    );
  }
}

class _GemCascadePainter extends CustomPainter {
  final double progress;
  final bool compact;
  final List<Color> colors;

  const _GemCascadePainter({
    required this.progress,
    required this.compact,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final count = compact ? 24 : 32;
    for (var index = 0; index < count; index += 1) {
      final seed = ((index * 53) % 100) / 100.0;
      final lane = ((index * 17) % 9) / 8.0;
      final fall = (progress * 1.85 + seed * 1.21) % 1.0;
      final wave = math.sin((progress * math.pi * 4.2) + index * 0.74);
      final x = size.width * (0.10 + lane * 0.80) + wave * size.width * 0.035;
      final y = -size.height * 0.18 + fall * size.height * 0.92;
      final fadeIn = (fall / 0.14).clamp(0.0, 1.0);
      final fadeOut = ((0.86 - fall) / 0.18).clamp(0.0, 1.0);
      final opacity = math.min(fadeIn, fadeOut) * (0.24 + (index % 4) * 0.08);
      if (opacity <= 0) continue;

      final gemSize = (7.5 + (index % 5) * 2.8) * (compact ? 0.88 : 1.0);
      final center = Offset(x, y);
      final color = colors[index % colors.length];
      final halfWidth = gemSize * 0.58;
      final halfHeight = gemSize * 0.78;
      final rotation = progress * math.pi * 2.2 + seed * math.pi * 2;
      final path = Path()
        ..moveTo(0, -halfHeight)
        ..lineTo(halfWidth, 0)
        ..lineTo(0, halfHeight)
        ..lineTo(-halfWidth, 0)
        ..close();

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      canvas.drawPath(
        path.shift(const Offset(0, 1.3)),
        Paint()..color = Colors.black.withValues(alpha: opacity * 0.22),
      );
      canvas.drawPath(
        path,
        Paint()..color = color.withValues(alpha: opacity),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Colors.white.withValues(alpha: opacity * 0.72),
      );
      canvas.drawLine(
        Offset(-halfWidth * 0.42, -halfHeight * 0.12),
        Offset(halfWidth * 0.34, -halfHeight * 0.48),
        Paint()
          ..color = Colors.white.withValues(alpha: opacity)
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _GemCascadePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.compact != compact ||
        oldDelegate.colors != colors;
  }
}

enum _CelebrationCharacter { gem, flame }

const _recordRewardGemAsset = 'assets/images/record_reward_gem_character.png';
const _passionFlameAsset = 'assets/images/passion_flame_character.png';

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
    return SizedBox.square(
      dimension: size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final phase = _controller.value;
          final bounce = math.sin(phase * math.pi * 2);
          final shimmer = (math.sin(phase * math.pi * 2.0) + 1) / 2;
          final lift = math.max(0.0, bounce) * size * 0.025;
          final isFlame = widget.character == _CelebrationCharacter.flame;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        widget.color.withValues(alpha: 0.18),
                        widget.color.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.58, 1],
                    ),
                  ),
                ),
              ),
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
                left: size * 0.08,
                top: size * (0.20 + shimmer * 0.018),
                child: Transform.rotate(
                  angle: -0.22,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Color.lerp(widget.color, Colors.white, 0.18)!
                        .withValues(alpha: 0.76),
                    size: size * 0.13,
                  ),
                ),
              ),
              Positioned(
                right: size * 0.09,
                top: size * (0.32 - shimmer * 0.025),
                child: Transform.rotate(
                  angle: 0.26,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Color.lerp(
                      widget.color,
                      const Color(0xFF38BDF8),
                      widget.character == _CelebrationCharacter.gem ? 0.34 : 0,
                    )!
                        .withValues(alpha: 0.72),
                    size: size * 0.10,
                  ),
                ),
              ),
              Positioned(
                left: size * 0.19,
                bottom: size * (0.18 + shimmer * 0.018),
                child: Transform.rotate(
                  angle: 0.18,
                  child: Icon(
                    Icons.star_rounded,
                    color: widget.color.withValues(alpha: 0.64),
                    size: size * 0.08,
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -lift),
                child: Transform.rotate(
                  angle: isFlame ? 0 : bounce * 0.035,
                  child: isFlame
                      ? _BurningFlameIcon(
                          color: widget.color,
                          size: size * 0.92,
                          phase: phase,
                        )
                      : _CuteGemIcon(
                          color: widget.color,
                          size: size * 0.86,
                          glint: 0.82 + math.max(0.0, bounce) * 0.12,
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
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
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
  final int count;
  final double speed;
  final double gemScale;

  const _FallingGemBackdrop({
    required this.color,
    this.count = 18,
    this.speed = 1,
    this.gemScale = 1,
  });

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
            count: widget.count,
            speed: widget.speed,
            gemScale: widget.gemScale,
          ),
        );
      },
    );
  }
}

class _FallingGemPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final int count;
  final double speed;
  final double gemScale;

  const _FallingGemPainter({
    required this.progress,
    required this.colors,
    required this.count,
    required this.speed,
    required this.gemScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    for (var index = 0; index < count; index++) {
      final seed = ((index * 37) % 100) / 100.0;
      final depth = 0.72 + ((index % 6) * 0.07);
      final fall = (progress * speed + seed * 1.37) % 1.0;
      final sway =
          math.sin((progress * math.pi * 2 * speed) + index) * 24 * depth;
      final x = ((seed * size.width) + sway).clamp(8.0, size.width - 8);
      final y = (fall * (size.height + 140)) - 70;
      final gemSize = (9.0 + ((index % 5) * 3.6)) * gemScale * depth;
      final color = colors[index % colors.length];
      final opacity = (0.24 + ((index % 5) * 0.055)) * depth;
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
    return oldDelegate.progress != progress ||
        oldDelegate.colors != colors ||
        oldDelegate.count != count ||
        oldDelegate.speed != speed ||
        oldDelegate.gemScale != gemScale;
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

class _BurningFlameIcon extends StatelessWidget {
  final Color color;
  final double size;
  final double phase;

  const _BurningFlameIcon({
    required this.color,
    required this.size,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final flicker = (math.sin(phase * math.pi * 8.2) + 1) / 2;
    final slowBreath = (math.sin(phase * math.pi * 2.0) + 1) / 2;
    final innerFlicker = (math.sin((phase + 0.18) * math.pi * 11.6) + 1) / 2;
    final scaleX = 0.96 + flicker * 0.055 - innerFlicker * 0.018;
    final scaleY = 1.00 + slowBreath * 0.085 + flicker * 0.044;
    final lift = (slowBreath * 0.018 + flicker * 0.014) * size;
    final glow = 0.18 + slowBreath * 0.16 + flicker * 0.08;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _FlameEmberPainter(
                color: color,
                progress: phase,
                intensity: 1,
              ),
            ),
          ),
          Center(
            child: Transform.scale(
              scale: 1 + slowBreath * 0.08,
              child: Container(
                width: size * 0.68,
                height: size * 0.76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFF3B0).withValues(alpha: glow),
                      color.withValues(alpha: glow * 0.48),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.44, 1],
                  ),
                ),
              ),
            ),
          ),
          Transform(
            key: const ValueKey('burning-flame-body-transform'),
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..translateByDouble(0.0, -lift, 0.0, 1.0)
              ..scaleByDouble(scaleX, scaleY, 1.0, 1.0),
            child: _CuteFlameIcon(color: color, size: size * 0.92),
          ),
        ],
      ),
    );
  }
}

class _FlameEmberPainter extends CustomPainter {
  final Color color;
  final double progress;
  final double intensity;

  const _FlameEmberPainter({
    required this.color,
    required this.progress,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final emberCount = (18 * intensity).round().clamp(8, 24);
    for (var index = 0; index < emberCount; index += 1) {
      final seed = ((index * 41) % 100) / 100.0;
      final rise = (progress * (0.86 + (index % 5) * 0.11) + seed) % 1.0;
      final horizontalSeed = ((index * 29) % 100) / 100.0;
      final sway =
          math.sin(progress * math.pi * 5.4 + index * 0.86) * size.width * 0.05;
      final x = size.width * (0.22 + horizontalSeed * 0.56) + sway;
      final y = size.height * (0.86 - rise * 0.78);
      final fadeIn = (rise / 0.18).clamp(0.0, 1.0);
      final fadeOut = ((1 - rise) / 0.28).clamp(0.0, 1.0);
      final opacity =
          math.min(fadeIn, fadeOut) * (0.26 + (index % 4) * 0.06) * intensity;
      if (opacity <= 0) continue;

      final emberSize = size.shortestSide * (0.016 + (index % 4) * 0.004);
      final emberColor = Color.lerp(
        color,
        index.isEven ? const Color(0xFFFFF7AD) : const Color(0xFFFFB020),
        0.48,
      )!;
      final center = Offset(x, y);
      final path = Path()
        ..moveTo(center.dx, center.dy - emberSize * 1.45)
        ..cubicTo(
          center.dx + emberSize,
          center.dy - emberSize * 0.64,
          center.dx + emberSize * 0.78,
          center.dy + emberSize * 0.78,
          center.dx,
          center.dy + emberSize * 1.12,
        )
        ..cubicTo(
          center.dx - emberSize * 0.82,
          center.dy + emberSize * 0.74,
          center.dx - emberSize,
          center.dy - emberSize * 0.62,
          center.dx,
          center.dy - emberSize * 1.45,
        )
        ..close();

      canvas.drawCircle(
        center,
        emberSize * 2.1,
        Paint()..color = emberColor.withValues(alpha: opacity * 0.16),
      );
      canvas.drawPath(
        path,
        Paint()..color = emberColor.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FlameEmberPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.intensity != intensity;
  }
}

class _CuteFlameIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _CuteFlameIcon({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return _StorybookCelebrationImage(
      assetName: _passionFlameAsset,
      glowColor: color,
      glowStrength: 0.13,
      size: size,
    );
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
    return _StorybookCelebrationImage(
      assetName: _recordRewardGemAsset,
      glowColor: color,
      glowStrength: 0.07 + glint.clamp(0.0, 1.0) * 0.08,
      size: size,
    );
  }
}

class _StorybookCelebrationImage extends StatelessWidget {
  final String assetName;
  final Color glowColor;
  final double glowStrength;
  final double size;

  const _StorybookCelebrationImage({
    required this.assetName,
    required this.glowColor,
    required this.glowStrength,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final glow = glowStrength.clamp(0.0, 0.24);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    glowColor.withValues(alpha: glow),
                    glowColor.withValues(alpha: glow * 0.34),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.56, 1],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(size * 0.015),
              child: Image.asset(
                assetName,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              ),
            ),
          ],
        ),
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
