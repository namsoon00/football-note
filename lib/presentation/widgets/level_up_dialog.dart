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
    final gradientStart = Color.alphaBlend(
      spec.color.withValues(alpha: 0.18),
      scheme.surface,
    );
    final gradientEnd = Color.alphaBlend(
      scheme.tertiary.withValues(alpha: 0.16),
      scheme.surfaceContainerHighest,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: spec.color.withValues(alpha: 0.22)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactHeight = constraints.maxHeight < 620;
            final heroSize = math.min(
              constraints.maxWidth * 0.58,
              compactHeight ? 178.0 : 236.0,
            );
            return Stack(
              children: [
                Positioned.fill(child: _OrbitGemBackdrop(color: spec.color)),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    compactHeight ? 18 : 28,
                    20,
                    18,
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
                              constraints: const BoxConstraints(maxWidth: 540),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    spec.title,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: scheme.onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    spec.message,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w700,
                                          height: 1.35,
                                        ),
                                  ),
                                  SizedBox(height: compactHeight ? 16 : 22),
                                  _OrbitGemCelebration(
                                    color: spec.color,
                                    size: heroSize,
                                  ),
                                  SizedBox(height: compactHeight ? 16 : 24),
                                  _XpHeroAmount(
                                    color: spec.color,
                                    label: l10n.trainingXpDialogRewardLabel,
                                    value: l10n.trainingXpDialogXp(
                                      award.gainedXp,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _LevelProgressStrip(
                                    progress: award.after.progress,
                                    foreground: spec.color,
                                    background: spec.color.withValues(
                                      alpha: 0.16,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    progressText,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _RewardStatCard(
                                          label:
                                              l10n.trainingXpDialogTotalLabel,
                                          value: l10n
                                              .trainingXpDialogTotalValue(
                                                award.after.totalXp,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _RewardStatCard(
                                          label:
                                              l10n.trainingXpDialogLevelLabel,
                                          value: l10n
                                              .trainingXpDialogLevelValue(
                                                award.after.level,
                                                l10n.playerLevelName(
                                                  award.after.level,
                                                ),
                                              ),
                                        ),
                                      ),
                                    ],
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
                          backgroundColor: spec.color,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const flame = Color(0xFFF97316);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.alphaBlend(flame.withValues(alpha: 0.18), scheme.surface),
              Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.14),
                scheme.surfaceContainerHighest,
              ),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: flame.withValues(alpha: 0.22)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactHeight = constraints.maxHeight < 620;
            return Stack(
              children: [
                const Positioned.fill(child: _WarmPulseBackdrop(color: flame)),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    compactHeight ? 18 : 24,
                    20,
                    18,
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
                                  SizedBox(
                                    height: compactHeight ? 126 : 164,
                                    child: const FittedBox(
                                      child: _FlameBurst(color: flame),
                                    ),
                                  ),
                                  SizedBox(height: compactHeight ? 16 : 22),
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: scheme.onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    message,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w700,
                                          height: 1.35,
                                        ),
                                  ),
                                  SizedBox(height: compactHeight ? 22 : 30),
                                  _StreakTrail(days: streakDays, color: flame),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.local_fire_department_rounded),
                        label: Text(l10n.trainingStreakCheerAction),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: flame,
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

class _XpHeroAmount extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _XpHeroAmount({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.12), scheme.surface),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _CuteGemIcon(color: color, size: 54, glint: 0.86),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.auto_awesome_rounded,
            color: color.withValues(alpha: 0.68),
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _RewardStatCard extends StatelessWidget {
  final String label;
  final String value;

  const _RewardStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
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

  const _MiniFlameToken({
    required this.color,
    required this.scale,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
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

class _OrbitGemCelebration extends StatefulWidget {
  final Color color;
  final double size;

  const _OrbitGemCelebration({required this.color, required this.size});

  @override
  State<_OrbitGemCelebration> createState() => _OrbitGemCelebrationState();
}

class _OrbitGemCelebrationState extends State<_OrbitGemCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _controller.value;
          final pulse = 1 + math.sin(progress * math.pi * 2) * 0.035;
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _OrbitGemPainter(
                    color: widget.color,
                    progress: progress,
                  ),
                ),
              ),
              Transform.scale(
                scale: pulse,
                child: _CuteGemIcon(
                  color: widget.color,
                  size: widget.size * 0.48,
                  glint: (math.sin((progress * math.pi * 2) + 0.8) + 1) / 2,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrbitGemPainter extends CustomPainter {
  final Color color;
  final double progress;

  const _OrbitGemPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * 0.36;
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 2.15,
        height: radius * 1.08,
      ),
      ringPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 1.18,
        height: radius * 2.10,
      ),
      ringPaint..color = color.withValues(alpha: 0.13),
    );

    for (var index = 0; index < 12; index += 1) {
      final angle = progress * math.pi * 2 + (index * math.pi * 2 / 12);
      final x =
          center.dx + math.cos(angle) * radius * (index.isEven ? 1.04 : 0.74);
      final y =
          center.dy + math.sin(angle) * radius * (index.isEven ? 0.46 : 0.92);
      final sizeFactor = 4.0 + (index % 3) * 1.6;
      final path = Path()
        ..moveTo(x, y - sizeFactor)
        ..lineTo(x + sizeFactor, y)
        ..lineTo(x, y + sizeFactor)
        ..lineTo(x - sizeFactor, y)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = color.withValues(alpha: 0.24 + (index % 4) * 0.06),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.36)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitGemPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}

class _OrbitGemBackdrop extends StatefulWidget {
  final Color color;

  const _OrbitGemBackdrop({required this.color});

  @override
  State<_OrbitGemBackdrop> createState() => _OrbitGemBackdropState();
}

class _OrbitGemBackdropState extends State<_OrbitGemBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _RibbonBackdropPainter(
            color: widget.color,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _WarmPulseBackdrop extends StatefulWidget {
  final Color color;

  const _WarmPulseBackdrop({required this.color});

  @override
  State<_WarmPulseBackdrop> createState() => _WarmPulseBackdropState();
}

class _WarmPulseBackdropState extends State<_WarmPulseBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _RibbonBackdropPainter(
            color: widget.color,
            progress: _controller.value,
            warm: true,
          ),
        );
      },
    );
  }
}

class _RibbonBackdropPainter extends CustomPainter {
  final Color color;
  final double progress;
  final bool warm;

  const _RibbonBackdropPainter({
    required this.color,
    required this.progress,
    this.warm = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final ribbonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 6; index += 1) {
      final offset = ((progress + index * 0.19) % 1.0) * size.width;
      final y = size.height * (0.16 + index * 0.14);
      final path = Path()
        ..moveTo(offset - size.width * 0.55, y)
        ..cubicTo(
          offset - size.width * 0.24,
          y - 48,
          offset + size.width * 0.08,
          y + 48,
          offset + size.width * 0.42,
          y - 12,
        );
      ribbonPaint
        ..strokeWidth = warm ? 16.0 - index : 10.0 - index * 0.7
        ..color = color.withValues(alpha: warm ? 0.08 : 0.065);
      canvas.drawPath(path, ribbonPaint);
    }

    final sparklePaint = Paint()..color = color.withValues(alpha: 0.20);
    for (var index = 0; index < 18; index += 1) {
      final seed = ((index * 29) % 101) / 101.0;
      final x = (seed * size.width + progress * 48) % size.width;
      final y = ((index * 41) % 100) / 100.0 * size.height;
      final radius = 1.8 + (index % 3);
      final center = Offset(x, y);
      canvas.drawLine(
        center.translate(-radius, 0),
        center.translate(radius, 0),
        sparklePaint..strokeWidth = 1.2,
      );
      canvas.drawLine(
        center.translate(0, -radius),
        center.translate(0, radius),
        sparklePaint..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RibbonBackdropPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.progress != progress ||
        oldDelegate.warm != warm;
  }
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
      width: 164,
      height: 126,
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
                  child: _CuteFlameIcon(color: widget.color, size: 88),
                ),
                Positioned(
                  top: 10 + math.sin(progress * math.pi * 2) * 2,
                  left: 42 + math.cos(progress * math.pi * 2) * 3,
                  child: Icon(
                    Icons.auto_awesome_rounded,
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
      ..shader =
          RadialGradient(
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
      final x =
          size.width * (0.22 + seed * 0.56) +
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
          )!.withValues(alpha: (1 - rise).clamp(0.0, 1.0) * 0.78),
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _CuteFlamePainter(color: color)),
          ),
          Positioned(
            top: size * 0.48,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FaceDot(size: size * 0.055),
                SizedBox(width: size * 0.13),
                _FaceDot(size: size * 0.055),
              ],
            ),
          ),
          Positioned(
            top: size * 0.59,
            child: Container(
              width: size * 0.16,
              height: size * 0.07,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF5A260A).withValues(alpha: 0.72),
                    width: size * 0.018,
                  ),
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
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
        center: Offset(w * 0.50, h * 0.86),
        width: w * 0.58,
        height: h * 0.16,
      ),
      shadowPaint,
    );

    final outer = Path()
      ..moveTo(w * 0.50, h * 0.05)
      ..cubicTo(w * 0.33, h * 0.20, w * 0.43, h * 0.34, w * 0.27, h * 0.47)
      ..cubicTo(w * 0.05, h * 0.66, w * 0.19, h * 0.96, w * 0.50, h * 0.96)
      ..cubicTo(w * 0.82, h * 0.96, w * 0.98, h * 0.68, w * 0.72, h * 0.43)
      ..cubicTo(w * 0.58, h * 0.30, w * 0.64, h * 0.18, w * 0.50, h * 0.05)
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

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w * 0.035)
      ..color = Colors.white.withValues(alpha: 0.42)
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(outer, rimPaint);

    final inner = Path()
      ..moveTo(w * 0.54, h * 0.28)
      ..cubicTo(w * 0.42, h * 0.42, w * 0.51, h * 0.52, w * 0.39, h * 0.62)
      ..cubicTo(w * 0.25, h * 0.74, w * 0.34, h * 0.90, w * 0.52, h * 0.90)
      ..cubicTo(w * 0.72, h * 0.89, w * 0.80, h * 0.73, w * 0.64, h * 0.58)
      ..cubicTo(w * 0.55, h * 0.49, w * 0.63, h * 0.40, w * 0.54, h * 0.28)
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
      Offset(w * 0.37, h * 0.35),
      Offset(w * 0.29, h * 0.50),
      highlight,
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CuteGemPainter(color: color, glint: glint),
            ),
          ),
          Positioned(
            top: size * 0.38,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FaceDot(size: size * 0.05),
                SizedBox(width: size * 0.14),
                _FaceDot(size: size * 0.05),
              ],
            ),
          ),
          Positioned(
            top: size * 0.49,
            child: Container(
              width: size * 0.15,
              height: size * 0.06,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.78),
                    width: size * 0.016,
                  ),
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            top: size * 0.46,
            left: size * 0.23,
            child: _GemCheek(size: size * 0.07),
          ),
          Positioned(
            top: size * 0.46,
            right: size * 0.23,
            child: _GemCheek(size: size * 0.07),
          ),
        ],
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
        center: Offset(w * 0.5, h * 0.84),
        width: w * 0.74,
        height: h * 0.20,
      ),
      shadowPaint,
    );

    final top = Offset(w * 0.50, h * 0.03);
    final shoulderLeft = Offset(w * 0.30, h * 0.15);
    final shoulderRight = Offset(w * 0.70, h * 0.15);
    final upperLeft = Offset(w * 0.11, h * 0.36);
    final upperRight = Offset(w * 0.89, h * 0.36);
    final bottom = Offset(w * 0.50, h * 0.96);
    final center = Offset(w * 0.50, h * 0.43);
    final leftFacet = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(shoulderLeft.dx, shoulderLeft.dy)
      ..lineTo(upperLeft.dx, upperLeft.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    final rightFacet = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(upperRight.dx, upperRight.dy)
      ..lineTo(shoulderRight.dx, shoulderRight.dy)
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
      ..lineTo(shoulderRight.dx, shoulderRight.dy)
      ..lineTo(upperRight.dx, upperRight.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(upperLeft.dx, upperLeft.dy)
      ..lineTo(shoulderLeft.dx, shoulderLeft.dy)
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
    canvas.drawPath(
      Path()
        ..moveTo(shoulderLeft.dx, shoulderLeft.dy)
        ..lineTo(center.dx, center.dy)
        ..lineTo(shoulderRight.dx, shoulderRight.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, w * 0.018)
        ..color = Colors.white.withValues(alpha: 0.34),
    );
    canvas.drawPath(
      leftFacet,
      Paint()..color = Color.lerp(Colors.white, color, 0.22)!,
    );
    canvas.drawPath(
      rightFacet,
      Paint()..color = Color.lerp(Colors.white, color, 0.38)!,
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
        Rect.fromLTWH(w * 0.28, h * 0.22, w * 0.22, h * 0.08),
        Radius.circular(w * 0.06),
      ),
      shinePaint,
    );
    canvas.drawCircle(
      Offset(w * 0.66, h * 0.24),
      w * (0.035 + glint * 0.018),
      shinePaint,
    );
    canvas.drawCircle(
      Offset(w * 0.36, h * 0.18),
      w * (0.024 + glint * 0.012),
      shinePaint..color = Colors.white.withValues(alpha: 0.46),
    );
  }

  @override
  bool shouldRepaint(covariant _CuteGemPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.glint != glint;
  }
}

class _FaceDot extends StatelessWidget {
  final double size;

  const _FaceDot({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF3A2A20).withValues(alpha: 0.78),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
      ),
    );
  }
}

class _GemCheek extends StatelessWidget {
  final double size;

  const _GemCheek({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.66,
      decoration: BoxDecoration(
        color: const Color(0xFFFFB6C8).withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(size),
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
