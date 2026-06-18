import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../widgets/rinzy_mascot.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onStart;

  const WelcomeScreen({super.key, required this.onStart});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sections = _buildSections(l10n);
    final selected = sections[_selectedIndex];
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 700;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      compact ? 14 : 22,
                      22,
                      18,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _WelcomeHero(l10n: l10n, compact: compact),
                            SizedBox(height: compact ? 14 : 18),
                            _WelcomeSectionSelector(
                              sections: sections,
                              selectedIndex: _selectedIndex,
                              onSelected: (index) {
                                setState(() => _selectedIndex = index);
                              },
                            ),
                            const SizedBox(height: 14),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: _WelcomeFocusPanel(
                                key: ValueKey(selected.id),
                                section: selected,
                                l10n: l10n,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.welcomeGuideNextTabHint,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _WelcomeStartBar(l10n: l10n, onStart: widget.onStart),
          ],
        ),
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  final AppLocalizations l10n;
  final bool compact;

  const _WelcomeHero({required this.l10n, required this.compact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, compact ? 18 : 22, 20, 20),
        child: Column(
          children: [
            Container(
              width: compact ? 92 : 108,
              height: compact ? 92 : 108,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surface,
                shape: BoxShape.circle,
                border:
                    Border.all(color: scheme.primary.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: RinzyMascot(size: compact ? 72 : 84, progress: 0.44),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.appTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.welcomeGuideTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.welcomeGuideIntro,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                height: 1.42,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeSectionSelector extends StatelessWidget {
  final List<_WelcomeSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _WelcomeSectionSelector({
    required this.sections,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final section = sections[index];
          return _WelcomeSectionButton(
            key: ValueKey('welcome-section-${section.id}'),
            section: section,
            selected: index == selectedIndex,
            onTap: () => onSelected(index),
          );
        },
      ),
    );
  }
}

class _WelcomeSectionButton extends StatelessWidget {
  final _WelcomeSection section;
  final bool selected;
  final VoidCallback onTap;

  const _WelcomeSectionButton({
    super.key,
    required this.section,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest.withValues(alpha: 0.44),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                section.icon,
                size: 18,
                color: selected ? scheme.onPrimaryContainer : scheme.primary,
              ),
              const SizedBox(width: 7),
              Text(
                section.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color:
                      selected ? scheme.onPrimaryContainer : scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeFocusPanel extends StatelessWidget {
  final _WelcomeSection section;
  final AppLocalizations l10n;

  const _WelcomeFocusPanel({
    super.key,
    required this.section,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(section.icon, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.welcomeGuidePreviewLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              section.overview,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                height: 1.42,
              ),
            ),
            const SizedBox(height: 16),
            _PrimaryCoachMark(step: section.steps.first, l10n: l10n),
            const SizedBox(height: 16),
            Text(
              l10n.welcomeGuideSectionFlow,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            for (var index = 0; index < section.steps.length; index += 1) ...[
              _WelcomeStepRow(number: index + 1, step: section.steps[index]),
              if (index != section.steps.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrimaryCoachMark extends StatelessWidget {
  final _WelcomeStep step;
  final AppLocalizations l10n;

  const _PrimaryCoachMark({required this.step, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.touch_app_rounded, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.welcomeGuideCoachMarkLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    step.actionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Icon(step.icon, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

class _WelcomeStepRow extends StatelessWidget {
  final int number;
  final _WelcomeStep step;

  const _WelcomeStepRow({required this.number, required this.step});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Text(
            '$number',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(step.icon, size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      step.actionLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                step.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WelcomeStartBar extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onStart;

  const _WelcomeStartBar({required this.l10n, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('welcome-start-button'),
                onPressed: onStart,
                icon: const Icon(Icons.arrow_forward_rounded),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                label: Text(l10n.welcomeGuidePrimaryAction),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeSection {
  final String id;
  final IconData icon;
  final String title;
  final String overview;
  final List<_WelcomeStep> steps;

  const _WelcomeSection({
    required this.id,
    required this.icon,
    required this.title,
    required this.overview,
    required this.steps,
  });
}

class _WelcomeStep {
  final IconData icon;
  final String actionLabel;
  final String description;

  const _WelcomeStep({
    required this.icon,
    required this.actionLabel,
    required this.description,
  });
}

List<_WelcomeSection> _buildSections(AppLocalizations l10n) {
  return <_WelcomeSection>[
    _WelcomeSection(
      id: 'home',
      icon: Icons.home_outlined,
      title: l10n.tabHome,
      overview: l10n.welcomeHomeOverview,
      steps: [
        _WelcomeStep(
          icon: Icons.today_outlined,
          actionLabel: l10n.guideActionToday,
          description: l10n.welcomeHomeStepToday,
        ),
        _WelcomeStep(
          icon: Icons.rice_bowl_outlined,
          actionLabel: l10n.guideActionMeal,
          description: l10n.welcomeHomeStepMeal,
        ),
        _WelcomeStep(
          icon: Icons.bar_chart_outlined,
          actionLabel: l10n.homePriorityStatsAction,
          description: l10n.welcomeHomeStepStats,
        ),
      ],
    ),
    _WelcomeSection(
      id: 'logs',
      icon: Icons.list_alt_outlined,
      title: l10n.tabLogs,
      overview: l10n.welcomeLogsOverview,
      steps: [
        _WelcomeStep(
          icon: Icons.add_circle_outline,
          actionLabel: l10n.addEntry,
          description: l10n.welcomeLogsStepAdd,
        ),
        _WelcomeStep(
          icon: Icons.developer_board_outlined,
          actionLabel: l10n.homePriorityBoardAction,
          description: l10n.welcomeLogsStepBoard,
        ),
        _WelcomeStep(
          icon: Icons.view_agenda_outlined,
          actionLabel: l10n.guideActionCardList,
          description: l10n.welcomeLogsStepReview,
        ),
      ],
    ),
    _WelcomeSection(
      id: 'calendar',
      icon: Icons.calendar_month_outlined,
      title: l10n.tabCalendar,
      overview: l10n.welcomeCalendarOverview,
      steps: [
        _WelcomeStep(
          icon: Icons.touch_app_outlined,
          actionLabel: l10n.guideActionSelectDate,
          description: l10n.welcomeCalendarStepDate,
        ),
        _WelcomeStep(
          icon: Icons.add,
          actionLabel: l10n.guideActionPlus,
          description: l10n.welcomeCalendarStepPlus,
        ),
        _WelcomeStep(
          icon: Icons.rice_bowl_outlined,
          actionLabel: l10n.guideActionMeal,
          description: l10n.welcomeCalendarStepMeal,
        ),
      ],
    ),
    _WelcomeSection(
      id: 'stats',
      icon: Icons.bar_chart_outlined,
      title: l10n.tabStats,
      overview: l10n.welcomeStatsOverview,
      steps: [
        _WelcomeStep(
          icon: Icons.date_range_outlined,
          actionLabel: l10n.guideActionPeriod,
          description: l10n.welcomeStatsStepPeriod,
        ),
        _WelcomeStep(
          icon: Icons.stacked_line_chart,
          actionLabel: l10n.guideActionBenchmark,
          description: l10n.welcomeStatsStepAverage,
        ),
        _WelcomeStep(
          icon: Icons.flag_outlined,
          actionLabel: l10n.guideActionWeakPoint,
          description: l10n.welcomeStatsStepFocus,
        ),
      ],
    ),
    _WelcomeSection(
      id: 'challenge',
      icon: Icons.flag_outlined,
      title: l10n.challengeTitle,
      overview: l10n.welcomeChallengeOverview,
      steps: [
        _WelcomeStep(
          icon: Icons.flag_circle_outlined,
          actionLabel: l10n.welcomeChallengeActionStart,
          description: l10n.welcomeChallengeStepStart,
        ),
        _WelcomeStep(
          icon: Icons.touch_app_outlined,
          actionLabel: l10n.welcomeChallengeActionMission,
          description: l10n.welcomeChallengeStepMission,
        ),
        _WelcomeStep(
          icon: Icons.star_rounded,
          actionLabel: l10n.welcomeChallengeActionReward,
          description: l10n.welcomeChallengeStepReward,
        ),
      ],
    ),
    _WelcomeSection(
      id: 'diary',
      icon: Icons.auto_stories_outlined,
      title: l10n.tabDiary,
      overview: l10n.welcomeDiaryOverview,
      steps: [
        _WelcomeStep(
          icon: Icons.today_outlined,
          actionLabel: l10n.guideActionOpenToday,
          description: l10n.welcomeDiaryStepToday,
        ),
        _WelcomeStep(
          icon: Icons.sticky_note_2_outlined,
          actionLabel: l10n.guideActionRecordSticker,
          description: l10n.welcomeDiaryStepSticker,
        ),
        _WelcomeStep(
          icon: Icons.save_outlined,
          actionLabel: l10n.guideActionSaveDiary,
          description: l10n.welcomeDiaryStepSave,
        ),
      ],
    ),
  ];
}
