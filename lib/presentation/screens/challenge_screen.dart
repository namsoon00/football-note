import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../application/backup_service.dart';
import '../../application/challenge_service.dart';
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
  bool _reminderSyncInFlight = false;
  String? _lastFinalizeSignature;
  String? _lastReminderSignature;

  @override
  void initState() {
    super.initState();
    _challengeService = ChallengeService(widget.optionRepository);
    _settingsService = widget.settingsService..load();
    _reminderService = TrainingPlanReminderService(
      widget.optionRepository,
      _settingsService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.challengeTitle),
        actions: [
          IconButton(
            tooltip: l10n.challengeHistoryTitle,
            onPressed: _openHistory,
            icon: const Icon(Icons.history),
          ),
        ],
      ),
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
                    _scheduleFinalizeSync(progress);
                  }
                  _scheduleChallengeReminderSync(progress);
                  final skillOptions = _challengeProgramSkillOptions(
                    l10n,
                    widget.optionRepository,
                  );
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      if (progress == null)
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
    final completedRounds = progress.rounds
        .where((round) => round.completed)
        .map((round) => round.round.number)
        .join(',');
    final signature =
        '${progress.run.id}:finalize:$completedRounds:${progress.rounds.length}';
    if (_finalizeInFlight || _lastFinalizeSignature == signature) return;
    _lastFinalizeSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_syncFinalization(progress, signature));
    });
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
      if (!mounted) return;
      if (!progress.allRoundsCompleted) {
        _playChallengeSuccessFeedback();
        await Navigator.of(context).push(
          AppPageRoute<void>(
            builder: (_) => _ChallengeFailureScreen(
              failedRoundNumber:
                  progress.firstIncompleteRound?.round.number ??
                  progress.rounds.length,
              gainedXp: gainedXp,
            ),
          ),
        );
      } else if (gainedXp > 0) {
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

  Future<void> _startChallenge(
    ChallengeTemplate template,
    List<String> selectedSkillIds,
    ChallengeMissionTargets missionTargets,
  ) async {
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
    _playChallengeTapFeedback();
    final navigator = Navigator.of(context);
    final existingEntry = await _trainingEntryForRound(
      round.date,
      programId: programMission?.programId,
    );
    if (!mounted) return;
    final remainingProgramMinutes = programMission == null
        ? 0
        : (programMission.targetMinutes - programMission.currentMinutes).clamp(
            0,
            programMission.targetMinutes,
          );
    final initialPlanContext = existingEntry == null && programMission != null
        ? EntryFormInitialPlanContext(
            scheduledAt: round.date,
            program: programMission.label,
            durationMinutes: remainingProgramMinutes > 0
                ? remainingProgramMinutes
                : programMission.targetMinutes,
          )
        : null;
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
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<TrainingEntry?> _trainingEntryForRound(
    DateTime day, {
    String? programId,
  }) async {
    final normalizedDay = normalizeDay(day);
    final targetProgram = programId?.trim();
    final entries = await widget.trainingService.allEntries();
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
    if (mounted) setState(() {});
  }

  Future<void> _openTrainingProgramSetup() async {
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

class _ChallengeHistoryScreen extends StatelessWidget {
  final List<ChallengeRun> runs;

  const _ChallengeHistoryScreen({required this.runs});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.challengeHistoryTitle)),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [_ChallengeHistorySection(runs: runs, showTitle: false)],
          ),
        ),
      ),
    );
  }
}

class _ChallengeHistorySection extends StatelessWidget {
  final List<ChallengeRun> runs;
  final bool showTitle;

  const _ChallengeHistorySection({required this.runs, this.showTitle = true});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shownRuns = runs.take(8).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          Text(
            l10n.challengeHistoryTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
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

  const _ChallengeHistoryTile({required this.run, required this.title});

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
  final VoidCallback onAbandon;
  final _OpenChallengeTrainingMission onOpenTraining;
  final ValueChanged<ChallengeRoundProgress> onOpenJumpRope;
  final ValueChanged<ChallengeRoundProgress> onOpenLifting;
  final ValueChanged<ChallengeRoundProgress> onOpenMeal;
  final VoidCallback onOpenTrainingPrograms;

  const _ActiveChallengeSection({
    required this.progress,
    required this.templateTitle,
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
        _ChallengeRoundsCalendar(progress: progress, onAbandon: onAbandon),
        const SizedBox(height: 18),
        if (activeRound != null)
          _RoundFocusCard(
            progress: progress,
            round: activeRound,
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
  final _OpenChallengeTrainingMission onOpenTraining;
  final ValueChanged<ChallengeRoundProgress> onOpenJumpRope;
  final ValueChanged<ChallengeRoundProgress> onOpenLifting;
  final ValueChanged<ChallengeRoundProgress> onOpenMeal;
  final VoidCallback onOpenTrainingPrograms;

  const _RoundFocusCard({
    required this.progress,
    required this.round,
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
    final potentialXp = challengeTotalPotentialXpFor(
      progress.template,
      progress.run.trainingLevel,
    );
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
          const SizedBox(height: 12),
          _ChallengeInfoGrid(
            items: [
              _ChallengeInfoItem(
                icon: Icons.flag_outlined,
                label: l10n.challengeInfoStatusLabel,
                value:
                    '${round.completedMissionCount}/${round.missionCount} · '
                    '${round.completed ? l10n.challengeCompletedBadge : l10n.challengePendingBadge}',
              ),
              _ChallengeInfoItem(
                icon: Icons.star_border_rounded,
                label: l10n.challengeInfoRoundXpLabel,
                value: l10n.challengeRewardXp(round.round.rewardXp),
              ),
              _ChallengeInfoItem(
                icon: Icons.workspace_premium_outlined,
                label: l10n.challengeInfoPotentialXpLabel,
                value: l10n.challengeRewardXp(potentialXp),
              ),
            ],
          ),
          if (!round.isToday) ...[
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
                onTap: () => onOpenTraining(round),
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
                  onTap: () => onOpenTraining(round, program: program),
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
              onTap: () => onOpenJumpRope(round),
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
              onTap: () => onOpenLifting(round),
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
              onTap: () => onOpenMeal(round),
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
  final VoidCallback onAbandon;

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
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final startDate = rounds.first.date;
    final endDate = rounds.last.date;
    final calendarTitle =
        startDate.year == endDate.year && startDate.month == endDate.month
        ? DateFormat.yMMMM(localeName).format(startDate)
        : '${DateFormat.yMMMd(localeName).format(startDate)} - '
              '${DateFormat.yMMMd(localeName).format(endDate)}';
    final percent = (progress.completionRate * 100).round();
    final potentialXp = challengeTotalPotentialXpFor(
      progress.template,
      progress.run.trainingLevel,
    );
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
              TextButton.icon(
                onPressed: onAbandon,
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(l10n.challengeAbandonAction),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ChallengeInfoGrid(
            items: [
              _ChallengeInfoItem(
                icon: Icons.date_range_outlined,
                label: l10n.challengeInfoPeriodLabel,
                value: calendarTitle,
              ),
              _ChallengeInfoItem(
                icon: Icons.done_all_rounded,
                label: l10n.challengeInfoRoundProgressLabel,
                value: l10n.challengeRoundCount(
                  progress.completedRoundCount,
                  progress.totalRoundCount,
                ),
              ),
              _ChallengeInfoItem(
                icon: Icons.workspace_premium_outlined,
                label: l10n.challengeInfoPotentialXpLabel,
                value: l10n.challengeRewardXp(potentialXp),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ChallengeGauge(progress: progress.completionRate),
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              l10n.challengeProgressPercent(percent),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
              final crossAxisCount = _challengeRoundColumnCount(
                rounds.length,
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
                    rounds.length,
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

int _challengeRoundColumnCount(int roundCount, {required bool compact}) {
  if (roundCount <= 3) return roundCount.clamp(1, 3).toInt();
  if (roundCount <= 5) return compact ? 3 : roundCount;
  if (roundCount <= DateTime.daysPerWeek) {
    return compact ? 4 : DateTime.daysPerWeek;
  }
  return compact ? 4 : DateTime.daysPerWeek;
}

double _challengeRoundAspectRatio(int roundCount, {required bool compact}) {
  if (roundCount <= 3) return compact ? 0.82 : 1.0;
  if (roundCount <= 5) return compact ? 0.82 : 0.92;
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
    final statusLabel = completed
        ? l10n.challengeCompletedBadge
        : missed
        ? l10n.challengeHistoryResultFailed
        : l10n.challengePendingBadge;
    final missionCountLabel =
        '${round.completedMissionCount}/${round.missionCount}';

    return Semantics(
      label:
          '${l10n.challengeRoundTitle(round.round.number)}, '
          '${_roundSubtitle(context, round)}, '
          '$missionCountLabel, '
          '$statusLabel',
      child: AnimatedContainer(
        key: ValueKey('challenge-calendar-round-${round.round.number}'),
        duration: AppMotion.base(context),
        curve: AppMotion.curveEnter,
        padding: EdgeInsets.all(completed ? 2 : 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: completed ? 1.6 : 1),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shortestSide = constraints.biggest.shortestSide;
            final mascotSize = completed
                ? (shortestSide * 0.96).clamp(30.0, 96.0)
                : (constraints.maxWidth * 0.58).clamp(34.0, 56.0);
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
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$missionCountLabel · $statusLabel',
                    maxLines: 1,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: foreground.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final reduceMotion = AppMotion.reduceMotion(context);
    final missionCountLabel =
        '${round.completedMissionCount}/${round.missionCount}';
    final statusLabel = failed
        ? l10n.challengeHistoryResultFailed
        : l10n.challengePendingBadge;
    final progress = round.missionCompletionRate;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: size,
          child: failed
              ? CryingRinzyMascot(size: size, animate: !reduceMotion)
              : RinzyMascot(
                  size: size,
                  progress: progress,
                  animate: !reduceMotion,
                ),
        ),
        const SizedBox(height: 4),
        Text(
          'R${round.round.number}',
          maxLines: 1,
          textAlign: TextAlign.center,
          overflow: TextOverflow.clip,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$missionCountLabel · $statusLabel',
            maxLines: 1,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ],
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
  final VoidCallback onTap;

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
                showStartIcon: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeGauge extends StatelessWidget {
  final double progress;

  const _ChallengeGauge({required this.progress});

  @override
  Widget build(BuildContext context) {
    return ProgressStarGauge(progress: progress);
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
  final int failedRoundNumber;
  final int gainedXp;

  const _ChallengeFailureScreen({
    required this.failedRoundNumber,
    required this.gainedXp,
  });

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
                            ).width.clamp(220, 340).toDouble(),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.challengeFailureTitle(failedRoundNumber),
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
                          CheerRinzyMascot(
                            size: MediaQuery.sizeOf(
                              context,
                            ).width.clamp(240, 360).toDouble(),
                            progress: 1,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            body,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _SmallStatusPill(
                            label: l10n.challengeRewardXp(gainedXp),
                          ),
                        ],
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
