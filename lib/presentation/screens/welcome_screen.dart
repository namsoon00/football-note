import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.welcomeGuideTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.welcomeGuideIntro,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
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
                  icon: const Icon(Icons.arrow_forward_rounded),
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
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            section.overview,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.welcomeGuideSectionFlow,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
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
