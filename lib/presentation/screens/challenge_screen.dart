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
import '../../application/player_profile_service.dart';
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
                          recommendedLevel: recommendedLevel,
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
              failedRoundNumber: progress.firstIncompleteRound?.round.number ??
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
    ChallengeTrainingLevel trainingLevel,
    List<String> selectedSkillIds,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    _playChallengeTapFeedback();
    await _challengeService.startChallenge(
      template,
      trainingLevel: trainingLevel,
      selectedSkillIds: selectedSkillIds,
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

  Future<void> _openTrainingMission(ChallengeRoundProgress round) {
    return _openTrainingEntryMission(round, initialFocusTarget: null);
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
  }) async {
    _playChallengeTapFeedback();
    final navigator = Navigator.of(context);
    final existingEntry = await _trainingEntryForRound(round.date);
    if (!mounted) return;
    await navigator.push(
      AppPageRoute<void>(
        builder: (_) => EntryFormScreen(
          trainingService: widget.trainingService,
          optionRepository: widget.optionRepository,
          localeService: widget.localeService,
          settingsService: _settingsService,
          driveBackupService: widget.driveBackupService,
          entry: existingEntry,
          initialDate: existingEntry == null ? round.date : null,
          initialFocusTarget: initialFocusTarget,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<TrainingEntry?> _trainingEntryForRound(DateTime day) async {
    final normalizedDay = normalizeDay(day);
    final entries = await widget.trainingService.allEntries();
    final sameDayEntries = entries
        .where(
          (entry) =>
              !entry.isMatch && normalizeDay(entry.date) == normalizedDay,
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
        builder: (_) => EntryFormScreen(
          trainingService: widget.trainingService,
          optionRepository: widget.optionRepository,
          localeService: widget.localeService,
          settingsService: _settingsService,
          driveBackupService: widget.driveBackupService,
          initialDate: DateTime.now(),
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
  final ChallengeTrainingLevel recommendedLevel;
  final String Function(ChallengeTemplate template) templateTitle;
  final String Function(ChallengeTemplate template) templateDescription;
  final List<_ChallengeSkillOption> skillOptions;
  final VoidCallback onOpenTrainingPrograms;
  final void Function(
    ChallengeTemplate template,
    ChallengeTrainingLevel trainingLevel,
    List<String> selectedSkillIds,
  ) onStart;

  const _ChallengeStartSection({
    required this.templates,
    required this.recommendedLevel,
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
  final GlobalKey _levelSectionKey = GlobalKey();
  final GlobalKey _readySectionKey = GlobalKey();
  ChallengeTemplate? _selectedTemplate;
  ChallengeTrainingLevel? _selectedLevel;
  late Set<String> _selectedSkillIds;

  @override
  void initState() {
    super.initState();
    _selectedSkillIds = _initialChallengeSkillSelection(widget.skillOptions);
  }

  @override
  void didUpdateWidget(_ChallengeStartSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recommendedLevel != widget.recommendedLevel) {
      _selectedLevel = null;
    }
    if (!_sameChallengeSkillOptions(
      oldWidget.skillOptions,
      widget.skillOptions,
    )) {
      final availableIds =
          widget.skillOptions.map((option) => option.id).toSet();
      _selectedSkillIds =
          _selectedSkillIds.where(availableIds.contains).toSet();
      if (_selectedSkillIds.isEmpty) {
        _selectedSkillIds = _initialChallengeSkillSelection(
          widget.skillOptions,
        );
      }
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
            onSelect: () => _selectTemplate(template),
          ),
          const SizedBox(height: 10),
        ],
        if (_selectedTemplate != null) ...[
          const SizedBox(height: 10),
          Text(
            l10n.challengeTrainingLevelTitle,
            key: _levelSectionKey,
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
              onSelect: () => _selectLevel(config.level),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          Text(
            l10n.challengeSkillSelectTitle,
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
          _ChallengeSkillPicker(
            options: widget.skillOptions,
            selectedSkillIds: _selectedSkillIds,
            onChanged: (ids) {
              setState(() => _selectedSkillIds = ids);
            },
          ),
          const SizedBox(height: 10),
          _TrainingProgramLinkCard(
            onOpenTrainingPrograms: widget.onOpenTrainingPrograms,
          ),
        ],
        if (_selectedTemplate != null && _selectedLevel != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.challengeStartReadyTitle,
            key: _readySectionKey,
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
            onPressed: () => widget.onStart(
              _selectedTemplate!,
              _selectedLevel!,
              normalizeChallengeSkillIds(_selectedSkillIds),
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
      _selectedLevel = null;
      _selectedSkillIds = _initialChallengeSkillSelection(widget.skillOptions);
    });
    _scrollTo(_levelSectionKey);
  }

  void _selectLevel(ChallengeTrainingLevel level) {
    setState(() => _selectedLevel = level);
    _scrollTo(_readySectionKey);
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
                accent.withValues(alpha: selected ? 0.22 : 0.12),
                theme.colorScheme.surface,
                const Color(0xFFFFD166).withValues(alpha: 0.10),
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
                    color:
                        selected ? accent : theme.colorScheme.onSurfaceVariant,
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
    final accent = _challengeLevelAccent(level);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('challenge-level-${level.name}'),
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: selected ? 0.20 : 0.10),
                theme.colorScheme.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? accent : theme.colorScheme.onSurfaceVariant,
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

class _ChallengeSkillPicker extends StatelessWidget {
  final List<_ChallengeSkillOption> options;
  final Set<String> selectedSkillIds;
  final ValueChanged<Set<String>> onChanged;

  const _ChallengeSkillPicker({
    required this.options,
    required this.selectedSkillIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          FilterChip(
            avatar: Icon(
              option.icon,
              size: 18,
              color: selectedSkillIds.contains(option.id)
                  ? option.color
                  : theme.colorScheme.onSurfaceVariant,
            ),
            label: Text(option.label),
            selected: selectedSkillIds.contains(option.id),
            selectedColor: option.color.withValues(alpha: 0.18),
            checkmarkColor: option.color,
            side: BorderSide(
              color: selectedSkillIds.contains(option.id)
                  ? option.color.withValues(alpha: 0.62)
                  : theme.colorScheme.outlineVariant,
            ),
            onSelected: (selected) {
              final next = Set<String>.from(selectedSkillIds);
              if (selected) {
                next.add(option.id);
              } else {
                next.remove(option.id);
              }
              if (next.isEmpty) return;
              onChanged(next);
            },
          ),
      ],
    );
  }
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
    const accent = Color(0xFFFF7A59);
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
                accent.withValues(alpha: 0.18),
                const Color(0xFF2DD4BF).withValues(alpha: 0.14),
                const Color(0xFFFFD166).withValues(alpha: 0.16),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.30)),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 36 : 42,
                height: compact ? 36 : 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.tune_rounded, color: accent),
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
              const Icon(Icons.chevron_right_rounded, color: accent),
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
            const Color(0xFFFFD166).withValues(alpha: 0.28),
            const Color(0xFF06D6A0).withValues(alpha: 0.16),
            const Color(0xFF7C4DFF).withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFB703).withValues(alpha: 0.38),
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
            const Color(0xFF06D6A0).withValues(alpha: 0.24),
            const Color(0xFFFFD166).withValues(alpha: 0.20),
            const Color(0xFFEF476F).withValues(alpha: 0.12),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF06D6A0).withValues(alpha: 0.34),
        ),
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
  final ValueChanged<ChallengeRoundProgress> onOpenTraining;
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
  final ValueChanged<ChallengeRoundProgress> onOpenTraining;
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
    final selectedSkills = _challengeSkillLabels(
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
            const Color(0xFF00A6A6).withValues(alpha: 0.18),
            const Color(0xFFFF7A59).withValues(alpha: 0.12),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00A6A6).withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 7,
                      children: [
                        _SmallStatusPill(
                          label: l10n.challengeActiveLevelPill(
                            _trainingLevelTitle(
                              l10n,
                              progress.run.trainingLevel,
                            ),
                          ),
                        ),
                        _SmallStatusPill(
                          label: l10n.challengePotentialXpPill(potentialXp),
                        ),
                        _SmallStatusPill(
                          label: l10n.challengeRoundXpLabel(
                            round.round.rewardXp,
                          ),
                        ),
                      ],
                    ),
                    if (selectedSkills.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          for (final skill in selectedSkills)
                            _SmallStatusPill(label: skill),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _SmallStatusPill(
                label: round.completed
                    ? l10n.challengeCompletedBadge
                    : l10n.challengePendingBadge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TrainingProgramLinkCard(
            onOpenTrainingPrograms: onOpenTrainingPrograms,
            compact: true,
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
            progress: _goalProgress(
              round.trainingMinutes,
              round.round.targetTrainingMinutes,
            ),
            completed: round.trainingCompleted,
            onTap: () => onOpenTraining(round),
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
            progress: _goalProgress(
              round.jumpRopeMinutes,
              round.round.targetJumpRopeMinutes,
            ),
            completed: round.jumpRopeCompleted,
            onTap: () => onOpenJumpRope(round),
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
            progress: _goalProgress(
              round.liftingMinutes,
              round.round.targetLiftingMinutes,
            ),
            completed: round.liftingCompleted,
            onTap: () => onOpenLifting(round),
          ),
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
            const Color(0xFF7C4DFF).withValues(alpha: 0.16),
            const Color(0xFFFFD166).withValues(alpha: 0.16),
            const Color(0xFF06D6A0).withValues(alpha: 0.12),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF7C4DFF).withValues(alpha: 0.26),
        ),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  calendarTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SmallStatusPill(
                label: l10n.challengeRoundCount(
                  progress.completedRoundCount,
                  progress.totalRoundCount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 7,
            children: [
              _SmallStatusPill(
                label: l10n.challengeActiveLevelPill(
                  _trainingLevelTitle(l10n, progress.run.trainingLevel),
                ),
              ),
              _SmallStatusPill(
                label: l10n.challengePotentialXpPill(potentialXp),
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

    return Semantics(
      label: '${l10n.challengeRoundTitle(round.round.number)}, '
          '${_roundSubtitle(context, round)}, '
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
                      missed
                          ? Icons.cancel_rounded
                          : round.isToday
                              ? Icons.flag_circle_outlined
                              : Icons.radio_button_unchecked,
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
                    statusLabel,
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
  final IconData icon;
  final String label;
  final String value;
  final double progress;
  final bool completed;
  final VoidCallback onTap;

  const _MissionProgressRow({
    required this.icon,
    required this.label,
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
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
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
  final title = switch (run.templateId) {
    'starter_3' => l10n.challengeTemplateStarterTitle,
    'weekly_7' => l10n.challengeTemplateWeeklyTitle,
    'focus_14' => l10n.challengeTemplateFocusTitle,
    _ => l10n.challengeTitle,
  };
  return '$title · ${_trainingLevelTitle(l10n, run.trainingLevel)}';
}

Color _challengeTemplateAccent(String templateId) {
  return switch (templateId) {
    'starter_3' => const Color(0xFF06D6A0),
    'weekly_7' => const Color(0xFFFF7A59),
    'focus_14' => const Color(0xFF7C4DFF),
    _ => const Color(0xFF00A6A6),
  };
}

Color _challengeLevelAccent(ChallengeTrainingLevel level) {
  return switch (level) {
    ChallengeTrainingLevel.rookie => const Color(0xFF06D6A0),
    ChallengeTrainingLevel.growth => const Color(0xFFFFB703),
    ChallengeTrainingLevel.ace => const Color(0xFF7C4DFF),
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
    const Color(0xFF00A6A6),
    const Color(0xFFFF7A59),
    const Color(0xFF7C4DFF),
    const Color(0xFFFFB703),
    const Color(0xFF2F80ED),
    const Color(0xFF40B85A),
  ];
  final icons = <IconData>[
    Icons.sports_soccer,
    Icons.directions_run_rounded,
    Icons.groups_2_outlined,
    Icons.self_improvement_rounded,
    Icons.bolt_rounded,
    Icons.auto_awesome_rounded,
  ];
  return <_ChallengeSkillOption>[
    for (var index = 0; index < programs.length; index++)
      _ChallengeSkillOption(
        id: programs[index],
        label: programs[index],
        icon: icons[index % icons.length],
        color: colors[index % colors.length],
      ),
  ];
}

Set<String> _initialChallengeSkillSelection(
  List<_ChallengeSkillOption> options,
) {
  if (options.isEmpty) {
    return Set<String>.from(defaultChallengeSkillIds);
  }
  return options.map((option) => option.id).toSet();
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
      icon: Icons.sports_soccer,
      color: const Color(0xFF00A6A6),
    ),
    _ChallengeSkillOption(
      id: 'speedRun',
      label: l10n.challengeSkillSpeedRun,
      icon: Icons.directions_run_rounded,
      color: const Color(0xFFFF7A59),
    ),
    _ChallengeSkillOption(
      id: 'jumpRope',
      label: l10n.challengeSkillJumpRope,
      icon: Icons.sports_gymnastics_rounded,
      color: const Color(0xFF7C4DFF),
    ),
    _ChallengeSkillOption(
      id: 'lifting',
      label: l10n.challengeSkillLifting,
      icon: Icons.sports_soccer_outlined,
      color: const Color(0xFFFFB703),
    ),
    _ChallengeSkillOption(
      id: 'passing',
      label: l10n.challengeSkillPassing,
      icon: Icons.sync_alt_rounded,
      color: const Color(0xFF2F80ED),
    ),
    _ChallengeSkillOption(
      id: 'shooting',
      label: l10n.challengeSkillShooting,
      icon: Icons.adjust_rounded,
      color: const Color(0xFF40B85A),
    ),
    _ChallengeSkillOption(
      id: 'firstTouch',
      label: l10n.challengeSkillFirstTouch,
      icon: Icons.ads_click_rounded,
      color: const Color(0xFFEC4899),
    ),
    _ChallengeSkillOption(
      id: 'defense',
      label: l10n.challengeSkillDefense,
      icon: Icons.shield_outlined,
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
  final IconData icon;
  final Color color;

  const _ChallengeSkillOption({
    required this.id,
    required this.label,
    required this.icon,
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
