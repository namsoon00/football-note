import 'dart:async';

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../application/challenge_service.dart';
import '../../application/meal_log_service.dart';
import '../../application/player_level_service.dart';
import '../../application/player_profile_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';
import '../widgets/app_page_route.dart';
import '../widgets/rinzy_mascot.dart';

class ChallengeScreen extends StatefulWidget {
  final TrainingService trainingService;
  final MealLogService mealLogService;
  final OptionRepository optionRepository;

  const ChallengeScreen({
    super.key,
    required this.trainingService,
    required this.mealLogService,
    required this.optionRepository,
  });

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  late final ChallengeService _challengeService;
  bool _awardInFlight = false;
  bool _failureInFlight = false;
  String? _lastAwardSignature;
  String? _lastFailureSignature;

  @override
  void initState() {
    super.initState();
    _challengeService = ChallengeService(widget.optionRepository);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.challengeTitle)),
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<List<TrainingEntry>>(
            stream: widget.trainingService.watchEntries(),
            builder: (context, trainingSnapshot) {
              final trainingEntries =
                  (trainingSnapshot.data ?? const <TrainingEntry>[])
                      .where((entry) => !entry.isMatch)
                      .toList(growable: false);
              return StreamBuilder<List<MealEntry>>(
                stream: widget.mealLogService.watchEntries(),
                builder: (context, mealSnapshot) {
                  final mealEntries = widget.mealLogService.mergedEntries(
                    directEntries: mealSnapshot.data ?? const <MealEntry>[],
                    legacyEntries: trainingEntries,
                  );
                  final progress = _challengeService.activeProgress(
                    trainingEntries: trainingEntries,
                    mealEntries: mealEntries,
                  );
                  if (progress != null) {
                    final missedRound = progress.missedExpiredRound();
                    if (missedRound != null) {
                      _scheduleFailureSync(progress, missedRound);
                    } else {
                      _scheduleAwardSync(progress);
                    }
                  }
                  final runs = _challengeService.loadRuns();
                  final historyRuns =
                      runs.where((run) => run.isEnded).toList(growable: false);
                  final profileService = PlayerProfileService(
                    widget.optionRepository,
                  );
                  final profile = profileService.load();
                  final recommendedLevel = ChallengeService.recommendedLevel(
                    ageYears: profileService.ageInYears(
                      profile,
                      DateTime.now(),
                    ),
                    soccerYears: profileService.soccerYears(
                      profile,
                      DateTime.now(),
                    ),
                  );
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      if (progress == null)
                        _ChallengeStartSection(
                          templates: _challengeService.templates(),
                          historyRuns: historyRuns,
                          recommendedLevel: recommendedLevel,
                          templateTitle: (template) =>
                              _templateTitle(l10n, template),
                          templateDescription: (template) =>
                              _templateDescription(l10n, template),
                          onStart: _startChallenge,
                        )
                      else
                        _ActiveChallengeSection(
                          progress: progress,
                          templateTitle:
                              _templateTitle(l10n, progress.template),
                          onAbandon: _confirmAbandon,
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _scheduleAwardSync(ChallengeProgress progress) {
    final completedRounds = progress.rounds
        .where((round) => round.completed)
        .map((round) => round.round.number)
        .join(',');
    if (completedRounds.isEmpty) return;
    final signature = '${progress.run.id}:$completedRounds';
    if (_awardInFlight || _lastAwardSignature == signature) return;
    _lastAwardSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_syncAwards(progress, signature));
    });
  }

  void _scheduleFailureSync(
    ChallengeProgress progress,
    ChallengeRoundProgress missedRound,
  ) {
    final signature = '${progress.run.id}:fail:${missedRound.round.number}';
    if (_failureInFlight || _lastFailureSignature == signature) return;
    _lastFailureSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_syncFailure(progress, missedRound, signature));
    });
  }

  Future<void> _syncFailure(
    ChallengeProgress progress,
    ChallengeRoundProgress missedRound,
    String signature,
  ) async {
    if (_failureInFlight) return;
    _failureInFlight = true;
    final l10n = AppLocalizations.of(context)!;
    try {
      await _challengeService.failRun(
        progress.run.id,
        roundNumber: missedRound.round.number,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.challengeFailedSnack(missedRound.round.number)),
        ),
      );
      setState(() {});
    } finally {
      _failureInFlight = false;
      _lastFailureSignature = signature;
    }
  }

  Future<void> _syncAwards(
    ChallengeProgress progress,
    String signature,
  ) async {
    if (_awardInFlight) return;
    _awardInFlight = true;
    try {
      final awards = await _challengeService.awardCompletedRounds(
        progress: progress,
        playerLevelService: PlayerLevelService(widget.optionRepository),
      );
      final gainedXp = awards.fold<int>(
        0,
        (sum, award) => sum + award.gainedXp,
      );
      if (!mounted) return;
      if (gainedXp > 0) {
        final awardedRoundCount = awards
            .where((award) => award.gainedXp > 0)
            .length
            .clamp(1, progress.rounds.length)
            .toInt();
        await Navigator.of(context).push(
          AppPageRoute<void>(
            builder: (_) => _ChallengeCelebrationScreen(
              gainedXp: gainedXp,
              awardedRoundCount: awardedRoundCount,
              challengeCompleted: progress.allRoundsCompleted,
            ),
          ),
        );
      }
      if (!mounted) return;
      setState(() {});
    } finally {
      _awardInFlight = false;
      _lastAwardSignature = signature;
    }
  }

  Future<void> _startChallenge(
    ChallengeTemplate template,
    ChallengeTrainingLevel trainingLevel,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await _challengeService.startChallenge(
      template,
      trainingLevel: trainingLevel,
    );
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(l10n.challengeStartSnack(_templateTitle(l10n, template)))),
    );
  }

  Future<void> _confirmAbandon() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.challengeAbandonTitle),
        content: Text(l10n.challengeAbandonBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.challengeAbandonConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _challengeService.abandonActiveRun();
    if (!mounted) return;
    setState(() {});
  }
}

class _ChallengeStartSection extends StatefulWidget {
  final List<ChallengeTemplate> templates;
  final List<ChallengeRun> historyRuns;
  final ChallengeTrainingLevel recommendedLevel;
  final String Function(ChallengeTemplate template) templateTitle;
  final String Function(ChallengeTemplate template) templateDescription;
  final void Function(
    ChallengeTemplate template,
    ChallengeTrainingLevel trainingLevel,
  ) onStart;

  const _ChallengeStartSection({
    required this.templates,
    required this.historyRuns,
    required this.recommendedLevel,
    required this.templateTitle,
    required this.templateDescription,
    required this.onStart,
  });

  @override
  State<_ChallengeStartSection> createState() => _ChallengeStartSectionState();
}

class _ChallengeStartSectionState extends State<_ChallengeStartSection> {
  ChallengeTemplate? _selectedTemplate;
  ChallengeTrainingLevel? _selectedLevel;

  @override
  void didUpdateWidget(_ChallengeStartSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recommendedLevel != widget.recommendedLevel) {
      _selectedLevel = null;
    }
    final selectedTemplate = _selectedTemplate;
    if (selectedTemplate != null &&
        !widget.templates.contains(selectedTemplate)) {
      _selectedTemplate = null;
      _selectedLevel = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChallengeIntroCard(
          title: l10n.challengeStartHeroTitle,
          body: l10n.challengeStartHeroBody,
          progress: 0,
          footer: widget.historyRuns.isEmpty
              ? null
              : _SmallStatusPill(label: l10n.challengeLatestComplete),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.challengeDurationSelectTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        for (final template in widget.templates) ...[
          _ChallengeTemplateCard(
            template: template,
            title: widget.templateTitle(template),
            description: widget.templateDescription(template),
            selected: template.id == _selectedTemplate?.id,
            level: _selectedLevel,
            onSelect: () => setState(() {
              _selectedTemplate = template;
              _selectedLevel = null;
            }),
          ),
          const SizedBox(height: 10),
        ],
        if (_selectedTemplate != null) ...[
          const SizedBox(height: 10),
          Text(
            l10n.challengeTrainingLevelTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (final config in challengeTrainingLevelConfigs) ...[
            _ChallengeLevelCard(
              level: config.level,
              selected: config.level == _selectedLevel,
              recommended: config.level == widget.recommendedLevel,
              onSelect: () => setState(() => _selectedLevel = config.level),
            ),
            const SizedBox(height: 10),
          ],
        ],
        if (_selectedTemplate != null && _selectedLevel != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.challengeStartReadyTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _RewardPitchCard(
            roundXp: trainingLevelConfig(_selectedLevel!).rewardXpPerRound,
            completionBonusXp: challengeCompletionBonusXpFor(
              _selectedTemplate!,
              _selectedLevel!,
            ),
            totalXp: challengeTotalPotentialXpFor(
              _selectedTemplate!,
              _selectedLevel!,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () =>
                widget.onStart(_selectedTemplate!, _selectedLevel!),
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.challengeStartAction),
          ),
        ],
        const SizedBox(height: 22),
        _ChallengeHistorySection(
          runs: widget.historyRuns,
        ),
      ],
    );
  }
}

class _ChallengeTemplateCard extends StatelessWidget {
  final ChallengeTemplate template;
  final String title;
  final String description;
  final bool selected;
  final ChallengeTrainingLevel? level;
  final VoidCallback onSelect;

  const _ChallengeTemplateCard({
    required this.template,
    required this.title,
    required this.description,
    required this.selected,
    required this.level,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('challenge-template-${template.id}'),
        onTap: onSelect,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.flag_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(description, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SmallStatusPill(
                    label: l10n.challengeDaysLabel(template.dayCount),
                  ),
                  if (level != null) ...[
                    _SmallStatusPill(
                      label: l10n.challengeRoundXpLabel(
                        trainingLevelConfig(level!).rewardXpPerRound,
                      ),
                    ),
                    _SmallStatusPill(
                      label: l10n.challengeCompletionBonusLabel(
                        challengeCompletionBonusXpFor(template, level!),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeLevelCard extends StatelessWidget {
  final ChallengeTrainingLevel level;
  final bool selected;
  final bool recommended;
  final VoidCallback onSelect;

  const _ChallengeLevelCard({
    required this.level,
    required this.selected,
    required this.recommended,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final config = trainingLevelConfig(level);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('challenge-level-${level.name}'),
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _trainingLevelTitle(l10n, level),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (recommended)
                          _SmallStatusPill(
                            label: l10n.challengeRecommendedLevelBadge,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _trainingLevelDescription(l10n, level),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SmallStatusPill(
                          label: l10n.challengeRoundXpLabel(
                            config.rewardXpPerRound,
                          ),
                        ),
                        _SmallStatusPill(
                          label: l10n.challengeLevelTrainingTargetLabel(
                            config.targetTrainingMinutes,
                          ),
                        ),
                        _SmallStatusPill(
                          label: l10n.challengeLevelJumpRopeTargetLabel(
                            config.targetJumpRopeMinutes,
                          ),
                        ),
                        _SmallStatusPill(
                          label: l10n.challengeLevelLiftingTargetLabel(
                            config.targetLiftingMinutes,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardPitchCard extends StatelessWidget {
  final int roundXp;
  final int completionBonusXp;
  final int totalXp;

  const _RewardPitchCard({
    required this.roundXp,
    required this.completionBonusXp,
    required this.totalXp,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.challengeRewardPitchTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallStatusPill(label: l10n.challengeRoundXpLabel(roundXp)),
              _SmallStatusPill(
                label: l10n.challengeCompletionBonusLabel(completionBonusXp),
              ),
              _SmallStatusPill(label: l10n.challengeTotalXpLabel(totalXp)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChallengeHistorySection extends StatelessWidget {
  final List<ChallengeRun> runs;

  const _ChallengeHistorySection({
    required this.runs,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shownRuns = runs.take(8).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.challengeHistoryTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        if (shownRuns.isEmpty)
          Text(
            l10n.challengeHistoryEmpty,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (final run in shownRuns) ...[
            _ChallengeHistoryTile(
              run: run,
              title: _templateTitleForRun(l10n, run),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _ChallengeHistoryTile extends StatelessWidget {
  final ChallengeRun run;
  final String title;

  const _ChallengeHistoryTile({
    required this.run,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final started = DateFormat.yMMMd(localeName).format(run.startDay);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(
            run.isCompleted
                ? Icons.emoji_events_outlined
                : run.isFailed
                    ? Icons.flag_circle_outlined
                    : Icons.stop_circle_outlined,
            color: run.isCompleted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  run.isFailed && run.failedRoundNumber != null
                      ? l10n.challengeHistoryFailedRound(
                          started,
                          run.failedRoundNumber!,
                        )
                      : l10n.challengeHistoryStarted(started),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _SmallStatusPill(label: _runResultLabel(l10n, run)),
        ],
      ),
    );
  }
}

class _ChallengeIntroCard extends StatelessWidget {
  final String title;
  final String body;
  final double progress;
  final Widget? footer;

  const _ChallengeIntroCard({
    required this.title,
    required this.body,
    required this.progress,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 330;
          final mascot = RinzyMascot(
            size: compact ? 116 : 98,
            progress: progress,
          );
          final text = Column(
            crossAxisAlignment:
                compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Text(
                title,
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: theme.textTheme.bodyMedium,
              ),
              if (footer != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: compact
                      ? Alignment.center
                      : AlignmentDirectional.centerStart,
                  child: footer,
                ),
              ],
            ],
          );
          if (compact) {
            return Column(
              children: [
                mascot,
                const SizedBox(height: 12),
                text,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              mascot,
              const SizedBox(width: 14),
              Expanded(child: text),
            ],
          );
        },
      ),
    );
  }
}

class _ActiveChallengeIntroCard extends StatelessWidget {
  final ChallengeProgress progress;
  final String templateTitle;

  const _ActiveChallengeIntroCard({
    required this.progress,
    required this.templateTitle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final percent = (progress.completionRate * 100).round();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.18),
            theme.colorScheme.tertiaryContainer.withValues(alpha: 0.38),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.20),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 330;
          final mascot = RinzyMascot(
            size: compact ? 122 : 104,
            progress: progress.completionRate,
          );
          final summary = Column(
            crossAxisAlignment:
                compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Text(
                templateTitle,
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.challengeRoundCount(
                  progress.completedRoundCount,
                  progress.totalRoundCount,
                ),
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 9,
                  value: progress.completionRate,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.challengeProgressPercent(percent),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SmallStatusPill(
                    label: _trainingLevelTitle(
                      l10n,
                      progress.run.trainingLevel,
                    ),
                  ),
                  _SmallStatusPill(
                    label: l10n.challengeCompletionBonusLabel(
                      challengeCompletionBonusXpFor(
                        progress.template,
                        progress.run.trainingLevel,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
          if (compact) {
            return Column(
              children: [
                mascot,
                const SizedBox(height: 12),
                summary,
              ],
            );
          }
          return Row(
            children: [
              mascot,
              const SizedBox(width: 14),
              Expanded(child: summary),
            ],
          );
        },
      ),
    );
  }
}

class _ActiveChallengeSection extends StatelessWidget {
  final ChallengeProgress progress;
  final String templateTitle;
  final VoidCallback onAbandon;

  const _ActiveChallengeSection({
    required this.progress,
    required this.templateTitle,
    required this.onAbandon,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final activeRound = progress.activeRound;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActiveChallengeIntroCard(
          progress: progress,
          templateTitle: templateTitle,
        ),
        const SizedBox(height: 12),
        if (activeRound != null)
          _RoundFocusCard(round: activeRound)
        else
          _CompletedCard(title: templateTitle),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.challengeRoundsTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onAbandon,
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(l10n.challengeAbandonAction),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final round in progress.rounds) ...[
          _RoundProgressTile(round: round),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _RoundFocusCard extends StatelessWidget {
  final ChallengeRoundProgress round;

  const _RoundFocusCard({required this.round});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final title = round.isToday
        ? l10n.challengeTodayRoundTitle(round.round.number)
        : l10n.challengeUpcomingRoundTitle(round.round.number);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _SmallStatusPill(
                label: round.completed
                    ? l10n.challengeCompletedBadge
                    : l10n.challengePendingBadge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MissionProgressRow(
            icon: Icons.timer_outlined,
            label: l10n.challengeTrainingLabel,
            value: _minutesGoalValue(
              l10n,
              round.trainingMinutes,
              round.round.targetTrainingMinutes,
            ),
            completed: round.trainingCompleted,
          ),
          const SizedBox(height: 10),
          _MissionProgressRow(
            icon: Icons.directions_run,
            label: l10n.challengeJumpRopeLabel,
            value: _minutesGoalValue(
              l10n,
              round.jumpRopeMinutes,
              round.round.targetJumpRopeMinutes,
            ),
            completed: round.jumpRopeCompleted,
          ),
          const SizedBox(height: 10),
          _MissionProgressRow(
            icon: Icons.sports_soccer,
            label: l10n.challengeLiftingLabel,
            value: _minutesGoalValue(
              l10n,
              round.liftingMinutes,
              round.round.targetLiftingMinutes,
            ),
            completed: round.liftingCompleted,
          ),
          const SizedBox(height: 10),
          _MissionProgressRow(
            icon: Icons.rice_bowl_outlined,
            label: l10n.challengeMealLabel,
            value: l10n.challengeMealGoalValue(
              _formatBowls(round.riceBowls),
              _formatBowls(round.round.targetRiceBowls),
            ),
            completed: round.mealCompleted,
          ),
        ],
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  final String title;

  const _CompletedCard({required this.title});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        l10n.challengeCompletedSummary(title),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RoundProgressTile extends StatelessWidget {
  final ChallengeRoundProgress round;

  const _RoundProgressTile({required this.round});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final statusColor = round.completed
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: round.isToday
              ? theme.colorScheme.primary.withValues(alpha: 0.34)
              : theme.colorScheme.outline,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            round.completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: statusColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.challengeRoundTitle(round.round.number),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _roundSubtitle(context, round),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SmallStatusPill(
                      label:
                          '${l10n.challengeTrainingLabel} ${_minutesGoalValue(
                        l10n,
                        round.trainingMinutes,
                        round.round.targetTrainingMinutes,
                      )}',
                    ),
                    _SmallStatusPill(
                      label:
                          '${l10n.challengeJumpRopeLabel} ${_minutesGoalValue(
                        l10n,
                        round.jumpRopeMinutes,
                        round.round.targetJumpRopeMinutes,
                      )}',
                    ),
                    _SmallStatusPill(
                      label: '${l10n.challengeLiftingLabel} ${_minutesGoalValue(
                        l10n,
                        round.liftingMinutes,
                        round.round.targetLiftingMinutes,
                      )}',
                    ),
                    _SmallStatusPill(
                      label:
                          '${l10n.challengeMealLabel} ${l10n.challengeMealGoalValue(
                        _formatBowls(round.riceBowls),
                        _formatBowls(round.round.targetRiceBowls),
                      )}',
                    ),
                    _SmallStatusPill(
                      label: l10n.challengeRewardXp(round.round.rewardXp),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionProgressRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool completed;

  const _MissionProgressRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = completed
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SmallStatusPill extends StatelessWidget {
  final String label;

  const _SmallStatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _ChallengeCelebrationScreen extends StatelessWidget {
  final int gainedXp;
  final int awardedRoundCount;
  final bool challengeCompleted;

  const _ChallengeCelebrationScreen({
    required this.gainedXp,
    required this.awardedRoundCount,
    required this.challengeCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final title = challengeCompleted
        ? l10n.challengeCelebrationCompleteTitle
        : l10n.challengeCelebrationTitle;
    final body = challengeCompleted
        ? l10n.challengeCelebrationCompleteBody(gainedXp)
        : l10n.challengeCelebrationBody(awardedRoundCount, gainedXp);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
                const Spacer(),
                RinzyMascot(
                  size: MediaQuery.sizeOf(context)
                      .width
                      .clamp(180, 260)
                      .toDouble(),
                  progress: 1,
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                _SmallStatusPill(label: l10n.challengeRewardXp(gainedXp)),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.celebration_outlined),
                    label: Text(l10n.challengeCelebrationAction),
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

String _templateTitle(AppLocalizations l10n, ChallengeTemplate template) {
  return switch (template.id) {
    'starter_3' => l10n.challengeTemplateStarterTitle,
    'weekly_7' => l10n.challengeTemplateWeeklyTitle,
    'focus_14' => l10n.challengeTemplateFocusTitle,
    _ => l10n.challengeTitle,
  };
}

String _templateDescription(AppLocalizations l10n, ChallengeTemplate template) {
  return switch (template.id) {
    'starter_3' => l10n.challengeTemplateStarterDescription,
    'weekly_7' => l10n.challengeTemplateWeeklyDescription,
    'focus_14' => l10n.challengeTemplateFocusDescription,
    _ => l10n.challengeStartHeroBody,
  };
}

String _trainingLevelTitle(
  AppLocalizations l10n,
  ChallengeTrainingLevel level,
) {
  return switch (level) {
    ChallengeTrainingLevel.rookie => l10n.challengeTrainingLevelRookieTitle,
    ChallengeTrainingLevel.growth => l10n.challengeTrainingLevelGrowthTitle,
    ChallengeTrainingLevel.ace => l10n.challengeTrainingLevelAceTitle,
  };
}

String _trainingLevelDescription(
  AppLocalizations l10n,
  ChallengeTrainingLevel level,
) {
  return switch (level) {
    ChallengeTrainingLevel.rookie =>
      l10n.challengeTrainingLevelRookieDescription,
    ChallengeTrainingLevel.growth =>
      l10n.challengeTrainingLevelGrowthDescription,
    ChallengeTrainingLevel.ace => l10n.challengeTrainingLevelAceDescription,
  };
}

String _minutesGoalValue(
  AppLocalizations l10n,
  int current,
  int target,
) {
  return l10n.challengeTrainingGoalValue(current, target);
}

String _runResultLabel(AppLocalizations l10n, ChallengeRun run) {
  if (run.isCompleted) return l10n.challengeHistoryResultCompleted;
  if (run.isFailed) return l10n.challengeHistoryResultFailed;
  if (run.isAbandoned) return l10n.challengeHistoryResultAbandoned;
  return l10n.challengeHistoryResultInProgress;
}

String _templateTitleForRun(
  AppLocalizations l10n,
  ChallengeRun run,
) {
  final title = switch (run.templateId) {
    'starter_3' => l10n.challengeTemplateStarterTitle,
    'weekly_7' => l10n.challengeTemplateWeeklyTitle,
    'focus_14' => l10n.challengeTemplateFocusTitle,
    _ => l10n.challengeTitle,
  };
  return '$title · ${_trainingLevelTitle(l10n, run.trainingLevel)}';
}

String _roundSubtitle(BuildContext context, ChallengeRoundProgress round) {
  final l10n = AppLocalizations.of(context)!;
  if (round.isToday) return l10n.challengeRoundDateToday;
  final localeName = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(localeName).format(round.date);
}

String _formatBowls(double value) {
  final fixed = value.toStringAsFixed(1);
  return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
}
