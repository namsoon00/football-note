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
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sections = _buildSections(l10n);
    final selected = sections[_selectedIndex];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.28),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RinzyWelcomeHeader(l10n: l10n),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(sections.length, (i) {
                      final section = sections[i];
                      return Padding(
                        padding: EdgeInsets.only(
                          right: i == sections.length - 1 ? 0 : 8,
                        ),
                        child: ChoiceChip(
                          selected: i == _selectedIndex,
                          avatar: Icon(section.icon, size: 16),
                          label: Text(section.title),
                          onSelected: (_) => setState(() => _selectedIndex = i),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _WelcomeSectionCard(
                      key: ValueKey(selected.id),
                      section: selected,
                      l10n: l10n,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    label: Text(l10n.welcomeGuidePrimaryAction),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RinzyWelcomeHeader extends StatelessWidget {
  final AppLocalizations l10n;

  const _RinzyWelcomeHeader({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RinzyMascot(size: 70, progress: 0.42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.welcomeGuideTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.welcomeGuideIntro,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
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

class _WelcomeSectionCard extends StatelessWidget {
  final _WelcomeSection section;
  final AppLocalizations l10n;

  const _WelcomeSectionCard({
    super.key,
    required this.section,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(section.icon, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _WelcomeScreenPreview(section: section, l10n: l10n),
          const SizedBox(height: 12),
          _CoachMarkBubble(
            title: l10n.welcomeGuideCoachMarkLabel,
            body: section.overview,
            step: section.steps.first,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.welcomeGuideSectionFlow,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: section.steps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _WelcomeStepTile(
                  number: index + 1,
                  step: section.steps[index],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: scheme.primary.withValues(alpha: 0.10),
            ),
            child: Text(
              l10n.welcomeGuideNextTabHint,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeScreenPreview extends StatelessWidget {
  final _WelcomeSection section;
  final AppLocalizations l10n;

  const _WelcomeScreenPreview({required this.section, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primaryStep = section.steps.first;
    final secondarySteps = section.steps.skip(1).toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(section.icon, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.welcomeGuidePreviewLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  section.title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PreviewLine(
                        icon: Icons.radio_button_unchecked,
                        label: section.title,
                        muted: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.more_horiz, color: scheme.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: 10),
                _HighlightedPreviewAction(step: primaryStep),
                if (secondarySteps.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < secondarySteps.length; i++) ...[
                        Expanded(
                          child: _PreviewLine(
                            icon: secondarySteps[i].icon,
                            label: secondarySteps[i].actionLabel,
                            muted: true,
                          ),
                        ),
                        if (i < secondarySteps.length - 1)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightedPreviewAction extends StatelessWidget {
  final _WelcomeStep step;

  const _HighlightedPreviewAction({required this.step});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(step.icon, color: scheme.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              step.actionLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Icon(Icons.touch_app_rounded, color: scheme.onPrimaryContainer),
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool muted;

  const _PreviewLine({
    required this.icon,
    required this.label,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: muted ? scheme.onSurfaceVariant : scheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: muted ? scheme.onSurfaceVariant : scheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachMarkBubble extends StatelessWidget {
  final String title;
  final String body;
  final _WelcomeStep step;

  const _CoachMarkBubble({
    required this.title,
    required this.body,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.secondary.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_outlined, color: scheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title · ${step.actionLabel}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeStepTile extends StatelessWidget {
  final int number;
  final _WelcomeStep step;

  const _WelcomeStepTile({required this.number, required this.step});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: scheme.primary,
            child: Text(
              '$number',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HighlightedButtonLabel(step: step),
                const SizedBox(height: 6),
                Text(
                  step.description,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightedButtonLabel extends StatelessWidget {
  final _WelcomeStep step;

  const _HighlightedButtonLabel({required this.step});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.26)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(step.icon, size: 15, color: scheme.onPrimaryContainer),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                step.actionLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
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
