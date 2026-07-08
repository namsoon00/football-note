import 'dart:async';

import 'package:flutter/material.dart';
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
import '../../application/sport_capabilities.dart';
import '../../application/sport_defaults.dart';
import '../../application/sport_service.dart';
import '../../application/training_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/sport_definition.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../utils/app_sound_effects.dart';
import '../utils/sport_conditioning_visuals.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/app_background.dart';
import '../widgets/app_page_route.dart';
import '../widgets/progress_star_gauge.dart';
import '../widgets/rinzy_mascot.dart';
import 'entry_form_screen.dart';
import 'meal_log_screen.dart';
import 'settings_screen.dart';

typedef _OpenChallengeTrainingMission = Future<void> Function(
  ChallengeProgress progress,
  ChallengeRoundProgress round, {
  ChallengeTrainingProgramProgress? program,
});

typedef _OpenChallengeMission = Future<void> Function(
  ChallengeProgress progress,
  ChallengeRoundProgress round,
);

enum _ChallengeScreenMode { list, create, detail, edit }

class ChallengeScreen extends StatefulWidget {
  final TrainingService trainingService;
  final MealLogService mealLogService;
  final OptionRepository optionRepository;
  final LocaleService localeService;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final String? initialRunId;
  final int? initialRoundNumber;

  const ChallengeScreen({
    super.key,
    required this.trainingService,
    required this.mealLogService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
    this.driveBackupService,
    this.initialRunId,
    this.initialRoundNumber,
  });

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  late final ChallengeService _challengeService;
  late final SettingsService _settingsService;
  late final TrainingPlanReminderService _reminderService;
  bool _prepareChallengeInFlight = false;
  bool _startPreparedChallengeInFlight = false;
  bool _updateChallengeInFlight = false;
  bool _finalizeInFlight = false;
  bool _roundAwardInFlight = false;
  bool _reminderSyncInFlight = false;
  final Map<String, String> _lastFinalizeSignatures = <String, String>{};
  final Map<String, String> _lastRoundAwardSignatures = <String, String>{};
  String? _lastReminderSignature;
  final Set<String> _pendingFinalizeSignatures = <String>{};
  final Set<String> _pendingRoundAwardSignatures = <String>{};
  _ChallengeScreenMode _mode = _ChallengeScreenMode.list;
  String? _selectedRunId;
  int? _focusedRoundNumber;

  @override
  void initState() {
    super.initState();
    _challengeService = ChallengeService(widget.optionRepository);
    _settingsService = widget.settingsService;
    _reminderService = TrainingPlanReminderService(
      widget.optionRepository,
      _settingsService,
    );
    final initialRunId = widget.initialRunId?.trim();
    if (initialRunId != null && initialRunId.isNotEmpty) {
      _mode = _ChallengeScreenMode.detail;
      _selectedRunId = initialRunId;
      _focusedRoundNumber = widget.initialRoundNumber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isParentReadOnlyMode = _isParentReadOnlyMode;
    final canRunChallengeSideEffects =
        !isParentReadOnlyMode && (ModalRoute.of(context)?.isCurrent ?? true);
    final challengeTrainingRange = _activeChallengeTrainingRange();
    final challengeTrainingRangeSignature = challengeTrainingRange == null
        ? 'none'
        : '${challengeTrainingRange.start.millisecondsSinceEpoch}-'
            '${challengeTrainingRange.end.millisecondsSinceEpoch}';
    return Scaffold(
      appBar: AppBar(
        leading: _mode == _ChallengeScreenMode.list
            ? null
            : IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: _showChallengeList,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        title: Text(_challengeScreenTitle(l10n)),
        actions: [
          AppBarActionButton.label(
            onPressed: _openRewardGuide,
            tooltip: l10n.challengeRewardAction,
            icon: const Icon(Icons.workspace_premium_outlined),
            label: l10n.challengeRewardAction,
            maxLabelWidth: 84,
          ),
          AppBarActionButton.label(
            onPressed: _openHistory,
            tooltip: l10n.challengeHistoryAction,
            icon: const Icon(Icons.history),
            label: l10n.challengeHistoryAction,
            maxLabelWidth: 84,
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<List<TrainingEntry>>(
            key: ValueKey(
              'challenge-training-entries-$challengeTrainingRangeSignature',
            ),
            stream: _watchChallengeTrainingEntries(challengeTrainingRange),
            builder: (context, trainingSnapshot) {
              final sportId =
                  SportService(widget.optionRepository).currentSportId();
              final trainingEntries = filterEntriesForSport(
                trainingSnapshot.data ?? const <TrainingEntry>[],
                sportId,
              ).where((entry) => !entry.isMatch).toList(growable: false);
              return StreamBuilder<List<MealEntry>>(
                stream: widget.mealLogService.watchEntries(),
                builder: (context, mealSnapshot) {
                  final mealEntries = widget.mealLogService.mergedEntries(
                    directEntries: mealSnapshot.data ?? const <MealEntry>[],
                    legacyEntries: trainingEntries,
                  );
                  final progresses = _challengeService.activeProgresses(
                    trainingEntries: trainingEntries,
                    mealEntries: mealEntries,
                  );
                  if (canRunChallengeSideEffects) {
                    for (final progress in progresses) {
                      _scheduleRoundAwardSync(progress);
                      _scheduleFinalizeSync(progress);
                    }
                  }
                  if (canRunChallengeSideEffects) {
                    _scheduleChallengeReminderSync(progresses);
                  }
                  final skillOptions = _challengeProgramSkillOptions(
                    l10n,
                    widget.optionRepository,
                  );
                  final latestCompletedRun =
                      _challengeService.latestCompletedRun();
                  final latestCompletedTemplate = latestCompletedRun == null
                      ? null
                      : _challengeService.templateById(
                          latestCompletedRun.templateId,
                        );
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: _challengeBodyWidgets(
                      l10n: l10n,
                      sportId: sportId,
                      progresses: progresses,
                      latestCompletedRun: latestCompletedRun,
                      latestCompletedTemplate: latestCompletedTemplate,
                      skillOptions: skillOptions,
                      readOnly: isParentReadOnlyMode,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _challengeScreenTitle(AppLocalizations l10n) {
    return switch (_mode) {
      _ChallengeScreenMode.list => l10n.challengeListTitle,
      _ChallengeScreenMode.create => l10n.challengeCreateTitle,
      _ChallengeScreenMode.detail => l10n.challengeDetailTitle,
      _ChallengeScreenMode.edit => l10n.challengeEditTitle,
    };
  }

  List<Widget> _challengeBodyWidgets({
    required AppLocalizations l10n,
    required String sportId,
    required List<ChallengeProgress> progresses,
    required ChallengeRun? latestCompletedRun,
    required ChallengeTemplate? latestCompletedTemplate,
    required List<_ChallengeSkillOption> skillOptions,
    required bool readOnly,
  }) {
    final selectedProgress = _selectedProgress(progresses);
    if (_mode == _ChallengeScreenMode.create) {
      return [
        _ChallengeStartSection(
          sportId: sportId,
          templates: _challengeService.templates(),
          templateTitle: (template) => _templateTitle(l10n, template),
          templateDescription: (template) =>
              _templateDescription(l10n, template),
          latestCompletedRun: latestCompletedRun,
          latestCompletedTemplate: latestCompletedTemplate,
          skillOptions: skillOptions,
          canEditRewardGift: readOnly,
          onOpenTrainingPrograms: _openTrainingProgramSetup,
          onStart: _prepareChallenge,
          submitLabel: l10n.challengePrepareAction,
          submitIcon: Icons.checklist_rounded,
        ),
      ];
    }
    if (_mode == _ChallengeScreenMode.edit && selectedProgress != null) {
      return [
        _ChallengeStartSection(
          sportId: sportId,
          templates: _challengeService.templates(),
          templateTitle: (template) => _templateTitle(l10n, template),
          templateDescription: (template) =>
              _templateDescription(l10n, template),
          latestCompletedRun: null,
          latestCompletedTemplate: null,
          initialRun: selectedProgress.run,
          initialTemplate: selectedProgress.template,
          skillOptions: skillOptions,
          canEditRewardGift: readOnly,
          onOpenTrainingPrograms: _openTrainingProgramSetup,
          onStart: (
            template,
            selectedSkillIds,
            missionTargets,
            cadenceDays,
            rewardGift,
          ) =>
              _updateChallenge(
            selectedProgress.run.id,
            template,
            selectedSkillIds,
            missionTargets,
            cadenceDays,
            rewardGift,
          ),
          onAutoSave: (
            template,
            selectedSkillIds,
            missionTargets,
            cadenceDays,
            rewardGift,
          ) =>
              _updateChallenge(
            selectedProgress.run.id,
            template,
            selectedSkillIds,
            missionTargets,
            cadenceDays,
            rewardGift,
            showFeedback: false,
            stayInEdit: true,
          ),
          submitLabel: l10n.challengeUpdateAction,
          submitIcon: Icons.check_rounded,
        ),
      ];
    }
    if (_mode == _ChallengeScreenMode.detail && selectedProgress != null) {
      return [
        _ChallengeDetailActions(
          onEdit: _canEditPendingChallenge(selectedProgress)
              ? () => _showChallengeEdit(selectedProgress)
              : null,
          onDelete: _canDeleteParentPendingChallenge(selectedProgress)
              ? () => _confirmDeleteParentPendingChallenge(selectedProgress)
              : null,
        ),
        const SizedBox(height: 12),
        _ActiveChallengeSection(
          sportId: sportId,
          progress: selectedProgress,
          templateTitle: _templateTitle(l10n, selectedProgress.template),
          readOnly: readOnly,
          onAbandon: () => _confirmAbandon(selectedProgress),
          onOpenTraining: _openTrainingMission,
          onOpenJumpRope: _openJumpRopeMission,
          onOpenLifting: _openLiftingMission,
          onOpenMeal: _openMealMission,
          onOpenTrainingPrograms: _openTrainingProgramSetup,
          onStartPrepared: () => _startPreparedChallenge(selectedProgress),
          focusRoundNumber: _focusedRoundNumber,
        ),
      ];
    }
    return _challengeListWidgets(
      l10n: l10n,
      progresses: progresses,
      latestCompletedRun: latestCompletedRun,
      latestCompletedTemplate: latestCompletedTemplate,
      readOnly: readOnly,
    );
  }

  List<Widget> _challengeListWidgets({
    required AppLocalizations l10n,
    required List<ChallengeProgress> progresses,
    required ChallengeRun? latestCompletedRun,
    required ChallengeTemplate? latestCompletedTemplate,
    required bool readOnly,
  }) {
    final widgets = <Widget>[];
    if (progresses.isEmpty) {
      if (latestCompletedRun != null && latestCompletedTemplate != null) {
        widgets.add(
          _ChallengeFinishedPraiseCard(
            run: latestCompletedRun,
            template: latestCompletedTemplate,
            templateTitle: _templateTitle(l10n, latestCompletedTemplate),
          ),
        );
        widgets.add(const SizedBox(height: 18));
      } else {
        widgets.add(
          _ChallengeIntroCard(
            title: l10n.challengeStartHeroTitle,
            body: l10n.challengeStartHeroBody,
            progress: 0,
          ),
        );
        widgets.add(const SizedBox(height: 18));
      }
      if (readOnly) {
        widgets.add(const _ParentReadOnlyChallengeNotice());
        widgets.add(const SizedBox(height: 14));
      }
      widgets.add(
        FilledButton.icon(
          key: const ValueKey('challenge-create-button'),
          onPressed: _showChallengeCreate,
          icon: const Icon(Icons.add_task_rounded),
          label: Text(l10n.challengeCreateAction),
        ),
      );
      return widgets;
    }
    if (readOnly) {
      widgets.add(const _ParentReadOnlyChallengeNotice());
      widgets.add(const SizedBox(height: 14));
    }
    widgets.add(_ChallengeListHeader(count: progresses.length));
    widgets.add(const SizedBox(height: 12));
    for (final progress in progresses) {
      final canEdit = _canEditPendingChallenge(progress);
      widgets.add(
        _ChallengeListCard(
          progress: progress,
          templateTitle: _templateTitle(l10n, progress.template),
          readOnly: !canEdit,
          onOpen: () => _showChallengeDetail(progress),
          onEdit: () => _showChallengeEdit(progress),
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }
    widgets.add(const SizedBox(height: 8));
    widgets.add(
      OutlinedButton.icon(
        key: const ValueKey('challenge-create-button'),
        onPressed: _showChallengeCreate,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.challengeCreateAnotherTitle),
      ),
    );
    return widgets;
  }

  ChallengeProgress? _selectedProgress(List<ChallengeProgress> progresses) {
    final selectedRunId = _selectedRunId;
    if (selectedRunId == null) return null;
    for (final progress in progresses) {
      if (progress.run.id == selectedRunId) return progress;
    }
    return null;
  }

  void _showChallengeList() {
    setState(() {
      _mode = _ChallengeScreenMode.list;
      _selectedRunId = null;
      _focusedRoundNumber = null;
    });
  }

  void _showChallengeCreate() {
    setState(() {
      _mode = _ChallengeScreenMode.create;
      _selectedRunId = null;
      _focusedRoundNumber = null;
    });
  }

  void _showChallengeDetail(ChallengeProgress progress) {
    setState(() {
      _mode = _ChallengeScreenMode.detail;
      _selectedRunId = progress.run.id;
      _focusedRoundNumber = null;
    });
  }

  void _showChallengeEdit(ChallengeProgress progress) {
    if (!_canEditPendingChallenge(progress)) {
      _showChallengeTopSnackBar(
        AppLocalizations.of(context)!.challengeEditUnavailableSnack,
      );
      return;
    }
    setState(() {
      _mode = _ChallengeScreenMode.edit;
      _selectedRunId = progress.run.id;
      _focusedRoundNumber = null;
    });
  }

  void _scheduleFinalizeSync(ChallengeProgress progress) {
    if (!progress.readyToFinalize()) return;
    final signature = _finalizationSignature(progress);
    if (_finalizeInFlight ||
        _pendingFinalizeSignatures.contains(signature) ||
        _lastFinalizeSignatures[progress.run.id] == signature) {
      return;
    }
    _pendingFinalizeSignatures.add(signature);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _pendingFinalizeSignatures.remove(signature);
        return;
      }
      unawaited(_runScheduledFinalization(progress, signature));
    });
  }

  void _scheduleRoundAwardSync(ChallengeProgress progress) {
    if (progress.readyToFinalize()) return;
    final signature = _roundAwardSignature(progress);
    if (_roundAwardInFlight ||
        _pendingRoundAwardSignatures.contains(signature) ||
        _lastRoundAwardSignatures[progress.run.id] == signature) {
      return;
    }
    _pendingRoundAwardSignatures.add(signature);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _pendingRoundAwardSignatures.remove(signature);
        return;
      }
      unawaited(_runScheduledRoundAwardSync(progress, signature));
    });
  }

  Future<void> _runScheduledFinalization(
    ChallengeProgress progress,
    String signature,
  ) async {
    try {
      if (!_pendingFinalizeSignatures.contains(signature) ||
          _lastFinalizeSignatures[progress.run.id] == signature) {
        return;
      }
      await _syncFinalization(progress, signature, presentResult: false);
    } finally {
      _pendingFinalizeSignatures.remove(signature);
    }
  }

  Future<void> _runScheduledRoundAwardSync(
    ChallengeProgress progress,
    String signature,
  ) async {
    try {
      if (!_pendingRoundAwardSignatures.contains(signature) ||
          _lastRoundAwardSignatures[progress.run.id] == signature) {
        return;
      }
      final completedRounds = _completedRoundNumbersToken(progress);
      if (completedRounds.isEmpty) {
        await _syncRoundAwardRevocations(progress, signature);
      } else {
        await _syncRoundAwards(progress, signature, presentResult: false);
      }
    } finally {
      _pendingRoundAwardSignatures.remove(signature);
    }
  }

  String _roundAwardSignature(ChallengeProgress progress) {
    final completedRounds = _completedRoundNumbersToken(progress);
    return completedRounds.isEmpty
        ? '${progress.run.id}:rounds:none'
        : '${progress.run.id}:rounds:$completedRounds';
  }

  String _completedRoundNumbersToken(ChallengeProgress progress) {
    return progress.rounds
        .where((round) => round.completed)
        .map((round) => round.round.number)
        .join(',');
  }

  Future<void> _syncRoundAwardRevocations(
    ChallengeProgress progress,
    String signature,
  ) async {
    if (_roundAwardInFlight) return;
    _roundAwardInFlight = true;
    try {
      await _challengeService.revokeIncompleteAwards(
        progress: progress,
        playerLevelService: PlayerLevelService(
          widget.optionRepository,
          sportId: SportService(widget.optionRepository).currentSportId(),
        ),
      );
      if (!mounted) return;
      setState(() {});
    } finally {
      _roundAwardInFlight = false;
      _lastRoundAwardSignatures[progress.run.id] = signature;
    }
  }

  Future<void> _syncRoundAwards(
    ChallengeProgress progress,
    String signature, {
    required bool presentResult,
  }) async {
    if (_roundAwardInFlight) return;
    _roundAwardInFlight = true;
    try {
      final awards = await _challengeService.awardCompletedRounds(
        progress: progress,
        playerLevelService: PlayerLevelService(
          widget.optionRepository,
          sportId: SportService(widget.optionRepository).currentSportId(),
        ),
      );
      final gainedXp = awards.fold<int>(
        0,
        (sum, award) => sum + award.gainedXp,
      );
      if (!mounted) return;
      if (!presentResult) {
        setState(() {});
        return;
      }
      _playChallengeSuccessFeedback();
      final newlyAwardedRoundCount = awards
          .where((award) => award.reasons.contains('challenge_round_completed'))
          .length;
      final awardedRoundCount = newlyAwardedRoundCount > 0
          ? newlyAwardedRoundCount.clamp(1, progress.rounds.length).toInt()
          : progress.completedRoundCount
              .clamp(1, progress.rounds.length)
              .toInt();
      final l10n = AppLocalizations.of(context)!;
      await Navigator.of(context).push(
        AppPageRoute<void>(
          builder: (_) => _ChallengeCelebrationScreen(
            gainedXp: gainedXp,
            awardedRoundCount: awardedRoundCount,
            challengeCompleted: false,
            rewardGift: progress.run.rewardGift,
            roundGainedXp: gainedXp,
            completionGainedXp: 0,
            missionSummaries: _completedMissionSummariesForRounds(
              l10n,
              SportService(widget.optionRepository).currentSportId(),
              progress.rounds.where((round) => round.completed),
            ),
          ),
        ),
      );
      if (!mounted) return;
      setState(() {});
    } finally {
      _roundAwardInFlight = false;
      _lastRoundAwardSignatures[progress.run.id] = signature;
    }
  }

  void _scheduleChallengeReminderSync(List<ChallengeProgress> progresses) {
    final signature = progresses.isEmpty
        ? 'none'
        : progresses
            .map(
              (progress) => '${progress.run.id}:'
                  '${progress.rounds.where((round) => round.completed).map((round) => round.round.number).join(',')}:'
                  '${progress.rounds.length}',
            )
            .join('|');
    if (_reminderSyncInFlight || _lastReminderSignature == signature) return;
    _lastReminderSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_syncChallengeReminders(progresses, signature));
    });
  }

  Future<void> _syncChallengeReminders(
    List<ChallengeProgress> progresses,
    String signature,
  ) async {
    if (_reminderSyncInFlight) return;
    _reminderSyncInFlight = true;
    try {
      await _reminderService.syncChallengeReminders(
        progresses.isEmpty ? null : progresses.first,
      );
    } finally {
      _reminderSyncInFlight = false;
      _lastReminderSignature = signature;
    }
  }

  Future<void> _syncFinalization(
    ChallengeProgress progress,
    String signature, {
    required bool presentResult,
  }) async {
    if (_finalizeInFlight) return;
    _finalizeInFlight = true;
    try {
      final awards = await _challengeService.finalizeRun(
        progress: progress,
        playerLevelService: PlayerLevelService(
          widget.optionRepository,
          sportId: SportService(widget.optionRepository).currentSportId(),
        ),
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
      final l10n = AppLocalizations.of(context)!;
      if (gainedXp > 0 && progress.allRoundsCompleted) {
        _showChallengeXpAlertsInBackground(awards, gainedXp);
      }
      if (!presentResult) {
        setState(() {});
        return;
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
              rewardGift: progress.run.rewardGift,
              roundGainedXp: roundGainedXp,
              completionGainedXp: completionGainedXp,
              missionSummaries: _completedMissionSummariesForRounds(
                l10n,
                SportService(widget.optionRepository).currentSportId(),
                progress.rounds.where((round) => round.completed),
              ),
            ),
          ),
        );
      }
      if (!mounted) return;
      setState(() {});
    } finally {
      _finalizeInFlight = false;
      _lastFinalizeSignatures[progress.run.id] = signature;
    }
  }

  String _finalizationSignature(ChallengeProgress progress) {
    final completedRounds = progress.rounds
        .where((round) => round.completed)
        .map((round) => round.round.number)
        .join(',');
    return '${progress.run.id}:finalize:$completedRounds:${progress.rounds.length}';
  }

  Future<void> _syncChallengeProgressAfterMissionReturn(String runId) async {
    if (_isParentReadOnlyMode) return;
    final trainingEntries = (await _activeChallengeTrainingEntries())
        .where((entry) => !entry.isMatch)
        .toList(growable: false);
    final mealEntries = widget.mealLogService.mergedEntries(
      directEntries: widget.mealLogService.allEntries(),
      legacyEntries: trainingEntries,
    );
    final progress = _challengeService.activeProgressForRun(
      runId: runId,
      trainingEntries: trainingEntries,
      mealEntries: mealEntries,
    );
    if (progress == null) return;
    if (progress.readyToFinalize()) {
      if (_finalizeInFlight) return;
      final signature = _finalizationSignature(progress);
      if (_lastFinalizeSignatures[progress.run.id] == signature) return;
      _pendingFinalizeSignatures.remove(signature);
      await _syncFinalization(progress, signature, presentResult: true);
      return;
    }
    if (_roundAwardInFlight) return;
    final signature = _roundAwardSignature(progress);
    if (_lastRoundAwardSignatures[progress.run.id] == signature) return;
    _pendingRoundAwardSignatures.remove(signature);
    final completedRounds = _completedRoundNumbersToken(progress);
    if (completedRounds.isEmpty) {
      await _syncRoundAwardRevocations(progress, signature);
    } else {
      await _syncRoundAwards(progress, signature, presentResult: true);
    }
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

  void _showChallengeXpAlertsInBackground(
    List<PlayerLevelAward> awards,
    int gainedXp,
  ) {
    unawaited(
      _showChallengeXpAlerts(awards, gainedXp).catchError((Object _) {}),
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

  Stream<List<TrainingEntry>> _watchChallengeTrainingEntries(
    DateTimeRange? range,
  ) {
    if (range == null) {
      return Stream<List<TrainingEntry>>.value(const <TrainingEntry>[]);
    }
    return widget.trainingService.watchEntriesInRange(range.start, range.end);
  }

  Future<List<TrainingEntry>> _activeChallengeTrainingEntries() async {
    final range = _activeChallengeTrainingRange();
    if (range == null) return const <TrainingEntry>[];
    final entries = await widget.trainingService.entriesInRange(
      range.start,
      range.end,
    );
    return filterEntriesForSport(
      entries,
      SportService(widget.optionRepository).currentSportId(),
    );
  }

  DateTimeRange? _activeChallengeTrainingRange() {
    DateTime? start;
    DateTime? end;
    for (final run in _challengeService.activeRuns()) {
      final template = _challengeService.templateById(run.templateId);
      if (template == null) continue;
      final runStart = run.startDay;
      final runEnd =
          run.dayForRound(template.dayCount).add(const Duration(days: 1));
      start = start == null || runStart.isBefore(start) ? runStart : start;
      end = end == null || runEnd.isAfter(end) ? runEnd : end;
    }
    if (start == null || end == null) return null;
    return DateTimeRange(start: start, end: end);
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

  Future<void> _prepareChallenge(
    ChallengeTemplate template,
    List<String> selectedSkillIds,
    ChallengeMissionTargets missionTargets,
    int cadenceDays,
    String rewardGift,
  ) async {
    if (_prepareChallengeInFlight) return;
    _prepareChallengeInFlight = true;
    final l10n = AppLocalizations.of(context)!;
    try {
      _playChallengeTapFeedback();
      final run = await _challengeService.prepareChallenge(
        template,
        selectedSkillIds: selectedSkillIds,
        missionTargets: missionTargets,
        cadenceDays: cadenceDays,
        rewardGift: rewardGift,
      );
      if (!mounted) return;
      setState(() {
        _mode = _ChallengeScreenMode.detail;
        _selectedRunId = run.id;
      });
      unawaited(_syncParentChallengeBackupIfPossible());
      _showChallengeTopSnackBar(
        _challengeSnackWithParentSync(
          l10n,
          l10n.challengePrepareSnack(_templateTitle(l10n, template)),
        ),
      );
    } finally {
      _prepareChallengeInFlight = false;
    }
  }

  Future<void> _startPreparedChallenge(ChallengeProgress progress) async {
    if (_startPreparedChallengeInFlight) return;
    if (_isParentReadOnlyMode) {
      _showParentReadOnlyMessage();
      return;
    }
    if (progress.run.isStarted) return;
    _startPreparedChallengeInFlight = true;
    final l10n = AppLocalizations.of(context)!;
    try {
      _playChallengeTapFeedback();
      final startedRun = await _challengeService.startPreparedRun(
        progress.run.id,
      );
      if (!mounted) return;
      if (startedRun == null) {
        setState(() {
          _mode = _ChallengeScreenMode.list;
          _selectedRunId = null;
        });
        return;
      }
      _lastFinalizeSignatures.remove(progress.run.id);
      _lastRoundAwardSignatures.remove(progress.run.id);
      setState(() {
        _mode = _ChallengeScreenMode.detail;
        _selectedRunId = startedRun.id;
      });
      _showChallengeTopSnackBar(
        l10n.challengeStartSnack(_templateTitle(l10n, progress.template)),
      );
    } finally {
      _startPreparedChallengeInFlight = false;
    }
  }

  Future<void> _updateChallenge(
    String runId,
    ChallengeTemplate template,
    List<String> selectedSkillIds,
    ChallengeMissionTargets missionTargets,
    int cadenceDays,
    String rewardGift, {
    bool showFeedback = true,
    bool stayInEdit = false,
  }) async {
    if (_updateChallengeInFlight) return;
    _updateChallengeInFlight = true;
    final l10n = AppLocalizations.of(context)!;
    try {
      final currentProgress = await _currentProgressForRun(runId);
      if (!mounted) return;
      if (currentProgress == null ||
          !_canEditPendingChallenge(currentProgress)) {
        if (showFeedback) {
          setState(() {
            _mode = currentProgress == null
                ? _ChallengeScreenMode.list
                : _ChallengeScreenMode.detail;
            _selectedRunId = currentProgress?.run.id;
          });
          _showChallengeTopSnackBar(l10n.challengeEditUnavailableSnack);
        }
        return;
      }
      if (showFeedback) {
        _playChallengeTapFeedback();
      }
      final updatedRun = await _challengeService.updateRun(
        runId,
        template: template,
        selectedSkillIds: selectedSkillIds,
        missionTargets: missionTargets,
        cadenceDays: cadenceDays,
        rewardGift: rewardGift,
      );
      if (!mounted) return;
      if (updatedRun == null) {
        if (showFeedback) {
          setState(() {
            _mode = _ChallengeScreenMode.list;
            _selectedRunId = null;
          });
        }
        return;
      }
      _lastFinalizeSignatures.remove(runId);
      _lastRoundAwardSignatures.remove(runId);
      setState(() {
        _mode = stayInEdit
            ? _ChallengeScreenMode.edit
            : _ChallengeScreenMode.detail;
        _selectedRunId = updatedRun.id;
      });
      unawaited(_syncParentChallengeBackupIfPossible());
      if (showFeedback) {
        _showChallengeTopSnackBar(
          _challengeSnackWithParentSync(l10n, l10n.challengeUpdateSnack),
        );
      }
    } finally {
      _updateChallengeInFlight = false;
    }
  }

  Future<void> _confirmDeleteParentPendingChallenge(
    ChallengeProgress progress,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_canDeleteParentPendingChallenge(progress)) {
      _showChallengeTopSnackBar(l10n.challengeDeletePendingUnavailableSnack);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.challengeDeletePendingTitle),
        content: Text(l10n.challengeDeletePendingBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.challengeDeletePendingConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!_canDeleteParentPendingChallenge(progress)) {
      _showChallengeTopSnackBar(l10n.challengeDeletePendingUnavailableSnack);
      return;
    }
    final deleted = await _challengeService.deleteActiveRun(progress.run.id);
    if (!mounted) return;
    if (!deleted) {
      _showChallengeTopSnackBar(l10n.challengeDeletePendingUnavailableSnack);
      return;
    }
    _lastFinalizeSignatures.remove(progress.run.id);
    _lastRoundAwardSignatures.remove(progress.run.id);
    _pendingFinalizeSignatures.removeWhere(
      (signature) => signature.startsWith('${progress.run.id}:'),
    );
    _pendingRoundAwardSignatures.removeWhere(
      (signature) => signature.startsWith('${progress.run.id}:'),
    );
    setState(() {
      _mode = _ChallengeScreenMode.list;
      _selectedRunId = null;
    });
    unawaited(_syncParentChallengeBackupIfPossible());
    _showChallengeTopSnackBar(
      _challengeSnackWithParentSync(l10n, l10n.challengeDeletePendingSnack),
    );
  }

  Future<void> _confirmAbandon(ChallengeProgress progress) async {
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
    final trainingEntries = (await _activeChallengeTrainingEntries())
        .where((entry) => !entry.isMatch)
        .toList(growable: false);
    final mealEntries = widget.mealLogService.mergedEntries(
      directEntries: widget.mealLogService.allEntries(),
      legacyEntries: trainingEntries,
    );
    var gainedXp = 0;
    var awardedRoundCount = 0;
    final currentProgress = _challengeService.activeProgressForRun(
      runId: progress.run.id,
      trainingEntries: trainingEntries,
      mealEntries: mealEntries,
    );
    final completedRoundNumbers = currentProgress == null
        ? const <int>[]
        : currentProgress.rounds
            .where((round) => round.completed)
            .map((round) => round.round.number)
            .toList(growable: false);
    if (currentProgress != null && completedRoundNumbers.isNotEmpty) {
      final awards = await _challengeService.awardCompletedRounds(
        progress: currentProgress,
        playerLevelService: PlayerLevelService(
          widget.optionRepository,
          sportId: SportService(widget.optionRepository).currentSportId(),
        ),
      );
      gainedXp = awards.fold<int>(0, (sum, award) => sum + award.gainedXp);
      awardedRoundCount = awards
          .where((award) => award.reasons.contains('challenge_round_completed'))
          .length
          .clamp(0, currentProgress.rounds.length)
          .toInt();
    }
    await _challengeService.abandonRun(
      progress.run.id,
      completedRoundNumbers: completedRoundNumbers,
    );
    if (!mounted) return;
    setState(() {
      _mode = _ChallengeScreenMode.list;
      _selectedRunId = null;
    });
    if (gainedXp > 0) {
      _playChallengeSuccessFeedback();
      await Navigator.of(context).push(
        AppPageRoute<void>(
          builder: (_) => _ChallengeCelebrationScreen(
            gainedXp: gainedXp,
            awardedRoundCount: awardedRoundCount.clamp(1, 99).toInt(),
            challengeCompleted: false,
            rewardGift: progress.run.rewardGift,
            roundGainedXp: gainedXp,
            completionGainedXp: 0,
            missionSummaries: _completedMissionSummariesForRounds(
              l10n,
              SportService(widget.optionRepository).currentSportId(),
              currentProgress?.rounds.where((round) => round.completed) ??
                  const <ChallengeRoundProgress>[],
            ),
          ),
        ),
      );
      if (!mounted) return;
    }
    setState(() {});
  }

  Future<void> _openTrainingMission(
    ChallengeProgress progress,
    ChallengeRoundProgress round, {
    ChallengeTrainingProgramProgress? program,
  }) {
    return _openTrainingEntryMission(
      progress,
      round,
      initialFocusTarget: null,
      programMission: program,
    );
  }

  Future<void> _openJumpRopeMission(
    ChallengeProgress progress,
    ChallengeRoundProgress round,
  ) {
    return _openTrainingEntryMission(
      progress,
      round,
      initialFocusTarget: EntryFormInitialFocusTarget.jumpRope,
    );
  }

  Future<void> _openLiftingMission(
    ChallengeProgress progress,
    ChallengeRoundProgress round,
  ) {
    return _openTrainingEntryMission(
      progress,
      round,
      initialFocusTarget: EntryFormInitialFocusTarget.lifting,
    );
  }

  Future<void> _openTrainingEntryMission(
    ChallengeProgress progress,
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
    final initialPlanContext = initialFocusTarget == null &&
            targetTrainingMinutes > 0 &&
            (existingEntry == null || remainingTrainingMinutes > 0)
        ? EntryFormInitialPlanContext(
            scheduledAt: round.date,
            program: programMission?.label ?? '',
            durationMinutes: remainingTrainingMinutes > 0
                ? remainingTrainingMinutes
                : targetTrainingMinutes,
          )
        : null;
    final initialConditioningOnly = existingEntry == null &&
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
          initialEnableJumpRope: initialFocusTarget != null &&
              round.round.targetJumpRopeMinutes > 0,
          initialEnableLifting: initialFocusTarget != null &&
              round.round.targetLiftingMinutes > 0,
        ),
      ),
    );
    if (!mounted) return;
    await _syncChallengeProgressAfterMissionReturn(progress.run.id);
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
    final sameDayEntries = entries
        .where(
          (entry) =>
              !entry.isMatch && normalizeDay(entry.date) == normalizedDay,
        )
        .toList(growable: false)
      ..sort(TrainingEntry.compareByRecentCreated);
    if (sameDayEntries.isEmpty) return null;
    if (targetProgram == null || targetProgram.isEmpty) {
      return sameDayEntries.first;
    }
    for (final entry in sameDayEntries) {
      if (trainingEntryMatchesChallengeSkill(entry, <String>[targetProgram])) {
        return entry;
      }
    }
    return sameDayEntries.first;
  }

  Future<void> _openMealMission(
    ChallengeProgress progress,
    ChallengeRoundProgress round,
  ) async {
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
    await _syncChallengeProgressAfterMissionReturn(progress.run.id);
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
    AppSoundEffects.playTap();
  }

  void _playChallengeSuccessFeedback() {
    AppSoundEffects.playMissionComplete();
  }

  void _showChallengeTopSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final media = MediaQuery.maybeOf(context);
    final bottomMargin = media == null
        ? 16.0
        : (media.size.height - media.padding.top - 104)
            .clamp(16.0, media.size.height * 0.82)
            .toDouble();
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsetsDirectional.only(
            start: 16,
            end: 16,
            bottom: bottomMargin,
          ),
        ),
      );
  }

  bool get _isParentReadOnlyMode {
    return FamilyAccessService(
      widget.optionRepository,
    ).loadState().isParentMode;
  }

  bool _canDeleteParentPendingChallenge(ChallengeProgress progress) {
    if (!_isParentReadOnlyMode) return false;
    return _canEditPendingChallenge(progress);
  }

  bool _canEditPendingChallenge(ChallengeProgress progress) {
    if (progress.run.isEnded) return false;
    return !progress.run.isStarted;
  }

  Future<ChallengeProgress?> _currentProgressForRun(String runId) async {
    final trainingEntries = (await _activeChallengeTrainingEntries())
        .where((entry) => !entry.isMatch)
        .toList(growable: false);
    final mealEntries = widget.mealLogService.mergedEntries(
      directEntries: widget.mealLogService.allEntries(),
      legacyEntries: trainingEntries,
    );
    return _challengeService.activeProgressForRun(
      runId: runId,
      trainingEntries: trainingEntries,
      mealEntries: mealEntries,
    );
  }

  Future<void> _syncParentChallengeBackupIfPossible() async {
    if (!_isParentReadOnlyMode) return;
    final backup = widget.driveBackupService;
    if (backup == null) return;
    try {
      await backup.markParentSharedDataDirty();
      await backup.backupIfSignedIn();
    } catch (_) {
      // Challenge setup remains saved locally if shared backup is unavailable.
    }
  }

  String _challengeSnackWithParentSync(
    AppLocalizations l10n,
    String message,
  ) {
    if (!_isParentReadOnlyMode) return message;
    return '$message ${l10n.parentSharedSyncPending}';
  }

  void _showParentReadOnlyMessage() {
    _showChallengeTopSnackBar(
      AppLocalizations.of(context)!.parentReadOnlyChallengeMessage,
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
          Icon(
            Icons.supervisor_account_rounded,
            color: theme.colorScheme.primary,
          ),
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
  final String sportId;
  final List<ChallengeTemplate> templates;
  final String Function(ChallengeTemplate template) templateTitle;
  final String Function(ChallengeTemplate template) templateDescription;
  final ChallengeRun? latestCompletedRun;
  final ChallengeTemplate? latestCompletedTemplate;
  final ChallengeRun? initialRun;
  final ChallengeTemplate? initialTemplate;
  final List<_ChallengeSkillOption> skillOptions;
  final bool canEditRewardGift;
  final VoidCallback onOpenTrainingPrograms;
  final Future<void> Function(
    ChallengeTemplate template,
    List<String> selectedSkillIds,
    ChallengeMissionTargets missionTargets,
    int cadenceDays,
    String rewardGift,
  ) onStart;
  final Future<void> Function(
    ChallengeTemplate template,
    List<String> selectedSkillIds,
    ChallengeMissionTargets missionTargets,
    int cadenceDays,
    String rewardGift,
  )? onAutoSave;
  final String submitLabel;
  final IconData submitIcon;

  const _ChallengeStartSection({
    required this.sportId,
    required this.templates,
    required this.templateTitle,
    required this.templateDescription,
    required this.latestCompletedRun,
    required this.latestCompletedTemplate,
    this.initialRun,
    this.initialTemplate,
    required this.skillOptions,
    required this.canEditRewardGift,
    required this.onOpenTrainingPrograms,
    required this.onStart,
    this.onAutoSave,
    required this.submitLabel,
    required this.submitIcon,
  });

  @override
  State<_ChallengeStartSection> createState() => _ChallengeStartSectionState();
}

class _ChallengeStartSectionState extends State<_ChallengeStartSection> {
  static const Duration _autoSaveDelay = Duration(milliseconds: 700);

  final GlobalKey _missionSectionKey = GlobalKey();
  final GlobalKey _readySectionKey = GlobalKey();
  ChallengeTemplate? _selectedTemplate;
  late Set<String> _selectedSkillIds;
  int _selectedCadenceDays = 1;
  ChallengeMissionTargets? _missionTargets;
  bool _submitting = false;
  late final TextEditingController _rewardGiftController;
  Timer? _autoSaveTimer;
  Future<void>? _activeAutoSave;
  bool _autoSaveInFlight = false;
  bool _autoSaveQueued = false;
  String _lastAutoSavedSignature = '';

  @override
  void initState() {
    super.initState();
    _rewardGiftController = TextEditingController();
    _applyInitialValues();
    _lastAutoSavedSignature = _currentAutoSaveSignature();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _rewardGiftController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ChallengeStartSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRun?.id != widget.initialRun?.id ||
        oldWidget.initialTemplate?.id != widget.initialTemplate?.id) {
      _applyInitialValues();
      _lastAutoSavedSignature = _currentAutoSaveSignature();
      return;
    }
    if (!_sameChallengeSkillOptions(
      oldWidget.skillOptions,
      widget.skillOptions,
    )) {
      final availableIds =
          widget.skillOptions.map((option) => option.id).toSet();
      _selectedSkillIds =
          _selectedSkillIds.where(availableIds.contains).toSet();
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
    final latestCompletedRun = widget.latestCompletedRun;
    final latestCompletedTemplate = widget.latestCompletedTemplate;
    final editing = widget.initialRun != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (editing)
          _ChallengeIntroCard(
            title: l10n.challengeEditTitle,
            body: l10n.challengeEditBody,
            progress: _selectedTemplate == null ? 0 : 1,
          )
        else if (latestCompletedRun != null && latestCompletedTemplate != null)
          _ChallengeFinishedPraiseCard(
            run: latestCompletedRun,
            template: latestCompletedTemplate,
            templateTitle: widget.templateTitle(latestCompletedTemplate),
          )
        else
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
            l10n.challengeCadenceSelectTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cadenceDays in _challengeCadenceOptions)
                ChoiceChip(
                  label: Text(_challengeCadenceLabel(l10n, cadenceDays)),
                  selected: cadenceDays == _selectedCadenceDays,
                  onSelected: (_) => _updateAndScheduleAutoSave(
                    () => _selectedCadenceDays = cadenceDays,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
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
            sportId: widget.sportId,
            trainingProgramOptions: widget.skillOptions,
            selectedTrainingProgramIds: _selectedSkillIds,
            missionTargets: _effectiveMissionTargets,
            defaultTargets: _defaultMissionTargetsForSelectedLevel,
            onOpenTrainingPrograms: widget.onOpenTrainingPrograms,
            onTrainingProgramsChanged: _updateSelectedTrainingPrograms,
            onMissionTargetsChanged: _updateMissionTargets,
          ),
          const SizedBox(height: 10),
          _ChallengeMissionTargetSection(
            sportId: widget.sportId,
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
          if (widget.canEditRewardGift ||
              _rewardGiftController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _ChallengeRewardGiftField(
              controller: _rewardGiftController,
              enabled: widget.canEditRewardGift,
              onChanged: (_) => _updateAndScheduleAutoSave(() {}),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : Icon(widget.submitIcon),
            label: Text(widget.submitLabel),
          ),
        ],
      ],
    );
  }

  Future<void> _submit() async {
    final selectedTemplate = _selectedTemplate;
    if (_submitting || selectedTemplate == null) return;
    _autoSaveTimer?.cancel();
    setState(() {
      _submitting = true;
    });
    try {
      await _activeAutoSave;
      await widget.onStart(
        selectedTemplate,
        normalizeChallengeSkillIds(
          _selectedSkillIds,
          allowEmpty: !_effectiveMissionTargets.hasTrainingMission,
        ),
        _effectiveMissionTargets,
        _selectedCadenceDays,
        _rewardGiftController.text,
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _applyInitialValues() {
    final initialRun = widget.initialRun;
    _selectedTemplate = widget.initialTemplate;
    _selectedCadenceDays = initialRun?.normalizedCadenceDays ?? 1;
    if (initialRun == null) {
      _selectedSkillIds = <String>{};
      _missionTargets = null;
      _rewardGiftController.text = '';
      return;
    }
    _selectedSkillIds = normalizeChallengeSkillIds(
      initialRun.selectedSkillIds,
      allowEmpty: initialRun.missionTargets?.hasTrainingMission == false,
    ).toSet();
    _missionTargets = initialRun.missionTargets ??
        _defaultInitialMissionTargets(
          _selectedSkillIds,
        );
    _rewardGiftController.text = initialRun.rewardGift;
  }

  void _selectTemplate(ChallengeTemplate template) {
    final selectedTrainingPrograms = _defaultSelectedTrainingProgramIds();
    setState(() {
      _selectedTemplate = template;
      _selectedSkillIds = selectedTrainingPrograms;
      _missionTargets = _defaultInitialMissionTargets(selectedTrainingPrograms);
    });
    _scheduleAutoSave();
    _scrollTo(_missionSectionKey);
  }

  ChallengeMissionTargets get _defaultMissionTargetsForSelectedLevel {
    return challengeMissionTargetsFromConfig(
      trainingLevelConfig(ChallengeTrainingLevel.rookie),
    );
  }

  Set<String> _defaultSelectedTrainingProgramIds() {
    if (widget.skillOptions.isEmpty) return <String>{};
    return <String>{widget.skillOptions.first.id};
  }

  ChallengeMissionTargets _defaultInitialMissionTargets(
    Set<String> selectedTrainingPrograms,
  ) {
    final defaults = _defaultMissionTargetsForSelectedLevel.copyWith(
      liftingMinutes: 0,
      riceBowls: 0,
    );
    return _targetsWithSelectedTrainingPrograms(
      defaults,
      selectedTrainingPrograms,
      defaultTrainingMinutes: defaults.trainingMinutes,
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
    _scheduleAutoSave();
  }

  void _updateMissionTargets(ChallengeMissionTargets targets) {
    if (!targets.hasAnyMission) return;
    setState(() {
      _missionTargets = targets;
      if (!targets.hasTrainingMission) {
        _selectedSkillIds = <String>{};
      }
    });
    _scheduleAutoSave();
  }

  void _updateAndScheduleAutoSave(VoidCallback update) {
    setState(update);
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    if (widget.initialRun == null || widget.onAutoSave == null) {
      return;
    }
    final signature = _currentAutoSaveSignature();
    if (signature.isEmpty || signature == _lastAutoSavedSignature) {
      return;
    }
    if (_autoSaveInFlight) {
      _autoSaveQueued = true;
      return;
    }
    _autoSaveTimer = Timer(_autoSaveDelay, () {
      final future = _runAutoSave();
      _activeAutoSave = future;
      unawaited(future);
    });
  }

  Future<void> _runAutoSave() async {
    final onAutoSave = widget.onAutoSave;
    final selectedTemplate = _selectedTemplate;
    if (onAutoSave == null || selectedTemplate == null) return;
    final missionTargets = _effectiveMissionTargets;
    final selectedSkillIds = normalizeChallengeSkillIds(
      _selectedSkillIds,
      allowEmpty: !missionTargets.hasTrainingMission,
    );
    final signature = _autoSaveSignature(
      template: selectedTemplate,
      selectedSkillIds: selectedSkillIds,
      missionTargets: missionTargets,
      cadenceDays: _selectedCadenceDays,
      rewardGift: _rewardGiftController.text,
    );
    if (signature == _lastAutoSavedSignature) return;
    if (_autoSaveInFlight) {
      _autoSaveQueued = true;
      return;
    }
    _autoSaveInFlight = true;
    try {
      await onAutoSave(
        selectedTemplate,
        selectedSkillIds,
        missionTargets,
        _selectedCadenceDays,
        _rewardGiftController.text,
      );
      _lastAutoSavedSignature = signature;
    } finally {
      _autoSaveInFlight = false;
      _activeAutoSave = null;
      if (_autoSaveQueued && mounted) {
        _autoSaveQueued = false;
        _scheduleAutoSave();
      }
    }
  }

  String _currentAutoSaveSignature() {
    final selectedTemplate = _selectedTemplate;
    if (selectedTemplate == null) return '';
    final missionTargets = _effectiveMissionTargets;
    return _autoSaveSignature(
      template: selectedTemplate,
      selectedSkillIds: normalizeChallengeSkillIds(
        _selectedSkillIds,
        allowEmpty: !missionTargets.hasTrainingMission,
      ),
      missionTargets: missionTargets,
      cadenceDays: _selectedCadenceDays,
      rewardGift: _rewardGiftController.text,
    );
  }

  String _autoSaveSignature({
    required ChallengeTemplate template,
    required List<String> selectedSkillIds,
    required ChallengeMissionTargets missionTargets,
    required int cadenceDays,
    required String rewardGift,
  }) {
    final programTargets = missionTargets.trainingProgramMinutes.entries
        .toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));
    return [
      template.id,
      cadenceDays.toString(),
      selectedSkillIds.join(','),
      missionTargets.trainingMinutes.toString(),
      missionTargets.jumpRopeMinutes.toString(),
      missionTargets.liftingMinutes.toString(),
      missionTargets.riceBowls.toString(),
      for (final target in programTargets) '${target.key}:${target.value}',
      rewardGift.trim(),
    ].join('\n');
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

class _ChallengeFinishedPraiseCard extends StatelessWidget {
  final ChallengeRun run;
  final ChallengeTemplate template;
  final String templateTitle;

  const _ChallengeFinishedPraiseCard({
    required this.run,
    required this.template,
    required this.templateTitle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final completedRoundCount = (run.completedRoundNumbers.isEmpty
            ? template.dayCount
            : run.completedRoundNumbers.toSet().length)
        .clamp(1, template.dayCount)
        .toInt();
    return Container(
      key: const ValueKey('challenge-finished-praise-card'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.22 : 0.34,
        ),
        borderRadius: AppRadius.surface,
        border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 350;
          final promptMaxWidth = (constraints.maxWidth - (compact ? 78 : 44))
              .clamp(120.0, 260.0)
              .toDouble();
          final mascot = ChallengeCheerRinzyMascot(
            size: compact ? 138 : 116,
            progress: 1,
            useImage: true,
          );
          final content = Column(
            crossAxisAlignment:
                compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              _SmallStatusPill(label: l10n.challengeCompletedBadge),
              const SizedBox(height: 10),
              Text(
                l10n.challengeFinishedPraiseTitle,
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.challengeFinishedPraiseBody(
                  templateTitle,
                  completedRoundCount,
                ),
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: compact ? WrapAlignment.center : WrapAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SmallStatusPill(
                    label: l10n.challengeFinishedCompletedRoundsLabel(
                      completedRoundCount,
                    ),
                  ),
                  _SmallStatusPill(
                    label: l10n.challengeDaysLabel(template.dayCount),
                  ),
                ],
              ),
              if (run.hasRewardGift) ...[
                const SizedBox(height: 12),
                _ChallengeRewardGiftNotice(rewardGift: run.rewardGift),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.74),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_task_rounded,
                      color: scheme.primary,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: promptMaxWidth),
                      child: Text(
                        l10n.challengeFinishedNextPrompt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          if (compact) {
            return Column(
              children: [
                mascot,
                const SizedBox(height: 12),
                content,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              mascot,
              const SizedBox(width: 16),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
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
    final scheme = theme.colorScheme;
    final accent = scheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('challenge-template-${template.id}'),
        onTap: onSelect,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.24 : 0.34,
                  )
                : scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.78)
                  : scheme.outlineVariant.withValues(alpha: 0.72),
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
                      color: selected
                          ? accent.withValues(alpha: 0.14)
                          : scheme.surfaceContainerHighest.withValues(
                              alpha: 0.74,
                            ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.flag_outlined,
                      color: selected ? accent : scheme.onSurfaceVariant,
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
                    color: selected ? accent : scheme.onSurfaceVariant,
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

const List<int> _challengeCadenceOptions = <int>[1, 2, 7];

String _challengeCadenceLabel(AppLocalizations l10n, int cadenceDays) {
  return switch (cadenceDays) {
    1 => l10n.challengeCadenceDaily,
    2 => l10n.challengeCadenceEveryTwoDays,
    7 => l10n.challengeCadenceWeekly,
    _ => l10n.challengeCadenceEveryNDays(cadenceDays),
  };
}

String _challengePeriodLabel(BuildContext context, ChallengeProgress progress) {
  final l10n = AppLocalizations.of(context)!;
  final localeName = Localizations.localeOf(context).toLanguageTag();
  final formatter = DateFormat.Md(localeName);
  final end = progress.finalRoundDate ?? progress.run.startDay;
  return l10n.challengeHistoryDetailPeriodValue(
    formatter.format(progress.run.startDay),
    formatter.format(end),
  );
}

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
  final String sportId;
  final List<_ChallengeSkillOption> trainingProgramOptions;
  final Set<String> selectedTrainingProgramIds;
  final ChallengeMissionTargets missionTargets;
  final ChallengeMissionTargets defaultTargets;
  final VoidCallback onOpenTrainingPrograms;
  final ValueChanged<Set<String>> onTrainingProgramsChanged;
  final ValueChanged<ChallengeMissionTargets> onMissionTargetsChanged;

  const _ChallengeMissionPicker({
    required this.sportId,
    required this.trainingProgramOptions,
    required this.selectedTrainingProgramIds,
    required this.missionTargets,
    required this.defaultTargets,
    required this.onOpenTrainingPrograms,
    required this.onTrainingProgramsChanged,
    required this.onMissionTargetsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final primaryConditioningLabel = SportDefaults.primaryConditioningLabel(
      l10n: l10n,
      sportId: sportId,
    );
    final secondaryConditioningLabel = SportDefaults.secondaryConditioningLabel(
      l10n: l10n,
      sportId: sportId,
    );
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
              _AddTrainingProgramButton(onPressed: onOpenTrainingPrograms),
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
                icon: sportPrimaryConditioningIcon(sportId),
                label: primaryConditioningLabel,
                selected: missionTargets.hasJumpRopeMission,
                onSelected: (selected) => _toggleJumpRope(selected),
              ),
              _MissionToggleChip(
                icon: sportSecondaryConditioningIcon(sportId),
                label: secondaryConditioningLabel,
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

class _AddTrainingProgramButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddTrainingProgramButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Tooltip(
      message: l10n.challengeTrainingProgramLinkTitle,
      child: Semantics(
        button: true,
        label: l10n.challengeTrainingProgramLinkTitle,
        child: SizedBox.square(
          key: const ValueKey('challenge-add-training-program-button'),
          dimension: 40,
          child: Material(
            color: color.withValues(alpha: 0.10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: color.withValues(alpha: 0.34)),
            ),
            child: InkWell(
              onTap: onPressed,
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.add_rounded, color: color),
            ),
          ),
        ),
      ),
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
    final selectedColor = theme.colorScheme.primary;
    return FilterChip(
      avatar: AnimatedContainer(
        duration: AppMotion.fast(context),
        curve: AppMotion.curveEmphasis,
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: selected
              ? selectedColor
              : theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? selectedColor : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: selected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
      selected: selected,
      selectedColor: selectedColor.withValues(alpha: 0.18),
      checkmarkColor: selectedColor,
      side: BorderSide(
        color: selected
            ? selectedColor.withValues(alpha: 0.72)
            : theme.colorScheme.outlineVariant,
        width: selected ? 1.4 : 1,
      ),
      onSelected: onSelected,
    );
  }
}

class _ChallengeMissionTargetSection extends StatelessWidget {
  final String sportId;
  final List<_ChallengeSkillOption> selectedTrainingPrograms;
  final ChallengeMissionTargets missionTargets;
  final ValueChanged<ChallengeMissionTargets> onChanged;

  const _ChallengeMissionTargetSection({
    required this.sportId,
    required this.selectedTrainingPrograms,
    required this.missionTargets,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final primaryConditioningLabel = SportDefaults.primaryConditioningLabel(
      l10n: l10n,
      sportId: sportId,
    );
    final secondaryConditioningLabel = SportDefaults.secondaryConditioningLabel(
      l10n: l10n,
      sportId: sportId,
    );
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
              icon: sportPrimaryConditioningIcon(sportId),
              title: primaryConditioningLabel,
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
              icon: sportSecondaryConditioningIcon(sportId),
              title: secondaryConditioningLabel,
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

class _ChallengeRewardGiftField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _ChallengeRewardGiftField({
    required this.controller,
    required this.enabled,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.card_giftcard_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.challengeRewardGiftSectionTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.challengeRewardGiftSectionSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('challenge-reward-gift-input'),
            controller: controller,
            enabled: enabled,
            maxLength: 40,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              counterText: '',
              labelText: l10n.challengeRewardGiftInputLabel,
              hintText: l10n.challengeRewardGiftInputHint,
              prefixIcon: const Icon(Icons.redeem_rounded),
            ),
            onChanged: onChanged,
          ),
          if (!enabled && controller.text.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _SmallStatusPill(
              label: l10n.challengeRewardGiftPill(controller.text.trim()),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChallengeRewardGiftNotice extends StatelessWidget {
  final String rewardGift;

  const _ChallengeRewardGiftNotice({required this.rewardGift});

  @override
  Widget build(BuildContext context) {
    final gift = rewardGift.trim();
    if (gift.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.card_giftcard_rounded, color: scheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.challengeRewardGiftPromisedLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onTertiaryContainer,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.challengeRewardGiftPromisedBody(gift),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onTertiaryContainer,
                    fontWeight: FontWeight.w700,
                    height: 1.28,
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
              if (activeProgress?.run.hasRewardGift == true) ...[
                const SizedBox(height: 12),
                _ChallengeRewardGiftNotice(
                  rewardGift: activeProgress!.run.rewardGift,
                ),
              ],
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
  final Set<int> completedRoundNumbers;

  const _ChallengeRewardBreakdownCard({
    required this.title,
    required this.template,
    required this.level,
    this.progress,
    this.completedRoundNumbers = const <int>{},
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
        ? completedRoundNumbers.isEmpty
            ? null
            : _challengeEarnedRoundXpForCompletedRounds(
                template: template,
                level: level,
                completedRoundNumbers: completedRoundNumbers,
              )
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
                _progressRoundCompleted(progress, roundNumber) ||
                completedRoundNumbers.contains(roundNumber),
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
    final shownRuns =
        limit == null ? runs : runs.take(limit!).toList(growable: false);
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
    final completedRounds = _historyCompletedRoundTotal(runs);
    final failedRounds = _historyFailedRoundTotal(runs);
    final totalRounds = _historyRoundTotal(runs);
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
                value: l10n.challengeHistoryRoundSuccessCount(
                  completedRounds,
                  totalRounds,
                ),
              ),
              _ChallengeInfoItem(
                icon: Icons.error_outline_rounded,
                label: l10n.challengeHistoryResultFailed,
                value: l10n.challengeHistoryRoundFailureCount(
                  failedRounds,
                  totalRounds,
                ),
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
    final failedRounds = _historyFailedRoundCount(run, template);
    final roundCount = template == null
        ? ''
        : l10n.challengeHistoryRoundSuccessCount(
            completedRounds,
            template!.dayCount,
          );
    final earnedXp =
        template == null ? 0 : _historyEarnedXpForRun(run, template!);
    final detailParts = <String>[
      run.isFailed && run.failedRoundNumber != null
          ? l10n.challengeHistoryFailedRound(started, run.failedRoundNumber!)
          : l10n.challengeHistoryStarted(started),
      _runResultLabel(l10n, run),
      if (roundCount.isNotEmpty) roundCount,
      if (template != null && failedRounds > 0)
        l10n.challengeHistoryRoundFailureCount(
          failedRounds,
          template!.dayCount,
        ),
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
                      ? const ChallengeCheerRinzyMascot(size: 34, progress: 1)
                      : run.isFailed
                          ? const ChallengeSadRinzyMascot(size: 34)
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
    final endDay =
        run.completedAt == null ? run.startDay : normalizeDay(run.completedAt!);
    final end = DateFormat.yMMMd(localeName).format(endDay);
    final missionLabels = _challengeSkillLabels(l10n, run.selectedSkillIds);
    final earnedXp =
        template == null ? 0 : _historyEarnedXpForRun(run, template);
    final completedRoundCount = _historyCompletedRoundCount(run, template);
    final failedRoundCount = _historyFailedRoundCount(run, template);
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
                    if (run.hasRewardGift)
                      _ChallengeInfoItem(
                        icon: Icons.card_giftcard_rounded,
                        label: l10n.challengeRewardGiftPromisedLabel,
                        value: run.rewardGift,
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
                        value: l10n.challengeHistoryRoundSuccessCount(
                          completedRoundCount,
                          template.dayCount,
                        ),
                      ),
                    if (template != null)
                      _ChallengeInfoItem(
                        icon: Icons.error_outline_rounded,
                        label: l10n.challengeHistoryResultFailed,
                        value: l10n.challengeHistoryRoundFailureCount(
                          failedRoundCount,
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
                  completedRoundNumbers: _historyCompletedRoundNumbers(
                    run,
                    template,
                  ),
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
              final completed = _historyRoundCompleted(
                run,
                template,
                round.number,
              );
              final failed = _historyRoundFailed(run, template, round.number);
              final earnedXp = completed
                  ? challengeRoundRewardXpFor(
                      baseRewardXp: config.rewardXpPerRound,
                      consecutiveRoundNumber: _historyRoundStreakFor(
                        run,
                        template,
                        round.number,
                      ),
                    )
                  : 0;
              return _ChallengeHistoryRoundTile(
                label: l10n.challengeHistoryDetailRoundDate(
                  round.number,
                  dateFormatter.format(run.dayForRound(round.number)),
                ),
                status: _historyRoundStatusLabel(
                  l10n,
                  run,
                  template,
                  round.number,
                ),
                reward: l10n.challengeRewardXp(earnedXp),
                completed: completed,
                failed: failed,
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
  final bool failed;

  const _ChallengeHistoryRoundTile({
    required this.label,
    required this.status,
    required this.reward,
    required this.completed,
    required this.failed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = completed
        ? theme.colorScheme.primary
        : failed
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: failed
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.34)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed
              ? theme.colorScheme.primary.withValues(alpha: 0.34)
              : failed
                  ? theme.colorScheme.error.withValues(alpha: 0.34)
                  : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            completed
                ? Icons.check_circle_rounded
                : failed
                    ? Icons.cancel_rounded
                    : Icons.circle_outlined,
            size: 20,
            color: statusColor,
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
                    color: statusColor,
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

  const _ChallengeDetailCard({super.key, required this.child});

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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.subtleDecoration(
        theme.colorScheme,
        theme.brightness,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 330;
          final mascot = ChallengeRinzyMascot(
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
  final String sportId;
  final ChallengeProgress progress;
  final String templateTitle;
  final bool readOnly;
  final VoidCallback onAbandon;
  final _OpenChallengeTrainingMission onOpenTraining;
  final _OpenChallengeMission onOpenJumpRope;
  final _OpenChallengeMission onOpenLifting;
  final _OpenChallengeMission onOpenMeal;
  final VoidCallback onOpenTrainingPrograms;
  final VoidCallback onStartPrepared;
  final int? focusRoundNumber;

  const _ActiveChallengeSection({
    required this.sportId,
    required this.progress,
    required this.templateTitle,
    required this.readOnly,
    required this.onAbandon,
    required this.onOpenTraining,
    required this.onOpenJumpRope,
    required this.onOpenLifting,
    required this.onOpenMeal,
    required this.onOpenTrainingPrograms,
    required this.onStartPrepared,
    this.focusRoundNumber,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final focusedRound = _focusedRoundFor(progress, focusRoundNumber);
    final started = progress.run.isStarted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (readOnly) ...[
          const _ParentReadOnlyChallengeNotice(),
          const SizedBox(height: 18),
        ],
        if (progress.run.hasRewardGift) ...[
          _ChallengeRewardGiftNotice(rewardGift: progress.run.rewardGift),
          const SizedBox(height: 18),
        ],
        if (!started)
          _ChallengeReadyCard(
            templateTitle: templateTitle,
            readOnly: readOnly,
            onStart: readOnly ? null : onStartPrepared,
          )
        else ...[
          Text(
            l10n.challengeActiveCardTitle(templateTitle),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _ChallengeRoundsCalendar(
            progress: progress,
            onAbandon: readOnly ? null : onAbandon,
          ),
          const SizedBox(height: 18),
          if (focusedRound != null)
            _RoundFocusCard(
              sportId: sportId,
              progress: progress,
              round: focusedRound,
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
      ],
    );
  }

  ChallengeRoundProgress? _focusedRoundFor(
    ChallengeProgress progress,
    int? roundNumber,
  ) {
    if (roundNumber != null) {
      for (final round in progress.rounds) {
        if (round.round.number == roundNumber) return round;
      }
    }
    return progress.activeRound;
  }
}

class _ChallengeReadyCard extends StatelessWidget {
  final String templateTitle;
  final bool readOnly;
  final VoidCallback? onStart;

  const _ChallengeReadyCard({
    required this.templateTitle,
    required this.readOnly,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return _ChallengeDetailCard(
      key: const ValueKey('challenge-ready-card'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final mascot = ChallengeRinzyMascot(
            size: compact ? 112 : 96,
            progress: 0.18,
          );
          final content = Column(
            crossAxisAlignment:
                compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              _SmallStatusPill(label: l10n.challengeReadyBadge),
              const SizedBox(height: 10),
              Text(
                l10n.challengeReadyCardTitle(templateTitle),
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                readOnly
                    ? l10n.challengeReadyParentBody
                    : l10n.challengeReadyPlayerBody,
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              if (onStart != null) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  key: const ValueKey('challenge-start-prepared-button'),
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.challengeReadyStartAction),
                ),
              ],
            ],
          );
          if (compact) {
            return Column(
                children: [mascot, const SizedBox(height: 12), content]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              mascot,
              const SizedBox(width: 14),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}

class _RoundFocusCard extends StatelessWidget {
  final String sportId;
  final ChallengeProgress progress;
  final ChallengeRoundProgress round;
  final bool readOnly;
  final _OpenChallengeTrainingMission onOpenTraining;
  final _OpenChallengeMission onOpenJumpRope;
  final _OpenChallengeMission onOpenLifting;
  final _OpenChallengeMission onOpenMeal;
  final VoidCallback onOpenTrainingPrograms;

  const _RoundFocusCard({
    required this.sportId,
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
        : round.completed || round.isMissed
            ? l10n.challengeRoundTitle(round.round.number)
            : l10n.challengeUpcomingRoundTitle(round.round.number);
    final selectedPrograms = _challengeSkillLabels(
      l10n,
      progress.run.selectedSkillIds,
    );
    final primaryConditioningLabel = SportDefaults.primaryConditioningLabel(
      l10n: l10n,
      sportId: sportId,
    );
    final secondaryConditioningLabel = SportDefaults.secondaryConditioningLabel(
      l10n: l10n,
      sportId: sportId,
    );
    final isCurrentRound = round.isToday && !round.completed;
    final activeGreen = theme.brightness == Brightness.dark
        ? const Color(0xFF63C986)
        : const Color(0xFF2E7D32);
    final missionProgressPercent = (round.missionCompletionRate * 100).round();
    return Container(
      padding: AppSpacing.card,
      decoration: AppSurfaces.subtleDecoration(
        theme.colorScheme,
        theme.brightness,
        accent: isCurrentRound ? activeGreen : theme.colorScheme.primary,
        accentAlpha: isCurrentRound ? 0.14 : 0.08,
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
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  [
                    l10n.challengeMissionCount(
                      round.completedMissionCount,
                      round.missionCount,
                    ),
                    l10n.challengeProgressPercent(missionProgressPercent),
                  ].join(' · '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.challengeRoundXpLabel(
                  _challengePotentialRoundXp(progress, round),
                ),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ChallengeQuietProgressBar(
            progress: round.missionCompletionRate,
            semanticsLabel: l10n.challengeProgressPercent(
              missionProgressPercent,
            ),
          ),
          const SizedBox(height: 4),
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
                key: const ValueKey('challenge-mission-training'),
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
                onTap: readOnly ? null : () => onOpenTraining(progress, round),
              )
            else
              for (final program in round.trainingPrograms) ...[
                _MissionProgressRow(
                  key: ValueKey(
                    'challenge-mission-program-${program.programId}',
                  ),
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
                      : () => onOpenTraining(
                            progress,
                            round,
                            program: program,
                          ),
                ),
                if (program != round.trainingPrograms.last)
                  const SizedBox(height: 10),
              ],
          ],
          if (round.round.targetJumpRopeMinutes > 0) ...[
            const SizedBox(height: 10),
            _MissionProgressRow(
              key: const ValueKey('challenge-mission-jump-rope'),
              icon: sportPrimaryConditioningIcon(sportId),
              label: primaryConditioningLabel,
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
              onTap: readOnly ? null : () => onOpenJumpRope(progress, round),
            ),
          ],
          if (round.round.targetLiftingMinutes > 0) ...[
            const SizedBox(height: 10),
            _MissionProgressRow(
              key: const ValueKey('challenge-mission-lifting'),
              icon: sportSecondaryConditioningIcon(sportId),
              label: secondaryConditioningLabel,
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
              onTap: readOnly ? null : () => onOpenLifting(progress, round),
            ),
          ],
          if (round.round.targetRiceBowls > 0) ...[
            const SizedBox(height: 10),
            _MissionProgressRow(
              key: const ValueKey('challenge-mission-meal'),
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
              onTap: readOnly ? null : () => onOpenMeal(progress, round),
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

class _ChallengeListHeader extends StatelessWidget {
  final int count;

  const _ChallengeListHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.challengeListTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.challengeListBody(count),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ChallengeListCard extends StatelessWidget {
  final ChallengeProgress progress;
  final String templateTitle;
  final bool readOnly;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  const _ChallengeListCard({
    required this.progress,
    required this.templateTitle,
    required this.readOnly,
    required this.onOpen,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ready = !progress.run.isStarted;
    final activeRound = progress.activeRound;
    final progressPercent = (progress.completionRate * 100).round();
    final period = ready
        ? l10n.challengeReadyPeriodLabel
        : _challengePeriodLabel(context, progress);
    final activeRoundLabel = ready
        ? l10n.challengeReadyBadge
        : activeRound == null
            ? l10n.challengeCompletedSummary(templateTitle)
            : activeRound.isToday
                ? l10n.challengeTodayRoundTitle(activeRound.round.number)
                : l10n.challengeUpcomingRoundTitle(activeRound.round.number);
    return Material(
      key: ValueKey('challenge-list-card-${progress.run.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: AppSurfaces.subtleDecoration(
            scheme,
            theme.brightness,
            accent: scheme.primary,
            accentAlpha: 0.08,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChallengeCurrentRoundBadge(
                    round: activeRound,
                    ready: ready,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          templateTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            activeRoundLabel,
                            _challengeCadenceLabel(
                              l10n,
                              progress.run.normalizedCadenceDays,
                            ),
                          ].join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          period,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.76,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (progress.run.hasRewardGift) ...[
                const SizedBox(height: 12),
                _ChallengeRewardGiftNotice(
                  rewardGift: progress.run.rewardGift,
                ),
              ],
              const SizedBox(height: 12),
              _ChallengeQuietProgressBar(
                progress: progress.completionRate,
                semanticsLabel: l10n.challengeProgressPercent(progressPercent),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        l10n.challengeRoundCount(
                          progress.completedRoundCount,
                          progress.totalRoundCount,
                        ),
                        l10n.challengeProgressPercent(progressPercent),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: Text(l10n.challengeDetailAction),
                  ),
                  if (!readOnly)
                    IconButton(
                      tooltip: l10n.challengeEditAction,
                      onPressed: onEdit,
                      icon: const Icon(Icons.tune_rounded),
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

class _ChallengeCurrentRoundBadge extends StatelessWidget {
  final ChallengeRoundProgress? round;
  final bool ready;

  const _ChallengeCurrentRoundBadge({
    required this.round,
    this.ready = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final round = this.round;
    const size = 62.0;
    final activeGreen = theme.brightness == Brightness.dark
        ? const Color(0xFF63C986)
        : const Color(0xFF2E7D32);
    final inProgress =
        !ready && round != null && round.isToday && !round.completed;
    final progress = ready
        ? 0.08
        : round == null
            ? 1.0
            : round.missionCompletionRate.clamp(0.08, 1).toDouble();
    final label = ready
        ? l10n.challengeReadyBadge
        : round == null
            ? l10n.challengeCompletedBadge
            : inProgress
                ? l10n.challengePendingBadge
                : round.isToday
                    ? l10n.challengeRoundDateToday
                    : l10n.challengeRoundTitle(round.round.number);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: activeGreen.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.18 : 0.12,
        ),
        borderRadius: BorderRadius.circular(size * 0.29),
        border: Border.all(color: activeGreen.withValues(alpha: 0.42)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: size * 0.68,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: size * 0.064,
              backgroundColor: activeGreen.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(activeGreen),
            ),
          ),
          Container(
            width: size * 0.50,
            height: size * 0.50,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.84),
              shape: BoxShape.circle,
            ),
            child: Icon(
              ready
                  ? Icons.hourglass_empty_rounded
                  : round == null
                      ? Icons.emoji_events_rounded
                      : inProgress
                          ? Icons.radio_button_checked_rounded
                          : Icons.flag_rounded,
              color: activeGreen,
              size: size * 0.34,
            ),
          ),
          PositionedDirectional(
            top: size * 0.11,
            end: size * 0.13,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: scheme.tertiary,
              size: size * 0.23,
            ),
          ),
          PositionedDirectional(
            bottom: size * 0.10,
            start: size * 0.10,
            end: size * 0.10,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: activeGreen,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeDetailActions extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ChallengeDetailActions({required this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onEdit = this.onEdit;
    final onDelete = this.onDelete;
    if (onEdit == null && onDelete == null) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onDelete != null) ...[
          OutlinedButton.icon(
            key: const ValueKey('challenge-delete-pending-button'),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(l10n.challengeDeletePendingAction),
          ),
          const SizedBox(width: 8),
        ],
        if (onEdit != null)
          OutlinedButton.icon(
            key: const ValueKey('challenge-edit-button'),
            onPressed: onEdit,
            icon: const Icon(Icons.tune_rounded),
            label: Text(l10n.challengeEditAction),
          ),
      ],
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
    final earnedXp = _challengeEarnedTotalXp(progress);
    final totalPotentialXp = challengeTotalPotentialXpFor(
      progress.template,
      progress.run.trainingLevel,
    );
    final progressPercent = (progress.completionRate * 100).round();
    if (rounds.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      key: const ValueKey('challenge-rounds-calendar'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.subtleDecoration(
        theme.colorScheme,
        theme.brightness,
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (onAbandon != null)
                IconButton(
                  tooltip: l10n.challengeAbandonAction,
                  onPressed: onAbandon,
                  icon: const Icon(Icons.stop_circle_outlined),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              l10n.challengeRoundCount(
                progress.completedRoundCount,
                progress.totalRoundCount,
              ),
              l10n.challengeProgressPercent(progressPercent),
            ].join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _ChallengeQuietProgressBar(
            progress: progress.completionRate,
            semanticsLabel: l10n.challengeProgressPercent(progressPercent),
          ),
          const SizedBox(height: 8),
          Text(
            [
              '${l10n.challengeRewardGuideEarnedLabel} ${l10n.challengeRewardXp(earnedXp)}',
              l10n.challengeTotalXpLabel(totalPotentialXp),
            ].join(' · '),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
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

class _ChallengeQuietProgressBar extends StatelessWidget {
  final double progress;
  final String semanticsLabel;

  const _ChallengeQuietProgressBar({
    required this.progress,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final value = progress.clamp(0, 1).toDouble();
    return Semantics(
      label: semanticsLabel,
      child: ClipRRect(
        borderRadius: AppRadius.full,
        child: LinearProgressIndicator(
          value: value,
          minHeight: 7,
          backgroundColor: scheme.surfaceContainerHighest.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.72 : 0.9,
          ),
          valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
        ),
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
    final activeGreenContainer = theme.brightness == Brightness.dark
        ? const Color(0xFF123D24)
        : const Color(0xFFE2F7E8);
    final activeGreen = theme.brightness == Brightness.dark
        ? const Color(0xFF63C986)
        : const Color(0xFF2E7D32);
    final activeGreenForeground = theme.brightness == Brightness.dark
        ? const Color(0xFFBDF4CD)
        : const Color(0xFF0F3D1D);
    final completed = round.completed;
    final missed = round.isMissed;
    final current = round.isToday && !completed && !missed;
    final bgColor = completed
        ? scheme.primaryContainer.withValues(alpha: 0.68)
        : missed
            ? scheme.errorContainer.withValues(alpha: 0.62)
            : current
                ? activeGreenContainer
                : scheme.surfaceContainerHighest.withValues(alpha: 0.62);
    final borderColor = completed
        ? scheme.primary.withValues(alpha: 0.62)
        : missed
            ? scheme.error.withValues(alpha: 0.60)
            : current
                ? activeGreen.withValues(alpha: 0.72)
                : scheme.outline.withValues(alpha: 0.32);
    final foreground = completed
        ? scheme.onPrimaryContainer
        : missed
            ? scheme.onErrorContainer
            : current
                ? activeGreenForeground
                : scheme.onSurfaceVariant;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final weekday = DateFormat.E(localeName).format(round.date);

    return Semantics(
      label: '${l10n.challengeRoundTitle(round.round.number)}, '
          '${_roundSubtitle(context, round)}',
      child: AnimatedContainer(
        key: ValueKey('challenge-calendar-round-${round.round.number}'),
        duration: AppMotion.base(context),
        curve: AppMotion.curveEnter,
        padding: EdgeInsets.all(completed || missed || current ? 2 : 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: completed || missed || current ? 1.8 : 1,
          ),
          boxShadow: current
              ? [
                  BoxShadow(
                    color: activeGreen.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shortestSide = constraints.biggest.shortestSide;
            final mascotSize = completed || missed || current
                ? (shortestSide * 0.96).clamp(30.0, 96.0)
                : (shortestSide * 0.62).clamp(26.0, 52.0);
            if (completed) {
              return Center(
                child: _RoundCalendarRinzyCelebration(size: mascotSize),
              );
            }
            if (missed) {
              return Center(
                child: SizedBox.square(
                  dimension: mascotSize,
                  child: ChallengeSadRinzyMascot(size: mascotSize),
                ),
              );
            }
            if (current) {
              return _ChallengeRoundCurrentMarker(
                round: round,
                weekday: weekday,
                foreground: foreground,
                activeGreen: activeGreen,
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

class _ChallengeRoundCurrentMarker extends StatelessWidget {
  final ChallengeRoundProgress round;
  final String weekday;
  final Color foreground;
  final Color activeGreen;

  const _ChallengeRoundCurrentMarker({
    required this.round,
    required this.weekday,
    required this.foreground,
    required this.activeGreen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final progress = round.missionCompletionRate.clamp(0.08, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final markerSize = constraints.biggest.shortestSide
                      .clamp(28.0, 54.0)
                      .toDouble();
                  return SizedBox.square(
                    key: ValueKey(
                      'challenge-current-round-status-${round.round.number}',
                    ),
                    dimension: markerSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.square(
                          dimension: markerSize,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: markerSize * 0.09,
                            backgroundColor: activeGreen.withValues(
                              alpha: 0.14,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              activeGreen,
                            ),
                          ),
                        ),
                        Container(
                          key: ValueKey(
                            'challenge-current-round-cute-marker-${round.round.number}',
                          ),
                          width: markerSize * 0.62,
                          height: markerSize * 0.62,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.86,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.radio_button_checked_rounded,
                            color: activeGreen,
                            size: markerSize * 0.38,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              l10n.challengePendingBadge,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundCalendarRinzyCelebration extends StatelessWidget {
  final double size;

  const _RoundCalendarRinzyCelebration({required this.size});

  @override
  Widget build(BuildContext context) {
    return ChallengeCheerRinzyMascot(
      size: size,
      progress: 1,
      animate: true,
      showCheerSticks: true,
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
    super.key,
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
                          ChallengeSadRinzyMascot(
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

class _ChallengeCompletedMissionSummary {
  final IconData icon;
  final String label;
  final String value;

  const _ChallengeCompletedMissionSummary({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _ChallengeCompletedMissionPanel extends StatelessWidget {
  final List<_ChallengeCompletedMissionSummary> summaries;

  const _ChallengeCompletedMissionPanel({required this.summaries});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.challengeCelebrationMissionsTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final summary in summaries)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.40),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(summary.icon, size: 17, color: scheme.primary),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 190),
                      child: Text(
                        '${summary.label} · ${summary.value}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChallengeGiftReceiveVisual extends StatelessWidget {
  final String gift;
  final double mascotSize;

  const _ChallengeGiftReceiveVisual({
    required this.gift,
    required this.mascotSize,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visualHeight = (mascotSize + 46).clamp(188.0, 268.0).toDouble();
    final giftBoxSize = (mascotSize * 0.42).clamp(68.0, 92.0).toDouble();
    return SizedBox(
      height: visualHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 10,
            child: ChallengeCheerRinzyMascot(
              size: mascotSize,
              progress: 1,
              useImage: true,
            ),
          ),
          PositionedDirectional(
            end: 8,
            bottom: 2,
            child: Container(
              width: giftBoxSize,
              height: giftBoxSize,
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: scheme.tertiary.withValues(alpha: 0.35),
                  width: 1.4,
                ),
                boxShadow: AppShadows.surface(theme.brightness),
              ),
              child: Icon(
                Icons.card_giftcard_rounded,
                color: scheme.onTertiaryContainer,
                size: giftBoxSize * 0.52,
              ),
            ),
          ),
          PositionedDirectional(
            start: 8,
            top: 2,
            child: Container(
              constraints: BoxConstraints(maxWidth: mascotSize * 0.84),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.redeem_rounded,
                    size: 17,
                    color: scheme.tertiary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.challengeRewardGiftPill(gift),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCelebrationScreen extends StatelessWidget {
  final int gainedXp;
  final int awardedRoundCount;
  final bool challengeCompleted;
  final String rewardGift;
  final int roundGainedXp;
  final int completionGainedXp;
  final List<_ChallengeCompletedMissionSummary> missionSummaries;

  const _ChallengeCelebrationScreen({
    required this.gainedXp,
    required this.awardedRoundCount,
    required this.challengeCompleted,
    this.rewardGift = '',
    required this.roundGainedXp,
    required this.completionGainedXp,
    required this.missionSummaries,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final completedRewardGift = challengeCompleted ? rewardGift.trim() : '';
    final showsGiftReceiveScreen = completedRewardGift.isNotEmpty;
    final title = showsGiftReceiveScreen
        ? l10n.challengeGiftReceiveTitle
        : challengeCompleted
            ? l10n.challengeCelebrationCompleteTitle
            : l10n.challengeCelebrationTitle;
    final body = showsGiftReceiveScreen
        ? l10n.challengeGiftReceiveBody(completedRewardGift)
        : challengeCompleted
            ? (gainedXp > 0
                ? l10n.challengeCelebrationCompleteBody(gainedXp)
                : l10n.challengeCelebrationCompleteBodyNoXp)
            : (gainedXp > 0
                ? l10n.challengeCelebrationBody(awardedRoundCount, gainedXp)
                : l10n.challengeCelebrationBodyNoXp);
    final actionLabel = showsGiftReceiveScreen
        ? l10n.challengeGiftReceiveAction
        : challengeCompleted
            ? l10n.challengeCelebrationNextChallengeAction
            : l10n.challengeCelebrationAction;
    final actionIcon = showsGiftReceiveScreen
        ? Icons.card_giftcard_rounded
        : challengeCompleted
            ? Icons.add_task_rounded
            : Icons.celebration_outlined;
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
                          borderRadius: AppRadius.surface,
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.56,
                            ),
                          ),
                          boxShadow: AppShadows.surface(theme.brightness),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showsGiftReceiveScreen)
                              _ChallengeGiftReceiveVisual(
                                gift: completedRewardGift,
                                mascotSize: mascotSize,
                              )
                            else
                              ChallengeCheerRinzyMascot(
                                size: mascotSize,
                                progress: 1,
                                useImage: true,
                              ),
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
                            if (missionSummaries.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              _ChallengeCompletedMissionPanel(
                                summaries: missionSummaries,
                              ),
                            ],
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
                    icon: Icon(actionIcon),
                    label: Text(actionLabel),
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

List<_ChallengeCompletedMissionSummary> _completedMissionSummariesForRounds(
  AppLocalizations l10n,
  String sportId,
  Iterable<ChallengeRoundProgress> rounds,
) {
  final summaries = <String, _ChallengeCompletedMissionSummary>{};
  final primaryConditioningLabel = SportDefaults.primaryConditioningLabel(
    l10n: l10n,
    sportId: sportId,
  );
  final secondaryConditioningLabel = SportDefaults.secondaryConditioningLabel(
    l10n: l10n,
    sportId: sportId,
  );

  void put({
    required String key,
    required IconData icon,
    required String label,
    required String value,
  }) {
    summaries[key] = _ChallengeCompletedMissionSummary(
      icon: icon,
      label: label,
      value: value,
    );
  }

  for (final round in rounds) {
    if (round.round.targetTrainingMinutes > 0 && round.trainingCompleted) {
      if (round.trainingPrograms.isEmpty) {
        put(
          key: 'training',
          icon: Icons.sports_soccer_outlined,
          label: l10n.challengeTrainingProgramMissionLabel,
          value: _minutesGoalValue(
            l10n,
            round.trainingMinutes,
            round.round.targetTrainingMinutes,
          ),
        );
      } else {
        for (final program in round.trainingPrograms) {
          if (!program.completed) continue;
          put(
            key: 'program:${program.programId}',
            icon: Icons.sports_soccer_outlined,
            label: program.label,
            value: _minutesGoalValue(
              l10n,
              program.currentMinutes,
              program.targetMinutes,
            ),
          );
        }
      }
    }
    if (round.round.targetJumpRopeMinutes > 0 && round.jumpRopeCompleted) {
      put(
        key: 'jumpRope',
        icon: sportPrimaryConditioningIcon(sportId),
        label: primaryConditioningLabel,
        value: _minutesGoalValue(
          l10n,
          round.jumpRopeMinutes,
          round.round.targetJumpRopeMinutes,
        ),
      );
    }
    if (round.round.targetLiftingMinutes > 0 && round.liftingCompleted) {
      put(
        key: 'lifting',
        icon: sportSecondaryConditioningIcon(sportId),
        label: secondaryConditioningLabel,
        value: _minutesGoalValue(
          l10n,
          round.liftingMinutes,
          round.round.targetLiftingMinutes,
        ),
      );
    }
    if (round.round.targetRiceBowls > 0 && round.mealCompleted) {
      put(
        key: 'meal',
        icon: Icons.rice_bowl_outlined,
        label: l10n.challengeMealLabel,
        value: l10n.challengeMealGoalValue(
          _formatBowls(round.riceBowls),
          _formatBowls(round.round.targetRiceBowls),
        ),
      );
    }
  }

  return summaries.values.toList(growable: false);
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
  ChallengeTemplate template,
  int roundNumber,
) {
  if (_historyRoundCompleted(run, template, roundNumber)) {
    return l10n.challengeHistoryDetailRoundCompleted;
  }
  if (_historyRoundFailed(run, template, roundNumber)) {
    return l10n.challengeHistoryDetailRoundFailed;
  }
  if (run.isAbandoned || run.isFailed) {
    return l10n.challengeHistoryDetailRoundEnded;
  }
  return l10n.challengePendingBadge;
}

bool _historyRoundCompleted(
  ChallengeRun run,
  ChallengeTemplate template,
  int roundNumber,
) {
  return _historyCompletedRoundNumbers(run, template).contains(roundNumber);
}

bool _historyRoundFailed(
  ChallengeRun run,
  ChallengeTemplate template,
  int roundNumber,
) {
  if (!run.isFailed || roundNumber < 1 || roundNumber > template.dayCount) {
    return false;
  }
  return !_historyRoundCompleted(run, template, roundNumber);
}

int _historyCompletedRoundCount(ChallengeRun run, ChallengeTemplate? template) {
  if (template == null) return 0;
  return _historyCompletedRoundNumbers(run, template).length;
}

Set<int> _historyCompletedRoundNumbers(
  ChallengeRun run,
  ChallengeTemplate template,
) {
  final stored = run.completedRoundNumbers
      .where((round) => round >= 1 && round <= template.dayCount)
      .toSet();
  if (stored.isNotEmpty) return stored;
  if (run.isCompleted) {
    return Set<int>.from(
      List<int>.generate(template.dayCount, (index) => index + 1),
    );
  }
  if (run.isFailed && run.failedRoundNumber != null) {
    final lastCompleted =
        (run.failedRoundNumber! - 1).clamp(0, template.dayCount).toInt();
    return Set<int>.from(
      List<int>.generate(lastCompleted, (index) => index + 1),
    );
  }
  return const <int>{};
}

int _historyFailedRoundCount(ChallengeRun run, ChallengeTemplate? template) {
  if (template == null || !run.isFailed) return 0;
  final completed = _historyCompletedRoundCount(run, template);
  return (template.dayCount - completed).clamp(0, template.dayCount).toInt();
}

int _historyRoundTotal(Iterable<ChallengeRun> runs) {
  return runs.fold<int>(
    0,
    (sum, run) => sum + (_challengeTemplateForRun(run)?.dayCount ?? 0),
  );
}

int _historyCompletedRoundTotal(Iterable<ChallengeRun> runs) {
  return runs.fold<int>(
    0,
    (sum, run) =>
        sum + _historyCompletedRoundCount(run, _challengeTemplateForRun(run)),
  );
}

int _historyFailedRoundTotal(Iterable<ChallengeRun> runs) {
  return runs.fold<int>(
    0,
    (sum, run) =>
        sum + _historyFailedRoundCount(run, _challengeTemplateForRun(run)),
  );
}

int _historyEarnedXpForRun(ChallengeRun run, ChallengeTemplate template) {
  final completedRoundNumbers = _historyCompletedRoundNumbers(run, template);
  if (completedRoundNumbers.isEmpty && !run.isCompleted) return 0;
  final config = trainingLevelConfig(run.trainingLevel);
  var total = 0;
  var consecutiveRoundNumber = 0;
  for (var roundNumber = 1; roundNumber <= template.dayCount; roundNumber++) {
    if (!completedRoundNumbers.contains(roundNumber)) {
      consecutiveRoundNumber = 0;
      continue;
    }
    consecutiveRoundNumber += 1;
    total += challengeRoundRewardXpFor(
      baseRewardXp: config.rewardXpPerRound,
      consecutiveRoundNumber: consecutiveRoundNumber,
    );
  }
  if (run.isCompleted) {
    total += challengeCompletionBonusXpFor(template, run.trainingLevel);
  }
  return total;
}

int _historyRoundStreakFor(
  ChallengeRun run,
  ChallengeTemplate template,
  int roundNumber,
) {
  final completedRoundNumbers = _historyCompletedRoundNumbers(run, template);
  var streak = 0;
  for (var current = 1; current <= roundNumber; current++) {
    if (completedRoundNumbers.contains(current)) {
      streak += 1;
    } else {
      streak = 0;
    }
  }
  return streak;
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

int _challengeEarnedTotalXp(ChallengeProgress progress) {
  final roundXp = _challengeEarnedRoundXp(progress);
  if (!progress.allRoundsCompleted) return roundXp;
  return roundXp +
      challengeCompletionBonusXpFor(
        progress.template,
        progress.run.trainingLevel,
      );
}

int _challengeEarnedRoundXpForCompletedRounds({
  required ChallengeTemplate template,
  required ChallengeTrainingLevel level,
  required Set<int> completedRoundNumbers,
}) {
  final config = trainingLevelConfig(level);
  var total = 0;
  var consecutiveRoundNumber = 0;
  for (var roundNumber = 1; roundNumber <= template.dayCount; roundNumber++) {
    if (!completedRoundNumbers.contains(roundNumber)) {
      consecutiveRoundNumber = 0;
      continue;
    }
    consecutiveRoundNumber += 1;
    total += challengeRoundRewardXpFor(
      baseRewardXp: config.rewardXpPerRound,
      consecutiveRoundNumber: consecutiveRoundNumber,
    );
  }
  return total;
}

int _challengePotentialRoundXp(
  ChallengeProgress progress,
  ChallengeRoundProgress targetRound,
) {
  var consecutiveRoundNumber = 0;
  for (final round in progress.rounds) {
    final isTarget = round.round.number == targetRound.round.number;
    if (isTarget) {
      final potentialStreak = consecutiveRoundNumber + 1;
      return challengeRoundRewardXpFor(
        baseRewardXp: round.round.rewardXp,
        consecutiveRoundNumber: potentialStreak,
      );
    }
    if (round.completed) {
      consecutiveRoundNumber += 1;
    } else {
      consecutiveRoundNumber = 0;
    }
  }
  return targetRound.round.rewardXp;
}

bool _progressRoundCompleted(ChallengeProgress? progress, int roundNumber) {
  if (progress == null) return false;
  for (final round in progress.rounds) {
    if (round.round.number == roundNumber) return round.completed;
  }
  return false;
}

List<_ChallengeSkillOption> _challengeProgramSkillOptions(
  AppLocalizations l10n,
  OptionRepository optionRepository,
) {
  final sportId = SportService(optionRepository).currentSportId();
  final programOptionsKey = SportCatalog.optionKey(
    'programs',
    sportId: sportId,
  );
  final defaults = SportDefaults.programOptions(l10n: l10n, sportId: sportId);
  final stored = optionRepository.getOptions(programOptionsKey, defaults);
  final normalized = LocalizedOptionDefaults.normalizeOptions(
    key: programOptionsKey,
    stored: stored,
    localizedDefaults: defaults,
  );
  if (!_sameStringList(stored, normalized)) {
    unawaited(optionRepository.saveOptions(programOptionsKey, normalized));
  }
  final seen = <String>{};
  final programs = <String>[];
  final primaryConditioningLabel = SportDefaults.primaryConditioningLabel(
    l10n: l10n,
    sportId: sportId,
  );
  final secondaryConditioningLabel = SportDefaults.secondaryConditioningLabel(
    l10n: l10n,
    sportId: sportId,
  );
  final standaloneMissionLabels = <String>{
    l10n.challengeJumpRopeLabel.trim(),
    l10n.challengeLiftingLabel.trim(),
    primaryConditioningLabel.trim(),
    secondaryConditioningLabel.trim(),
  };
  for (final program in normalized) {
    final trimmed = program.trim();
    if (trimmed.isEmpty ||
        seen.contains(trimmed) ||
        standaloneMissionLabels.contains(trimmed)) {
      continue;
    }
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
