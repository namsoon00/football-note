import 'dart:async';

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../application/family_access_service.dart';
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

ButtonStyle _competitionFilledActionStyle(BuildContext context) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final background = theme.brightness == Brightness.dark
      ? scheme.primary
      : Color.lerp(scheme.primary, Colors.black, 0.08)!;
  return FilledButton.styleFrom(
    backgroundColor: background,
    foregroundColor: scheme.onPrimary,
    disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
    disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
    minimumSize: const Size(0, AppSizes.primaryButtonHeight),
    textStyle: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w900,
    ),
    shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
  );
}

ButtonStyle _competitionOutlinedActionStyle(BuildContext context) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final foreground = theme.brightness == Brightness.dark
      ? scheme.primary
      : Color.lerp(scheme.primary, Colors.black, 0.18)!;
  return OutlinedButton.styleFrom(
    backgroundColor: scheme.surface,
    foregroundColor: foreground,
    disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
    side: BorderSide(color: foreground.withValues(alpha: 0.58)),
    minimumSize: const Size(0, AppSizes.primaryButtonHeight),
    textStyle: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w900,
    ),
    shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
  );
}

class CompetitionManagementScreen extends StatefulWidget {
  final TrainingService trainingService;
  final OptionRepository optionRepository;
  final String? sportId;
  final bool readOnly;

  const CompetitionManagementScreen({
    super.key,
    required this.trainingService,
    required this.optionRepository,
    this.sportId,
    this.readOnly = false,
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
    _competitionService = MatchCompetitionService(
      widget.optionRepository,
      sportId: widget.sportId,
    );
  }

  bool get _isReadOnlySupportMode =>
      widget.readOnly ||
      FamilyAccessService(
        widget.optionRepository,
      ).loadState().isReadOnlySupportMode;

  @override
  Widget build(BuildContext context) {
    final sportId = widget.sportId ??
        SportService(widget.optionRepository).currentSportId();
    final readOnly = _isReadOnlySupportMode;
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
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CompetitionOperationsHero(
                      metrics: metrics,
                      readOnly: readOnly,
                      onBack: () => Navigator.of(context).maybePop(),
                      onCreateLeague: () => _openCompetitionEditor(
                        initialKind: MatchCompetitionRecord.kindLeague,
                      ),
                      onCreateTournament: () => _openCompetitionEditor(
                        initialKind: MatchCompetitionRecord.kindTournament,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CompetitionListHeader(count: records.length),
                    if (records.isEmpty)
                      _CompetitionEmptyState(
                        readOnly: readOnly,
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
                            readOnly: readOnly,
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
    if (_isReadOnlySupportMode) {
      AppFeedback.showMessage(
        context,
        text: AppLocalizations.of(context)!.parentReadOnlyCoreDataMessage,
      );
      return;
    }
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

class _CompetitionOperationsHero extends StatelessWidget {
  final _CompetitionOperationsMetrics metrics;
  final bool readOnly;
  final VoidCallback onBack;
  final VoidCallback onCreateLeague;
  final VoidCallback onCreateTournament;

  const _CompetitionOperationsHero({
    required this.metrics,
    required this.readOnly,
    required this.onBack,
    required this.onCreateLeague,
    required this.onCreateTournament,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackButton(
              onPressed: onBack,
            ),
            const SizedBox(width: AppSpacing.xs),
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
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.matchCompetitionOperationsSummaryTitle,
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _CompetitionHeroMetricPill(
              label: l10n.matchCompetitionStatusActive,
              value: '${metrics.activeCompetitions}',
            ),
            _CompetitionHeroMetricPill(
              label: l10n.matchCompetitionStatusFinished,
              value: '${metrics.finishedCompetitions}',
            ),
            _CompetitionHeroMetricPill(
              label: l10n.matchCompetitionSummaryTeams,
              value: '${metrics.registeredTeams}',
            ),
            _CompetitionHeroMetricPill(
              label: l10n.matchCompetitionSummaryMatches,
              value: '${metrics.recordedCompetitionMatches}',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _CompetitionHeroActions(
          readOnly: readOnly,
          onCreateLeague: onCreateLeague,
          onCreateTournament: onCreateTournament,
        ),
      ],
    );
  }
}

class _CompetitionHeroActions extends StatelessWidget {
  final bool readOnly;
  final VoidCallback onCreateLeague;
  final VoidCallback onCreateTournament;

  const _CompetitionHeroActions({
    required this.readOnly,
    required this.onCreateLeague,
    required this.onCreateTournament,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    const actionColor = Color(0xFF166153);
    final primary = FilledButton.icon(
      onPressed: readOnly ? null : onCreateLeague,
      icon: const Icon(Icons.leaderboard_outlined),
      label: Text(l10n.matchCompetitionCreateLeagueButton),
      style: FilledButton.styleFrom(
        backgroundColor: actionColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, AppSizes.primaryButtonHeight),
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    final secondary = OutlinedButton.icon(
      onPressed: readOnly ? null : onCreateTournament,
      icon: const Icon(Icons.account_tree_outlined),
      label: Text(l10n.matchCompetitionCreateTournamentButton),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: actionColor,
        side: BorderSide(color: actionColor.withValues(alpha: 0.58)),
        minimumSize: const Size(0, AppSizes.primaryButtonHeight),
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              primary,
              const SizedBox(height: AppSpacing.xs),
              secondary,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: secondary),
          ],
        );
      },
    );
  }
}

class _CompetitionHeroMetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _CompetitionHeroMetricPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 118),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetitionListHeader extends StatelessWidget {
  final int count;

  const _CompetitionListHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.matchCompetitionListTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _InfoPill(text: l10n.matchCompetitionListCount(count)),
        ],
      ),
    );
  }
}

class _CompetitionEmptyState extends StatelessWidget {
  final bool readOnly;
  final VoidCallback onCreateLeague;

  const _CompetitionEmptyState({
    required this.readOnly,
    required this.onCreateLeague,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.lg,
      ),
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
            onPressed: readOnly ? null : onCreateLeague,
            icon: const Icon(Icons.add_outlined),
            label: Text(l10n.matchCompetitionCreateLeagueButton),
            style: _competitionFilledActionStyle(context),
          ),
        ],
      ),
    );
  }
}

class _CompetitionOperationsCard extends StatelessWidget {
  final MatchCompetitionRecord record;
  final List<TrainingEntry> matchEntries;
  final bool readOnly;
  final VoidCallback onEdit;

  const _CompetitionOperationsCard({
    required this.record,
    required this.matchEntries,
    required this.readOnly,
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
    final nextAction = _nextActionLabel(l10n, record, progress, entries);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppSurfaces.borderColor(scheme, theme.brightness),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isLeague ? Icons.leaderboard_outlined : Icons.account_tree,
                color: accent,
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
              _InlineCompetitionIconAction(
                icon: Icons.edit_outlined,
                tooltip: l10n.matchCompetitionEditButton,
                onPressed: readOnly ? null : onEdit,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _CompetitionNextActionBanner(
            accent: accent,
            label: l10n.matchCompetitionNextActionLabel,
            value: nextAction,
            progressLabel: progress.label(l10n),
            progressPercent: l10n.matchCompetitionProgressPercent(
              progress.percent,
            ),
            progressValue: progress.value,
          ),
          const SizedBox(height: AppSpacing.md),
          _CompetitionMetricGrid(
            metrics: [
              _CompetitionMetricData(
                icon: Icons.groups_2_outlined,
                label: l10n.matchCompetitionSummaryTeams,
                value: '${record.teams.length}',
              ),
              _CompetitionMetricData(
                icon: Icons.sports_score_outlined,
                label: l10n.matchCompetitionSummaryMatches,
                value: '${entries.length}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _CompetitionMetadata(record: record),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 620;
              final preview = isLeague
                  ? _LeagueOperationsPreview(
                      record: record,
                      entries: matchEntries,
                    )
                  : _TournamentOperationsPreview(
                      record: record,
                      entries: entries,
                    );
              if (!isWide) return preview;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: preview),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _CompetitionTeamsPreview(
                      teams: record.teams,
                      accent: accent,
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

class _InlineCompetitionIconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _InlineCompetitionIconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: InkResponse(
          onTap: onPressed,
          radius: 22,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Icon(
              icon,
              color: enabled
                  ? scheme.onSurfaceVariant
                  : scheme.onSurfaceVariant.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompetitionNextActionBanner extends StatelessWidget {
  final Color accent;
  final String label;
  final String value;
  final String progressLabel;
  final String progressPercent;
  final double progressValue;

  const _CompetitionNextActionBanner({
    required this.accent,
    required this.label,
    required this.value,
    required this.progressLabel,
    required this.progressPercent,
    required this.progressValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: AppRadius.small,
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: AppRadius.small,
                ),
                child: Icon(Icons.playlist_add_check_outlined, color: accent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                progressPercent,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.full,
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              color: accent,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            progressLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetitionMetricData {
  final IconData icon;
  final String label;
  final String value;

  const _CompetitionMetricData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _CompetitionMetricGrid extends StatelessWidget {
  final List<_CompetitionMetricData> metrics;

  const _CompetitionMetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: itemWidth,
                child: _CompetitionMetricTile(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _CompetitionMetricTile extends StatelessWidget {
  final _CompetitionMetricData metric;

  const _CompetitionMetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: AppRadius.small,
        border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(metric.icon, color: scheme.primary, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
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

class _CompetitionTeamsPreview extends StatelessWidget {
  final List<String> teams;
  final Color accent;

  const _CompetitionTeamsPreview({
    required this.teams,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _PreviewPanel(
      icon: Icons.groups_2_outlined,
      title: l10n.matchCompetitionTeamsListTitle,
      accent: accent,
      child: teams.isEmpty
          ? _EmptyPreview(text: l10n.matchCompetitionNoTeams)
          : Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final team in teams.take(8)) _InfoPill(text: team),
              ],
            ),
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
  final Color? accent;

  const _PreviewPanel({
    required this.icon,
    required this.title,
    required this.child,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = accent ?? scheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: color.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.34 : 0.18),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
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
  static const Duration _autoSaveDelay = Duration(milliseconds: 700);

  late String _kind;
  late String _status;
  late List<String> _teams;
  late final TextEditingController _nameController;
  late final TextEditingController _seasonController;
  late final TextEditingController _venueController;
  late final TextEditingController _organizerController;
  late final TextEditingController _noteController;
  late final TextEditingController _teamController;
  MatchCompetitionRecord? _persistedRecord;
  Timer? _autoSaveTimer;
  bool _autoSaveInFlight = false;
  bool _autoSaveQueued = false;
  String _lastSavedSignature = '';

  List<TextEditingController> get _autoSaveControllers => [
        _nameController,
        _seasonController,
        _venueController,
        _organizerController,
        _noteController,
      ];

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _persistedRecord = record;
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
    _lastSavedSignature =
        record == null ? '' : _competitionRecordSignature(record);
    for (final controller in _autoSaveControllers) {
      controller.addListener(_handleEditorChanged);
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    for (final controller in _autoSaveControllers) {
      controller.removeListener(_handleEditorChanged);
    }
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
                      _EditorSectionPanel(
                        title: l10n.matchCompetitionEditorBasicsTitle,
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
                              _updateAndScheduleAutoSave(
                                () => _kind = selection.first,
                              );
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
                              hintText:
                                  _kind == MatchCompetitionRecord.kindLeague
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
                                label:
                                    Text(l10n.matchCompetitionStatusFinished),
                              ),
                            ],
                            selected: {_status},
                            showSelectedIcon: false,
                            onSelectionChanged: (selection) {
                              _updateAndScheduleAutoSave(
                                () => _status = selection.first,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _EditorSectionPanel(
                        title: l10n.matchCompetitionEditorOperationsTitle,
                        children: [
                          _EditorFieldGrid(
                            children: [
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
                            ],
                          ),
                        ],
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
                      style: _competitionOutlinedActionStyle(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saveCompetition,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(l10n.matchCompetitionSaveCompetition),
                      style: _competitionFilledActionStyle(context),
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
    _scheduleAutoSave();
  }

  void _removeTeam(String team) {
    setState(() {
      _teams = _teams.where((item) => item != team).toList(growable: false);
    });
    _scheduleAutoSave();
  }

  Future<void> _saveCompetition() async {
    final l10n = AppLocalizations.of(context)!;
    final updated = _buildCompetitionRecord();
    if (updated == null) {
      AppFeedback.showMessage(
        context,
        text: l10n.matchCompetitionNameRequired,
      );
      return;
    }
    _autoSaveTimer?.cancel();
    await _persistCompetition(updated);
    if (!mounted) return;
    AppFeedback.showSuccess(
      context,
      text: l10n.matchCompetitionSavedFeedback,
    );
    Navigator.of(context).pop(true);
  }

  void _handleEditorChanged() {
    if (!mounted) return;
    setState(() {});
    _scheduleAutoSave();
  }

  void _updateAndScheduleAutoSave(VoidCallback update) {
    setState(update);
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    final updated = _buildCompetitionRecord();
    if (updated == null ||
        _competitionRecordSignature(updated) == _lastSavedSignature) {
      return;
    }
    if (_autoSaveInFlight) {
      _autoSaveQueued = true;
      return;
    }
    _autoSaveTimer = Timer(_autoSaveDelay, () {
      unawaited(_autoSaveCompetition());
    });
  }

  Future<void> _autoSaveCompetition() async {
    final updated = _buildCompetitionRecord();
    if (updated == null ||
        _competitionRecordSignature(updated) == _lastSavedSignature) {
      return;
    }
    if (_autoSaveInFlight) {
      _autoSaveQueued = true;
      return;
    }
    _autoSaveInFlight = true;
    try {
      await _persistCompetition(updated);
      if (mounted) setState(() {});
    } finally {
      _autoSaveInFlight = false;
      if (_autoSaveQueued && mounted) {
        _autoSaveQueued = false;
        _scheduleAutoSave();
      }
    }
  }

  MatchCompetitionRecord? _buildCompetitionRecord() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return null;
    return MatchCompetitionRecord.create(
      kind: _kind,
      name: name,
      teams: _teams,
      status: _status,
      season: _seasonController.text,
      venue: _venueController.text,
      organizer: _organizerController.text,
      note: _noteController.text,
    );
  }

  Future<void> _persistCompetition(MatchCompetitionRecord updated) async {
    final existing = _persistedRecord ?? widget.record;
    if (existing != null && existing.id != updated.id) {
      await widget.service.deleteCompetition(existing.id);
    }
    final createdAt = existing?.createdAt ?? updated.createdAt;
    final normalized = updated.copyWith(createdAt: createdAt);
    await widget.service.upsertCompetition(normalized);
    _persistedRecord =
        widget.service.findCompetitionById(normalized.id) ?? normalized;
    _lastSavedSignature = _competitionRecordSignature(updated);
  }

  String _competitionRecordSignature(MatchCompetitionRecord record) {
    return [
      record.kind,
      record.name.trim(),
      record.status,
      record.season.trim(),
      record.venue.trim(),
      record.organizer.trim(),
      record.note.trim(),
      ...MatchCompetitionService.normalizeTeams(record.teams),
    ].join('\n');
  }
}

class _EditorSectionPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _EditorSectionPanel({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _EditorFieldGrid extends StatelessWidget {
  final List<Widget> children;

  const _EditorFieldGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 2 : 1;
        final itemWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final child in children)
              SizedBox(
                width: itemWidth,
                child: child,
              ),
          ],
        );
      },
    );
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
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
                  color: scheme.onSurfaceVariant,
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
                color: scheme.onSurfaceVariant,
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
                height: AppSizes.primaryButtonHeight,
                child: FilledButton.icon(
                  onPressed: onAddTeam,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.matchCompetitionAddTeamButton),
                  style: _competitionFilledActionStyle(context),
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
