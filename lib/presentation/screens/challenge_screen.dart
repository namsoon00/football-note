import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../application/backup_service.dart';
import '../../application/challenge_service.dart';
import '../../application/family_access_service.dart';
import '../../application/locale_service.dart';
import '../../application/localized_option_defaults.dart';
import '../../application/meal_log_service.dart';
import '../../application/player_level_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../theme/app_motion.dart';
import '../widgets/app_background.dart';
import '../widgets/app_page_route.dart';
import '../widgets/progress_star_gauge.dart';
import '../widgets/rinzy_mascot.dart';
import 'entry_form_screen.dart';
import 'meal_log_screen.dart';
import 'settings_screen.dart';

typedef _OpenChallengeTrainingMission =
    Future<void> Function(
      ChallengeRoundProgress round, {
      ChallengeTrainingProgramProgress? program,
    });

class ChallengeScreen extends StatefulWidget {
  final TrainingService trainingService;
  final MealLogService mealLogService;
  final OptionRepository optionRepository;
  final LocaleService localeService;
  final SettingsService settingsService;
  final BackupService? driveBackupService;

  const ChallengeScreen({
    super.key,
    required this.trainingService,
    required this.mealLogService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
    this.driveBackupService,
  });

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  late final ChallengeService _challengeService;
  late final SettingsService _settingsService;
  late final TrainingPlanReminderService _reminderService;
  bool _finalizeInFlight = false;
  bool _roundAwardInFlight = false;
  bool _reminderSyncInFlight = false;
  String? _lastFinalizeSignature;
  String? _lastRoundAwardSignature;
  String? _lastReminderSignature;

  @override
  void initState() {
    super.initState();
    _challengeService = ChallengeService(widget.optionRepository);
    _settingsService = widget.settingsService;
    _reminderService = TrainingPlanReminderService(
      widget.optionRepository,
      _settingsService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isParentReadOnlyMode = _isParentReadOnlyMode;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.challengeTitle),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: TextButton.icon(
              onPressed: _openRewardGuide,
              icon: const Icon(Icons.workspace_premium_outlined),
              label: Text(l10n.challengeRewardAction),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: TextButton.icon(
              onPressed: _openHistory,
              icon: const Icon(Icons.history),
              label: Text(l10n.challengeHistoryAction),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<List<TrainingEntry>>(
            stream: _watchChallengeTrainingEntries(),
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
                  if (progress != null && !isParentReadOnlyMode) {
                    _scheduleRoundAwardSync(progress);
                    _scheduleFinalizeSync(progress);
                  }
                  if (!isParentReadOnlyMode) {
                    _scheduleChallengeReminderSync(progress);
                  }
                  final skillOptions = _challengeProgramSkillOptions(
                    l10n,
                    widget.optionRepository,
                  );
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      if (progress == null && isParentReadOnlyMode)
                        const _ChallengeReadOnlyEmptySection()
                      else if (progress == null)
                        _ChallengeStartSection(
                          templates: _challengeService.templates(),
                          templateTitle: (template) =>
                              _templateTitle(l10n, template),
                          templateDescription: (template) =>
                              _templateDescription(l10n, template),
                          skillOptions: skillOptions,
                          onOpenTrainingPrograms: _openTrainingProgramSetup,
                          onStart: _startChallenge,
                        )
                      else
                        _ActiveChallengeSection(
                          progress: progress,
                          templateTitle: _templateTitle(
                            l10n,
                            progress.template,
                          ),
                          readOnly: isParentReadOnlyMode,
                          onAbandon: _confirmAbandon,
                          onOpenTraining: _openTrainingMission,
                          onOpenJumpRope: _openJumpRopeMission,
                          onOpenLifting: _openLiftingMission,
                          onOpenMeal: _openMealMission,
                          onOpenTrainingPrograms: _openTrainingProgramSetup,
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

  void _scheduleFinalizeSync(ChallengeProgress progress) {
    if (!progress.readyToFinalize()) return;
    final signature = _finalizationSignature(progress);
    if (_finalizeInFlight || _lastFinalizeSignature == signature) return;
    _lastFinalizeSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_syncFinalization(progress, signature));
    });
  }

  void _scheduleRoundAwardSync(ChallengeProgress progress) {
    if (progress.readyToFinalize()) return;
    final completedRounds = progress.rounds
        .where((round) => round.completed)
        .map((round) => round.round.number)
        .join(',');
    if (completedRounds.isEmpty) return;
    final signature = '${progress.run.id}:rounds:$completedRounds';
    if (_roundAwardInFlight || _lastRoundAwardSignature == signature) return;
    _lastRoundAwardSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_syncRoundAwards(progress, signature));
    });
  }

  Future<void> _syncRoundAwards(
    ChallengeProgress progress,
    String signature,
  ) async {
    if (_roundAwardInFlight) return;
    _roundAwardInFlight = true;
    try {
      final awards = await _challengeService.awardCompletedRounds(
        progress: progress,
        playerLevelService: PlayerLevelService(widget.optionRepository),
      );
      final gainedXp = awards.fold<int>(
        0,
        (sum, award) => sum + award.gainedXp,
      );
      if (gainedXp <= 0 || !mounted) return;
      await _showChallengeXpAlerts(awards, gainedXp);
      if (!mounted) return;
      _playChallengeSuccessFeedback();
      final awardedRoundCount = awards
          .where((award) => award.reasons.contains('challenge_round_completed'))
          .length
          .clamp(1, progress.rounds.length)
          .toInt();
      await Navigator.of(context).push(
        AppPageRoute<void>(
          builder: (_) => _ChallengeCelebrationScreen(
            gainedXp: gainedXp,
            awardedRoundCount: awardedRoundCount,
            challengeCompleted: false,
            roundGainedXp: gainedXp,
            completionGainedXp: 0,
          ),
        ),
      );
      if (!mounted) return;
      setState(() {});
    } finally {
      _roundAwardInFlight = false;
      _lastRoundAwardSignature = signature;
    }
  }

  void _scheduleChallengeReminderSync(ChallengeProgress? progress) {
    final signature = progress == null
        ? 'none'
        : '${progress.run.id}:'
              '${progress.rounds.where((round) => round.completed).map((round) => round.round.number).join(',')}:'
              '${progress.rounds.length}';
    if (_reminderSyncInFlight || _lastReminderSignature == signature) return;
    _lastReminderSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_syncChallengeReminders(progress, signature));
    });
  }

  Future<void> _syncChallengeReminders(
    ChallengeProgress? progress,
    String signature,
  ) async {
    if (_reminderSyncInFlight) return;
    _reminderSyncInFlight = true;
    try {
      await _reminderService.syncChallengeReminders(progress);
    } finally {
      _reminderSyncInFlight = false;
      _lastReminderSignature = signature;
    }
  }

  Future<void> _syncFinalization(
    ChallengeProgress progress,
    String signature,
  ) async {
    if (_finalizeInFlight) return;
    _finalizeInFlight = true;
    try {
      final awards = await _challengeService.finalizeRun(
        progress: progress,
        playerLevelService: PlayerLevelService(widget.optionRepository),
      );
      final gainedXp = awards.fold<int>(
        0,
        (sum, award) => sum + award.gainedXp,
      );
      final completionGainedXp = awards
          .where((award) => award.reasons.contains('challenge_completed_bonus'))
          .fold<int>(0, (sum, award) => sum + award.gainedXp);
      final roundGainedXp = gainedXp - completionGainedXp;
      if (!mounted) return;
      if (gainedXp > 0) {
        await _showChallengeXpAlerts(awards, gainedXp);
        if (!mounted) return;
      }
      if (!progress.allRoundsCompleted) {
        _playChallengeSuccessFeedback();
        await Navigator.of(context).push(
          AppPageRoute<void>(
            builder: (_) => _ChallengeFailureScreen(gainedXp: gainedXp),
          ),
        );
      } else {
        _playChallengeSuccessFeedback();
        final awardedRoundCount = progress.completedRoundCount
            .clamp(1, progress.rounds.length)
            .toInt();
        await Navigator.of(context).push(
          AppPageRoute<void>(
            builder: (_) => _ChallengeCelebrationScreen(
              gainedXp: gainedXp,
              awardedRoundCount: awardedRoundCount,
              challengeCompleted: progress.allRoundsCompleted,
              roundGainedXp: roundGainedXp,
              completionGainedXp: completionGainedXp,
            ),
          ),
        );
      }
      if (!mounted) return;
      setState(() {});
    } finally {
      _finalizeInFlight = false;
      _lastFinalizeSignature = signature;
    }
  }

  String _finalizationSignature(ChallengeProgress progress) {
    final completedRounds = progress.rounds
        .where((round) => round.completed)
        .map((round) => round.round.number)
        .join(',');
    return '${progress.run.id}:finalize:$completedRounds:${progress.rounds.length}';
  }

  Future<void> _finalizeChallengeIfReadyNow() async {
    if (_isParentReadOnlyMode || _finalizeInFlight) return;
    final trainingEntries = (await _activeChallengeTrainingEntries())
        .where((entry) => !entry.isMatch)
        .toList(growable: false);
    final mealEntries = widget.mealLogService.mergedEntries(
      directEntries: widget.mealLogService.allEntries(),
      legacyEntries: trainingEntries,
    );
    final progress = _challengeService.activeProgress(
      trainingEntries: trainingEntries,
      mealEntries: mealEntries,
    );
    if (progress == null || !progress.readyToFinalize()) return;
    final signature = _finalizationSignature(progress);
    if (_lastFinalizeSignature == signature) return;
    await _syncFinalization(progress, signature);
  }

  Future<void> _showChallengeXpAlerts(
    List<PlayerLevelAward> awards,
    int gainedXp,
  ) async {
    if (awards.isEmpty || gainedXp <= 0) return;
    final l10n = AppLocalizations.of(context)!;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final lastAward = awards.last;
    await _reminderService.showXpGainAlert(
      gainedXp: gainedXp,
      totalXp: lastAward.after.totalXp,
      isKo: isKo,
      sourceLabel: l10n.challengeTitle,
    );
    PlayerLevelAward? leveledAward;
    for (final award in awards) {
      if (award.didLevelUp) {
        leveledAward = award;
        break;
      }
    }
    if (leveledAward == null) return;
    await _reminderService.showLevelUpAlert(
      level: leveledAward.after.level,
      isKo: isKo,
    );
  }

  void _openHistory() {
    final historyRuns = _challengeService
        .loadRuns()
        .where((run) => run.isEnded)
        .toList(growable: false);
    Navigator.of(context).push(
      AppPageRoute<void>(
        builder: (_) => _ChallengeHistoryScreen(runs: historyRuns),
      ),
    );
  }

  Stream<List<TrainingEntry>> _watchChallengeTrainingEntries() {
    final range = _activeChallengeTrainingRange();
    if (range == null) {
      return Stream<List<TrainingEntry>>.value(const <TrainingEntry>[]);
    }
    return widget.trainingService.watchEntriesInRange(range.start, range.end);
  }

  Future<List<TrainingEntry>> _activeChallengeTrainingEntries() async {
    final range = _activeChallengeTrainingRange();
    if (range == null) return const <TrainingEntry>[];
    return widget.trainingService.entriesInRange(range.start, range.end);
  }

  DateTimeRange? _activeChallengeTrainingRange() {
    final run = _challengeService.activeRun();
    if (run == null) return null;
    final template = _challengeService.templateById(run.templateId);
    if (template == null) return null;
    final start = run.startDay;
    return DateTimeRange(
      start: start,
      end: start.add(Duration(days: template.dayCount)),
    );
  }

  Future<void> _openRewardGuide() async {
    final trainingEntries = (await _activeChallengeTrainingEntries())
        .where((entry) => !entry.isMatch)
        .toList(growable: false);
    final mealEntries = widget.mealLogService.mergedEntries(
      legacyEntries: trainingEntries,
    );
    final progress = _challengeService.activeProgress(
      trainingEntries: trainingEntries,
      mealEntries: mealEntries,
    );
    if (!mounted) return;
    Navigator.of(context).push(
      AppPageRoute<void>(
        builder: (_) => _ChallengeRewardGuideScreen(
          progress: progress,
          templates: _challengeService.templates(),
        ),
      ),
    );
  }

  Future<void> _startChallenge(
    ChallengeTemplate template,
    List<String> selectedSkillIds,
    ChallengeMissionTargets missionTargets,
  ) async {
    if (_isParentReadOnlyMode) {
      _showParentReadOnlyMessage();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    _playChallengeTapFeedback();
    await _challengeService.startChallenge(
      template,
      selectedSkillIds: selectedSkillIds,
      missionTargets: missionTargets,
    );
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.challengeStartSnack(_templateTitle(l10n, template))),
      ),
    );
  }

  Future<void> _confirmAbandon() async {
    if (_isParentReadOnlyMode) {
      _showParentReadOnlyMessage();
      return;
    }
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

  Future<void> _openTrainingMission(
    ChallengeRoundProgress round, {
    ChallengeTrainingProgramProgress? program,
  }) {
    return _openTrainingEntryMission(
      round,
      initialFocusTarget: null,
      programMission: program,
    );
  }

  Future<void> _openJumpRopeMission(ChallengeRoundProgress round) {
    return _openTrainingEntryMission(
      round,
      initialFocusTarget: EntryFormInitialFocusTarget.jumpRope,
    );
  }

  Future<void> _openLiftingMission(ChallengeRoundProgress round) {
    return _openTrainingEntryMission(
      round,
      initialFocusTarget: EntryFormInitialFocusTarget.lifting,
    );
  }

  Future<void> _openTrainingEntryMission(
    ChallengeRoundProgress round, {
    required EntryFormInitialFocusTarget? initialFocusTarget,
    ChallengeTrainingProgramProgress? programMission,
  }) async {
    if (_isParentReadOnlyMode) {
      _showParentReadOnlyMessage();
      return;
    }
    _playChallengeTapFeedback();
    final navigator = Navigator.of(context);
    final existingEntry = await _trainingEntryForRound(
      round.date,
      programId: programMission?.programId,
    );
    if (!mounted) return;
    final targetTrainingMinutes =
        programMission?.targetMinutes ?? round.round.targetTrainingMinutes;
    final currentTrainingMinutes =
        programMission?.currentMinutes ?? round.trainingMinutes;
    final remainingTrainingMinutes =
        (targetTrainingMinutes - currentTrainingMinutes)
            .clamp(0, targetTrainingMinutes)
            .toInt();
    final initialPlanContext =
        existingEntry == null &&
            initialFocusTarget == null &&
            targetTrainingMinutes > 0
        ? EntryFormInitialPlanContext(
            scheduledAt: round.date,
            program: programMission?.label ?? '',
            durationMinutes: remainingTrainingMinutes > 0
                ? remainingTrainingMinutes
                : targetTrainingMinutes,
          )
        : null;
    final initialConditioningOnly =
        existingEntry == null &&
        initialPlanContext == null &&
        initialFocusTarget != null;
    await navigator.push(
      AppPageRoute<void>(
        builder: (_) => EntryFormScreen(
          trainingService: widget.trainingService,
          optionRepository: widget.optionRepository,
          localeService: widget.localeService,
          settingsService: _settingsService,
          driveBackupService: widget.driveBackupService,
          entry: existingEntry,
          initialDate: existingEntry == null && initialPlanContext == null
              ? round.date
              : null,
          initialPlanContext: initialPlanContext,
          initialFocusTarget: initialFocusTarget,
          initialConditioningOnly: initialConditioningOnly,
          initialEnableJumpRope:
              initialFocusTarget != null &&
              round.round.targetJumpRopeMinutes > 0,
          initialEnableLifting:
              initialFocusTarget != null &&
              round.round.targetLiftingMinutes > 0,
        ),
      ),
    );
    if (!mounted) return;
    await _finalizeChallengeIfReadyNow();
    if (!mounted) return;
    setState(() {});
  }

  Future<TrainingEntry?> _trainingEntryForRound(
    DateTime day, {
    String? programId,
  }) async {
    final normalizedDay = normalizeDay(day);
    final targetProgram = programId?.trim();
    final entries = await widget.trainingService.entriesInRange(
      normalizedDay,
      normalizedDay.add(const Duration(days: 1)),
    );
    final sameDayEntries =
        entries
            .where(
              (entry) =>
                  !entry.isMatch && normalizeDay(entry.date) == normalizedDay,
            )
            .where(
              (entry) =>
                  targetProgram == null ||
                  targetProgram.isEmpty ||
                  trainingEntryMatchesChallengeSkill(entry, <String>[
                    targetProgram,
                  ]),
            )
            .toList(growable: false)
          ..sort(TrainingEntry.compareByRecentCreated);
    return sameDayEntries.isEmpty ? null : sameDayEntries.first;
  }

  Future<void> _openMealMission(ChallengeRoundProgress round) async {
    if (_isParentReadOnlyMode) {
      _showParentReadOnlyMessage();
      return;
    }
    _playChallengeTapFeedback();
    await Navigator.of(context).push(
      AppPageRoute<void>(
        builder: (_) => MealLogScreen(
          mealLogService: widget.mealLogService,
          optionRepository: widget.optionRepository,
          settingsService: _settingsService,
          initialDate: round.date,
        ),
      ),
    );
    if (!mounted) return;
    await _finalizeChallengeIfReadyNow();
    if (mounted) setState(() {});
  }

  Future<void> _openTrainingProgramSetup() async {
    if (_isParentReadOnlyMode) {
      _showParentReadOnlyMessage();
      return;
    }
    _playChallengeTapFeedback();
    await Navigator.of(context).push(
      AppPageRoute<void>(
        builder: (_) => SettingsScreen(
          localeService: widget.localeService,
          settingsService: _settingsService,
          optionRepository: widget.optionRepository,
          driveBackupService: widget.driveBackupService,
          initialTarget: SettingsInitialTarget.trainingPrograms,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  void _playChallengeTapFeedback() {
    unawaited(HapticFeedback.selectionClick());
    unawaited(SystemSound.play(SystemSoundType.click));
  }

  void _playChallengeSuccessFeedback() {
    unawaited(HapticFeedback.heavyImpact());
    unawaited(SystemSound.play(SystemSoundType.alert));
  }

  bool get _isParentReadOnlyMode {
    return FamilyAccessService(
      widget.optionRepository,
    ).loadState().isParentMode;
  }

  void _showParentReadOnlyMessage() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.parentReadOnlyChallengeMessage,
          ),
        ),
      );
  }
}

class _ChallengeReadOnlyEmptySection extends StatelessWidget {
  const _ChallengeReadOnlyEmptySection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChallengeIntroCard(
          title: l10n.challengeStartHeroTitle,
          body: l10n.challengeStartHeroBody,
          progress: 0,
        ),
        const SizedBox(height: 18),
        const _ParentReadOnlyChallengeNotice(),
      ],
    );
  }
}

class _ParentReadOnlyChallengeNotice extends StatelessWidget {
  const _ParentReadOnlyChallengeNotice();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.parentReadOnlyChallengeSummary,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.parentReadOnlyChallengeMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
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

class _ChallengeStartSection extends StatefulWidget {
  final List<ChallengeTemplate> templates;
  final String Function(ChallengeTemplate template) templateTitle;
  final String Function(ChallengeTemplate template) templateDescription;
  final List<_ChallengeSkillOption> skillOptions;
  final VoidCallback onOpenTrainingPrograms;
  final void Function(
    ChallengeTemplate template,
    List<String> selectedSkillIds,
    ChallengeMissionTargets missionTargets,
  )
  onStart;

  const _ChallengeStartSection({
    required this.templates,
    required this.templateTitle,
    required this.templateDescription,
    required this.skillOptions,
    required this.onOpenTrainingPrograms,
    required this.onStart,
  });

  @override
  State<_ChallengeStartSection> createState() => _ChallengeStartSectionState();
}

class _ChallengeStartSectionState extends State<_ChallengeStartSection> {
  final GlobalKey _missionSectionKey = GlobalKey();
  final GlobalKey _readySectionKey = GlobalKey();
  ChallengeTemplate? _selectedTemplate;
  late Set<String> _selectedSkillIds;
  ChallengeMissionTargets? _missionTargets;

  @override
  void initState() {
    super.initState();
    _selectedSkillIds = <String>{};
  }

  @override
  void didUpdateWidget(_ChallengeStartSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameChallengeSkillOptions(
      oldWidget.skillOptions,
      widget.skillOptions,
    )) {
      final availableIds = widget.skillOptions
          .map((option) => option.id)
          .toSet();
      _selectedSkillIds = _selectedSkillIds
          .where(availableIds.contains)
          .toSet();
    }
    final selectedTemplate = _selectedTemplate;
    if (selectedTemplate != null &&
        !widget.templates.contains(selectedTemplate)) {
      _selectedTemplate = null;
      _missionTargets = null;
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
            onSelect: () => _selectTemplate(template),
          ),
          const SizedBox(height: 10),
        ],
        if (_selectedTemplate != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.challengeSkillSelectTitle,
            key: _missionSectionKey,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.challengeSkillSelectSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          _ChallengeMissionPicker(
            trainingProgramOptions: widget.skillOptions,
            selectedTrainingProgramIds: _selectedSkillIds,
            missionTargets: _effectiveMissionTargets,
            defaultTargets: _defaultMissionTargetsForSelectedLevel,
            onTrainingProgramsChanged: _updateSelectedTrainingPrograms,
            onMissionTargetsChanged: _updateMissionTargets,
          ),
          const SizedBox(height: 10),
          _TrainingProgramLinkCard(
            onOpenTrainingPrograms: widget.onOpenTrainingPrograms,
          ),
          const SizedBox(height: 10),
          _ChallengeMissionTargetSection(
            selectedTrainingPrograms: widget.skillOptions
                .where((option) => _selectedSkillIds.contains(option.id))
                .toList(growable: false),
            missionTargets: _effectiveMissionTargets,
            onChanged: _updateMissionTargets,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.challengeStartReadyTitle,
            key: _readySectionKey,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _RewardPitchCard(
            roundXp: trainingLevelConfig(
              ChallengeTrainingLevel.rookie,
            ).rewardXpPerRound,
            streakBonusXp: challengeRoundStreakBonusXpFor(
              _selectedTemplate!.dayCount,
            ),
            completionBonusXp: challengeCompletionBonusXpFor(
              _selectedTemplate!,
              ChallengeTrainingLevel.rookie,
            ),
            totalXp: challengeTotalPotentialXpFor(
              _selectedTemplate!,
              ChallengeTrainingLevel.rookie,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => widget.onStart(
              _selectedTemplate!,
              normalizeChallengeSkillIds(
                _selectedSkillIds,
                allowEmpty: !_effectiveMissionTargets.hasTrainingMission,
              ),
              _effectiveMissionTargets,
            ),
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.challengeStartAction),
          ),
        ],
      ],
    );
  }

  void _selectTemplate(ChallengeTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _missionTargets = challengeMissionTargetsFromConfig(
        trainingLevelConfig(ChallengeTrainingLevel.rookie),
      );
      _selectedSkillIds = <String>{};
    });
    _scrollTo(_missionSectionKey);
  }

  ChallengeMissionTargets get _defaultMissionTargetsForSelectedLevel {
    return challengeMissionTargetsFromConfig(
      trainingLevelConfig(ChallengeTrainingLevel.rookie),
    );
  }

  ChallengeMissionTargets get _effectiveMissionTargets {
    final targets = _missionTargets ?? _defaultMissionTargetsForSelectedLevel;
    if (_selectedSkillIds.isEmpty && targets.hasTrainingMission) {
      return targets.copyWith(
        trainingMinutes: 0,
        trainingProgramMinutes: const <String, int>{},
      );
    }
    if (_selectedSkillIds.isEmpty) return targets;
    return _targetsWithSelectedTrainingPrograms(targets, _selectedSkillIds);
  }

  void _updateSelectedTrainingPrograms(Set<String> ids) {
    final defaults = _defaultMissionTargetsForSelectedLevel;
    final current = _missionTargets ?? defaults;
    setState(() {
      _selectedSkillIds = ids;
      _missionTargets = _targetsWithSelectedTrainingPrograms(
        current,
        ids,
        defaultTrainingMinutes: defaults.trainingMinutes,
      );
    });
  }

  void _updateMissionTargets(ChallengeMissionTargets targets) {
    if (!targets.hasAnyMission) return;
    setState(() {
      _missionTargets = targets;
      if (!targets.hasTrainingMission) {
        _selectedSkillIds = <String>{};
      }
    });
  }

  ChallengeMissionTargets _targetsWithSelectedTrainingPrograms(
    ChallengeMissionTargets targets,
    Set<String> selectedIds, {
    int? defaultTrainingMinutes,
  }) {
    if (selectedIds.isEmpty) {
      return targets.copyWith(
        trainingMinutes: 0,
        trainingProgramMinutes: const <String, int>{},
      );
    }
    final fallback = _defaultTrainingProgramTarget(
      targets,
      defaultTrainingMinutes ??
          _defaultMissionTargetsForSelectedLevel.trainingMinutes,
    );
    final programTargets = <String, int>{
      for (final id in selectedIds)
        id: targets.trainingProgramMinutes[id] ?? fallback,
    };
    final total = programTargets.values.fold<int>(
      0,
      (sum, minutes) => sum + minutes,
    );
    return targets.copyWith(
      trainingMinutes: total,
      trainingProgramMinutes: programTargets,
    );
  }

  void _scrollTo(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context == null || !mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }
}

class _ChallengeTemplateCard extends StatelessWidget {
  final ChallengeTemplate template;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onSelect;

  const _ChallengeTemplateCard({
    required this.template,
    required this.title,
    required this.description,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accent = _challengeTemplateAccent(template.id);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('challenge-template-${template.id}'),
        onTap: onSelect,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: selected ? 0.12 : 0.05),
                theme.colorScheme.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent : theme.colorScheme.outlineVariant,
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
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.flag_outlined, color: accent),
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
                        ? accent
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const List<int> _challengeTrainingTargetOptions = <int>[
  15,
  30,
  45,
  60,
  75,
  90,
  120,
  150,
  180,
];

const List<int> _challengeConditioningTargetOptions = <int>[
  5,
  10,
  15,
  20,
  30,
  45,
  60,
];

const List<double> _challengeMealTargetOptions = <double>[
  1,
  1.5,
  2,
  2.5,
  3,
  3.5,
  4,
  4.5,
];

class _ChallengeMissionPicker extends StatelessWidget {
  final List<_ChallengeSkillOption> trainingProgramOptions;
  final Set<String> selectedTrainingProgramIds;
  final ChallengeMissionTargets missionTargets;
  final ChallengeMissionTargets defaultTargets;
  final ValueChanged<Set<String>> onTrainingProgramsChanged;
  final ValueChanged<ChallengeMissionTargets> onMissionTargetsChanged;

  const _ChallengeMissionPicker({
    required this.trainingProgramOptions,
    required this.selectedTrainingProgramIds,
    required this.missionTargets,
    required this.defaultTargets,
    required this.onTrainingProgramsChanged,
    required this.onMissionTargetsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MissionPickerSectionTitle(
            icon: Icons.tune_rounded,
            label: l10n.program,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in trainingProgramOptions)
                _MissionFilterChip(
                  option: option,
                  selected: selectedTrainingProgramIds.contains(option.id),
                  onSelected: (selected) {
                    final next = Set<String>.from(selectedTrainingProgramIds);
                    if (selected) {
                      next.add(option.id);
                    } else {
                      next.remove(option.id);
                    }
                    if (!_hasAnySelectedMission(next, missionTargets)) return;
                    onTrainingProgramsChanged(next);
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
          _MissionPickerSectionTitle(
            icon: Icons.checklist_rounded,
            label: l10n.challengeMissionOtherSectionTitle,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MissionToggleChip(
                icon: Icons.sports_gymnastics_rounded,
                label: l10n.challengeJumpRopeLabel,
                selected: missionTargets.hasJumpRopeMission,
                onSelected: (selected) => _toggleJumpRope(selected),
              ),
              _MissionToggleChip(
                icon: Icons.sports_soccer_outlined,
                label: l10n.challengeLiftingLabel,
                selected: missionTargets.hasLiftingMission,
                onSelected: (selected) => _toggleLifting(selected),
              ),
              _MissionToggleChip(
                icon: Icons.rice_bowl_outlined,
                label: l10n.challengeMealLabel,
                selected: missionTargets.hasMealMission,
                onSelected: (selected) => _toggleMeal(selected),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleJumpRope(bool selected) {
    final next = missionTargets.copyWith(
      jumpRopeMinutes: selected ? defaultTargets.jumpRopeMinutes : 0,
    );
    if (!_hasAnySelectedMission(selectedTrainingProgramIds, next)) return;
    onMissionTargetsChanged(next);
  }

  void _toggleLifting(bool selected) {
    final next = missionTargets.copyWith(
      liftingMinutes: selected ? defaultTargets.liftingMinutes : 0,
    );
    if (!_hasAnySelectedMission(selectedTrainingProgramIds, next)) return;
    onMissionTargetsChanged(next);
  }

  void _toggleMeal(bool selected) {
    final next = missionTargets.copyWith(
      riceBowls: selected ? defaultTargets.riceBowls : 0,
    );
    if (!_hasAnySelectedMission(selectedTrainingProgramIds, next)) return;
    onMissionTargetsChanged(next);
  }
}

class _MissionPickerSectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MissionPickerSectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _MissionFilterChip extends StatelessWidget {
  final _ChallengeSkillOption option;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _MissionFilterChip({
    required this.option,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(option.label),
      selected: selected,
      selectedColor: option.color.withValues(alpha: 0.12),
      checkmarkColor: option.color,
      side: BorderSide(
        color: selected
            ? option.color.withValues(alpha: 0.45)
            : theme.colorScheme.outlineVariant,
      ),
      onSelected: onSelected,
    );
  }
}

class _MissionToggleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _MissionToggleChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      avatar: Icon(
        icon,
        size: 18,
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(label),
      selected: selected,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.12),
      checkmarkColor: theme.colorScheme.primary,
      side: BorderSide(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.45)
            : theme.colorScheme.outlineVariant,
      ),
      onSelected: onSelected,
    );
  }
}

class _ChallengeMissionTargetSection extends StatelessWidget {
  final List<_ChallengeSkillOption> selectedTrainingPrograms;
  final ChallengeMissionTargets missionTargets;
  final ValueChanged<ChallengeMissionTargets> onChanged;

  const _ChallengeMissionTargetSection({
    required this.selectedTrainingPrograms,
    required this.missionTargets,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.challengeMissionTargetsTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.challengeMissionTargetsSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (selectedTrainingPrograms.isNotEmpty) ...[
            for (final program in selectedTrainingPrograms) ...[
              _MissionTargetChoiceRow<int>(
                title: program.label,
                subtitle: l10n.program,
                value: _targetForTrainingProgram(program.id),
                values: _challengeTrainingTargetOptions,
                labelBuilder: l10n.minutes,
                onChanged: (value) => onChanged(
                  _copyWithTrainingProgramTarget(program.id, value),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
          if (missionTargets.hasJumpRopeMission) ...[
            _MissionTargetChoiceRow<int>(
              icon: Icons.sports_gymnastics_rounded,
              title: l10n.challengeJumpRopeLabel,
              value: missionTargets.jumpRopeMinutes,
              values: _challengeConditioningTargetOptions,
              labelBuilder: l10n.minutes,
              onChanged: (value) =>
                  onChanged(missionTargets.copyWith(jumpRopeMinutes: value)),
            ),
            const SizedBox(height: 12),
          ],
          if (missionTargets.hasLiftingMission) ...[
            _MissionTargetChoiceRow<int>(
              icon: Icons.sports_soccer_outlined,
              title: l10n.challengeLiftingLabel,
              value: missionTargets.liftingMinutes,
              values: _challengeConditioningTargetOptions,
              labelBuilder: l10n.minutes,
              onChanged: (value) =>
                  onChanged(missionTargets.copyWith(liftingMinutes: value)),
            ),
            const SizedBox(height: 12),
          ],
          if (missionTargets.hasMealMission)
            _MissionTargetChoiceRow<double>(
              icon: Icons.rice_bowl_outlined,
              title: l10n.challengeMealLabel,
              value: missionTargets.riceBowls,
              values: _challengeMealTargetOptions,
              labelBuilder: (value) =>
                  l10n.challengeRiceBowlsOption(_formatBowls(value)),
              onChanged: (value) =>
                  onChanged(missionTargets.copyWith(riceBowls: value)),
            ),
        ],
      ),
    );
  }

  int _targetForTrainingProgram(String programId) {
    final target = missionTargets.trainingProgramMinutes[programId];
    if (target != null && target > 0) return target;
    if (missionTargets.trainingMinutes > 0) {
      return missionTargets.trainingMinutes;
    }
    return _challengeTrainingTargetOptions.first;
  }

  ChallengeMissionTargets _copyWithTrainingProgramTarget(
    String programId,
    int value,
  ) {
    final targets = <String, int>{
      for (final program in selectedTrainingPrograms)
        program.id: _targetForTrainingProgram(program.id),
    };
    targets[programId] = value;
    final total = targets.values.fold<int>(0, (sum, minutes) => sum + minutes);
    return missionTargets.copyWith(
      trainingMinutes: total,
      trainingProgramMinutes: targets,
    );
  }
}

class _MissionTargetChoiceRow<T extends num> extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  const _MissionTargetChoiceRow({
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveValues = values.contains(value)
        ? values
        : (<T>[value, ...values]..sort((a, b) => a.compareTo(b)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (subtitle?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in effectiveValues)
              ChoiceChip(
                label: Text(labelBuilder(option)),
                selected: option == value,
                onSelected: (_) => onChanged(option),
              ),
          ],
        ),
      ],
    );
  }
}

bool _hasAnySelectedMission(
  Set<String> selectedTrainingProgramIds,
  ChallengeMissionTargets missionTargets,
) {
  return selectedTrainingProgramIds.isNotEmpty ||
      missionTargets.hasJumpRopeMission ||
      missionTargets.hasLiftingMission ||
      missionTargets.hasMealMission;
}

int _defaultTrainingProgramTarget(
  ChallengeMissionTargets targets,
  int fallback,
) {
  for (final minutes in targets.trainingProgramMinutes.values) {
    if (minutes > 0) return minutes;
  }
  if (targets.trainingMinutes > 0) return targets.trainingMinutes;
  return fallback;
}

class _TrainingProgramLinkCard extends StatelessWidget {
  final VoidCallback onOpenTrainingPrograms;
  final bool compact;

  const _TrainingProgramLinkCard({
    required this.onOpenTrainingPrograms,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenTrainingPrograms,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.07),
                theme.colorScheme.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 36 : 42,
                height: compact ? 36 : 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.tune_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.challengeTrainingProgramLinkTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.challengeTrainingProgramLinkBody,
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.challengeTrainingProgramLinkAction,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardPitchCard extends StatelessWidget {
  final int roundXp;
  final int streakBonusXp;
  final int completionBonusXp;
  final int totalXp;

  const _RewardPitchCard({
    required this.roundXp,
    required this.streakBonusXp,
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
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
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
              if (streakBonusXp > 0)
                _SmallStatusPill(
                  label: l10n.challengeStreakBonusLabel(streakBonusXp),
                ),
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

class _ChallengeRewardGuideScreen extends StatelessWidget {
  final ChallengeProgress? progress;
  final List<ChallengeTemplate> templates;

  const _ChallengeRewardGuideScreen({
    required this.progress,
    required this.templates,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeProgress = progress;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.challengeRewardGuideTitle)),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _ChallengeIntroCard(
                title: l10n.challengeRewardGuideTitle,
                body: l10n.challengeRewardGuideBody,
                progress: activeProgress?.completionRate ?? 0,
              ),
              const SizedBox(height: 12),
              if (activeProgress == null)
                _ChallengeDetailCard(
                  child: _ChallengeInlineNotice(
                    icon: Icons.flag_outlined,
                    message: l10n.challengeRewardGuideNoActive,
                  ),
                )
              else
                _ChallengeRewardBreakdownCard(
                  title: l10n.challengeRewardGuideActiveTitle,
                  template: activeProgress.template,
                  level: activeProgress.run.trainingLevel,
                  progress: activeProgress,
                ),
              const SizedBox(height: 18),
              _ChallengeSectionHeader(
                title: l10n.challengeRewardGuideTemplatesTitle,
              ),
              const SizedBox(height: 10),
              for (final template in templates) ...[
                _ChallengeRewardBreakdownCard(
                  title: l10n.challengeRewardGuideTemplateTitle(
                    _templateTitle(l10n, template),
                  ),
                  template: template,
                  level: ChallengeTrainingLevel.rookie,
                ),
                if (template != templates.last) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeRewardBreakdownCard extends StatelessWidget {
  final String title;
  final ChallengeTemplate template;
  final ChallengeTrainingLevel level;
  final ChallengeProgress? progress;

  const _ChallengeRewardBreakdownCard({
    required this.title,
    required this.template,
    required this.level,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final config = trainingLevelConfig(level);
    final totalRoundXp = challengeTotalRoundRewardXpFor(template, level);
    final finishBonusXp = challengeCompletionBonusXpFor(template, level);
    final totalPotentialXp = challengeTotalPotentialXpFor(template, level);
    final activeProgress = progress;
    final earnedRoundXp = activeProgress == null
        ? null
        : _challengeEarnedRoundXp(activeProgress);
    final remainingXp = earnedRoundXp == null
        ? null
        : (totalPotentialXp - earnedRoundXp).clamp(0, totalPotentialXp).toInt();
    return _ChallengeDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _ChallengeRewardTotalBand(
            totalPotentialXp: totalPotentialXp,
            totalRoundXp: totalRoundXp,
            finishBonusXp: finishBonusXp,
            earnedRoundXp: earnedRoundXp,
            remainingXp: remainingXp,
          ),
          if (activeProgress != null) ...[
            const SizedBox(height: 12),
            ProgressStarGauge(
              progress: activeProgress.completionRate,
              height: 30,
              trackHeight: 8,
              iconSize: 26,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SmallStatusPill(
                  label: l10n.challengeRoundCount(
                    activeProgress.completedRoundCount,
                    activeProgress.totalRoundCount,
                  ),
                ),
                _SmallStatusPill(
                  label: l10n.challengeProgressPercent(
                    (activeProgress.completionRate * 100).round(),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _ChallengeInfoGrid(
            items: [
              _ChallengeInfoItem(
                icon: Icons.star_border_rounded,
                label: l10n.challengeRewardGuideBaseRoundLabel,
                value: l10n.challengeRewardXp(config.rewardXpPerRound),
              ),
              _ChallengeInfoItem(
                icon: Icons.local_fire_department_outlined,
                label: l10n.challengeRewardGuideStreakBonusLabel,
                value: l10n.challengeRewardXp(
                  challengeRoundStreakBonusXpFor(template.dayCount),
                ),
              ),
              _ChallengeInfoItem(
                icon: Icons.format_list_numbered_rounded,
                label: l10n.challengeRewardGuideRoundTotalLabel,
                value: l10n.challengeRewardXp(totalRoundXp),
              ),
              _ChallengeInfoItem(
                icon: Icons.emoji_events_outlined,
                label: l10n.challengeRewardGuideFinishBonusLabel,
                value: l10n.challengeRewardXp(finishBonusXp),
              ),
              _ChallengeInfoItem(
                icon: Icons.workspace_premium_outlined,
                label: l10n.challengeRewardGuidePotentialLabel,
                value: l10n.challengeRewardXp(totalPotentialXp),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            l10n.challengeRewardGuideRoundsTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _ChallengeRewardRoundGrid(
            dayCount: template.dayCount,
            baseRewardXp: config.rewardXpPerRound,
            isCompleted: (roundNumber) =>
                _progressRoundCompleted(progress, roundNumber),
          ),
        ],
      ),
    );
  }
}

class _ChallengeRewardTotalBand extends StatelessWidget {
  final int totalPotentialXp;
  final int totalRoundXp;
  final int finishBonusXp;
  final int? earnedRoundXp;
  final int? remainingXp;

  const _ChallengeRewardTotalBand({
    required this.totalPotentialXp,
    required this.totalRoundXp,
    required this.finishBonusXp,
    required this.earnedRoundXp,
    required this.remainingXp,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.challengeRewardGuidePotentialLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                l10n.challengeRewardXp(totalPotentialXp),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallStatusPill(label: l10n.challengeRewardGuideRoundTotalLabel),
              _SmallStatusPill(label: l10n.challengeRewardXp(totalRoundXp)),
              _SmallStatusPill(
                label: l10n.challengeCompletionBonusLabel(finishBonusXp),
              ),
              if (earnedRoundXp != null)
                _SmallStatusPill(
                  label:
                      '${l10n.challengeRewardGuideEarnedLabel} ${l10n.challengeRewardXp(earnedRoundXp!)}',
                ),
              if (remainingXp != null)
                _SmallStatusPill(
                  label:
                      '${l10n.challengeRewardGuideRemainingLabel} ${l10n.challengeRewardXp(remainingXp!)}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChallengeRewardRoundGrid extends StatelessWidget {
  final int dayCount;
  final int baseRewardXp;
  final bool Function(int roundNumber) isCompleted;

  const _ChallengeRewardRoundGrid({
    required this.dayCount,
    required this.baseRewardXp,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560
            ? 4
            : constraints.maxWidth >= 380
            ? 3
            : 2;
        const spacing = 8.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var roundNumber = 1; roundNumber <= dayCount; roundNumber++)
              SizedBox(
                width: width,
                child: _ChallengeRewardRoundCard(
                  roundNumber: roundNumber,
                  rewardXp: challengeRoundRewardXpFor(
                    baseRewardXp: baseRewardXp,
                    consecutiveRoundNumber: roundNumber,
                  ),
                  streakBonusXp: challengeRoundStreakBonusXpFor(roundNumber),
                  completed: isCompleted(roundNumber),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ChallengeRewardRoundCard extends StatelessWidget {
  final int roundNumber;
  final int rewardXp;
  final int streakBonusXp;
  final bool completed;

  const _ChallengeRewardRoundCard({
    required this.roundNumber,
    required this.rewardXp,
    required this.streakBonusXp,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: completed
            ? scheme.primaryContainer.withValues(alpha: 0.56)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: completed
              ? scheme.primary.withValues(alpha: 0.42)
              : scheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                completed ? Icons.check_circle_rounded : Icons.flag_outlined,
                size: 18,
                color: completed ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.challengeRoundTitle(roundNumber),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.challengeRewardXp(rewardXp),
            style: theme.textTheme.titleSmall?.copyWith(
              color: completed ? scheme.primary : scheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (streakBonusXp > 0) ...[
            const SizedBox(height: 4),
            Text(
              l10n.challengeStreakBonusLabel(streakBonusXp),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChallengeHistoryScreen extends StatelessWidget {
  final List<ChallengeRun> runs;

  const _ChallengeHistoryScreen({required this.runs});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sortedRuns = List<ChallengeRun>.from(runs)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.challengeHistoryTitle)),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _ChallengeHistoryOverviewCard(runs: sortedRuns),
              if (sortedRuns.isNotEmpty) ...[
                const SizedBox(height: 16),
                _ChallengeHistorySection(
                  runs: sortedRuns,
                  showTitle: true,
                  limit: null,
                  onOpenRun: (run) {
                    Navigator.of(context).push(
                      AppPageRoute<void>(
                        builder: (_) => _ChallengeHistoryDetailScreen(run: run),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeHistorySection extends StatelessWidget {
  final List<ChallengeRun> runs;
  final bool showTitle;
  final ValueChanged<ChallengeRun>? onOpenRun;
  final int? limit;

  const _ChallengeHistorySection({
    required this.runs,
    this.showTitle = true,
    this.onOpenRun,
    this.limit = 8,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shownRuns = limit == null
        ? runs
        : runs.take(limit!).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          Text(
            l10n.challengeHistoryListTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
        ],
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
              template: _challengeTemplateForRun(run),
              onTap: onOpenRun == null ? null : () => onOpenRun!(run),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _ChallengeHistoryOverviewCard extends StatelessWidget {
  final List<ChallengeRun> runs;

  const _ChallengeHistoryOverviewCard({required this.runs});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (runs.isEmpty) {
      return _ChallengeDetailCard(
        child: _ChallengeInlineNotice(
          icon: Icons.history_rounded,
          message: l10n.challengeHistoryEmpty,
        ),
      );
    }
    final latest = runs.first;
    final completed = runs.where((run) => run.isCompleted).length;
    final failed = runs.where((run) => run.isFailed).length;
    final latestTemplate = _challengeTemplateForRun(latest);
    final latestCompletedRounds = _historyCompletedRoundCount(
      latest,
      latestTemplate,
    );
    final latestRoundValue = latestTemplate == null
        ? _runResultLabel(l10n, latest)
        : l10n.challengeRoundCount(
            latestCompletedRounds,
            latestTemplate.dayCount,
          );
    return _ChallengeDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChallengeSectionHeader(title: l10n.challengeHistorySummaryTitle),
          const SizedBox(height: 10),
          _ChallengeInfoGrid(
            items: [
              _ChallengeInfoItem(
                icon: Icons.history_rounded,
                label: l10n.challengeHistorySummaryTotalLabel,
                value: '${runs.length}',
              ),
              _ChallengeInfoItem(
                icon: Icons.check_circle_outline_rounded,
                label: l10n.challengeHistorySummarySuccessLabel,
                value: '$completed/${runs.length}',
              ),
              _ChallengeInfoItem(
                icon: Icons.error_outline_rounded,
                label: l10n.challengeHistoryResultFailed,
                value: '$failed',
              ),
              _ChallengeInfoItem(
                icon: Icons.flag_outlined,
                label: l10n.challengeHistorySummaryLatestLabel,
                value: latestRoundValue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChallengeHistoryTile extends StatelessWidget {
  final ChallengeRun run;
  final String title;
  final ChallengeTemplate? template;
  final VoidCallback? onTap;

  const _ChallengeHistoryTile({
    required this.run,
    required this.title,
    required this.template,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final started = DateFormat.yMMMd(localeName).format(run.startDay);
    final completedRounds = _historyCompletedRoundCount(run, template);
    final roundCount = template == null
        ? ''
        : l10n.challengeRoundCount(completedRounds, template!.dayCount);
    final earnedXp = template == null
        ? 0
        : _historyEarnedXpForRun(run, template!);
    final detailParts = <String>[
      run.isFailed && run.failedRoundNumber != null
          ? l10n.challengeHistoryFailedRound(started, run.failedRoundNumber!)
          : l10n.challengeHistoryStarted(started),
      _runResultLabel(l10n, run),
      if (roundCount.isNotEmpty) roundCount,
    ];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 36,
                child: Center(
                  child: run.isCompleted
                      ? const CheerRinzyMascot(size: 34, progress: 1)
                      : run.isFailed
                      ? const CryingRinzyMascot(size: 34)
                      : Icon(
                          Icons.stop_circle_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                ),
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
                      detailParts.join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _SmallStatusPill(label: l10n.challengeRewardXp(earnedXp)),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeHistoryDetailScreen extends StatelessWidget {
  final ChallengeRun run;

  const _ChallengeHistoryDetailScreen({required this.run});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final template = _challengeTemplateForRun(run);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final start = DateFormat.yMMMd(localeName).format(run.startDay);
    final endDay = run.completedAt == null
        ? run.startDay
        : normalizeDay(run.completedAt!);
    final end = DateFormat.yMMMd(localeName).format(endDay);
    final missionLabels = _challengeSkillLabels(l10n, run.selectedSkillIds);
    final earnedXp = template == null
        ? 0
        : _historyEarnedXpForRun(run, template);
    final completedRoundCount = _historyCompletedRoundCount(run, template);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.challengeHistoryDetailTitle)),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _ChallengeIntroCard(
                title: _templateTitleForRun(l10n, run),
                body: _historyDetailBody(l10n, run),
                progress: run.isCompleted ? 1 : 0,
              ),
              const SizedBox(height: 12),
              _ChallengeDetailCard(
                child: _ChallengeInfoGrid(
                  items: [
                    _ChallengeInfoItem(
                      icon: Icons.flag_outlined,
                      label: l10n.challengeInfoStatusLabel,
                      value: _runResultLabel(l10n, run),
                    ),
                    _ChallengeInfoItem(
                      icon: Icons.date_range_outlined,
                      label: l10n.challengeInfoPeriodLabel,
                      value: l10n.challengeHistoryDetailPeriodValue(start, end),
                    ),
                    _ChallengeInfoItem(
                      icon: Icons.signal_cellular_alt_rounded,
                      label: l10n.challengeInfoLevelLabel,
                      value: _challengeTrainingLevelLabel(
                        l10n,
                        run.trainingLevel,
                      ),
                    ),
                    _ChallengeInfoItem(
                      icon: Icons.sports_soccer,
                      label: l10n.challengeHistoryDetailMissionsLabel,
                      value: missionLabels.isEmpty
                          ? l10n.challengeHistoryDetailNoMissions
                          : missionLabels.join(', '),
                    ),
                    _ChallengeInfoItem(
                      icon: Icons.star_rounded,
                      label: l10n.challengeHistoryDetailEarnedXpLabel,
                      value: l10n.challengeRewardXp(earnedXp),
                    ),
                    if (template != null)
                      _ChallengeInfoItem(
                        icon: Icons.check_circle_outline_rounded,
                        label: l10n.challengeHistoryDetailRoundsTitle,
                        value: l10n.challengeRoundCount(
                          completedRoundCount,
                          template.dayCount,
                        ),
                      ),
                  ],
                ),
              ),
              if (template != null) ...[
                const SizedBox(height: 12),
                _ChallengeRewardBreakdownCard(
                  title: l10n.challengeRewardGuideHistoryTitle,
                  template: template,
                  level: run.trainingLevel,
                ),
                const SizedBox(height: 12),
                _ChallengeDetailCard(
                  child: _ChallengeHistoryRoundList(
                    run: run,
                    template: template,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeHistoryRoundList extends StatelessWidget {
  final ChallengeRun run;
  final ChallengeTemplate template;

  const _ChallengeHistoryRoundList({required this.run, required this.template});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final dateFormatter = DateFormat.MMMd(localeName);
    final config = trainingLevelConfig(run.trainingLevel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.challengeHistoryDetailRoundsTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        for (final round in template.rounds) ...[
          Builder(
            builder: (context) {
              final completed = _historyRoundCompleted(run, round.number);
              final earnedXp = completed
                  ? challengeRoundRewardXpFor(
                      baseRewardXp: config.rewardXpPerRound,
                      consecutiveRoundNumber: round.number,
                    )
                  : 0;
              return _ChallengeHistoryRoundTile(
                label: l10n.challengeHistoryDetailRoundDate(
                  round.number,
                  dateFormatter.format(run.dayForRound(round.number)),
                ),
                status: _historyRoundStatusLabel(l10n, run, round.number),
                reward: l10n.challengeRewardXp(earnedXp),
                completed: completed,
              );
            },
          ),
          if (round != template.rounds.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ChallengeHistoryRoundTile extends StatelessWidget {
  final String label;
  final String status;
  final String reward;
  final bool completed;

  const _ChallengeHistoryRoundTile({
    required this.label,
    required this.status,
    required this.reward,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed
              ? theme.colorScheme.primary.withValues(alpha: 0.34)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 20,
            color: completed
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _SmallStatusPill(label: reward),
        ],
      ),
    );
  }
}

class _ChallengeDetailCard extends StatelessWidget {
  final Widget child;

  const _ChallengeDetailCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _ChallengeSectionHeader extends StatelessWidget {
  final String title;

  const _ChallengeSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ChallengeInlineNotice extends StatelessWidget {
  final IconData icon;
  final String message;

  const _ChallengeInlineNotice({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _ChallengeIntroCard extends StatelessWidget {
  final String title;
  final String body;
  final double progress;

  const _ChallengeIntroCard({
    required this.title,
    required this.body,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 330;
          final mascot = RinzyMascot(
            size: compact ? 116 : 98,
            progress: progress,
          );
          final text = Column(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
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
            ],
          );
          if (compact) {
            return Column(children: [mascot, const SizedBox(height: 12), text]);
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

class _ActiveChallengeSection extends StatelessWidget {
  final ChallengeProgress progress;
  final String templateTitle;
  final bool readOnly;
  final VoidCallback onAbandon;
  final _OpenChallengeTrainingMission onOpenTraining;
  final ValueChanged<ChallengeRoundProgress> onOpenJumpRope;
  final ValueChanged<ChallengeRoundProgress> onOpenLifting;
  final ValueChanged<ChallengeRoundProgress> onOpenMeal;
  final VoidCallback onOpenTrainingPrograms;

  const _ActiveChallengeSection({
    required this.progress,
    required this.templateTitle,
    required this.readOnly,
    required this.onAbandon,
    required this.onOpenTraining,
    required this.onOpenJumpRope,
    required this.onOpenLifting,
    required this.onOpenMeal,
    required this.onOpenTrainingPrograms,
  });

  @override
  Widget build(BuildContext context) {
    final activeRound = progress.activeRound;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (readOnly) ...[
          const _ParentReadOnlyChallengeNotice(),
          const SizedBox(height: 18),
        ],
        _ChallengeRoundsCalendar(
          progress: progress,
          onAbandon: readOnly ? null : onAbandon,
        ),
        const SizedBox(height: 18),
        if (activeRound != null)
          _RoundFocusCard(
            progress: progress,
            round: activeRound,
            readOnly: readOnly,
            onOpenTraining: onOpenTraining,
            onOpenJumpRope: onOpenJumpRope,
            onOpenLifting: onOpenLifting,
            onOpenMeal: onOpenMeal,
            onOpenTrainingPrograms: onOpenTrainingPrograms,
          )
        else
          _CompletedCard(title: templateTitle),
      ],
    );
  }
}

class _RoundFocusCard extends StatelessWidget {
  final ChallengeProgress progress;
  final ChallengeRoundProgress round;
  final bool readOnly;
  final _OpenChallengeTrainingMission onOpenTraining;
  final ValueChanged<ChallengeRoundProgress> onOpenJumpRope;
  final ValueChanged<ChallengeRoundProgress> onOpenLifting;
  final ValueChanged<ChallengeRoundProgress> onOpenMeal;
  final VoidCallback onOpenTrainingPrograms;

  const _RoundFocusCard({
    required this.progress,
    required this.round,
    required this.readOnly,
    required this.onOpenTraining,
    required this.onOpenJumpRope,
    required this.onOpenLifting,
    required this.onOpenMeal,
    required this.onOpenTrainingPrograms,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final title = round.isToday
        ? l10n.challengeTodayRoundTitle(round.round.number)
        : l10n.challengeUpcomingRoundTitle(round.round.number);
    final selectedPrograms = _challengeSkillLabels(
      l10n,
      progress.run.selectedSkillIds,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallStatusPill(
                label: l10n.challengeMissionCount(
                  round.completedMissionCount,
                  round.missionCount,
                ),
              ),
              _SmallStatusPill(
                label: l10n.challengeProgressPercent(
                  (round.missionCompletionRate * 100).round(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ProgressStarGauge(
            progress: round.missionCompletionRate,
            height: 30,
            trackHeight: 8,
            iconSize: 26,
          ),
          if (!round.isToday && !readOnly) ...[
            const SizedBox(height: 12),
            _TrainingProgramLinkCard(
              onOpenTrainingPrograms: onOpenTrainingPrograms,
              compact: true,
            ),
          ],
          if (round.round.targetTrainingMinutes > 0) ...[
            const SizedBox(height: 12),
            if (round.trainingPrograms.isEmpty)
              _MissionProgressRow(
                label: l10n.challengeTrainingProgramMissionLabel,
                subtitle: selectedPrograms.isEmpty
                    ? null
                    : selectedPrograms.join(', '),
                value: _minutesGoalValue(
                  l10n,
                  round.trainingMinutes,
                  round.round.targetTrainingMinutes,
                ),
                progress: _goalProgress(
                  round.trainingMinutes,
                  round.round.targetTrainingMinutes,
                ),
                completed: round.trainingCompleted,
                onTap: readOnly ? null : () => onOpenTraining(round),
              )
            else
              for (final program in round.trainingPrograms) ...[
                _MissionProgressRow(
                  label: program.label,
                  subtitle: l10n.challengeTrainingProgramMissionLabel,
                  value: _minutesGoalValue(
                    l10n,
                    program.currentMinutes,
                    program.targetMinutes,
                  ),
                  progress: program.progressRate,
                  completed: program.completed,
                  onTap: readOnly
                      ? null
                      : () => onOpenTraining(round, program: program),
                ),
                if (program != round.trainingPrograms.last)
                  const SizedBox(height: 10),
              ],
          ],
          if (round.round.targetJumpRopeMinutes > 0) ...[
            const SizedBox(height: 10),
            _MissionProgressRow(
              icon: Icons.sports_gymnastics_rounded,
              label: l10n.challengeJumpRopeLabel,
              value: _minutesGoalValue(
                l10n,
                round.jumpRopeMinutes,
                round.round.targetJumpRopeMinutes,
              ),
              progress: _goalProgress(
                round.jumpRopeMinutes,
                round.round.targetJumpRopeMinutes,
              ),
              completed: round.jumpRopeCompleted,
              onTap: readOnly ? null : () => onOpenJumpRope(round),
            ),
          ],
          if (round.round.targetLiftingMinutes > 0) ...[
            const SizedBox(height: 10),
            _MissionProgressRow(
              icon: Icons.sports_soccer,
              label: l10n.challengeLiftingLabel,
              value: _minutesGoalValue(
                l10n,
                round.liftingMinutes,
                round.round.targetLiftingMinutes,
              ),
              progress: _goalProgress(
                round.liftingMinutes,
                round.round.targetLiftingMinutes,
              ),
              completed: round.liftingCompleted,
              onTap: readOnly ? null : () => onOpenLifting(round),
            ),
          ],
          if (round.round.targetRiceBowls > 0) ...[
            const SizedBox(height: 10),
            _MissionProgressRow(
              icon: Icons.rice_bowl_outlined,
              label: l10n.challengeMealLabel,
              value: l10n.challengeMealGoalValue(
                _formatBowls(round.riceBowls),
                _formatBowls(round.round.targetRiceBowls),
              ),
              progress: _goalProgress(
                round.riceBowls,
                round.round.targetRiceBowls,
              ),
              completed: round.mealCompleted,
              onTap: readOnly ? null : () => onOpenMeal(round),
            ),
          ],
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

class _ChallengeInfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _ChallengeInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _ChallengeInfoGrid extends StatelessWidget {
  final List<_ChallengeInfoItem> items;

  const _ChallengeInfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 640 ? 4 : 2;
        const spacing = 8.0;
        final width =
            (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _ChallengeInfoTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _ChallengeInfoTile extends StatelessWidget {
  final _ChallengeInfoItem item;

  const _ChallengeInfoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
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

class _ChallengeRoundsCalendar extends StatelessWidget {
  final ChallengeProgress progress;
  final VoidCallback? onAbandon;

  const _ChallengeRoundsCalendar({
    required this.progress,
    required this.onAbandon,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rounds = progress.rounds;
    if (rounds.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      key: const ValueKey('challenge-rounds-calendar'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.07),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.challengeRoundsTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (onAbandon != null)
                TextButton.icon(
                  onPressed: onAbandon,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: Text(l10n.challengeAbandonAction),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallStatusPill(
                label: l10n.challengeRoundCount(
                  progress.completedRoundCount,
                  progress.totalRoundCount,
                ),
              ),
              _SmallStatusPill(
                label: l10n.challengeProgressPercent(
                  (progress.completionRate * 100).round(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ProgressStarGauge(
            progress: progress.completionRate,
            height: 30,
            trackHeight: 8,
            iconSize: 26,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
              final crossAxisCount = _challengeRoundColumnCount(
                compact: compact,
              );
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rounds.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: compact ? 8 : 10,
                  mainAxisSpacing: compact ? 8 : 10,
                  childAspectRatio: _challengeRoundAspectRatio(
                    compact: compact,
                  ),
                ),
                itemBuilder: (context, index) {
                  return _ChallengeRoundCalendarCell(round: rounds[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

int _challengeRoundColumnCount({required bool compact}) {
  return compact ? 4 : DateTime.daysPerWeek;
}

double _challengeRoundAspectRatio({required bool compact}) {
  return compact ? 0.84 : 0.82;
}

class _ChallengeRoundCalendarCell extends StatelessWidget {
  final ChallengeRoundProgress round;

  const _ChallengeRoundCalendarCell({required this.round});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final completed = round.completed;
    final missed = round.isMissed;
    final bgColor = completed
        ? scheme.primaryContainer.withValues(alpha: 0.68)
        : missed
        ? scheme.errorContainer.withValues(alpha: 0.62)
        : round.isToday
        ? scheme.secondaryContainer.withValues(alpha: 0.56)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.62);
    final borderColor = completed
        ? scheme.primary.withValues(alpha: 0.62)
        : missed
        ? scheme.error.withValues(alpha: 0.60)
        : round.isToday
        ? scheme.secondary.withValues(alpha: 0.54)
        : scheme.outline.withValues(alpha: 0.32);
    final foreground = completed
        ? scheme.onPrimaryContainer
        : missed
        ? scheme.onErrorContainer
        : round.isToday
        ? scheme.onSecondaryContainer
        : scheme.onSurfaceVariant;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final weekday = DateFormat.E(localeName).format(round.date);

    return Semantics(
      label:
          '${l10n.challengeRoundTitle(round.round.number)}, '
          '${_roundSubtitle(context, round)}',
      child: AnimatedContainer(
        key: ValueKey('challenge-calendar-round-${round.round.number}'),
        duration: AppMotion.base(context),
        curve: AppMotion.curveEnter,
        padding: EdgeInsets.all(completed || missed ? 2 : 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: completed || missed ? 1.6 : 1,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shortestSide = constraints.biggest.shortestSide;
            final mascotSize = completed || missed
                ? (shortestSide * 0.96).clamp(30.0, 96.0)
                : (shortestSide * 0.62).clamp(26.0, 52.0);
            if (completed) {
              return Center(
                child: _RoundCalendarRinzyCelebration(size: mascotSize),
              );
            }
            if (missed || round.isToday) {
              return Center(
                child: _RoundCalendarRinzyStatus(
                  round: round,
                  size: mascotSize,
                  failed: missed,
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        weekday,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: foreground.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                    Text(
                      '${round.date.day}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: foreground.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: Icon(
                      Icons.radio_button_unchecked,
                      color: foreground,
                      size: mascotSize * 0.72,
                    ),
                  ),
                ),
                Text(
                  'R${round.round.number}',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.clip,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RoundCalendarRinzyStatus extends StatelessWidget {
  final ChallengeRoundProgress round;
  final double size;
  final bool failed;

  const _RoundCalendarRinzyStatus({
    required this.round,
    required this.size,
    required this.failed,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotion(context);
    final progress = round.missionCompletionRate;
    if (failed) {
      return SizedBox.square(
        dimension: size,
        child: CryingRinzyMascot(size: size, animate: !reduceMotion),
      );
    }
    return SizedBox.square(
      dimension: size,
      child: RinzyMascot(
        size: size,
        progress: progress,
        animate: !reduceMotion,
      ),
    );
  }
}

class _RoundCalendarRinzyCelebration extends StatelessWidget {
  final double size;

  const _RoundCalendarRinzyCelebration({required this.size});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotion(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.92, end: 1),
      duration: AppMotion.slow(context),
      curve: AppMotion.curveEmphasis,
      builder: (context, scale, child) {
        return Transform.scale(scale: reduceMotion ? 1 : scale, child: child);
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            CheerRinzyMascot(size: size, progress: 1, animate: !reduceMotion),
          ],
        ),
      ),
    );
  }
}

class _MissionProgressRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String? subtitle;
  final String value;
  final double progress;
  final bool completed;
  final VoidCallback? onTap;

  const _MissionProgressRow({
    this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.progress,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = completed
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final ratio = progress.clamp(0, 1).toDouble();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: completed
                  ? theme.colorScheme.primary.withValues(alpha: 0.34)
                  : theme.colorScheme.outline.withValues(alpha: 0.20),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (subtitle?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 0,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    completed
                        ? Icons.check_circle_rounded
                        : onTap == null
                        ? Icons.visibility_outlined
                        : Icons.chevron_right_rounded,
                    color: color,
                    size: completed ? 18 : 20,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ProgressStarGauge(
                progress: ratio,
                height: 24,
                trackHeight: 8,
                iconSize: 22,
              ),
            ],
          ),
        ),
      ),
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

class _ChallengeFailureScreen extends StatelessWidget {
  final int gainedXp;

  const _ChallengeFailureScreen({required this.gainedXp});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
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
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CryingRinzyMascot(
                            size: MediaQuery.sizeOf(
                              context,
                            ).shortestSide.clamp(150, 220).toDouble(),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.challengeFailureSimpleTitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.challengeFailureBody,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                          if (gainedXp > 0) ...[
                            const SizedBox(height: 20),
                            _SmallStatusPill(
                              label: l10n.challengeRewardXp(gainedXp),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(l10n.challengeFailureAction),
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

class _ChallengeCelebrationScreen extends StatelessWidget {
  final int gainedXp;
  final int awardedRoundCount;
  final bool challengeCompleted;
  final int roundGainedXp;
  final int completionGainedXp;

  const _ChallengeCelebrationScreen({
    required this.gainedXp,
    required this.awardedRoundCount,
    required this.challengeCompleted,
    required this.roundGainedXp,
    required this.completionGainedXp,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final title = challengeCompleted
        ? l10n.challengeCelebrationCompleteTitle
        : l10n.challengeCelebrationTitle;
    final body = challengeCompleted
        ? (gainedXp > 0
              ? l10n.challengeCelebrationCompleteBody(gainedXp)
              : l10n.challengeCelebrationCompleteBodyNoXp)
        : l10n.challengeCelebrationBody(awardedRoundCount, gainedXp);
    final mascotSize = MediaQuery.sizeOf(
      context,
    ).shortestSide.clamp(154, 220).toDouble();
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.58),
              theme.colorScheme.surface,
              theme.colorScheme.secondaryContainer.withValues(alpha: 0.42),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
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
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(
                            alpha: 0.9,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.56,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              blurRadius: 28,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CheerRinzyMascot(size: mascotSize, progress: 1),
                            const SizedBox(height: 18),
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
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                            if (gainedXp > 0) ...[
                              const SizedBox(height: 18),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (challengeCompleted && roundGainedXp > 0)
                                    _SmallStatusPill(
                                      label: l10n.challengeRoundXpLabel(
                                        roundGainedXp,
                                      ),
                                    ),
                                  if (challengeCompleted &&
                                      completionGainedXp > 0)
                                    _SmallStatusPill(
                                      label: l10n.challengeCompletionBonusLabel(
                                        completionGainedXp,
                                      ),
                                    ),
                                  _SmallStatusPill(
                                    label: l10n.challengeRewardXp(gainedXp),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
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

String _minutesGoalValue(AppLocalizations l10n, int current, int target) {
  return l10n.challengeTrainingGoalValue(current, target);
}

double _goalProgress(num current, num target) {
  if (target <= 0) return 1;
  return (current / target).clamp(0, 1).toDouble();
}

String _runResultLabel(AppLocalizations l10n, ChallengeRun run) {
  if (run.isCompleted) return l10n.challengeHistoryResultCompleted;
  if (run.isFailed) return l10n.challengeHistoryResultFailed;
  if (run.isAbandoned) return l10n.challengeHistoryResultAbandoned;
  return l10n.challengeHistoryResultInProgress;
}

String _templateTitleForRun(AppLocalizations l10n, ChallengeRun run) {
  return switch (run.templateId) {
    'starter_3' => l10n.challengeTemplateStarterTitle,
    'weekly_7' => l10n.challengeTemplateWeeklyTitle,
    'focus_14' => l10n.challengeTemplateFocusTitle,
    _ => l10n.challengeTitle,
  };
}

ChallengeTemplate? _challengeTemplateForRun(ChallengeRun run) {
  for (final template in defaultChallengeTemplates) {
    if (template.id == run.templateId) return template;
  }
  return null;
}

String _challengeTrainingLevelLabel(
  AppLocalizations l10n,
  ChallengeTrainingLevel level,
) {
  return switch (level) {
    ChallengeTrainingLevel.rookie => l10n.challengeTrainingLevelRookieTitle,
    ChallengeTrainingLevel.growth => l10n.challengeTrainingLevelGrowthTitle,
    ChallengeTrainingLevel.ace => l10n.challengeTrainingLevelAceTitle,
  };
}

String _historyDetailBody(AppLocalizations l10n, ChallengeRun run) {
  if (run.isCompleted) return l10n.challengeHistoryDetailCompletedBody;
  if (run.isFailed) {
    return l10n.challengeHistoryDetailFailedBody(run.failedRoundNumber ?? 1);
  }
  if (run.isAbandoned) return l10n.challengeHistoryDetailAbandonedBody;
  return l10n.challengeHistoryResultInProgress;
}

String _historyRoundStatusLabel(
  AppLocalizations l10n,
  ChallengeRun run,
  int roundNumber,
) {
  if (_historyRoundCompleted(run, roundNumber)) {
    return l10n.challengeHistoryDetailRoundCompleted;
  }
  if (run.isFailed && run.failedRoundNumber == roundNumber) {
    return l10n.challengeHistoryDetailRoundFailed;
  }
  if (run.isAbandoned || run.isFailed) {
    return l10n.challengeHistoryDetailRoundEnded;
  }
  return l10n.challengePendingBadge;
}

bool _historyRoundCompleted(ChallengeRun run, int roundNumber) {
  if (run.isCompleted) return true;
  if (!run.isFailed) return false;
  final failedRound = run.failedRoundNumber;
  return failedRound != null && roundNumber < failedRound;
}

int _historyCompletedRoundCount(ChallengeRun run, ChallengeTemplate? template) {
  if (template == null) return 0;
  if (run.isCompleted) return template.dayCount;
  if (run.isFailed && run.failedRoundNumber != null) {
    return (run.failedRoundNumber! - 1).clamp(0, template.dayCount).toInt();
  }
  return 0;
}

int _historyEarnedXpForRun(ChallengeRun run, ChallengeTemplate template) {
  final completedRoundCount = _historyCompletedRoundCount(run, template);
  if (completedRoundCount <= 0 && !run.isCompleted) return 0;
  final config = trainingLevelConfig(run.trainingLevel);
  var total = 0;
  for (var roundNumber = 1; roundNumber <= completedRoundCount; roundNumber++) {
    total += challengeRoundRewardXpFor(
      baseRewardXp: config.rewardXpPerRound,
      consecutiveRoundNumber: roundNumber,
    );
  }
  if (run.isCompleted) {
    total += challengeCompletionBonusXpFor(template, run.trainingLevel);
  }
  return total;
}

int _challengeEarnedRoundXp(ChallengeProgress progress) {
  var total = 0;
  var consecutiveRoundNumber = 0;
  for (final round in progress.rounds) {
    if (!round.completed) {
      consecutiveRoundNumber = 0;
      continue;
    }
    consecutiveRoundNumber += 1;
    total += challengeRoundRewardXpFor(
      baseRewardXp: round.round.rewardXp,
      consecutiveRoundNumber: consecutiveRoundNumber,
    );
  }
  return total;
}

bool _progressRoundCompleted(ChallengeProgress? progress, int roundNumber) {
  if (progress == null) return false;
  for (final round in progress.rounds) {
    if (round.round.number == roundNumber) return round.completed;
  }
  return false;
}

Color _challengeTemplateAccent(String templateId) {
  return switch (templateId) {
    'starter_3' => const Color(0xFF2A9D8F),
    'weekly_7' => const Color(0xFFE76F51),
    'focus_14' => const Color(0xFF5B6CFF),
    _ => const Color(0xFF256D85),
  };
}

List<_ChallengeSkillOption> _challengeProgramSkillOptions(
  AppLocalizations l10n,
  OptionRepository optionRepository,
) {
  final defaults = <String>[
    l10n.defaultProgram1,
    l10n.defaultProgram2,
    l10n.defaultProgram3,
    l10n.defaultProgram4,
  ];
  final stored = optionRepository.getOptions('programs', defaults);
  final normalized = LocalizedOptionDefaults.normalizeOptions(
    key: 'programs',
    stored: stored,
    localizedDefaults: defaults,
  );
  if (!_sameStringList(stored, normalized)) {
    unawaited(optionRepository.saveOptions('programs', normalized));
  }
  final seen = <String>{};
  final programs = <String>[];
  for (final program in normalized) {
    final trimmed = program.trim();
    if (trimmed.isEmpty || seen.contains(trimmed)) continue;
    seen.add(trimmed);
    programs.add(trimmed);
  }
  final colors = <Color>[
    const Color(0xFF256D85),
    const Color(0xFF2A9D8F),
    const Color(0xFFE76F51),
    const Color(0xFFE9A23B),
    const Color(0xFF5B6CFF),
    const Color(0xFF4C956C),
  ];
  return <_ChallengeSkillOption>[
    for (var index = 0; index < programs.length; index++)
      _ChallengeSkillOption(
        id: programs[index],
        label: programs[index],
        color: colors[index % colors.length],
      ),
  ];
}

bool _sameChallengeSkillOptions(
  List<_ChallengeSkillOption> a,
  List<_ChallengeSkillOption> b,
) {
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index].id != b[index].id) return false;
  }
  return true;
}

bool _sameStringList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}

List<_ChallengeSkillOption> _legacyChallengeSkillOptions(
  AppLocalizations l10n,
) {
  return <_ChallengeSkillOption>[
    _ChallengeSkillOption(
      id: 'dribble',
      label: l10n.challengeSkillDribble,
      color: const Color(0xFF256D85),
    ),
    _ChallengeSkillOption(
      id: 'speedRun',
      label: l10n.challengeSkillSpeedRun,
      color: const Color(0xFFE76F51),
    ),
    _ChallengeSkillOption(
      id: 'jumpRope',
      label: l10n.challengeSkillJumpRope,
      color: const Color(0xFF5B6CFF),
    ),
    _ChallengeSkillOption(
      id: 'lifting',
      label: l10n.challengeSkillLifting,
      color: const Color(0xFFE9A23B),
    ),
    _ChallengeSkillOption(
      id: 'passing',
      label: l10n.challengeSkillPassing,
      color: const Color(0xFF2F80ED),
    ),
    _ChallengeSkillOption(
      id: 'shooting',
      label: l10n.challengeSkillShooting,
      color: const Color(0xFF40B85A),
    ),
    _ChallengeSkillOption(
      id: 'firstTouch',
      label: l10n.challengeSkillFirstTouch,
      color: const Color(0xFFEC4899),
    ),
    _ChallengeSkillOption(
      id: 'defense',
      label: l10n.challengeSkillDefense,
      color: const Color(0xFF64748B),
    ),
  ];
}

List<String> _challengeSkillLabels(
  AppLocalizations l10n,
  Iterable<String> selectedSkillIds,
) {
  final optionsById = {
    for (final option in _legacyChallengeSkillOptions(l10n))
      option.id: option.label,
  };
  return normalizeChallengeSkillIds(
    selectedSkillIds,
  ).map((id) => optionsById[id] ?? id).toList(growable: false);
}

class _ChallengeSkillOption {
  final String id;
  final String label;
  final Color color;

  const _ChallengeSkillOption({
    required this.id,
    required this.label,
    required this.color,
  });
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
