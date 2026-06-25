import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../application/backup_service.dart';
import '../../application/locale_service.dart';
import '../../application/match_competition_service.dart';
import '../../application/news_badge_service.dart';
import '../../application/player_profile_service.dart';
import '../../application/settings_service.dart';
import '../../application/sport_capabilities.dart';
import '../../application/sport_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../theme/app_theme.dart';
import '../utils/match_entry_format.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_page_route.dart';
import '../widgets/shared_tab_header.dart';
import 'news_screen.dart';
import 'notification_center_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'skill_quiz_screen.dart';

class MatchHubScreen extends StatefulWidget {
  final TrainingService trainingService;
  final LocaleService localeService;
  final OptionRepository optionRepository;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final VoidCallback onRecordMatch;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenMatchStats;

  const MatchHubScreen({
    super.key,
    required this.trainingService,
    required this.localeService,
    required this.optionRepository,
    required this.settingsService,
    this.driveBackupService,
    required this.onRecordMatch,
    required this.onOpenCalendar,
    required this.onOpenMatchStats,
  });

  @override
  State<MatchHubScreen> createState() => _MatchHubScreenState();
}

class _MatchHubScreenState extends State<MatchHubScreen> {
  bool _routePushInFlight = false;

  @override
  void initState() {
    super.initState();
    NewsBadgeService.refresh(widget.optionRepository);
  }

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
    final l10n = AppLocalizations.of(context)!;
    final sportId = SportService(widget.optionRepository).currentSportId();
    final reminderUnreadCount = TrainingPlanReminderService(
      widget.optionRepository,
      widget.settingsService,
    ).unreadReminderCountSync();
    final profile = PlayerProfileService(
      widget.optionRepository,
      sportId: sportId,
    ).load();

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
              final competitions = _collectCompetitionRecords(matchEntries);
              final metrics = _MatchHubMetrics.from(
                entries: matchEntries,
                competitions: competitions,
              );
              final competitionSummaries = _buildCompetitionSummaries(
                context,
                competitions: competitions,
                matchEntries: matchEntries,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: NewsBadgeService.listenable(
                        widget.optionRepository,
                      ),
                      builder: (context, newsCount, _) => SharedTabHeader(
                        padding: EdgeInsets.zero,
                        onLeadingTap: () => Navigator.of(context).maybePop(),
                        leadingIcon: Icons.arrow_back,
                        leadingTooltip:
                            MaterialLocalizations.of(context).backButtonTooltip,
                        onNewsTap: () => _openNews(context),
                        newsBadgeCount: newsCount,
                        onQuizTap: () => _openQuiz(context),
                        onMatchTap: () {},
                        matchSelected: true,
                        onNotificationTap: () => _openNotifications(context),
                        notificationBadgeCount: reminderUnreadCount,
                        profilePhotoSource: profile.photoUrl,
                        onProfileTap: () => _openProfile(context),
                        onSettingsTap: () => _openSettings(context),
                        title: l10n.matchHubTitle,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _MatchHubHero(
                      metrics: metrics,
                      onRecordMatch: () => _closeThen(widget.onRecordMatch),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _MatchHubQuickActions(
                      onRecordMatch: () => _closeThen(widget.onRecordMatch),
                      onOpenCalendar: () => _closeThen(widget.onOpenCalendar),
                      onOpenMatchStats: () =>
                          _closeThen(widget.onOpenMatchStats),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _MatchHubCompetitionSection(
                      summaries: competitionSummaries,
                      onRecordMatch: () => _closeThen(widget.onRecordMatch),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _MatchHubRecentSection(
                        entries: matchEntries.take(6).toList()),
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
    List<TrainingEntry> entries,
  ) {
    final records = <String, MatchCompetitionRecord>{
      for (final record
          in MatchCompetitionService(widget.optionRepository).allCompetitions())
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

  Future<void> _openNews(BuildContext context) async {
    await _pushPageSafely(
      AppPageRoute(
        builder: (_) => NewsScreen(
          trainingService: widget.trainingService,
          localeService: widget.localeService,
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
          isActive: true,
        ),
      ),
    );
    if (mounted) {
      await NewsBadgeService.refresh(widget.optionRepository);
    }
  }

  Future<void> _openQuiz(BuildContext context) async {
    await _pushPageSafely(
      AppPageRoute(
        builder: (_) =>
            SkillQuizScreen(optionRepository: widget.optionRepository),
      ),
    );
  }

  Future<void> _openNotifications(BuildContext context) async {
    await _pushPageSafely(
      AppPageRoute(
        builder: (_) => NotificationCenterScreen(
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
        ),
      ),
    );
  }

  Future<void> _openProfile(BuildContext context) async {
    await _pushPageSafely(
      AppPageRoute(
        builder: (_) =>
            ProfileScreen(optionRepository: widget.optionRepository),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => SettingsScreen(
          localeService: widget.localeService,
          settingsService: widget.settingsService,
          optionRepository: widget.optionRepository,
          driveBackupService: widget.driveBackupService,
        ),
      ),
    );
  }

  void _closeThen(VoidCallback action) {
    final l10n = AppLocalizations.of(context)!;
    AppFeedback.showSuccess(context, text: l10n.matchHubOpeningFeedback);
    Navigator.of(context).maybePop();
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }
}

class _MatchHubHero extends StatelessWidget {
  final _MatchHubMetrics metrics;
  final VoidCallback onRecordMatch;

  const _MatchHubHero({
    required this.metrics,
    required this.onRecordMatch,
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
                  Icons.sports_soccer,
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
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onRecordMatch,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(l10n.matchHubRecordButton),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF166153),
              minimumSize: const Size.fromHeight(AppSizes.primaryButtonHeight),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchHubQuickActions extends StatelessWidget {
  final VoidCallback onRecordMatch;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenMatchStats;

  const _MatchHubQuickActions({
    required this.onRecordMatch,
    required this.onOpenCalendar,
    required this.onOpenMatchStats,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = [
      _QuickActionData(
        icon: Icons.edit_note_outlined,
        title: l10n.matchHubRecordButton,
        subtitle: l10n.matchHubRecordHelper,
        onTap: onRecordMatch,
      ),
      _QuickActionData(
        icon: Icons.calendar_month_outlined,
        title: l10n.matchHubCalendarButton,
        subtitle: l10n.matchHubCalendarHelper,
        onTap: onOpenCalendar,
      ),
      _QuickActionData(
        icon: Icons.analytics_outlined,
        title: l10n.matchHubStatsButton,
        subtitle: l10n.matchHubStatsHelper,
        onTap: onOpenMatchStats,
      ),
      _QuickActionData(
        icon: Icons.account_tree_outlined,
        title: l10n.matchCompetitionManageButton,
        subtitle: l10n.matchHubCompetitionHelper,
        onTap: onRecordMatch,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 560 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: constraints.maxWidth >= 560 ? 1.45 : 1.28,
          ),
          itemBuilder: (context, index) =>
              _QuickActionCard(data: actions[index]),
        );
      },
    );
  }
}

class _MatchHubCompetitionSection extends StatelessWidget {
  final List<_CompetitionSummary> summaries;
  final VoidCallback onRecordMatch;

  const _MatchHubCompetitionSection({
    required this.summaries,
    required this.onRecordMatch,
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
          trailing: TextButton.icon(
            onPressed: onRecordMatch,
            icon: const Icon(Icons.add_outlined, size: 18),
            label: Text(l10n.matchCompetitionManageButton),
          ),
        ),
        if (visibleSummaries.isEmpty)
          _EmptyPanel(
            icon: Icons.emoji_events_outlined,
            title: l10n.matchHubNoCompetitionsTitle,
            body: l10n.matchHubNoCompetitionsSubtitle,
            actionLabel: l10n.matchHubRecordButton,
            onAction: onRecordMatch,
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

class _MatchHubRecentSection extends StatelessWidget {
  final List<TrainingEntry> entries;

  const _MatchHubRecentSection({required this.entries});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: l10n.matchHubRecentMatchesTitle),
        if (entries.isEmpty)
          _EmptyPanel(
            icon: Icons.sports_score_outlined,
            title: l10n.matchHubEmptyTitle,
            body: l10n.matchHubEmptySubtitle,
          )
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _RecentMatchCard(entry: entry),
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

class _RecentMatchCard extends StatelessWidget {
  final TrainingEntry entry;

  const _RecentMatchCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final locale = Localizations.localeOf(context).toString();
    final outcome = _matchOutcome(entry);
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
    final details = matchCompetitionDetailParts(entry, l10n, teamLimit: 2);
    return Container(
      decoration: AppSurfaces.cardDecoration(scheme, brightness),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _outcomeColor(outcome, scheme).withValues(alpha: 0.12),
              borderRadius: AppRadius.small,
            ),
            child: Center(
              child: Text(
                _outcomeShortLabel(outcome, l10n),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _outcomeColor(outcome, scheme),
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
                  details.isEmpty
                      ? DateFormat.yMMMd(locale).format(entry.date)
                      : details.join(' · '),
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
                  color: _outcomeColor(outcome, scheme),
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

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData data;

  const _QuickActionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: AppRadius.surface,
        child: Ink(
          decoration: AppSurfaces.cardDecoration(scheme, brightness),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(data.icon, color: scheme.primary, size: 24),
              const Spacer(),
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                data.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
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

class _QuickActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
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

Color _outcomeColor(int? outcome, ColorScheme scheme) {
  return switch (outcome) {
    1 => const Color(0xFF1F8A70),
    0 => const Color(0xFFB7791F),
    -1 => scheme.error,
    _ => scheme.onSurfaceVariant,
  };
}
