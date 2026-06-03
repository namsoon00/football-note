import 'dart:async';

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../application/challenge_service.dart';
import '../../application/meal_log_service.dart';
import '../../application/player_level_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';
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
  String? _lastAwardSignature;

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
                    _scheduleAwardSync(progress);
                  }
                  final latestCompleted = progress == null
                      ? _challengeService.latestCompletedRun()
                      : null;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      if (progress == null)
                        _ChallengeStartSection(
                          templates: _challengeService.templates(),
                          latestCompletedRun: latestCompleted,
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

  Future<void> _syncAwards(
    ChallengeProgress progress,
    String signature,
  ) async {
    if (_awardInFlight) return;
    _awardInFlight = true;
    final l10n = AppLocalizations.of(context)!;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.challengeAwardSnack(gainedXp))),
        );
      }
      if (progress.allRoundsCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.challengeCompletedSnack)),
        );
      }
      setState(() {});
    } finally {
      _awardInFlight = false;
      _lastAwardSignature = signature;
    }
  }

  Future<void> _startChallenge(ChallengeTemplate template) async {
    final l10n = AppLocalizations.of(context)!;
    await _challengeService.startChallenge(template);
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

class _ChallengeStartSection extends StatelessWidget {
  final List<ChallengeTemplate> templates;
  final ChallengeRun? latestCompletedRun;
  final String Function(ChallengeTemplate template) templateTitle;
  final String Function(ChallengeTemplate template) templateDescription;
  final ValueChanged<ChallengeTemplate> onStart;

  const _ChallengeStartSection({
    required this.templates,
    required this.latestCompletedRun,
    required this.templateTitle,
    required this.templateDescription,
    required this.onStart,
  });

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
          footer: latestCompletedRun == null
              ? null
              : _SmallStatusPill(label: l10n.challengeLatestComplete),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.challengeSelectTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        for (final template in templates) ...[
          _ChallengeTemplateCard(
            template: template,
            title: templateTitle(template),
            description: templateDescription(template),
            onStart: () => onStart(template),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ChallengeTemplateCard extends StatelessWidget {
  final ChallengeTemplate template;
  final String title;
  final String description;
  final VoidCallback onStart;

  const _ChallengeTemplateCard({
    required this.template,
    required this.title,
    required this.description,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('challenge-template-${template.id}'),
        onTap: onStart,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outline),
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
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
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
                  _SmallStatusPill(
                    label: l10n.challengeRewardXp(
                      template.rewardXpPerRound,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.challengeStartAction,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
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
            value: l10n.challengeTrainingGoalValue(
              round.trainingMinutes,
              round.round.targetTrainingMinutes,
            ),
            completed: round.trainingCompleted,
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
                      label: l10n.challengeTrainingGoalValue(
                        round.trainingMinutes,
                        round.round.targetTrainingMinutes,
                      ),
                    ),
                    _SmallStatusPill(
                      label: l10n.challengeMealGoalValue(
                        _formatBowls(round.riceBowls),
                        _formatBowls(round.round.targetRiceBowls),
                      ),
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
