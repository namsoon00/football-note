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

class MatchRecordsContent extends StatelessWidget {
  final TrainingService trainingService;
  final OptionRepository optionRepository;
  final bool showHeader;
  final bool scrollable;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onBack;

  const MatchRecordsContent({
    super.key,
    required this.trainingService,
    required this.optionRepository,
    this.showHeader = false,
    this.scrollable = false,
    this.padding = EdgeInsets.zero,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sportId = SportService(optionRepository).currentSportId();
    return StreamBuilder<List<TrainingEntry>>(
      stream: trainingService.watchEntries(),
      builder: (context, snapshot) {
        final entries = filterEntriesForSport(
          snapshot.data ?? const <TrainingEntry>[],
          sportId,
        ).where((entry) => entry.isMatch).toList(growable: false)
          ..sort((a, b) => b.date.compareTo(a.date));
        final metrics = _MatchRecordsMetrics.from(entries);
        final content = Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHeader) ...[
                _MatchRecordsHeader(
                  onBack: onBack ?? () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _MatchRecordsSummary(metrics: metrics),
              const SizedBox(height: AppSpacing.md),
              _RecordsSectionHeader(title: l10n.matchRecordsListTitle),
              if (entries.isEmpty)
                _RecordsEmptyPanel(
                  icon: Icons.fact_check_outlined,
                  title: l10n.matchHubEmptyTitle,
                  body: l10n.matchHubEmptySubtitle,
                )
              else
                ...entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _MatchRecordCard(entry: entry),
                  ),
                ),
            ],
          ),
        );
        if (!scrollable) return content;
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
      DateFormat.yMMMd(locale).format(entry.date),
      ...matchCompetitionDetailParts(entry, l10n, teamLimit: 3),
    ];

    return Container(
      decoration: AppSurfaces.cardDecoration(scheme, brightness),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.small,
            ),
            child: Center(
              child: Text(
                _outcomeShortLabel(outcome, l10n),
                style: theme.textTheme.titleMedium?.copyWith(
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
                  '${matchKindLabel(entry, l10n)} · $opponent',
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                outcomeLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordsSectionHeader extends StatelessWidget {
  final String title;

  const _RecordsSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RecordsEmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _RecordsEmptyPanel({
    required this.icon,
    required this.title,
    required this.body,
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
        ],
      ),
    );
  }
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

String _outcomeShortLabel(int? outcome, AppLocalizations l10n) {
  return switch (outcome) {
    1 => l10n.statsMatchOutcomeWinShort,
    0 => l10n.statsMatchOutcomeDrawShort,
    -1 => l10n.statsMatchOutcomeLossShort,
    _ => '-',
  };
}

Color _outcomeColor(int? outcome, ColorScheme scheme) {
  return switch (outcome) {
    1 => const Color(0xFF1F8A70),
    0 => const Color(0xFFB7791F),
    -1 => scheme.error,
    _ => scheme.onSurfaceVariant,
  };
}
