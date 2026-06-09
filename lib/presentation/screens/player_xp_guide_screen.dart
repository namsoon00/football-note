import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../application/player_level_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';

class PlayerXpGuideScreen extends StatelessWidget {
  final OptionRepository optionRepository;

  const PlayerXpGuideScreen({super.key, required this.optionRepository});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final levelState = PlayerLevelService(optionRepository).loadState();
    final sections = <_XpGuideSection>[
      _XpGuideSection(
        title: l10n.playerXpGuideLoggingTitle,
        subtitle: l10n.playerXpGuideLoggingSubtitle,
        items: [
          _XpGuideItem(
            icon: Icons.edit_note_outlined,
            title: l10n.playerXpGuideTrainingLogSaved,
            xpLabel: '+${PlayerLevelService.trainingLogSavedXp} XP',
          ),
          _XpGuideItem(
            icon: Icons.wb_sunny_outlined,
            title: l10n.playerXpGuideFirstDailyLog,
            xpLabel: '+${PlayerLevelService.firstDailyTrainingLogXp} XP',
          ),
          _XpGuideItem(
            icon: Icons.event_available_outlined,
            title: l10n.playerXpGuidePlannedDayComplete,
            xpLabel: '+${PlayerLevelService.plannedTrainingDayXp} XP',
          ),
          _XpGuideItem(
            icon: Icons.sports_soccer_outlined,
            title: l10n.playerXpGuideLiftingRecorded,
            xpLabel: '+${PlayerLevelService.conditioningRecordedXp} XP',
          ),
          _XpGuideItem(
            icon: Icons.fitness_center_outlined,
            title: l10n.playerXpGuideJumpRopeRecorded,
            xpLabel: '+${PlayerLevelService.conditioningRecordedXp} XP',
          ),
          _XpGuideItem(
            icon: Icons.task_alt_outlined,
            title: l10n.playerXpGuideTrainingRoutineComplete,
            xpLabel: '+${PlayerLevelService.routineCompleteXp} XP',
          ),
          _XpGuideItem(
            icon: Icons.remove_circle_outline,
            title: l10n.playerXpGuideMissingConditioning,
            xpLabel: l10n.playerXpGuideMissingConditioningXp,
          ),
        ],
      ),
      _XpGuideSection(
        title: l10n.playerXpGuideStreakTitle,
        subtitle: l10n.playerXpGuideStreakSubtitle,
        items: [
          _XpGuideItem(
            icon: Icons.local_fire_department_outlined,
            title: l10n.playerXpGuideStreakMilestones,
            xpLabel:
                '+${PlayerLevelService.streak3DaysXp} XP / +${PlayerLevelService.streak7DaysXp} XP',
          ),
          _XpGuideItem(
            icon: Icons.bolt_outlined,
            title: l10n.playerXpGuideStreakDailyBonus,
            xpLabel:
                '+${PlayerLevelService.streakDaily2To3Xp} XP / +${PlayerLevelService.streakDaily4To6Xp} XP / +${PlayerLevelService.streakDaily7PlusXp} XP',
          ),
          _XpGuideItem(
            icon: Icons.bar_chart_outlined,
            title: l10n.playerXpGuideWeeklyBonus,
            xpLabel:
                '+${PlayerLevelService.weekly3LogsXp} XP / +${PlayerLevelService.weekly5LogsXp} XP',
          ),
        ],
      ),
      _XpGuideSection(
        title: l10n.playerXpGuideActivityTitle,
        subtitle: l10n.playerXpGuideActivitySubtitle,
        items: [
          _XpGuideItem(
            icon: Icons.event_note_outlined,
            title: l10n.playerXpGuidePlanCreated,
            xpLabel: '+6 XP',
          ),
          _XpGuideItem(
            icon: Icons.sports_soccer_outlined,
            title: l10n.playerXpGuideMatchLogged,
            xpLabel:
                '+${PlayerLevelService.matchLogSavedXp} XP / +${PlayerLevelService.matchDetailRecordedXp} XP',
          ),
          _XpGuideItem(
            icon: Icons.draw_outlined,
            title: l10n.playerXpGuideTrainingSketchSaved,
            xpLabel: l10n.playerXpGuideTrainingSketchSavedXp,
          ),
          _XpGuideItem(
            icon: Icons.menu_book_outlined,
            title: l10n.playerXpGuideDiaryCreated,
            xpLabel: '+3 XP',
          ),
          _XpGuideItem(
            icon: Icons.quiz_outlined,
            title: l10n.playerXpGuideQuizComplete,
            xpLabel: l10n.playerXpGuideQuizCompleteXp,
          ),
          _XpGuideItem(
            icon: Icons.rice_bowl_outlined,
            title: l10n.playerXpGuideMealTwoPlus,
            xpLabel: '+3 XP',
          ),
          _XpGuideItem(
            icon: Icons.restaurant_outlined,
            title: l10n.playerXpGuideMealFull,
            xpLabel: '+8 XP / +10 XP',
          ),
          _XpGuideItem(
            icon: Icons.task_alt_outlined,
            title: l10n.playerXpGuideDailyTasksComplete,
            xpLabel: '+${PlayerLevelService.dailyTaskCompletionXp} XP',
          ),
          _XpGuideItem(
            icon: Icons.speed_outlined,
            title: l10n.playerXpGuideDailyCap,
            xpLabel: '${PlayerLevelService.dailyPositiveXpCap} XP',
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.playerXpGuideTitle)),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _XpGuideHeroCard(l10n: l10n, levelState: levelState),
              const SizedBox(height: 12),
              for (final section in sections) ...[
                _XpGuideSectionCard(section: section),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _XpGuideHeroCard extends StatelessWidget {
  final AppLocalizations l10n;
  final PlayerLevelState levelState;

  const _XpGuideHeroCard({required this.l10n, required this.levelState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.playerXpGuideHeroLevel(levelState.level),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            levelState.isMaxLevel
                ? l10n.playerXpGuideHeroMax(
                    PlayerLevelService.maxLevelMasterySpan,
                    levelState.xpToNextMasteryStar,
                  )
                : l10n.playerXpGuideHeroBody(levelState.xpToNextLevel),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: levelState.progress,
              backgroundColor: theme.colorScheme.surface.withValues(
                alpha: 0.35,
              ),
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _XpGuideSectionCard extends StatelessWidget {
  final _XpGuideSection section;

  const _XpGuideSectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            section.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(section.subtitle, style: theme.textTheme.bodySmall),
          children: [
            for (final item in section.items) ...[
              _XpGuideRow(item: item),
              if (item != section.items.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _XpGuideRow extends StatelessWidget {
  final _XpGuideItem item;

  const _XpGuideRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            item.xpLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _XpGuideSection {
  final String title;
  final String subtitle;
  final List<_XpGuideItem> items;

  const _XpGuideSection({
    required this.title,
    required this.subtitle,
    required this.items,
  });
}

class _XpGuideItem {
  final IconData icon;
  final String title;
  final String xpLabel;

  const _XpGuideItem({
    required this.icon,
    required this.title,
    required this.xpLabel,
  });
}
