import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../application/sport_capabilities.dart';
import '../../application/sport_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../theme/app_theme.dart';
import '../utils/match_entry_format.dart';
import '../widgets/app_bar_action_button.dart';

enum _MatchRecordKindFilter { all, friendly, league, tournament }

class MatchRecordsScreen extends StatelessWidget {
  final TrainingService trainingService;
  final OptionRepository optionRepository;

  const MatchRecordsScreen({
    super.key,
    required this.trainingService,
    required this.optionRepository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: MatchRecordsContent(
            trainingService: trainingService,
            optionRepository: optionRepository,
            showHeader: true,
            scrollable: true,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
        ),
      ),
    );
  }
}

class MatchRecordsContent extends StatefulWidget {
  final TrainingService trainingService;
  final OptionRepository optionRepository;
  final bool showHeader;
  final bool showSummary;
  final bool scrollable;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onBack;

  const MatchRecordsContent({
    super.key,
    required this.trainingService,
    required this.optionRepository,
    this.showHeader = false,
    this.showSummary = true,
    this.scrollable = false,
    this.padding = EdgeInsets.zero,
    this.onBack,
  });

  @override
  State<MatchRecordsContent> createState() => _MatchRecordsContentState();
}

class _MatchRecordsContentState extends State<MatchRecordsContent> {
  _MatchRecordKindFilter _kindFilter = _MatchRecordKindFilter.all;
  String? _competitionFilter;

  List<TrainingEntry> _filterEntries(
    List<TrainingEntry> entries,
    String? competitionFilter,
  ) {
    return entries.where((entry) {
      final matchesKind = switch (_kindFilter) {
        _MatchRecordKindFilter.all => true,
        _MatchRecordKindFilter.friendly =>
          !entry.isLeagueMatch && !entry.isTournamentMatch,
        _MatchRecordKindFilter.league => entry.isLeagueMatch,
        _MatchRecordKindFilter.tournament => entry.isTournamentMatch,
      };
      if (!matchesKind) return false;
      if (competitionFilter == null) return true;
      return entry.matchCompetitionName.trim() == competitionFilter;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sportId = SportService(widget.optionRepository).currentSportId();
    return StreamBuilder<List<TrainingEntry>>(
      stream: widget.trainingService.watchEntries(),
      builder: (context, snapshot) {
        final entries = filterEntriesForSport(
          snapshot.data ?? const <TrainingEntry>[],
          sportId,
        ).where((entry) => entry.isMatch).toList(growable: false)
          ..sort((a, b) => b.date.compareTo(a.date));
        final competitionNames = entries
            .map((entry) => entry.matchCompetitionName.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
        final effectiveCompetitionFilter =
            competitionNames.contains(_competitionFilter)
                ? _competitionFilter
                : null;
        final filteredEntries = _filterEntries(
          entries,
          effectiveCompetitionFilter,
        );
        final metrics = _MatchRecordsMetrics.from(entries);
        final content = Padding(
          padding: widget.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showHeader) ...[
                _MatchRecordsHeader(
                  onBack:
                      widget.onBack ?? () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (widget.showSummary) ...[
                _MatchRecordsSummary(metrics: metrics),
                const SizedBox(height: AppSpacing.md),
              ],
              _RecordsSectionHeader(
                title: l10n.matchRecordsListTitle,
                kindFilter: _kindFilter,
                competitionNames: competitionNames,
                competitionFilter: effectiveCompetitionFilter,
                onKindFilterChanged: (value) {
                  setState(() => _kindFilter = value);
                },
                onCompetitionFilterChanged: (value) {
                  setState(() => _competitionFilter = value);
                },
              ),
              if (entries.isEmpty)
                _RecordsEmptyPanel(
                  icon: Icons.fact_check_outlined,
                  title: l10n.matchHubEmptyTitle,
                  body: l10n.matchHubEmptySubtitle,
                )
              else if (filteredEntries.isEmpty)
                _RecordsEmptyPanel(
                  icon: Icons.filter_alt_off_outlined,
                  title: l10n.matchRecordsFilterEmptyTitle,
                  body: l10n.matchRecordsFilterEmptyBody,
                  actionLabel: l10n.filterReset,
                  onAction: () {
                    setState(() {
                      _kindFilter = _MatchRecordKindFilter.all;
                      _competitionFilter = null;
                    });
                  },
                )
              else
                ...filteredEntries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _MatchRecordCard(entry: entry),
                  ),
                ),
            ],
          ),
        );
        if (!widget.scrollable) return content;
        return SingleChildScrollView(child: content);
      },
    );
  }
}

class _MatchRecordsHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _MatchRecordsHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Row(
      children: [
        AppBarActionButton.icon(
          icon: Icons.arrow_back,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onBack,
          margin: EdgeInsets.zero,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.matchRecordsTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                l10n.matchRecordsSubtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MatchRecordsSummary extends StatelessWidget {
  final _MatchRecordsMetrics metrics;

  const _MatchRecordsSummary({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    return Container(
      decoration: AppSurfaces.cardDecoration(scheme, brightness),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.matchRecordsSummaryTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 560;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: isWide ? 1.7 : 1.45,
                children: [
                  _SummaryTile(
                    color: const Color(0xFF2563EB),
                    label: l10n.statsMatchTotalMatchesLabel,
                    value: l10n.statsMatchTotalMatchesValue(
                      metrics.totalMatches,
                    ),
                  ),
                  _SummaryTile(
                    color: const Color(0xFF1F8A70),
                    label: l10n.statsMatchRecordLabel,
                    value: l10n.statsMatchRecordValue(
                      metrics.wins,
                      metrics.draws,
                      metrics.losses,
                    ),
                  ),
                  _SummaryTile(
                    color: const Color(0xFFC2410C),
                    label: l10n.statsMatchWinRateLabel,
                    value: l10n.statsMatchWinRateValue(metrics.winRate),
                  ),
                  _SummaryTile(
                    color: const Color(0xFF6D28D9),
                    label: l10n.statsMatchTypeLabel,
                    value: l10n.matchHubKindBreakdown(
                      metrics.friendlyMatches,
                      metrics.leagueMatches,
                      metrics.tournamentMatches,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _SummaryTile({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.small,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchRecordCard extends StatelessWidget {
  final TrainingEntry entry;

  const _MatchRecordCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final locale = Localizations.localeOf(context).toString();
    final outcome = _matchOutcome(entry);
    final color = _outcomeColor(outcome, scheme);
    final outcomeLabel = switch (outcome) {
      1 => l10n.matchResultWin,
      0 => l10n.matchResultDraw,
      -1 => l10n.matchResultLoss,
      _ => l10n.matchResultUnset,
    };
    final scored = entry.scoredGoals;
    final conceded = entry.concededGoals;
    final score = scored == null || conceded == null
        ? l10n.matchResultUnset
        : '$scored : $conceded';
    final opponent = entry.opponentTeam.trim().isEmpty
        ? l10n.statsCompetitionOpponentUnset
        : entry.opponentTeam.trim();
    final details = [
      matchKindLabel(entry, l10n),
      DateFormat.yMMMd(locale).format(entry.date),
      ...matchCompetitionDetailParts(entry, l10n, teamLimit: 3),
    ];

    return Container(
      decoration: AppSurfaces.cardDecoration(scheme, brightness),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.small,
            ),
            child: Center(
              child: Text(
                _opponentInitials(opponent),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opponent,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  details.join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: AppRadius.small,
                ),
                child: Text(
                  outcomeLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
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

String _opponentInitials(String opponent) {
  final trimmed = opponent.trim();
  if (trimmed.isEmpty) return '-';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length > 1) {
    return parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first)
        .join();
  }
  return trimmed.characters.take(2).toString();
}

class _RecordsSectionHeader extends StatelessWidget {
  final String title;
  final _MatchRecordKindFilter kindFilter;
  final List<String> competitionNames;
  final String? competitionFilter;
  final ValueChanged<_MatchRecordKindFilter> onKindFilterChanged;
  final ValueChanged<String?> onCompetitionFilterChanged;

  const _RecordsSectionHeader({
    required this.title,
    required this.kindFilter,
    required this.competitionNames,
    required this.competitionFilter,
    required this.onKindFilterChanged,
    required this.onCompetitionFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: MenuAnchor(
                  key: const ValueKey('match-record-kind-filter'),
                  menuChildren: [
                    for (final value in _MatchRecordKindFilter.values)
                      MenuItemButton(
                        leadingIcon: kindFilter == value
                            ? const Icon(Icons.check)
                            : const SizedBox(width: 24),
                        onPressed: () => onKindFilterChanged(value),
                        child: Text(_matchRecordKindFilterLabel(l10n, value)),
                      ),
                  ],
                  builder: (context, controller, child) =>
                      _CompactRecordsFilterButton(
                    icon: Icons.sports_soccer_outlined,
                    label: _matchRecordKindFilterLabel(l10n, kindFilter),
                    active: kindFilter != _MatchRecordKindFilter.all,
                    onPressed: () => controller.isOpen
                        ? controller.close()
                        : controller.open(),
                  ),
                ),
              ),
              if (competitionNames.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: MenuAnchor(
                    key: const ValueKey('match-record-competition-filter'),
                    menuChildren: [
                      MenuItemButton(
                        leadingIcon: competitionFilter == null
                            ? const Icon(Icons.check)
                            : const SizedBox(width: 24),
                        onPressed: () => onCompetitionFilterChanged(null),
                        child: Text(l10n.matchRecordsCompetitionAllFilter),
                      ),
                      for (final name in competitionNames)
                        MenuItemButton(
                          leadingIcon: competitionFilter == name
                              ? const Icon(Icons.check)
                              : const SizedBox(width: 24),
                          onPressed: () => onCompetitionFilterChanged(name),
                          child: Text(name),
                        ),
                    ],
                    builder: (context, controller, child) =>
                        _CompactRecordsFilterButton(
                      icon: Icons.emoji_events_outlined,
                      label: competitionFilter ??
                          l10n.matchRecordsCompetitionAllFilter,
                      active: competitionFilter != null,
                      onPressed: () => controller.isOpen
                          ? controller.close()
                          : controller.open(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactRecordsFilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onPressed;

  const _CompactRecordsFilterButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = active ? scheme.primary : scheme.onSurfaceVariant;
    return Material(
      color: active
          ? scheme.primary.withValues(alpha: 0.10)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.48),
      borderRadius: AppRadius.small,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.small,
        child: SizedBox(
          height: 38,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              children: [
                Icon(icon, size: 17, color: foreground),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Icon(Icons.arrow_drop_down, size: 18, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordsEmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _RecordsEmptyPanel({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    return Container(
      decoration: AppSurfaces.subtleDecoration(scheme, brightness),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(icon, color: scheme.primary, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

String _matchRecordKindFilterLabel(
  AppLocalizations l10n,
  _MatchRecordKindFilter filter,
) {
  return switch (filter) {
    _MatchRecordKindFilter.all => l10n.filterAll,
    _MatchRecordKindFilter.friendly => l10n.matchKindFriendly,
    _MatchRecordKindFilter.league => l10n.matchKindLeague,
    _MatchRecordKindFilter.tournament => l10n.matchKindTournament,
  };
}

class _MatchRecordsMetrics {
  final int totalMatches;
  final int wins;
  final int draws;
  final int losses;
  final int friendlyMatches;
  final int leagueMatches;
  final int tournamentMatches;

  const _MatchRecordsMetrics({
    required this.totalMatches,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.friendlyMatches,
    required this.leagueMatches,
    required this.tournamentMatches,
  });

  factory _MatchRecordsMetrics.from(List<TrainingEntry> entries) {
    final outcomes =
        entries.map(_matchOutcome).whereType<int>().toList(growable: false);
    return _MatchRecordsMetrics(
      totalMatches: entries.length,
      wins: outcomes.where((value) => value > 0).length,
      draws: outcomes.where((value) => value == 0).length,
      losses: outcomes.where((value) => value < 0).length,
      friendlyMatches: entries
          .where((entry) => !entry.isLeagueMatch && !entry.isTournamentMatch)
          .length,
      leagueMatches: entries.where((entry) => entry.isLeagueMatch).length,
      tournamentMatches:
          entries.where((entry) => entry.isTournamentMatch).length,
    );
  }

  int get winRate {
    final decided = wins + draws + losses;
    if (decided == 0) return 0;
    return ((wins / decided) * 100).round();
  }
}

int? _matchOutcome(TrainingEntry entry) {
  final scored = entry.scoredGoals;
  final conceded = entry.concededGoals;
  if (scored != null && conceded != null) {
    if (scored > conceded) return 1;
    if (scored == conceded) return 0;
    return -1;
  }
  final points = entry.leaguePoints;
  if (points != null) {
    if (points >= 3) return 1;
    if (points == 1) return 0;
    return -1;
  }
  if (entry.tournamentOutcome == 'advanced' ||
      entry.tournamentOutcome == 'champion') {
    return 1;
  }
  if (entry.tournamentOutcome == 'eliminated') return -1;
  return null;
}

Color _outcomeColor(int? outcome, ColorScheme scheme) {
  return switch (outcome) {
    1 => const Color(0xFF1F8A70),
    0 => const Color(0xFFB7791F),
    -1 => scheme.error,
    _ => scheme.onSurfaceVariant,
  };
}
