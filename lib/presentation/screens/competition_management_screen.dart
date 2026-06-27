import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../application/match_competition_service.dart';
import '../../application/sport_capabilities.dart';
import '../../application/sport_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../theme/app_theme.dart';
import '../utils/match_entry_format.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/app_feedback.dart';

class CompetitionManagementScreen extends StatefulWidget {
  final TrainingService trainingService;
  final OptionRepository optionRepository;

  const CompetitionManagementScreen({
    super.key,
    required this.trainingService,
    required this.optionRepository,
  });

  @override
  State<CompetitionManagementScreen> createState() =>
      _CompetitionManagementScreenState();
}

class _CompetitionManagementScreenState
    extends State<CompetitionManagementScreen> {
  late final MatchCompetitionService _competitionService;

  @override
  void initState() {
    super.initState();
    _competitionService = MatchCompetitionService(widget.optionRepository);
  }

  @override
  Widget build(BuildContext context) {
    final sportId = SportService(widget.optionRepository).currentSportId();
    return Scaffold(
      body: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: StreamBuilder<List<TrainingEntry>>(
            stream: widget.trainingService.watchEntries(),
            builder: (context, snapshot) {
              final matchEntries = filterEntriesForSport(
                snapshot.data ?? const <TrainingEntry>[],
                sportId,
              ).where((entry) => entry.isMatch).toList(growable: false)
                ..sort((a, b) => b.date.compareTo(a.date));
              final records = _competitionService.allCompetitions();
              final metrics = _CompetitionOperationsMetrics.from(
                records: records,
                entries: matchEntries,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CompetitionManagementHeader(
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CompetitionOperationsSummary(metrics: metrics),
                    const SizedBox(height: AppSpacing.md),
                    _CompetitionCreateActions(
                      onCreateLeague: () => _openCompetitionEditor(
                        initialKind: MatchCompetitionRecord.kindLeague,
                      ),
                      onCreateTournament: () => _openCompetitionEditor(
                        initialKind: MatchCompetitionRecord.kindTournament,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (records.isEmpty)
                      _CompetitionEmptyState(
                        onCreateLeague: () => _openCompetitionEditor(
                          initialKind: MatchCompetitionRecord.kindLeague,
                        ),
                      )
                    else
                      ...records.map(
                        (record) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _CompetitionOperationsCard(
                            record: record,
                            matchEntries: matchEntries,
                            onEdit: () =>
                                _openCompetitionEditor(record: record),
                          ),
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

  Future<void> _openCompetitionEditor({
    MatchCompetitionRecord? record,
    String initialKind = MatchCompetitionRecord.kindLeague,
  }) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      showDragHandle: true,
      builder: (context) {
        return _CompetitionEditorSheet(
          service: _competitionService,
          record: record,
          initialKind: record?.kind ?? initialKind,
        );
      },
    );
    if (changed == true && mounted) {
      setState(() {});
    }
  }
}

class _CompetitionManagementHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _CompetitionManagementHeader({required this.onBack});

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
                l10n.matchCompetitionProTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                l10n.matchCompetitionProSubtitle,
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

class _CompetitionOperationsSummary extends StatelessWidget {
  final _CompetitionOperationsMetrics metrics;

  const _CompetitionOperationsSummary({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: AppSurfaces.cardDecoration(scheme, theme.brightness),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.matchCompetitionOperationsSummaryTitle,
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
                childAspectRatio: isWide ? 1.55 : 1.25,
                children: [
                  _OperationsMetricTile(
                    color: const Color(0xFF1F8A70),
                    icon: Icons.play_circle_outline,
                    label: l10n.matchCompetitionStatusActive,
                    value: '${metrics.activeCompetitions}',
                  ),
                  _OperationsMetricTile(
                    color: const Color(0xFF6D28D9),
                    icon: Icons.flag_circle_outlined,
                    label: l10n.matchCompetitionStatusFinished,
                    value: '${metrics.finishedCompetitions}',
                  ),
                  _OperationsMetricTile(
                    color: const Color(0xFF2563EB),
                    icon: Icons.groups_2_outlined,
                    label: l10n.matchCompetitionSummaryTeams,
                    value: '${metrics.registeredTeams}',
                  ),
                  _OperationsMetricTile(
                    color: const Color(0xFFC2410C),
                    icon: Icons.sports_score_outlined,
                    label: l10n.matchCompetitionSummaryMatches,
                    value: '${metrics.recordedCompetitionMatches}',
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

class _OperationsMetricTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String value;

  const _OperationsMetricTile({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.small,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetitionCreateActions extends StatelessWidget {
  final VoidCallback onCreateLeague;
  final VoidCallback onCreateTournament;

  const _CompetitionCreateActions({
    required this.onCreateLeague,
    required this.onCreateTournament,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onCreateLeague,
            icon: const Icon(Icons.leaderboard_outlined),
            label: Text(l10n.matchCompetitionCreateLeagueButton),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCreateTournament,
            icon: const Icon(Icons.account_tree_outlined),
            label: Text(l10n.matchCompetitionCreateTournamentButton),
          ),
        ),
      ],
    );
  }
}

class _CompetitionEmptyState extends StatelessWidget {
  final VoidCallback onCreateLeague;

  const _CompetitionEmptyState({required this.onCreateLeague});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: AppSurfaces.subtleDecoration(scheme, theme.brightness),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined, color: scheme.primary, size: 34),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.matchHubNoCompetitionsTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.matchCompetitionNoCompetitionsProBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onCreateLeague,
            icon: const Icon(Icons.add_outlined),
            label: Text(l10n.matchCompetitionCreateLeagueButton),
          ),
        ],
      ),
    );
  }
}

class _CompetitionOperationsCard extends StatelessWidget {
  final MatchCompetitionRecord record;
  final List<TrainingEntry> matchEntries;
  final VoidCallback onEdit;

  const _CompetitionOperationsCard({
    required this.record,
    required this.matchEntries,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLeague = record.kind == MatchCompetitionRecord.kindLeague;
    final accent = isLeague ? const Color(0xFF2563EB) : const Color(0xFFC2410C);
    final entries = MatchCompetitionService.competitionEntries(
      kind: record.kind,
      competitionName: record.name,
      entries: matchEntries,
    );
    final progress = _CompetitionProgress.from(
      record: record,
      entries: entries,
    );
    return Container(
      decoration: AppSurfaces.cardDecoration(scheme, theme.brightness),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppRadius.small,
                ),
                child: Icon(
                  isLeague ? Icons.leaderboard_outlined : Icons.account_tree,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _InfoPill(
                          text: isLeague
                              ? l10n.matchKindLeague
                              : l10n.matchKindTournament,
                        ),
                        _InfoPill(
                          text: record.isFinished
                              ? l10n.matchCompetitionStatusFinished
                              : l10n.matchCompetitionStatusActive,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppBarActionButton.label(
                icon: const Icon(Icons.edit_outlined),
                label: l10n.matchCompetitionEditButton,
                onPressed: onEdit,
                margin: EdgeInsets.zero,
                maxLabelWidth: 104,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _CompetitionMetadata(record: record),
          const SizedBox(height: AppSpacing.md),
          _CompetitionProgressBar(progress: progress, accent: accent),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _CompactMetric(
                      label: l10n.matchCompetitionSummaryTeams,
                      value: '${record.teams.length}',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _CompactMetric(
                      label: l10n.matchCompetitionSummaryMatches,
                      value: '${entries.length}',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _CompactMetric(
                      label: l10n.matchCompetitionNextActionLabel,
                      value: _nextActionLabel(l10n, record, progress, entries),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _CompactMetric(
                      label: l10n.matchCompetitionSummaryProgress,
                      value: progress.label(l10n),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (isLeague)
            _LeagueOperationsPreview(record: record, entries: matchEntries)
          else
            _TournamentOperationsPreview(record: record, entries: entries),
        ],
      ),
    );
  }

  String _nextActionLabel(
    AppLocalizations l10n,
    MatchCompetitionRecord record,
    _CompetitionProgress progress,
    List<TrainingEntry> entries,
  ) {
    if (record.teams.length < 2) {
      return l10n.matchCompetitionNextRegisterTeams;
    }
    if (entries.isEmpty) {
      return l10n.matchCompetitionNextRecordFirstMatch;
    }
    if (record.isFinished) {
      return l10n.matchCompetitionNextReviewArchive;
    }
    if (progress.isComplete) {
      return l10n.matchCompetitionNextCloseCompetition;
    }
    return l10n.matchCompetitionNextRecordNextMatch;
  }
}

class _CompetitionMetadata extends StatelessWidget {
  final MatchCompetitionRecord record;

  const _CompetitionMetadata({required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <String>[
      if (record.season.trim().isNotEmpty)
        '${l10n.matchCompetitionSeasonLabel}: ${record.season}',
      if (record.venue.trim().isNotEmpty)
        '${l10n.matchCompetitionVenueLabel}: ${record.venue}',
      if (record.organizer.trim().isNotEmpty)
        '${l10n.matchCompetitionOrganizerLabel}: ${record.organizer}',
      if (record.note.trim().isNotEmpty)
        '${l10n.matchCompetitionNoteLabel}: ${record.note}',
    ];
    if (items.isEmpty) {
      return _InfoPill(text: l10n.matchCompetitionOperationsDetailEmpty);
    }
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final item in items) _InfoPill(text: item),
      ],
    );
  }
}

class _CompetitionProgressBar extends StatelessWidget {
  final _CompetitionProgress progress;
  final Color accent;

  const _CompetitionProgressBar({
    required this.progress,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: AppRadius.full,
          child: LinearProgressIndicator(
            value: progress.value,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: accent,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.matchCompetitionProgressPercent(progress.percent),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _LeagueOperationsPreview extends StatelessWidget {
  final MatchCompetitionRecord record;
  final List<TrainingEntry> entries;

  const _LeagueOperationsPreview({
    required this.record,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final standings = MatchCompetitionService.buildLeagueStandings(
      competitionName: record.name,
      registeredTeams: record.teams,
      entries: entries,
      ownTeamName: l10n.matchCompetitionMyTeamFallback,
    );
    return _PreviewPanel(
      icon: Icons.leaderboard_outlined,
      title: l10n.matchLeagueStandingsTitle,
      child: standings.isEmpty
          ? _EmptyPreview(text: l10n.matchCompetitionNoTeams)
          : Column(
              children: [
                for (final item in standings.take(3).indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _LeagueStandingPreviewRow(
                      rank: item.$1 + 1,
                      row: item.$2,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _LeagueStandingPreviewRow extends StatelessWidget {
  final int rank;
  final LeagueStandingRow row;

  const _LeagueStandingPreviewRow({
    required this.rank,
    required this.row,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '$rank',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Text(
            row.team,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          l10n.matchLeaguePointsSummary(row.points),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _TournamentOperationsPreview extends StatelessWidget {
  final MatchCompetitionRecord record;
  final List<TrainingEntry> entries;

  const _TournamentOperationsPreview({
    required this.record,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pairs = MatchCompetitionService.buildTournamentBracketPairs(
      record.teams,
    );
    return _PreviewPanel(
      icon: Icons.account_tree_outlined,
      title: l10n.matchTournamentBracketTitle,
      child: pairs.isEmpty
          ? _EmptyPreview(text: l10n.matchCompetitionNoTeams)
          : Column(
              children: [
                for (final pair in pairs.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _TournamentPairPreviewRow(pair: pair),
                  ),
                if (entries.isNotEmpty)
                  _InfoPill(
                    text: matchTournamentOutcomeLabel(
                      l10n,
                      entries.first.tournamentOutcome,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _TournamentPairPreviewRow extends StatelessWidget {
  final TournamentBracketPair pair;

  const _TournamentPairPreviewRow({required this.pair});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final teamB = pair.hasBye ? l10n.matchTournamentByeLabel : pair.teamB;
    return Row(
      children: [
        Expanded(
          child: Text(
            pair.teamA,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text(
            l10n.matchTournamentVersusLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Text(
            teamB,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _PreviewPanel({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: AppSurfaces.subtleDecoration(
        theme.colorScheme,
        theme.brightness,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  final String text;

  const _EmptyPreview({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  final String label;
  final String value;

  const _CompactMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;

  const _InfoPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.full,
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CompetitionEditorSheet extends StatefulWidget {
  final MatchCompetitionService service;
  final MatchCompetitionRecord? record;
  final String initialKind;

  const _CompetitionEditorSheet({
    required this.service,
    required this.record,
    required this.initialKind,
  });

  @override
  State<_CompetitionEditorSheet> createState() =>
      _CompetitionEditorSheetState();
}

class _CompetitionEditorSheetState extends State<_CompetitionEditorSheet> {
  late String _kind;
  late String _status;
  late List<String> _teams;
  late final TextEditingController _nameController;
  late final TextEditingController _seasonController;
  late final TextEditingController _venueController;
  late final TextEditingController _organizerController;
  late final TextEditingController _noteController;
  late final TextEditingController _teamController;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _kind = record?.kind ?? widget.initialKind;
    _status = record?.status ?? MatchCompetitionRecord.statusActive;
    _teams = MatchCompetitionService.normalizeTeams(record?.teams ?? const []);
    _nameController = TextEditingController(text: record?.name ?? '');
    _seasonController = TextEditingController(text: record?.season ?? '');
    _venueController = TextEditingController(text: record?.venue ?? '');
    _organizerController = TextEditingController(
      text: record?.organizer ?? '',
    );
    _noteController = TextEditingController(text: record?.note ?? '');
    _teamController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _seasonController.dispose();
    _venueController.dispose();
    _organizerController.dispose();
    _noteController.dispose();
    _teamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = _nameController.text.trim().isEmpty
        ? l10n.matchCompetitionManagerNewTitle
        : l10n.matchCompetitionManagerTitle(_nameController.text.trim());
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.86,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  AppBarActionButton.icon(
                    icon: Icons.keyboard_arrow_down_outlined,
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(false),
                    margin: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment<String>(
                            value: MatchCompetitionRecord.kindLeague,
                            icon: const Icon(Icons.leaderboard_outlined),
                            label: Text(l10n.matchKindLeague),
                          ),
                          ButtonSegment<String>(
                            value: MatchCompetitionRecord.kindTournament,
                            icon: const Icon(Icons.account_tree_outlined),
                            label: Text(l10n.matchKindTournament),
                          ),
                        ],
                        selected: {_kind},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) {
                          setState(() => _kind = selection.first);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _nameController,
                        maxLength: 40,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: l10n.matchCompetitionNameLabel,
                          hintText: _kind == MatchCompetitionRecord.kindLeague
                              ? l10n.matchLeagueNameHint
                              : l10n.matchTournamentNameHint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment<String>(
                            value: MatchCompetitionRecord.statusActive,
                            icon: const Icon(Icons.play_circle_outline),
                            label: Text(l10n.matchCompetitionStatusActive),
                          ),
                          ButtonSegment<String>(
                            value: MatchCompetitionRecord.statusFinished,
                            icon: const Icon(Icons.flag_circle_outlined),
                            label: Text(l10n.matchCompetitionStatusFinished),
                          ),
                        ],
                        selected: {_status},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) {
                          setState(() => _status = selection.first);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _EditorTextField(
                        controller: _seasonController,
                        label: l10n.matchCompetitionSeasonLabel,
                        hint: l10n.matchCompetitionSeasonHint,
                        maxLength: 24,
                      ),
                      _EditorTextField(
                        controller: _venueController,
                        label: l10n.matchCompetitionVenueLabel,
                        hint: l10n.matchCompetitionVenueHint,
                        maxLength: 40,
                      ),
                      _EditorTextField(
                        controller: _organizerController,
                        label: l10n.matchCompetitionOrganizerLabel,
                        hint: l10n.matchCompetitionOrganizerHint,
                        maxLength: 40,
                      ),
                      _EditorTextField(
                        controller: _noteController,
                        label: l10n.matchCompetitionNoteLabel,
                        hint: l10n.matchCompetitionNoteHint,
                        maxLength: 80,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _EditorTeamsPanel(
                        teams: _teams,
                        teamController: _teamController,
                        onAddTeam: _addTeam,
                        onRemoveTeam: _removeTeam,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(false),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(l10n.matchCompetitionBackButton),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saveCompetition,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(l10n.matchCompetitionSaveCompetition),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addTeam() {
    final l10n = AppLocalizations.of(context)!;
    final additions = MatchCompetitionService.parseTeams(_teamController.text);
    if (additions.isEmpty) {
      AppFeedback.showMessage(
        context,
        text: l10n.matchCompetitionTeamNameRequired,
      );
      return;
    }
    final next =
        MatchCompetitionService.normalizeTeams([..._teams, ...additions]);
    if (next.length == _teams.length) {
      AppFeedback.showMessage(
        context,
        text: l10n.matchCompetitionTeamAlreadyAdded,
      );
      return;
    }
    setState(() {
      _teams = next;
      _teamController.clear();
    });
  }

  void _removeTeam(String team) {
    setState(() {
      _teams = _teams.where((item) => item != team).toList(growable: false);
    });
  }

  Future<void> _saveCompetition() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppFeedback.showMessage(
        context,
        text: l10n.matchCompetitionNameRequired,
      );
      return;
    }
    final updated = MatchCompetitionRecord.create(
      kind: _kind,
      name: name,
      teams: _teams,
      status: _status,
      season: _seasonController.text,
      venue: _venueController.text,
      organizer: _organizerController.text,
      note: _noteController.text,
    );
    final existing = widget.record;
    if (existing != null && existing.id != updated.id) {
      await widget.service.deleteCompetition(existing.id);
    }
    await widget.service.upsertCompetition(
      updated.copyWith(createdAt: existing?.createdAt ?? updated.createdAt),
    );
    if (!mounted) return;
    AppFeedback.showSuccess(
      context,
      text: l10n.matchCompetitionSavedFeedback,
    );
    Navigator.of(context).pop(true);
  }
}

class _EditorTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLength;

  const _EditorTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _EditorTeamsPanel extends StatelessWidget {
  final List<String> teams;
  final TextEditingController teamController;
  final VoidCallback onAddTeam;
  final ValueChanged<String> onRemoveTeam;

  const _EditorTeamsPanel({
    required this.teams,
    required this.teamController,
    required this.onAddTeam,
    required this.onRemoveTeam,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      decoration: AppSurfaces.subtleDecoration(
        theme.colorScheme,
        theme.brightness,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.matchCompetitionTeamsListTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                l10n.matchCompetitionTeamCount(teams.length),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (teams.isEmpty)
            Text(
              l10n.matchCompetitionNoTeams,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final team in teams)
                  InputChip(
                    label: Text(team),
                    onDeleted: () => onRemoveTeam(team),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: teamController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onAddTeam(),
                  decoration: InputDecoration(
                    labelText: l10n.matchCompetitionTeamNameLabel,
                    hintText: l10n.matchCompetitionTeamsInputHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: onAddTeam,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.matchCompetitionAddTeamButton),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompetitionOperationsMetrics {
  final int activeCompetitions;
  final int finishedCompetitions;
  final int registeredTeams;
  final int recordedCompetitionMatches;

  const _CompetitionOperationsMetrics({
    required this.activeCompetitions,
    required this.finishedCompetitions,
    required this.registeredTeams,
    required this.recordedCompetitionMatches,
  });

  factory _CompetitionOperationsMetrics.from({
    required List<MatchCompetitionRecord> records,
    required List<TrainingEntry> entries,
  }) {
    return _CompetitionOperationsMetrics(
      activeCompetitions: records.where((record) => !record.isFinished).length,
      finishedCompetitions: records.where((record) => record.isFinished).length,
      registeredTeams: records.fold<int>(
        0,
        (total, record) => total + record.teams.length,
      ),
      recordedCompetitionMatches: entries
          .where((entry) => entry.isLeagueMatch || entry.isTournamentMatch)
          .length,
    );
  }
}

class _CompetitionProgress {
  final int recorded;
  final int target;

  const _CompetitionProgress({
    required this.recorded,
    required this.target,
  });

  factory _CompetitionProgress.from({
    required MatchCompetitionRecord record,
    required List<TrainingEntry> entries,
  }) {
    final target = record.kind == MatchCompetitionRecord.kindLeague
        ? _leagueTarget(record.teams.length)
        : MatchCompetitionService.buildTournamentBracketPairs(record.teams)
            .where((pair) => !pair.hasBye)
            .length;
    return _CompetitionProgress(recorded: entries.length, target: target);
  }

  double get value {
    if (target <= 0) return recorded > 0 ? 1 : 0;
    return (recorded / target).clamp(0.0, 1.0).toDouble();
  }

  int get percent => (value * 100).round();

  bool get isComplete => target > 0 && recorded >= target;

  String label(AppLocalizations l10n) {
    if (target <= 0) return l10n.matchHubRecordedOnlyProgress(recorded);
    return l10n.statsCompetitionProgressValue(recorded, target);
  }

  static int _leagueTarget(int teamCount) {
    if (teamCount <= 1) return 0;
    return teamCount * (teamCount - 1) ~/ 2;
  }
}
