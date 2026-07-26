import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../application/family_access_service.dart';
import '../../application/match_competition_service.dart';
import '../../application/sport_capabilities.dart';
import '../../application/sport_service.dart';
import '../../application/team_management_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../theme/app_theme.dart';
import '../utils/match_entry_format.dart';
import '../utils/pdf_export.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_page_route.dart';

enum _CompetitionStatusFilter { all, active, finished }

enum _CompetitionDetailAction { edit, delete }

enum _CompetitionDetailView { schedule, standings, bracket, teams }

typedef CompetitionFixtureRecordHandler = Future<void> Function(
  MatchCompetitionRecord competition,
  CompetitionFixture fixture,
  TrainingEntry? editingEntry,
);

Color _competitionAccent(BuildContext context, String kind) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  if (kind == MatchCompetitionRecord.kindLeague) {
    return dark ? const Color(0xFF8AB4FF) : const Color(0xFF1D4ED8);
  }
  return dark ? const Color(0xFFFFB37A) : const Color(0xFFB9380A);
}

Color _competitionPositiveColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF67DDB2)
      : const Color(0xFF087A55);
}

String _competitionNextActionLabel(
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

class CompetitionManagementScreen extends StatefulWidget {
  final TrainingService trainingService;
  final OptionRepository optionRepository;
  final String? sportId;
  final bool readOnly;
  final CompetitionFixtureRecordHandler? onOpenFixtureRecord;

  const CompetitionManagementScreen({
    super.key,
    required this.trainingService,
    required this.optionRepository,
    this.sportId,
    this.readOnly = false,
    this.onOpenFixtureRecord,
  });

  @override
  State<CompetitionManagementScreen> createState() =>
      _CompetitionManagementScreenState();
}

class _CompetitionManagementScreenState
    extends State<CompetitionManagementScreen> {
  late final MatchCompetitionService _competitionService;
  _CompetitionStatusFilter _statusFilter = _CompetitionStatusFilter.all;

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

  String _managedTeamName() {
    final sportId = widget.sportId ??
        SportService(widget.optionRepository).currentSportId();
    final teams = TeamManagementService(
      widget.optionRepository,
      sportId: sportId,
    ).allTeams();
    return teams.isEmpty ? '' : teams.first.name.trim();
  }

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
              );
              final visibleRecords = records.where((record) {
                return switch (_statusFilter) {
                  _CompetitionStatusFilter.all => true,
                  _CompetitionStatusFilter.active => !record.isFinished,
                  _CompetitionStatusFilter.finished => record.isFinished,
                };
              }).toList(growable: false);

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
                      statusFilter: _statusFilter,
                      onBack: () => Navigator.of(context).maybePop(),
                      onCreateCompetition: () => _openCompetitionEditor(
                        initialKind: MatchCompetitionRecord.kindLeague,
                      ),
                      onStatusFilterChanged: (value) {
                        setState(() => _statusFilter = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CompetitionListHeader(count: visibleRecords.length),
                    if (visibleRecords.isEmpty)
                      _CompetitionEmptyState(
                        readOnly: readOnly,
                        filtered: records.isNotEmpty,
                        onResetFilter: () {
                          setState(
                            () => _statusFilter = _CompetitionStatusFilter.all,
                          );
                        },
                        onCreateCompetition: () => _openCompetitionEditor(
                          initialKind: MatchCompetitionRecord.kindLeague,
                        ),
                      )
                    else
                      ...visibleRecords.map(
                        (record) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _CompetitionOperationsCard(
                            record: record,
                            matchEntries: matchEntries,
                            onOpen: () => _openCompetitionDetail(
                              record: record,
                            ),
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
    final l10n = AppLocalizations.of(context)!;
    final changed = await Navigator.of(context).push<bool>(
      AppPageRoute(
        builder: (_) => _CompetitionEditorScreen(
          service: _competitionService,
          record: record,
          initialKind: record?.kind ?? initialKind,
          managedTeamName: _managedTeamName(),
          fallbackTeamName: l10n.matchCompetitionMyTeamFallback,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _openCompetitionDetail({
    required MatchCompetitionRecord record,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await Navigator.of(context).push<_CompetitionDetailAction>(
      AppPageRoute(
        builder: (_) => _CompetitionDetailScreen(
          record: record,
          competitionService: _competitionService,
          trainingService: widget.trainingService,
          sportId: widget.sportId ??
              SportService(widget.optionRepository).currentSportId(),
          readOnly: _isReadOnlySupportMode,
          managedTeamName: _managedTeamName(),
          fallbackTeamName: l10n.matchCompetitionMyTeamFallback,
          onOpenFixtureRecord: widget.onOpenFixtureRecord,
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _CompetitionDetailAction.edit:
        await _openCompetitionEditor(record: record);
        break;
      case _CompetitionDetailAction.delete:
        await _confirmDeleteCompetition(record);
        break;
    }
  }

  Future<void> _confirmDeleteCompetition(
    MatchCompetitionRecord record,
  ) async {
    if (_isReadOnlySupportMode) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.matchCompetitionDeleteDialogTitle),
        content: Text(l10n.matchCompetitionDeleteDialogBody(record.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.matchCompetitionDeleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _competitionService.deleteCompetition(record.id);
    if (!mounted) return;
    setState(() {});
    AppFeedback.showSuccess(
      context,
      text: l10n.matchCompetitionDeletedFeedback,
    );
  }
}

class _CompetitionOperationsHero extends StatelessWidget {
  final _CompetitionOperationsMetrics metrics;
  final bool readOnly;
  final _CompetitionStatusFilter statusFilter;
  final VoidCallback onBack;
  final VoidCallback onCreateCompetition;
  final ValueChanged<_CompetitionStatusFilter> onStatusFilterChanged;

  const _CompetitionOperationsHero({
    required this.metrics,
    required this.readOnly,
    required this.statusFilter,
    required this.onBack,
    required this.onCreateCompetition,
    required this.onStatusFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BackButton(
              onPressed: onBack,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.matchCompetitionProTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            AppBarActionButton.label(
              key: const ValueKey('competition-create-action'),
              icon: const Icon(Icons.add_outlined),
              label: l10n.matchCompetitionNewButton,
              tooltip: l10n.matchCompetitionNewButton,
              onPressed: readOnly ? null : onCreateCompetition,
              margin: EdgeInsets.zero,
              maxLabelWidth: 80,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<_CompetitionStatusFilter>(
          key: const ValueKey('competition-status-filter'),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: _CompetitionStatusFilter.all,
              label: Text(
                l10n.matchCompetitionFilterAll(
                  metrics.activeCompetitions + metrics.finishedCompetitions,
                ),
              ),
            ),
            ButtonSegment(
              value: _CompetitionStatusFilter.active,
              label: Text(
                l10n.matchCompetitionFilterActive(
                  metrics.activeCompetitions,
                ),
              ),
            ),
            ButtonSegment(
              value: _CompetitionStatusFilter.finished,
              label: Text(
                l10n.matchCompetitionFilterFinished(
                  metrics.finishedCompetitions,
                ),
              ),
            ),
          ],
          selected: {statusFilter},
          onSelectionChanged: (selection) {
            onStatusFilterChanged(selection.single);
          },
        ),
      ],
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
  final bool filtered;
  final VoidCallback onCreateCompetition;
  final VoidCallback onResetFilter;

  const _CompetitionEmptyState({
    required this.readOnly,
    required this.filtered,
    required this.onCreateCompetition,
    required this.onResetFilter,
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
          Icon(
            filtered
                ? Icons.filter_alt_off_outlined
                : Icons.emoji_events_outlined,
            color: scheme.primary,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            filtered
                ? l10n.matchCompetitionFilterEmptyTitle
                : l10n.matchHubNoCompetitionsTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            filtered
                ? l10n.matchCompetitionFilterEmptyBody
                : l10n.matchCompetitionNoCompetitionsProBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (filtered)
            TextButton(
              onPressed: onResetFilter,
              child: Text(l10n.filterReset),
            )
          else
            FilledButton.icon(
              onPressed: readOnly ? null : onCreateCompetition,
              icon: const Icon(Icons.add_outlined),
              label: Text(l10n.matchCompetitionNewButton),
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
  final VoidCallback onOpen;

  const _CompetitionOperationsCard({
    required this.record,
    required this.matchEntries,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLeague = record.kind == MatchCompetitionRecord.kindLeague;
    final accent = _competitionAccent(context, record.kind);
    final entries = MatchCompetitionService.competitionEntries(
      kind: record.kind,
      competitionName: record.name,
      entries: matchEntries,
    );
    final progress = _CompetitionProgress.from(
      record: record,
      entries: entries,
    );
    final nextAction = _competitionNextActionLabel(
      l10n,
      record,
      progress,
      entries,
    );
    final details = <String>[
      isLeague ? l10n.matchKindLeague : l10n.matchKindTournament,
      if (record.season.trim().isNotEmpty) record.season.trim(),
      if (record.venue.trim().isNotEmpty) record.venue.trim(),
    ];
    return Container(
      key: ValueKey('competition-card-${record.id}'),
      decoration: AppSurfaces.cardDecoration(
        scheme,
        theme.brightness,
      ).copyWith(
        borderRadius: AppRadius.small,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
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
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: AppRadius.small,
                      ),
                      child: Icon(
                        isLeague
                            ? Icons.leaderboard_outlined
                            : Icons.account_tree,
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
                          Text(
                            details.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _CompetitionStatusBadge(
                      label: record.isFinished
                          ? l10n.matchCompetitionStatusFinished
                          : l10n.matchCompetitionStatusActive,
                      active: !record.isFinished,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nextAction,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      progress.label(l10n),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: AppRadius.full,
                  child: LinearProgressIndicator(
                    value: progress.value,
                    minHeight: 5,
                    backgroundColor:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.72),
                    color: accent,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.groups_2_outlined,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Expanded(
                      child: Text(
                        l10n.matchCompetitionCardSummary(
                          record.teams.length,
                          entries.length,
                        ),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompetitionStatusBadge extends StatelessWidget {
  final String label;
  final bool active;

  const _CompetitionStatusBadge({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color =
        active ? _competitionPositiveColor(context) : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.small,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetitionDetailScreen extends StatefulWidget {
  final MatchCompetitionRecord record;
  final MatchCompetitionService competitionService;
  final TrainingService trainingService;
  final String sportId;
  final bool readOnly;
  final String managedTeamName;
  final String fallbackTeamName;
  final CompetitionFixtureRecordHandler? onOpenFixtureRecord;

  const _CompetitionDetailScreen({
    required this.record,
    required this.competitionService,
    required this.trainingService,
    required this.sportId,
    required this.readOnly,
    required this.managedTeamName,
    required this.fallbackTeamName,
    this.onOpenFixtureRecord,
  });

  @override
  State<_CompetitionDetailScreen> createState() =>
      _CompetitionDetailScreenState();
}

class _CompetitionDetailScreenState extends State<_CompetitionDetailScreen> {
  late MatchCompetitionRecord _record;
  late _CompetitionDetailView _selectedView;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
    _selectedView = _record.kind == MatchCompetitionRecord.kindLeague
        ? _CompetitionDetailView.schedule
        : _CompetitionDetailView.bracket;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TrainingEntry>>(
      stream: widget.trainingService.watchEntries(),
      builder: (context, snapshot) {
        final matchEntries = filterEntriesForSport(
          snapshot.data ?? const <TrainingEntry>[],
          widget.sportId,
        ).where((entry) => entry.isMatch).toList(growable: false);
        return _buildDetail(context, matchEntries);
      },
    );
  }

  Widget _buildDetail(BuildContext context, List<TrainingEntry> matchEntries) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLeague = _record.kind == MatchCompetitionRecord.kindLeague;
    final accent = _competitionAccent(context, _record.kind);
    final effectiveTeams = MatchCompetitionService.teamsWithManagedTeam(
      kind: _record.kind,
      teams: _record.teams,
      managedTeamName: widget.managedTeamName,
      fallbackTeamName: widget.fallbackTeamName,
      replaceLeagueFirstTeam: true,
    );
    final managedTeam = widget.managedTeamName.trim();
    final fallbackTeamKey = MatchCompetitionService.normalizeTeamKey(
      widget.fallbackTeamName,
    );
    String displayTeam(String team) {
      if (managedTeam.isEmpty ||
          fallbackTeamKey.isEmpty ||
          MatchCompetitionService.normalizeTeamKey(team) != fallbackTeamKey) {
        return team;
      }
      return managedTeam;
    }

    final effectiveRecord = _record.copyWith(
      teams: effectiveTeams,
      fixtures: _record.fixtures
          .map(
            (fixture) => fixture.copyWith(
              homeTeam: displayTeam(fixture.homeTeam),
              awayTeam: displayTeam(fixture.awayTeam),
            ),
          )
          .toList(growable: false),
    );
    final entries = MatchCompetitionService.competitionEntries(
      kind: _record.kind,
      competitionName: _record.name,
      competitionId: _record.id,
      entries: matchEntries,
    );
    final ownTeamName = widget.managedTeamName.trim().isEmpty
        ? widget.fallbackTeamName
        : widget.managedTeamName.trim();
    final operationPanel = isLeague
        ? _LeagueOperationsPreview(
            record: effectiveRecord,
            entries: entries,
            ownTeamName: ownTeamName,
            fallbackTeamName: widget.fallbackTeamName,
            preferManagedTeamName: widget.managedTeamName.trim().isNotEmpty,
          )
        : _TournamentOperationsPreview(
            record: effectiveRecord,
            entries: entries,
            ownTeamName: ownTeamName,
            onOpenFixture: widget.readOnly ? null : _openFixture,
          );
    final teamsPanel = _CompetitionTeamsPreview(
      teams: effectiveRecord.teams,
      accent: accent,
      ownTeamName: ownTeamName,
    );
    final fixturesPanel = _CompetitionFixturesPreview(
      record: effectiveRecord,
      entries: entries,
      accent: accent,
      onOpenFixture: widget.readOnly ? null : _openFixture,
      onOpenSchedulePlanner: widget.readOnly ? null : _openSchedulePlanner,
    );

    final viewSegments = <ButtonSegment<_CompetitionDetailView>>[
      ButtonSegment<_CompetitionDetailView>(
        value: _CompetitionDetailView.schedule,
        icon: const Icon(Icons.event_note_outlined),
        label: Text(l10n.matchCompetitionScheduleTab),
      ),
      ButtonSegment<_CompetitionDetailView>(
        value: isLeague
            ? _CompetitionDetailView.standings
            : _CompetitionDetailView.bracket,
        icon: Icon(
          isLeague ? Icons.leaderboard_outlined : Icons.account_tree_outlined,
        ),
        label: Text(
          isLeague
              ? l10n.matchCompetitionStandingsTab
              : l10n.matchCompetitionBracketTab,
        ),
      ),
      ButtonSegment<_CompetitionDetailView>(
        value: _CompetitionDetailView.teams,
        icon: const Icon(Icons.groups_2_outlined),
        label: Text(l10n.matchCompetitionTeamsViewTab),
      ),
    ];
    final activePanel = switch (_selectedView) {
      _CompetitionDetailView.schedule => fixturesPanel,
      _CompetitionDetailView.standings => operationPanel,
      _CompetitionDetailView.bracket => operationPanel,
      _CompetitionDetailView.teams => teamsPanel,
    };

    return Scaffold(
      body: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  0,
                ),
                child: Row(
                  children: [
                    const BackButton(),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _record.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    AppBarActionButton.label(
                      key: const ValueKey('competition-detail-edit'),
                      icon: const Icon(Icons.edit_outlined),
                      label: l10n.matchCompetitionEditButton,
                      tooltip: l10n.matchCompetitionEditButton,
                      onPressed: widget.readOnly
                          ? null
                          : () => Navigator.of(
                                context,
                              ).pop(_CompetitionDetailAction.edit),
                      maxLabelWidth: 56,
                    ),
                    AppBarActionButton.icon(
                      key: const ValueKey('competition-detail-delete'),
                      icon: Icons.delete_outline,
                      tooltip: l10n.matchCompetitionDeleteButton,
                      onPressed: widget.readOnly
                          ? null
                          : () => Navigator.of(
                                context,
                              ).pop(_CompetitionDetailAction.delete),
                      margin: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    0,
                    AppSpacing.sm,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<_CompetitionDetailView>(
                        key: const ValueKey('competition-detail-view-tabs'),
                        segments: viewSegments,
                        selected: {_selectedView},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) {
                          setState(() => _selectedView = selection.first);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      activePanel,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFixture(CompetitionFixtureState fixture) async {
    final updated = await Navigator.of(context).push<MatchCompetitionRecord>(
      AppPageRoute(
        builder: (_) => _CompetitionFixtureEditorScreen(
          service: widget.competitionService,
          competition: _record,
          fixtureState: fixture,
          managedTeamAliases: [
            widget.managedTeamName,
            widget.fallbackTeamName,
          ],
          readOnly: widget.readOnly,
          onOpenFixtureRecord: widget.onOpenFixtureRecord,
        ),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _record = updated);
  }

  Future<void> _openSchedulePlanner() async {
    final updated = await Navigator.of(context).push<MatchCompetitionRecord>(
      AppPageRoute(
        builder: (_) => _CompetitionSchedulePlannerScreen(
          service: widget.competitionService,
          competition: _record,
        ),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _record = updated);
  }
}

class _CompetitionTeamsPreview extends StatelessWidget {
  final List<String> teams;
  final Color accent;
  final String ownTeamName;

  const _CompetitionTeamsPreview({
    required this.teams,
    required this.accent,
    required this.ownTeamName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return _PreviewPanel(
      icon: Icons.groups_2_outlined,
      title: l10n.matchCompetitionTeamsListTitle,
      accent: accent,
      child: teams.isEmpty
          ? _EmptyPreview(text: l10n.matchCompetitionNoTeams)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.matchCompetitionTeamCount(teams.length),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: AppRadius.small,
                  child: Column(
                    children: [
                      Container(
                        color: accent.withValues(alpha: 0.12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 42,
                              child: Text(
                                l10n.matchCompetitionParticipantOrderColumn,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                l10n.matchCompetitionParticipantTeamColumn,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final item in teams.indexed)
                        _CompetitionParticipantRow(
                          index: item.$1,
                          team: item.$2,
                          isOwnTeam: MatchCompetitionService.normalizeTeamKey(
                                item.$2,
                              ) ==
                              MatchCompetitionService.normalizeTeamKey(
                                ownTeamName,
                              ),
                          accent: accent,
                          showDivider: item.$1 < teams.length - 1,
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _CompetitionParticipantRow extends StatelessWidget {
  final int index;
  final String team;
  final bool isOwnTeam;
  final Color accent;
  final bool showDivider;

  const _CompetitionParticipantRow({
    required this.index,
    required this.team,
    required this.isOwnTeam,
    required this.accent,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isOwnTeam ? accent.withValues(alpha: 0.07) : null,
        border: showDivider
            ? Border(bottom: BorderSide(color: scheme.outlineVariant))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Text(
                '${index + 1}'.padLeft(2, '0'),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      team,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (isOwnTeam) ...[
                    const SizedBox(width: AppSpacing.xs),
                    _CompetitionOwnTeamBadge(accent: accent),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompetitionFixturesPreview extends StatelessWidget {
  final MatchCompetitionRecord record;
  final List<TrainingEntry> entries;
  final Color accent;
  final ValueChanged<CompetitionFixtureState>? onOpenFixture;
  final VoidCallback? onOpenSchedulePlanner;

  const _CompetitionFixturesPreview({
    required this.record,
    required this.entries,
    required this.accent,
    this.onOpenFixture,
    this.onOpenSchedulePlanner,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLeague = record.kind == MatchCompetitionRecord.kindLeague;
    final fixtures = MatchCompetitionService.resolveFixtureStates(
      competition: record,
      entries: entries,
    );
    final scheduledCount = fixtures
        .where(
          (fixture) =>
              fixture.fixture.scheduledAt != null && !fixture.isRecorded,
        )
        .length;
    final completedCount =
        fixtures.where((fixture) => fixture.isRecorded).length;
    final unscheduledCount = fixtures
        .where(
          (fixture) =>
              fixture.fixture.scheduledAt == null && !fixture.isRecorded,
        )
        .length;
    final fixturesByRound = <int, List<CompetitionFixtureState>>{};
    for (final fixture in fixtures) {
      (fixturesByRound[fixture.fixture.roundNumber] ??=
              <CompetitionFixtureState>[])
          .add(fixture);
    }
    return _PreviewPanel(
      icon: Icons.event_note_outlined,
      title: l10n.matchCompetitionFixturesTitle,
      accent: accent,
      action: AppBarActionButton.label(
        key: const ValueKey('competition-schedule-plan-action'),
        icon: const Icon(Icons.calendar_month_outlined),
        label: l10n.matchCompetitionFixtureSchedulePlanAction,
        tooltip: l10n.matchCompetitionFixtureSchedulePlanAction,
        onPressed: onOpenSchedulePlanner,
        margin: EdgeInsets.zero,
        maxLabelWidth: 76,
      ),
      child: fixtures.isEmpty
          ? _EmptyPreview(text: l10n.matchCompetitionFixturesEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CompetitionFixtureSummary(
                  scheduledCount: scheduledCount,
                  completedCount: completedCount,
                  unscheduledCount: unscheduledCount,
                  totalCount: fixtures.length,
                  accent: accent,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final round in fixturesByRound.entries) ...[
                  _CompetitionFixtureRoundGroup(
                    label: isLeague
                        ? l10n.matchCompetitionFixtureRound(round.key)
                        : matchTournamentStageLabel(
                            l10n,
                            round.value.first.fixture.stage,
                          ),
                    fixtures: round.value,
                    accent: accent,
                    onOpenFixture: onOpenFixture,
                  ),
                  if (round.key != fixturesByRound.keys.last)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
    );
  }
}

class _CompetitionFixtureSummary extends StatelessWidget {
  final int scheduledCount;
  final int completedCount;
  final int unscheduledCount;
  final int totalCount;
  final Color accent;

  const _CompetitionFixtureSummary({
    required this.scheduledCount,
    required this.completedCount,
    required this.unscheduledCount,
    required this.totalCount,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: AppRadius.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.matchCompetitionFixtureScheduleCount(
              scheduledCount,
              totalCount,
            ),
            textAlign: TextAlign.end,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _CompetitionFixtureSummaryMetric(
                  value: scheduledCount,
                  label: l10n.matchCompetitionFixtureStatusScheduled,
                  color: accent,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: scheme.outlineVariant,
              ),
              Expanded(
                child: _CompetitionFixtureSummaryMetric(
                  value: completedCount,
                  label: l10n.matchCompetitionFixtureStatusCompleted,
                  color: _competitionPositiveColor(context),
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: scheme.outlineVariant,
              ),
              Expanded(
                child: _CompetitionFixtureSummaryMetric(
                  value: unscheduledCount,
                  label: l10n.matchCompetitionFixtureUnscheduled,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompetitionFixtureSummaryMetric extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _CompetitionFixtureSummaryMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '$value',
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CompetitionFixtureRoundGroup extends StatelessWidget {
  final String label;
  final List<CompetitionFixtureState> fixtures;
  final Color accent;
  final ValueChanged<CompetitionFixtureState>? onOpenFixture;

  const _CompetitionFixtureRoundGroup({
    required this.label,
    required this.fixtures,
    required this.accent,
    this.onOpenFixture,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.small,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sm),
              ),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Column(
              children: [
                for (final item in fixtures.indexed)
                  _CompetitionFixtureRow(
                    fixture: item.$2,
                    showDivider: item.$1 < fixtures.length - 1,
                    dividerColor: scheme.outlineVariant,
                    onOpenFixture: onOpenFixture,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetitionFixtureRow extends StatelessWidget {
  final CompetitionFixtureState fixture;
  final bool showDivider;
  final Color dividerColor;
  final ValueChanged<CompetitionFixtureState>? onOpenFixture;

  const _CompetitionFixtureRow({
    required this.fixture,
    required this.showDivider,
    required this.dividerColor,
    this.onOpenFixture,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final homeScore = fixture.scoreFor(fixture.homeTeam);
    final awayScore = fixture.scoreFor(fixture.awayTeam);
    final scheduledAt = fixture.fixture.scheduledAt;
    final date = scheduledAt == null
        ? l10n.matchCompetitionFixtureUnscheduled
        : '${MaterialLocalizations.of(context).formatShortDate(scheduledAt)} · '
            '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(scheduledAt))}';
    final statusLabel = _fixtureStatusLabel(l10n, fixture);
    final statusColor = _fixtureStatusColor(context, fixture);
    final canOpen = onOpenFixture != null;
    void openFixture() {
      if (!canOpen) return;
      onOpenFixture?.call(fixture);
    }

    final row = DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: dividerColor))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fixture.homeTeam.isEmpty
                              ? l10n.matchCompetitionFixtureTbd
                              : fixture.homeTeam,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: fixture.winner == fixture.homeTeam
                                ? FontWeight.w900
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      SizedBox(
                        width: 62,
                        child: Text(
                          fixture.isRecorded
                              ? '${homeScore ?? '-'} : ${awayScore ?? '-'}'
                              : l10n.matchCompetitionFixtureVersus,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: fixture.isRecorded
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          fixture.awayTeam.isEmpty
                              ? l10n.matchCompetitionFixtureTbd
                              : fixture.awayTeam,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: fixture.winner == fixture.awayTeam
                                ? FontWeight.w900
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      _CompetitionFixtureStatusBadge(
                        label: statusLabel,
                        color: statusColor,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (canOpen) ...[
              const SizedBox(width: AppSpacing.xs),
              _CompetitionRowAction(
                key: ValueKey(
                  'competition-fixture-action-${fixture.fixture.id}',
                ),
                icon: Icons.tune_rounded,
                tooltip: l10n.matchCompetitionFixtureManageAction,
                onPressed: openFixture,
              ),
            ],
          ],
        ),
      ),
    );
    return Semantics(
      button: canOpen,
      label: l10n.matchCompetitionFixtureManageAction,
      child: GestureDetector(onTap: canOpen ? openFixture : null, child: row),
    );
  }
}

class _CompetitionFixtureStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _CompetitionFixtureStatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Color _fixtureStatusColor(
  BuildContext context,
  CompetitionFixtureState fixture,
) {
  final scheme = Theme.of(context).colorScheme;
  if (fixture.isCancelled) return scheme.error;
  if (fixture.fixture.isPostponed) return scheme.tertiary;
  if (fixture.isRecorded) return _competitionPositiveColor(context);
  return scheme.primary;
}

String _fixtureStatusLabel(
  AppLocalizations l10n,
  CompetitionFixtureState fixture,
) {
  if (fixture.isCancelled) return l10n.matchCompetitionFixtureStatusCancelled;
  if (fixture.fixture.isPostponed) {
    return l10n.matchCompetitionFixtureStatusPostponed;
  }
  if (fixture.isRecorded) return l10n.matchCompetitionFixtureStatusCompleted;
  return l10n.matchCompetitionFixtureStatusScheduled;
}

class _LeagueOperationsPreview extends StatelessWidget {
  final MatchCompetitionRecord record;
  final List<TrainingEntry> entries;
  final String ownTeamName;
  final String fallbackTeamName;
  final bool preferManagedTeamName;

  const _LeagueOperationsPreview({
    required this.record,
    required this.entries,
    required this.ownTeamName,
    required this.fallbackTeamName,
    required this.preferManagedTeamName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final accent = _competitionAccent(
      context,
      MatchCompetitionRecord.kindLeague,
    );
    final standings = record.fixtures.isEmpty
        ? MatchCompetitionService.buildLeagueStandings(
            competitionName: record.name,
            registeredTeams: record.teams,
            entries: entries,
            ownTeamName: ownTeamName,
            preferOwnTeamName: preferManagedTeamName,
            ownTeamAliases: [fallbackTeamName],
          )
        : MatchCompetitionService.buildLeagueStandingsForCompetition(
            competition: record,
            entries: entries,
          );
    return _PreviewPanel(
      icon: Icons.leaderboard_outlined,
      title: l10n.matchLeagueStandingsTitle,
      accent: accent,
      child: standings.isEmpty
          ? _EmptyPreview(text: l10n.matchCompetitionNoTeams)
          : ClipRRect(
              borderRadius: AppRadius.small,
              child: Column(
                children: [
                  Container(
                    color: accent.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs,
                    ),
                    child: _LeagueStandingsTableHeader(
                      rank: l10n.matchCompetitionStandingsRankColumn,
                      team: l10n.matchCompetitionStandingsTeamColumn,
                      played: l10n.matchCompetitionStandingsPlayedColumn,
                      record: l10n.matchCompetitionStandingsRecordColumn,
                      difference:
                          l10n.matchCompetitionStandingsGoalDifferenceColumn,
                      points: l10n.matchCompetitionStandingsPointsColumn,
                      color: accent,
                    ),
                  ),
                  for (final item in standings.indexed)
                    _LeagueStandingPreviewRow(
                      rank: item.$1 + 1,
                      row: item.$2,
                      accent: accent,
                      showDivider: item.$1 < standings.length - 1,
                      dividerColor: scheme.outlineVariant,
                    ),
                ],
              ),
            ),
    );
  }
}

class _LeagueStandingsTableHeader extends StatelessWidget {
  final String rank;
  final String team;
  final String played;
  final String record;
  final String difference;
  final String points;
  final Color color;

  const _LeagueStandingsTableHeader({
    required this.rank,
    required this.team,
    required this.played,
    required this.record,
    required this.difference,
    required this.points,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        );
    return Row(
      children: [
        SizedBox(width: 34, child: Text(rank, style: textStyle)),
        Expanded(child: Text(team, style: textStyle)),
        SizedBox(
          width: 28,
          child: Text(played, textAlign: TextAlign.center, style: textStyle),
        ),
        SizedBox(
          width: 50,
          child: Text(record, textAlign: TextAlign.center, style: textStyle),
        ),
        SizedBox(
          width: 34,
          child: Text(
            difference,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(points, textAlign: TextAlign.center, style: textStyle),
        ),
      ],
    );
  }
}

class _LeagueStandingPreviewRow extends StatelessWidget {
  final int rank;
  final LeagueStandingRow row;
  final Color accent;
  final bool showDivider;
  final Color dividerColor;

  const _LeagueStandingPreviewRow({
    required this.rank,
    required this.row,
    required this.accent,
    required this.showDivider,
    required this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final goalDifference = row.goalDifference > 0
        ? '+${row.goalDifference}'
        : '${row.goalDifference}';
    final textStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w800,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: dividerColor))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: AppRadius.small,
                  ),
                  child: Text(
                    '$rank',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
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
            SizedBox(
              width: 28,
              child: Text(
                '${row.played}',
                textAlign: TextAlign.center,
                style: textStyle,
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                '${row.wins}-${row.draws}-${row.losses}',
                textAlign: TextAlign.center,
                style: textStyle,
              ),
            ),
            SizedBox(
              width: 34,
              child: Text(
                goalDifference,
                textAlign: TextAlign.center,
                style: textStyle?.copyWith(
                  color: row.goalDifference == 0
                      ? scheme.onSurfaceVariant
                      : row.goalDifference > 0
                          ? _competitionPositiveColor(context)
                          : scheme.error,
                ),
              ),
            ),
            SizedBox(
              width: 34,
              child: Text(
                '${row.points}',
                textAlign: TextAlign.center,
                style: textStyle?.copyWith(
                  color: accent,
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

class _TournamentOperationsPreview extends StatefulWidget {
  final MatchCompetitionRecord record;
  final List<TrainingEntry> entries;
  final String ownTeamName;
  final ValueChanged<CompetitionFixtureState>? onOpenFixture;

  const _TournamentOperationsPreview({
    required this.record,
    required this.entries,
    required this.ownTeamName,
    this.onOpenFixture,
  });

  @override
  State<_TournamentOperationsPreview> createState() =>
      _TournamentOperationsPreviewState();
}

class _TournamentOperationsPreviewState
    extends State<_TournamentOperationsPreview> {
  bool _imageShareInProgress = false;

  Future<void> _shareBracketImage() async {
    if (_imageShareInProgress) return;
    setState(() => _imageShareInProgress = true);
    try {
      await _shareTournamentBracketImage(
        context: context,
        record: widget.record,
        bracket: MatchCompetitionService.resolveTournamentBracket(
          competition: widget.record,
          entries: widget.entries,
        ),
        ownTeamName: widget.ownTeamName,
        fixtureStatesBySlot: {
          for (final fixture in MatchCompetitionService.resolveFixtureStates(
            competition: widget.record,
            entries: widget.entries,
          ))
            fixture.fixture.slotNumber: fixture,
        },
      );
      if (!mounted) return;
      AppFeedback.showSuccess(
        context,
        text: AppLocalizations.of(
          context,
        )!
            .matchTournamentImageExportedFeedback,
      );
    } catch (error, stackTrace) {
      debugPrint('Tournament bracket image export failed: $error\n$stackTrace');
      if (!mounted) return;
      AppFeedback.showMessage(
        context,
        text: AppLocalizations.of(
          context,
        )!
            .matchTournamentImageExportFailedFeedback,
      );
    } finally {
      if (mounted) {
        setState(() => _imageShareInProgress = false);
      } else {
        _imageShareInProgress = false;
      }
    }
  }

  void _openFullScreen(
    TournamentBracket bracket,
    Map<int, CompetitionFixtureState> fixtureStatesBySlot,
  ) {
    Navigator.of(context).push<void>(
      AppPageRoute(
        builder: (_) => _TournamentBracketFullScreen(
          record: widget.record,
          bracket: bracket,
          ownTeamName: widget.ownTeamName,
          fixtureStatesBySlot: fixtureStatesBySlot,
          onOpenFixture: widget.onOpenFixture,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _competitionAccent(
      context,
      MatchCompetitionRecord.kindTournament,
    );
    final bracket = MatchCompetitionService.resolveTournamentBracket(
      competition: widget.record,
      entries: widget.entries,
    );
    final fixtureStates = MatchCompetitionService.resolveFixtureStates(
      competition: widget.record,
      entries: widget.entries,
    );
    final fixtureStatesBySlot = <int, CompetitionFixtureState>{
      for (final fixture in fixtureStates)
        if (fixture.isReady) fixture.fixture.slotNumber: fixture,
    };
    return Container(
      decoration: BoxDecoration(
        color: AppSurfaces.subtleColor(scheme, theme.brightness),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: accent.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.34 : 0.18,
          ),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree_outlined, color: accent, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.matchTournamentBracketTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              AppBarActionButton.label(
                key: const ValueKey('competition-tournament-image-button'),
                icon: const Icon(Icons.ios_share_rounded),
                label: l10n.matchTournamentImageAction,
                tooltip: l10n.matchTournamentImageTooltip,
                onPressed: bracket.rounds.isEmpty || _imageShareInProgress
                    ? null
                    : () => unawaited(_shareBracketImage()),
                maxLabelWidth: 54,
              ),
              AppBarActionButton.icon(
                key: const ValueKey('competition-tournament-expand-button'),
                icon: Icons.open_in_full_rounded,
                tooltip: l10n.matchTournamentOpenFullScreen,
                onPressed: bracket.rounds.isEmpty
                    ? null
                    : () => _openFullScreen(bracket, fixtureStatesBySlot),
                margin: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (bracket.rounds.isEmpty)
            _EmptyPreview(text: l10n.matchCompetitionNoTeams)
          else
            _TournamentBracketViewport(
              bracket: bracket,
              ownTeamName: widget.ownTeamName,
              fixtureStatesBySlot: fixtureStatesBySlot,
              onOpenFixture: widget.onOpenFixture,
            ),
          if (fixtureStates.any((fixture) => fixture.isRecorded)) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(color: scheme.outlineVariant),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.matchTournamentRecordedProgressTitle,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final fixture in fixtureStates.where(
              (fixture) => fixture.isRecorded,
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _TournamentFixtureProgressRow(fixture: fixture),
              ),
          ],
        ],
      ),
    );
  }
}

Future<void> _shareTournamentBracketImage({
  required BuildContext context,
  required MatchCompetitionRecord record,
  required TournamentBracket bracket,
  required String ownTeamName,
  Map<int, CompetitionFixtureState> fixtureStatesBySlot =
      const <int, CompetitionFixtureState>{},
}) async {
  if (bracket.rounds.isEmpty) return;
  final bytes = await captureWidgetPng(
    context,
    size: const Size(2000, 1200),
    pixelRatio: 1.5,
    child: _TournamentBracketShareImage(
      record: record,
      bracket: bracket,
      ownTeamName: ownTeamName,
      fixtureStatesBySlot: fixtureStatesBySlot,
    ),
  );
  await sharePngImage(
    pngImage: bytes,
    filename: timestampedImageFilename('tournament-bracket-${record.name}'),
    title: record.name,
  );
}

class _TournamentBracketFullScreen extends StatefulWidget {
  final MatchCompetitionRecord record;
  final TournamentBracket bracket;
  final String ownTeamName;
  final Map<int, CompetitionFixtureState> fixtureStatesBySlot;
  final ValueChanged<CompetitionFixtureState>? onOpenFixture;

  const _TournamentBracketFullScreen({
    required this.record,
    required this.bracket,
    required this.ownTeamName,
    this.fixtureStatesBySlot = const <int, CompetitionFixtureState>{},
    this.onOpenFixture,
  });

  @override
  State<_TournamentBracketFullScreen> createState() =>
      _TournamentBracketFullScreenState();
}

class _TournamentBracketFullScreenState
    extends State<_TournamentBracketFullScreen> {
  bool _imageShareInProgress = false;

  Future<void> _shareBracketImage() async {
    if (_imageShareInProgress) return;
    setState(() => _imageShareInProgress = true);
    try {
      await _shareTournamentBracketImage(
        context: context,
        record: widget.record,
        bracket: widget.bracket,
        ownTeamName: widget.ownTeamName,
        fixtureStatesBySlot: widget.fixtureStatesBySlot,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(
        context,
        text: AppLocalizations.of(
          context,
        )!
            .matchTournamentImageExportedFeedback,
      );
    } catch (error, stackTrace) {
      debugPrint('Tournament bracket image export failed: $error\n$stackTrace');
      if (!mounted) return;
      AppFeedback.showMessage(
        context,
        text: AppLocalizations.of(
          context,
        )!
            .matchTournamentImageExportFailedFeedback,
      );
    } finally {
      if (mounted) {
        setState(() => _imageShareInProgress = false);
      } else {
        _imageShareInProgress = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.record.name),
        actions: [
          AppBarActionButton.label(
            key: const ValueKey(
              'competition-tournament-fullscreen-image-button',
            ),
            icon: const Icon(Icons.ios_share_rounded),
            label: l10n.matchTournamentImageAction,
            tooltip: l10n.matchTournamentImageTooltip,
            onPressed: _imageShareInProgress
                ? null
                : () => unawaited(_shareBracketImage()),
            maxLabelWidth: 54,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: _TournamentBracketViewport(
            bracket: widget.bracket,
            ownTeamName: widget.ownTeamName,
            fullScreen: true,
            fixtureStatesBySlot: widget.fixtureStatesBySlot,
            onOpenFixture: widget.onOpenFixture,
          ),
        ),
      ),
    );
  }
}

class _TournamentBracketViewport extends StatefulWidget {
  final TournamentBracket bracket;
  final String ownTeamName;
  final bool fullScreen;
  final Map<int, CompetitionFixtureState> fixtureStatesBySlot;
  final ValueChanged<CompetitionFixtureState>? onOpenFixture;

  const _TournamentBracketViewport({
    required this.bracket,
    required this.ownTeamName,
    this.fullScreen = false,
    this.fixtureStatesBySlot = const <int, CompetitionFixtureState>{},
    this.onOpenFixture,
  });

  @override
  State<_TournamentBracketViewport> createState() =>
      _TournamentBracketViewportState();
}

class _TournamentBracketViewportState
    extends State<_TournamentBracketViewport> {
  static const double _minScale = 0.14;
  static const double _maxScale = 2.4;
  static const double _zoomStep = 1.22;

  final TransformationController _controller = TransformationController();
  Matrix4? _initialMatrix;
  String? _layoutSignature;
  Size _viewportSize = const Size(360, 420);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTransformChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTransformChanged);
    _controller.dispose();
    super.dispose();
  }

  double get _currentScale => _controller.value
      .getMaxScaleOnAxis()
      .clamp(_minScale, _maxScale)
      .toDouble();

  void _handleTransformChanged() {
    if (mounted) setState(() {});
  }

  void _scheduleInitialTransform({
    required Size canvasSize,
    required Size viewportSize,
  }) {
    final signature = '${canvasSize.width}:${canvasSize.height}:'
        '${viewportSize.width}:${viewportSize.height}:${widget.fullScreen}';
    if (_layoutSignature == signature) return;
    _layoutSignature = signature;
    final fitScale = math.min(
      (viewportSize.width - 24) / canvasSize.width,
      (viewportSize.height - 24) / canvasSize.height,
    );
    final scale = fitScale.clamp(_minScale, 1.0).toDouble();
    final offset = Offset(
      (viewportSize.width - canvasSize.width * scale) / 2,
      math.max(12, (viewportSize.height - canvasSize.height * scale) / 2),
    );
    final matrix = _matrixFor(scale: scale, offset: offset);
    _initialMatrix = Matrix4.copy(matrix);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _layoutSignature != signature) return;
      _controller.value = Matrix4.copy(matrix);
    });
  }

  Matrix4 _matrixFor({required double scale, required Offset offset}) {
    final matrix = Matrix4.identity();
    matrix.setEntry(0, 0, scale);
    matrix.setEntry(1, 1, scale);
    matrix.setEntry(2, 2, scale);
    matrix.setEntry(0, 3, offset.dx);
    matrix.setEntry(1, 3, offset.dy);
    return matrix;
  }

  void _zoomBy(double factor) {
    final currentScale = _currentScale;
    final nextScale =
        (currentScale * factor).clamp(_minScale, _maxScale).toDouble();
    if ((nextScale - currentScale).abs() < 0.001) return;
    final translation = _controller.value.getTranslation();
    final focalPoint = Offset(
      _viewportSize.width / 2,
      _viewportSize.height / 2,
    );
    final worldFocalPoint = Offset(
      (focalPoint.dx - translation.x) / currentScale,
      (focalPoint.dy - translation.y) / currentScale,
    );
    _controller.value = _matrixFor(
      scale: nextScale,
      offset: Offset(
        focalPoint.dx - worldFocalPoint.dx * nextScale,
        focalPoint.dy - worldFocalPoint.dy * nextScale,
      ),
    );
  }

  void _resetZoom() {
    final matrix = _initialMatrix;
    _controller.value =
        matrix == null ? Matrix4.identity() : Matrix4.copy(matrix);
  }

  Widget _zoomButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return AppBarActionButton.icon(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: icon,
      margin: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final geometry = _TournamentBracketGeometry(widget.bracket);
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final previewHeight = switch (widget.bracket.slotCount) {
          <= 4 => 300.0,
          <= 8 => 350.0,
          _ => 430.0,
        };
        final height = widget.fullScreen && constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : previewHeight;
        final viewerHeight = math.max(220.0, height - 44);
        _viewportSize = Size(constraints.maxWidth, viewerHeight);
        _scheduleInitialTransform(
          canvasSize: geometry.size,
          viewportSize: _viewportSize,
        );
        return SizedBox(
          height: height,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _zoomButton(
                    tooltip: l10n.matchTournamentZoomOut,
                    icon: Icons.zoom_out_rounded,
                    onPressed: _currentScale > _minScale + 0.01
                        ? () => _zoomBy(1 / _zoomStep)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  _zoomButton(
                    tooltip: l10n.matchTournamentZoomReset,
                    icon: Icons.restart_alt_rounded,
                    onPressed: _resetZoom,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  _zoomButton(
                    tooltip: l10n.matchTournamentZoomIn,
                    icon: Icons.zoom_in_rounded,
                    onPressed: _currentScale < _maxScale - 0.01
                        ? () => _zoomBy(_zoomStep)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.small,
                  child: ColoredBox(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.34 : 0.48,
                    ),
                    child: InteractiveViewer(
                      key: const ValueKey(
                        'competition-tournament-bracket-viewport',
                      ),
                      transformationController: _controller,
                      minScale: _minScale,
                      maxScale: _maxScale,
                      boundaryMargin: const EdgeInsets.all(240),
                      constrained: false,
                      child: _TournamentBracketCanvas(
                        bracket: widget.bracket,
                        ownTeamName: widget.ownTeamName,
                        geometry: geometry,
                        fixtureStatesBySlot: widget.fixtureStatesBySlot,
                        onOpenFixture: widget.onOpenFixture,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    return content;
  }
}

class _TournamentBracketGeometry {
  static const double horizontalPadding = 24;
  static const double cardWidth = 184;
  static const double cardHeight = 80;
  static const double horizontalGap = 40;
  static const double roundGap = 48;
  static const double roundLabelHeight = 22;
  static const double topPadding = 12;
  static const double bottomPadding = 28;
  static const double championWidth = 150;
  static const double championGap = 24;

  final TournamentBracket bracket;

  const _TournamentBracketGeometry(this.bracket);

  int get finalRoundIndex => bracket.rounds.length - 1;

  int get firstRoundMatchCount => bracket.rounds.first.matches.length;

  double get width =>
      horizontalPadding * 2 +
      firstRoundMatchCount * cardWidth +
      math.max(0, firstRoundMatchCount - 1) * horizontalGap;

  double get firstRoundPitch => cardWidth + horizontalGap;

  double get centerX => width / 2;

  double get championLabelTop => topPadding;

  Rect get championRect => Rect.fromLTWH(
        centerX - championWidth / 2,
        championLabelTop + roundLabelHeight,
        championWidth,
        cardHeight,
      );

  double get finalRoundTop =>
      championRect.bottom + championGap + roundLabelHeight + 8;

  double roundTop(int roundIndex) =>
      finalRoundTop + (finalRoundIndex - roundIndex) * (cardHeight + roundGap);

  double roundLabelTop(int roundIndex) =>
      roundTop(roundIndex) - roundLabelHeight - 8;

  double matchCenterX(int roundIndex, int matchIndex) {
    final scale = math.pow(2, roundIndex).toDouble();
    final sourceOffset = (scale - 1) / 2;
    return horizontalPadding +
        cardWidth / 2 +
        firstRoundPitch * (scale * matchIndex + sourceOffset);
  }

  Rect matchRect(int roundIndex, int matchIndex) => Rect.fromCenter(
        center: Offset(
          matchCenterX(roundIndex, matchIndex),
          roundTop(roundIndex) + cardHeight / 2,
        ),
        width: cardWidth,
        height: cardHeight,
      );

  Size get size => Size(
        width,
        roundTop(0) + cardHeight + bottomPadding,
      );
}

class _TournamentBracketCanvas extends StatelessWidget {
  final TournamentBracket bracket;
  final String ownTeamName;
  final _TournamentBracketGeometry geometry;
  final Map<int, CompetitionFixtureState> fixtureStatesBySlot;
  final ValueChanged<CompetitionFixtureState>? onOpenFixture;

  const _TournamentBracketCanvas({
    required this.bracket,
    required this.ownTeamName,
    required this.geometry,
    this.fixtureStatesBySlot = const <int, CompetitionFixtureState>{},
    this.onOpenFixture,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accent = _competitionAccent(
      context,
      MatchCompetitionRecord.kindTournament,
    );
    return SizedBox.fromSize(
      key: const ValueKey('competition-tournament-bracket-canvas'),
      size: geometry.size,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _TournamentBracketConnectorPainter(
                bracket: bracket,
                geometry: geometry,
                color: accent.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.72 : 0.5,
                ),
              ),
            ),
          ),
          for (var roundIndex = 0;
              roundIndex < bracket.rounds.length;
              roundIndex += 1)
            Positioned(
              left: 0,
              top: geometry.roundLabelTop(roundIndex),
              width: geometry.width,
              child: Text(
                _tournamentRoundLabel(
                  l10n,
                  bracket.rounds[roundIndex].teamCapacity,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          for (var roundIndex = 0;
              roundIndex < bracket.rounds.length;
              roundIndex += 1)
            for (var matchIndex = 0;
                matchIndex < bracket.rounds[roundIndex].matches.length;
                matchIndex += 1)
              Positioned.fromRect(
                rect: geometry.matchRect(roundIndex, matchIndex),
                child: Builder(
                  builder: (context) {
                    final match =
                        bracket.rounds[roundIndex].matches[matchIndex];
                    final fixture = fixtureStatesBySlot[match.slotNumber];
                    return _TournamentBracketMatchCard(
                      match: match,
                      ownTeamName: ownTeamName,
                      accent: accent,
                      fixture: fixture,
                      onTap: fixture == null || onOpenFixture == null
                          ? null
                          : () => onOpenFixture?.call(fixture),
                      actionLabel: fixture == null
                          ? null
                          : l10n.matchCompetitionFixtureManageAction,
                    );
                  },
                ),
              ),
          Positioned(
            left: geometry.championRect.left,
            top: geometry.championLabelTop,
            width: geometry.championRect.width,
            child: Text(
              l10n.matchTournamentChampionSlot,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned.fromRect(
            rect: geometry.championRect,
            child: _TournamentChampionCard(
              sourceMatch: bracket.rounds.last.matches.single.slotNumber,
              accent: accent,
              winner: fixtureStatesBySlot[
                      bracket.rounds.last.matches.single.slotNumber]
                  ?.winner,
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentBracketConnectorPainter extends CustomPainter {
  final TournamentBracket bracket;
  final _TournamentBracketGeometry geometry;
  final Color color;

  const _TournamentBracketConnectorPainter({
    required this.bracket,
    required this.geometry,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var roundIndex = 1;
        roundIndex < bracket.rounds.length;
        roundIndex += 1) {
      for (var targetIndex = 0;
          targetIndex < bracket.rounds[roundIndex].matches.length;
          targetIndex += 1) {
        final targetRect = geometry.matchRect(roundIndex, targetIndex);
        final firstSource = geometry.matchRect(roundIndex - 1, targetIndex * 2);
        final secondSource =
            geometry.matchRect(roundIndex - 1, targetIndex * 2 + 1);
        final elbowY = (firstSource.top + targetRect.bottom) / 2;
        final path = Path()
          ..moveTo(firstSource.center.dx, firstSource.top)
          ..lineTo(firstSource.center.dx, elbowY)
          ..lineTo(targetRect.center.dx, elbowY)
          ..moveTo(secondSource.center.dx, secondSource.top)
          ..lineTo(secondSource.center.dx, elbowY)
          ..lineTo(targetRect.center.dx, elbowY)
          ..moveTo(targetRect.center.dx, elbowY)
          ..lineTo(targetRect.center.dx, targetRect.bottom);
        canvas.drawPath(path, paint);
      }
    }
    final finalRect = geometry.matchRect(geometry.finalRoundIndex, 0);
    canvas.drawLine(
      Offset(finalRect.center.dx, finalRect.top),
      Offset(geometry.championRect.center.dx, geometry.championRect.bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TournamentBracketConnectorPainter oldDelegate) =>
      oldDelegate.bracket != bracket || oldDelegate.color != color;
}

class _TournamentBracketMatchCard extends StatelessWidget {
  final TournamentBracketPair match;
  final String ownTeamName;
  final Color accent;
  final CompetitionFixtureState? fixture;
  final VoidCallback? onTap;
  final String? actionLabel;

  const _TournamentBracketMatchCard({
    required this.match,
    required this.ownTeamName,
    required this.accent,
    this.fixture,
    this.onTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final card = DecoratedBox(
      key: ValueKey('competition-tournament-match-${match.slotNumber}'),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.small,
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.2 : 0.08,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 22,
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(7),
              ),
            ),
            child: Text(
              l10n.matchTournamentPairLabel(match.slotNumber),
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: _TournamentBracketTeamLine(
              team: match.teamA,
              seed: match.seedA,
              sourceMatch: match.sourceMatchA,
              ownTeamName: ownTeamName,
              accent: accent,
              score: fixture?.homeScore,
              penaltyScore: fixture?.homePenaltyScore,
              isWinner: fixture?.winner == match.teamA,
            ),
          ),
          Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
          Expanded(
            child: _TournamentBracketTeamLine(
              team: match.teamB,
              seed: match.seedB,
              sourceMatch: match.sourceMatchB,
              ownTeamName: ownTeamName,
              accent: accent,
              score: fixture?.awayScore,
              penaltyScore: fixture?.awayPenaltyScore,
              isWinner: fixture?.winner == match.teamB,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return Semantics(
      button: true,
      label: actionLabel,
      child: GestureDetector(onTap: onTap, child: card),
    );
  }
}

class _TournamentBracketTeamLine extends StatelessWidget {
  final String team;
  final int? seed;
  final int? sourceMatch;
  final String ownTeamName;
  final Color accent;
  final int? score;
  final int? penaltyScore;
  final bool isWinner;

  const _TournamentBracketTeamLine({
    required this.team,
    required this.seed,
    required this.sourceMatch,
    required this.ownTeamName,
    required this.accent,
    this.score,
    this.penaltyScore,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final normalizedTeam = team.trim();
    final isSource = sourceMatch != null && normalizedTeam.isEmpty;
    final isBye = sourceMatch == null && normalizedTeam.isEmpty;
    final isOwnTeam = normalizedTeam.isNotEmpty &&
        normalizedTeam.toLowerCase() == ownTeamName.trim().toLowerCase();
    final label = normalizedTeam.isNotEmpty
        ? normalizedTeam
        : isSource
            ? l10n.matchTournamentWinnerSource(sourceMatch!)
            : l10n.matchTournamentByeLabel;
    return ColoredBox(
      color: isOwnTeam ? accent.withValues(alpha: 0.1) : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          children: [
            if (seed != null) ...[
              SizedBox(
                width: 22,
                child: Text(
                  '$seed',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ] else ...[
              Icon(
                isBye ? Icons.redo_rounded : Icons.call_merge_rounded,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSource || isBye
                      ? theme.colorScheme.onSurfaceVariant
                      : null,
                  fontWeight:
                      isOwnTeam || isWinner ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
            if (score != null)
              Text(
                penaltyScore == null ? '$score' : '$score ($penaltyScore)',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isWinner ? accent : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TournamentChampionCard extends StatelessWidget {
  final int sourceMatch;
  final Color accent;
  final String? winner;

  const _TournamentChampionCard({
    required this.sourceMatch,
    required this.accent,
    this.winner,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('competition-tournament-champion'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: AppRadius.small,
        border: Border.all(color: accent.withValues(alpha: 0.56)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_rounded, color: accent, size: 24),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            winner?.trim().isNotEmpty == true
                ? winner!
                : l10n.matchTournamentWinnerSource(sourceMatch),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentBracketShareImage extends StatelessWidget {
  final MatchCompetitionRecord record;
  final TournamentBracket bracket;
  final String ownTeamName;
  final Map<int, CompetitionFixtureState> fixtureStatesBySlot;

  const _TournamentBracketShareImage({
    required this.record,
    required this.bracket,
    required this.ownTeamName,
    this.fixtureStatesBySlot = const <int, CompetitionFixtureState>{},
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accent = _competitionAccent(
      context,
      MatchCompetitionRecord.kindTournament,
    );
    final geometry = _TournamentBracketGeometry(bracket);
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: AppRadius.small,
                  ),
                  child: Icon(
                    Icons.account_tree_rounded,
                    color: accent,
                    size: 30,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        l10n.matchTournamentBracketTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.matchCompetitionTeamCount(record.teams.length),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.34 : 0.48,
                  ),
                  borderRadius: AppRadius.small,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  child: _TournamentBracketCanvas(
                    bracket: bracket,
                    ownTeamName: ownTeamName,
                    geometry: geometry,
                    fixtureStatesBySlot: fixtureStatesBySlot,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _tournamentRoundLabel(AppLocalizations l10n, int teamCapacity) {
  return switch (teamCapacity) {
    2 => l10n.matchTournamentStageFinal,
    4 => l10n.matchTournamentStageSemifinal,
    8 => l10n.matchTournamentStageQuarterfinal,
    16 => l10n.matchTournamentStageRound16,
    _ => l10n.matchTournamentRoundOf(teamCapacity),
  };
}

class _TournamentFixtureProgressRow extends StatelessWidget {
  final CompetitionFixtureState fixture;

  const _TournamentFixtureProgressRow({required this.fixture});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 18,
          color: _competitionPositiveColor(context),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            l10n.matchTournamentRecordedProgress(
              matchTournamentStageLabel(l10n, fixture.fixture.stage),
              l10n.matchTournamentPairText(
                fixture.homeTeam,
                fixture.awayTeam,
              ),
              '${fixture.homeScore} : ${fixture.awayScore}',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
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
  final Widget? action;

  const _PreviewPanel({
    required this.icon,
    required this.title,
    required this.child,
    this.accent,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = accent ?? scheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: AppSurfaces.subtleColor(scheme, theme.brightness),
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
              if (action != null) action!,
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

class _CompetitionFixtureEditorScreen extends StatefulWidget {
  final MatchCompetitionService service;
  final MatchCompetitionRecord competition;
  final CompetitionFixtureState fixtureState;
  final List<String> managedTeamAliases;
  final bool readOnly;
  final CompetitionFixtureRecordHandler? onOpenFixtureRecord;

  const _CompetitionFixtureEditorScreen({
    required this.service,
    required this.competition,
    required this.fixtureState,
    required this.managedTeamAliases,
    required this.readOnly,
    this.onOpenFixtureRecord,
  });

  @override
  State<_CompetitionFixtureEditorScreen> createState() =>
      _CompetitionFixtureEditorScreenState();
}

class _CompetitionFixtureEditorScreenState
    extends State<_CompetitionFixtureEditorScreen> {
  late DateTime? _scheduledAt;
  late String _venue;
  late String _status;
  late bool _recordResult;
  late int _homeScore;
  late int _awayScore;
  late int _homePenaltyScore;
  late int _awayPenaltyScore;
  bool _saving = false;

  CompetitionFixtureState get _fixtureState => widget.fixtureState;

  bool get _isTournament =>
      widget.competition.kind == MatchCompetitionRecord.kindTournament;

  bool get _hasParticipants => _fixtureState.hasParticipants;

  bool get _needsPenalty =>
      _isTournament && _recordResult && _homeScore == _awayScore;

  List<String> get _venueOptions {
    final options = <String>[
      '',
      widget.competition.venue.trim(),
      _fixtureState.fixture.venue.trim(),
      _venue.trim(),
    ];
    final unique = <String>[];
    for (final option in options) {
      if (!unique.contains(option)) unique.add(option);
    }
    return unique;
  }

  @override
  void initState() {
    super.initState();
    _scheduledAt = _fixtureState.fixture.scheduledAt;
    _venue = _fixtureState.fixture.venue.trim();
    _status = switch (_fixtureState.fixture.status) {
      CompetitionFixture.statusPostponed => CompetitionFixture.statusPostponed,
      CompetitionFixture.statusCancelled => CompetitionFixture.statusCancelled,
      _ => CompetitionFixture.statusScheduled,
    };
    _recordResult = _fixtureState.isRecorded;
    _homeScore = _fixtureState.homeScore ?? 0;
    _awayScore = _fixtureState.awayScore ?? 0;
    _homePenaltyScore = _fixtureState.homePenaltyScore ?? 0;
    _awayPenaltyScore = _fixtureState.awayPenaltyScore ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accent = _competitionAccent(context, widget.competition.kind);
    final scheduledAt = _scheduledAt;
    final dateLabel = scheduledAt == null
        ? l10n.matchCompetitionFixtureUnscheduled
        : MaterialLocalizations.of(context).formatShortDate(scheduledAt);
    final timeLabel = scheduledAt == null
        ? l10n.matchCompetitionFixtureTimeAction
        : MaterialLocalizations.of(
            context,
          ).formatTimeOfDay(TimeOfDay.fromDateTime(scheduledAt));
    return Scaffold(
      body: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  0,
                ),
                child: Row(
                  children: [
                    BackButton(onPressed: _saving ? null : _close),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        l10n.matchCompetitionFixtureEditorTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    AppBarActionButton.label(
                      key: const ValueKey('competition-fixture-save-action'),
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: l10n.matchCompetitionFixtureSave,
                      tooltip: l10n.matchCompetitionFixtureSave,
                      onPressed: widget.readOnly || _saving ? null : _save,
                      margin: EdgeInsets.zero,
                      maxLabelWidth: 78,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FixtureMatchupHeader(
                            fixture: _fixtureState,
                            accent: accent,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _EditorSectionPanel(
                            title: l10n.matchCompetitionFixtureScheduleSection,
                            children: [
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  OutlinedButton.icon(
                                    key: const ValueKey(
                                      'competition-fixture-date-picker',
                                    ),
                                    onPressed:
                                        widget.readOnly ? null : _pickDate,
                                    icon: const Icon(
                                      Icons.calendar_today_outlined,
                                    ),
                                    label: Text(dateLabel),
                                  ),
                                  OutlinedButton.icon(
                                    key: const ValueKey(
                                      'competition-fixture-time-picker',
                                    ),
                                    onPressed:
                                        widget.readOnly ? null : _pickTime,
                                    icon: const Icon(Icons.schedule_outlined),
                                    label: Text(timeLabel),
                                  ),
                                  if (scheduledAt != null)
                                    AppBarActionButton.icon(
                                      key: const ValueKey(
                                        'competition-fixture-clear-schedule',
                                      ),
                                      tooltip: l10n
                                          .matchCompetitionFixtureClearSchedule,
                                      onPressed: widget.readOnly
                                          ? null
                                          : () => setState(
                                                () => _scheduledAt = null,
                                              ),
                                      icon: Icons.event_busy_outlined,
                                      margin: EdgeInsets.zero,
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              DropdownButtonFormField<String>(
                                key: const ValueKey(
                                  'competition-fixture-venue-selector',
                                ),
                                initialValue: _venue,
                                decoration: InputDecoration(
                                  labelText: l10n.matchCompetitionVenueLabel,
                                  border: const OutlineInputBorder(),
                                ),
                                items: [
                                  for (final venue in _venueOptions)
                                    DropdownMenuItem<String>(
                                      value: venue,
                                      child: Text(
                                        venue.isEmpty
                                            ? l10n
                                                .matchCompetitionFixtureVenueUnset
                                            : venue ==
                                                    widget.competition.venue
                                                        .trim()
                                                ? l10n
                                                    .matchCompetitionFixtureVenueDefault
                                                : venue,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                                onChanged: widget.readOnly
                                    ? null
                                    : (value) {
                                        setState(() => _venue = value ?? '');
                                      },
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SegmentedButton<String>(
                                key: const ValueKey(
                                  'competition-fixture-status-selector',
                                ),
                                showSelectedIcon: false,
                                segments: [
                                  ButtonSegment<String>(
                                    value: CompetitionFixture.statusScheduled,
                                    icon: const Icon(Icons.event_available),
                                    label: Text(
                                      l10n.matchCompetitionFixtureStatusScheduled,
                                    ),
                                  ),
                                  ButtonSegment<String>(
                                    value: CompetitionFixture.statusPostponed,
                                    icon: const Icon(Icons.update_outlined),
                                    label: Text(
                                      l10n.matchCompetitionFixtureStatusPostponed,
                                    ),
                                  ),
                                  ButtonSegment<String>(
                                    value: CompetitionFixture.statusCancelled,
                                    icon: const Icon(Icons.event_busy_outlined),
                                    label: Text(
                                      l10n.matchCompetitionFixtureStatusCancelled,
                                    ),
                                  ),
                                ],
                                selected: {_status},
                                onSelectionChanged: widget.readOnly
                                    ? null
                                    : (selection) {
                                        setState(() {
                                          _status = selection.first;
                                          if (_status ==
                                              CompetitionFixture
                                                  .statusCancelled) {
                                            _recordResult = false;
                                          }
                                        });
                                      },
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _EditorSectionPanel(
                            title: l10n.matchCompetitionFixtureResultSection,
                            children: [
                              if (!_hasParticipants)
                                Text(
                                  l10n.matchCompetitionFixtureResultUnavailable,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                )
                              else ...[
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  value: _recordResult,
                                  title: Text(
                                    l10n.matchCompetitionFixtureResultEnabled,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  onChanged: widget.readOnly ||
                                          _status ==
                                              CompetitionFixture.statusCancelled
                                      ? null
                                      : (value) {
                                          setState(() => _recordResult = value);
                                        },
                                ),
                                if (_recordResult) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  _FixtureScoreboardEditor(
                                    homeTeam: _fixtureState.homeTeam,
                                    awayTeam: _fixtureState.awayTeam,
                                    homeScore: _homeScore,
                                    awayScore: _awayScore,
                                    onHomeChanged: widget.readOnly
                                        ? null
                                        : (value) {
                                            setState(() => _homeScore = value);
                                          },
                                    onAwayChanged: widget.readOnly
                                        ? null
                                        : (value) {
                                            setState(() => _awayScore = value);
                                          },
                                  ),
                                  if (_needsPenalty) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      l10n.matchCompetitionFixturePenaltyTitle,
                                      style:
                                          theme.textTheme.labelLarge?.copyWith(
                                        color: accent,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    _FixtureScoreboardEditor(
                                      homeTeam: _fixtureState.homeTeam,
                                      awayTeam: _fixtureState.awayTeam,
                                      homeScore: _homePenaltyScore,
                                      awayScore: _awayPenaltyScore,
                                      onHomeChanged: widget.readOnly
                                          ? null
                                          : (value) {
                                              setState(
                                                () => _homePenaltyScore = value,
                                              );
                                            },
                                      onAwayChanged: widget.readOnly
                                          ? null
                                          : (value) {
                                              setState(
                                                () => _awayPenaltyScore = value,
                                              );
                                            },
                                    ),
                                  ],
                                ],
                              ],
                            ],
                          ),
                          if (_canOpenTeamRecord) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: OutlinedButton.icon(
                                key: const ValueKey(
                                  'competition-fixture-team-record-action',
                                ),
                                onPressed: widget.readOnly || _saving
                                    ? null
                                    : _openTeamRecord,
                                icon: const Icon(Icons.groups_2_outlined),
                                label: Text(
                                  l10n.matchCompetitionFixtureOpenTeamRecord,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canOpenTeamRecord {
    final handler = widget.onOpenFixtureRecord;
    return handler != null &&
        _fixtureState.isReady &&
        widget.managedTeamAliases.any(_fixtureState.involvesTeam);
  }

  Future<void> _pickDate() async {
    final current = _scheduledAt ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 5),
      lastDate: DateTime(current.year + 10),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        current.hour == 0 && current.minute == 0 ? 10 : current.hour,
        current.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final current = _scheduledAt ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        current.year,
        current.month,
        current.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<MatchCompetitionRecord?> _persist({bool closeOnSuccess = true}) async {
    final l10n = AppLocalizations.of(context)!;
    if (_recordResult &&
        _needsPenalty &&
        _homePenaltyScore == _awayPenaltyScore) {
      AppFeedback.showMessage(
        context,
        text: l10n.matchCompetitionFixturePenaltyRequired,
      );
      return null;
    }
    setState(() => _saving = true);
    try {
      final fixture = _fixtureState.fixture.copyWith(
        scheduledAt: _scheduledAt,
        clearScheduledAt: _scheduledAt == null,
        venue: _venue,
        status: _recordResult ? CompetitionFixture.statusCompleted : _status,
        homeScore: _recordResult ? _homeScore : null,
        awayScore: _recordResult ? _awayScore : null,
        homePenaltyScore: _needsPenalty ? _homePenaltyScore : null,
        awayPenaltyScore: _needsPenalty ? _awayPenaltyScore : null,
        clearResult: !_recordResult,
        clearPenaltyResult: !_needsPenalty,
      );
      final updated = await widget.service.updateFixture(
        competition: widget.competition,
        fixture: fixture,
      );
      if (updated == null || !mounted) return updated;
      AppFeedback.showSuccess(
        context,
        text: l10n.matchCompetitionFixtureSavedFeedback,
      );
      if (closeOnSuccess) {
        Navigator.of(context).pop(updated);
      }
      return updated;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    await _persist();
  }

  Future<void> _openTeamRecord() async {
    final saved = await _persist(closeOnSuccess: false);
    if (saved == null || !mounted) return;
    final fixture = saved.fixtures.firstWhere(
      (item) => item.id == _fixtureState.fixture.id,
      orElse: () => _fixtureState.fixture,
    );
    await widget.onOpenFixtureRecord?.call(
      saved,
      fixture,
      _fixtureState.resultEntry,
    );
    if (!mounted) return;
    final refreshed = widget.service.findCompetitionById(saved.id) ?? saved;
    Navigator.of(context).pop(refreshed);
  }

  void _close() => Navigator.of(context).maybePop();
}

class _FixtureMatchupHeader extends StatelessWidget {
  final CompetitionFixtureState fixture;
  final Color accent;

  const _FixtureMatchupHeader({required this.fixture, required this.accent});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          fixture.competition.kind == MatchCompetitionRecord.kindLeague
              ? l10n.matchCompetitionFixtureRound(
                  fixture.fixture.roundNumber,
                )
              : matchTournamentStageLabel(l10n, fixture.fixture.stage),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            color: accent,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                fixture.homeTeam.isEmpty
                    ? l10n.matchCompetitionFixtureTbd
                    : fixture.homeTeam,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                fixture.isRecorded
                    ? '${fixture.homeScore} : ${fixture.awayScore}'
                    : l10n.matchCompetitionFixtureVersus,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: Text(
                fixture.awayTeam.isEmpty
                    ? l10n.matchCompetitionFixtureTbd
                    : fixture.awayTeam,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FixtureScoreboardEditor extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final ValueChanged<int>? onHomeChanged;
  final ValueChanged<int>? onAwayChanged;

  const _FixtureScoreboardEditor({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    this.onHomeChanged,
    this.onAwayChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _FixtureScoreStepper(
            label: homeTeam,
            value: homeScore,
            decreaseTooltip: l10n.matchCompetitionFixtureDecreaseScore,
            increaseTooltip: l10n.matchCompetitionFixtureIncreaseScore,
            onChanged: onHomeChanged,
            decreaseKey: const ValueKey('competition-fixture-home-decrease'),
            increaseKey: const ValueKey('competition-fixture-home-increase'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text(
            l10n.matchCompetitionFixtureVersus,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: _FixtureScoreStepper(
            label: awayTeam,
            value: awayScore,
            decreaseTooltip: l10n.matchCompetitionFixtureDecreaseScore,
            increaseTooltip: l10n.matchCompetitionFixtureIncreaseScore,
            onChanged: onAwayChanged,
            decreaseKey: const ValueKey('competition-fixture-away-decrease'),
            increaseKey: const ValueKey('competition-fixture-away-increase'),
          ),
        ),
      ],
    );
  }
}

class _FixtureScoreStepper extends StatelessWidget {
  final String label;
  final int value;
  final String decreaseTooltip;
  final String increaseTooltip;
  final ValueChanged<int>? onChanged;
  final Key decreaseKey;
  final Key increaseKey;

  const _FixtureScoreStepper({
    required this.label,
    required this.value,
    required this.decreaseTooltip,
    required this.increaseTooltip,
    required this.onChanged,
    required this.decreaseKey,
    required this.increaseKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppBarActionButton.icon(
              key: decreaseKey,
              tooltip: decreaseTooltip,
              onPressed: onChanged == null || value <= 0
                  ? null
                  : () => onChanged!(value - 1),
              icon: Icons.remove_circle_outline,
              margin: EdgeInsets.zero,
            ),
            SizedBox(
              width: 34,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            AppBarActionButton.icon(
              key: increaseKey,
              tooltip: increaseTooltip,
              onPressed: onChanged == null ? null : () => onChanged!(value + 1),
              icon: Icons.add_circle_outline,
              margin: EdgeInsets.zero,
            ),
          ],
        ),
      ],
    );
  }
}

class _CompetitionSchedulePlannerScreen extends StatefulWidget {
  final MatchCompetitionService service;
  final MatchCompetitionRecord competition;

  const _CompetitionSchedulePlannerScreen({
    required this.service,
    required this.competition,
  });

  @override
  State<_CompetitionSchedulePlannerScreen> createState() =>
      _CompetitionSchedulePlannerScreenState();
}

class _CompetitionSchedulePlannerScreenState
    extends State<_CompetitionSchedulePlannerScreen> {
  late DateTime _startAt;
  late int _intervalDays;
  late String _venue;
  bool _saving = false;

  List<String> get _venueOptions {
    final options = <String>['', widget.competition.venue.trim(), _venue];
    return options.fold(<String>[], (result, value) {
      if (!result.contains(value)) result.add(value);
      return result;
    });
  }

  @override
  void initState() {
    super.initState();
    final firstScheduled = widget.competition.fixtures
        .where((fixture) => fixture.scheduledAt != null)
        .map((fixture) => fixture.scheduledAt!)
        .fold<DateTime?>(null, (previous, next) {
      if (previous == null || next.isBefore(previous)) return next;
      return previous;
    });
    _startAt = firstScheduled ??
        widget.competition.fixtureStartDate ??
        DateTime.now().add(const Duration(days: 1));
    _intervalDays = widget.competition.fixtureIntervalDays;
    _venue = widget.competition.venue.trim();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final uniqueRounds = widget.competition.fixtures
        .map((fixture) => fixture.roundNumber)
        .toSet()
        .toList()
      ..sort();
    final firstRound = uniqueRounds.isEmpty ? 1 : uniqueRounds.first;
    return Scaffold(
      body: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  0,
                ),
                child: Row(
                  children: [
                    BackButton(onPressed: _saving ? null : _close),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        l10n.matchCompetitionFixtureSchedulePlanTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    AppBarActionButton.label(
                      key: const ValueKey('competition-schedule-plan-save'),
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: l10n.matchCompetitionFixtureScheduleApply,
                      tooltip: l10n.matchCompetitionFixtureScheduleApply,
                      onPressed: _saving ? null : _applySchedule,
                      margin: EdgeInsets.zero,
                      maxLabelWidth: 76,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _EditorSectionPanel(
                            title: l10n.matchCompetitionFixtureScheduleSection,
                            children: [
                              Text(
                                l10n.matchCompetitionFixtureScheduleStartLabel,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  OutlinedButton.icon(
                                    key: const ValueKey(
                                      'competition-schedule-plan-date-picker',
                                    ),
                                    onPressed: _pickDate,
                                    icon: const Icon(
                                      Icons.calendar_today_outlined,
                                    ),
                                    label: Text(
                                      MaterialLocalizations.of(
                                        context,
                                      ).formatShortDate(_startAt),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    key: const ValueKey(
                                      'competition-schedule-plan-time-picker',
                                    ),
                                    onPressed: _pickTime,
                                    icon: const Icon(Icons.schedule_outlined),
                                    label: Text(
                                      MaterialLocalizations.of(
                                        context,
                                      ).formatTimeOfDay(
                                        TimeOfDay.fromDateTime(_startAt),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              DropdownButtonFormField<int>(
                                key: const ValueKey(
                                  'competition-schedule-plan-interval-selector',
                                ),
                                initialValue: _intervalDays,
                                decoration: InputDecoration(
                                  labelText: l10n
                                      .matchCompetitionFixtureScheduleIntervalLabel,
                                  border: const OutlineInputBorder(),
                                ),
                                items: [1, 2, 3, 4, 7, 10, 14].map((days) {
                                  return DropdownMenuItem<int>(
                                    value: days,
                                    child: Text(
                                      l10n.matchCompetitionFixtureScheduleIntervalDays(
                                        days,
                                      ),
                                    ),
                                  );
                                }).toList(growable: false),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _intervalDays = value);
                                },
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              DropdownButtonFormField<String>(
                                key: const ValueKey(
                                  'competition-schedule-plan-venue-selector',
                                ),
                                initialValue: _venue,
                                decoration: InputDecoration(
                                  labelText: l10n.matchCompetitionVenueLabel,
                                  border: const OutlineInputBorder(),
                                ),
                                items: [
                                  for (final venue in _venueOptions)
                                    DropdownMenuItem<String>(
                                      value: venue,
                                      child: Text(
                                        venue.isEmpty
                                            ? l10n
                                                .matchCompetitionFixtureVenueUnset
                                            : venue ==
                                                    widget.competition.venue
                                                        .trim()
                                                ? l10n
                                                    .matchCompetitionFixtureVenueDefault
                                                : venue,
                                      ),
                                    ),
                                ],
                                onChanged: (value) {
                                  setState(() => _venue = value ?? '');
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _EditorSectionPanel(
                            title: l10n.matchCompetitionFixturesTitle,
                            children: [
                              if (uniqueRounds.isEmpty)
                                _EmptyPreview(
                                  text: l10n.matchCompetitionFixturesEmpty,
                                )
                              else
                                for (final round in uniqueRounds)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.xs,
                                    ),
                                    child: _SchedulePlanPreviewRow(
                                      label: widget.competition.kind ==
                                              MatchCompetitionRecord.kindLeague
                                          ? l10n.matchCompetitionFixtureRound(
                                              round,
                                            )
                                          : matchTournamentStageLabel(
                                              l10n,
                                              widget.competition.fixtures
                                                  .firstWhere(
                                                    (fixture) =>
                                                        fixture.roundNumber ==
                                                        round,
                                                  )
                                                  .stage,
                                            ),
                                      date: _startAt.add(
                                        Duration(
                                          days: _intervalDays *
                                              (round - firstRound),
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: DateTime(_startAt.year - 5),
      lastDate: DateTime(_startAt.year + 10),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _startAt.hour,
        _startAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startAt),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startAt = DateTime(
        _startAt.year,
        _startAt.month,
        _startAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _applySchedule() async {
    setState(() => _saving = true);
    try {
      final updated = await widget.service.scheduleFixtures(
        competition: widget.competition,
        startAt: _startAt,
        intervalDays: _intervalDays,
        venue: _venue,
      );
      if (updated == null || !mounted) return;
      AppFeedback.showSuccess(
        context,
        text: AppLocalizations.of(
          context,
        )!
            .matchCompetitionFixtureSavedFeedback,
      );
      Navigator.of(context).pop(updated);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _close() => Navigator.of(context).maybePop();
}

class _SchedulePlanPreviewRow extends StatelessWidget {
  final String label;
  final DateTime date;

  const _SchedulePlanPreviewRow({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          '${MaterialLocalizations.of(context).formatShortDate(date)} · '
          '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(date))}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CompetitionEditorScreen extends StatefulWidget {
  final MatchCompetitionService service;
  final MatchCompetitionRecord? record;
  final String initialKind;
  final String managedTeamName;
  final String fallbackTeamName;

  const _CompetitionEditorScreen({
    required this.service,
    required this.record,
    required this.initialKind,
    required this.managedTeamName,
    required this.fallbackTeamName,
  });

  @override
  State<_CompetitionEditorScreen> createState() =>
      _CompetitionEditorScreenState();
}

class _CompetitionEditorScreenState extends State<_CompetitionEditorScreen> {
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
  bool _allowPop = false;
  bool _hasPersistedChanges = false;
  bool _showValidationErrors = false;
  String _lastSavedSignature = '';

  String get _ownTeamName => widget.managedTeamName.trim().isEmpty
      ? widget.fallbackTeamName.trim()
      : widget.managedTeamName.trim();

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
    _teams = MatchCompetitionService.teamsWithManagedTeam(
      kind: _kind,
      teams: record?.teams ?? const [],
      managedTeamName: widget.managedTeamName,
      fallbackTeamName: widget.fallbackTeamName,
      replaceLeagueFirstTeam: record != null,
    );
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
    final theme = Theme.of(context);
    final title = _nameController.text.trim().isEmpty
        ? l10n.matchCompetitionManagerNewTitle
        : l10n.matchCompetitionManagerTitle(_nameController.text.trim());
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _allowPop) return;
        await _closeEditor();
      },
      child: Scaffold(
        body: ColoredBox(
          color: theme.scaffoldBackgroundColor,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    0,
                  ),
                  child: Row(
                    children: [
                      BackButton(onPressed: _closeEditor),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      AppBarActionButton.label(
                        key: const ValueKey('competition-editor-save'),
                        icon: _autoSaveInFlight
                            ? const SizedBox.square(
                                dimension: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: l10n.matchCompetitionSaveCompetition,
                        tooltip: l10n.matchCompetitionSaveCompetition,
                        onPressed: _autoSaveInFlight ? null : _saveCompetition,
                        margin: EdgeInsets.zero,
                        maxLabelWidth: 88,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
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
                                      icon: const Icon(
                                          Icons.leaderboard_outlined),
                                      label: Text(l10n.matchKindLeague),
                                    ),
                                    ButtonSegment<String>(
                                      value:
                                          MatchCompetitionRecord.kindTournament,
                                      icon: const Icon(
                                          Icons.account_tree_outlined),
                                      label: Text(l10n.matchKindTournament),
                                    ),
                                  ],
                                  selected: {_kind},
                                  showSelectedIcon: false,
                                  onSelectionChanged: (selection) {
                                    _changeCompetitionKind(selection.first);
                                  },
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextField(
                                  controller: _nameController,
                                  maxLength: 40,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText: l10n.requiredFieldLabel(
                                      l10n.matchCompetitionNameLabel,
                                    ),
                                    hintText: _kind ==
                                            MatchCompetitionRecord.kindLeague
                                        ? l10n.matchLeagueNameHint
                                        : l10n.matchTournamentNameHint,
                                    errorText: _showValidationErrors &&
                                            _nameController.text.trim().isEmpty
                                        ? l10n.matchCompetitionNameRequired
                                        : null,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                SegmentedButton<String>(
                                  segments: [
                                    ButtonSegment<String>(
                                      value:
                                          MatchCompetitionRecord.statusActive,
                                      icon:
                                          const Icon(Icons.play_circle_outline),
                                      label: Text(
                                          l10n.matchCompetitionStatusActive),
                                    ),
                                    ButtonSegment<String>(
                                      value:
                                          MatchCompetitionRecord.statusFinished,
                                      icon: const Icon(
                                          Icons.flag_circle_outlined),
                                      label: Text(
                                          l10n.matchCompetitionStatusFinished),
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
                            if (_kind == MatchCompetitionRecord.kindLeague)
                              _LeagueTeamsEditor(
                                teams: _teams,
                                ownTeamName: _ownTeamName,
                                teamController: _teamController,
                                onAddTeam: _addTeam,
                                onRemoveTeam: _removeTeam,
                                errorText: _competitionTeamsError(l10n),
                              )
                            else
                              _TournamentSeedsEditor(
                                teams: _teams,
                                ownTeamName: _ownTeamName,
                                teamController: _teamController,
                                onAddTeam: _addTeam,
                                onRemoveTeam: _removeTeam,
                                onReorder: _reorderTeam,
                                errorText: _competitionTeamsError(l10n),
                              ),
                            _EditorSectionPanel(
                              title: l10n.matchCompetitionEditorOperationsTitle,
                              children: [
                                _EditorFieldGrid(
                                  children: [
                                    _EditorTextField(
                                      fieldKey: const ValueKey(
                                        'competition-season-field',
                                      ),
                                      controller: _seasonController,
                                      label: l10n.matchCompetitionSeasonLabel,
                                      hint: l10n.matchCompetitionSeasonHint,
                                      maxLength: 24,
                                    ),
                                    _EditorTextField(
                                      fieldKey: const ValueKey(
                                        'competition-venue-field',
                                      ),
                                      controller: _venueController,
                                      label: l10n.matchCompetitionVenueLabel,
                                      hint: l10n.matchCompetitionVenueHint,
                                      maxLength: 40,
                                    ),
                                    _EditorTextField(
                                      fieldKey: const ValueKey(
                                        'competition-organizer-field',
                                      ),
                                      controller: _organizerController,
                                      label:
                                          l10n.matchCompetitionOrganizerLabel,
                                      hint: l10n.matchCompetitionOrganizerHint,
                                      maxLength: 40,
                                    ),
                                    _EditorTextField(
                                      fieldKey: const ValueKey(
                                        'competition-note-field',
                                      ),
                                      controller: _noteController,
                                      label: l10n.matchCompetitionNoteLabel,
                                      hint: l10n.matchCompetitionNoteHint,
                                      maxLength: 80,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
    if (team.trim().toLowerCase() == _ownTeamName.toLowerCase()) return;
    setState(() {
      _teams = _teams.where((item) => item != team).toList(growable: false);
    });
    _scheduleAutoSave();
  }

  void _changeCompetitionKind(String kind) {
    if (kind == _kind) return;
    setState(() {
      _kind = kind;
      _teams = MatchCompetitionService.teamsWithManagedTeam(
        kind: kind,
        teams: _teams,
        managedTeamName: widget.managedTeamName,
        fallbackTeamName: widget.fallbackTeamName,
      );
    });
    _scheduleAutoSave();
  }

  void _reorderTeam(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final team = _teams.removeAt(oldIndex);
      _teams.insert(newIndex, team);
    });
    _scheduleAutoSave();
  }

  Future<void> _closeEditor() async {
    if (_allowPop) return;
    _autoSaveTimer?.cancel();
    while (_autoSaveInFlight) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    final updated = _buildCompetitionRecord();
    if (updated != null &&
        _competitionRecordSignature(updated) != _lastSavedSignature) {
      await _persistCompetition(updated);
    }
    if (!mounted) return;
    _allowPop = true;
    Navigator.of(context).pop(_hasPersistedChanges);
  }

  Future<void> _saveCompetition() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _showValidationErrors = true);
    if (_nameController.text.trim().isEmpty) {
      AppFeedback.showMessage(
        context,
        text: l10n.matchCompetitionNameRequired,
      );
      return;
    }
    if (_teams.length < 2) {
      AppFeedback.showMessage(
        context,
        text: l10n.matchCompetitionMinimumTeamsRequired,
      );
      return;
    }
    final updated = _buildCompetitionRecord();
    if (updated == null) return;
    _autoSaveTimer?.cancel();
    await _persistCompetition(updated);
    if (!mounted) return;
    AppFeedback.showSuccess(
      context,
      text: l10n.matchCompetitionSavedFeedback,
    );
    _allowPop = true;
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
      if (mounted) {
        setState(() {});
        AppFeedback.showSuccess(
          context,
          text: AppLocalizations.of(context)!.matchCompetitionAutoSavedFeedback,
        );
      }
    } finally {
      _autoSaveInFlight = false;
      if (mounted) setState(() {});
      if (_autoSaveQueued && mounted) {
        _autoSaveQueued = false;
        _scheduleAutoSave();
      }
    }
  }

  MatchCompetitionRecord? _buildCompetitionRecord() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _teams.length < 2) return null;
    final existing = _persistedRecord ?? widget.record;
    final record = MatchCompetitionRecord.create(
      kind: _kind,
      name: name,
      teams: _teams,
      status: _status,
      season: _seasonController.text,
      venue: _venueController.text,
      organizer: _organizerController.text,
      note: _noteController.text,
      leagueLegs: existing?.leagueLegs ?? 1,
      fixtureStartDate: existing?.fixtureStartDate,
      fixtureIntervalDays: existing?.fixtureIntervalDays ?? 7,
    );
    if (existing == null) return record;
    return record.copyWith(
      id: existing.id,
      createdAt: existing.createdAt,
    );
  }

  String? _competitionTeamsError(AppLocalizations l10n) {
    if (!_showValidationErrors || _teams.length >= 2) return null;
    return l10n.matchCompetitionMinimumTeamsRequired;
  }

  Future<void> _persistCompetition(MatchCompetitionRecord updated) async {
    final existing = _persistedRecord ?? widget.record;
    final createdAt = existing?.createdAt ?? updated.createdAt;
    final normalized = updated.copyWith(
      id: existing?.id ?? updated.id,
      createdAt: createdAt,
    );
    await widget.service.upsertCompetition(normalized);
    _persistedRecord = widget.service.findCompetitionById(normalized.id) ??
        widget.service.findCompetition(
          kind: normalized.kind,
          name: normalized.name,
        ) ??
        normalized;
    _lastSavedSignature = _competitionRecordSignature(_persistedRecord!);
    _hasPersistedChanges = true;
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(height: AppSpacing.md),
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
  final Key? fieldKey;
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLength;

  const _EditorTextField({
    this.fieldKey,
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
        key: fieldKey,
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

class _LeagueTeamsEditor extends StatelessWidget {
  final List<String> teams;
  final String ownTeamName;
  final TextEditingController teamController;
  final VoidCallback onAddTeam;
  final ValueChanged<String> onRemoveTeam;
  final String? errorText;

  const _LeagueTeamsEditor({
    required this.teams,
    required this.ownTeamName,
    required this.teamController,
    required this.onAddTeam,
    required this.onRemoveTeam,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _competitionAccent(
      context,
      MatchCompetitionRecord.kindLeague,
    );
    return Container(
      key: const ValueKey('competition-league-team-editor'),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.cardDecoration(
        scheme,
        theme.brightness,
      ).copyWith(borderRadius: AppRadius.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard_outlined, color: accent, size: 21),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.matchCompetitionLeagueSetupTitle,
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.matchCompetitionLeagueSetupBody,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
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
                    avatar: team == ownTeamName
                        ? Icon(Icons.shield_outlined, size: 16, color: accent)
                        : null,
                    label: Text(team),
                    onDeleted:
                        team == ownTeamName ? null : () => onRemoveTeam(team),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          _CompetitionTeamInput(
            controller: teamController,
            onAddTeam: onAddTeam,
          ),
          if (errorText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _CompetitionRequiredFieldError(text: errorText!),
          ],
        ],
      ),
    );
  }
}

class _TournamentSeedsEditor extends StatelessWidget {
  final List<String> teams;
  final String ownTeamName;
  final TextEditingController teamController;
  final VoidCallback onAddTeam;
  final ValueChanged<String> onRemoveTeam;
  final ReorderCallback onReorder;
  final String? errorText;

  const _TournamentSeedsEditor({
    required this.teams,
    required this.ownTeamName,
    required this.teamController,
    required this.onAddTeam,
    required this.onRemoveTeam,
    required this.onReorder,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _competitionAccent(
      context,
      MatchCompetitionRecord.kindTournament,
    );
    final pairs = MatchCompetitionService.buildTournamentBracketPairs(teams);
    return Container(
      key: const ValueKey('competition-tournament-seed-editor'),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.cardDecoration(
        scheme,
        theme.brightness,
      ).copyWith(borderRadius: AppRadius.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree_outlined, color: accent, size: 21),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.matchCompetitionTournamentSetupTitle,
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.matchCompetitionTournamentSetupBody,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _CompetitionTeamInput(
            controller: teamController,
            onAddTeam: onAddTeam,
          ),
          if (errorText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _CompetitionRequiredFieldError(text: errorText!),
          ],
          const SizedBox(height: AppSpacing.md),
          if (teams.isEmpty)
            Text(
              l10n.matchCompetitionNoTeams,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: teams.length,
              onReorder: onReorder,
              proxyDecorator: (child, _, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  child: child,
                  builder: (context, child) {
                    final progress = Curves.easeOutCubic.transform(
                      animation.value,
                    );
                    return Transform.scale(
                      scale: 1 + (0.035 * progress),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color.alphaBlend(
                            accent.withValues(alpha: 0.22),
                            scheme.surface,
                          ),
                          borderRadius: AppRadius.small,
                          border: Border.all(color: accent, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.34),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          child: child,
                        ),
                      ),
                    );
                  },
                );
              },
              itemBuilder: (context, index) {
                final team = teams[index];
                final isOwnTeam = team == ownTeamName;
                return ReorderableDelayedDragStartListener(
                  key: ValueKey('competition-seed-$team'),
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.small,
                      border: index == teams.length - 1
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.72,
                                ),
                              ),
                            ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: AppRadius.small,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  team,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (isOwnTeam) ...[
                                const SizedBox(width: AppSpacing.xs),
                                _CompetitionOwnTeamBadge(accent: accent),
                              ],
                            ],
                          ),
                        ),
                        if (!isOwnTeam)
                          _CompetitionRowAction(
                            onPressed: () => onRemoveTeam(team),
                            icon: Icons.close,
                            tooltip: l10n.matchCompetitionRemoveTeamTooltip(
                              team,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          child: Icon(
                            Icons.drag_indicator,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (pairs.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: AppRadius.small,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.matchCompetitionTournamentPreviewTitle,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (final pair in pairs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                      child: Text(
                        l10n.matchCompetitionTournamentSeedPair(
                          pair.slotNumber,
                          pair.teamA,
                          pair.hasBye
                              ? l10n.matchTournamentByeLabel
                              : pair.teamB,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompetitionOwnTeamBadge extends StatelessWidget {
  final Color accent;

  const _CompetitionOwnTeamBadge({required this.accent});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: AppRadius.small,
      ),
      child: Text(
        l10n.matchCompetitionOwnTeamBadge,
        style: theme.textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CompetitionRowAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _CompetitionRowAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: InkResponse(
          onTap: onPressed,
          radius: 22,
          child: SizedBox.square(
            dimension: 40,
            child: Icon(icon, size: 19, color: scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _CompetitionRequiredFieldError extends StatelessWidget {
  final String text;

  const _CompetitionRequiredFieldError({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      key: const ValueKey('competition-team-validation-error'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompetitionTeamInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAddTeam;

  const _CompetitionTeamInput({
    required this.controller,
    required this.onAddTeam,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('competition-team-input'),
            controller: controller,
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
    );
  }
}

class _CompetitionOperationsMetrics {
  final int activeCompetitions;
  final int finishedCompetitions;

  const _CompetitionOperationsMetrics({
    required this.activeCompetitions,
    required this.finishedCompetitions,
  });

  factory _CompetitionOperationsMetrics.from({
    required List<MatchCompetitionRecord> records,
  }) {
    return _CompetitionOperationsMetrics(
      activeCompetitions: records.where((record) => !record.isFinished).length,
      finishedCompetitions: records.where((record) => record.isFinished).length,
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
    if (record.fixtures.isNotEmpty) {
      final fixtures = MatchCompetitionService.resolveFixtureStates(
        competition: record,
        entries: entries,
      );
      return _CompetitionProgress(
        recorded: fixtures.where((fixture) => fixture.isRecorded).length,
        target: fixtures
            .where(
              (fixture) =>
                  !fixture.fixture.isCancelled &&
                  (fixture.fixture.hasSourceSlots || !fixture.isBye),
            )
            .length,
      );
    }
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
