import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../application/backup_service.dart';
import '../../application/family_access_service.dart';
import '../../application/locale_service.dart';
import '../../application/match_competition_service.dart';
import '../../application/settings_service.dart';
import '../../application/sport_capabilities.dart';
import '../../application/sport_service.dart';
import '../../application/team_management_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../theme/app_theme.dart';
import '../utils/match_entry_format.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/app_page_route.dart';
import 'competition_management_screen.dart';
import 'match_record_screen.dart';
import 'match_records_screen.dart';
import 'team_management_screen.dart';

class MatchHubScreen extends StatefulWidget {
  final TrainingService trainingService;
  final LocaleService localeService;
  final OptionRepository optionRepository;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenMatchStats;
  final bool openRecordOnStart;
  final DateTime? initialRecordDate;

  const MatchHubScreen({
    super.key,
    required this.trainingService,
    required this.localeService,
    required this.optionRepository,
    required this.settingsService,
    this.driveBackupService,
    required this.onOpenCalendar,
    required this.onOpenMatchStats,
    this.openRecordOnStart = false,
    this.initialRecordDate,
  });

  @override
  State<MatchHubScreen> createState() => _MatchHubScreenState();
}

class _MatchHubScreenState extends State<MatchHubScreen> {
  bool _routePushInFlight = false;

  @override
  void initState() {
    super.initState();
    if (widget.openRecordOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_openMatchRecord(initialDate: widget.initialRecordDate));
      });
    }
  }

  bool get _isReadOnlySupportMode => FamilyAccessService(
        widget.optionRepository,
      ).loadState().isReadOnlySupportMode;

  Future<void> _pushPageSafely(Route<void> route) async {
    if (!mounted || _routePushInFlight) return;
    _routePushInFlight = true;
    try {
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      await Navigator.of(context).push(route);
    } finally {
      _routePushInFlight = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final sportId = SportService(widget.optionRepository).currentSportId();
    final supportsTeamManagement =
        SportCapabilities.forSport(sportId).supportsTeamManagement;

    return Scaffold(
      body: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: StreamBuilder<List<TrainingEntry>>(
            stream: widget.trainingService.watchEntries(),
            builder: (context, snapshot) {
              final entries = filterEntriesForSport(
                snapshot.data ?? const <TrainingEntry>[],
                sportId,
              );
              final matchEntries = entries
                  .where((entry) => entry.isMatch)
                  .toList(growable: false)
                ..sort((a, b) => b.date.compareTo(a.date));
              final competitions = _collectCompetitionRecords(
                matchEntries,
                sportId: sportId,
              );
              final metrics = _MatchHubMetrics.from(
                entries: matchEntries,
                competitions: competitions,
              );
              final competitionSummaries = _buildCompetitionSummaries(
                context,
                competitions: competitions,
                matchEntries: matchEntries,
              );
              final managedTeams = supportsTeamManagement
                  ? TeamManagementService(
                      widget.optionRepository,
                      sportId: sportId,
                    ).allTeams()
                  : const <ManagedTeam>[];
              final primaryTeam = managedTeams.firstOrNull;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MatchHubHeader(
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _MatchHubCommandCenter(
                      supportsTeamManagement: supportsTeamManagement,
                      primaryTeam: primaryTeam,
                      metrics: metrics,
                      onRecordMatch: () => _openMatchRecord(),
                      onManageTeams: () => _openTeamManagement(),
                      onManageCompetitions: () => _openCompetitionManagement(),
                      onOpenMatchRecords: () => _openMatchRecords(),
                      onOpenMatchStats: () =>
                          _closeThen(widget.onOpenMatchStats),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _MatchHubHero(
                      metrics: metrics,
                      supportsTeamManagement: supportsTeamManagement,
                      primaryTeam: primaryTeam,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _MatchHubCompetitionSection(
                      summaries: competitionSummaries,
                      onManageCompetitions: () => _openCompetitionManagement(),
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

  List<MatchCompetitionRecord> _collectCompetitionRecords(
    List<TrainingEntry> entries, {
    required String sportId,
  }) {
    final records = <String, MatchCompetitionRecord>{
      for (final record in MatchCompetitionService(
        widget.optionRepository,
        sportId: sportId,
      ).allCompetitions())
        record.id: record,
    };

    for (final entry in entries) {
      if (!entry.isLeagueMatch && !entry.isTournamentMatch) continue;
      final name = entry.matchCompetitionName.trim();
      if (name.isEmpty) continue;
      final kind = entry.isTournamentMatch
          ? MatchCompetitionRecord.kindTournament
          : MatchCompetitionRecord.kindLeague;
      final id = MatchCompetitionService.competitionId(
        kind: kind,
        name: name,
      );
      records.putIfAbsent(
        id,
        () => MatchCompetitionRecord.create(
          kind: kind,
          name: name,
          teams: [
            ...entry.leagueTeamNames,
            entry.opponentTeam,
          ],
          now: entry.date,
        ),
      );
    }

    return records.values.toList(growable: false)
      ..sort((a, b) {
        final statusCompare = a.status.compareTo(b.status);
        if (statusCompare != 0) return statusCompare;
        return b.updatedAt.compareTo(a.updatedAt);
      });
  }

  List<_CompetitionSummary> _buildCompetitionSummaries(
    BuildContext context, {
    required List<MatchCompetitionRecord> competitions,
    required List<TrainingEntry> matchEntries,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final summaries = <_CompetitionSummary>[];
    for (final record in competitions) {
      final entries = MatchCompetitionService.competitionEntries(
        kind: record.kind,
        competitionName: record.name,
        entries: matchEntries,
      );
      if (record.kind == MatchCompetitionRecord.kindLeague) {
        final standings = MatchCompetitionService.buildLeagueStandings(
          competitionName: record.name,
          registeredTeams: record.teams,
          entries: matchEntries,
          ownTeamName: l10n.matchCompetitionMyTeamFallback,
        );
        final teamCount = math.max(record.teams.length, standings.length);
        final expectedMatches =
            teamCount > 1 ? teamCount * (teamCount - 1) ~/ 2 : 0;
        final leader = standings.isEmpty
            ? l10n.matchCompetitionNoLeader
            : standings.first.team;
        summaries.add(
          _CompetitionSummary(
            record: record,
            recordedMatches: entries.length,
            targetMatches: expectedMatches,
            leadingValue: leader,
            secondaryValue: l10n.matchCompetitionTeamCount(teamCount),
          ),
        );
      } else {
        final pairs =
            MatchCompetitionService.buildTournamentBracketPairs(record.teams);
        final targetMatches = pairs.where((pair) => !pair.hasBye).length;
        final latestEntry = entries.isEmpty ? null : entries.first;
        final leadingValue = latestEntry == null
            ? l10n.matchCompetitionNoMatches
            : matchTournamentOutcomeLabel(
                l10n,
                latestEntry.tournamentOutcome,
              );
        summaries.add(
          _CompetitionSummary(
            record: record,
            recordedMatches: entries.length,
            targetMatches: targetMatches,
            leadingValue: leadingValue,
            secondaryValue: l10n.matchCompetitionTeamCount(record.teams.length),
          ),
        );
      }
    }
    return summaries;
  }

  void _closeThen(VoidCallback action) {
    final l10n = AppLocalizations.of(context)!;
    AppFeedback.showSuccess(context, text: l10n.matchHubOpeningFeedback);
    Navigator.of(context).maybePop();
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  Future<void> _openMatchRecord({DateTime? initialDate}) async {
    if (_isReadOnlySupportMode) {
      AppFeedback.showMessage(
        context,
        text: AppLocalizations.of(context)!.parentReadOnlyCoreDataMessage,
      );
      return;
    }
    await _pushPageSafely(
      AppPageRoute(
        builder: (_) => MatchRecordScreen(
          trainingService: widget.trainingService,
          localeService: widget.localeService,
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
          initialDate: initialDate,
        ),
      ),
    );
  }

  Future<void> _openTeamManagement() async {
    final readOnly = _isReadOnlySupportMode;
    await _pushPageSafely(
      AppPageRoute(
        builder: (_) => TeamManagementScreen(
          optionRepository: widget.optionRepository,
          sportId: SportService(widget.optionRepository).currentSportId(),
          readOnly: readOnly,
        ),
      ),
    );
  }

  Future<void> _openMatchRecords() async {
    await _pushPageSafely(
      AppPageRoute(
        builder: (_) => MatchRecordsScreen(
          trainingService: widget.trainingService,
          optionRepository: widget.optionRepository,
        ),
      ),
    );
  }

  Future<void> _openCompetitionManagement() async {
    final readOnly = _isReadOnlySupportMode;
    await _pushPageSafely(
      AppPageRoute(
        builder: (_) => CompetitionManagementScreen(
          trainingService: widget.trainingService,
          optionRepository: widget.optionRepository,
          sportId: SportService(widget.optionRepository).currentSportId(),
          readOnly: readOnly,
        ),
      ),
    );
  }
}

class _MatchHubHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _MatchHubHeader({required this.onBack});

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
                l10n.matchHubTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                l10n.matchHubTeamManagementHeaderSubtitle,
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

class _MatchHubHero extends StatelessWidget {
  final _MatchHubMetrics metrics;
  final bool supportsTeamManagement;
  final ManagedTeam? primaryTeam;

  const _MatchHubHero({
    required this.metrics,
    required this.supportsTeamManagement,
    required this.primaryTeam,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    return Container(
      decoration: AppSurfaces.heroDecoration(
        scheme,
        brightness,
        accent: const Color(0xFF1F8A70),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: AppRadius.small,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: const Icon(
                  Icons.sports_soccer_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.matchHubOverviewTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      l10n.matchHubSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _HeroMetricPill(
                label: l10n.statsMatchTotalMatchesLabel,
                value: l10n.statsMatchTotalMatchesValue(metrics.totalMatches),
              ),
              _HeroMetricPill(
                label: l10n.statsMatchRecordLabel,
                value: l10n.statsMatchRecordValue(
                  metrics.wins,
                  metrics.draws,
                  metrics.losses,
                ),
              ),
              _HeroMetricPill(
                label: l10n.statsMatchWinRateLabel,
                value: l10n.statsMatchWinRateValue(metrics.winRate),
              ),
              _HeroMetricPill(
                label: l10n.matchHubRecentFormLabel,
                value: metrics.formText(l10n),
              ),
              _HeroMetricPill(
                label: l10n.statsMatchTypeLabel,
                value: l10n.matchHubKindBreakdown(
                  metrics.friendlyMatches,
                  metrics.leagueMatches,
                  metrics.tournamentMatches,
                ),
              ),
              _HeroMetricPill(
                label: l10n.matchHubCompetitionStateLabel,
                value: l10n.matchHubCompetitionStateValue(
                  metrics.activeCompetitions,
                  metrics.finishedCompetitions,
                ),
              ),
              if (supportsTeamManagement)
                _HeroMetricPill(
                  label: l10n.matchHubTeamStateLabel,
                  value: primaryTeam?.name ?? l10n.matchHubNoPrimaryTeamValue,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatchHubCommandCenter extends StatelessWidget {
  final bool supportsTeamManagement;
  final ManagedTeam? primaryTeam;
  final _MatchHubMetrics metrics;
  final VoidCallback onRecordMatch;
  final VoidCallback onManageTeams;
  final VoidCallback onManageCompetitions;
  final VoidCallback onOpenMatchRecords;
  final VoidCallback onOpenMatchStats;

  const _MatchHubCommandCenter({
    required this.supportsTeamManagement,
    required this.primaryTeam,
    required this.metrics,
    required this.onRecordMatch,
    required this.onManageTeams,
    required this.onManageCompetitions,
    required this.onOpenMatchRecords,
    required this.onOpenMatchStats,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelCount = supportsTeamManagement ? 2 : 1;
        final gap = AppSpacing.sm * (panelCount - 1);
        final panelWidth = panelCount == 1 || constraints.maxWidth < 720
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / panelCount;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(title: l10n.matchHubCommandCenterTitle),
            Text(
              l10n.matchHubCommandCenterHelper,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (supportsTeamManagement)
                  SizedBox(
                    width: panelWidth,
                    child: _TeamCommandPanel(
                      team: primaryTeam,
                      onManageTeams: onManageTeams,
                    ),
                  ),
                SizedBox(
                  width: panelWidth,
                  child: _MatchCommandPanel(
                    metrics: metrics,
                    onRecordMatch: onRecordMatch,
                    onManageCompetitions: onManageCompetitions,
                    onOpenMatchRecords: onOpenMatchRecords,
                    onOpenMatchStats: onOpenMatchStats,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TeamCommandPanel extends StatelessWidget {
  final ManagedTeam? team;
  final VoidCallback onManageTeams;

  const _TeamCommandPanel({
    required this.team,
    required this.onManageTeams,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final totalSpots = team == null
        ? 0
        : TeamManagementService.formationSpots(team!.formation).length;
    return _CommandPanel(
      icon: Icons.manage_accounts_outlined,
      title: l10n.teamManagementOpenButton,
      subtitle: l10n.matchHubTeamCommandHelper,
      children: [
        if (team == null)
          Text(
            l10n.matchHubNoTeamsSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          )
        else ...[
          Text(
            team!.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _CompactInfo(
                  label: l10n.teamManagementPlayersTitle,
                  value: l10n.teamManagementPlayerCount(team!.players.length),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _CompactInfo(
                  label: l10n.teamManagementOperationsLineupLabel,
                  value: l10n.teamManagementLineupFilled(
                    team!.filledLineupCount,
                    totalSpots,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.icon(
            onPressed: onManageTeams,
            icon: const Icon(Icons.person_add_alt_outlined),
            label: Text(l10n.matchHubTeamCommandPrimary),
          ),
        ),
      ],
    );
  }
}

class _MatchCommandPanel extends StatelessWidget {
  final _MatchHubMetrics metrics;
  final VoidCallback onRecordMatch;
  final VoidCallback onManageCompetitions;
  final VoidCallback onOpenMatchRecords;
  final VoidCallback onOpenMatchStats;

  const _MatchCommandPanel({
    required this.metrics,
    required this.onRecordMatch,
    required this.onManageCompetitions,
    required this.onOpenMatchRecords,
    required this.onOpenMatchStats,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _CommandPanel(
      icon: Icons.sports_soccer_outlined,
      title: l10n.matchHubMatchCommandTitle,
      subtitle: l10n.matchHubMatchCommandHelper,
      children: [
        Row(
          children: [
            Expanded(
              child: _CompactInfo(
                label: l10n.statsMatchTotalMatchesLabel,
                value: l10n.statsMatchTotalMatchesValue(metrics.totalMatches),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CompactInfo(
                label: l10n.matchHubCompetitionStateLabel,
                value: l10n.matchHubCompetitionStateValue(
                  metrics.activeCompetitions,
                  metrics.finishedCompetitions,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 420 ? 2 : 1;
            final gap = AppSpacing.sm * (columns - 1);
            final buttonWidth = (constraints.maxWidth - gap) / columns;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                SizedBox(
                  width: buttonWidth,
                  child: FilledButton.icon(
                    onPressed: onRecordMatch,
                    icon: const Icon(Icons.edit_note_outlined),
                    label: Text(l10n.matchHubRecordButton),
                  ),
                ),
                SizedBox(
                  width: buttonWidth,
                  child: OutlinedButton.icon(
                    onPressed: onManageCompetitions,
                    icon: const Icon(Icons.emoji_events_outlined),
                    label: Text(l10n.matchCompetitionOpenButton),
                  ),
                ),
                SizedBox(
                  width: buttonWidth,
                  child: OutlinedButton.icon(
                    onPressed: onOpenMatchRecords,
                    icon: const Icon(Icons.fact_check_outlined),
                    label: Text(l10n.matchRecordsOpenButton),
                  ),
                ),
                SizedBox(
                  width: buttonWidth,
                  child: OutlinedButton.icon(
                    onPressed: onOpenMatchStats,
                    icon: const Icon(Icons.analytics_outlined),
                    label: Text(l10n.matchHubStatsButton),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CommandPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _CommandPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: AppSurfaces.cardDecoration(scheme, theme.brightness),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.small,
                ),
                child: Icon(icon, color: scheme.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _MatchHubCompetitionSection extends StatelessWidget {
  final List<_CompetitionSummary> summaries;
  final VoidCallback onManageCompetitions;

  const _MatchHubCompetitionSection({
    required this.summaries,
    required this.onManageCompetitions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final visibleSummaries = summaries.take(8).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: l10n.matchHubCompetitionsTitle,
          trailing: AppBarActionButton.label(
            icon: const Icon(Icons.add_outlined),
            label: l10n.matchCompetitionOpenButton,
            onPressed: onManageCompetitions,
            margin: EdgeInsets.zero,
            maxLabelWidth: 126,
          ),
        ),
        if (visibleSummaries.isEmpty)
          _EmptyPanel(
            icon: Icons.emoji_events_outlined,
            title: l10n.matchHubNoCompetitionsTitle,
            body: l10n.matchHubNoCompetitionsSubtitle,
            actionLabel: l10n.matchCompetitionOpenButton,
            onAction: onManageCompetitions,
          )
        else
          ...visibleSummaries.map(
            (summary) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _CompetitionCard(summary: summary),
            ),
          ),
        if (summaries.length > visibleSummaries.length)
          Text(
            l10n.statsCompetitionMoreCount(
              summaries.length - visibleSummaries.length,
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _CompetitionCard extends StatelessWidget {
  final _CompetitionSummary summary;

  const _CompetitionCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final record = summary.record;
    final isLeague = record.kind == MatchCompetitionRecord.kindLeague;
    final accent = isLeague ? const Color(0xFF2B6FF3) : const Color(0xFFC2410C);
    final progress = summary.progress;
    return Container(
      decoration: AppSurfaces.cardDecoration(scheme, brightness),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppRadius.small,
                ),
                child: Icon(
                  isLeague ? Icons.table_chart_outlined : Icons.account_tree,
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
                      isLeague
                          ? l10n.matchKindLeague
                          : l10n.matchKindTournament,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(
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
                child: _CompactInfo(
                  label: isLeague
                      ? l10n.matchCompetitionSummaryLeader
                      : l10n.matchCompetitionSummaryProgress,
                  value: summary.leadingValue,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _CompactInfo(
                  label: l10n.matchCompetitionSummaryTeams,
                  value: summary.secondaryValue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.full,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              color: accent,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            summary.progressLabel(l10n),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetricPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 136),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: AppRadius.small,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyPanel({
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
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_outlined),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactInfo extends StatelessWidget {
  final String label;
  final String value;

  const _CompactInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusChip({
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active ? const Color(0xFF1F8A70) : theme.colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: active ? color : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CompetitionSummary {
  final MatchCompetitionRecord record;
  final int recordedMatches;
  final int targetMatches;
  final String leadingValue;
  final String secondaryValue;

  const _CompetitionSummary({
    required this.record,
    required this.recordedMatches,
    required this.targetMatches,
    required this.leadingValue,
    required this.secondaryValue,
  });

  double get progress {
    if (targetMatches <= 0) return recordedMatches > 0 ? 1 : 0;
    return (recordedMatches / targetMatches).clamp(0.0, 1.0).toDouble();
  }

  String progressLabel(AppLocalizations l10n) {
    if (targetMatches <= 0) {
      return l10n.matchHubRecordedOnlyProgress(recordedMatches);
    }
    return l10n.statsCompetitionProgressValue(recordedMatches, targetMatches);
  }
}

class _MatchHubMetrics {
  final int totalMatches;
  final int wins;
  final int draws;
  final int losses;
  final int friendlyMatches;
  final int leagueMatches;
  final int tournamentMatches;
  final int activeCompetitions;
  final int finishedCompetitions;
  final List<int> recentOutcomes;

  const _MatchHubMetrics({
    required this.totalMatches,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.friendlyMatches,
    required this.leagueMatches,
    required this.tournamentMatches,
    required this.activeCompetitions,
    required this.finishedCompetitions,
    required this.recentOutcomes,
  });

  factory _MatchHubMetrics.from({
    required List<TrainingEntry> entries,
    required List<MatchCompetitionRecord> competitions,
  }) {
    final outcomes =
        entries.map(_matchOutcome).whereType<int>().toList(growable: false);
    final wins = outcomes.where((value) => value > 0).length;
    final draws = outcomes.where((value) => value == 0).length;
    final losses = outcomes.where((value) => value < 0).length;
    return _MatchHubMetrics(
      totalMatches: entries.length,
      wins: wins,
      draws: draws,
      losses: losses,
      friendlyMatches: entries
          .where((entry) => !entry.isLeagueMatch && !entry.isTournamentMatch)
          .length,
      leagueMatches: entries.where((entry) => entry.isLeagueMatch).length,
      tournamentMatches:
          entries.where((entry) => entry.isTournamentMatch).length,
      activeCompetitions:
          competitions.where((record) => !record.isFinished).length,
      finishedCompetitions:
          competitions.where((record) => record.isFinished).length,
      recentOutcomes: outcomes.take(5).toList(growable: false),
    );
  }

  int get winRate {
    final decided = wins + draws + losses;
    if (decided == 0) return 0;
    return ((wins / decided) * 100).round();
  }

  String formText(AppLocalizations l10n) {
    if (recentOutcomes.isEmpty) return l10n.statsMatchFormUnsetValue;
    return recentOutcomes
        .map((outcome) => _outcomeShortLabel(outcome, l10n))
        .join(' ');
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
